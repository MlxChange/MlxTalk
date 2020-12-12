import 'dart:async';
import 'dart:core';

import 'package:Enigma/screens/main_screen.dart';
import 'package:Enigma/screens/profile.dart';
import 'package:Enigma/util/const.dart';
import 'package:Enigma/widgets/chat_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Enigma/chat.dart';
import 'package:Enigma/const.dart';

import 'package:flutter/services.dart';
import 'package:Enigma/login.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Enigma/utils.dart';
import 'package:Enigma/DataModel.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  //全局定义错误事件处理
  FlutterError.onError = (FlutterErrorDetails details) {
    if (Enigma.isInDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode, report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  //
  runZoned<Future<void>>(() async {
    //运行app
    runApp(EnigmaWrapper());
    await SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Constants.lightPrimary,
      statusBarIconBrightness: Brightness.dark,
    ));
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `_reportError` function. This sends
    // Dart errors to the dev console or Sentry depending on the environment.
    await Enigma.reportError(error, stackTrace);
  });
}

class EnigmaWrapper extends StatelessWidget {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: SharedPreferences.getInstance(), //获取本地数据，如果没有就登陆
        builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (snapshot.hasData) {
            //显示主界面
            return MaterialApp(
              home: MainScreen2(
                  mainUI: MainScreen(
                      currentUserNo: snapshot.data.getString(PHONE))),
              theme: Constants.lightTheme,
            );
          }
          return MaterialApp(
            home: Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(enigmaBlue)),
              ),
              color: enigmaBlack.withOpacity(0.8),
            ),
          );
        });
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({@required this.currentUserNo, key}) : super(key: key);
  final String currentUserNo;

  @override
  State createState() => new MainScreenState(currentUserNo: this.currentUserNo);
}

class MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  MainScreenState({Key key, this.currentUserNo}) {
    //查找框注册监听器，监听查找框文本变化
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }

  @override
  bool get wantKeepAlive => true;

  //获得消息通知
  FirebaseMessaging notifications = new FirebaseMessaging();

  //本地存储
  SharedPreferences prefs;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //如果app处于前台就更新当前为在线状态，否则就为离线状态
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  //设置在线
  void setIsActive() async {
    if (currentUserNo != null)
      await Firestore.instance
          .collection(USERS)
          .document(currentUserNo)
          .setData({LAST_SEEN: true}, merge: true);
  }

  //设置最后登录时间
  void setLastSeen() async {
    if (currentUserNo != null)
      await Firestore.instance
          .collection(USERS)
          .document(currentUserNo)
          .setData({LAST_SEEN: DateTime.now().millisecondsSinceEpoch},
              merge: true);
  }

  //查找框的控制器
  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  //对方手机号的内容控制器
  TextEditingController _peerPhone = new TextEditingController();

  //
  //未读消息的订阅
  List<StreamSubscription> unreadSubscriptions = List<StreamSubscription>();
  //stream的控制器
  List<StreamController> controllers = new List<StreamController>();

  @override
  void initState() {
    //初始化登录，如果有数据就显示主界面，没有本地数据就跳转到登陆界面
    LocalAuthentication().canCheckBiometrics.then((res) {
      if (res) biometricEnabled = true;
    });
    getSignedInUserOrRedirect();
    Enigma.internetLookUp();
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    //释放所有资源，并且清空所有的内容
    WidgetsBinding.instance.removeObserver(this);
    controllers.forEach((controller) {
      controller.close();
    });
    _filter.dispose();

    _userQuery.close();
    cancelUnreadSubscriptions();
    //设置最后在线时间
    setLastSeen();
  }

  //取消未读订阅
  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription?.cancel();
    });
  }

  DataModel _cachedModel;//当前用户数据
  bool biometricEnabled = false;

  //获取当前登录状态 并判断是否跳转到登陆界面
  getSignedInUserOrRedirect() async {
    prefs = await SharedPreferences.getInstance();
    //跳转登录界面
    if (currentUserNo == null || currentUserNo.isEmpty)
      unawaited(Navigator.pushReplacement(
        context,
        new MaterialPageRoute(
            builder: (context) => new LoginScreen(title: 'Sign in to ZH')),
      ));
    else {
      //设置在线状态 并更新数据，通知所有好友在线
      setIsActive();
      String fcmToken = await notifications.getToken();
      if (prefs.getBool(IS_TOKEN_GENERATED) != true) {
        await Firestore.instance
            .collection(USERS)
            .document(currentUserNo)
            .setData({
          NOTIFICATION_TOKENS: FieldValue.arrayUnion([fcmToken])
        }, merge: true);
        unawaited(prefs.setBool(IS_TOKEN_GENERATED, true));
      }
    }
  }

  String currentUserNo; //当前用户的手机号

  bool isLoading = false;//是否处于加载状态

  //构建用户界面中的好友条目
  Widget buildItem(BuildContext context, Map<String, dynamic> user) {
    NavigatorState state = Navigator.of(context);
    //如果对方用户手机号是当前用户就不显示
    if (user[PHONE] as String == currentUserNo) {
      return Container(width: 0, height: 0);
    } else {
      return StreamBuilder(
          stream: getUnread(user).asBroadcastStream(),//获取未读消息
          builder: (context, AsyncSnapshot<MessageData> unreadData) {
            int unread = unreadData.hasData &&
                    unreadData.data.snapshot.documents.isNotEmpty
                ? unreadData.data.snapshot.documents
                    .where((t) => t[TIMESTAMP] > unreadData.data.lastSeen)
                    .length
                : 0;
            //定义未读消息的内容
            var unreadString = "";
            var unreadTime = "";//未读消息的时间
            if (unread != 0) {//如果未读消息不为0就继续
              var doc = unreadData.data.snapshot.documents
                  .where((t) => t[TIMESTAMP] > unreadData.data.lastSeen)
                  .toList()
                  .last;//得到未读消息的文档
              unreadTime = DateFormat('hh:mm')
                  .format(DateTime.fromMillisecondsSinceEpoch(doc[TIMESTAMP]));//获取未读消息的时间
              //判断未读消息的内容，如果是图片就只是显示图片，如果是文件就只是显示文件
              if (doc[TYPE] == MessageType.image.index) {
                unreadString = "[图片]";
              } else if (doc[TYPE] == MessageType.file.index) {
                unreadString = "[文件]";
              } else {
                //如果是文字就显示未读消息的文字
                unreadString = unreadData.data.snapshot.documents
                    .where((t) => t[TIMESTAMP] > unreadData.data.lastSeen)
                    .toList()
                    .last[CONTENT];
                print("reciver:$unreadString");
              }
            }
            //定义一个主题
            return Theme(
                data: ThemeData(
                    splashColor: enigmaWhite,
                    highlightColor: Colors.transparent),
                child: ChatItem( //列表的条目，也就是每一个好友的item的样式
                    //以下分别是头像，姓名，未读消息，未读消息时间，是否在线和未读消息数量
                    dp: Enigma.avatar(user),
                    name: Enigma.getNickname(user),
                    msg: unreadString,
                    time: unreadTime,
                    isOnline: user[LAST_SEEN] == true,
                    counter: unread == 0 ? 0 : int.parse(unread.toString()),
                    tap: () {
                      //点击事件，点击后进入聊天界面
                      if (_cachedModel.currentUser[LOCKED] != null &&
                          _cachedModel.currentUser[LOCKED]
                              .contains(user[PHONE])) {
                        NavigatorState state = Navigator.of(context);
                      } else {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new ChatScreen(
                                    unread: unread,
                                    model: _cachedModel,
                                    currentUserNo: currentUserNo,
                                    peerNo: user[PHONE] as String)));
                      }
                    }));
          });
    }
  }

  //获得未读消息
  Stream<MessageData> getUnread(Map<String, dynamic> user) {
    //得到会话id
    String chatId = Enigma.getChatId(currentUserNo, user[PHONE]);
    var controller = StreamController<MessageData>.broadcast();
    //未读订阅监听firebase实时数据库去同步数据
    unreadSubscriptions.add(Firestore.instance
        .collection(MESSAGES)
        .document(chatId)
        .snapshots()
        .listen((doc) {
      if (doc[currentUserNo] != null && doc[currentUserNo] is int) {
        //当有新消息的时候且不为0的时候 添加一个新的消息
        unreadSubscriptions.add(Firestore.instance
            .collection(MESSAGES)
            .document(chatId)
            .collection(chatId)
            .snapshots()
            .listen((snapshot) {
          controller.add(
              MessageData(snapshot: snapshot, lastSeen: doc[currentUserNo]));
        }));
      }
    }));
    controllers.add(controller);
    return controller.stream;
  }

  _isHidden(phoneNo) {
    Map<String, dynamic> _currentUser = _cachedModel.currentUser;
    return _currentUser[HIDDEN] != null &&
        _currentUser[HIDDEN].contains(phoneNo);
  }

  //定义一个用户查询
  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();
  //定义用户的好友列表
  List<Map<String, dynamic>> _users = List<Map<String, dynamic>>();

  _chats(Map<String, Map<String, dynamic>> _userData,
      Map<String, dynamic> currentUser) {
    //获取所有的用户好友
    _users = Map.from(_userData)
        .values
        .where((_user) => _user.keys.contains(CHAT_STATUS))
        .toList()
        .cast<Map<String, dynamic>>();
    Map<String, int> _lastSpokenAt = _cachedModel.lastSpokenAt;
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>();

    //排序
    _users.sort((a, b) {
      int aTimestamp = _lastSpokenAt[a[PHONE]] ?? 0;
      int bTimestamp = _lastSpokenAt[b[PHONE]] ?? 0;
      return bTimestamp - aTimestamp;
    });



    //返回页面布局
    return Stack(
      children: <Widget>[
        RefreshIndicator(
            onRefresh: () {
              return Future.value(false);
            },
            child: Container(
                child: _users.isNotEmpty //如果用户好友不为空的话就显示好友列表
                    ? StreamBuilder(
                        stream: _userQuery.stream.asBroadcastStream(),//查询好友
                        builder: (context, snapshot) {
                          //如果用户的查询好友关键字不为空的话就从好友列表中筛选出符合的好友
                          if (_filter.text.isNotEmpty ||
                              snapshot.hasData && snapshot.data.isNotEmpty) {
                            filtered = this._users.where((user) {
                              return user[NICKNAME]
                                  .toLowerCase()
                                  .trim()
                                  .contains(new RegExp(r'' +
                                      _filter.text.toLowerCase().trim() +
                                      ''));
                            }).toList();
                            //如果是空的话就不显示
                            if (filtered.isNotEmpty)
                              return ListView.separated(
                                padding: EdgeInsets.all(10),
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      height: 0.5,
                                      width: MediaQuery.of(context).size.width /
                                          1.3,
                                      child: Divider(),
                                    ),
                                  );
                                },
                                itemBuilder: (context, index) => buildItem(
                                    context, filtered.elementAt(index)),
                                itemCount: filtered.length,
                              );
                            else//如果没有好友显示此界面 或者显示没有查找到结果
                              return ListView(children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                3.5),
                                    child: Center(
                                      child: Text('No search results.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: enigmaWhite,
                                          )),
                                    ))
                              ]);
                          }//显示用户界面
                          return ListView.builder(
                            padding: EdgeInsets.all(10.0),
                            itemBuilder: (context, index) =>
                                buildItem(context, _users.elementAt(index)),
                            itemCount: _users.length,
                          );
                        })
                    : ListView(children: [ //好友数量为0 就显示此界面
                        Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 3.5),
                            child: Center(
                              child: Padding(
                                  padding: EdgeInsets.all(30.0),
                                  child: Text('快去添加一个好友聊天吧~',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: enigmaWhite,
                                      ))),
                            ))
                      ]))),
      ],
    );
  }

  //缓存用户数据
  DataModel getModel() {
    _cachedModel ??= DataModel(currentUserNo);
    return _cachedModel;
  }

  //背景颜色渐变
  LinearGradient SIGNUP_CARD_BACKGROUND = LinearGradient(
    tileMode: TileMode.clamp,
    begin: FractionalOffset.centerLeft,
    end: FractionalOffset.centerRight,
    stops: [0.1, 1.0],
    colors: [Color(0xffffc2a1), Color(0xffffb1bb)],
  );

  //输入框
  Widget inputText(
    String fieldName,
    String hintText,
    TextEditingController controller,
    bool obSecure,
  ) {
    return TextField(
      style: TextStyle(height: 1.3),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: fieldName,
        labelStyle: TextStyle(
          fontSize: 14.0,
          fontFamily: "Mlx",
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
          height: 0,
        ),
        border: InputBorder.none,
      ),
      obscureText: obSecure,
    );
  }

  @override //构建用户界面
  Widget build(BuildContext context) {
    super.build(context);
    final _media = MediaQuery.of(context).size;
    return Enigma.getNTPWrappedWidget(WillPopScope(
        onWillPop: () {
          if (!isAuthenticating) setLastSeen();
          return Future.value(true);
        },
        child: ScopedModel<DataModel>(
          model: getModel(),
          child: ScopedModelDescendant<DataModel>(
              builder: (context, child, _model) {
            _cachedModel = _model;
            return Scaffold(
                floatingActionButton: _model.loaded //添加好友按钮
                    ? FloatingActionButton(
                        child: Icon(
                          Icons.person_add,
                          size: 30.0,
                        ),
                        onPressed: () { //点击事件
                          //点击后显示一个对话框， 提示让用户输入手机号，然后有结果的话就进入用户的详情页
                          //没有的话就提示用户此用户不存在
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('查找'),
                                  content: inputText(
                                      "请输入对方手机号", '', _peerPhone, false),
                                  actions: <Widget>[
                                    new FlatButton(
                                      onPressed: () {
                                        //正则表达式，验证是否是手机号
                                        RegExp e164 =
                                            new RegExp(r'^\+[1-9]\d{1,14}$');
                                        print(_peerPhone.text);
                                        if (_peerPhone.text.isNotEmpty &&
                                            e164.hasMatch(
                                                "+86${_peerPhone.text.trim()}")) {
                                          dynamic wUser = _cachedModel.userData[
                                              "+86${_peerPhone.text.trim()}"];
                                          if (wUser != null &&
                                              wUser[CHAT_STATUS] != null) {
                                            //如果是手机号的话并且是好友就直接进入聊天界面
                                            Navigator.pushReplacement(
                                                context,
                                                new MaterialPageRoute(
                                                    builder: (context) => new ChatScreen(
                                                        model: _cachedModel,
                                                        currentUserNo: _cachedModel
                                                            .currentUser[PHONE],
                                                        peerNo:
                                                            "+86${_peerPhone.text.trim()}",
                                                        unread: 0)));
                                          } else {
                                            //如果不是好友就进入对方的资料界面
                                            getUser(
                                                phone:
                                                    "+86${_peerPhone.text.trim()}");
                                          }
                                        } else {

                                          Enigma.toast("请输入正确的手机号");
                                        }
                                      },
                                      child: new Text("确认"),
                                    ),
                                    new FlatButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: new Text("取消"),
                                    ),
                                  ],
                                );
                              });
//                          Navigator.push(
//                              context,
//                              new MaterialPageRoute(
//                                  builder: (context) => new Contacts(
//                                      prefs: prefs,
//                                      biometricEnabled: biometricEnabled,
//                                      currentUserNo: currentUserNo,
//                                      model: _cachedModel)));
                        })
                    : Container(),
                appBar: AppBar( //查找好友的输入框
                  bottom: PreferredSize(
                      preferredSize: Size.fromHeight(40.0),
                      child: TextField(
                        autofocus: false,
                        style: TextStyle(color: Colors.black),
                        controller: _filter, //控制器，用来获得用户输入的信息
                        decoration: new InputDecoration(
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            hintText: 'Search ',
                            hintStyle: TextStyle(color: Colors.black26)),
                      )),
                  backgroundColor: Colors.white,
                  title: Text(
                    'ZH',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                ),
                body: _chats(_model.userData, _model.currentUser));
          }),
        )));
  }

  //查找用户
  getUser({phone: String}) {
    //firebase数据库查找用户
    Firestore.instance.collection(USERS).document(phone).get().then((user) {
      setState(() {
        bool isUser = user.exists;
        if (isUser) { //如果用户存在就得到对方信息并进入资料页面
          var peeruser;
          if (_cachedModel.userData[phone] == null) {
            peeruser = user.data;
          } else {
            peeruser = _cachedModel.userData[phone];
          }
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Profile(
                        unread: 0,
                        currentUserNo: widget.currentUserNo,
                        model: _cachedModel,
                        peeruser: peeruser,
                      )));
        } else {
          Enigma.toast("没有找到此用户");
        }
      });
    });
  }
}

//颜色渐变
LinearGradient SIGNUP_SIX_FACEBOOK_BG = LinearGradient(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topRight,
  // Add one stop for each color. Stops should increase from 0 to 1
  stops: [0.1, 0.3],
  colors: [
    Color(0xffe0c3fc),
    Color(0xff8ec5fc),
  ],
);

class MessageData {
  int lastSeen;
  QuerySnapshot snapshot;

  MessageData({@required this.snapshot, @required this.lastSeen});
}
