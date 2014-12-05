package asqlib {

	public class Call {
		public var sync:Boolean;
		public var cmd:String;
		public var obj:Object;
		public var data:String;
		public var warn:String;
		public var error:String;
		public var timer:String;
		public var tr:Function;
		public var callBeg:Number;
		public var callEnd:Number;

		public function Call(s:Boolean, c:String=null, o:Object=null, p:String=null, e:String=null, w:String=null, t:Function=null, tmr:String=null) {
			callBeg=(new Date).getTime();
			sync = s;
			cmd=c;
			obj=o;
			data=p;
			warn=w;
			error=e;
			timer=tmr;
			tr=t;
		}
	}
}
