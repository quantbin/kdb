package asqlib {
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;

	public class ObjDump {
		private static const ARRAY_DUMP_LIMIT:int=30;
		private static const DUMP_LIMIT:int=100;
		private static const INDENT:String="  ";
		private static const RECURSION_LIMIT:int=5;
		private static var totalTimeSpentLogging:Number=0;
		private static var typePropertiesCache:Object={};

		public static function deepTrace(obj:*, level:int=0):String {
			var tabs:String="";
			var out:String="";
			for (var i:int=0; i < level; i++)
				tabs+="\t";
			for (var prop:String in obj) {
				out=out + tabs + "[" + prop + "] -> " + obj[prop];
				deepTrace(obj[prop], level + 1);
			}
			return out;
		}

		public static function toString(o:Object, recursionLevel:int=0):String {
			try {
				if (null == o) {
					return "<null>";
				}
				if (recursionLevel > RECURSION_LIMIT) {
					// past recursion limit; show standard toString() representation
					return "<" + o.toString() + ">";
				}
				var beg:Number=(new Date).time;
				var tabs:String="";
				var tabsLessOne:String="";
				for (var i:int=0; i < recursionLevel + 1; i++) {
					tabs=tabs + INDENT;
				}
				for (i=0; i < recursionLevel; i++) {
					tabsLessOne=tabsLessOne + INDENT;
				}
				if (ObjectUtil.isSimple(o)) {
					s=s + tabs + o.toString() + "\n";
				} else {
					var cn:String=getClassName(o);
					var s:String=cn + "[\n";
					var counter:int=0;
					var props:Array=new Array;
					for (var prop:String in o) {
						props.push(prop);
					}
					props.push(getPropertyNames(o));
					for each (var p:String in props) {
						if (null != o[p]) {
							if ("ArrayCollection" == cn && "list" == p) {
								// skip list member (it seems to repeat source)
								continue;
							}
							if (!ObjectUtil.isSimple(o[p]) || o[p] is Array) {
								if (o[p] is Array) {
									var arrayCounter:int=0;
									for each (var e:Object in o[p]) {
										if (!ObjectUtil.isSimple(e)) {
											s=s + tabs + p + "[" + arrayCounter + "]=" + toString(e, recursionLevel + 1) + "\n";
										} else {
											s=s + tabs + p + "[" + arrayCounter + "]=" + e.toString() + "\n";
										}
										arrayCounter=arrayCounter + 1;
										if (arrayCounter > ARRAY_DUMP_LIMIT) {
											s=s + tabs + "...clip (showing " + arrayCounter + " elements of " + (o[p] as Array).length + ")...\n";
											break;
										}
									}
								} else {
									s=s + tabs + p + "=" + toString(o[p], recursionLevel + 1) + "\n";
								}
							} else {
								s=s + tabs + p + "=" + o[p] + "\n";
							}
							counter=counter + 1;
						}
						if (counter > DUMP_LIMIT) {
							break;
						}
					}
				}
				var end:Number=(new Date).time;
				var timers:String=(end - beg) + "ms";
				if (0 == recursionLevel) {
					totalTimeSpentLogging=totalTimeSpentLogging + (end - beg);
					timers=timers + "(total " + totalTimeSpentLogging + "ms)";
				}
				s=s + tabsLessOne + "]: " + timers;
				return s;
			} catch (err:Error) {
				trace("error dumping object; error: " + err.toString());
			}
			return "<error>";
		}

		private static function getClassName(o:Object):String {
			var cn:String=getQualifiedClassName(o);
			var i:int=cn.lastIndexOf(":");
			if (-1 != i) {
				cn=cn.substr(i + 1);
			}
			return cn;
		}

		private static function getPropertyNames(instance:Object):Array {
			var className:String=getQualifiedClassName(instance);
			if (typePropertiesCache[className]) {
				return typePropertiesCache[className];
			}
			var typeDef:XML=describeType(instance);
			var props:Array=[];
			for each (var prop:XML in typeDef.accessor.(@access == "readwrite" || @access == "readonly")) {
				props.push(prop.@name);
			}
			return typePropertiesCache[className]=props;
		}
	}
}
