package xiaoChi.MapEditor {
	import xiaoChi.standardIO;
	import flash.utils.ByteArray;
	import flash.filesystem.File;
	import flash.display.BitmapData;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.events.EventDispatcher;
	import flash.display.SWFVersion;
	import flash.display.ActionScriptVersion;

	public class MEDocument extends EventDispatcher {
		internal var fileName: String = "";
		internal var path: String;
		private var _infoTree: XML;
		private var _scene: XML;
		private var _objects: XML;
		private var _floor: XML;
		private var _library: XML;
		private const byteArrays: Array = new Array();
		private static const safeSoftwareList: Array = new Array("MapEditor 1.x");
		private static const head: String = "MED application/x-med";
		private static const headswf: String = "application/x-shockwave-flash";
		private static const utf8: String = "utf-8";

		public function get infoTree(): XML {
			return _infoTree;
		}
		public function get scene(): XML {
			return _scene;
		}
		public function get library(): XML {
			return _library;
		}

		public function MEDocument() {
			//nothing
		}
		public function create() {
			_infoTree = new XML("<med></med>");
			_infoTree.@version = "1.0"; //MED版本号
			_infoTree.@type = "classic2D"; //MED文档类型
			_infoTree.@software = "MapEditor 1.x"; //MED编辑器版本
			_scene = new XML("<scene></scene>");
			_infoTree.appendChild(_scene);
			_scene.@unitLength = "50"; //场景单元格长度
			_scene.@sceneWidth = "20"; //场景宽度（单元格数量）
			_scene.@sceneHeight = "11"; //场景高度（单元格数量）
			_scene.@backgroundColor = "0xffffff"; //背景颜色
			_objects = new XML("<objects></objects>");
			_scene.appendChild(_objects);
			_floor = new XML("<floor></floor>");
			_scene.appendChild(_floor);
			_library = new XML("<library></library>");
			_infoTree.appendChild(_library);
			trace(_infoTree.toXMLString());
		}
		public function fromBytes(bytes: ByteArray) {
			const treeString: ByteArray = new ByteArray();
			var version: Number = 0;
			var byteHead: String;
			var len: uint = 0;
			var libLength: uint;
			var i: uint;
			var resBytes: ByteArray;
			var resLength: uint;
			try {
				bytes.position = 0;
				byteHead = bytes.readMultiByte(head.length, utf8);
				if (byteHead == head) {
					trace("当前打开文件是MED文档。");
				} else {
					notMED();
				}
				if (uint(bytes.readByte()) != 20) {
					notMED();
				}
				bytes.position = 40; //从第41位开始读详细内容
				len = uint(bytes.readUnsignedInt());
				trace(len);
				treeString.writeBytes(bytes, bytes.position, len);
				bytes.position += len;
				treeString.inflate();
				_infoTree = new XML(treeString.readMultiByte(treeString.length, utf8));
				_scene = _infoTree.child("scene")[0];
				_objects = _scene.child("objects")[0];
				_floor = _scene.child("floor")[0];
				_library = _infoTree.child("library")[0];
				if (uint(bytes.readByte()) != 18) {
					notMED();
				}
				trace(_infoTree.toXMLString());
				if (1.0 < Number(String(_infoTree.@version).match(/^[0-9]+.[0-9]+/)[0])) {
					standardIO("当前打开的文档是由" + _infoTree.@software + "创建的，当前版本的MapEditor不支持。", false, false, true);
				} else {
					if (uint(bytes.readUnsignedInt()) != 0x20181122) {
						notMED();
					}
					libLength = uint(bytes.readUnsignedInt());
					trace("资源数目：" + libLength);
					if (libLength != _library.child("resource").length()) {
						throw (new Error("Error: 文档异常，信息树记录的资源数目与文档后续存储的资源数目不符。"));
					}
					i = 0;
					while (i < libLength) {
						resLength = uint(bytes.readUnsignedInt());
						if (resLength != 0) {
							resBytes = new ByteArray();
							resBytes.writeBytes(bytes, bytes.position, resLength);
							bytes.position += resLength;
							resBytes.inflate();
							byteArrays.push(resBytes);
						} else {
							byteArrays.push(null);
						}
						if (uint(bytes.readByte()) != 11) {
							notMED();
						}
						i++;
					}
					if (uint(bytes.readByte()) != 22) {
						notMED();
					}
				}
			} catch (err: Error) {
				notMED(err.message);
			}
			function notMED(addition: String = null) {
				if (addition) {
					standardIO("Error: 当前打开文件不是MED文档。\n(" + addition + ")");
				} else {
					standardIO("Error: 当前打开文件不是MED文档。");
				}
				throw (new Error("Error: 当前打开文件不是MED文档。"));
			}
		}
		public function toBytes(): ByteArray {
			var bytes: ByteArray = new ByteArray();
			var treeString: ByteArray = new ByteArray();
			var i: uint;
			var libLength: uint;
			var resBytes: ByteArray = new ByteArray();
			bytes.writeMultiByte(head, utf8); //用于标识是MED文档
			bytes.writeByte(20); //标识+1
			bytes.position = 40; //从第41位开始写详细内容
			treeString.writeMultiByte(infoTree.toXMLString(), utf8);
			treeString.deflate(); //压缩infoTree
			bytes.writeUnsignedInt(treeString.length); //写入infoTree压缩后的字节长度
			trace(treeString.length)
			bytes.writeBytes(treeString); //写入infoTree
			bytes.writeByte(18); //标识+1
			bytes.writeUnsignedInt(0x20181122); //标记文档信息树部分结束，文档资源数据部分开始
			libLength = _library.child("resource").length();
			bytes.writeUnsignedInt(libLength); //写入资源数目
			i = 0;
			while (i < libLength) {
				resBytes.clear();
				if (byteArrays[i]) {
					resBytes.writeBytes(byteArrays[i]);
					resBytes.deflate();
					bytes.writeUnsignedInt(resBytes.length); //写入资源压缩后的大小
					bytes.writeBytes(resBytes); //写入压缩后的资源内容
				} else {
					bytes.writeUnsignedInt(0);
				}
				bytes.writeByte(11); //标识+1
				i++;
			}
			bytes.writeByte(22); //标识+1
			return bytes;
		}

		public function getResourceBytesAt(index: uint): ByteArray {
			var ba: ByteArray;
			if (index < byteArrays.length) {
				ba = byteArrays[index];
			} else {
				throw (new Error("Error: 意料之外的索引位置！"));
			}
			return ba;
		}
		public function getResource(name: String): XML {
			var i: uint = 0;
			var lib: XMLList = _library.child("resource");
			var libLen: uint = lib.length();
			while (i < libLen) {
				if (String(lib[i].@name) == name) {
					break;
				}
				i++;
			}
			return lib[i];
		}

		public function addResource(f: File) {
			var completeNum: uint = 0;
			const completeTotal: uint = 1;
			const ldr: Loader = new Loader();
			const ba: ByteArray = new ByteArray();
			const fs: FileStream = new FileStream();
			var isSuccessful: Boolean = false;
			var i: uint = 0;
			var j: uint = 0;
			var libLen: uint;
			var libList: XMLList;
			fs.open(f, FileMode.READ);
			fs.readBytes(ba);
			fs.close();
			ba.position = 0;
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, ldrLoadComplete);
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ldrLoadError);
			try {
				ldr.loadBytes(ba);
			} catch (err: Error) { //allowCodeImport为false时加载到SWF会报错
				completeNum++;
				calcResult();
			}
			function ldrLoadComplete(e: Event) {
				ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, ldrLoadComplete);
				ldr.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ldrLoadError);
				completeNum++;
				if (e.target.contentType == headswf) {
					ldr.unload(); //出入安全性考虑，禁止载入SWF文件
				} else {
					isSuccessful = true;
					i = 0;
					j = 0;
					libList = _library.child("resource");
					libLen = libList.length();
					while (j < libLen) {
						if (libList[j].@name == f.name) {
							i = 1;
							while (libList[j].@name == f.name + "_" + String(i)) {
								i++;
							}
						}
						j++;
					}
					if (i > 0) {
						_library.appendChild(new XML("<resource name=\"" + f.name + "_" + String(i) + "\" type=\"image\" width=\"" + ldr.content.width + "\" height=\"" + ldr.content.height + "\" x=\"0\" y=\"0\"/>"));
					} else {
						_library.appendChild(new XML("<resource name=\"" + f.name + "\" type=\"image\" width=\"" + ldr.content.width + "\" height=\"" + ldr.content.height + "\" x=\"0\" y=\"0\"/>"));
					} //加入资源列表
					byteArrays.push(ba); //加入资源数据
					dispatchEvent(new Event("update"));
					trace("Load: 载入图像资源。");
				}
				calcResult();
			}
			function ldrLoadError(e: IOErrorEvent) {
				ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, ldrLoadComplete);
				ldr.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ldrLoadError);
				completeNum++;
				calcResult();
			}
			function calcResult() {
				if (completeNum == completeTotal && !isSuccessful) {
					standardIO("不支持的文件！");
				}
			}
		}
		public function addResourceAsMP3(f: File) {
			var sound: Sound = new Sound();
			sound.addEventListener(Event.COMPLETE, soundLoadComplete);
			sound.addEventListener(IOErrorEvent.IO_ERROR, soundLoadError);
			sound.load(new URLRequest(f.url));
			function soundLoadComplete(e: Event) {
				sound.removeEventListener(Event.COMPLETE, soundLoadComplete);
				sound.removeEventListener(IOErrorEvent.IO_ERROR, soundLoadError);
				trace("Load: 载入音频资源。");
			}
			function soundLoadError(e: IOErrorEvent) {
				sound.removeEventListener(Event.COMPLETE, soundLoadComplete);
				sound.removeEventListener(IOErrorEvent.IO_ERROR, soundLoadError);
				standardIO("不支持的文件！");
			}
		}
		public function updateResourceBytes(name: String, byteArray: ByteArray) {
			byteArrays[getResource(name).childIndex()] = byteArray;
			dispatchEvent(new Event("update"));
		}
		public function createObject(name: String, renamable: Boolean = false): XML {
			var obj: XML;
			var i: uint;
			var j: uint;
			var libLen: uint;
			var libList: XMLList;
			var finalName: String = name;
			i = 0;
			j = 0;
			if (!renamable) { //重名用于作为子对象只起“引用”作用
				libList = _library.child("resource");
				libLen = libList.length();
				i = 1;
				while (j < libLen) {
					if (libList[j].@name == finalName) {
						finalName = name + "_" + String(i);
						i++;
						checkNewName(finalName);
						break;
					}
					j++;
				}
			}
			obj = new XML("<resource name=\"" + finalName + "\" type=\"object\" width=\"0\" height=\"0\" x=\"0\" y=\"0\"/>");
			//_library.appendChild(obj); 创建对象和添加对象还是分开吧
			return obj;
			function checkNewName(newName: String) {
				var k: uint;
				k = 0;
				while (k < libLen) {
					if (libList[k].@name == finalName) {
						finalName = name + "_" + String(i);
						i++;
						checkNewName(finalName);
						break;
					}
					k++;
				}
			}
		}
		public function addObject(resource: XML) {
			if (resource.localName() == "resource") {
				_library.appendChild(resource);
			} else {
				throw (new SecurityError("Error: 准备添加的标签限定名称意外。"));
			}
			byteArrays.push(null);
			dispatchEvent(new Event("update"));
		}
		public function removeResource(itemName: String) {
			var i: uint;
			var target: XML;
			target = getResource(itemName);
			i = target.childIndex();
			delete getResource(itemName); //trace(target); //null
			byteArrays.removeAt(i);
			removeResourceOverLibrary(itemName, _library);
			removeResourceOverLibrary(itemName, _objects);
			removeResourceOverLibrary(itemName, _floor);
			dispatchEvent(new Event("update"));
			function removeResourceOverLibrary(itemName: String, xml: XML) {
				var j: uint = 0;
				var list: XMLList = xml.child("resource");
				var max: uint = list.length();
				while (j < max) {
					if (list[j].@name == itemName) {
						delete list[j];
						max--;
					} else {
						if (list[j].child("resource").length()) {
							removeResourceOverLibrary(itemName, list[j]);
						}
						j++;
					}
				}
			}
		}
		public function renameResource(oldName: String, newName: String) {
			var i: uint;
			var libList: XMLList;
			var libLen: uint;
			libList = _library.child("resource");
			libLen = libList.length();
			if (oldName != newName) {
				while (i < libLen) {
					if (libList[i].@name == newName) {
						standardIO("同一文档内的资源不能拥有相同命名。");
						dispatchEvent(new Event("update"));
						return;
					}
					i++;
				}
				renameResInObj(oldName, newName, _library);
				renameResInObj(oldName, newName, _objects);
				renameResInObj(oldName, newName, _floor);
				dispatchEvent(new Event("update"));
			}
			function renameResInObj(oldName: String, newName: String, obj: XML) {
				var i: uint = 0;
				const chd: XMLList = obj.child("resource");
				const len: uint = chd.length();
				while (i < len) {
					if (chd[i].@name == oldName) {
						chd[i].@name = newName;
					}
					if (chd[i].child("resource")) {
						renameResInObj(oldName, newName, chd[i]);
					}
					i++;
				}
			}
		}

		public function checkDeadlock(object: XML, tree: XML) { //用于检验是否构成循环嵌套，测试环境中会导致崩溃，用户环境内不会崩溃
			var idx: uint;
			var chd: XMLList = object.child("resource");
			var max: uint;
			var name1: String;
			var name2: String;
			var type1: String;
			var type2: String;
			name1 = String(object.@name);
			name2 = String(tree.@name);
			if (name1 != name2) {
				idx = 0;
				max = chd.length();
				while (idx < max) {
					type1 = String(chd[idx].@type);
					if (type1 == "object") {
						name1 = String(chd[idx].@name);
						name2 = String(tree.@name);
						if (name1 == name2) {
							standardIO("尝试进行的操作会导致循环嵌套。");
							throw (new Error("Error: 尝试进行的操作会导致循环嵌套。"));
						} else if (getResource(name1).child("resource")) {
							checkDeadlock(getResource(name1), tree);
						}
					}
					idx++;
				}
			} else {
				standardIO("尝试进行的操作会导致循环嵌套。");
				throw (new Error("Error: 尝试进行的操作会导致循环嵌套。"));
			}
		}

	}

}