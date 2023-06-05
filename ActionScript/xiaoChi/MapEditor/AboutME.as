package xiaoChi.MapEditor {
	import xiaoChi.ContextMenuUtils;
	import flash.html.HTMLLoader;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.media.StageWebView;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;

	public class AboutME {
		private static const html: StageWebView = new StageWebView();
		private static var window: NativeWindow;
		private static const options: NativeWindowInitOptions = new NativeWindowInitOptions();
		private static const loader: URLLoader = new URLLoader();
		private static var pageLoaded: Boolean = false;

		public static function init() {
			loader.load(new URLRequest("data/about_MapEditor.html"));
			loader.addEventListener(Event.COMPLETE, loadComplete);
			ContextMenuUtils.getItemByLabel("关于MapEditor").addEventListener(Event.SELECT, changeDisplayState);
		}
		private static function windowResize(e: Event) {
			html.viewPort = new Rectangle(0, 0, window.stage.stageWidth, window.stage.stageHeight);
		}
		private static function windowClosing(e: Event) {
			e.preventDefault();
			window.visible = false;
			ContextMenuUtils.getItemByLabel("关于MapEditor").checked = false;
		}
		private static function changeDisplayState(e: Event) {
			if (!window) {
				window = new NativeWindow(options);
				window.title = "关于MapEditor";
				window.stage.align = StageAlign.TOP_LEFT;
				window.stage.scaleMode = StageScaleMode.NO_SCALE;
				window.stage.color = 0x313131;
				window.alwaysInFront = true;
				window.addEventListener(Event.CLOSING, windowClosing);
				html.stage = window.stage;
			}
			if (window.visible) {
				window.visible = false;
				ContextMenuUtils.getItemByLabel("关于MapEditor").checked = false;
			} else {
				if (pageLoaded) {
					html.loadString(loader.data);
					window.visible = true;
					window.width = window.stage.fullScreenWidth / 2;
					window.height = window.stage.fullScreenHeight / 2;
					window.x = (window.stage.fullScreenWidth - window.width) / 2;
					window.y = (window.stage.fullScreenHeight - window.height) / 2;
					html.viewPort = new Rectangle(0, 0, window.stage.stageWidth, window.stage.stageHeight);
					window.stage.addEventListener(Event.RESIZE, windowResize);
					ContextMenuUtils.getItemByLabel("关于MapEditor").checked = true;
					window.orderToFront();
				}
			}
		}
		private static function loadComplete(e: Event) {
			pageLoaded = true;
		}

	}

}