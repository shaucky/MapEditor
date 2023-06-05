package xiaoChi {
	import xiaoChi.WindowPanel;
	import xiaoChi.STDIOEvent;
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.events.Event;

	public function standardIO(desc: String, acceptable: Boolean = true, refuseable: Boolean = false, cancelable: Boolean = false): NativeWindow {
		const appDescriptor: XML = NativeApplication.nativeApplication.applicationDescriptor;
		const desNamespace: Namespace = appDescriptor.namespace();
		const appName: String = appDescriptor.desNamespace::filename;
		const appVer: String = appDescriptor.desNamespace::versionNumber;
		const options: NativeWindowInitOptions = new NativeWindowInitOptions();
		const array: Array = new Array();
		var window: NativeWindow;
		var tf: TextField;
		var accept: TextField;
		var refuse: TextField;
		var cancel: TextField;
		var behavior: String = "cancel";
		init();
		tf = ((window.stage.getChildAt(0) as Sprite).getChildAt(0) as TextField);
		tf.text = desc;
		tf.x = (window.stage.stageWidth - tf.width) / 2;
		tf.y = 10;
		accept = ((window.stage.getChildAt(0) as Sprite).getChildAt(1) as TextField);
		if (acceptable) {
			array.push(accept);
			accept.addEventListener(MouseEvent.CLICK, accepted);
			createButton(accept);
		} else {
			accept.visible = false;
		}
		accept.x = tf.x + 15;
		accept.y = tf.y + tf.height + 10;
		refuse = ((window.stage.getChildAt(0) as Sprite).getChildAt(2) as TextField);
		if (refuseable) {
			array.push(refuse);
			refuse.addEventListener(MouseEvent.CLICK, refused);
			createButton(refuse);
		} else {
			refuse.visible = false;
		}
		refuse.x = (window.stage.stageWidth - refuse.width) / 2;
		refuse.y = accept.y;
		cancel = ((window.stage.getChildAt(0) as Sprite).getChildAt(3) as TextField);
		if (cancelable) {
			array.push(cancel);
			cancel.addEventListener(MouseEvent.CLICK, canceled);
			createButton(cancel);
		} else {
			cancel.visible = false;
		}
		cancel.x = tf.x + tf.width - cancel.width - 15;
		cancel.y = accept.y;
		switch (array.length) {
			case 0:
				break;
			case 1:
				array[0].x = (window.stage.stageWidth - array[0].width) / 2;
				array[0].y = tf.y + tf.height + 10;
				break;
			case 2:
				array[0].x = tf.x + 15;
				array[0].y = tf.y + tf.height + 10;
				array[1].x = tf.x + tf.width - array[1].width - 15;
				array[1].y = tf.y + tf.height + 10;
				break;
			case 3:
				array[0].x = tf.x + 15;
				array[0].y = tf.y + tf.height + 10;
				array[1].x = (window.stage.stageWidth - array[0].width) / 2;
				array[1].y = tf.y + tf.height + 10;
				array[2].x = tf.x + tf.width - array[1].width - 15;
				array[2].y = tf.y + tf.height + 10;
				break;
		}
		trace(desc);
		window.activate();
		WindowPanel.lockUpAllWindows(); //禁用其他子窗口的交互
		return window;
		function accepted(e: MouseEvent) {
			behavior = STDIOEvent.ACCEPT;
			window.close();
		}
		function refused(e: MouseEvent) {
			behavior = STDIOEvent.REFUSE;
			window.close();
		}
		function canceled(e: MouseEvent) {
			behavior = STDIOEvent.CANCEL;
			window.close();
		}
		function onClose(e: Event) {
			trace(behavior + "（" + desc + "）");
			window.dispatchEvent(new STDIOEvent(behavior));
			WindowPanel.lockUpAllWindows(); //释放其他子窗口的交互
		}
		function init() {
			options.maximizable = false;
			options.minimizable = false;
			options.resizable = false;
			window = new NativeWindow(options);
			window.alwaysInFront = true;
			window.width = 350;
			window.height = 150;
			window.title = appName + " " + appVer;
			window.stage.color = 0x444444;
			window.stage.align = StageAlign.TOP_LEFT;
			window.stage.scaleMode = StageScaleMode.NO_SCALE;
			window.stage.addChild(new stdio());
			window.addEventListener(Event.CLOSE, onClose);
		}
		function createButton(tf: TextField) {
			tf.background = true;
			tf.backgroundColor = 0x444444;
			tf.border = true;
			tf.borderColor = 0x000000;
		}
	}

}