package xiaoChi.MapEditor {
	import xiaoChi.standardIO;
	import xiaoChi.STDIOEvent;
	import xiaoChi.ContextMenuUtils;
	import xiaoChi.WindowController;
	import xiaoChi.MapEditor.MEDocument;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.display.NativeWindow;
	import flash.permissions.PermissionStatus;
	import flash.events.PermissionEvent;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.utils.ByteArray;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.desktop.NativeApplication;
	import flash.events.InvokeEvent;
	import flash.desktop.InvokeEventReason;

	public class MEDManager extends EventDispatcher {
		private static var _mainWindow: NativeWindow;
		private static const application: NativeApplication = NativeApplication.nativeApplication;
		internal static const MEDList: Array = new Array();
		internal static var currentMED: MEDocument; //当前查看的MED文档
		internal static const fileRef: File = File.desktopDirectory;
		private static const fileStream: FileStream = new FileStream();
		private static const filtersForOpen: Array = new Array(new FileFilter("MapEditor文档", "*.med"), new FileFilter("所有文件", "*.*"));
		private static var tempArray: Array = new Array(); //File API冲突，该Array用于暂存可见的子窗口
		private static var numUnnamed: uint = 1; //未命名-numUnnamed.med
		public static function set mainWindow(value: NativeWindow) {
			if (!_mainWindow) {
				_mainWindow = value;
			}
		}

		public static function init() {
			ContextMenuUtils.getItemByLabel("关闭").enabled = false;
			ContextMenuUtils.getItemByLabel("保存").enabled = false;
			ContextMenuUtils.getItemByLabel("另存为…").enabled = false;
			ContextMenuUtils.getItemByLabel("导出为PNG图像").enabled = false;
			ContextMenuUtils.getItemByLabel("新建对象").enabled = false;
			ContextMenuUtils.getItemByLabel("导入").enabled = false;
			ContextMenuUtils.getItemByLabel("新建").addEventListener(Event.SELECT, createFile);
			ContextMenuUtils.getItemByLabel("打开").addEventListener(Event.SELECT, openFile);
			ContextMenuUtils.getItemByLabel("关闭").addEventListener(Event.SELECT, closeFile);
			ContextMenuUtils.getItemByLabel("保存").addEventListener(Event.SELECT, saveFile);
			ContextMenuUtils.getItemByLabel("另存为…").addEventListener(Event.SELECT, saveAsFile);
			ContextMenuUtils.getItemByLabel("导入").addEventListener(Event.SELECT, importResource);
			application.addEventListener(InvokeEvent.INVOKE, invokeMapEditor);
		}

		internal static function permissionRequest(fromFunc: Function = null): Boolean {
			var b: Boolean = false;
			switch (File.permissionStatus) {
				case PermissionStatus.UNKNOWN:
					fileRef.requestPermission();
					fileRef.addEventListener(PermissionEvent.PERMISSION_STATUS, permissionStatus);
					break;
				case PermissionStatus.GRANTED:
					b = true;
					break;
				case PermissionStatus.ONLY_WHEN_IN_USE:
					b = true;
					break;
				case PermissionStatus.DENIED:
					fileRef.requestPermission();
					fileRef.addEventListener(PermissionEvent.PERMISSION_STATUS, permissionStatus);
					break;
			}
			return b;
			function permissionStatus(e: PermissionEvent) {
				if ((File.permissionStatus == PermissionStatus.GRANTED || File.permissionStatus == PermissionStatus.ONLY_WHEN_IN_USE) && fromFunc is Function) {
					fromFunc(new Event(""));
				}
			}
		}

		internal static function createFile(e: Event) {
			var med: MEDocument = new MEDocument();
			med.create();
			pushIntoMEDList("未命名-" + numUnnamed+++".med", med);
		}
		internal static function openFile(e: Event) {
			var i: uint;
			if (permissionRequest(openFile)) {
				if (_mainWindow) {
					i = 0;
					while (i < _mainWindow.listOwnedWindows().length) {
						if (_mainWindow.listOwnedWindows()[i].visible) {
							tempArray.push(_mainWindow.listOwnedWindows()[i]);
							_mainWindow.listOwnedWindows()[i].visible = false;
						}
						i++;
					}
				}
				try {
					fileRef.browseForOpen("打开", filtersForOpen);
					fileRef.addEventListener(Event.SELECT, openSelected);
					fileRef.addEventListener(Event.CANCEL, openCanceled);
				} catch (err: Error) {
					trace(err.message);
				}
			}
		}
		private static function openSelected(e: Event) {
			var i: uint;
			var bytes: ByteArray = new ByteArray();
			var med: MEDocument = new MEDocument();
			fileRef.removeEventListener(Event.SELECT, openSelected);
			fileRef.removeEventListener(Event.CANCEL, openCanceled);
			trace("打开：" + decodeURI(fileRef.url));
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
			i = 0;
			while (i < MEDList.length) {
				if ((MEDList[i][0] as MEDocument).path == fileRef.url) {
					break;
				} else {
					i++;
				}
			}
			if (i < MEDList.length) {
				focusOnMED(i);
			} else {
				fileStream.open(fileRef, FileMode.READ);
				fileStream.readBytes(bytes);
				fileStream.close();
				med.fromBytes(bytes);
				bytes.clear();
				pushIntoMEDList(fileRef.name, med);
			}
		}
		private static function openCanceled(e: Event) {
			fileRef.removeEventListener(Event.SELECT, openSelected);
			fileRef.removeEventListener(Event.CANCEL, openCanceled);
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
		}

		internal static function closeFile(e: Event) {
			//
		}

		internal static function saveFile(e: Event) {
			var i: uint;
			if (permissionRequest(saveAsFile)) {
				if (_mainWindow) {
					i = 0;
					while (i < _mainWindow.listOwnedWindows().length) {
						if (_mainWindow.listOwnedWindows()[i].visible) {
							tempArray.push(_mainWindow.listOwnedWindows()[i]);
							_mainWindow.listOwnedWindows()[i].visible = false;
						}
						i++;
					}
				}
				replaceURLWithCurrentMED();
				try {
					fileRef.addEventListener(Event.SELECT, saveSelected);
					fileRef.addEventListener(Event.CANCEL, saveCanceled);
					if (currentMED.path == fileRef.url) {
						fileRef.dispatchEvent(new Event(Event.SELECT));
					} else {
						fileRef.browseForSave("保存");
					}
				} catch (err: Error) {
					trace(err.message);
				}
			}
		}
		private static function saveSelected(e: Event) {
			var i: uint;
			fileRef.removeEventListener(Event.SELECT, saveSelected);
			fileRef.removeEventListener(Event.CANCEL, saveCanceled);
			if (!fileRef.url.match(/.med$/)) {
				fileRef.url += ".med";
			}
			trace("保存：" + decodeURI(fileRef.url));
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
			fileStream.open(fileRef, FileMode.UPDATE);
			fileStream.writeBytes(currentMED.toBytes());
			fileStream.truncate();
			fileStream.close();
			i = 0;
			while (i < MEDList.length) {
				if (MEDList[i][0] == currentMED) {
					currentMED.fileName = fileRef.name;
					currentMED.path = fileRef.url;
					((MEDList[i][1] as Sprite).getChildAt(0) as TextField).text = currentMED.fileName;
					if ((_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.content) {
						if ((_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.currentTarget == currentMED.scene) {
							(_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.focusOn(currentMED.scene, currentMED.fileName);
						}
					}
					break;
				}
				i++;
			}
			ContextMenuUtils.getItemByLabel("保存").enabled = false;
		}
		private static function saveCanceled(e: Event) {
			fileRef.removeEventListener(Event.SELECT, saveSelected);
			fileRef.removeEventListener(Event.CANCEL, saveCanceled);
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
		}

		internal static function saveAsFile(e: Event) {
			var i: uint;
			if (permissionRequest(saveAsFile)) {
				if (_mainWindow) {
					i = 0;
					while (i < _mainWindow.listOwnedWindows().length) {
						if (_mainWindow.listOwnedWindows()[i].visible) {
							tempArray.push(_mainWindow.listOwnedWindows()[i]);
							_mainWindow.listOwnedWindows()[i].visible = false;
						}
						i++;
					}
				}
				replaceURLWithCurrentMED();
				try {
					fileRef.browseForSave("另存为");
					fileRef.addEventListener(Event.SELECT, saveAsSelected);
					fileRef.addEventListener(Event.CANCEL, saveAsCanceled);
				} catch (err: Error) {
					trace(err.message);
				}
			}
		}
		private static function saveAsSelected(e: Event) {
			var i: uint;
			fileRef.removeEventListener(Event.SELECT, saveAsSelected);
			fileRef.removeEventListener(Event.CANCEL, saveAsCanceled);
			if (!fileRef.url.match(/.med$/)) {
				fileRef.url += ".med";
			}
			trace("另存为：" + decodeURI(fileRef.url));
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
			fileStream.open(fileRef, FileMode.UPDATE);
			fileStream.writeBytes(currentMED.toBytes());
			fileStream.truncate();
			fileStream.close();
			i = 0;
			while (i < MEDList.length) {
				if (MEDList[i][0] == currentMED) {
					currentMED.fileName = fileRef.name;
					currentMED.path = fileRef.url;
					((MEDList[i][1] as Sprite).getChildAt(0) as TextField).text = currentMED.fileName;
					if ((_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.content) {
						if ((_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.currentTarget == currentMED.scene) {
							(_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.focusOn(currentMED.scene, currentMED.fileName);
						}
					}
					break;
				}
				i++;
			}
		}
		private static function saveAsCanceled(e: Event) {
			fileRef.removeEventListener(Event.SELECT, saveAsSelected);
			fileRef.removeEventListener(Event.CANCEL, saveAsCanceled);
			while (tempArray.length) {
				(tempArray[0] as NativeWindow).visible = true;
				tempArray.removeAt(0);
			}
		}
		private static function importResource(e: Event) {
			fileRef.browseForOpen("选择导入素材", new Array(new FileFilter("支持的图像类型", "*.jpg;*.png;*.gif;*.jpeg")));
			fileRef.addEventListener(Event.SELECT, importSelected);
			fileRef.addEventListener(Event.CANCEL, importCanceled);
		}
		private static function importSelected(e: Event) {
			MEDManager.currentMED.addResource(fileRef);
			fileRef.removeEventListener(Event.SELECT, importSelected);
			fileRef.removeEventListener(Event.CANCEL, importCanceled);
		}
		private static function importCanceled(e: Event) {
			fileRef.removeEventListener(Event.SELECT, importSelected);
			fileRef.removeEventListener(Event.CANCEL, importCanceled);
		}

		private static function invokeMapEditor(e: InvokeEvent) {
			if (e.arguments[0]) {
				fileRef.nativePath = e.arguments[0];
				fileRef.addEventListener(Event.SELECT, openSelected);
				fileRef.dispatchEvent(new Event(Event.SELECT));
			}
		}

		private static function pushIntoMEDList(fileName: String, med: MEDocument) {
			var noOwnWindow: Boolean = true;
			var i: uint = 0;
			var item: Sprite;
			while (i < WindowController.magnetWindows.length) {
				if (WindowController.magnetWindows[i].length) {
					noOwnWindow = false;
					break;
				} else {
					i++;
				}
			}
			if (noOwnWindow) {
				ContextMenuUtils.getItemByLabel("默认布局").dispatchEvent(new Event(Event.SELECT));
			}
			med.fileName = fileName;
			if (!fileRef.isDirectory) {
				med.path = fileRef.url;
			}
			MEDList.push(new Array(med, null)); //[n][0]为MED文档对象，[n][1]为MED标签
			currentMED = med;
			WindowController.changeMainWindowTitle(currentMED.fileName);
			if ((_mainWindow.stage.getChildAt(0) as Main).viewPanel.content) {
				item = (_mainWindow.stage.getChildAt(0) as Main).viewPanel.addMEDItem(med.fileName);
				MEDList[MEDList.length - 1][1] = item;
				(_mainWindow.stage.getChildAt(0) as Main).viewPanel.selectItem(item);
				(item.getChildAt(0) as TextField).addEventListener(MouseEvent.CLICK, selectItem);
				(item.getChildAt(1) as Sprite).addEventListener(MouseEvent.CLICK, closeItem);
			}
			focusOnMED(MEDList.length - 1);
		}
		internal static function addListenerForEveryItem() { //为后打开的ViewPanel提供
			var i: uint = 0;
			var item: Sprite;
			while (i < MEDList.length) {
				item = MEDList[i][1];
				(item.getChildAt(0) as TextField).addEventListener(MouseEvent.CLICK, selectItem);
				(item.getChildAt(1) as Sprite).addEventListener(MouseEvent.CLICK, closeItem);
				if (MEDList[i][0] == currentMED) {
					focusOnMED(i);
				}
				i++;
			}
		}
		internal static function focusOnMED(index: uint) {
			var labelText: String;
			currentMED.removeEventListener("update", updateLibList);
			currentMED = MEDList[index][0] as MEDocument;
			currentMED.addEventListener("update", updateLibList);
			if (MEDList[index][1]) {
				labelText = ((MEDList[index][1] as Sprite).getChildAt(0) as TextField).text;
				if (labelText.match(/\*$/)) {
					ContextMenuUtils.getItemByLabel("保存").enabled = true;
				} else {
					ContextMenuUtils.getItemByLabel("保存").enabled = false;
				}
			}
			ContextMenuUtils.getItemByLabel("关闭").enabled = true;
			ContextMenuUtils.getItemByLabel("另存为…").enabled = true;
			ContextMenuUtils.getItemByLabel("导出为PNG图像").enabled = true;
			ContextMenuUtils.getItemByLabel("新建对象").enabled = true;
			ContextMenuUtils.getItemByLabel("导入").enabled = true;
			WindowController.changeMainWindowTitle(currentMED.fileName);
			if ((_mainWindow.stage.getChildAt(0) as Main).viewPanel.content) {
				(_mainWindow.stage.getChildAt(0) as Main).viewPanel.selectItem(MEDList[index][1]);
			}
			(_mainWindow.stage.getChildAt(0) as Main).viewPanel.backgroundColor = currentMED.scene.@backgroundColor;
			(_mainWindow.stage.getChildAt(0) as Main).viewPanel.curTarget = currentMED.scene;
			(_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.focusOn(currentMED.scene, currentMED.fileName);
			(_mainWindow.stage.getChildAt(0) as Main).libraryPanel.queryMED();
			(_mainWindow.stage.getChildAt(0) as Main).layerPanel.clean();
			(_mainWindow.stage.getChildAt(0) as Main).viewPanel.refreshView();
		}
		private static function closeMED(index: uint) {
			var closedMED: MEDocument;
			if ((_mainWindow.stage.getChildAt(0) as Main).viewPanel.content) {
				(_mainWindow.stage.getChildAt(0) as Main).viewPanel.closeItem(MEDList[index][1]);
			}
			closedMED = MEDList[index][0] as MEDocument;
			MEDList.removeAt(index);
			if (MEDList.length > 0) {
				if (closedMED == currentMED) { //如果被关闭的MED是当前查看的MED，就查看其它MED
					if (index == 0) {
						currentMED = MEDList[index][0] as MEDocument;
						focusOnMED(index);
					} else {
						currentMED = MEDList[index - 1][0] as MEDocument;
						focusOnMED(index - 1);
					}
				}
			} else {
				currentMED = null;
				ContextMenuUtils.getItemByLabel("关闭").enabled = false;
				ContextMenuUtils.getItemByLabel("保存").enabled = false;
				ContextMenuUtils.getItemByLabel("另存为…").enabled = false;
				ContextMenuUtils.getItemByLabel("导出为PNG图像").enabled = false;
				ContextMenuUtils.getItemByLabel("新建对象").enabled = false;
				ContextMenuUtils.getItemByLabel("导入").enabled = false;
				WindowController.changeMainWindowTitle();
				(_mainWindow.stage.getChildAt(0) as Main).libraryPanel.clean();
				(_mainWindow.stage.getChildAt(0) as Main).layerPanel.clean();
				(_mainWindow.stage.getChildAt(0) as Main).viewPanel.clean();
				(_mainWindow.stage.getChildAt(0) as Main).propertiesPanel.clean();
			}
			trace(closedMED.fileName + "已关闭。");
		}
		private static function selectItem(e: MouseEvent) {
			var i: uint;
			(_mainWindow.stage.getChildAt(0) as Main).viewPanel.selectItem(e.target.parent);
			i = 0;
			while (i < MEDList.length) {
				if (MEDList[i][1] == e.target.parent) {
					focusOnMED(i);
					break;
				} else {
					i++;
				}
			}
			WindowController.changeMainWindowTitle((e.target as TextField).text.replace(/\*$/));
		}
		private static function closeItem(e: MouseEvent) {
			var w: NativeWindow;
			var i: uint;
			var t: Sprite = e.target as Sprite;
			if (e.target.parent.getChildAt(0).text.match(/\*$/)) {
				w = standardIO("要保存" + e.target.parent.getChildAt(0).text.replace(/\*$/, "") + "的更改吗？", true, true, true);
				w.addEventListener(STDIOEvent.ACCEPT, accepted);
				w.addEventListener(STDIOEvent.REFUSE, refused);
			} else {
				refused(new STDIOEvent(STDIOEvent.REFUSE));
			}
			function accepted(e: STDIOEvent) {
				w.removeEventListener(STDIOEvent.ACCEPT, accepted);
				w.removeEventListener(STDIOEvent.REFUSE, refused);
				replaceURLWithCurrentMED();
				fileRef.addEventListener(Event.SELECT, saveSelected);
				fileRef.addEventListener(Event.CANCEL, saveCanceled);
				if (currentMED.path == fileRef.url) {
					fileRef.dispatchEvent(new Event(Event.SELECT));
				} else {
					fileRef.browseForSave("保存");
				}
			}
			function refused(e: STDIOEvent) {
				if (w) {
					w.removeEventListener(STDIOEvent.ACCEPT, accepted);
					w.removeEventListener(STDIOEvent.REFUSE, refused);
				}
				i = 0;
				while (i < MEDList.length) {
					if (MEDList[i][1] == t.parent) {
						closeMED(i);
						break;
					} else {
						i++;
					}
				}
			}
		}

		private static function replaceURLWithCurrentMED() {
			if (currentMED.path) {
				fileRef.url = currentMED.path;
			} else {
				if (fileRef.isDirectory) {
					fileRef.url = fileRef.url + "/" + currentMED.fileName;
				} else {
					fileRef.url = fileRef.url.replace(/\/?[^\/]*?$/, "/" + currentMED.fileName);
				}
			}
		}
		internal static function markMEDItem(med: MEDocument) {
			var i: uint;
			if ((_mainWindow.stage.getChildAt(0) as Main).viewPanel.content) {
				i = 0;
				while (i < MEDList.length) {
					if (MEDList[i][0] == med) {
						if (!((MEDList[i][1] as Sprite).getChildAt(0) as TextField).text.match(/\*$/)) {
							((MEDList[i][1] as Sprite).getChildAt(0) as TextField).text += "*";
							ContextMenuUtils.getItemByLabel("保存").enabled = true;
						}
						break;
					} else {
						i++;
					}
				}
			}
		}

		internal static function updateLibList(e: Event) {
			markMEDItem(currentMED);
			(_mainWindow.stage.getChildAt(0) as Main).libraryPanel.queryMED();
			(_mainWindow.stage.getChildAt(0) as Main).viewPanel.refreshView();
		}

	}

}