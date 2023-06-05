package xiaoChi {
	import flash.events.Event;

	public class STDIOEvent extends Event {
		public static const ACCEPT: String = "accept";
		public static const CANCEL: String = "cancel";
		public static const REFUSE: String = "refuse";

		public function STDIOEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false) {
			super(type, bubbles, cancelable);
		}

	}

}