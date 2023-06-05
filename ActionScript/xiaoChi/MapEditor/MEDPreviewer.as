package xiaoChi.MapEditor {
	import xiaoChi.ContextMenuUtils;
	import xiaoChi.MapEditor.MEDManager;
	import flash.events.Event;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindow;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	public class MEDPreviewer {
		private static var inited: Boolean = false;
		private static const windowInitOptions: NativeWindowInitOptions = new NativeWindowInitOptions();

		public static function init() {
			if (!inited) {
				windowInitOptions.maximizable = false;
				windowInitOptions.resizable = false;
				ContextMenuUtils.getItemByLabel("在MapEditor中预览（AIR平台）").addEventListener(Event.SELECT, AIR_PreviewSelected);
				inited = true;
			}
		}
		private static function AIR_PreviewSelected(e: Event) {
			previewInAIR(MEDManager.currentMED);
		}

		public static function previewInAIR(med: MEDocument) { //在AIR中预览（即在MapEditor中预览）
			const AIRWindow: NativeWindow = new NativeWindow(windowInitOptions);
			trace("Preview: 在AIR中预览：" + med.fileName);
			AIRWindow.stage.align = StageAlign.TOP_LEFT;
			AIRWindow.stage.color = Number(med.scene.@backgroundColor);
			AIRWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			AIRWindow.stage.stageWidth = 1136;
			AIRWindow.stage.stageHeight = 640;
			AIRWindow.title = String(med.fileName);
			AIRWindow.activate();
		}

	}

}