package xiaoChi {
	import xiaoChi.OS;
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.NativeMenu;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.NativeMenuItem;
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;

	public class ContextMenuBox extends Sprite {
		internal static var operatorSystem: String;
		private var _id: String;
		private var _shortcutKey: String;
		private var tf: TextField;
		public const menu: NativeMenu = new NativeMenu();
		internal function get id(): String {
			return _id;
		}
		internal function get shortcutKey(): String {
			return _shortcutKey;
		}

		public function ContextMenuBox(id: String, shortcutKey: String) {
			if (shortcutKey.length > 1) {
				throw (new SecurityError("Error: ContextMenuBox的快捷键应当为1个字符。"));
			}
			_id = id;
			_shortcutKey = shortcutKey.toLowerCase();
			if (operatorSystem == OS.WIN) {
				tf = (this.getChildAt(0) as TextField);
				tf.text = _id + "(" + _shortcutKey.toUpperCase() + ")";
				this.addEventListener(MouseEvent.CLICK, showMyMenu);
			} else if (operatorSystem == OS.MAC) {
				NativeApplication.nativeApplication.menu.addSubmenu(menu, _id);
			}
		}
		public function addMenuItem(description: String, shortcutKey: String = null, ctrlKey: Boolean = false, altKey: Boolean = false, shiftKey: Boolean = false, isSeparator: Boolean = false): NativeMenuItem {
			var item: NativeMenuItem;
			var itemLabel: String;
			var keyEquivalent: String;
			var keyEquivalentModifiers: Array = new Array();
			if (operatorSystem == OS.MAC) {
				description = description.replace(/\([A-z]\)/g, "");
			}
			itemLabel = description;
			itemLabel += "                    ";
			item = new NativeMenuItem(itemLabel, isSeparator);
			if (shortcutKey) {
				if (shortcutKey.length > 1) {
					throw (new SecurityError("Error: NativeMenuItem的快捷键应当为1个字符。"));
				}
				if (ctrlKey && operatorSystem == OS.WIN) {
					keyEquivalentModifiers.push(Keyboard.CONTROL);
				}
				if (ctrlKey && operatorSystem == OS.MAC) {
					keyEquivalentModifiers.push(Keyboard.COMMAND);
				}
				if (altKey) {
					keyEquivalentModifiers.push(Keyboard.ALTERNATE);
				}
				if (shiftKey) {
					keyEquivalent = shortcutKey.toUpperCase();
				} else {
					keyEquivalent = shortcutKey.toLowerCase();
				}
			}
			item.keyEquivalent = keyEquivalent;
			item.keyEquivalentModifiers = keyEquivalentModifiers;
			menu.addItem(item);
			return item;
		}
		internal function showMyMenu(e: Event) {
			var stageX: Number = 0;
			var stageY: Number = 0;
			var par: DisplayObject;
			par = this;
			do {
				stageX += par.x;
				par = par.parent;
			} while (par.parent);
			par = this;
			do {
				stageY += par.y;
				par = par.parent;
			} while (par.parent);
			stageY += this.height;
			menu.display(this.stage, stageX, stageY);
		}
	}

}