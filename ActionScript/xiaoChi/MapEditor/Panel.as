package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.Locator;
	import xiaoChi.WindowPanel;
	import xiaoChi.ContextMenuUtils;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;
	import flash.display.Loader;
	import flash.system.LoaderContext;

	public class Panel extends WindowPanel {
		protected var mainFrame: Sprite;
		private var contentFile: File;
		private const contentFileStream: FileStream = new FileStream();
		protected const contentLoader: Loader = new Loader();
		private var _tag: String = null;
		public function set title(value: String) {
			window.title = value;
			ContextMenuUtils.getItemByLabel(window.title).addEventListener(Event.SELECT, panelActivate);
		}
		public function set tag(value: String) {
			_tag = value;
		}

		public function Panel(parentFrame: Sprite) {
			mainFrame = parentFrame;
		}
		private function panelActivate(e: Event) {
			if (this.window) {
				if (this.window.visible) {
					hide();
					ContextMenuUtils.getItemByLabel(window.title).checked = false;
				} else {
					show();
					ContextMenuUtils.getItemByLabel(window.title).checked = true;
					this.window.x = (this.stage.fullScreenWidth - this.window.width) / 2;
					this.window.y = (this.stage.fullScreenHeight - this.window.height) / 2;
					this.window.orderToFront();
					if (!content && _tag && Locator.isReady) {
						contentFile = (Locator.directory as File).resolvePath("frames/" + (Locator.data as XML).child("frames")[0].child(_tag)[0]);
						try {
							contentFileStream.openAsync(contentFile, FileMode.READ);
							contentFileStream.addEventListener(Event.COMPLETE, contentFileOpened);
							contentFileStream.addEventListener(IOErrorEvent.IO_ERROR, contentFileOpenError);
						} catch (err: Error) {
							trace("Error: 无法读取：\n" + contentFile.url);
						}
					}
				}
			}
		}
		private function contentFileOpened(e: Event) {
			var b: ByteArray = new ByteArray();
			var lc: LoaderContext = new LoaderContext();
			lc.allowCodeImport = true;
			try {
				contentFileStream.readBytes(b);
				contentLoader.loadBytes(b, lc);
				contentLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, contentIOError);
			} catch (err: Error) {
				trace("Error: 无法读取：\n" + contentFile.url);
			}
			contentFileStream.removeEventListener(Event.COMPLETE, contentFileOpened);
			contentFileStream.removeEventListener(IOErrorEvent.IO_ERROR, contentFileOpenError);
		}
		private function contentFileOpenError(e: IOErrorEvent) {
			contentFileStream.removeEventListener(Event.COMPLETE, contentFileOpened);
			contentFileStream.removeEventListener(IOErrorEvent.IO_ERROR, contentFileOpenError);
			trace("Error: 无法读取：\n" + contentFile.url);
		}
		private function contentIOError(e: IOErrorEvent) {
			contentLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, contentIOError);
			trace("Error: 无法读取：\n" + contentFile.url);
		}

	}

}