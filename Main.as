package {
	import xiaoChi.WindowController;
	import xiaoChi.ContextMenuUtils;
	import xiaoChi.MapEditor.Locator;
	import xiaoChi.MapEditor.MainWindowContexts;
	import xiaoChi.MapEditor.MEDManager;
	import xiaoChi.MapEditor.StartPanel;
	import xiaoChi.MapEditor.PropertiesPanel;
	import xiaoChi.MapEditor.ViewPanel;
	import xiaoChi.MapEditor.LibraryPanel;
	import xiaoChi.MapEditor.LayerPanel;
	import xiaoChi.MapEditor.ToolsPanel;
	import xiaoChi.MapEditor.ColorPalette;
	import xiaoChi.MapEditor.AboutME;
	import xiaoChi.MapEditor.MagnetWindowsLayout;
	import xiaoChi.MapEditor.MEDPreviewer;
	import flash.display.Sprite;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;

	public class Main extends Sprite {
		private const gcTimer: Timer = new Timer(5000);
		private var _propertiesPanel: PropertiesPanel; // = new PropertiesPanel(); //主窗口初始化前不要调用子窗口构造函数
		private var _viewPanel: ViewPanel;
		private var _libraryPanel: LibraryPanel;
		private var _layerPanel: LayerPanel;
		private var _toolsPanel: ToolsPanel;
		public const colorPalette: ColorPalette = new ColorPalette();
		public function get propertiesPanel(): PropertiesPanel {
			return _propertiesPanel;
		}
		public function get viewPanel(): ViewPanel {
			return _viewPanel;
		}
		public function get libraryPanel(): LibraryPanel {
			return _libraryPanel;
		}
		public function get layerPanel(): LayerPanel {
			return _layerPanel;
		}
		public function get toolsPanel(): ToolsPanel {
			return _toolsPanel;
		}

		public function Main() {
			gcTimer.start(); //强执垃圾回收器计时启动
			gcTimer.addEventListener(TimerEvent.TIMER, gc); //强执垃圾回收器计时侦听器启动
			Locator.init(); //资源定位器初始化（加载外置XML）
			WindowController.initMainWindow(stage.nativeWindow); //主窗口初始化
			ContextMenuUtils.frame = this; //配置菜单栏
			MainWindowContexts.init(); //主窗口菜单栏初始化
			MEDManager.init(); //MED管理器初始化
			MEDManager.mainWindow = stage.nativeWindow; //配置MED管理器
			MagnetWindowsLayout.init(stage.nativeWindow); //窗口布局初始化
			MEDPreviewer.init(); //预览器初始化
			WindowController.startPanel = new StartPanel(); //开始界面实例化
			_viewPanel = new ViewPanel(this); //视口界面实例化
			_libraryPanel = new LibraryPanel(this); //资源界面实例化
			_layerPanel = new LayerPanel(this); //图层界面实例化
			_propertiesPanel = new PropertiesPanel(this); //属性界面实例化
			_toolsPanel = new ToolsPanel(this); //工具界面实例化
			AboutME.init(); //关于界面初始化
		}
		private function gc(e: TimerEvent) {
			System.pauseForGCIfCollectionImminent(1);
			trace("垃圾回收完毕，当前占用内存：" + Math.floor(System.privateMemory / 1024 / 1024 * 100) / 100 + "MB。");
		}
	}

}