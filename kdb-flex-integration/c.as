package asqlib {
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.collections.ArrayCollection;
	import mx.events.FlexEvent;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	
	public class c extends EventDispatcher {
		public static var CONNECTED:String = "CONNECTED";
		public static var DISCONNECTED:String = "DISCONNECTED";
		public static var BEG_EXEC:String = "BEG_EXEC";
		public static var END_EXEC:String = "END_EXEC";
		public static var CONNECTION_ERROR:String = "CONNECTION_ERROR";
		private static var LONG_BASE:Number	= 0x100000000;
		public static const MILLISECONDS_PER_DAY:int = 1000 * 60 * 60 * 24;		
		public static const MILLISECONDS_PER_MINUTE:int = 1000 * 60;		
		
		public var MAX_ARRAY_LEN:int= 1000;
		public var s:Socket;
		public var v6:Boolean;
		public var inCall:Boolean = false;
		private var user:String;
		private var host:String;
		private var port:int;
		private var authCall:Boolean = false;
		private var authAttempt:int;
		private var _connected:Boolean = false;
		private var queue:Array = new Array;
		private var currentCall:Call;
		private var msgLen:int;
		private var msgBytesReceived:int;
		private var B:ByteArray;
		private var comp:Boolean;
		private var now:Date=new Date;
		
		public function c(h:String, p:int, u:String) {
			user = u;
			host = h;
			port = p;
		}
		
		public function get connected():Boolean {
			return _connected;
		}
		
		public function connect(retry:Boolean=true):void {
			B = new ByteArray();
			B.length = 2 + user.length;
			io(new Socket(host,port));
			wstr(user);
			if (retry) {
				authAttempt = 1;
				wbyte(1);
			} else {
				authAttempt = 2;
			}
			wbyte(0);
			inCall = true;
			authCall = true;
			s.writeBytes(B);
			s.flush();
			dispatchEvent(new FlexEvent(BEG_EXEC));
		}
		
		private function io(x:Socket):void {
			s=x;
			s.addEventListener(Event.CONNECT , connectHandlerData);
			s.addEventListener(Event.CLOSE , closeHandlerData);
			s.addEventListener(ErrorEvent.ERROR , errorHandlerData);
			s.addEventListener(IOErrorEvent.IO_ERROR , ioErrorHandlerData);
			s.addEventListener(ProgressEvent.SOCKET_DATA , dataHandlerData);
		}
		
		public function close():void {
			if (!connected) return;
			s.close();
			_connected = false;
			dispatchEvent(new FlexEvent(DISCONNECTED));
		}
		
		private function connectHandlerData(e:Event):void {
			_connected = true;
		}
		
		private function closeHandlerData(e:Event):void {
			_connected = false;
			dispatchEvent(new FlexEvent(DISCONNECTED));
		}
		
		private function errorHandlerData(e:ErrorEvent):void {
			dispatchEvent(new FlexEvent(CONNECTION_ERROR));
			if (null!=currentCall) {
				currentCall.obj[currentCall.error] = "connection error: " + e.toString();
			}
			trace("connection error 1: " + e.toString());
		}
		
		private function ioErrorHandlerData(e:IOErrorEvent):void {
			if (null!=currentCall) {
				currentCall.obj[currentCall.error] = "connection error: " + e.toString();
			} 
			dispatchEvent(new FlexEvent(CONNECTION_ERROR));
			trace("connection error 2: " + e.toString());
		}
		
		private function dataHandlerData(e:ProgressEvent):void {
			if (authCall) {
				if (1 != e.bytesLoaded) {
					if (1 == authAttempt) {
						connect(false);
						return;
					} else if (2 == authAttempt){
						inCall = false;
						authCall = false;
						s.close();
						currentCall.obj[currentCall.error] = "access denied";
						dispatchEvent(new FlexEvent(END_EXEC));
						return;
					} else {
						inCall = false;
						authCall = false;
						s.close();
						currentCall.obj[currentCall.error] = "invlaid authAttempt while in authCall";
						dispatchEvent(new FlexEvent(END_EXEC));
						return;
					}
				} else {
					var bytes:ByteArray = new ByteArray();
					s.readBytes(bytes, 0, 1);
					var n:int = bytes.readByte();
					v6 = (n == 1);
					inCall = false;
					authCall = false;
					if (v6) {
						dispatchEvent(new FlexEvent(CONNECTED));
						
					}
					dispatchEvent(new FlexEvent(END_EXEC));
				}
			} else {
				// data arrived
				if (0 == msgBytesReceived) {
					B = new ByteArray();
					B.length = 8;
					s.readBytes(B, 0, B.length);
					if (1 == B.readByte()) B.endian = Endian.LITTLE_ENDIAN else B.endian = Endian.BIG_ENDIAN;
					B.readByte();
					comp = B.readBoolean();
					B.readByte();
					msgLen = B.readInt();
					// read the rest of the buffer
					s.readBytes(B, 8, e.bytesLoaded - 8);
					msgBytesReceived = e.bytesLoaded;
				} else {
					// keep reading from socket until message length is reached
					s.readBytes(B, B.length, e.bytesLoaded);
					msgBytesReceived = msgBytesReceived + e.bytesLoaded;
				}
				if (msgLen == msgBytesReceived) {
					log("rcv: " + dump(B));
					B.position = 8;
					if (comp) {
						u();
					}
					var type:int = B.readByte();
					if (-128 == type) {
						currentCall.obj[currentCall.error] = B.readUTFBytes(B.bytesAvailable);
					} else {
						// read data and store in caller's obj/prop
						try {
							var r:Object=parseInput(type);
							currentCall.callEnd=(new Date).getTime();
							if (null!=currentCall.timer) currentCall.obj[currentCall.timer]=currentCall.callBeg-currentCall.callEnd;
							// NOTE that timer data was already sent to the caller
							currentCall.obj[currentCall.data] = r;
						} catch(er:Error) {
							log("parseInput error: " + er.toString());
							if (null!=currentCall.obj&&null!=currentCall.error)
								currentCall.obj[currentCall.error] = er.toString();
						}
					}
					inCall = false;
					dispatchEvent(new FlexEvent(END_EXEC));
					if (queue.length>0) {
						var call:Call = Call(queue.shift());
						log("executing call from queue");
						if (call.sync) {
							_ksync(call);
						} else {
							_kasync(call);
						}
					}
				}
			}
		}

		private function u():void {
			var n:int=0,r:int=0,f:int=0,s:int=8,p:int=s;
			var i:int=0;
			var dst:ByteArray=new ByteArray;
			dst.endian = B.endian;
			var len:int = B.readInt();
			dst.length=len;
			var d:int=0;
			// array of 256 int
			var aa:Array=new Array;
			var bt:int;
			while(s<dst.length){
				if(i==0){
					bt=B.readByte(); 
					f=0xff&bt;
					i=1;
				}
				if ((f & i) != 0) {
					bt=B.readByte();
					r = aa[0xff & bt];
					dst[s++] = dst[r++];
					dst[s++] = dst[r++];
					bt = B.readByte();
					n = 0xff & bt;
					for (var m:int  = 0; m < n; m++) {
						dst[s + m] = dst[r + m];
					}
				} else {
					bt=B.readByte();					
					dst[s++] = bt;
				}
				while (p < s - 1) {
					var idx:int =(0xff & int(dst[p]))^(0xff & int(dst[p+1])); 
					aa[idx] = p++;
				}
				if ((f & i) != 0) {
					s=s+n;
					p=s;
				}
				i =i*2;
				if (i == 256)
					i = 0;
			}
			B = dst;
			B.position=8;
		}
		
		private function parseInput(type:int):Object {
			var attr:int;
			var v:ArrayCollection;
			var sa:String = "";
			var vlen:int;
			var item:Object;
			if (0 == type) {
				// mixed list
				attr= B.readByte();
				v = new ArrayCollection;
				vlen = B.readInt();
				while(vlen>0) {
					type = B.readByte();
					item =parseInput(type);
					v.addItem(item);
					vlen--;
				}
				return v;
			} else if (type > 0) {
				if (type>=1&&type<=19) {
					// vector
					attr= B.readByte();
					v = new ArrayCollection;
					vlen = B.readInt();
					while(vlen>0) {
						item =parseInput(-type);
						if (10==type) {
							sa=sa+String(item);
						} else {
							v.addItem(item);
						}
						vlen--;
					}
					if (10==type) {
						return sa;
					} else {
						return v;
					}
				} else {
					switch(type) {
						case 98:
							//table
							log("table: " + type);
							attr= B.readByte();
							type = B.readByte();
							if (99!=type) throw new Error("table content should be dict");
							return parseInput(type);
							break;
						case 99:
						case 127:
							//dict
							log("dict: " + type);
							type = B.readByte();
							var keys:Object = parseInput(type);
							type = B.readByte();
							var values:Object = parseInput(type);
							var dict:Object;
							var ii:int;
							if (keys is ArrayCollection && values is ArrayCollection) {
								// regular dict
								dict = new Object;
								//log("keys:"+ObjectUtil.toString(keys));
								//log("values:"+ObjectUtil.toString(values));
								for(ii=0; ii<keys.length; ii++) {
									dict[keys[ii]]=values[ii];
								}
								return dict;
							} else if (keys is Object && values is Object) {
								// keyed table (?)
								dict = new Object;
								dict["k"] = keys;
								dict["v"] = values;
								return dict;
							} else {
								throw new Error("wrong components in dict");
							}
						case 101:
							if (0==B.bytesAvailable) {
								trace("probably result of assignement call");
							}
							break;
						case 100:
							// read context
							var ctx:String = "";
							while (0!=(attr= B.readByte())) {
								ctx=ctx+String.fromCharCode(s)
							}
							type = B.readByte();
							var fun:String = String(parseInput(type));
							var po:ObjectProxy = new ObjectProxy;
							po["c"] = ctx;
							po["f"] = fun;
							return po;
						case 102:
						case 103:
						case 104:
						case 105:
						case 106:
						case 107:
						case 108:
						case 109:
						case 110:
						case 111:
						case 112:
							// TODO need proper handling of labdas
							return "func";
						default:
							throw new Error("unknown type: " + type);
					}
				}
			} else {
				// atom
				var days:int;
				var minutes:int;
				var date:Date;
				switch(type) {
					case -1:
						var b:Boolean = new Boolean;
						b = B.readBoolean();
						return b;
					case -4:
						var x:int;
						x = B.readByte();
						return x;
					case -5:
						var h:int;
						h = readShort();
						return h;
					case -6:
						var i:int;
						i = B.readInt();
						return i;
					case -7:
						var l:Number;
						l = readLong();
						return l;
					case -8:
						var f:Number;
						f = B.readFloat();
						return f;
					case -9:
						var d:Number;
						d = B.readDouble();
						return d;
					case -10:
						var c:int;
						c = B.readByte();
						return String.fromCharCode(c);
					case -11:
						//string
						var s:int;
						while(0 != (s = B.readByte())) {
							sa = sa + String.fromCharCode(s);
						}
						return sa;
					case -12:
						// timestamp - 8 bytes
						var timestamp:Number=readLong();
						var n:Number=1000000000;
						var nj:Number=0x8000000000000000;
						var k:Number = 86400000 * 10957;
						var dd:Number = timestamp < 0 ? (timestamp + 1) / n - 1 : timestamp / n;
						date = new Date;
						date.setTime(timestamp == nj ? timestamp : gl(k + 1000 * dd));
						// NOTE that Date does not support nanos
						return date;
					case -13:
						// month - 4 bytes; count of months since the beginning of the year
						return B.readInt();
					case -14:
						// date - 4 bytes; count of days from Jan 1, 2000
						days=B.readInt();
						date=new Date(2000, 0, 1);
						date.setTime(date.getTime()+MILLISECONDS_PER_DAY*days);
						date.setTime(gl(date.getTime()));
						return date;
					case -15:
						// datetime - 8 bytes
						days=B.readInt();
						date=new Date(2000, 0, 1);
						date.setTime(date.getTime()+B.readInt());
						date.setTime(gl(date.getTime()));
						return date;
					case -16:
						// timespan - 8 bytes; system local time (as timespan) in nanoseconds
						return readLong();
					case -17:
						// minute - 4 bytes; count of minutes from midnight
						return B.readInt();
					case -18:
						// second - 4 bytes; count of seconds from midnight
						return B.readInt();
					case -19:
						// time - 4 bytes; count of milliseconds from midnight
						return B.readInt();
					default:
						throw new Error("unknown type: " + type);
				}
			}
			return null;
		}
		
		private function ns(s:String):int {
			var i:int;
			if (s == null) return 0;
			return s.length;
		}
		
		private function wstr(s:String):void {
			var n:int = ns(s);
			if (n < s.length) {
				s = s.substr(0, n);
			}
			B.writeUTFBytes(s);
		}

		private function wbyte(v:int):void {
			B.writeByte(v);
		}
		
		private function t(x:Object):int {
			if (x is Array) {
			} else {
				if (x is String) {
					return 10;
				}
			}
			throw new Error("NYI");
		}
		
		private function nx(x:Object):int {
			if (10 == t(x)) {
				return 6 + String(x).length;
			} else {
				throw new Error("NYI");
			}
		}
		
		public function kasync(cmd:String):Boolean {
			if (!_connected)return false; 
			var call:Call = new Call(false, cmd);
			if (inCall) {
				trace("queueing up the call");
				queue.push(call);
				return true;
			}
			_kasync(call);
			return true;
		}

		private function _kasync(call:Call):void {
			w(0, call.cmd);
		}

		public function ksync(cmd:String, obj:Object, prop:String, error:String=null, warn:String=null, tr:Function=null, timer:String=null):Boolean {
			if (!_connected)return false; 
			var call:Call = new Call(true, cmd, obj, prop, error, warn, tr, timer);
			if (inCall) {
				trace("queueing up the call");
				queue.push(call);
				return true;
			}
			inCall = true;
			dispatchEvent(new FlexEvent(BEG_EXEC));
			_ksync(call);
			return true;
		}
		
		private function _ksync(call:Call):void {
			currentCall = call;
			try {
				log("executing: " + call.cmd);
				w(1, call.cmd);
			} catch(e:Error) {
				if (null!=currentCall.error) currentCall.obj[currentCall.error] = e.toString();
			}
			msgLen = 0;
			msgBytesReceived = 0;
		}

		private function w(i:int, x:Object):void {
			var n:int = nx(x) + 8;
			B = new ByteArray;
			B.length = n;
			B.endian = Endian.LITTLE_ENDIAN;
			// 1 byte - endianness (little)
			if (Endian.BIG_ENDIAN==B.endian) B.writeByte(0) else B.writeByte(1); 
			// 1 byte - async/sync/resp
			B.writeByte(i);
			// 1 byte - dummy
			B.writeByte(0);
			// 1 byte - dummy
			B.writeByte(0);
			// 4 bytes - msg length
			B.writeInt(n);
			// write object
			wobj(x);
			//01 00 00 00 11 00 00 00 0a 00 03 00 00 00 78 3a 31
			// write data to socket
			B.position = 0;
			log("snd: " + dump(B));
			//trace("snd: " + dump(B));
			s.writeBytes(B);
			s.flush();
		}
		
		private function wobj(x:Object):void {
			switch(t(x)) {
				case 10:
					// type
					B.writeByte(10);
					// attributes
					B.writeByte(0);
					B.writeInt(String(x).length);
					B.writeUTFBytes(String(x));
					break;
				default:
					throw new Error("NYI");
			}
		}
		
		public static function dump(ba:ByteArray):String {
			var r:String = "";
			var pos:int = ba.position;
			ba.position = 0;
			for(var i:int = 0; i < ba.length; i++) {
				var ch:String = ba.readByte().toString(16);
				if (1 == ch.length) {
					ch = "0" + ch;
				}
				r = r + ch + " ";
			}
			ba.position = pos;
			return r;
		}

		private function readShort():int {
			var a:int = B.readByte();
			var b:int = B.readByte();
			if (Endian.BIG_ENDIAN == B.endian) {
				return a * 256 + b;
			} else {
				return b * 256 + a;
			}
		}

		private function readLong():Number {
			var a:int = B.readInt();
			var b:int = B.readInt();
			if (Endian.BIG_ENDIAN == B.endian) {
				return a * LONG_BASE+ b;
			} else {
				return b * LONG_BASE + a;
			}
		}
		
		private function gl(x:Number):Number {
			return x+now.getTimezoneOffset()*60*1000;
		}
		
		private function log(s:String):void {
			if (null!=currentCall.tr) currentCall.tr.call(null, s);
		}
	}
}
