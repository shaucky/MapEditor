package xiaoChi.MapEditor {
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;

	public class Locator {
		private static const locator: File = File.applicationDirectory.resolvePath("data/locator.xml");
		private static const locatorStream: FileStream = new FileStream();
		private static const _directory: File = File.applicationDirectory;
		private static var _xml: XML;
		private static var _ready: Boolean = false;
		public static function get directory(): File {
			var f: File = null;
			if (isReady) {
				f = _directory;
			}
			return f;
		}
		public static function get data(): XML {
			var x: XML = null;
			if (isReady) {
				x = _xml;
			}
			return x;
		}
		public static function get isReady(): Boolean {
			return _ready;
		}

		public static function init() {
			try {
				locatorStream.open(locator, FileMode.READ);
				_ready = true;
				_xml = new XML(locatorStream.readUTFBytes(locatorStream.bytesAvailable));
				trace(_xml);
			} catch (err: Error) {
				trace("Error: 初始化过程出现错误，无法读取：\n" + locator.url + "\n可能是程序错误，可尝试重新启动MapEditor。");
				trace("Exit: 初始化失败。");
				NativeApplication.nativeApplication.exit(1);
			}
		}

	}

}