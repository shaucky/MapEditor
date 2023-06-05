package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.Panel;
	import xiaoChi.ContextMenuUtils;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;

	public class LayerPanel extends Panel {
		private var currentLayer: String = "显示全部";
		private var allLayerItem: Sprite;
		private const allLayerButton: SimpleButton = new SimpleButton();
		private var objectLayerItem: Sprite;
		private const objectLayerButton: SimpleButton = new SimpleButton();
		private var groundLayerItem: Sprite;
		private const groundLayerButton: SimpleButton = new SimpleButton();
		private var hitLayerItem: Sprite;
		private const hitLayerButton: SimpleButton = new SimpleButton();

		public function LayerPanel(parentFrame: Sprite) {
			super(parentFrame);
			title = "图层";
			tag = "layer";
			((getChildAt(0) as Sprite).getChildAt(0) as TextField).text = window.title;
			window.width = 125;
			defaultWidth = 125;
			window.height = 125;
			defaultHeight = 125;
			stage.addEventListener(Event.RESIZE, stageResize);
			contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
		}
		private function resizeContent() {
			var accY: Number = 0;
			addLayerItem(allLayerButton, allLayerItem);
			addLayerItem(objectLayerButton, objectLayerItem);
			addLayerItem(groundLayerButton, groundLayerItem);
			//addLayerItem(hitLayerButton, hitLayerItem); //暂缓开发
			function addLayerItem(layerButton: SimpleButton, layerItem: Sprite) {
				content.addChild(layerButton);
				layerButton.y = accY;
				layerItem.getChildAt(0).y = ((stage.stageHeight - 35) / 4 - layerItem.getChildAt(0).height) / 2;
				layerItem.graphics.clear();
				layerItem.graphics.lineStyle(1, 0x000000);
				if (currentLayer == (layerItem.getChildAt(0) as TextField).text) {
					layerItem.graphics.beginFill(0x555555, 1);
				} else {
					layerItem.graphics.beginFill(0x555555, 0);
				}
				layerItem.graphics.drawRect(0, 0, stage.stageWidth - 1, (stage.stageHeight - 35) / 3);
				layerItem.graphics.endFill();
				accY += (stage.stageHeight - 35) / 3; //算上碰撞层3应改为4，上同
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
			allLayerItem = new(content as Object).LayerItem();
			allLayerItem.getChildAt(0).x = 50;
			(allLayerItem.getChildAt(0) as TextField).text = "显示全部";
			setButton(allLayerButton, allLayerItem);
			allLayerButton.addEventListener(MouseEvent.CLICK, focusAllLayer);
			objectLayerItem = new(content as Object).LayerItem();
			objectLayerItem.getChildAt(0).x = 50;
			(objectLayerItem.getChildAt(0) as TextField).text = "对象层";
			setButton(objectLayerButton, objectLayerItem);
			objectLayerButton.addEventListener(MouseEvent.CLICK, focusObjectLayer);
			groundLayerItem = new(content as Object).LayerItem();
			groundLayerItem.getChildAt(0).x = 50;
			(groundLayerItem.getChildAt(0) as TextField).text = "地形层";
			setButton(groundLayerButton, groundLayerItem);
			groundLayerButton.addEventListener(MouseEvent.CLICK, focusGroundLayer);
			/*
			hitLayerItem = new(content as Object).LayerItem();
			hitLayerItem.getChildAt(0).x = 50;
			(hitLayerItem.getChildAt(0) as TextField).text = "碰撞层";
			setButton(hitLayerButton, hitLayerItem);
			hitLayerButton.addEventListener(MouseEvent.CLICK, focusHitLayer);
			*/ //暂缓开发
			resizeContent();
			function setButton(button: SimpleButton, item: Sprite) {
				button.upState = item;
				button.overState = item;
				button.downState = item;
				button.hitTestState = item;
				button.addEventListener(MouseEvent.CLICK, clickItem);
			}
		}
		private function clickItem(e: MouseEvent) {
			currentLayer = (((e.target as SimpleButton).upState as Sprite).getChildAt(0) as TextField).text;
			resizeContent();
		}

		internal function clean() {
			if (content) {
				allLayerButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
		}

		private function focusAllLayer(e: MouseEvent) {
			if (MEDManager.currentMED) {
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curTarget = MEDManager.currentMED.scene;
				(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			}
		}
		private function focusObjectLayer(e: MouseEvent) {
			if (MEDManager.currentMED) {
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curTarget = MEDManager.currentMED.scene.child("objects")[0];
				(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			}
		}
		private function focusGroundLayer(e: MouseEvent) {
			if (MEDManager.currentMED) {
				(window.owner.stage.getChildAt(0) as Main).viewPanel.curTarget = MEDManager.currentMED.scene.child("floor")[0];
				(window.owner.stage.getChildAt(0) as Main).viewPanel.refreshView();
			}
		}
	}

}