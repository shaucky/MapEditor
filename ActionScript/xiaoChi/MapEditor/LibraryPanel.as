package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.MEDManager;
	import xiaoChi.MapEditor.Panel;
	import xiaoChi.ContextMenuUtils;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.desktop.NativeDragManager;
	import flash.events.NativeDragEvent;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragOptions;
	import flash.desktop.ClipboardFormats;
	import flash.filesystem.File;
	import flash.display.Loader;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.desktop.Clipboard;
	import flash.text.TextFieldType;
	import flash.events.FocusEvent;

	public class LibraryPanel extends Panel {
		private const preview: Sprite = new Sprite();
		private const previewMask: Shape = new Shape();
		private const previewClickArea: Sprite = new Sprite();
		private var currentItem: Sprite;
		private var currentType: String;
		private var scrollBar: Sprite;
		private var head: Sprite;
		private const listContainer: Sprite = new Sprite();
		private const dragTarget: Sprite = new Sprite();
		private const list: Sprite = new Sprite();
		private const listMask: Shape = new Shape();

		public function LibraryPanel(parentFrame: Sprite) {
			super(parentFrame);
			title = "资源";
			tag = "library";
			((getChildAt(0) as Sprite).getChildAt(0) as TextField).text = window.title;
			window.width = 125;
			defaultWidth = 125;
			window.height = 150;
			defaultHeight = 150;
			list.mask = listMask;
			stage.addEventListener(Event.RESIZE, stageResize);
			contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
			ContextMenuUtils.getItemByLabel("新建对象").addEventListener(Event.SELECT, createNewObject);
		}
		private function resizeContent() {
			var i: uint;
			var currentSprite: Sprite;
			const stageHeight: Number = stage.stageHeight;
			const stageWidth: Number = stage.stageWidth;
			preview.graphics.clear();
			preview.graphics.lineStyle(1, 0x000000);
			preview.graphics.beginFill(0x000000, 0);
			preview.graphics.drawRect(0, 0, stageWidth - 1, (stageWidth - 1) * 3 / 4);
			preview.graphics.endFill();
			previewMask.graphics.clear();
			previewMask.graphics.beginFill(0x000000);
			previewMask.graphics.drawRect(0, 1, stageWidth - 1, (stageWidth - 1) * 3 / 4);
			previewMask.graphics.endFill();
			previewClickArea.graphics.clear();
			previewClickArea.graphics.beginFill(0x000000, 0);
			previewClickArea.graphics.drawRect(0, 1, stageWidth - 1, (stageWidth - 1) * 3 / 4);
			previewClickArea.graphics.endFill();
			dragTarget.graphics.clear();
			dragTarget.graphics.beginFill(0xffffff, 0);
			dragTarget.graphics.drawRect(0, 0, stageWidth - 1, stageHeight - previewMask.height - head.height - 20 - 16);
			dragTarget.graphics.endFill();
			listMask.graphics.clear();
			listMask.graphics.beginFill(0x000000, 0);
			listMask.graphics.drawRect(0, 0, stageWidth - 1, stageHeight - previewMask.height - head.height - 20 - 16);
			listMask.graphics.endFill();
			scrollBar.width = 15;
			scrollBar.height = stageHeight - previewMask.height - head.height - 20 - 16;
			scrollBar.x = stageWidth - scrollBar.width;
			(scrollBar as Object).setScrollProperties(list.height, 0, list.height - listMask.height, list.height / 20);
			head.x = 0;
			head.y = preview.y + previewMask.height;
			head.graphics.clear();
			head.graphics.beginFill(0x555555);
			head.graphics.lineStyle(1, 0x000000);
			head.graphics.drawRect(0, 0, stageWidth - 1, head.height - 1);
			head.graphics.endFill();
			list.y = head.y + head.height - (scrollBar as Object).scrollPosition;
			dragTarget.y = head.y + head.height;
			listMask.y = head.y + head.height;
			scrollBar.y = head.y + head.height;
			if (stageWidth > 200) {
				(head.getChildAt(1) as TextField).width = stageWidth - 90 - 20;
				(head.getChildAt(2) as TextField).width = 90;
				(head.getChildAt(2) as TextField).x = (head.getChildAt(1) as TextField).width + 20;
				i = 0;
				while (i < list.numChildren) {
					currentSprite = (list.getChildAt(i) as Sprite);
					(currentSprite.getChildAt(1) as TextField).width = stageWidth - 90 - 20;
					(currentSprite.getChildAt(2) as TextField).width = 90;
					(currentSprite.getChildAt(2) as TextField).x = (currentSprite.getChildAt(1) as TextField).width + 20;
					i++;
				}
			} else {
				(head.getChildAt(1) as TextField).width = 90;
				(head.getChildAt(2) as TextField).width = stageWidth - 90 - 20;
				(head.getChildAt(2) as TextField).x = (head.getChildAt(1) as TextField).width + 20;
				i = 0;
				while (i < list.numChildren) {
					currentSprite = (list.getChildAt(i) as Sprite);
					(currentSprite.getChildAt(1) as TextField).width = 90;
					(currentSprite.getChildAt(2) as TextField).width = stageWidth - 90 - 20;
					(currentSprite.getChildAt(2) as TextField).x = (currentSprite.getChildAt(1) as TextField).width + 20;
					i++;
				}
			}
			if (currentItem) {
				currentItem.graphics.beginFill(0x888888);
				currentItem.graphics.drawRect(0, 0, currentItem.width, currentItem.height);
				currentItem.graphics.endFill();
			}
			resizePreview();
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
			preview.mask = previewMask;
			scrollBar = new(content as Object).ScrollBar();
			scrollBar.addEventListener(Event.SCROLL, barScroll);
			list.addEventListener(MouseEvent.MOUSE_WHEEL, listWheel);
			head = new(content as Object).Item();
			previewClickArea.doubleClickEnabled = true;
			listContainer.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragEntered);
			dragTarget.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, dragDropped);
			dragTarget.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, dragExited);
			previewClickArea.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickPreview);
			content.addChild(preview);
			content.addChild(previewMask);
			content.addChild(previewClickArea);
			content.addChild(listContainer);
			listContainer.addChild(dragTarget);
			listContainer.addChild(list);
			listContainer.addChild(listMask);
			content.addChild(scrollBar);
			content.addChild(head);
			queryMED();
			resizeContent();
		}
		private function startDragResource(e: MouseEvent) {
			const cb: Clipboard = new Clipboard();
			var tar: Sprite;
			if (e.target is Sprite) {
				tar = e.target as Sprite;
				cb.setData(ClipboardFormats.TEXT_FORMAT, (tar.getChildAt(1) as TextField).text);
				NativeDragManager.doDrag(tar, cb);
			} else {
				e.target.addEventListener(MouseEvent.MOUSE_OUT, function (e: MouseEvent) {
					e.target.removeEventListener(MouseEvent.MOUSE_OUT, arguments.callee);
					cb.setData(ClipboardFormats.TEXT_FORMAT, (tar.getChildAt(1) as TextField).text);
					NativeDragManager.doDrag(tar, cb);
				});
				tar = e.target.parent;
			}
		}
		private function dragEntered(e: NativeDragEvent) {
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT) && MEDManager.currentMED) {
				NativeDragManager.acceptDragDrop(dragTarget);
				listContainer.addChildAt(dragTarget, listContainer.numChildren);
			}
		}
		private function dragDropped(e: NativeDragEvent) {
			const f: File = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
			if (f.url.match(/\.mp3$/)) {
				MEDManager.currentMED.addResourceAsMP3(f);
			} else {
				MEDManager.currentMED.addResource(f);
			}
			listContainer.addChildAt(dragTarget, 0);
		}
		private function dragExited(e: NativeDragEvent) {
			listContainer.addChildAt(dragTarget, 0);
		}

		private function barScroll(e: Event) {
			list.y = head.y + head.height - (scrollBar as Object).scrollPosition;
		}
		private function listWheel(e: MouseEvent) {
			if (e.delta > 0) { //上滑
				(scrollBar as Object).scrollPosition -= list.height / 20;
			} else if (e.delta < 0) { //下滑
				(scrollBar as Object).scrollPosition += list.height / 20;
			}
		}
		private function doubleClickPreview(e: MouseEvent) {
			(window.owner.stage.getChildAt(0) as Main).viewPanel.curTarget = MEDManager.currentMED.getResource((currentItem.getChildAt(1) as TextField).text);
			(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
		}

		internal function queryMED() {
			var ary: Array = new Array();
			var i: uint
			var itm: Sprite;
			var lib: XML;
			var len: int;
			var typ: String;
			if (MEDManager.currentMED && content) {
				lib = MEDManager.currentMED.library;
				while (list.numChildren) {
					list.getChildAt(0).removeEventListener(MouseEvent.CLICK, selectResource);
					list.getChildAt(0).removeEventListener(MouseEvent.RIGHT_CLICK, rightClickItem);
					list.getChildAt(0).removeEventListener(MouseEvent.MOUSE_DOWN, startDragResource);
					list.removeChildAt(0);
				}
				i = 0;
				len = lib.resource.length();
				while (len > i) {
					itm = new(content as Object).Item();
					(itm.getChildAt(1) as TextField).text = lib.resource[i].@name;
					(itm.getChildAt(1) as TextField).doubleClickEnabled = true;
					typ = lib.resource[i].@type;
					switch (typ) { //很奇怪，直接引用XML属性会判断不了
						case "image":
							(itm.getChildAt(2) as TextField).text = "图像";
							break;
						case "media":
							(itm.getChildAt(2) as TextField).text = "音频";
							break;
						case "object":
							(itm.getChildAt(2) as TextField).text = "对象";
							break;
					}
					itm.addEventListener(MouseEvent.CLICK, selectResource);
					itm.addEventListener(MouseEvent.RIGHT_CLICK, rightClickItem);
					itm.addEventListener(MouseEvent.MOUSE_DOWN, startDragResource);
					(itm.getChildAt(1) as TextField).addEventListener(MouseEvent.DOUBLE_CLICK, renameResource);
					if (stage.stageWidth > 200) {
						(itm.getChildAt(1) as TextField).width = stage.stageWidth - 90 - 20;
						(itm.getChildAt(2) as TextField).width = 90;
						(itm.getChildAt(2) as TextField).x = (itm.getChildAt(1) as TextField).width + 20;
					} else {
						(itm.getChildAt(1) as TextField).width = 90;
						(itm.getChildAt(2) as TextField).width = stage.stageWidth - 90 - 20;
						(itm.getChildAt(2) as TextField).x = (itm.getChildAt(1) as TextField).width + 20;
					}
					ary.push(itm);
					i++;
				}
				i = 0;
				ary = ary.sort(onResName);
				while (0 < ary.length) {
					list.addChild(ary[0]);
					ary[0].y = i++ * 20;
					ary.removeAt(0);
				}
				i = 0;
				if (len == 0) {
					while (preview.numChildren) {
						preview.removeChildAt(0)
						i++;
					}
				} else {
					(list.getChildAt(0) as Sprite).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				}
				trace("当前的MED资源结构为：\n" + MEDManager.currentMED.library);
				(scrollBar as Object).setScrollProperties(list.height, 0, list.height - listMask.height, list.height / 20);
			}
			function onResName(a: Sprite, b: Sprite): int {
				var rtn: int;
				if ((a.getChildAt(1) as TextField).text > (b.getChildAt(1) as TextField).text) {
					rtn = 1;
				} else if ((a.getChildAt(1) as TextField).text < (b.getChildAt(1) as TextField).text) {
					rtn = -1;
				} else {
					if ((a.getChildAt(2) as TextField).text > (b.getChildAt(2) as TextField).text) {
						rtn = 1;
					} else if ((a.getChildAt(2) as TextField).text < (b.getChildAt(2) as TextField).text) {
						rtn = -1;
					} else {
						rtn = 0;
					}
				}
				return rtn;
			}
		}
		internal function clean() {
			currentItem = null;
			currentType = null;
			while (list.numChildren) {
				list.getChildAt(0).removeEventListener(MouseEvent.CLICK, selectResource);
				list.getChildAt(0).removeEventListener(MouseEvent.RIGHT_CLICK, rightClickItem);
				list.getChildAt(0).removeEventListener(MouseEvent.MOUSE_DOWN, startDragResource);
				((list.getChildAt(0) as Sprite).getChildAt(1) as TextField).removeEventListener(MouseEvent.DOUBLE_CLICK, renameResource);
				list.removeChildAt(0);
			}
			while (preview.numChildren > 0) {
				preview.removeChildAt(0);
			}
		}

		private function selectResource(e: MouseEvent) {
			var len: uint = uint(MEDManager.currentMED.scene.@unitLength);
			var lib: XMLList;
			var resName: String;
			var i: uint = 0;
			var j: uint;
			var resRoot: Sprite = new Sprite();
			if (e.target is Sprite) {
				currentItem = e.target as Sprite;
			} else {
				currentItem = e.target.parent;
			}
			while (i < list.numChildren) {
				(list.getChildAt(i) as Sprite).graphics.clear();
				i++;
			}
			currentItem.graphics.beginFill(0x888888);
			currentItem.graphics.drawRect(0, 0, currentItem.width, currentItem.height);
			currentItem.graphics.endFill();
			currentType = (currentItem.getChildAt(2) as TextField).text;
			switch (currentType) {
				case "图像":
					j = MEDManager.currentMED.getResource((currentItem.getChildAt(1) as TextField).text).childIndex();
					while (preview.numChildren > 0) {
						preview.removeChildAt(0);
					}
					preview.addChild(resRoot);
					resRoot.addChild(new Loader());
					(resRoot.getChildAt(0) as Loader).loadBytes(MEDManager.currentMED.getResourceBytesAt(j));
					(resRoot.getChildAt(0) as Loader).contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
					break;
				case "音频":
					break;
				case "对象":
					while (preview.numChildren > 0) {
						preview.removeChildAt(0);
					}
					preview.addChild(resRoot);
					loadChild(MEDManager.currentMED.getResource((currentItem.getChildAt(1) as TextField).text), resRoot);
					break;
			}
			function loadChild(object: XML, parent: Sprite) {
				var list: XMLList = object.child("resource");
				var idx: uint = 0;
				var res: XML;
				var type: String;
				var resIdx: uint = 0;
				var max: uint = list.length();
				while (idx < max) {
					res = list[idx];
					type = res.@type;
					switch (type) {
						case "image":
							resIdx = MEDManager.currentMED.getResource(res.@name).childIndex();
							parent.addChild(new Loader());
							(parent.getChildAt(parent.numChildren - 1) as Loader).x = Number(res.@x);
							(parent.getChildAt(parent.numChildren - 1) as Loader).y = Number(res.@y);
							(parent.getChildAt(parent.numChildren - 1) as Loader).loadBytes(MEDManager.currentMED.getResourceBytesAt(resIdx));
							(parent.getChildAt(parent.numChildren - 1) as Loader).contentLoaderInfo.addEventListener(Event.COMPLETE, objectStepLoaded);
							break;
						case "media":
							break;
						case "object":
							parent.addChild(new Sprite());
							(parent.getChildAt(parent.numChildren - 1) as Sprite).x = Number(res.@x);
							(parent.getChildAt(parent.numChildren - 1) as Sprite).y = Number(res.@y);
							loadChild(MEDManager.currentMED.getResource(res.@name), parent.getChildAt(parent.numChildren - 1));
							break;
					}
					idx++;
				}
			}
			function objectStepLoaded(e: Event) {
				if (resRoot.numChildren) {
					if (resRoot.width / resRoot.height >= previewMask.width / previewMask.height) {
						resRoot.width = previewMask.width;
						resRoot.scaleY = resRoot.scaleX;
						resRoot.x = 0;
						resRoot.y = (previewMask.height - resRoot.height) / 2;
					} else {
						resRoot.height = previewMask.height;
						resRoot.scaleX = resRoot.scaleY;
						resRoot.x = (previewMask.width - resRoot.width) / 2;
						resRoot.y = 0;
					}
				}
			}
			function imageLoaded(e: Event) {
				e.target.removeEventListener(Event.COMPLETE, imageLoaded);
				if (e.target.content.width / e.target.content.height >= previewMask.width / previewMask.height) {
					e.target.content.width = previewMask.width;
					e.target.content.scaleY = e.target.content.scaleX;
					e.target.loader.x = 0;
					e.target.loader.y = (previewMask.height - e.target.content.height) / 2;
				} else {
					e.target.content.height = previewMask.height;
					e.target.content.scaleX = e.target.content.scaleY;
					e.target.loader.x = (previewMask.width - e.target.content.width) / 2;
					e.target.loader.y = 0;
				}
			}
		}
		private function rightClickItem(e: MouseEvent) {
			var tar: Sprite;
			var menu: NativeMenu = new NativeMenu();
			var menuItem: NativeMenuItem;
			if (e.target is Sprite) {
				tar = e.target as Sprite;
			} else {
				tar = e.target.parent;
			}
			menuItem = new NativeMenuItem("删除");
			menuItem.addEventListener(Event.SELECT, deleteItem);
			menu.addItem(menuItem);
			menuItem = new NativeMenuItem("快速创建对象");
			menuItem.addEventListener(Event.SELECT, quickCreateObject);
			menu.addItem(menuItem);
			menu.display(stage, e.stageX, e.stageY);
			function deleteItem(e: Event) {
				e.target.removeEventListener(Event.SELECT, deleteItem);
				MEDManager.currentMED.removeResource((tar.getChildAt(1) as TextField).text);
				queryMED();
			}
			function quickCreateObject(e: Event) {
				var str: String;
				var xml: XML;
				var res: XML = MEDManager.currentMED.getResource((tar.getChildAt(1) as TextField).text);
				var child: XML;
				e.target.removeEventListener(Event.SELECT, quickCreateObject);
				xml = MEDManager.currentMED.createObject((tar.getChildAt(1) as TextField).text);
				str = res.@type;
				switch (str) {
					case "image":
						xml.@width = String(Math.ceil(Number(res.@width) / Number(MEDManager.currentMED.scene.@unitLength)));
						xml.@height = String(Math.ceil(Number(res.@height) / Number(MEDManager.currentMED.scene.@unitLength)));
						child = res.copy();
						child.@x = "0";
						child.@y = "0";
						break;
					case "media":
						break;
					case "object":
						xml.@width = String(Number(res.@width));
						xml.@height = String(Number(res.@height));
						child = MEDManager.currentMED.createObject((tar.getChildAt(1) as TextField).text, true);
						break;
				}
				MEDManager.currentMED.checkDeadlock(child, xml);
				xml.appendChild(child);
				MEDManager.currentMED.addObject(xml);
				queryMED();
			}
		}
		private function renameResource(e: MouseEvent) {
			var parent: Sprite;
			var oldName: String;
			if (e.target is TextField) {
				e.target.parent.removeEventListener(MouseEvent.MOUSE_DOWN, startDragResource);
				e.target.parent.removeEventListener(MouseEvent.CLICK, selectResource);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, function (e: MouseEvent) {
					if (e.target != stage.focus) {
						stage.focus = null;
						stage.removeEventListener(MouseEvent.MOUSE_DOWN, arguments.callee);
					}
				}); //文本编辑状态下，因未知原因无法通过点击其它非文本框对象失去对某一文本框的聚焦，通过这里失去
				parent = e.target.parent;
				oldName = e.target.text;
				e.target.type = TextFieldType.INPUT;
				e.target.selectable = true;
				e.target.textColor = 0x000000;
				e.target.background = true;
				e.target.backgroundColor = 0xffffff;
				e.target.border = true;
				e.target.borderColor = 0xB0832C;
				e.target.setSelection(0, e.target.length);
				e.target.addEventListener(FocusEvent.FOCUS_OUT, function (e: FocusEvent) {
					e.target.removeEventListener(FocusEvent.FOCUS_OUT, arguments.callee);
					parent.addEventListener(MouseEvent.MOUSE_DOWN, startDragResource);
					parent.addEventListener(MouseEvent.CLICK, selectResource);
					e.target.type = TextFieldType.DYNAMIC;
					e.target.selectable = false;
					e.target.textColor = 0xffffff;
					e.target.background = false;
					e.target.border = false;
					e.target.scrollH = 0;
					MEDManager.currentMED.renameResource(oldName, e.target.text);
				});
			}
		}
		private function createNewObject(e: Event) {
			var xml: XML;
			xml = MEDManager.currentMED.createObject("object");
			xml.@width = "1";
			xml.@height = "1";
			MEDManager.currentMED.addObject(xml);
			queryMED();
		}

		private function resizePreview() {
			var target: Object;
			if (preview.numChildren) {
				switch (currentType) {
					case null:
						break;
					case "图像":
						target = preview.getChildAt(0) as Sprite;
						if (target.numChildren) {
							if (target.width / target.height >= previewMask.width / previewMask.height) {
								target.width = previewMask.width;
								target.scaleY = target.scaleX;
								target.x = 0;
								target.y = (previewMask.height - target.height) / 2;
							} else {
								target.height = previewMask.height;
								target.scaleX = target.scaleY;
								target.x = (previewMask.width - target.width) / 2;
								target.y = 0;
							}
						}
						break;
					case "音频":
						break;
					case "对象":
						target = preview.getChildAt(0) as Sprite;
						if (target.numChildren) {
							if (target.width / target.height >= previewMask.width / previewMask.height) {
								target.width = previewMask.width;
								target.scaleY = target.scaleX;
								target.x = 0;
								target.y = (previewMask.height - target.height) / 2;
							} else {
								target.height = previewMask.height;
								target.scaleX = target.scaleY;
								target.x = (previewMask.width - target.width) / 2;
								target.y = 0;
							}
						}
						break;
				}
			}
		}
	}

}