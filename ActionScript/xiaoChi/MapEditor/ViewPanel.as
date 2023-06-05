package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.EditAction;
	import xiaoChi.MapEditor.MEDManager;
	import xiaoChi.MapEditor.MEDocument;
	import xiaoChi.MapEditor.Panel;
	import xiaoChi.ContextMenuUtils;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.Shape;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.desktop.NativeDragManager;
	import flash.events.NativeDragEvent;
	import flash.desktop.ClipboardFormats;
	import flash.display.Loader;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	import flash.display.PNGEncoderOptions;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.display.NativeWindow;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;

	public class ViewPanel extends Panel {
		private const viewArea: Sprite = new Sprite();
		private const viewAreaContent: Sprite = new Sprite();
		private const viewAreaMask: Shape = new Shape();
		private const dragTarget: Sprite = new Sprite();
		private const grid: Shape = new Shape();
		internal var curTarget: XML;
		private var _curFocusObject: Sprite;
		private var _backgroundColor: Number = 0x333333;
		private const fileList: Sprite = new Sprite();
		private const _fileListMask: Shape = new Shape();
		private const fileListMoreButton: Sprite = new Sprite();
		private const fileListMore: NativeMenu = new NativeMenu();
		private var numLoadingImage: uint = 0; //总共要加载的图像数目
		private var numLoadedImage: uint = 0; //已经加载的图像数目
		private const drawSceneDispatcher: EventDispatcher = new EventDispatcher();
		private var _editAction: String = "move";
		private var oldX: Number = 0;
		private var oldY: Number = 0;
		private var oldObjX: Number = 0;
		private var oldObjY: Number = 0;
		private var cutArray: Array;
		private var cutShape: Shape;

		internal function set curFocusObject(value: Sprite) {
			var object: XML;
			var i: uint = 0;
			var mi: uint;
			var listLength: uint;
			while (i < viewAreaContent.numChildren) {
				if (viewAreaContent.getChildAt(i) is Sprite) {
					(viewAreaContent.getChildAt(i) as Sprite).graphics.clear();
				}
				if (viewAreaContent.getChildAt(i) == value) {
					mi = i;
				}
				i++;
			}
			_curFocusObject = value;
			if (_curFocusObject) {
				_curFocusObject.graphics.clear();
				_curFocusObject.graphics.lineStyle(1, 0x3164a3);
				_curFocusObject.graphics.beginFill(0x000000, 0);
				_curFocusObject.graphics.drawRect(0, 0, Math.ceil(Number(_curFocusObject.width) / Number(MEDManager.currentMED.scene.@unitLength)) * Number(MEDManager.currentMED.scene.@unitLength), Math.ceil(Number(_curFocusObject.height) / Number(MEDManager.currentMED.scene.@unitLength)) * Number(MEDManager.currentMED.scene.@unitLength));
				_curFocusObject.graphics.endFill();
				if (curTarget.localName() == "scene") {
					listLength = curTarget.child("floor")[0].child("resource").length();
					if (mi <= listLength) {
						object = curTarget.child("floor")[0].child("resource")[mi - 1];
					} else {
						object = curTarget.child("objects")[0].child("resource")[mi - 1 - listLength];
					}
				} else {
					object = curTarget.child("resource")[mi - 1];
				}
				(window.owner.stage.getChildAt(0) as Main).propertiesPanel.focusOn(object);
			} else if (curTarget) {
				(window.owner.stage.getChildAt(0) as Main).propertiesPanel.focusOn(curTarget);
			}
		}
		internal function get curFocusObject(): Sprite {
			return _curFocusObject;
		}
		public function set backgroundColor(value: Number) {
			_backgroundColor = value;
			viewArea.graphics.clear();
			viewArea.graphics.beginFill(_backgroundColor);
			viewArea.graphics.lineStyle(1, 0x000000);
			viewArea.graphics.drawRect(0, 0, stage.stageWidth - 1, stage.stageHeight - 40 - 16);
			viewArea.graphics.endFill();
		}
		public function get backgroundColor(): Number {
			return _backgroundColor;
		}
		internal function set editAction(value: String) {
			_editAction = value;
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, startMoveContent);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, startDragContent);
			stage.removeEventListener(MouseEvent.CLICK, startCutImage);
			switch (_editAction) {
				case EditAction.MOVE:
					stage.addEventListener(MouseEvent.MOUSE_DOWN, startMoveContent);
					break;
				case EditAction.DRAG:
					stage.addEventListener(MouseEvent.MOUSE_DOWN, startDragContent);
					break;
				case EditAction.CUT:
					stage.addEventListener(MouseEvent.CLICK, startCutImage);
					break;
			}
		}
		internal function get editAction(): String {
			return _editAction;
		}

		public function ViewPanel(parentFrame: Sprite) {
			super(parentFrame);
			title = "视口";
			tag = "view";
			((getChildAt(0) as Sprite).getChildAt(0) as TextField).text = window.title;
			window.width = 450;
			defaultWidth = 450;
			window.height = 300;
			defaultHeight = 300;
			viewArea.x = 0;
			viewArea.y = 16;
			fileList.mask = _fileListMask;
			viewAreaContent.mask = viewAreaMask;
			viewAreaContent.x = 0;
			viewAreaContent.y = 16;
			viewAreaMask.x = 0;
			viewAreaMask.y = 36;
			dragTarget.x = 0;
			dragTarget.y = 16;
			stage.addEventListener(Event.RESIZE, stageResize);
			contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
			//stage.addEventListener(MouseEvent.CLICK, function(e:MouseEvent){trace(e.target + e.target.width + " " + e.target.height)});
		}
		private function resizeContent() {
			const stageHeight: Number = stage.stageHeight;
			const stageWidth: Number = stage.stageWidth;
			viewArea.graphics.clear();
			viewArea.graphics.beginFill(_backgroundColor);
			viewArea.graphics.lineStyle(1, 0x000000);
			viewArea.graphics.drawRect(0, 0, stageWidth - 1, stageHeight - 40 - 16);
			viewArea.graphics.endFill();
			viewAreaMask.graphics.clear();
			viewAreaMask.graphics.beginFill(_backgroundColor);
			viewAreaMask.graphics.lineStyle(1, 0x000000);
			viewAreaMask.graphics.drawRect(0, 0, stageWidth - 1, stageHeight - 40 - 16);
			viewAreaMask.graphics.endFill();
			dragTarget.graphics.clear();
			dragTarget.graphics.beginFill(_backgroundColor, 0);
			dragTarget.graphics.lineStyle(1, 0x000000);
			dragTarget.graphics.drawRect(0, 0, stageWidth - 1, stageHeight - 40);
			dragTarget.graphics.endFill();
			_fileListMask.graphics.clear();
			_fileListMask.graphics.beginFill(0x000000);
			_fileListMask.graphics.drawRect(0, 0, stageWidth, 16);
			_fileListMask.graphics.endFill();
			fileListMoreButton.x = stageWidth - 30;
		}
		private function stageResize(e: Event) {
			if (content) {
				resizeContent();
			}
		}
		private function contentLoaded(e: Event) {
			var i: uint;
			content = contentLoader.content as Sprite;
			contentLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, contentLoaded);
			i = 0;
			while (MEDManager.MEDList.length > i) {
				MEDManager.MEDList[i][1] = addMEDItem((MEDManager.MEDList[i][0] as MEDocument).fileName);
				i++;
			}
			if (MEDManager.MEDList.length > 0) {
				MEDManager.addListenerForEveryItem();
			}
			fileListMoreButton.graphics.beginFill(0x444444);
			fileListMoreButton.graphics.lineStyle(1, 0x000000);
			fileListMoreButton.graphics.drawRect(0, 0, 30 - 1, 16);
			fileListMoreButton.graphics.endFill();
			fileListMoreButton.graphics.lineStyle(2, 0x888888);
			fileListMoreButton.graphics.moveTo(7, 4);
			fileListMoreButton.graphics.lineTo(15, 7);
			fileListMoreButton.graphics.lineTo(23, 4);
			fileListMoreButton.graphics.moveTo(7, 10);
			fileListMoreButton.graphics.lineTo(15, 13);
			fileListMoreButton.graphics.lineTo(23, 10);
			fileListMoreButton.addEventListener(MouseEvent.CLICK, showListMore);
			stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragEntered);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, deleteObject);
			viewArea.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragEntered);
			dragTarget.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragEntered);
			dragTarget.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, dragDropped);
			dragTarget.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, dragExited);
			viewArea.addEventListener(MouseEvent.MOUSE_WHEEL, wheelToResize);
			viewAreaContent.addEventListener(MouseEvent.MOUSE_WHEEL, wheelToResize);
			ContextMenuUtils.getItemByLabel("导出为PNG图像").addEventListener(Event.SELECT, drawSceneToPNG);
			content.addChild(dragTarget);
			content.addChild(viewArea);
			content.addChild(fileList);
			content.addChild(_fileListMask);
			content.addChild(fileListMoreButton);
			content.addChild(viewAreaContent);
			refreshView();
			resizeContent();
		}
		internal function addMEDItem(fileName: String): Sprite {
			var s: Sprite;
			if (content) {
				s = new(content as Object).FileTag();
				(s.getChildAt(0) as TextField).text = fileName;
				s.graphics.beginFill(0x444444);
				s.graphics.lineStyle(1, 0x000000);
				s.graphics.drawRect(0, 0, 119, 15);
				s.graphics.endFill();
				s.x = fileList.numChildren * s.width;
				fileList.addChild(s);
			}
			return s;
		}
		internal function selectItem(item: Sprite) {
			var i: uint = 0;
			var spr: Sprite;
			while (i < fileList.numChildren) {
				spr = fileList.getChildAt(i) as Sprite;
				spr.graphics.clear();
				spr.graphics.beginFill(0x444444);
				spr.graphics.lineStyle(1, 0x000000);
				spr.graphics.drawRect(0, 0, 119, 15);
				spr.graphics.endFill();
				i++;
			}
			item.graphics.clear();
			item.graphics.beginFill(0x666666);
			item.graphics.lineStyle(1, 0x000000);
			item.graphics.drawRect(0, 0, 119, 15);
			item.graphics.endFill();
		}
		internal function closeItem(item: Sprite) {
			var i: uint;
			fileList.removeChild(item);
			i = 0;
			while (i < fileList.numChildren) {
				fileList.getChildAt(i).x = i * fileList.getChildAt(i).width;
				i++;
			}
			if (fileList.x >= -fileList.width) {
				fileList.x = 0;
			}
		}

		internal function refreshView() {
			var i: uint;
			var unitLength: uint;
			var col: uint;
			var row: uint;
			var spr: Sprite;
			if (content && MEDManager.currentMED) {
				unitLength = uint(MEDManager.currentMED.scene.@unitLength);
				viewAreaContent.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
				viewAreaContent.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickObject);
				viewArea.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
				curFocusObject = null;
				/* //每次刷新都重置位置的话，会影响拖拽等操作
				viewAreaContent.x = 0;
				viewAreaContent.y = 16;
				viewAreaContent.scaleX = 1;
				viewAreaContent.scaleY = 1;
				*/
				while (viewAreaContent.numChildren) {
					viewAreaContent.removeChildAt(0);
				}
				numLoadingImage = 0;
				numLoadedImage = 0;
				if (curTarget.localName() == "scene") { //打开文档默认目标为场景（显示全部）
					col = uint(MEDManager.currentMED.scene.@sceneWidth);
					row = uint(MEDManager.currentMED.scene.@sceneHeight);
					grid.graphics.clear(); //清理grid栅格，开始重绘栅格
					grid.graphics.lineStyle(1, 0x888888);
					i = 0;
					while (i < row + 1) {
						grid.graphics.lineTo(col * unitLength, i * unitLength);
						grid.graphics.moveTo(0, (i + 1) * unitLength);
						i++;
					}
					i = 0;
					grid.graphics.moveTo(0, 0);
					while (i < col + 1) {
						grid.graphics.lineTo(i * unitLength, row * unitLength);
						grid.graphics.moveTo((i + 1) * unitLength, 0);
						i++;
					}
					viewAreaContent.addChild(grid); //grid栅格绘制完毕，重新加入内容
					loadChild(curTarget.child("floor")[0], viewAreaContent);
					loadChild(curTarget.child("objects")[0], viewAreaContent);
					viewAreaContent.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
					viewAreaContent.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickObject);
					viewArea.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
				} else if (curTarget.localName() == "objects" || curTarget.localName() == "floor") {
					col = uint(MEDManager.currentMED.scene.@sceneWidth);
					row = uint(MEDManager.currentMED.scene.@sceneHeight);
					grid.graphics.clear(); //清理grid栅格，开始重绘栅格
					grid.graphics.lineStyle(1, 0x888888);
					i = 0;
					while (i < row + 1) {
						grid.graphics.lineTo(col * unitLength, i * unitLength);
						grid.graphics.moveTo(0, (i + 1) * unitLength);
						i++;
					}
					i = 0;
					grid.graphics.moveTo(0, 0);
					while (i < col + 1) {
						grid.graphics.lineTo(i * unitLength, row * unitLength);
						grid.graphics.moveTo((i + 1) * unitLength, 0);
						i++;
					}
					viewAreaContent.addChild(grid); //grid栅格绘制完毕，重新加入内容
					loadChild(curTarget, viewAreaContent);
					viewAreaContent.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
					viewAreaContent.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickObject);
					viewArea.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
				} else if (curTarget.localName() == "resource") { //从资源面板打开具体资源
					if (curTarget.@type == "image") {
						spr = new Sprite();
						spr.doubleClickEnabled = true;
						spr.addChild(new Loader());
						(spr.getChildAt(0) as Loader).loadBytes(MEDManager.currentMED.getResourceBytesAt(MEDManager.currentMED.getResource(curTarget.@name).childIndex()));
						(spr.getChildAt(0) as Loader).contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
						numLoadingImage++;
						viewAreaContent.addChild(spr);
					} else if (curTarget.@type == "media") {
						//暂缓开发
					} else if (curTarget.@type == "object") {
						col = uint(curTarget.@width);
						row = uint(curTarget.@height);
						grid.graphics.clear(); //清理grid栅格，开始重绘栅格
						grid.graphics.lineStyle(1, 0x888888);
						i = 0;
						while (i < row + 1) {
							grid.graphics.lineTo(col * unitLength, i * unitLength);
							grid.graphics.moveTo(0, (i + 1) * unitLength);
							i++;
						}
						i = 0;
						grid.graphics.moveTo(0, 0);
						while (i < col + 1) {
							grid.graphics.lineTo(i * unitLength, row * unitLength);
							grid.graphics.moveTo((i + 1) * unitLength, 0);
							i++;
						}
						viewAreaContent.addChild(grid); //grid栅格绘制完毕，重新加入内容
						loadChild(curTarget, viewAreaContent);
						viewAreaContent.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
						viewAreaContent.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickObject);
						viewArea.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
					}
				}
				function imageLoaded(e: Event) {
					e.target.loader.parent.addChild(e.target.content);
					e.target.loader.parent.removeChild(e.target.loader);
					e.target.removeEventListener(Event.COMPLETE, imageLoaded);
					numLoadedImage++;
					if (numLoadingImage == numLoadedImage) {
						drawSceneDispatcher.dispatchEvent(new Event(Event.COMPLETE));
					}
				}
			}
			function loadChild(object: XML, parent: Sprite) {
				var list: XMLList = object.child("resource");
				var idx: uint = 0;
				var res: XML;
				var spr: Sprite;
				var ldr: Loader;
				var type: String;
				var resIdx: uint = 0;
				var max: uint = list.length();
				while (idx < max) {
					res = list[idx];
					type = res.@type;
					switch (type) {
						case "image":
							ldr = new Loader();
							spr = new Sprite();
							spr.doubleClickEnabled = true;
							resIdx = MEDManager.currentMED.getResource(res.@name).childIndex();
							parent.addChild(spr);
							spr.addChild(ldr);
							spr.x = Number(res.@x);
							spr.y = Number(res.@y);
							ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
							ldr.loadBytes(MEDManager.currentMED.getResourceBytesAt(resIdx));
							numLoadingImage++;
							break;
						case "media":
							break;
						case "object":
							spr = new Sprite();
							spr.doubleClickEnabled = true;
							parent.addChild(spr);
							spr.x = Number(res.@x);
							spr.y = Number(res.@y);
							loadChild(MEDManager.currentMED.getResource(res.@name), parent.getChildAt(parent.numChildren - 1));
							break;
					}
					idx++;
				}
				function imageLoaded(e: Event) {
					e.target.loader.parent.addChild(e.target.content);
					e.target.loader.parent.removeChild(e.target.loader);
					e.target.removeEventListener(Event.COMPLETE, imageLoaded);
					numLoadedImage++;
					if (numLoadingImage == numLoadedImage) {
						drawSceneDispatcher.dispatchEvent(new Event(Event.COMPLETE));
					}
				}
			}
		}

		internal function rearrange2DResource() {
			var array: Array = new Array();
			var i: uint;
			var j: uint;
			var max: uint;
			var xmlList: XMLList;
			if (content) {
				if (curTarget) {
					if (curTarget.localName() == "scene") {
						xmlList = curTarget.child("objects")[0].child("resource");
						max = xmlList.length();
						i = curTarget.child("floor")[0].child("resource").length();
						j = 0;
						while (i + 1 < viewAreaContent.numChildren) {
							array.push(new Array(viewAreaContent.getChildAt(i + 1), xmlList[j])); //+1是因为grid影响
							i++;
							j++;
						}
						array.sort(onY);
						i = 0;
						while (i < array.length) {
							curTarget.child("objects")[0].appendChild(array[i][1]);
							viewAreaContent.addChild(array[i][0]);
							i++;
						}
					} else if (curTarget.localName() != "floor") {
						xmlList = curTarget.child("resource");
						i = 0;
						while (i + 1 < viewAreaContent.numChildren) {
							array.push(new Array(viewAreaContent.getChildAt(i + 1), xmlList[i])); //+1是因为grid影响
							i++;
						}
						array.sort(onY);
						i = 0;
						while (i < array.length) {
							curTarget.appendChild(array[i][1]);
							viewAreaContent.addChild(array[i][0]);
							i++;
						}
					}
				}
			}
			function onY(a: Array, b: Array): int {
				var result: int = 0;
				var aY: Number = Number(a[1].@y);
				var bY: Number = Number(b[1].@y);
				if (aY > bY) {
					result = 1;
				} else if (aY < bY) {
					result = -1;
				}
				return result;
			}
		}

		private function mouseDownObject(e: MouseEvent) {
			var target: DisplayObject = e.target as DisplayObject;
			if (target == viewArea) {
				curFocusObject = null;
			} else {
				if (target) {
					if (target.parent) {
						while (target.parent) {
							if (target.parent != viewAreaContent) {
								target = target.parent;
							} else {
								break;
							}
						}
						curFocusObject = target as Sprite;
					} else {
						curFocusObject = null;
					}
				} else {
					curFocusObject = null;
				}
			}
		}
		private function doubleClickObject(e: MouseEvent) {
			var target: DisplayObject = e.target as DisplayObject;
			var i: uint;
			var name: String;
			var len: uint;
			if (target == viewArea) {
				curFocusObject = null;
			} else {
				if (target) {
					if (target.parent) {
						while (target.parent) {
							if (target.parent != viewAreaContent) {
								target = target.parent;
							} else {
								break;
							}
						}
						curFocusObject = target as Sprite;
						i = 0;
						while (i < viewAreaContent.numChildren) {
							if (viewAreaContent.getChildAt(i) == _curFocusObject) {
								if (curTarget.localName() == "scene") {
									len = curTarget.child("floor")[0].child("resource").length();
									if (i <= len) {
										name = curTarget.child("floor")[0].child("resource")[i - 1].@name; //-1应该是因为放了grid（栅格）
									} else {
										name = curTarget.child("objects")[0].child("resource")[i - 1 - len].@name;
									}
								} else {
									name = curTarget.child("resource")[i - 1].@name;
								}
								curTarget = MEDManager.currentMED.getResource(name);
								refreshView();
								break;
							}
							i++;
						}
					} else {
						curFocusObject = null;
					}
				} else {
					curFocusObject = null;
				}
			}
		}

		private function startMoveContent(e: MouseEvent) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, updateContentPosition);
			stage.addEventListener(MouseEvent.MOUSE_UP, stopMoveContent);
			oldX = e.stageX;
			oldY = e.stageY;
		}
		private function updateContentPosition(e: MouseEvent) {
			viewAreaContent.x += e.stageX - oldX;
			oldX = e.stageX;
			viewAreaContent.y += e.stageY - oldY;
			oldY = e.stageY;
		}
		private function stopMoveContent(e: MouseEvent) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateContentPosition);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopMoveContent);
		}
		private function startDragContent(e: MouseEvent) {
			if (_curFocusObject) {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, updateObjectPosition);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopDragContent);
				oldX = e.stageX;
				oldY = e.stageY;
				oldObjX = _curFocusObject.x;
				oldObjY = _curFocusObject.y;
			}
		}
		private function updateObjectPosition(e: MouseEvent) {
			if (_curFocusObject) {
				_curFocusObject.x = Math.round((e.stageX - oldX + oldObjX) / Number(MEDManager.currentMED.scene.@unitLength)) * Number(MEDManager.currentMED.scene.@unitLength);
				_curFocusObject.y = Math.round((e.stageY - oldY + oldObjY) / Number(MEDManager.currentMED.scene.@unitLength)) * Number(MEDManager.currentMED.scene.@unitLength);
			}
		}
		private function stopDragContent(e: MouseEvent) {
			var list: XMLList;
			var list2: XMLList;
			var listLength: uint;
			var i: uint;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateObjectPosition);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragContent);
			if (_curFocusObject) {
				i = 0;
				while (i < viewAreaContent.numChildren) {
					if (viewAreaContent.getChildAt(i) == _curFocusObject) {
						if (curTarget.localName() == "scene") {
							list = curTarget.child("floor")[0].child("resource");
							list2 = curTarget.child("objects")[0].child("resource");
							listLength = list.length();
							if (i < listLength) {
								(list[i - 1]).@x = Math.round(_curFocusObject.x);
								(list[i - 1]).@y = Math.round(_curFocusObject.y);
							} else {
								(list2[i - 1 - listLength]).@x = Math.round(_curFocusObject.x);
								(list2[i - 1 - listLength]).@y = Math.round(_curFocusObject.y);
							}
						} else {
							(curTarget.child("resource")[i - 1]).@x = Math.round(_curFocusObject.x);
							(curTarget.child("resource")[i - 1]).@y = Math.round(_curFocusObject.y);
						}
					}
					i++;
				}
				curFocusObject = _curFocusObject;
				rearrange2DResource();
				MEDManager.markMEDItem(MEDManager.currentMED);
			}
		}
		private function startCutImage(e: MouseEvent) {
			if (curTarget) {
				if (curTarget.localName() == "resource" && curTarget.@type == "image") {
					cutArray = new Array();
					cutArray.push(new Point(e.stageX / viewAreaContent.scaleX - content.x - viewAreaContent.x / viewAreaContent.scaleX, e.stageY / viewAreaContent.scaleY - content.y - (viewAreaContent.y / viewAreaContent.scaleY) - 20 / viewAreaContent.scaleY));
					cutShape = new Shape();
					viewAreaContent.addChild(cutShape);
					viewAreaContent.doubleClickEnabled = true;
					stage.addEventListener(MouseEvent.MOUSE_MOVE, cutImageMove);
					viewArea.addEventListener(MouseEvent.CLICK, cutImagePoint);
					viewAreaContent.addEventListener(MouseEvent.CLICK, cutImagePoint);
					viewArea.addEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
					viewAreaContent.addEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
					viewAreaContent.getChildAt(0).addEventListener(Event.REMOVED, cutImageStop);
					stage.removeEventListener(MouseEvent.CLICK, startCutImage);
				}
			}
		}
		private function cutImageMove(e: MouseEvent) {
			var i: uint;
			cutShape.graphics.clear();
			cutShape.graphics.lineStyle(1, 0x232323);
			cutShape.graphics.moveTo((cutArray[0] as Point).x, (cutArray[0] as Point).y);
			i = 1;
			while (i < cutArray.length) {
				cutShape.graphics.lineTo((cutArray[i] as Point).x, (cutArray[i] as Point).y);
				i++;
			}
			cutShape.graphics.lineTo(e.stageX / viewAreaContent.scaleX - content.x - viewAreaContent.x / viewAreaContent.scaleX, e.stageY / viewAreaContent.scaleY - content.y - (viewAreaContent.y / viewAreaContent.scaleY) - 20 / viewAreaContent.scaleY);
		}
		private function cutImagePoint(e: MouseEvent) {
			cutArray.push(new Point(e.stageX / viewAreaContent.scaleX - content.x - viewAreaContent.x / viewAreaContent.scaleX, e.stageY / viewAreaContent.scaleY - content.y - (viewAreaContent.y / viewAreaContent.scaleY) - 20 / viewAreaContent.scaleY));
		}
		private function cutImageComplete(e: MouseEvent) {
			var minX: Number = 0;
			var minY: Number = 0;
			var maxX: Number = 0;
			var maxY: Number = 0;
			var a: int;
			var b: int;
			var i: uint;
			var tempSprite: Sprite = new Sprite();
			var spr: Sprite;
			var bmd: BitmapData;
			var bmd2: BitmapData;
			viewAreaContent.doubleClickEnabled = false;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, cutImageMove);
			viewArea.removeEventListener(MouseEvent.CLICK, cutImagePoint);
			viewAreaContent.removeEventListener(MouseEvent.CLICK, cutImagePoint);
			viewArea.removeEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
			viewAreaContent.removeEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
			viewAreaContent.getChildAt(0).removeEventListener(Event.REMOVED, cutImageStop);
			stage.addEventListener(MouseEvent.CLICK, startCutImage);
			cutShape.graphics.clear();
			cutShape.graphics.beginFill(0x000000);
			cutShape.graphics.moveTo((cutArray[0] as Point).x, (cutArray[0] as Point).y);
			i = 1;
			while (i < cutArray.length) {
				cutShape.graphics.lineTo((cutArray[i] as Point).x, (cutArray[i] as Point).y);
				i++;
			}
			cutShape.graphics.lineTo(e.stageX / viewAreaContent.scaleX - content.x - viewAreaContent.x, e.stageY / viewAreaContent.scaleY - content.y - viewAreaContent.y - 20);
			i = 0;
			while (i < cutArray.length) {
				if ((cutArray[i] as Point).x < minX) {
					minX = (cutArray[i] as Point).x;
				}
				if ((cutArray[i] as Point).x > maxX) {
					maxX = (cutArray[i] as Point).x;
				}
				if ((cutArray[i] as Point).y < minY) {
					minY = (cutArray[i] as Point).y;
				}
				if ((cutArray[i] as Point).y > maxY) {
					maxY = (cutArray[i] as Point).y;
				}
				i++;
			}
			spr = viewAreaContent.getChildAt(0) as Sprite;
			tempSprite.addChild(spr);
			tempSprite.addChild(cutShape);
			spr.x = -minX;
			spr.y = -minY;
			cutShape.x = -minX;
			cutShape.y = -minY;
			spr.mask = cutShape;
			bmd = new BitmapData(maxX - minX, maxY - minY, true, 0x00000000);
			bmd.draw(tempSprite);
			a = 0;
			wh1: while (a < bmd.height) {
				b = 0;
				while (b < bmd.width) {
					if (bmd.getPixel32(b, a) != 0x00000000) {
						break wh1;
					}
					b++;
				}
				a++;
			}
			minY = a;
			a = bmd.height;
			wh2: while (a > 0) {
				b = 0;
				while (b < bmd.width) {
					if (bmd.getPixel32(b, a) != 0x00000000) {
						break wh2;
					}
					b++;
				}
				a--;
			}
			maxY = a;
			b = 0;
			wh3: while (b < bmd.width) {
				a = 0;
				while (a < bmd.height) {
					if (bmd.getPixel32(b, a) != 0x00000000) {
						break wh3;
					}
					a++;
				}
				b++;
			}
			minX = b;
			b = bmd.width;
			wh4: while (b > 0) {
				a = 0;
				while (a < bmd.height) {
					if (bmd.getPixel32(b, a) != 0x00000000) {
						break wh4;
					}
					a++;
				}
				b--;
			}
			maxX = b;
			bmd2 = new BitmapData(maxX - minX, maxY - minY, true, 0x00000000);
			spr.mask = null;
			spr.removeChildAt(0);
			spr.addChild(new Bitmap(bmd));
			tempSprite.removeChild(cutShape);
			spr.x = -minX;
			spr.y = -minY;
			bmd2.draw(tempSprite);
			spr.removeChildAt(0);
			spr.addChild(new Bitmap(bmd2));
			viewAreaContent.addChild(spr);
			MEDManager.currentMED.updateResourceBytes(curTarget.@name, bmd2.encode(new Rectangle(0, 0, bmd2.width, bmd2.height), new PNGEncoderOptions()));
			tempSprite = null;
		}
		private function cutImageStop(e: Event) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, cutImageMove);
			viewArea.removeEventListener(MouseEvent.CLICK, cutImagePoint);
			viewAreaContent.removeEventListener(MouseEvent.CLICK, cutImagePoint);
			viewArea.removeEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
			viewAreaContent.removeEventListener(MouseEvent.DOUBLE_CLICK, cutImageComplete);
			viewAreaContent.getChildAt(0).removeEventListener(Event.REMOVED, cutImageStop);
			stage.addEventListener(MouseEvent.CLICK, startCutImage);
		}
		private function wheelToResize(e: MouseEvent) {
			var oldWidth: Number = viewAreaContent.width;
			var oldCenterX: Number = (e.stageX - viewAreaContent.x) / viewAreaContent.width;
			var oldHeight: Number = viewAreaContent.height;
			var oldCenterY: Number = (e.stageY - viewAreaContent.y - 20) / viewAreaContent.height;
			//if (e.target.parent == content) {
			if (e.delta > 0) { //上滑
				if (viewAreaContent.scaleX > 1 / 16 && viewAreaContent.scaleY > 1 / 16) {
					viewAreaContent.scaleX /= 2;
					viewAreaContent.scaleY /= 2;
				}
			} else if (e.delta < 0) { //下滑
				if (viewAreaContent.scaleX < 16 && viewAreaContent.scaleY < 16) {
					viewAreaContent.scaleX *= 2;
					viewAreaContent.scaleY *= 2;
				}
			}
			//}
			viewAreaContent.x += (oldWidth - viewAreaContent.width) * oldCenterX;
			viewAreaContent.y += (oldHeight - viewAreaContent.height) * oldCenterY;
		}
		private function drawSceneToPNG(e: Event) {
			var i: uint;
			var windowNum: uint;
			var f: File;
			var fs: FileStream;
			var bmd: BitmapData;
			var tempArray: Array;
			if (MEDManager.currentMED) {
				windowNum = mainFrame.stage.nativeWindow.listOwnedWindows().length;
				tempArray = new Array();
				i = 0;
				while (i < windowNum) {
					if (mainFrame.stage.nativeWindow.listOwnedWindows()[i].visible) {
						tempArray.push(mainFrame.stage.nativeWindow.listOwnedWindows()[i]);
						mainFrame.stage.nativeWindow.listOwnedWindows()[i].visible = false;
					}
					i++;
				}
				f = File.desktopDirectory;
				f.browseForSave("选择导出PNG的位置");
				f.addEventListener(Event.SELECT, drawPNGSelected);
				f.addEventListener(Event.CANCEL, drawPNGCanceled);
			}
			function drawPNGSelected(e: Event) {
				f.removeEventListener(Event.SELECT, drawPNGSelected);
				f.removeEventListener(Event.CANCEL, drawPNGCanceled);
				while (tempArray.length) {
					(tempArray[0] as NativeWindow).visible = true;
					tempArray.removeAt(0);
				}
				if (MEDManager.currentMED) {
					if (!f.url.match(/.png$/)) {
						f.url += ".png";
					}
					bmd = new BitmapData(Number(MEDManager.currentMED.scene.@sceneWidth) * Number(MEDManager.currentMED.scene.@unitLength), Number(MEDManager.currentMED.scene.@sceneHeight) * Number(MEDManager.currentMED.scene.@unitLength), true, 0x00000000);
					curTarget = MEDManager.currentMED.scene;
					refreshView();
					//bmd.draw(viewAreaContent); //素材加载是异步的，立即绘图得不到内容
					drawSceneDispatcher.addEventListener(Event.COMPLETE, drawScene);
				}
			}
			function drawScene(e: Event) {
				drawSceneDispatcher.removeEventListener(Event.COMPLETE, drawScene);
				viewAreaContent.removeChild(grid);
				viewAreaContent.mask = null;
				bmd.draw(viewAreaContent);
				viewAreaContent.addChildAt(grid, 0);
				viewAreaContent.mask = viewAreaMask;
				fs = new FileStream();
				fs.open(f, FileMode.UPDATE);
				fs.writeBytes(bmd.encode(new Rectangle(0, 0, bmd.width, bmd.height), new PNGEncoderOptions()));
				fs.truncate();
				fs.close();
			}
			function drawPNGCanceled(e: Event) {
				f.removeEventListener(Event.SELECT, drawPNGSelected);
				f.removeEventListener(Event.CANCEL, drawPNGCanceled);
				while (tempArray.length) {
					(tempArray[0] as NativeWindow).visible = true;
					tempArray.removeAt(0);
				}
				f = null;
			}
		}

		internal function clean() {
			curTarget = null;
			viewAreaContent.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
			viewArea.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownObject);
			while (viewAreaContent.numChildren) {
				viewAreaContent.removeChildAt(0);
			}
			grid.graphics.clear();
			backgroundColor = 0x333333;
			curFocusObject = null;
		}

		private function showListMore(e: MouseEvent) {
			var i: uint;
			fileListMore.addEventListener(Event.SELECT, selectedFileItem);
			fileListMore.removeAllItems();
			if (fileList.numChildren > 0) {
				i = 0;
				while (i < fileList.numChildren) {
					fileListMore.addItem(new NativeMenuItem(((fileList.getChildAt(i) as Sprite).getChildAt(0) as TextField).text));
					i++;
				}
			}
			fileListMore.display(stage, stage.stageWidth - 30, 35);
		}
		private function selectedFileItem(e: Event) {
			var i: uint = 0;
			fileListMore.removeEventListener(Event.SELECT, selectedFileItem);
			while (i < fileListMore.numItems) {
				if (e.target == fileListMore.items[i]) {
					MEDManager.focusOnMED(i);
					fileList.x = -fileList.getChildAt(i).x;
					break;
				}
				i++;
			}
		}

		private function deleteObject(e: KeyboardEvent) {
			var plusLen: uint;
			var len: uint;
			var i: uint;
			if (e.charCode == 8 || e.charCode == 127) {
				if (_curFocusObject) {
					i = 0;
					if (curTarget.localName() == "scene") {
						len = curTarget.child("floor")[0].child("resource").length();
						plusLen = len + curTarget.child("objects")[0].child("resource").length();
						while (i <= plusLen) {
							if (viewAreaContent.getChildAt(i) == _curFocusObject) {
								break;
							}
							i++;
						}
						if (i <= len) {
							delete curTarget.child("floor")[0].child("resource")[i - 1];
						} else {
							delete curTarget.child("objects")[0].child("resource")[i - 1 - len];
						}
						MEDManager.markMEDItem(MEDManager.currentMED);
						refreshView();
					} else {
						len = curTarget.child("resource").length();
						while (i <= len) {
							if (viewAreaContent.getChildAt(i) == _curFocusObject) {
								break;
							}
							i++;
						}
						delete curTarget.child("resource")[i - 1];
						MEDManager.markMEDItem(MEDManager.currentMED);
						refreshView();
					}
				}
			}
		}

		internal function readyToBeDropped() {
			content.addChild(dragTarget);
		}

		private function dragEntered(e: NativeDragEvent) {
			if (e.clipboard.hasFormat(ClipboardFormats.TEXT_FORMAT) && MEDManager.currentMED) {
				NativeDragManager.acceptDragDrop(dragTarget);
				content.addChild(dragTarget);
			}
		}
		private function dragDropped(e: NativeDragEvent) {
			const resName: String = e.clipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
			var object: XML = MEDManager.currentMED.getResource(resName);
			var type: String;
			type = object.@type;
			switch (type) {
				case "image":
					object = object.copy(); //图像不应当有子节点，所以可以直接复制
					break;
				case "media": //暂缓开发
					break;
				case "object":
					object = MEDManager.currentMED.createObject(resName, true); //对象可能存在子节点，需要创建新节点，作为引用
					break;
			}
			try {
				if (curTarget.localName() == "scene") {
					MEDManager.currentMED.checkDeadlock(MEDManager.currentMED.getResource(resName), curTarget.child("objects")[0]);
					curTarget.child("objects")[0].appendChild(object);
				} else {
					MEDManager.currentMED.checkDeadlock(MEDManager.currentMED.getResource(resName), curTarget);
					curTarget.appendChild(object);
				}
			} catch (e: Error) {
				content.addChildAt(dragTarget, 0);
				throw (e);
			}
			MEDManager.markMEDItem(MEDManager.currentMED);
			refreshView();
			rearrange2DResource();
			content.addChildAt(dragTarget, 0);
			trace("当前的MED场景结构为：\n" + MEDManager.currentMED.scene);
		}
		private function dragExited(e: NativeDragEvent) {
			content.addChildAt(dragTarget, 0);
		}

	}

}