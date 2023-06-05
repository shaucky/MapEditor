package xiaoChi {
	import xiaoChi.WindowController;
	import xiaoChi.WindowPanelDirection;
	import xiaoChi.OS;
	import flash.display.Sprite;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.MouseEvent;
	import flash.display.NativeWindowType;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.NativeWindowDisplayState;

	public class WindowPanel extends Sprite {
		internal static var parentWindow: NativeWindow;
		internal static var operatorSystem: String;
		private static var allWindowsLocked: Boolean = false;
		private const bar: Sprite = new Sprite();
		public const resizeCorner: Sprite = new Sprite();
		internal const windowMagnets: Sprite = new Sprite();
		internal const windowMagnetArray: Array = new Array(new Sprite(), new Sprite(), new Sprite(), new Sprite());
		public var isMagnetic: Boolean = false;
		internal const windowMagnetTimer: Timer = new Timer(50);
		private var windowMagnetIndex: uint = 0;
		private var windowMagnetTime: uint = 0;
		public var direct: String = "none";
		private const lockCurtain: Sprite = new Sprite();
		public var defaultWidth: Number = 250;
		public var defaultHeight: Number = 400;
		public var oriWidth: Number;
		public var oriHeight: Number;
		private var mouseDownEvent: MouseEvent;
		private const _mask: Sprite = new Sprite();
		private var _window: NativeWindow;
		private const _content: Sprite = new Sprite();
		public function get window(): NativeWindow {
			return _window;
		}
		public function set content(value: Sprite) {
			while (_content.numChildren) {
				_content.removeChildAt(0);
			}
			_content.addChild(value);
		}
		public function get content(): Sprite {
			var s: Sprite = null;
			if (_content.numChildren) {
				s = _content.getChildAt(0) as Sprite;
			}
			return s;
		}

		public function WindowPanel() {
			var i: uint;
			var j: uint;
			_window = createNewWindow();
			_window.addEventListener(Event.CLOSE, windowClose);
			_window.addEventListener(NativeWindowBoundsEvent.MOVE, windowMove);
			_window.stage.addEventListener(Event.RESIZE, windowResize);
			_window.stage.addChild(this);
			_window.width = defaultWidth;
			_window.height = defaultHeight;
			//子窗口标题栏相关
			addChildAt(bar, 0);
			bar.addChild(getChildAt(1));
			bar.x = 0;
			bar.y = 0;
			bar.graphics.beginGradientFill(GradientType.LINEAR, new Array(0x303030, 0x2a2a2a), new Array(1, 1), new Array(0, 255), new Matrix(Math.cos(90 * Math.PI / 180), Math.sin(90 * Math.PI / 180), -Math.sin(90 * Math.PI / 180), Math.cos(90 * Math.PI / 180)));
			bar.graphics.lineStyle(0x000000);
			bar.graphics.drawRect(0, 0, _window.width - 1, 20);
			bar.graphics.endFill();
			bar.getChildAt(0).x = 10;
			bar.getChildAt(0).width = _window.width - 11;
			//子窗口面板相关
			this.graphics.beginFill(0x444444);
			this.graphics.lineStyle(0x000000);
			this.graphics.drawRect(0, 20, _window.width - 1, _window.height - 20 - 1);
			this.graphics.endFill();
			//子窗口内容相关
			addChild(_content);
			addChild(_mask);
			_mask.graphics.beginFill(0xffffff);
			_mask.graphics.drawRect(0, 20, _window.width - 1, _window.height - 20 - 1);
			_mask.graphics.endFill();
			_content.mask = _mask;
			_content.x = 0;
			_content.y = 20;
			//子窗口磁贴相关
			addChild(windowMagnets);
			windowMagnets.x = 0;
			windowMagnets.y = bar.height;
			i = 0;
			while (windowMagnetArray.length > i) {
				windowMagnets.addChild(windowMagnetArray[i++]);
			}
			windowMagnetTimer.addEventListener(TimerEvent.TIMER, magnetTimerActivate);
			//子窗口缩放角相关
			addChild(resizeCorner);
			resizeCorner.x = _window.width - 15;
			resizeCorner.y = _window.height - 15;
			resizeCorner.graphics.beginFill(0x888888, 0);
			resizeCorner.graphics.drawRect(0, 0, 15, 15);
			resizeCorner.graphics.endFill();
			resizeCorner.graphics.beginFill(0x888888);
			i = 0;
			while (i++ < 3) {
				j = 0;
				while (j++ < i) {
					resizeCorner.graphics.drawCircle(9 - (j * 9 / 3) + 9 / 6, ((i - 1) * 9 / 3) + 9 / 6, 1);
				}
			}
			resizeCorner.graphics.endFill();
			//禁止交互功能
			addChild(lockCurtain);
			lockCurtain.visible = allWindowsLocked;
			lockCurtain.graphics.beginFill(0xffffff, 0);
			lockCurtain.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			lockCurtain.graphics.endFill();
			//激活本窗口
			//_window.activate(); //测试用
			bar.addEventListener(MouseEvent.MOUSE_DOWN, moveThisReady);
			resizeCorner.addEventListener(MouseEvent.MOUSE_DOWN, resizeWindow);
		}
		public function createNewWindow(): NativeWindow {
			var options: NativeWindowInitOptions = new NativeWindowInitOptions();
			var newWindow: NativeWindow;
			if (!parentWindow) {
				throw (new Error("Error: WindowPanel类的parentWindow属性为null。"));
			}
			options.maximizable = false;
			options.minimizable = false;
			options.owner = parentWindow;
			options.resizable = false;
			options.systemChrome = NativeWindowSystemChrome.NONE;
			options.transparent = true;
			options.type = NativeWindowType.LIGHTWEIGHT;
			newWindow = new NativeWindow(options);
			newWindow.stage.align = StageAlign.TOP_LEFT;
			newWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			return newWindow;
		}

		public function show() {
			_window.visible = true;
			oriWidth = _window.width;
			oriHeight = _window.height;
		}
		public function hide() {
			var i: uint;
			var j: uint;
			_window.visible = false;
			i = 0;
			wh: while (i < WindowController.magnetWindowArray.length) {
				j = 0;
				while (j < (WindowController.magnetWindowArray[i] as Array).length) {
					if (WindowController.magnetWindowArray[i][j] as WindowPanel == this) {
						(WindowController.magnetWindowArray[i] as Array).removeAt(j);
						resetMagneticWindows();
						direct = WindowPanelDirection.NONE;
						break wh;
					}
					j++;
				}
				i++;
			}
			isMagnetic = false;
			_window.width = oriWidth;
			_window.height = oriHeight;
			resizeCorner.visible = true;
		}

		private function magnetTimerActivate(e: TimerEvent) {
			const maxTime: uint = 15;
			var stageHeight: Number = stage.stageHeight;
			var stageWidth: Number = stage.stageWidth;
			if (direct == WindowPanelDirection.ROW && (windowMagnetIndex == 0 || windowMagnetIndex == 3)) {
				updateMagnets();
				if (maxTime > windowMagnetTime) {
					windowMagnetTime++;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.beginFill(0x6db3f1, windowMagnetTime / maxTime);
				switch (windowMagnetIndex) {
					case 0:
						(windowMagnetArray[0] as Sprite).graphics.drawRect(0, stageHeight - bar.height, stageWidth, -20 * windowMagnetTime / maxTime);
						break;
					case 3:
						(windowMagnetArray[3] as Sprite).graphics.drawRect(0, 0, stageWidth, 20 * windowMagnetTime / maxTime);
						break;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.endFill();
			} else if (direct == WindowPanelDirection.COL && (windowMagnetIndex == 1 || windowMagnetIndex == 2)) {
				updateMagnets();
				if (maxTime > windowMagnetTime) {
					windowMagnetTime++;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.beginFill(0x6db3f1, windowMagnetTime / maxTime);
				switch (windowMagnetIndex) {
					case 1:
						(windowMagnetArray[1] as Sprite).graphics.drawRect(0, 0, 20 * windowMagnetTime / maxTime, stageHeight - bar.height);
						break;
					case 2:
						(windowMagnetArray[2] as Sprite).graphics.drawRect(stageWidth, 0, -20 * windowMagnetTime / maxTime, stageHeight - bar.height);
						break;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.endFill();
			} else if (direct == WindowPanelDirection.ALL) {
				updateMagnets();
				if (maxTime > windowMagnetTime) {
					windowMagnetTime++;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.beginFill(0x6db3f1, windowMagnetTime / maxTime);
				switch (windowMagnetIndex) {
					case 0:
						(windowMagnetArray[0] as Sprite).graphics.drawRect(0, stageHeight - bar.height, stageWidth, -20 * windowMagnetTime / maxTime);
						break;
					case 1:
						(windowMagnetArray[1] as Sprite).graphics.drawRect(0, 0, 20 * windowMagnetTime / maxTime, stageHeight - bar.height);
						break;
					case 2:
						(windowMagnetArray[2] as Sprite).graphics.drawRect(stageWidth, 0, -20 * windowMagnetTime / maxTime, stageHeight - bar.height);
						break;
					case 3:
						(windowMagnetArray[3] as Sprite).graphics.drawRect(0, 0, stageWidth, 20 * windowMagnetTime / maxTime);
						break;
				}
				(windowMagnetArray[windowMagnetIndex] as Sprite).graphics.endFill();
			}
		}
		internal function magnetTimerStart(index: uint): Boolean {
			if (index < windowMagnetArray.length) {
				windowMagnetIndex = index;
			} else {
				throw (new SecurityError("Error: 意料之外的索引位置。"));
			}
			windowMagnetTimer.start();
			return true;
		}
		internal function magnetTimerStop(): Boolean {
			windowMagnetTime = 0;
			updateMagnets();
			windowMagnetTimer.stop();
			windowMagnetTimer.reset();
			return true;
		}
		private function updateMagnets() {
			var stageHeight: Number = stage.stageHeight;
			var stageWidth: Number = stage.stageWidth;
			(windowMagnetArray[0] as Sprite).graphics.clear();
			(windowMagnetArray[0] as Sprite).graphics.beginFill(0xffffff, 0);
			(windowMagnetArray[0] as Sprite).graphics.drawRect(0, stageHeight - bar.height, stageWidth, -20);
			(windowMagnetArray[0] as Sprite).graphics.endFill();
			(windowMagnetArray[1] as Sprite).graphics.clear();
			(windowMagnetArray[1] as Sprite).graphics.beginFill(0xffffff, 0);
			(windowMagnetArray[1] as Sprite).graphics.drawRect(0, 0, 20, stageHeight - bar.height);
			(windowMagnetArray[1] as Sprite).graphics.endFill();
			(windowMagnetArray[2] as Sprite).graphics.clear();
			(windowMagnetArray[2] as Sprite).graphics.beginFill(0xffffff, 0);
			(windowMagnetArray[2] as Sprite).graphics.drawRect(stageWidth, 0, -20, stageHeight - bar.height);
			(windowMagnetArray[2] as Sprite).graphics.endFill();
			(windowMagnetArray[3] as Sprite).graphics.clear();
			(windowMagnetArray[3] as Sprite).graphics.beginFill(0xffffff, 0);
			(windowMagnetArray[3] as Sprite).graphics.drawRect(0, 0, stageWidth, 20);
			(windowMagnetArray[3] as Sprite).graphics.endFill();
		}
		private static function putIntoParentWindow(me: WindowPanel, neighbor: WindowPanel = null, magnetIndex: uint = 0) {
			var i: uint;
			var j: uint;
			if (neighbor) {
				neighbor.windowMagnets.visible = false;
				neighbor.magnetTimerStop();
				if (WindowController.magnetWindowArray[0][0] == neighbor) {
					switch (magnetIndex) {
						case 0: //下
							(WindowController.magnetWindowArray[magnetIndex + 1] as Array).unshift(me);
							me.direct = WindowPanelDirection.ROW;
							break;
						case 1: //左
							(WindowController.magnetWindowArray[magnetIndex + 1] as Array).push(me);
							me.direct = WindowPanelDirection.COL;
							break;
						case 2: //右
							(WindowController.magnetWindowArray[magnetIndex + 1] as Array).unshift(me);
							me.direct = WindowPanelDirection.COL;
							break;
						case 3: //上
							(WindowController.magnetWindowArray[magnetIndex + 1] as Array).push(me);
							me.direct = WindowPanelDirection.ROW;
							break;
					}
					me.oriWidth = me.window.width;
					me.oriHeight = me.window.height;
					me.isMagnetic = true;
					me.window.orderInFrontOf(parentWindow);
				} else {
					i = 0;
					wh: while (i < WindowController.magnetWindowArray.length) {
						j = 0;
						while (j < WindowController.magnetWindowArray[i].length) {
							if (WindowController.magnetWindowArray[i][j] == neighbor) {
								break wh;
							}
							j++;
						}
						i++;
					}
					switch (i - 1) {
						case 0: //下
							if (magnetIndex == 3) {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j, me);
							} else {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j + 1, me);
							}
							me.direct = WindowPanelDirection.ROW;
							break;
						case 1: //左
							if (magnetIndex == 1) {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j, me);
							} else {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j + 1, me);
							}
							me.direct = WindowPanelDirection.COL;
							break;
						case 2: //右
							if (magnetIndex == 1) {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j, me);
							} else {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j + 1, me);
							}
							me.direct = WindowPanelDirection.COL;
							break;
						case 3: //上
							if (magnetIndex == 3) {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j, me);
							} else {
								(WindowController.magnetWindowArray[i] as Array).insertAt(j + 1, me);
							}
							me.direct = WindowPanelDirection.ROW;
							break;
					}
					me.oriWidth = me.window.width;
					me.oriHeight = me.window.height;
					me.isMagnetic = true;
					me.window.orderInFrontOf(parentWindow);
				}
				import flash.events.Event;
				import flash.events.FocusEvent;
				import xiaoChi.WindowPanel;

			} else {
				WindowController.magnetTimerStop();
				(WindowController.magnetWindowArray[0] as Array).push(me);
				me.direct = WindowPanelDirection.ALL;
				me.oriWidth = me.window.width;
				me.oriHeight = me.window.height;
				me.window.x = parentWindow.x + 0;
				me.window.y = parentWindow.y + WindowController.mainWindowBarHeight - 1;
				me.window.width = parentWindow.width;
				me.window.height = parentWindow.height - WindowController.mainWindowBarHeight;
				me.isMagnetic = true;
				me.window.orderInFrontOf(parentWindow);
			}
			resetMagneticWindows();
		}
		public static function resetMagneticWindows() {
			var arrayLength: uint;
			var tempArray: Array;
			var centerWidest: WindowPanel; //最宽的子窗口面板
			var centerX: Number = parentWindow.x;
			var accHeight: Number = 0; //累积高度
			var ttlHeight: Number = 0; //总计高度
			var accWidth: Number = 0; //累积宽度
			var ttlWidth: Number = 0; //总计宽度
			const magnetTotalHeight: Number = parentWindow.height - WindowController.mainWindowBarHeight - 15;
			var i: uint;
			tempArray = new Array(); //新建临时数组
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[1] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[1][i]); //将下行子窗口存入临时数组
				i++;
			}
			tempArray.push(WindowController.magnetWindowArray[0][0]); //将中心子窗口存入临时数组
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[4] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[4][i]); //将上行子窗口存入临时数组
				i++;
			}
			tempArray.sort(sortOnWidth);
			centerWidest = (tempArray[0] as WindowPanel); //取这三行的最宽子窗口
			tempArray = new Array(); //新建临时数组
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[2] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[2][i]); //将左列子窗口存入临时数组
				i++;
			}
			if (centerWidest) {
				tempArray.push(centerWidest); //将中间最宽子窗口存入数组
			}
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[3] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[3][i]); //将右列子窗口存入临时数组
				i++;
			}
			i = 0;
			arrayLength = tempArray.length
			while (arrayLength > i) {
				ttlWidth += (tempArray[i] as WindowPanel).defaultWidth;
				i++;
			}
			tempArray.forEach(setWindowWidth); //对外三列子窗口设置宽度
			if (centerWidest) {
				centerX = centerWidest.window.x;
			}
			tempArray = new Array(); //新建临时数组
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[4] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[4][i]); //将上行子窗口存入临时数组
				i++;
			}
			if (WindowController.magnetWindowArray[0][0]) {
				tempArray.push(WindowController.magnetWindowArray[0][0]); //将中心子窗口存入临时数组
			}
			i = 0;
			arrayLength = (WindowController.magnetWindowArray[1] as Array).length;
			while (i < arrayLength) {
				tempArray.push(WindowController.magnetWindowArray[1][i]); //将下行子窗口存入临时数组
				i++;
			}
			i = 0;
			arrayLength = tempArray.length;
			while (arrayLength > i) {
				ttlHeight += (tempArray[i] as WindowPanel).defaultHeight;
				i++;
			}
			tempArray.forEach(setWindowHeight); //对内三行子窗口设置高度
			function setWindowHeight(wp: WindowPanel, index: int, array: Array) {
				wp.window.x = centerX;
				wp.window.y = parentWindow.y + WindowController.mainWindowBarHeight - 1 + accHeight;
				wp.window.width = centerWidest.window.width;
				wp.window.height = magnetTotalHeight * wp.defaultHeight / ttlHeight;
				accHeight += wp.window.height;
			}
			function setWindowWidth(wp: WindowPanel, index: int, array: Array) {
				wp.window.x = parentWindow.x + accWidth;
				wp.window.y = parentWindow.y + WindowController.mainWindowBarHeight - 1;
				wp.window.width = parentWindow.width * wp.defaultWidth / ttlWidth;
				wp.window.height = magnetTotalHeight;
				accWidth += wp.window.width;
			}
		}
		private static function sortOnWidth(a: WindowPanel, b: WindowPanel): Number {
			var result: Number;
			if (a.defaultWidth < b.defaultWidth) {
				return 1;
			} else if (a.defaultWidth > b.defaultWidth) {
				return -1;
			} else {
				return 0;
			}
		}
		private static function sortOnHeight(a: WindowPanel, b: WindowPanel): Number {
			var result: Number;
			if (a.defaultHeight < b.defaultHeight) {
				return 1;
			} else if (a.defaultHeight > b.defaultHeight) {
				return -1;
			} else {
				return 0;
			}
		}

		public static function lockUpAllWindows(): Boolean {
			var list: Vector.<NativeWindow> = parentWindow.listOwnedWindows();
			var i: uint = 0;
			allWindowsLocked = !allWindowsLocked;
			while (i < list.length) {
				(list[i].stage.getChildAt(0) as WindowPanel).lockCurtain.visible = allWindowsLocked;
				i++;
			}
			return allWindowsLocked;
		}

		private function windowClose(e: Event) {
			_window.removeEventListener(Event.CLOSE, windowClose);
			_window.removeEventListener(NativeWindowBoundsEvent.MOVE, windowMove);
			_window = null;
		}
		private function windowMove(e: NativeWindowBoundsEvent) {
			var maxIndex: uint = WindowController.mainWindowMagnetArray.length;
			var i: uint;
			var j: uint;
			var k: uint;
			if (mouseDownEvent) {
				if (!(WindowController.magnetWindowArray[0] as Array).length) {
					i = 0;
					while (maxIndex > i) {
						if ((WindowController.mainWindowMagnetArray[i] as Sprite).hitTestPoint(e.afterBounds.x - parentWindow.x + mouseDownEvent.stageX, e.afterBounds.y - parentWindow.y + mouseDownEvent.stageY, true)) {
							if (!WindowController.mainWindowMagnetTimerIsRunning) {
								WindowController.magnetTimerStart(i); //触发主窗口磁贴
							}
							break;
						} else {
							i++;
						}
					}
					if (i == maxIndex) {
						WindowController.magnetTimerStop(); //休眠主窗口磁贴
					}
				} else {
					WindowController.magnetTimerStop(); //休眠主窗口磁贴
				}
				i = 0;
				wh: while (i < WindowController.magnetWindowArray.length) {
					j = 0;
					while (j < (WindowController.magnetWindowArray[i] as Array).length) {
						k = 0;
						while (k < (WindowController.magnetWindowArray[i][j] as WindowPanel).windowMagnetArray.length) {
							if (((WindowController.magnetWindowArray[i][j] as WindowPanel).windowMagnetArray[k] as Sprite).hitTestPoint(e.afterBounds.x - (WindowController.magnetWindowArray[i][j] as WindowPanel).window.x + mouseDownEvent.stageX, e.afterBounds.y - (WindowController.magnetWindowArray[i][j] as WindowPanel).window.y + mouseDownEvent.stageY, true)) {
								(WindowController.magnetWindowArray[i][j] as WindowPanel).windowMagnets.visible = true;
								(WindowController.magnetWindowArray[i][j] as WindowPanel).magnetTimerStart(k);
								break wh;
							} else {
								k++;
							}
						}
						if (k == (WindowController.magnetWindowArray[i][j] as WindowPanel).windowMagnetArray.length) {
							(WindowController.magnetWindowArray[i][j] as WindowPanel).windowMagnets.visible = false;
							(WindowController.magnetWindowArray[i][j] as WindowPanel).magnetTimerStop();
						}
						j++;
					}
					i++;
				}
			}
		}
		private function windowMoveEnd(e: MouseEvent) {
			var list: Vector.<NativeWindow>;
			var i: uint;
			bar.removeEventListener(MouseEvent.MOUSE_UP, windowMoveEnd);
			mouseDownEvent = null;
			if (WindowController.magnetWindowArray[0].length) {
				list = parentWindow.listOwnedWindows();
				i = 0;
				while (i < list.length) {
					if ((list[i] as NativeWindow).visible && ((list[i] as NativeWindow).stage.getChildAt(0) as WindowPanel).windowMagnetTimer.running) {
						putIntoParentWindow(this, (list[i] as NativeWindow).stage.getChildAt(0) as WindowPanel, ((list[i] as NativeWindow).stage.getChildAt(0) as WindowPanel).windowMagnetIndex);
						resizeCorner.visible = false;
						break;
					}
					i++;
				}
				if (i == list.length && isMagnetic) {
					isMagnetic = false;
					_window.width = oriWidth;
					_window.height = oriHeight;
					resizeCorner.visible = true;
				}
			} else if (WindowController.mainWindowMagnetTimerIsRunning) {
				putIntoParentWindow(this);
				resizeCorner.visible = false;
			} else if (isMagnetic) {
				isMagnetic = false;
				_window.width = oriWidth;
				_window.height = oriHeight;
				resizeCorner.visible = true;
			}
		}
		private function windowResize(e: Event) {
			var matrix: Matrix = new Matrix();
			//子窗口标题栏相关
			matrix.createGradientBox(_window.width - 1, 20, 90 * Math.PI / 180);
			bar.graphics.clear();
			bar.graphics.beginGradientFill(GradientType.LINEAR, new Array(0x303030, 0x2a2a2a), new Array(1, 1), new Array(0, 255), matrix);
			bar.graphics.lineStyle(0x000000);
			bar.graphics.drawRect(0, 0, _window.width - 1, 20);
			bar.graphics.endFill();
			if (bar.numChildren > 0) {
				bar.getChildAt(0).x = 10;
				bar.getChildAt(0).width = _window.width - 11;
			}
			//子窗口面板相关
			this.graphics.clear();
			this.graphics.beginFill(0x444444);
			this.graphics.lineStyle(0x000000);
			this.graphics.drawRect(0, 20, _window.width - 1, _window.height - 20 - 1);
			this.graphics.endFill();
			//子窗口内容相关
			_mask.graphics.beginFill(0xffffff);
			_mask.graphics.drawRect(0, 20, _window.width - 1, _window.height - 20 - 1);
			_mask.graphics.endFill();
			//缩放角相关
			resizeCorner.x = _window.width - 12;
			resizeCorner.y = _window.height - 12;
			//禁止交互功能
			lockCurtain.graphics.beginFill(0xffffff, 0);
			lockCurtain.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			lockCurtain.graphics.endFill();
		}
		private function moveThisReady(e: MouseEvent) {
			bar.addEventListener(MouseEvent.MOUSE_MOVE, moveThis);
			bar.addEventListener(MouseEvent.MOUSE_UP, moveThisFail);
		}
		private function moveThisFail(e: MouseEvent) {
			bar.removeEventListener(MouseEvent.MOUSE_MOVE, moveThis);
			bar.removeEventListener(MouseEvent.MOUSE_UP, moveThisFail);
			resetMagneticWindows();
		}
		private function moveThis(e: MouseEvent) {
			var i: uint;
			var j: uint;
			bar.removeEventListener(MouseEvent.MOUSE_MOVE, moveThis);
			bar.removeEventListener(MouseEvent.MOUSE_UP, moveThisFail);
			mouseDownEvent = e;
			_window.startMove();
			bar.addEventListener(MouseEvent.MOUSE_UP, windowMoveEnd);
			i = 0;
			wh: while (i < WindowController.magnetWindowArray.length) {
				j = 0;
				while (j < (WindowController.magnetWindowArray[i] as Array).length) {
					if (WindowController.magnetWindowArray[i][j] as WindowPanel == this) {
						(WindowController.magnetWindowArray[i] as Array).removeAt(j);
						resetMagneticWindows();
						direct = WindowPanelDirection.NONE;
						break wh;
					}
					j++;
				}
				i++;
			}
		}
		private function resizeWindow(e: MouseEvent) {
			_window.startResize();
		}

	}

}