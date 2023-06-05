package xiaoChi {
	import xiaoChi.ContextMenuBox;
	import xiaoChi.WindowController;
	import flash.display.Sprite;
	import flash.display.NativeMenuItem;
	import flash.display.NativeMenu;

	public class ContextMenuUtils {
		private static var _frame: Sprite;

		public static function set frame(value: Sprite) {
			if (!_frame) {
				_frame = value;
			} else {
				throw (new SecurityError("Error: 不能重复设置ContextMenuUtils的frame属性。"));
			}
		}
		public static function get frame(): Sprite {
			return _frame;
		}
		public static function addMainWindowContext(contextBox: ContextMenuBox) {
			WindowController.addMainWindowContext(contextBox);
		}
		public static function removeMainWindowContext(contextBox: ContextMenuBox) {
			WindowController.removeMainWindowContext(contextBox);
		}
		public static function getMainWindowContextAt(index: uint): ContextMenuBox {
			return WindowController.getMainWindowContextAt(index);
		}
		public static function getItemByLabel(lbl: String): NativeMenuItem {
			const maxNum: uint = WindowController.numContext;
			var item: NativeMenuItem = null;
			var i: uint = 0;
			while (maxNum > i && item == null) {
				item = matchLabel(lbl + "                    ", WindowController.getMainWindowContextAt(i).menu);
				i++;
			}
			return item;
		}
		private static function matchLabel(lbl: String, menu: NativeMenu): NativeMenuItem {
			var i: uint = 0;
			while (i < menu.numItems) {
				if (menu.items[i] is NativeMenuItem) {
					if ((menu.items[i] as NativeMenuItem).label.replace(/\([A-z]\)/g, "") == lbl) {
						return menu.items[i] as NativeMenuItem;
					}
				} else if (menu.items[i] is NativeMenu) {
					matchLabel(lbl, menu.items[i] as NativeMenu);
				}
				i++;
			}
			return null;
		}
		public static function jumpOut() {
			_frame = null;
		}

	}

}