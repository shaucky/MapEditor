package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.MEDManager;
	import xiaoChi.MapEditor.MEDocument;
	import xiaoChi.MapEditor.Panel;
	import xiaoChi.standardIO;
	import xiaoChi.ContextMenuUtils;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;

	public class PropertiesPanel extends Panel {
		private var target: XML;
		private var _targetType: String = "";
		private var _targetFile: String = "";
		private var targetName: Sprite;
		private var _fileName: String = "";
		private var viewAreaBackground: Sprite;
		private var viewAreaBackgroundColor: Number = 0x000000;
		private var unitLength: Sprite;
		private var sceneSize: Sprite;
		private var objectPosition: Sprite;
		private var imagePosition: Sprite;

		public function get currentTarget(): XML {
			return target;
		}
		public function set targetType(value: String) {
			_targetType = value;
			if (targetName) {
				(targetName.getChildAt(0) as TextField).text = _targetType;
			}
		}
		public function get targetType(): String {
			return _targetType;
		}
		public function set targetFile(value: String) {
			_targetFile = value;
			if (targetName) {
				(targetName.getChildAt(1) as TextField).text = _targetFile;
			}
		}
		public function get targetFile(): String {
			return _targetFile;
		}

		public function PropertiesPanel(parentFrame: Sprite) {
			super(parentFrame);
			title = "属性";
			tag = "properties";
			((getChildAt(0) as Sprite).getChildAt(0) as TextField).text = window.title;
			window.width = 125;
			defaultWidth = 125;
			window.height = 225;
			defaultHeight = 225;
			stage.addEventListener(Event.RESIZE, stageResize);
			contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
		}

		internal function focusOn(object: XML, fileName: String = null) {
			var xmlName: String;
			var xmlType: String;
			xmlName = object.localName();
			if (xmlName == "objects" || xmlName == "floor") {
				target = object.parent();
			} else {
				target = object;
			}
			xmlName = target.localName();
			if (xmlName == "scene") {
				targetType = "文档";
				if (fileName) {
					_fileName = fileName;
					targetFile = _fileName;
				} else {
					targetFile = _fileName;
				}
			} else if (xmlName == "resource") {
				xmlType = String(object.@type);
				switch (xmlType) {
					case "image":
						targetType = "图像";
						targetFile = object.@name;
						break;
					case "media":
						targetType = "音频";
						break;
					case "object":
						targetType = "对象";
						targetFile = object.@name;
						break;
				}
			}
			if (content) {
				while (content.numChildren) {
					content.removeChildAt(0);
				}
				content.addChild(targetName);
				switch (_targetType) {
					case "文档":
						content.addChild(viewAreaBackground);
						recordBackgroundColor(Number(target.@backgroundColor));
						content.addChild(unitLength);
						(unitLength.getChildAt(1) as TextField).text = target.@unitLength;
						content.addChild(sceneSize);
						(sceneSize.getChildAt(1) as TextField).text = target.@sceneWidth;
						(sceneSize.getChildAt(3) as TextField).text = target.@sceneHeight;
						break;
					case "图像":
						if (target.parent()) {
							if (target.parent().localName() != "library") {
								content.addChild(imagePosition);
								(imagePosition.getChildAt(1) as TextField).text = target.@x;
								(imagePosition.getChildAt(3) as TextField).text = target.@y;
							}
						}
						break;
					case "对象":
						if (target.parent()) {
							if (target.parent().localName() != "library") {
								content.addChild(objectPosition);
								(objectPosition.getChildAt(1) as TextField).text = target.@x;
								(objectPosition.getChildAt(3) as TextField).text = target.@y;
							}
						}
						break;
				}
				resizeContent();
			}
		}
		internal function clean() {
			targetType = "";
			targetFile = "";
			if (content) {
				while (content.numChildren) {
					content.removeChildAt(0);
				}
				content.addChild(targetName);
			}
		}
		private function resizeContent() {
			var lineH: Number = 0;
			content.graphics.clear();
			content.graphics.moveTo(0, 0);
			content.graphics.lineStyle(1, 0x000000);
			content.graphics.lineTo(stage.stageWidth - 1, lineH);
			targetName.x = 15;
			targetName.y = lineH + 15;
			targetName.getChildAt(0).width = stage.stageWidth - 30;
			targetName.getChildAt(1).width = stage.stageWidth - 30;
			lineH += targetName.height + 30;
			content.graphics.moveTo(0, lineH);
			content.graphics.lineTo(stage.stageWidth - 1, lineH);
			switch (_targetType) {
				case "文档":
					viewAreaBackground.x = 15;
					viewAreaBackground.y = lineH + 15;
					viewAreaBackground.graphics.clear();
					viewAreaBackground.graphics.beginFill(viewAreaBackgroundColor);
					viewAreaBackground.graphics.lineStyle(1, 0x000000);
					viewAreaBackground.graphics.drawRect(40, 0, 24, 24);
					viewAreaBackground.graphics.endFill();
					unitLength.x = 15;
					unitLength.y = lineH + 50;
					sceneSize.x = 15;
					sceneSize.y = lineH + 80;
					break;
				case "图像":
					imagePosition.x = 15;
					imagePosition.y = lineH + 15;
					break;
				case "对象":
					objectPosition.x = 15;
					objectPosition.y = lineH + 15;
					break;
			}
		}
		private function stageResize(e: Event) {
			if (content) {
				resizeContent();
			}
		}
		private function contentLoaded(e: Event) {
			content = contentLoader.content as Sprite;
			contentLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, contentLoaded);
			targetName = new(content as Object).TargetName();
			viewAreaBackground = new(content as Object).ViewAreaBackground();
			viewAreaBackground.addEventListener(MouseEvent.CLICK, backgroundColorSelect);
			unitLength = new(content as Object).UnitLength();
			(unitLength.getChildAt(1) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setUnitLength);
			sceneSize = new(content as Object).SceneSize();
			(sceneSize.getChildAt(1) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setSceneWidth);
			(sceneSize.getChildAt(3) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setSceneHeight);
			objectPosition = new(content as Object).ObjectPosition();
			(objectPosition.getChildAt(1) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setObjectX);
			(objectPosition.getChildAt(3) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setObjectY);
			imagePosition = new(content as Object).ImagePosition();
			(imagePosition.getChildAt(1) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setImageX);
			(imagePosition.getChildAt(3) as TextField).addEventListener(FocusEvent.FOCUS_OUT, setImageY); //focusOn(new XML("<scene></scene>")); //测试用
			if (target) {
				focusOn(target, _targetFile);
			}
			resizeContent();
		}

		private function backgroundColorSelect(e: MouseEvent) {
			(window.owner.stage.getChildAt(0) as Main).colorPalette.select(viewAreaBackgroundColor, "视口背景");
			(window.owner.stage.getChildAt(0) as Main).colorPalette.addEventListener(Event.SELECT, backgroundColorSelected);
		}
		private function backgroundColorSelected(e: Event) {
			setBackgroundColor((window.owner.stage.getChildAt(0) as Main).colorPalette.color);
		}
		private function recordBackgroundColor(color: Number) {
			viewAreaBackgroundColor = color;
			viewAreaBackground.graphics.clear();
			viewAreaBackground.graphics.beginFill(viewAreaBackgroundColor);
			viewAreaBackground.graphics.lineStyle(1, 0x000000);
			viewAreaBackground.graphics.drawRect(40, 0, 24, 24);
			viewAreaBackground.graphics.endFill();
		}
		private function setBackgroundColor(color: Number) {
			recordBackgroundColor(color);
			(window.owner.stage.getChildAt(0) as Main).viewPanel.backgroundColor = viewAreaBackgroundColor;
			MEDManager.currentMED.scene.@backgroundColor = "0x" + color.toString(16);
			MEDManager.markMEDItem(MEDManager.currentMED);
		}
		private function setUnitLength(e: FocusEvent) {
			if (isNaN(Number((unitLength.getChildAt(1) as TextField).text)) || Number((unitLength.getChildAt(1) as TextField).text) <= 0 || Number((unitLength.getChildAt(1) as TextField).text) > 1024) {
				(unitLength.getChildAt(1) as TextField).text = MEDManager.currentMED.scene.@unitLength;
				standardIO("需要输入大于0且不大于1024的值。");
			} else {
				(unitLength.getChildAt(1) as TextField).text = String(Math.round(Number((unitLength.getChildAt(1) as TextField).text)));
			}
			MEDManager.currentMED.scene.@unitLength = (unitLength.getChildAt(1) as TextField).text;
			(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			MEDManager.markMEDItem(MEDManager.currentMED);
		}
		private function setSceneWidth(e: FocusEvent) {
			if (isNaN(Number((sceneSize.getChildAt(1) as TextField).text)) || Number((sceneSize.getChildAt(1) as TextField).text) <= 0 || Number((sceneSize.getChildAt(1) as TextField).text) > 65536) {
				(sceneSize.getChildAt(1) as TextField).text = MEDManager.currentMED.scene.@sceneWidth;
				standardIO("需要输入大于0且不大于65536的值。");
			} else {
				(sceneSize.getChildAt(1) as TextField).text = String(Math.round(Number((sceneSize.getChildAt(1) as TextField).text)));
			}
			MEDManager.currentMED.scene.@sceneWidth = (sceneSize.getChildAt(1) as TextField).text;
			(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			MEDManager.markMEDItem(MEDManager.currentMED);
		}
		private function setSceneHeight(e: FocusEvent) {
			if (isNaN(Number((sceneSize.getChildAt(3) as TextField).text)) || Number((sceneSize.getChildAt(3) as TextField).text) <= 0 || Number((sceneSize.getChildAt(3) as TextField).text) > 65536) {
				(sceneSize.getChildAt(3) as TextField).text = MEDManager.currentMED.scene.@sceneHeight;
				standardIO("需要输入大于0且不大于65536的值。");
			} else {
				(sceneSize.getChildAt(3) as TextField).text = String(Math.round(Number((sceneSize.getChildAt(3) as TextField).text)));
			}
			MEDManager.currentMED.scene.@sceneHeight = (sceneSize.getChildAt(3) as TextField).text;
			(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			MEDManager.markMEDItem(MEDManager.currentMED);
		}
		private function setObjectX(e: FocusEvent) {
			if ((window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject) {
				if (isNaN(Number((objectPosition.getChildAt(1) as TextField).text))) {
					(objectPosition.getChildAt(1) as TextField).text = target.@x;
				} else {
					(objectPosition.getChildAt(1) as TextField).text = String(Math.round(Number(((objectPosition.getChildAt(1) as TextField).text)) * 100) / 100);
				}
				target.@x = (objectPosition.getChildAt(1) as TextField).text;
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject.x = Number(target.@x);
				MEDManager.markMEDItem(MEDManager.currentMED);
			}
		}
		private function setObjectY(e: FocusEvent) {
			if ((window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject) {
				if (isNaN(Number((objectPosition.getChildAt(3) as TextField).text))) {
					(objectPosition.getChildAt(3) as TextField).text = target.@y;
				} else {
					(objectPosition.getChildAt(3) as TextField).text = String(Math.round(Number(((objectPosition.getChildAt(3) as TextField).text)) * 100) / 100);
				}
				target.@y = (objectPosition.getChildAt(3) as TextField).text;
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject.y = Number(target.@y);
				MEDManager.markMEDItem(MEDManager.currentMED);
			}
		}
		private function setImageX(e: FocusEvent) {
			if ((window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject) {
				if (isNaN(Number((imagePosition.getChildAt(1) as TextField).text))) {
					(imagePosition.getChildAt(1) as TextField).text = target.@x;
				} else {
					(imagePosition.getChildAt(1) as TextField).text = String(Math.round(Number(((imagePosition.getChildAt(1) as TextField).text)) * 100) / 100);
				}
				target.@x = (imagePosition.getChildAt(1) as TextField).text;
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject.x = Number(target.@x);
				MEDManager.markMEDItem(MEDManager.currentMED);
			}
		}
		private function setImageY(e: FocusEvent) {
			if ((window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject) {
				if (isNaN(Number((imagePosition.getChildAt(3) as TextField).text))) {
					(imagePosition.getChildAt(3) as TextField).text = target.@y;
				} else {
					(imagePosition.getChildAt(3) as TextField).text = String(Math.round(Number(((imagePosition.getChildAt(3) as TextField).text)) * 100) / 100);
				}
				target.@y = (imagePosition.getChildAt(3) as TextField).text;
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curFocusObject.y = Number(target.@y);
				MEDManager.markMEDItem(MEDManager.currentMED);
			}
		}
	}

}