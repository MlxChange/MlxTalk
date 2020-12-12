import 'dart:async';
import 'dart:io';
import 'package:Enigma/photo_view.dart';
import 'package:Enigma/screens/profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart' as path;

import 'package:Enigma/util/const.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:Enigma/const.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Enigma/ImagePicker/image_picker.dart';
import 'package:Enigma/bubble.dart';
import 'package:Enigma/E2EE/e2ee.dart' as e2ee;
import 'package:Enigma/seen_provider.dart';
import 'package:Enigma/seen_state.dart';
import 'package:Enigma/message.dart';
import 'package:Enigma/utils.dart';
import 'package:Enigma/chat_controller.dart';
import 'package:Enigma/DataModel.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:Enigma/save.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//聊天界面
class ChatScreen extends StatefulWidget {
  //对方用户，当前用户
  final String peerNo, currentUserNo;
  //数据模型
  final DataModel model;
  //未读消息数量
  final int unread;

  ChatScreen(
      {Key key,
      @required this.currentUserNo,
      @required this.peerNo,
      @required this.model,
      @required this.unread});

  @override
  State createState() =>
      new _ChatScreenState(currentUserNo: currentUserNo, peerNo: peerNo);
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  //
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();

  //对方的头像，手机号，当前用户的手机号，私钥，分享密钥
  String peerAvatar, peerNo, currentUserNo, privateKey, sharedSecret;

  //对方用户信息和当前用户信息
  Map<String, dynamic> peer, currentUser;
  //聊天状态和未读消息
  int chatStatus, unread;

  _ChatScreenState({@required this.peerNo, @required this.currentUserNo});

  //会话id
  String chatId;
  SharedPreferences prefs;//存储

  bool typing = false;

  File imageFile;//图片文件
  bool isLoading;//是否加载状态
  String imageUrl;//图片地址
  SeenState seenState;//最近的状态
  List<Message> messages = new List<Message>();//聊天消息
  //保存的聊天消息
  List<Map<String, dynamic>> _savedMessageDocs =
      new List<Map<String, dynamic>>();

  //上传的时间
  int uploadTimestamp;

  //订阅  最近状态的订阅，消息事件的订阅，删除更新事件的订阅
  StreamSubscription seenSubscription, msgSubscription, deleteUptoSubscription;

  //消息文本框
  final TextEditingController textEditingController =
      new TextEditingController();
  //滚动控制器
  final ScrollController realtime = new ScrollController();
  //保存控制器
  final ScrollController saved = new ScrollController();
  //缓存的当前用户数据
  DataModel _cachedModel;

  @override
  //初始化状态
  void initState() {
    super.initState();
    //沉浸式状态栏
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

    //检查网络状态
    Enigma.internetLookUp();
    //将获得的数据缓存
    _cachedModel = widget.model;
    //更新本地缓存用户
    updateLocalUserData(_cachedModel);
    //读取本地缓存的消息
    readLocal();
    seenState = new SeenState(false);
    //组件订阅观察者
    WidgetsBinding.instance.addObserver(this);
    chatId = '';
    unread = widget.unread;
    isLoading = false;
    imageUrl = '';
    //加载本地存储的消息
    loadSavedMessages();
  }

  //更新本地用户数据
  updateLocalUserData(model) {
    peer = model.userData[peerNo];
    currentUser = _cachedModel.currentUser;
    if (currentUser != null && peer != null) {
      chatStatus = peer[CHAT_STATUS];
      peerAvatar = peer[PHOTO_URL];
    }
  }

  //当界面释放时，释放所有的订阅
  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    setLastSeen();
    msgSubscription?.cancel();
    seenSubscription?.cancel();
    deleteUptoSubscription?.cancel();
  }

  //设置最后的在线时间
  void setLastSeen() async {
    if (chatStatus != ChatStatus.blocked.index) {
      if (chatId != null) {
        await Firestore.instance.collection(MESSAGES).document(chatId).setData(
            {'$currentUserNo': DateTime.now().millisecondsSinceEpoch},
            merge: true);
      }
    }
  }



  //设置是否在线
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  //设置在线
  void setIsActive() async {
    //在firebase中更新在线状态
    await Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .setData({'$currentUserNo': true}, merge: true);
  }

  //上次在线时间
  dynamic lastSeen;

  //存储
  FlutterSecureStorage storage = new FlutterSecureStorage();
  //加密
  encrypt.Encrypter cryptor;
  final iv = encrypt.IV.fromLength(8);

  //异步读取本地数据
  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    try {
      //读取本地消息并解密
      privateKey = await storage.read(key: PRIVATE_KEY);
      sharedSecret = (await e2ee.X25519().calculateSharedSecret(
              e2ee.Key.fromBase64(privateKey, false),
              e2ee.Key.fromBase64(peer[PUBLIC_KEY], true)))
          .toBase64();
      final key = encrypt.Key.fromBase64(sharedSecret);
      print("key:" + sharedSecret);
      cryptor = new encrypt.Encrypter(encrypt.Salsa20(key));
    } catch (e) {
      sharedSecret = null;
    }
    try {
      seenState.value = prefs.getInt(getLastSeenKey());
    } catch (e) {
      seenState.value = false;
    }
    chatId = Enigma.getChatId(currentUserNo, peerNo);
    //监听文本消息框
    textEditingController.addListener(() {

      if (textEditingController.text.isNotEmpty && typing == false) {
        lastSeen = peerNo;
        Firestore.instance
            .collection(USERS)
            .document(currentUserNo)
            .setData({LAST_SEEN: peerNo}, merge: true);
        typing = true;
      }
      if (textEditingController.text.isEmpty && typing == true) {
        lastSeen = true;
        Firestore.instance
            .collection(USERS)
            .document(currentUserNo)
            .setData({LAST_SEEN: true}, merge: true);
        typing = false;
      }
    });
    setIsActive();
    //初始化删除订阅
    deleteUptoSubscription = Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .snapshots()
        .listen((doc) {
      if (doc != null && mounted) {
        deleteMessagesUpto(doc.data[DELETE_UPTO]);
      }
    });
    //初始化最近消息订阅
    seenSubscription = Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .snapshots()
        .listen((doc) {
      if (doc != null && mounted) {
        seenState.value = doc[peerNo] ?? false;
        if (seenState.value is int) {
          prefs.setInt(getLastSeenKey(), seenState.value);
        }
      }
    });
    //加载消息并且实时监听消息的变化
    loadMessagesAndListen();
  }

  //获得密钥
  String getLastSeenKey() {
    return "$peerNo-$LAST_SEEN";
  }

  //获得图片
  getImage(File image) {
    if (image != null) {
      setState(() {
        imageFile = image;
      });
    }
    return uploadFile();
  }


  //获得消息壁纸
  getWallpaper(File image) {
    if (image != null) {
      _cachedModel.setWallpaper(peerNo, image);
    }
    return Future.value(false);
  }

  //获取文件名字
  getImageFileName(id, timestamp) {
    return "$id-$timestamp";
  }

  //上传聊天文件
  Future uploadChatFile(File file) async {
    //设置上传时间，上传文件名，然后上传后获得文件的地址
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = path.basename(file.path) + "$uploadTimestamp}";
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageTaskSnapshot uploading = await reference.putFile(file).onComplete;
    return uploading.ref.getDownloadURL();
  }

  //上传文件
  Future uploadFile() async {
    //设置上传时间，上传文件名，然后上传后获得文件的地址
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = getImageFileName(currentUserNo, '$uploadTimestamp');
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageTaskSnapshot uploading =
        await reference.putFile(imageFile).onComplete;
    return uploading.ref.getDownloadURL();
  }

  //异步发送消息方法
  void onSendMessage(String content, MessageType type, int timestamp,
      {String filename}) async {
    //如果内容不为空才继续
    if (content.trim() != '') {

      content = content.trim();
      //如果聊天状态为空就发送好友请求
      if (chatStatus == null) ChatController.request(currentUserNo, peerNo);
      textEditingController.clear();
      //内容不为空则继续
      if (content.isNotEmpty) {
        if (filename == null) {
          filename = "";
        }
        print("send:$content");
        //firebase中添加一个消息
        Future messaging = Firestore.instance
            .collection(MESSAGES)
            .document(chatId)
            .collection(chatId)
            .document('$timestamp')
            .setData({
          FROM: currentUserNo,
          TO: peerNo,
          TIMESTAMP: timestamp,
          CONTENT: content,
          TYPE: type.index,
          CHAT_FILENAME: filename
        });
        //本地数据中添加消息
        _cachedModel.addMessage(peerNo, timestamp, messaging);
        //设置消息
        var tempDoc = {
          TIMESTAMP: timestamp,
          TYPE: type.index,
          CONTENT: content,
          FROM: currentUserNo,
          CHAT_FILENAME: filename
        };
        //更新状态
        setState(() {
          //设置不加载
          isLoading = false;
          //添加消息到列表中
          messages = List.from(messages)
            ..add(Message(
              buildTempMessage(type, content, timestamp, messaging,
                  fileName: filename),
              onTap: type == MessageType.image //如果消息是图片的话，点击可查看大图
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewWrapper(
                          tag: timestamp.toString(),
                          imageProvider: CachedNetworkImageProvider(content),
                        ),
                      ))
                  : null,
              onDismiss: null,
              onDoubleTap: () {//双击的话就保存这个消息
                save(tempDoc);
              },
              onLongPress: () {
                contextMenu(tempDoc);
              },
              from: currentUserNo,
              timestamp: timestamp,
            ));
        });

        unawaited(realtime.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut));
      } else {
        Enigma.toast('Nothing to send');
      }
    }
  }

  //删除消息
  delete(int ts) {
    setState(() {
      messages.removeWhere((msg) => msg.timestamp == ts);
      messages = List.from(messages);
    });
  }

  //显示消息的各种操作
  contextMenu(Map<String, dynamic> doc, {bool saved = false}) {
    List<Widget> tiles = List<Widget>();
    //显示保存按钮并保存消息
    if (saved == false) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.save_alt),
          title: Text(
            'Save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            save(doc);
            Navigator.pop(context);
          }));
    }
    //删除消息
    if (doc[FROM] == currentUserNo && saved == false) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete),
          title: Text(
            'Delete',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            delete(doc[TIMESTAMP]);
            Firestore.instance
                .collection(MESSAGES)
                .document(chatId)
                .collection(chatId)
                .document('${doc[TIMESTAMP]}')
                .delete();
            Navigator.pop(context);
            Enigma.toast('Deleted!');
          }));
    }
    //删除保存的消息
    if (saved == true) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete),
          title: Text(
            'Delete',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Save.deleteMessage(peerNo, doc);
            _savedMessageDocs
                .removeWhere((msg) => msg[TIMESTAMP] == doc[TIMESTAMP]);
            setState(() {
              _savedMessageDocs = List.from(_savedMessageDocs);
            });
            Navigator.pop(context);
            Enigma.toast('Deleted!');
          }));
    }
    //复制消息
    if (doc[TYPE] == MessageType.text.index) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.content_copy),
          title: Text(
            'Copy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: doc[CONTENT]));
            Navigator.pop(context);
            Enigma.toast('Copied!');
          }));
    }
    showDialog(
        context: context,
        builder: (context) {
          return Theme(data: EnigmaTheme, child: SimpleDialog(children: tiles));
        });
  }

  //删除对话
  deleteUpto(int upto) {
    Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .collection(chatId)
        .where(TIMESTAMP, isLessThanOrEqualTo: upto)
        .getDocuments()
        .then((query) {
      query.documents.forEach((msg) {
        if (msg[TYPE] == MessageType.image.index) {
          FirebaseStorage.instance
              .ref()
              .child(getImageFileName(msg[FROM], msg[TIMESTAMP]))
              .delete();
        }
        msg.reference.delete();
      });
    });

    //firebase删除对话并更新数据
    Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .setData({DELETE_UPTO: upto}, merge: true);
    deleteMessagesUpto(upto);
    empty = true;
  }

  //从本地消息列表中删除消息
  deleteMessagesUpto(int upto) {
    if (upto != null) {
      int before = messages.length;
      setState(() {
        messages = List.from(messages.where((msg) => msg.timestamp > upto));
        if (messages.length < before) Enigma.toast('Conversation Ended!');
      });
    }
  }

  //保存消息
  save(Map<String, dynamic> doc) async {
    Enigma.toast('Saved');
    if (!_savedMessageDocs.any((_doc) => _doc[TIMESTAMP] == doc[TIMESTAMP])) {
      String content;
      if (doc[TYPE] == MessageType.image.index) {
        content = doc[CONTENT].toString().startsWith('http')
            ? await Save.getBase64FromImage(imageUrl: doc[CONTENT] as String)
            : doc[CONTENT]; // if not a url, it is a base64 from saved messages
      } else {
        // If text
        content = doc[CONTENT];
      }
      doc[CONTENT] = content;
      Save.saveMessage(peerNo, doc);
      _savedMessageDocs.add(doc);
      setState(() {
        _savedMessageDocs = List.from(_savedMessageDocs);
      });
    }
  }

  //获取文本消息
  Widget getTextMessage(bool isMe, Map<String, dynamic> doc, bool saved) {
    return Text(
      doc[CONTENT],
      style:
          TextStyle(color: isMe ? enigmaWhite : Colors.black, fontSize: 16.0),
    );
  }

  //获取对方的文本消息
  Widget getTempTextMessage(String message) {
    return Text(
      message,
      style: TextStyle(color: enigmaWhite, fontSize: 16.0),
    );
  }

  //获取图片消息
  Widget getImageMessage(Map<String, dynamic> doc, {bool saved = false}) {
    return Container(
      child: saved
          ? doc[TYPE] == MessageType.image
              ? Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: Save.getImageFromBase64(doc[CONTENT]).image,
                        fit: BoxFit.cover),
                  ),
                  width: 200.0,
                  height: 200.0,
                )
              : Container(
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        "assets/file.png",
                        width: 100,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            //宽度尽可能大
                            maxWidth: 160),
                        child: Text(
                          "${doc[CHAT_FILENAME]}",
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      )
                    ],
                  ),
                )
          : doc[TYPE] == MessageType.image.index
              ? CachedNetworkImage(
                  placeholder: (context, url) => Container(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(enigmaBlue),
                    ),
                    width: 200.0,
                    height: 200.0,
                    padding: EdgeInsets.all(80.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
                  errorWidget: (context, str, error) => Material(
                    child: Image.asset(
                      'assets/img_not_available.jpeg',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                  imageUrl: doc[CONTENT],
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                )
              : Container(
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        "assets/file.png",
                        width: 100,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            //宽度尽可能大
                            maxWidth: 160),
                        child: Text(
                          "${doc[CHAT_FILENAME]}",
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  //获取对面的图片消息
  Widget getTempImageMessage({String url, String fileName}) {
    return imageFile != null
        ? Container(
            child: Image.file(
              imageFile,
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
          )
        : getImageMessage({CONTENT: url, CHAT_FILENAME: fileName});
  }

  //构建消息
  Widget buildMessage(Map<String, dynamic> doc,
      {bool saved = false, List<Message> savedMsgs}) {
    final bool isMe = doc[FROM] == currentUserNo;
    bool isContinuing;
    if (savedMsgs == null)
      isContinuing =
          messages.isNotEmpty ? messages.last.from == doc[FROM] : false;
    else {
      isContinuing =
          savedMsgs.isNotEmpty ? savedMsgs.last.from == doc[FROM] : false;
    }
    return SeenProvider(
        timestamp: doc[TIMESTAMP].toString(),
        data: seenState,
        child: Bubble(
            child: doc[TYPE] == MessageType.text.index
                ? getTextMessage(isMe, doc, saved)
                : getImageMessage(
                    doc,
                    saved: saved,
                  ),
            isMe: isMe,
            timestamp: doc[TIMESTAMP],
            delivered: _cachedModel.getMessageStatus(peerNo, doc[TIMESTAMP]),
            isContinuing: isContinuing));
  }

  //构建对方的消息
  Widget buildTempMessage(MessageType type, content, timestamp, delivered,
      {String fileName}) {
    final bool isMe = true;
    return SeenProvider(
        timestamp: timestamp.toString(),
        data: seenState,
        child: Bubble(
          child: type == MessageType.text
              ? getTempTextMessage(content)
              : getTempImageMessage(url: content, fileName: fileName),
          isMe: isMe,
          timestamp: timestamp,
          delivered: delivered,
          isContinuing:
              messages.isNotEmpty && messages.last.from == currentUserNo,
        ));
  }

  //构建进度条
  Widget buildLoading() {
    return isLoading
        ? SpinKitCubeGrid(
            color: Colors.white,
            size: 50.0,
          )
        : Container();
  }

  //构建输入框
  Widget buildInput() {
    if (chatStatus == ChatStatus.requested.index) {
      //这是接受请求的
      return AlertDialog(
        backgroundColor: Colors.black12,
        elevation: 10.0,
        title: Text(
          '接受 ${peer[NICKNAME]}\'的好友请求吗？?',
          style: TextStyle(color: enigmaWhite),
        ),
        actions: <Widget>[ //接受和拒绝聊天请求
          FlatButton(
              child: Text('拒绝'),
              onPressed: () {
                ChatController.block(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.blocked.index;
                });
              }),
          FlatButton(
              child: Text('接受'),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    //构建界面
    return Container(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container( //容器
//                height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey[500],
                offset: Offset(0.0, 1.5),
                blurRadius: 4.0,
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: 190,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: ListTile(
                  //这个是左下角的加号按钮
                  leading: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).accentColor,
                    ),
                    onPressed: chatStatus == ChatStatus.blocked.index
                        ? null
                        : () async {
                      //点击事件，点击后弹出对话框选择是分享图片还是文件
                            int i = await showDialog<int>(
                                context: context,
                                builder: (BuildContext context) {
                                  //弹出对话框
                                  return SimpleDialog(
                                    title: const Text('请选择分享的类型'),
                                    children: <Widget>[
                                      SimpleDialogOption(//图片选项
                                        onPressed: () {
                                          // 返回1
                                          Navigator.pop(context, 1);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          child: const Text('图片'),
                                        ),
                                      ),
                                      SimpleDialogOption(//文件选项
                                        onPressed: () {
                                          // 返回2
                                          Navigator.pop(context, 2);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          child: const Text('文件'),
                                        ),
                                      ),
                                    ],
                                  );
                                });

                            //获得用户的选项后，根据用户的选择做对应的操作
                            if (i != null) {
                              if (i == 1) {//打开相册
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => HybridImagePicker(
                                              title: 'Pick an image',
                                              callback: getImage,
                                            ))).then((url) {
                                  if (url != null) {
                                    onSendMessage(url, MessageType.image,
                                        uploadTimestamp);
                                  }
                                });
                              } else {//设置进度条，获得文件并上传
                                setState(() {
                                  isLoading = true;
                                });
                                File selectfile = await FilePicker.getFile();
                                String url = await uploadChatFile(selectfile);
                                if (url != null) {
                                  onSendMessage(
                                      url, MessageType.file, uploadTimestamp,
                                      filename: path.basename(selectfile.path));
                                }
                              }
                            }
                          },
                  ),
                  contentPadding: EdgeInsets.all(0),
                  title: TextField( //中间的输入框
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Theme.of(context).textTheme.title.color,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      hintText: "Write your message...",
                      hintStyle: TextStyle(
                        fontSize: 15.0,
                        color: Theme.of(context).textTheme.title.color,
                      ),
                    ),
                    maxLines: null,
                    controller: textEditingController,
                  ),
                  trailing: IconButton( //发送按钮
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).accentColor,
                    ),
                    onPressed: chatStatus == ChatStatus.blocked.index //点击发送按钮以后发送消息
                        ? null
                        : () => onSendMessage(
                            textEditingController.text,
                            MessageType.text,
                            DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      width: double.infinity,
      height: 60.0,
      decoration: new BoxDecoration(
        border:
            new Border(top: new BorderSide(color: Colors.white, width: 0.5)),
        color: Colors.white,
      ),
    );
  }


  bool empty = true;

  //加载消息并且异步实时监听消息的更新
  loadMessagesAndListen() async {
    //等待firebase同步消息
    await Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .collection(chatId)
        .orderBy(TIMESTAMP)
        .getDocuments()
        .then((docs) {
          //如果文档不为空的话就迭代读取文档中的消息并保存
      if (docs.documents.isNotEmpty) empty = false;
      docs.documents.forEach((doc) {
        Map<String, dynamic> _doc = Map.from(doc.data);
        int ts = _doc[TIMESTAMP];
        // _doc[CONTENT] = decryptWithCRC(_doc[CONTENT]);
        //添加消息到列表中
        messages.add(Message(buildMessage(_doc),
            onDismiss: _doc[FROM] == peerNo ? () => deleteUpto(ts) : null,
            //点击事件，如果是图片就显示大图，如果是文件就下载文件
            onTap: _doc[TYPE] == MessageType.image.index
                ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewWrapper(
                            tag: ts.toString(),
                            imageProvider:
                                CachedNetworkImageProvider(_doc[CONTENT]),
                          ),
                        ));
                  }
                : _doc[TYPE] == MessageType.file
                    ? () async {
                        var dio = Dio();
                        Enigma.toast("开始下载");

                        var save = Directory("/storage/emulated/0/ZH/");
                        if (!save.existsSync()) {
                          await save.create(recursive: true);
                        }
                        try {
                          var response = await dio.download(_doc[CONTENT],
                              "${save.path}${_doc[CHAT_FILENAME]}");
                          if (response.statusCode == 200) {
                            Enigma.toast("已下载到${save.path}");
                          }
                        } catch (e) {
                          print("${e}");
                          Enigma.toast("下载失败:错误${e}");
                        }
                      }
                    : null, onDoubleTap: () {
          save(_doc);
        }, onLongPress: () {
          contextMenu(_doc);
        }, from: _doc[FROM], timestamp: ts));
      });
      if (mounted) {
        setState(() {
          messages = List.from(messages);
        });
      }
      //消息监听事件监听当前会话
      msgSubscription = Firestore.instance
          .collection(MESSAGES)
          .document(chatId)
          .collection(chatId)
          .where(FROM, isEqualTo: peerNo)
          .snapshots()
          .listen((query) {
            //如果有更新并且内容不为空的话就把消息缓存，并把消息的内容读取出来添加到消息列表中
        if (empty == true ||
            query.documents.length != query.documentChanges.length) {
          query.documentChanges.where((doc) {
            return doc.oldIndex <= doc.newIndex;
          }).forEach((change) {
            Map<String, dynamic> _doc = Map.from(change.document.data);
            int ts = _doc[TIMESTAMP];
            //_doc[CONTENT] = decryptWithCRC(_doc[CONTENT]);
            messages.add(Message(buildMessage(_doc),
                onLongPress: () {
                  contextMenu(_doc);
                },
                onTap: _doc[TYPE] == MessageType.image.index
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewWrapper(
                            tag: ts.toString(),
                            imageProvider:
                                CachedNetworkImageProvider(_doc[CONTENT]),
                          ),
                        ))
                    : null,
                onDoubleTap: () {
                  save(_doc);
                },
                from: _doc[FROM],
                timestamp: ts,
                onDismiss: () => deleteUpto(ts)));
          });
          if (mounted) {
            setState(() {
              messages = List.from(messages);
            });
          }
        }
      });
    });
  }

  //加载本地保存的消息
  void loadSavedMessages() {
    if (_savedMessageDocs.isEmpty) {
      Save.getSavedMessages(peerNo).then((_msgDocs) {
        if (_msgDocs != null) {
          setState(() {
            _savedMessageDocs = _msgDocs;
          });
        }
      });
    }
  }

  //排序分组的消息
  List<Widget> sortAndGroupSavedMessages(List<Map<String, dynamic>> _msgs) {
    _msgs.sort((a, b) => a[TIMESTAMP] - b[TIMESTAMP]);
    List<Message> _savedMessages = new List<Message>();
    List<Widget> _groupedSavedMessages = new List<Widget>();
    _msgs.forEach((msg) {
      _savedMessages.add(Message(
          buildMessage(msg, saved: true, savedMsgs: _savedMessages),
          saved: true,
          from: msg[FROM],
          onDoubleTap: () {}, onLongPress: () {
        contextMenu(msg, saved: true);
      },
          onDismiss: null,
          onTap: msg[TYPE] == MessageType.image.index
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewWrapper(
                      tag: "saved_" + msg[TIMESTAMP].toString(),
                      imageProvider: msg[CONTENT].toString().startsWith(
                              'http') // See if it is an online or saved
                          ? CachedNetworkImageProvider(msg[CONTENT])
                          : Save.getImageFromBase64(msg[CONTENT]).image,
                    ),
                  ))
              : null,
          timestamp: msg[TIMESTAMP]));
    });

    _groupedSavedMessages
        .add(Center(child: Chip(label: Text('Saved Conversations'))));

    groupBy<Message, String>(_savedMessages, (msg) {
      return getWhen(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));
    }).forEach((when, _actualMessages) {
      _groupedSavedMessages.add(Center(
          child: Chip(
        label: Text(when),
      )));
      _actualMessages.forEach((msg) {
        _groupedSavedMessages.add(msg.child);
      });
    });
    return _groupedSavedMessages;
  }

  //获得分组的消息
  List<Widget> getGroupedMessages() {
    List<Widget> _groupedMessages = new List<Widget>();
    int count = 0;
    groupBy<Message, String>(messages, (msg) {
      return getWhen(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));
    }).forEach((when, _actualMessages) {
      _groupedMessages.add(Center(
          child: Chip(
        label: Text(when),
      )));
      _actualMessages.forEach((msg) {
        count++;
        if (unread != 0 && (messages.length - count) == unread - 1) {
          _groupedMessages.add(Center(
              child: Chip(
            label: Text('${unread} unread messages'),
          )));
          unread = 0; // reset
        }
        _groupedMessages.add(msg.child);
      });
    });
    return _groupedMessages.reversed.toList();
  }

  //构建保存消息的界面
  Widget buildSavedMessages() {
    return Flexible(
        child: ListView(
      padding: EdgeInsets.all(10.0),
      children: _savedMessageDocs.isEmpty
          ? [
              Padding(
                  padding: EdgeInsets.only(top: 200.0),
                  child: Text('No saved messages.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: enigmaWhite, fontSize: 18)))
            ]
          : sortAndGroupSavedMessages(_savedMessageDocs),
      controller: saved,
    ));
  }

  //构建消息界面
  Widget buildMessages() {
    if (chatStatus == ChatStatus.blocked.index) {
      return AlertDialog(
        backgroundColor: Colors.black12,
        elevation: 10.0,
        title: Text(
          '接受 ${peer[NICKNAME]}的消息吗?',
          style: TextStyle(color: enigmaWhite),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text('不接受'),
              onPressed: () {
                Navigator.pop(context);
              }),
          FlatButton(
              child: Text('接受'),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    return Flexible(
        child: chatId == '' || messages.isEmpty || sharedSecret == null
            ? ListView(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(top: 200.0),
                      child: Text(
                          sharedSecret == null
                              ? 'Setting things up.'
                              : 'Say Hi!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: enigmaWhite, fontSize: 18))),
                ],
                controller: realtime,
              )
            : ListView(
                padding: EdgeInsets.all(10.0),
                children: getGroupedMessages(),
                controller: realtime,
                reverse: true,
              ));
  }

  //获得时间
  getWhen(date) {
    DateTime now = DateTime.now();
    String when;
    if (date.day == now.day)
      when = '今天';
    else if (date.day == now.subtract(Duration(days: 1)).day)
      when = '昨天';
    else
      when = DateFormat.MMMd().format(date);
    return when;
  }

  //获得对方的状态
  getPeerStatus(val) {
    if (val is bool && val == true) {
      return '在线';
    } else if (val is int) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(val);
      String at = DateFormat.jm().format(date), when = getWhen(date);
      return '上次在线： $when $at';
    } else if (val is String) {
      if (val == currentUserNo) return 'typing…';
      return '在线';
    }
    return 'loading…';
  }

  bool isBlocked() {
    return chatStatus == ChatStatus.blocked.index ?? true;
  }

  //构建真正的用户界面
  @override
  Widget build(BuildContext context) {
    //沉浸式状态栏
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Constants.lightPrimary,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Enigma.getNTPWrappedWidget(WillPopScope(
        onWillPop: () async {
          setLastSeen();
          if (lastSeen == peerNo)
            await Firestore.instance
                .collection(USERS)
                .document(currentUserNo)
                .setData({LAST_SEEN: true}, merge: true);
          return Future.value(true);
        },
        child: ScopedModel<DataModel>(
            model: _cachedModel,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, _model) {
              _cachedModel = _model;
              updateLocalUserData(_model);
              return peer != null
                  ? Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top),
                      child: Scaffold(
                          key: _scaffold,
                          backgroundColor: Colors.white,
                          appBar: PreferredSize(
                            preferredSize: Size.fromHeight(40.0),
                            child: Material(
                              child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Profile(
                                                  unread: 0,
                                                  currentUserNo:
                                                      widget.currentUserNo,
                                                  model: widget.model,
                                                  peeruser: widget.model
                                                      .userData[widget.peerNo],
                                                )));
                                  },
                                  dense: true,
                                  leading: Enigma.avatar(peer),
                                  title: Text(
                                    Enigma.getNickname(peer),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Theme(
                                      data: Constants.lightTheme,
                                      child: PopupMenuButton(
                                        onSelected: (val) {
                                          switch (val) {
                                            case 'remove_wallpaper':
                                              _cachedModel
                                                  .removeWallpaper(peerNo);
                                              Enigma.toast(
                                                  'Wallpaper removed.');
                                              break;
                                            case 'set_wallpaper':
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          HybridImagePicker(
                                                            title: '选择一个图片',
                                                            callback:
                                                                getWallpaper,
                                                          )));
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) =>
                                            <PopupMenuItem<String>>[
                                          PopupMenuItem<String>(
                                              value: 'set_wallpaper',
                                              child: Text('设置壁纸')),
                                          peer[WALLPAPER] != null
                                              ? PopupMenuItem<String>(
                                                  value: 'remove_wallpaper',
                                                  child: Text('删除壁纸'))
                                              : null,
                                        ].where((o) => o != null).toList(),
                                      )),
                                  subtitle: chatId.isNotEmpty
                                      ? Text(
                                          getPeerStatus(peer[LAST_SEEN]),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400),
                                        )
                                      : Text('loading…',
                                          style:
                                              TextStyle(color: Colors.black))),
                              elevation: 4,
                              color: Colors.white,
                            ),
                          ),
                          body: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              new Container(
                                decoration: new BoxDecoration(
                                  image: new DecorationImage(
                                      image: peer[WALLPAPER] == null
                                          ? AssetImage("assets/bg.jpg")
                                          : Image.file(File(peer[WALLPAPER]))
                                              .image,
                                      fit: BoxFit.cover),
                                ),
                              ),
                              PageView(
                                children: <Widget>[
                                  Column(
                                    children: [
                                      // List of messages
                                      buildMessages(),
                                      // Input content
                                      isBlocked() ? Container() : buildInput(),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      // List of saved messages
                                      buildSavedMessages()
                                    ],
                                  ),
                                ],
                              ),

                              // Loading
                              buildLoading()
                            ],
                          )))
                  : Container();
            }))));
  }
}
