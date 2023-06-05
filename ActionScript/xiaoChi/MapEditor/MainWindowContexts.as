package xiaoChi.MapEditor {
	import xiaoChi.ContextMenuBox;
	import xiaoChi.ContextMenuUtils;
	import flash.events.Event;
	import flash.display.NativeMenuItem;

	public class MainWindowContexts {

		public static function init() {
			var i: uint = 0;
			addMainWindowContext(new ContextMenuBox("文件", "F"));
			addMenuItem("新建(N)", "n", true);
			addMenuItem("打开", "o", true);
			addMenuItem("关闭(C)");
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("保存(S)", "s", true);
			addMenuItem("另存为(A)…", "s", true, true);
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("导出为PNG图像", "e", true);
			i++;
			addMainWindowContext(new ContextMenuBox("编辑", "E"));
			/*
			addMenuItem("撤销(U)", "z", true);
			addMenuItem("重做(R)", "z", true, false, true);
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("剪切(T)", "x", true);
			addMenuItem("复制(C)", "c", true);
			addMenuItem("粘贴(P)", "v", true);
			addMenuItem("全选(A)", "a", true);
			addMenuItem("", null, false, false, false, true); //分隔符
			*/ //暂缓开发
			addMenuItem("新建对象", "c", true, true);
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("导入");
			i++;
			addMainWindowContext(new ContextMenuBox("模拟", "S"));
			addMenuItem("在MapEditor中预览（AIR平台）", "f", true);
			i++;
			addMainWindowContext(new ContextMenuBox("窗口", "W"));
			addMenuItem("属性");
			addMenuItem("工具(T)", "t", true);
			addMenuItem("资源(R)", "r", true);
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("视口");
			addMenuItem("图层");
			addMenuItem("", null, false, false, false, true); //分隔符
			addMenuItem("默认布局");
			i++;
			addMainWindowContext(new ContextMenuBox("帮助", "H"));
			addMenuItem("MapEditor 帮助");
			addMenuItem("关于MapEditor(A)");
			i++;
			function addMainWindowContext(contextBox: ContextMenuBox) {
				ContextMenuUtils.addMainWindowContext(contextBox);
			}
			function addMenuItem(description: String, shortcutKey: String = null, ctrlKey: Boolean = false, altKey: Boolean = false, shiftKey: Boolean = false, isSeparator: Boolean = false) {
				ContextMenuUtils.getMainWindowContextAt(i).addMenuItem(description, shortcutKey, ctrlKey, altKey, shiftKey, isSeparator);
			}
		}

	}

}