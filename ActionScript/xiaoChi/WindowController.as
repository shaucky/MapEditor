package xiaoChi {
	import xiaoChi.ContextMenuBox;
	import xiaoChi.OS;
	import xiaoChi.MainWindowIcon;
	import xiaoChi.WindowButtonType;
	import xiaoChi.WindowPanel;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.display.Bitmap;
	import flash.display.NativeWindowDisplayState;
	import flash.system.Capabilities;
	import flash.desktop.NativeApplication;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.display.NativeMenuItem;
	import flash.display.NativeMenu;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.Stage;

	public class WindowController {
		private static var _startPanel: Sprite;
		private static var operatorSystem: String;
		private static var mainWindow: NativeWindow;
		private static var mainFrame: Sprite;
		private static const mainWindowBar: Sprite = new Sprite(); //主窗口菜单栏
		internal static var mainWindowBarHeight: Number = 0;
		private static const mainWindowContent: Sprite = new Sprite(); //主窗口内容
		private static const mainWindowIcon: Bitmap = new Bitmap(new MainWindowIcon()); //主窗口图标
		private static const mainWindowButtons: Sprite = new Sprite(); //主窗口按钮容器
		private static const mainWindowCloseButton: Sprite = new Sprite(); //主窗口关闭按钮
		private static const mainWindowMaxiButton: Sprite = new Sprite(); //主窗口最大化按钮
		private static const mainWindowMiniButton: Sprite = new Sprite(); //主窗口最小化按钮
		private static const mainWindowContexts: Sprite = new Sprite(); //主窗口上下文菜单
		private static const mainWindowResizeCorner: Sprite = new Sprite(); //主窗口右下角缩放角
		private static const mainWindowMagnets: Sprite = new Sprite(); //主窗口磁贴容器
		internal static const mainWindowMagnetArray: Array = new Array(new Sprite(), new Sprite(), new Sprite(), new Sprite()); //主窗口磁贴
		private static const mainWindowMagnetTimer: Timer = new Timer(50); //磁贴计时器
		private static var mainWindowMagnetIndex: uint = 0; //响应磁贴索引数
		private static var mainWindowMagnetTime: uint = 0; //磁贴计时器响应次数
		internal static const magnetWindowArray: Array = new Array(new Array(), new Array(), new Array(), new Array(), new Array()); //磁贴窗口列表
		internal static var wasMaximized: Boolean = false;
		private static var afterBoundsWidth: Number = 0;
		private static var afterBoundsHeight: Number = 0;
		private static var afterBoundsX: Number = 0;
		private static var afterBoundsY: Number = 0;
		private static var beforeBoundsWidth: Number = 0;
		private static var beforeBoundsHeight: Number = 0;
		private static var beforeBoundsX: Number = 0;
		private static var beforeBoundsY: Number = 0;
		private static const appDescriptor: XML = NativeApplication.nativeApplication.applicationDescriptor;
		private static const desNamespace: Namespace = appDescriptor.namespace();
		private static const appName: String = appDescriptor.desNamespace::filename;
		private static const appVer: String = appDescriptor.desNamespace::versionNumber;
		public static function get startPanel(): Sprite {
			return _startPanel;
		}
		public static function set startPanel(value: Sprite) {
			if (!_startPanel) {
				_startPanel = value;
			} else {
				throw (new SecurityError("Error: 不能在startPanel不为null的情况下为startPanel赋值。"));
			}
			/*
			if (mainFrame) {
				mainWindowContent.addChild(_startPanel);
			}*/
		}
		public static function get mainWindowMagnetTimerIsRunning(): Boolean {
			return mainWindowMagnetTimer.running;
		}
		internal static function get numContext(): uint {
			return mainWindowContexts.numChildren;
		}
		public static function get magnetWindows(): Array {
			return magnetWindowArray;
		}

		public static function initMainWindow(window: NativeWindow) {
			var i: uint;
			var j: uint;
			if (mainWindow) {
				//主窗口已存在
				throw (new SecurityError("Error: 在已经初始化主窗口的情况下尝试初始化主窗口。"));
			} else {
				//主窗口不存在（例如应用刚启动或被关闭）
				mainWindow = window;
				WindowPanel.parentWindow = mainWindow;
				/*
				mainWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, resizeFrame);
				mainWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeFrame);
				*/
				mainWindow.stage.addEventListener(Event.RESIZE, resizeFrame);
				mainWindow.addEventListener(NativeWindowBoundsEvent.MOVE, moveFrame);
				//mainWindow.menu = new NativeMenu(); //Error: Illegal window settings.
				mainWindow.addEventListener(Event.CLOSE, closeApplication);
			}
			//获取操作系统套系
			trace("当前操作系统：" + Capabilities.os);
			if (Capabilities.os.match("Windows")) {
				trace(appName + "将以" + OS.WIN + "逻辑运行。");
				operatorSystem = OS.WIN;
			} else if (Capabilities.os.match("Mac OS")) {
				trace(appName + "将以" + OS.MAC + "逻辑运行。");
				operatorSystem = OS.MAC;
			} else {
				trace("Exit: 不支持的操作系统。");
				NativeApplication.nativeApplication.exit(1);
			}
			ContextMenuBox.operatorSystem = operatorSystem;
			WindowPanel.operatorSystem = operatorSystem;
			//主窗口相关设置
			mainWindow.height = mainWindow.stage.fullScreenHeight * 2 / 3;
			mainWindow.width = mainWindow.stage.fullScreenWidth * 2 / 3;
			mainWindow.stage.align = StageAlign.TOP_LEFT;
			mainWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			mainWindow.stage.color = 0x313131;
			afterBoundsWidth = mainWindow.stage.stageWidth;
			afterBoundsHeight = mainWindow.stage.stageHeight;
			beforeBoundsWidth = mainWindow.stage.stageWidth;
			beforeBoundsHeight = mainWindow.stage.stageHeight;
			if (!mainFrame) {
				//主内容（访问主SWF）相关设置
				mainFrame = (mainWindow.stage.getChildAt(0) as Sprite);
				mainFrame.addChild(mainWindowContent);
				mainFrame.addChild(mainWindowBar);
				mainFrame.addChild(mainWindowButtons);
				mainFrame.addChild(mainWindowResizeCorner);
				mainWindowBar.addEventListener(MouseEvent.MOUSE_DOWN, moveMainWindow);
				mainWindowBar.addEventListener(MouseEvent.MOUSE_UP, movedMainWindow);
				mainWindowBar.doubleClickEnabled = true;
				mainWindowBar.addEventListener(MouseEvent.DOUBLE_CLICK, maxiMainWindow);
				//上下文菜单初步设置
				if (operatorSystem == OS.WIN) {
					mainWindowBar.addChild(mainWindowContexts);
					mainFrame.addEventListener(KeyboardEvent.KEY_DOWN, matchShortcutKey);
				}
				//主窗口图标部分
				mainWindowBar.addChild(mainWindowIcon);
				mainWindowIcon.width = 24;
				mainWindowIcon.height = 24;
				//主窗口控制按钮
				mainWindowButtons.addChild(mainWindowMiniButton);
				mainWindowButtons.addChild(mainWindowMaxiButton);
				mainWindowButtons.addChild(mainWindowCloseButton);
				mainWindowMiniButton.addEventListener(MouseEvent.CLICK, miniMainWindow);
				mainWindowMaxiButton.addEventListener(MouseEvent.CLICK, maxiMainWindow);
				mainWindowCloseButton.addEventListener(MouseEvent.CLICK, closeMainWindow);
				if (operatorSystem == OS.MAC) {
					mainWindowButtons.addEventListener(MouseEvent.MOUSE_OVER, macButtonOver);
					mainWindowButtons.addEventListener(MouseEvent.MOUSE_OUT, macButtonOut);
				}
				//主窗口缩放角
				mainWindowResizeCorner.graphics.beginFill(0x888888, 0);
				mainWindowResizeCorner.graphics.drawRect(0, 0, 12, 12);
				mainWindowResizeCorner.graphics.endFill();
				mainWindowResizeCorner.graphics.beginFill(0x888888);
				i = 0;
				while (i++ < 3) {
					j = 0;
					while (j++ < i) {
						mainWindowResizeCorner.graphics.drawCircle(9 - (j * 9 / 3) + 9 / 6, ((i - 1) * 9 / 3) + 9 / 6, 1);
					}
				}
				mainWindowResizeCorner.graphics.endFill();
				mainWindowResizeCorner.addEventListener(MouseEvent.MOUSE_DOWN, resizeMainWindow);
				//主窗口磁贴相关
				mainWindowContent.addChild(mainWindowMagnets);
				i = 0;
				while (i < mainWindowMagnetArray.length) {
					mainWindowMagnets.addChild(mainWindowMagnetArray[i++]);
				}
				mainWindowMagnetTimer.addEventListener(TimerEvent.TIMER, magnetTimerActivate);
				//移除Mac默认菜单
				if (operatorSystem == OS.MAC) {
					NativeApplication.nativeApplication.menu.removeItemAt(1);
					NativeApplication.nativeApplication.menu.removeItemAt(1);
					NativeApplication.nativeApplication.menu.removeItemAt(1);
				}
				//绘制主窗口
				updateMainWindow();
			}
			//将主内容添加至主窗口舞台
			mainWindow.stage.addChild(mainFrame);
			//主窗口名称
			mainWindow.title = appName + " " + appVer; //curDoc
			if (!mainWindow.active) {
				//激活主窗口
				mainWindow.activate();
			}
		}
		public static function updateAllWindows() {
			updateMainWindow();
		}
		private static function updateMainWindow() {
			var baseTop: Number = 0;
			var baseLeft: Number = 0;
			if (operatorSystem == OS.WIN) {
				mainWindowButtons.x = mainWindow.stage.stageWidth;
				mainWindowButtons.y = 0;
				if (mainWindow.displayState == NativeWindowDisplayState.MAXIMIZED) {
					baseTop = 6;
					baseLeft = 6;
				}
				mainWindowContexts.x = mainWindowIcon.x + mainWindowIcon.width + 10 + baseLeft;
				mainWindowContexts.y = 12.5 + baseTop;
				mainWindowIcon.x = 8 + baseLeft;
				mainWindowIcon.y = 8 + baseTop;
			} else if (operatorSystem == OS.MAC) {
				mainWindowButtons.x = 0;
				mainWindowButtons.y = 0;
				mainWindowIcon.x = (mainWindow.stage.stageWidth - mainWindowIcon.width) / 2;
				mainWindowIcon.y = 8;
			}
			//主窗口菜单栏部分
			mainWindowBar.graphics.clear();
			mainWindowBar.graphics.beginFill(0x444444);
			mainWindowBar.graphics.lineStyle(1, 0x000000);
			mainWindowBar.graphics.drawRect(0, 0, mainWindow.stage.stageWidth - 1 + baseLeft, 40 - 1 + baseTop);
			mainWindowBar.graphics.endFill();
			mainWindowBarHeight = mainWindowBar.height;
			drawWindowButton(mainWindowMiniButton, WindowButtonType.MINI_BUTTON, WindowButtonType.LEFT_ROUND);
			drawWindowButton(mainWindowMaxiButton, WindowButtonType.MAXI_BUTTON, WindowButtonType.NO_ROUND);
			drawWindowButton(mainWindowCloseButton, WindowButtonType.CLOSE_BUTTON, WindowButtonType.RIGHT_ROUND);
			//主窗口内容部分
			mainWindowContent.graphics.clear();
			mainWindowContent.y = mainWindowBar.height - 1;
			mainWindowContent.graphics.beginFill(0x444444);
			mainWindowContent.graphics.lineStyle(1, 0x000000);
			mainWindowContent.graphics.drawRect(0, 0, mainWindow.stage.stageWidth - 1, mainWindow.stage.stageHeight - mainWindowBar.height);
			mainWindowContent.graphics.moveTo(0, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
			mainWindowContent.graphics.lineTo(mainWindow.stage.stageWidth, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
			mainWindowContent.graphics.endFill();
			//主窗口磁贴
			updateMagnets();
			//主窗口缩放角部分
			if (mainWindow.displayState == NativeWindowDisplayState.MAXIMIZED && operatorSystem == OS.WIN) {
				mainWindowResizeCorner.visible = false;
			} else {
				mainWindowResizeCorner.visible = true;
			}
			mainWindowResizeCorner.x = mainWindow.stage.stageWidth - 12;
			mainWindowResizeCorner.y = mainWindow.stage.stageHeight - 12;
		}

		private static function drawWindowButton(button: Sprite, buttonType: String, roundType: String = "no round"): Sprite {
			var baseRight: Number = -3;
			var baseTop: Number = 0;
			if (operatorSystem == OS.WIN) {
				if (mainWindow.displayState == NativeWindowDisplayState.MAXIMIZED) {
					baseRight = -7;
					baseTop = 6;
				}
				button.graphics.clear();
				switch (buttonType) {
					case WindowButtonType.MINI_BUTTON:
						button.graphics.moveTo(-107.5 + baseRight, 0);
						button.graphics.beginFill(0x444444);
						button.graphics.lineStyle(1, 0x000000);
						button.graphics.lineTo(-80 + baseRight, 0);
						switch (roundType) {
							case WindowButtonType.RIGHT_ROUND:
								button.graphics.lineTo(-80 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-80 + baseRight, 20 + baseTop, -82.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 0);
								break;
							case WindowButtonType.LEFT_ROUND:
								button.graphics.lineTo(-80 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-105 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-107.5 + baseRight, 20 + baseTop, -107.5 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 0);
								break;
							case WindowButtonType.DOUBLE_ROUND:
								button.graphics.lineTo(-80 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-80 + baseRight, 20 + baseTop, -82.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-105 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-107.5 + baseRight, 20 + baseTop, -107.5 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 0);
								break;
							case WindowButtonType.NO_ROUND:
								button.graphics.lineTo(-80 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-107.5 + baseRight, 0);
								break;
						}
						button.graphics.beginFill(0xdddddd);
						button.graphics.lineStyle();
						button.graphics.drawRect(-98.4 + baseRight, 12 + baseTop, 9.1, 3);
						button.graphics.endFill();
						break;
					case WindowButtonType.MAXI_BUTTON:
						button.graphics.moveTo(-80 + baseRight, 0);
						button.graphics.beginFill(0x444444);
						button.graphics.lineStyle(1, 0x000000);
						button.graphics.lineTo(-52.5 + baseRight, 0);
						switch (roundType) {
							case WindowButtonType.RIGHT_ROUND:
								button.graphics.lineTo(-52.5 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-52.5 + baseRight, 20 + baseTop, -55 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 0);
								break;
							case WindowButtonType.LEFT_ROUND:
								button.graphics.lineTo(-52.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-77.5 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-80 + baseRight, 20 + baseTop, -80 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 0);
								break;
							case WindowButtonType.DOUBLE_ROUND:
								button.graphics.lineTo(-52.5 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-52.5 + baseRight, 20 + baseTop, -55 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-77.5 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-80 + baseRight, 20 + baseTop, -80 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 0);
								break;
							case WindowButtonType.NO_ROUND:
								button.graphics.lineTo(-52.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-80 + baseRight, 0);
								break;
						}
						if (mainWindow.displayState == NativeWindowDisplayState.MAXIMIZED) {
							button.graphics.beginFill(0xdddddd);
							button.graphics.lineStyle();
							button.graphics.drawRect(-68.22 + baseRight, 6 + baseTop, 7.85, 8);
							button.graphics.endFill();
							button.graphics.beginFill(0x444444);
							button.graphics.drawRect(-66.25 + baseRight, 8 + baseTop, 3.85, 4);
							button.graphics.endFill();
							button.graphics.beginFill(0xdddddd);
							button.graphics.drawRect(-72.14 + baseRight, 9 + baseTop, 7.85, 7);
							button.graphics.endFill();
							button.graphics.beginFill(0x444444);
							button.graphics.drawRect(-70.14 + baseRight, 11 + baseTop, 3.85, 3);
							button.graphics.endFill();
						} else if (mainWindow.displayState == NativeWindowDisplayState.NORMAL) {
							button.graphics.beginFill(0xdddddd);
							button.graphics.lineStyle();
							button.graphics.drawRect(-70.8 + baseRight, 7 + baseTop, 9.1, 8);
							button.graphics.endFill();
							button.graphics.beginFill(0x444444);
							button.graphics.lineStyle();
							button.graphics.drawRect(-68.8 + baseRight, 9 + baseTop, 5.1, 4);
							button.graphics.endFill();
						}
						break;
					case WindowButtonType.CLOSE_BUTTON:
						button.graphics.moveTo(-52.5 + baseRight, 0);
						button.graphics.beginFill(0x444444);
						button.graphics.lineStyle(1, 0x000000);
						button.graphics.lineTo(-5 + baseRight, 0);
						switch (roundType) {
							case WindowButtonType.RIGHT_ROUND:
								button.graphics.lineTo(-5 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-5 + baseRight, 20 + baseTop, -7.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 0);
								break;
							case WindowButtonType.LEFT_ROUND:
								button.graphics.lineTo(-5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-50 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-52.5 + baseRight, 20 + baseTop, -52.5 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 0);
								break;
							case WindowButtonType.DOUBLE_ROUND:
								button.graphics.lineTo(-5 + baseRight, 17.5 + baseTop);
								button.graphics.curveTo(-5 + baseRight, 20 + baseTop, -7.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-50 + baseRight, 20 + baseTop);
								button.graphics.curveTo(-52.5 + baseRight, 20 + baseTop, -52.5 + baseRight, 17.5 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 0);
								break;
							case WindowButtonType.NO_ROUND:
								button.graphics.lineTo(-5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 20 + baseTop);
								button.graphics.lineTo(-52.5 + baseRight, 0);
								break;
						}
						button.graphics.endFill();
						button.graphics.beginFill(0xdddddd);
						button.graphics.lineStyle();
						button.graphics.moveTo(-34.5 + baseRight, 6 + baseTop);
						button.graphics.lineTo(-30.5 + baseRight, 6 + baseTop);
						button.graphics.lineTo(-28.5 + baseRight, 8 + baseTop);
						button.graphics.lineTo(-26.5 + baseRight, 6 + baseTop);
						button.graphics.lineTo(-22.5 + baseRight, 6 + baseTop);
						button.graphics.lineTo(-26.5 + baseRight, 10 + baseTop);
						button.graphics.lineTo(-22.5 + baseRight, 14 + baseTop);
						button.graphics.lineTo(-26.5 + baseRight, 14 + baseTop);
						button.graphics.lineTo(-28.5 + baseRight, 12 + baseTop);
						button.graphics.lineTo(-30.5 + baseRight, 14 + baseTop);
						button.graphics.lineTo(-34.5 + baseRight, 14 + baseTop);
						button.graphics.lineTo(-30.5 + baseRight, 10 + baseTop);
						button.graphics.lineTo(-34.5 + baseRight, 6 + baseTop);
						button.graphics.endFill();
						break;
				}
			} else if (operatorSystem == OS.MAC) {
				button.graphics.clear();
				switch (buttonType) {
					case WindowButtonType.MINI_BUTTON:
						button.graphics.beginFill(0xf3be4e);
						button.graphics.lineStyle(1, 0xd09b38);
						button.graphics.drawCircle(34, 20, 6);
						button.graphics.endFill();
						break;
					case WindowButtonType.MAXI_BUTTON:
						button.graphics.beginFill(0x63c554);
						button.graphics.lineStyle(1, 0x4ca237);
						button.graphics.drawCircle(54, 20, 6);
						button.graphics.endFill();
						break;
					case WindowButtonType.CLOSE_BUTTON:
						button.graphics.beginFill(0xeb695e);
						button.graphics.lineStyle(1, 0xbb4a3e);
						button.graphics.drawCircle(14, 20, 6);
						button.graphics.endFill();
						break;
				}
			}
			return button;
		}
		private static function macButtonOver(e: MouseEvent) {
			mainWindowMiniButton.graphics.beginFill(0xf3be4e);
			mainWindowMiniButton.graphics.lineStyle(1, 0xd09b38);
			mainWindowMiniButton.graphics.drawCircle(34, 20, 6);
			mainWindowMiniButton.graphics.endFill();
			mainWindowMiniButton.graphics.lineStyle(1, 0xc18c35);
			mainWindowMiniButton.graphics.moveTo(34 - 3.5, 20);
			mainWindowMiniButton.graphics.lineTo(34 + 3.5, 20);
			mainWindowMaxiButton.graphics.beginFill(0x63c554);
			mainWindowMaxiButton.graphics.lineStyle(1, 0x4ca237);
			mainWindowMaxiButton.graphics.drawCircle(54, 20, 6);
			mainWindowMaxiButton.graphics.endFill();
			mainWindowMaxiButton.graphics.lineStyle(1, 0x2a6118);
			mainWindowMaxiButton.graphics.moveTo(54, 20 - 3.5);
			mainWindowMaxiButton.graphics.lineTo(54, 20 + 3.5);
			mainWindowMaxiButton.graphics.moveTo(54 + 3.5, 20);
			mainWindowMaxiButton.graphics.lineTo(54 - 3.5, 20);
			mainWindowCloseButton.graphics.beginFill(0xeb695e);
			mainWindowCloseButton.graphics.lineStyle(1, 0xbb4a3e);
			mainWindowCloseButton.graphics.drawCircle(14, 20, 6);
			mainWindowCloseButton.graphics.endFill();
			mainWindowCloseButton.graphics.lineStyle(1, 0x68110a);
			mainWindowCloseButton.graphics.moveTo(14 - 1.75 / Math.sin(45 * Math.PI / 180), 20 - 1.75 / Math.sin(45 * Math.PI / 180));
			mainWindowCloseButton.graphics.lineTo(14 + 1.75 / Math.sin(45 * Math.PI / 180), 20 + 1.75 / Math.sin(45 * Math.PI / 180));
			mainWindowCloseButton.graphics.moveTo(14 + 1.75 / Math.sin(45 * Math.PI / 180), 20 - 1.75 / Math.sin(45 * Math.PI / 180));
			mainWindowCloseButton.graphics.lineTo(14 - 1.75 / Math.sin(45 * Math.PI / 180), 20 + 1.75 / Math.sin(45 * Math.PI / 180));
		}
		private static function macButtonOut(e: MouseEvent) {
			drawWindowButton(mainWindowMiniButton, WindowButtonType.MINI_BUTTON, WindowButtonType.NO_ROUND);
			drawWindowButton(mainWindowMaxiButton, WindowButtonType.MAXI_BUTTON, WindowButtonType.NO_ROUND);
			drawWindowButton(mainWindowCloseButton, WindowButtonType.CLOSE_BUTTON, WindowButtonType.NO_ROUND);
		}

		private static function magnetTimerActivate(e: TimerEvent) {
			const maxTime: uint = 15;
			updateMagnets();
			if (maxTime > mainWindowMagnetTime) {
				mainWindowMagnetTime++;
			}
			(mainWindowMagnetArray[mainWindowMagnetIndex] as Sprite).graphics.beginFill(0x6db3f1, mainWindowMagnetTime / maxTime);
			switch (mainWindowMagnetIndex) {
				case 0:
					(mainWindowMagnetArray[0] as Sprite).graphics.drawRect(0, mainWindow.stage.stageHeight - mainWindowBar.height - 15, mainWindow.stage.stageWidth, -20 * mainWindowMagnetTime / maxTime);
					break;
				case 1:
					(mainWindowMagnetArray[1] as Sprite).graphics.drawRect(0, 0, 20 * mainWindowMagnetTime / maxTime, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
					break;
				case 2:
					(mainWindowMagnetArray[2] as Sprite).graphics.drawRect(mainWindow.stage.stageWidth, 0, -20 * mainWindowMagnetTime / maxTime, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
					break;
				case 3:
					(mainWindowMagnetArray[3] as Sprite).graphics.drawRect(0, 0, mainWindow.stage.stageWidth, 20 * mainWindowMagnetTime / maxTime);
					break;
			}
			(mainWindowMagnetArray[mainWindowMagnetIndex] as Sprite).graphics.endFill();
		}
		internal static function magnetTimerStart(index: uint): Boolean {
			if (index < mainWindowMagnetArray.length) {
				mainWindowMagnetIndex = index;
			} else {
				throw (new SecurityError("Error: 意料之外的索引位置。"));
			}
			mainWindowMagnetTimer.start();
			return true;
		}
		internal static function magnetTimerStop(): Boolean {
			mainWindowMagnetTime = 0;
			updateMagnets();
			mainWindowMagnetTimer.stop();
			mainWindowMagnetTimer.reset();
			return true;
		}
		private static function updateMagnets() {
			(mainWindowMagnetArray[0] as Sprite).graphics.clear();
			(mainWindowMagnetArray[0] as Sprite).graphics.beginFill(0xffffff, 0);
			(mainWindowMagnetArray[0] as Sprite).graphics.drawRect(0, mainWindow.stage.stageHeight - mainWindowBar.height - 15, mainWindow.stage.stageWidth, -20);
			(mainWindowMagnetArray[0] as Sprite).graphics.endFill();
			(mainWindowMagnetArray[1] as Sprite).graphics.clear();
			(mainWindowMagnetArray[1] as Sprite).graphics.beginFill(0xffffff, 0);
			(mainWindowMagnetArray[1] as Sprite).graphics.drawRect(0, 0, 20, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
			(mainWindowMagnetArray[1] as Sprite).graphics.endFill();
			(mainWindowMagnetArray[2] as Sprite).graphics.clear();
			(mainWindowMagnetArray[2] as Sprite).graphics.beginFill(0xffffff, 0);
			(mainWindowMagnetArray[2] as Sprite).graphics.drawRect(mainWindow.stage.stageWidth, 0, -20, mainWindow.stage.stageHeight - mainWindowBar.height - 15);
			(mainWindowMagnetArray[2] as Sprite).graphics.endFill();
			(mainWindowMagnetArray[3] as Sprite).graphics.clear();
			(mainWindowMagnetArray[3] as Sprite).graphics.beginFill(0xffffff, 0);
			(mainWindowMagnetArray[3] as Sprite).graphics.drawRect(0, 0, mainWindow.stage.stageWidth, 20);
			(mainWindowMagnetArray[3] as Sprite).graphics.endFill();
		}

		internal static function isMainFrame(frame: Sprite): Boolean {
			return frame == mainFrame;
		}
		internal static function addMainWindowContext(contextBox: ContextMenuBox) {
			var i: uint = 0;
			//if (operatorSystem == OS.WIN) {
			mainWindowContexts.addChild(contextBox);
			mainWindowContexts.getChildAt(0).x = 0;
			i++;
			while (i < mainWindowContexts.numChildren) {
				mainWindowContexts.getChildAt(i).x = i * 55;
				i++;
			}
			//}
		}
		internal static function removeMainWindowContext(contextBox: ContextMenuBox) {
			var i: uint = 0;
			while (i < mainWindowContexts.numChildren) {
				if (mainWindowContexts.getChildAt(i) == contextBox) {
					mainWindowContexts.removeChildAt(i);
					break;
				}
				i++;
			}
			i = 0;
			while (i < mainWindowContexts.numChildren) {
				mainWindowContexts.getChildAt(i).x = i * 55;
				i++;
			}
		}
		internal static function getMainWindowContextAt(index: uint): ContextMenuBox {
			var box: ContextMenuBox;
			if (index < mainWindowContexts.numChildren && mainWindowContexts.getChildAt(index) is ContextMenuBox) {
				box = mainWindowContexts.getChildAt(index) as ContextMenuBox;
			} else {
				throw (new SecurityError("Error: 意料之外的索引位置。"));
			}
			return box;
		}

		private static function matchShortcutKey(e: KeyboardEvent) {
			var s: String;
			var i: uint;
			var j: uint;
			if (e.altKey && !e.ctrlKey && !e.shiftKey) {
				i = 0;
				//if (operatorSystem == OS.WIN) {
				while (i < mainWindowContexts.numChildren) {
					if (e.charCode == (mainWindowContexts.getChildAt(i) as ContextMenuBox).shortcutKey.charCodeAt(0)) {
						(mainWindowContexts.getChildAt(i) as ContextMenuBox).showMyMenu(e);
						break;
					}
					i++;
				}
				//}
			}
		}

		public static function changeMainWindowTitle(fileName: String = null) {
			if (!fileName) {
				mainWindow.title = appName + " " + appVer;
			} else {
				mainWindow.title = fileName + " - " + appName + " " + appVer;
			}
		}

		private static function resizeFrame(e: Event) {
			beforeBoundsX = afterBoundsX;
			beforeBoundsY = afterBoundsY;
			afterBoundsX = mainWindow.x;
			afterBoundsY = mainWindow.y;
			updateMainWindow();
			WindowPanel.resetMagneticWindows();
		}
		private static function moveFrame(e: NativeWindowBoundsEvent) {
			beforeBoundsX = afterBoundsX;
			beforeBoundsY = afterBoundsY;
			afterBoundsX = mainWindow.x;
			afterBoundsY = mainWindow.y;
			WindowPanel.resetMagneticWindows();
		}

		private static function moveMainWindow(e: MouseEvent) {
			mainWindow.startMove();
		}
		private static function movedMainWindow(e: MouseEvent) {
			WindowPanel.resetMagneticWindows();
		}
		private static function miniMainWindow(e: MouseEvent) {
			mainWindow.minimize();
		}
		private static function maxiMainWindow(e: MouseEvent) {
			if (mainWindow.displayState == NativeWindowDisplayState.MAXIMIZED) {
				mainWindow.restore();
			} else if (mainWindow.displayState == NativeWindowDisplayState.NORMAL) {
				mainWindow.maximize();
			}
		}
		private static function resizeMainWindow(e: MouseEvent) {
			mainWindow.startResize();
		}
		private static function closeMainWindow(e: MouseEvent) {
			mainWindow.close();
		}
		private static function closeApplication(e: Event) {
			trace("Exit: 用户通过关闭主窗口退出" + appName + " " + appVer + "。");
			NativeApplication.nativeApplication.exit(0);
		}
	}

}