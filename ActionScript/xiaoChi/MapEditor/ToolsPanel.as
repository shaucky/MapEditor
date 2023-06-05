package xiaoChi.MapEditor {
	import xiaoChi.MapEditor.EditAction;
	import xiaoChi.MapEditor.Panel;
	import xiaoChi.ContextMenuUtils;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;

	public class ToolsPanel extends Panel {
		private const icons: Sprite = new Sprite();
		private const cutIcon: Sprite = new Sprite();
		private const dragIcon: Sprite = new Sprite();
		private const moveIcon: Sprite = new Sprite();

		public function ToolsPanel(parentFrame: Sprite) {
			super(parentFrame);
			title = "工具";
			tag = "tools";
			((getChildAt(0) as Sprite).getChildAt(0) as TextField).text = window.title;
			window.width = 40;
			defaultWidth = 40;
			window.height = 240;
			defaultHeight = 60;
			stage.addEventListener(Event.RESIZE, stageResize);
			contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
		}
		private function resizeContent() {
			var i: uint;
			const length: Number = 25;
			const stageWidth: Number = stage.stageWidth;
			const stageHeight: Number = stage.stageHeight;
			if (stageWidth <= stageHeight - 20) { //20是标题栏高度
				if (stageWidth > 25) {
					i = 0;
					while (i < icons.numChildren) {
						icons.getChildAt(i).width = length;
						icons.getChildAt(i).height = length;
						icons.getChildAt(i).x = (stageWidth - icons.getChildAt(i).width) / 2;
						icons.getChildAt(i).y = 15 + i * (length + 15);
						i++;
					}
				} else {
					i = 0;
					while (i < icons.numChildren) {
						icons.getChildAt(i).width = stageWidth;
						icons.getChildAt(i).height = stageWidth;
						icons.getChildAt(i).x = 0;
						icons.getChildAt(i).y = i * (length + 15) + 15;
						i++;
					}
				}
			} else {
				if (stageHeight - 20 > 25) {
					i = 0;
					while (i < icons.numChildren) {
						icons.getChildAt(i).width = length;
						icons.getChildAt(i).height = length;
						icons.getChildAt(i).x = 15 + i * (length + 15);
						icons.getChildAt(i).y = (stageHeight - 20 - icons.getChildAt(i).height) / 2;
						i++;
					}
				} else {
					i = 0;
					while (i < icons.numChildren) {
						icons.getChildAt(i).width = stageHeight;
						icons.getChildAt(i).height = stageHeight;
						icons.getChildAt(i).x = i * (length + 15) + 15;
						icons.getChildAt(i).y = 0;
						i++;
					}
				}
			}
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
			content.addChild(icons);
			moveIcon.addChild(new Bitmap(new(content as Object).MoveIcon()));
			moveIcon.addEventListener(MouseEvent.CLICK, clickMove);
			icons.addChild(moveIcon);
			dragIcon.addChild(new Bitmap(new(content as Object).DragIcon()));
			dragIcon.addEventListener(MouseEvent.CLICK, clickDrag);
			icons.addChild(dragIcon);
			cutIcon.addChild(new Bitmap(new(content as Object).CutIcon()));
			cutIcon.addEventListener(MouseEvent.CLICK, clickCut);
			icons.addChild(cutIcon);
			while (i < icons.numChildren) {
				icons.getChildAt(i).addEventListener(MouseEvent.CLICK, clickIcon);
				i++;
			}
			moveIcon.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			resizeContent();
		}
		private function clickMove(e: MouseEvent) {
			(window.owner.stage.getChildAt(0) as Main).viewPanel.editAction = EditAction.MOVE;
		}
		private function clickDrag(e: MouseEvent) {
			(window.owner.stage.getChildAt(0) as Main).viewPanel.editAction = EditAction.DRAG;
		}
		private function clickCut(e: MouseEvent) {
			(window.owner.stage.getChildAt(0) as Main).viewPanel.editAction = EditAction.CUT;
		}
		private function clickIcon(e: MouseEvent) {
			var i: uint = 0;
			while (i < icons.numChildren) {
				(icons.getChildAt(i) as Sprite).graphics.clear();
				if (icons.getChildAt(i) == e.target) {
					(icons.getChildAt(i) as Sprite).graphics.beginFill(0x888888, 0.2);
					(icons.getChildAt(i) as Sprite).graphics.drawRoundRect(0, 0, icons.getChildAt(i).width / icons.getChildAt(i).scaleX, icons.getChildAt(i).height / icons.getChildAt(i).scaleY, icons.getChildAt(i).width / icons.getChildAt(i).scaleX / 10);
					(icons.getChildAt(i) as Sprite).graphics.endFill();
				}
				i++;
			}
		}

	}

}