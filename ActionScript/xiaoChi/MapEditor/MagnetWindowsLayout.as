package xiaoChi.MapEditor {
	import xiaoChi.ContextMenuUtils;
	import xiaoChi.WindowController;
	import xiaoChi.WindowPanel;
	import xiaoChi.WindowPanelDirection;
	import flash.events.Event;
	import flash.display.NativeWindow;

	public class MagnetWindowsLayout {
		private static var _mainWindow: NativeWindow;

		public static function init(mainWindow: NativeWindow) {
			if (!_mainWindow) {
				_mainWindow = mainWindow;
			}
			ContextMenuUtils.getItemByLabel("默认布局").addEventListener(Event.SELECT, classicLayout);
		}
		private static function classicLayout(e: Event) {
			var array: Array = WindowController.magnetWindows;
			var main: Main = (_mainWindow.stage.getChildAt(0) as Main);
			array[0].splice(0);
			array[1].splice(0);
			array[2].splice(0);
			array[3].splice(0);
			array[4].splice(0);
			magneticWindow(main.viewPanel, WindowPanelDirection.ALL);
			array[0].push(main.viewPanel);
			magneticWindow(main.layerPanel, WindowPanelDirection.ROW);
			array[1].push(main.layerPanel);
			magneticWindow(main.libraryPanel, WindowPanelDirection.COL);
			array[2].push(main.libraryPanel);
			magneticWindow(main.toolsPanel, WindowPanelDirection.COL);
			array[3].push(main.toolsPanel);
			magneticWindow(main.propertiesPanel, WindowPanelDirection.COL);
			array[3].push(main.propertiesPanel);
			WindowPanel.resetMagneticWindows();
		}

		private static function magneticWindow(panel: WindowPanel, direct: String) {
			if (!panel.window.visible) {
				ContextMenuUtils.getItemByLabel(panel.window.title).dispatchEvent(new Event(Event.SELECT));
			}
			panel.direct = direct;
			panel.resizeCorner.visible = false;
			panel.isMagnetic = true;
		}

	}

}