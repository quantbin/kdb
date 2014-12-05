package components {
	import flash.events.Event;

	public class SelectionChangedEvent extends Event {
		public function SelectionChangedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		public var left:Number;
		public var right:Number;
	}
}