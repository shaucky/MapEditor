package xiaoChi.MapEditor {
	import xiaoChi.WindowPanel;
	import flash.display.Sprite;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.FileMode;
	import flash.utils.ByteArray;
	import flash.system.LoaderContext;
	import flash.display.Loader;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.filters.ColorMatrixFilter;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.desktop.NotificationType;
	import flash.events.KeyboardEvent;

	public class ColorPalette extends Sprite {
		private var isSelecting: Boolean = false;
		private var colorSelected: Boolean = false;
		private var oldColor: Number = 0xff0000;
		private var window: NativeWindow;
		private const windowOptions: NativeWindowInitOptions = new NativeWindowInitOptions();
		private var content: Object;
		private var contentFile: File;
		private const contentFileStream: FileStream = new FileStream();
		private const contentLoader: Loader = new Loader();
		private var innerPalette: Sprite;
		private const innerPalettePointer: Sprite = new Sprite();
		private var innerHue: Sprite;
		private var innerHuePointer: Sprite;
		private const colorMatrixFilter: ColorMatrixFilter = new ColorMatrixFilter();
		private const currentColor: Sprite = new Sprite();
		private var propertyR: Sprite;
		private var propertyG: Sprite;
		private var propertyB: Sprite;
		private var property16: Sprite;
		private var buttonSelect: Sprite;
		private var buttonCancel: Sprite;
		public function get color(): Number {
			return oldColor;
		}
		private function set colorMatrix(value: Number) {
			var matrix: Array = new Array(1, 0, 0, 0, 33, 0, 1, 0, 0, 33, 0, 0, 1, 0, 33, 0, 0, 0, 1, 0); //4x5矩阵
			var lumR: Number = 0.213;
			var lumG: Number = 0.712;
			var lumB: Number = 0.075;
			var valSin: Number;
			var valCos: Number;
			value = value * 360 / 255;
			//value = cleanValue(value, 180);
			value = value * Math.PI / 180;
			valSin = Math.sin(value);
			valCos = Math.cos(value);
			//R通道
			matrix[0] = lumR + valCos * (1 - lumR) + valSin * (-lumR);
			matrix[1] = lumG + valCos * (-lumG) + valSin * (-lumG);
			matrix[2] = lumB + valCos * (-lumB) + valSin * (1 - lumB);
			//G通道
			matrix[5] = lumR + valCos * (-lumR) + valSin * (0.143);
			matrix[6] = lumG + valCos * (1 - lumG) + valSin * (0.140);
			matrix[7] = lumB + valCos * (-lumB) + valSin * (-0.283);
			//B通道
			matrix[10] = lumR + valCos * (-lumR) + valSin * (-(1 - lumR));
			matrix[11] = lumG + valCos * (-lumG) + valSin * (lumG);
			matrix[12] = lumB + valCos * (1 - lumB) + valSin * (lumB);
			colorMatrixFilter.matrix = matrix;
			/*
			function cleanValue(value: Number, limit: Number): Number {
				return Math.min(limit, Math.max(limit, value));
			}*/
		}

		public function ColorPalette() {
			windowOptions.maximizable = false;
			windowOptions.minimizable = false;
			windowOptions.resizable = false;
		}
		public function select(color: Number = -1, target: String = null) {
			var str: String
			if (isSelecting) {
				window.notifyUser(NotificationType.INFORMATIONAL);
				throw (new Error("Error: 无法在调色板正在使用时使用调色板。"));
			} else if (!window) {
				isSelecting = true;
				window = new NativeWindow(windowOptions);
				window.width = 450;
				window.height = 340;
				window.stage.color = 0x444444;
				window.stage.align = StageAlign.TOP_LEFT;
				window.stage.scaleMode = StageScaleMode.NO_SCALE;
				window.stage.addChild(this);
				if (target) {
					window.title = "调色板（" + target + "）";
				} else {
					window.title = "调色板";
				}
				window.alwaysInFront = true;
				window.activate();
				WindowPanel.lockUpAllWindows();
				window.addEventListener(Event.CLOSE, windowClosed);
				if (!content && Locator.isReady) {
					if (color == -1) {
						color = 0xff0000;
					}
					oldColor = color;
					contentFile = (Locator.directory as File).resolvePath("frames/" + (Locator.data as XML).child("frames")[0].child("color")[0]);
					try {
						contentFileStream.openAsync(contentFile, FileMode.READ);
						contentFileStream.addEventListener(Event.COMPLETE, contentFileOpened);
						contentFileStream.addEventListener(IOErrorEvent.IO_ERROR, contentFileOpenError);
					} catch (err: Error) {
						trace("Error: 无法读取：\n" + contentFile.url);
					}
				} else if (content) {
					if (color == -1) {
						color = 0xff0000;
					}
					str = color.toString(16);
					while (str.length < 6) {
						str = "0" + str;
					}
					((property16 as Sprite).getChildAt(1) as TextField).text = str;
					((property16 as Sprite).getChildAt(1) as TextField).dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP));
				}
			}
		}
		private function updateCurrentColor(color: Number) {
			currentColor.graphics.beginFill(color);
			currentColor.graphics.lineStyle(1, 0x000000);
			currentColor.graphics.drawRect(0, 0, 50, 50);
			currentColor.graphics.endFill();
		}
		private function calculateColorFromPalette() {
			var array: Array = new Array();
			var propertyArray: Array = new Array(propertyR, propertyG, propertyB);
			var stringArray: Array = new Array();
			var baseR: Number;
			var baseG: Number;
			var baseB: Number;
			if (256 - (innerHuePointer.y - 20) >= 256 * 0 / 6 && 256 - (innerHuePointer.y - 20) < 256 * 1 / 6) {
				baseR = 255;
				baseG = Math.min(255, (255 - (innerHuePointer.y - 20) - 255 * 0 / 6) * 6);
				baseB = 0;
			} else if (256 - (innerHuePointer.y - 20) >= 256 * 1 / 6 && 256 - (innerHuePointer.y - 20) < 256 * 2 / 6) {
				baseR = Math.max(0, 255 - (255 - (innerHuePointer.y - 20) - 255 * 1 / 6) * 6);
				baseG = 255;
				baseB = 0;
			} else if (256 - (innerHuePointer.y - 20) >= 256 * 2 / 6 && 256 - (innerHuePointer.y - 20) < 256 * 3 / 6) {
				baseR = 0;
				baseG = 255;
				baseB = Math.min(255, (255 - (innerHuePointer.y - 20) - 255 * 2 / 6) * 6);
			} else if (256 - (innerHuePointer.y - 20) >= 256 * 3 / 6 && 256 - (innerHuePointer.y - 20) < 256 * 4 / 6) {
				baseR = 0;
				baseG = Math.max(0, 255 - (255 - (innerHuePointer.y - 20) - 255 * 3 / 6) * 6);
				baseB = 255;
			} else if (256 - (innerHuePointer.y - 20) >= 256 * 4 / 6 && 256 - (innerHuePointer.y - 20) < 256 * 5 / 6) {
				baseR = Math.min(255, (255 - (innerHuePointer.y - 20) - 255 * 4 / 6) * 6);
				baseG = 0;
				baseB = 255;
			} else if (256 - (innerHuePointer.y - 20) >= 256 * 5 / 6 && 256 - (innerHuePointer.y - 20) <= 256 * 6 / 6) {
				baseR = 255;
				baseG = 0;
				baseB = Math.max(0, 255 - (255 - (innerHuePointer.y - 20) - 255 * 5 / 6) * 6);
			}
			transLight(baseR);
			transLight(baseG);
			transLight(baseB);
			(property16.getChildAt(1) as TextField).text = stringArray[0] + stringArray[1] + stringArray[2];
			updateCurrentColor(Number("0x" + (property16.getChildAt(1) as TextField).text));
			function transLight(light: Number) {
				array.push(light);
				if (array[array.length - 1] > 255) {
					array[array.length - 1] = 255;
				} else if (array[array.length - 1] < 0) {
					array[array.length - 1] = 0;
				}
				if (innerPalettePointer.x < 20 + 255 - x) {
					array[array.length - 1] += (255 - array[array.length - 1]) * ((255 + 20 - x) - innerPalettePointer.x) / 255;
				}
				array[array.length - 1] *= (255 - innerPalettePointer.y + 20) / 255;
				((propertyArray[array.length - 1] as Sprite).getChildAt(1) as TextField).text = String(Math.round(array[array.length - 1]));
				stringArray.push((array[array.length - 1] as Number).toString(16));
				if ((stringArray[array.length - 1] as String).length == 1) {
					stringArray[array.length - 1] = "0" + stringArray[array.length - 1];
				}
			}
		}
		private function calculateColorFromRGB() {
			var array: Array = new Array();
			var hueArray: Array = new Array();
			var stringArray: Array = new Array();
			var largest: Number;
			var num1: Number;
			var num2: Number;
			var i: uint;
			initLight(Math.round(Number((propertyR.getChildAt(1) as TextField).text)));
			initLight(Math.round(Number((propertyG.getChildAt(1) as TextField).text)));
			initLight(Math.round(Number((propertyB.getChildAt(1) as TextField).text)));
			largest = Math.max(array[0], array[1], array[2]);
			num1 = largest / 255;
			switch (largest) {
				case array[0]: //R最大
					if (array[1] >= array[2]) { //G次大
						calcHue(0, 1, 2);
						innerHuePointer.y = 20 + 255 - (hueArray[1] / 6 + 255 * 0 / 6);
					} else { //B次大
						calcHue(0, 2, 1);
						innerHuePointer.y = 20 + 255 - ((255 - hueArray[2]) / 6 + 255 * 5 / 6);
					}
					break;
				case array[1]: //G最大
					if (array[2] >= array[0]) { //B次大
						calcHue(1, 2, 0);
						innerHuePointer.y = 20 + 255 - (hueArray[2] / 6 + 255 * 2 / 6);
					} else { //R次大
						calcHue(1, 0, 2);
						innerHuePointer.y = 20 + 255 - ((255 - hueArray[0]) / 6 + 255 * 1 / 6);
					}
					break;
				case array[2]: //B最大
					if (array[0] >= array[1]) { //R次大
						calcHue(2, 0, 1);
						innerHuePointer.y = 20 + 255 - (hueArray[0] / 6 + 255 * 4 / 6);
					} else { //G次大
						calcHue(2, 1, 0);
						innerHuePointer.y = 20 + 255 - ((255 - hueArray[1]) / 6 + 255 * 3 / 6);
					}
					break;
			}
			colorMatrix = 255 - (innerHuePointer.y - 20);
			innerPalette.filters = new Array(colorMatrixFilter);
			i = 0;
			while (i < array.length) {
				stringArray.push((array[i] as Number).toString(16));
				if ((stringArray[i] as String).length == 1) {
					stringArray[i] = "0" + stringArray[i];
				}
				i++;
			}
			(property16.getChildAt(1) as TextField).text = stringArray[0] + stringArray[1] + stringArray[2];
			updateCurrentColor(Number("0x" + (property16.getChildAt(1) as TextField).text));
			function initLight(light: Number) {
				if (light > 255) {
					light = 255;
				} else if (light < 0) {
					light = 0;
				}
				array.push(light);
			}
			function calcHue(index1: uint, index2: uint, index3: uint) {
				hueArray[index1] = 255;
				if (array[index1] == array[index2] && array[index2] == array[index3]) {
					hueArray[0] = 255;
					hueArray[1] = 0;
					hueArray[2] = 0;
				} else if (array[index3] == 0) {
					hueArray[index3] = 0;
					hueArray[index2] = array[index2];
				} else if (array[index3] == 255) {
					hueArray[index3] = 255;
					hueArray[index2] = 255;
				} else {
					num2 = array[index3] / num1 / 255;
					hueArray[index2] = Math.floor(array[index2] / num1);
					hueArray[index3] = 0;
					hueArray[index2] = Math.floor((hueArray[index2] / num2 - 255) * num2 / (1 - num2));
				}
				innerPalettePointer.x = 20 + 255 - (array[index3] / num1);
				innerPalettePointer.y = 20 + 255 - (array[index1]);
			}
		}
		private function calculateColorFromNumber16() {
			var inputString: String = ((property16 as Sprite).getChildAt(1) as TextField).text;
			if (inputString.length >= 6) {
				((propertyR as Sprite).getChildAt(1) as TextField).text = String(Number("0x" + inputString.charAt(0) + inputString.charAt(1)));
				((propertyG as Sprite).getChildAt(1) as TextField).text = String(Number("0x" + inputString.charAt(2) + inputString.charAt(3)));
				((propertyB as Sprite).getChildAt(1) as TextField).text = String(Number("0x" + inputString.charAt(4) + inputString.charAt(5)));
				calculateColorFromRGB();
				((property16 as Sprite).getChildAt(1) as TextField).text = inputString;
			}
		}

		private function startChangeColor(e: MouseEvent) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, changeColor);
			stage.addEventListener(MouseEvent.MOUSE_UP, endChangeColor);
			changeColor(e);
		}
		private function changeColor(e: MouseEvent) {
			if (e.stageX >= 20 && e.stageX <= 20 + 256) {
				innerPalettePointer.x = e.stageX - x;
			} else if (e.stageX < 20) {
				innerPalettePointer.x = 20 - x;
			} else if (e.stageX > 20 + 255) {
				innerPalettePointer.x = 20 + 255 - x;
			}
			if (e.stageY >= 20 && e.stageY <= 20 + 256) {
				innerPalettePointer.y = e.stageY - y;
			} else if (e.stageY < 20) {
				innerPalettePointer.y = 20 - y;
			} else if (e.stageY > 20 + 255) {
				innerPalettePointer.y = 20 + 255 - y;
			}
			innerPalettePointer.graphics.clear();
			if (e.stageX <= 20 + (256 * 1 / 3) && e.stageY <= 20 + (256 * 2 / 3)) {
				innerPalettePointer.graphics.lineStyle(1, 0x000000);
			} else {
				innerPalettePointer.graphics.lineStyle(1, 0xffffff);
			}
			innerPalettePointer.graphics.drawCircle(0, 0, 8);
			calculateColorFromPalette();
		}
		private function endChangeColor(e: MouseEvent) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, changeColor);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endChangeColor);
		}
		private function startChangeHue(e: MouseEvent) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, changeHue);
			stage.addEventListener(MouseEvent.MOUSE_UP, endChangeHue);
		}
		private function changeHue(e: MouseEvent) {
			if (e.stageY >= 20 && e.stageY <= 20 + 255) {
				innerHuePointer.y = e.stageY + y;
			} else if (e.stageY < 20) {
				innerHuePointer.y = 20 + y;
			} else if (e.stageY > 20 + 255) {
				innerHuePointer.y = 20 + 255 + y;
			}
			colorMatrix = 255 - (innerHuePointer.y - 20);
			innerPalette.filters = new Array(colorMatrixFilter);
			calculateColorFromPalette();
		}
		private function endChangeHue(e: MouseEvent) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, changeHue);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endChangeHue);
		}
		private function clickHue(e: MouseEvent) {
			if (e.stageY >= 20 && e.stageY <= 20 + 255) {
				innerHuePointer.y = e.stageY + y;
			} else if (e.stageY < 20) {
				innerHuePointer.y = 20 + y;
			} else if (e.stageY > 20 + 255) {
				innerHuePointer.y = 20 + 255 + y;
			}
			colorMatrix = 255 - (innerHuePointer.y - 20);
			innerPalette.filters = new Array(colorMatrixFilter);
			calculateColorFromPalette();
			innerHuePointer.dispatchEvent(e);
		}
		private function RGBChangeColor(e: KeyboardEvent) {
			calculateColorFromRGB();
		}
		private function numberChangeColor(e: KeyboardEvent) {
			calculateColorFromNumber16();
		}

		private function clickButtonSelect(e: MouseEvent) {
			colorSelected = true;
			oldColor = Number("0x" + ((property16 as Sprite).getChildAt(1) as TextField).text);
			window.close();
		}
		private function clickButtonCancel(e: MouseEvent) {
			window.close();
		}

		private function contentFileOpened(e: Event) {
			var b: ByteArray = new ByteArray();
			var lc: LoaderContext = new LoaderContext();
			lc.allowCodeImport = true;
			try {
				contentFileStream.readBytes(b);
				contentLoader.loadBytes(b, lc);
				contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
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
		private function contentLoaded(e: Event) {
			var str: String;
			content = contentLoader.content;
			innerPalette = new content.ColorPalette();
			innerPalette.x = 20;
			innerPalette.y = 20;
			colorMatrix = 0;
			innerPalette.filters = new Array(colorMatrixFilter);
			addChild(innerPalette);
			innerPalette.addEventListener(MouseEvent.MOUSE_DOWN, startChangeColor);
			innerPalettePointer.graphics.lineStyle(1, 0xffffff);
			innerPalettePointer.graphics.drawCircle(0, 0, 8);
			innerPalettePointer.x = innerPalette.x + 256;
			innerPalettePointer.y = innerPalette.y;
			addChild(innerPalettePointer);
			innerHue = new content.Hue();
			innerHue.x = 25 + 256;
			innerHue.y = 20;
			addChild(innerHue);
			innerHue.addEventListener(MouseEvent.MOUSE_DOWN, clickHue);
			innerHuePointer = new content.HuePointer();
			innerHuePointer.x = 25 + 256;
			innerHuePointer.y = 20 + 256;
			addChild(innerHuePointer);
			innerHuePointer.addEventListener(MouseEvent.MOUSE_DOWN, startChangeHue);
			currentColor.x = 90 + 256;
			currentColor.y = 25;
			updateCurrentColor(0xff0000);
			addChild(currentColor);
			propertyR = new content.Property();
			(propertyR.getChildAt(0) as TextField).text = "R:";
			(propertyR.getChildAt(1) as TextField).text = "255";
			propertyR.x = 80 + 256;
			propertyR.y = 90;
			addChild(propertyR);
			propertyR.addEventListener(KeyboardEvent.KEY_UP, RGBChangeColor);
			propertyG = new content.Property();
			(propertyG.getChildAt(0) as TextField).text = "G:";
			(propertyG.getChildAt(1) as TextField).text = "0";
			propertyG.x = 80 + 256;
			propertyG.y = 125;
			addChild(propertyG);
			propertyG.addEventListener(KeyboardEvent.KEY_UP, RGBChangeColor);
			propertyB = new content.Property();
			(propertyB.getChildAt(0) as TextField).text = "B:";
			(propertyB.getChildAt(1) as TextField).text = "0";
			propertyB.x = 80 + 256;
			propertyB.y = 160;
			addChild(propertyB);
			propertyB.addEventListener(KeyboardEvent.KEY_UP, RGBChangeColor);
			property16 = new content.Property();
			(property16.getChildAt(0) as TextField).text = " #";
			(property16.getChildAt(1) as TextField).text = "ff0000";
			property16.x = 80 + 256;
			property16.y = 195;
			addChild(property16);
			property16.addEventListener(KeyboardEvent.KEY_UP, numberChangeColor);
			buttonSelect = new content.Button();
			(buttonSelect.getChildAt(0) as TextField).text = "确定";
			(buttonSelect.getChildAt(0) as TextField).background = true;
			(buttonSelect.getChildAt(0) as TextField).backgroundColor = 0x444444;
			(buttonSelect.getChildAt(0) as TextField).border = true;
			(buttonSelect.getChildAt(0) as TextField).borderColor = 0x000000;
			buttonSelect.x = 75 + 256;
			buttonSelect.y = 230;
			addChild(buttonSelect);
			buttonSelect.addEventListener(MouseEvent.CLICK, clickButtonSelect);
			buttonCancel = new content.Button();
			(buttonCancel.getChildAt(0) as TextField).text = "取消";
			(buttonCancel.getChildAt(0) as TextField).background = true;
			(buttonCancel.getChildAt(0) as TextField).backgroundColor = 0x444444;
			(buttonCancel.getChildAt(0) as TextField).border = true;
			(buttonCancel.getChildAt(0) as TextField).borderColor = 0x000000;
			buttonCancel.x = 75 + 256;
			buttonCancel.y = 265;
			addChild(buttonCancel);
			buttonCancel.addEventListener(MouseEvent.CLICK, clickButtonCancel);
			str = oldColor.toString(16);
			while (str.length < 6) {
				str = "0" + str;
			}
			((property16 as Sprite).getChildAt(1) as TextField).text = str;
			((property16 as Sprite).getChildAt(1) as TextField).text = str;
			calculateColorFromNumber16();
			contentLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, contentLoaded);
			contentLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, contentIOError);
		}
		private function contentIOError(e: IOErrorEvent) {
			contentLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, contentLoaded);
			contentLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, contentIOError);
			trace("Error: 无法读取：\n" + contentFile.url);
		}
		private function windowClosed(e: Event) {
			window.removeEventListener(Event.CLOSE, windowClosed);
			window = null;
			isSelecting = false;
			if (colorSelected) {
				this.dispatchEvent(new Event(Event.SELECT));
				colorSelected = false;
			} else {
				this.dispatchEvent(new Event(Event.CANCEL));
			}
			WindowPanel.lockUpAllWindows();
		}

	}

}