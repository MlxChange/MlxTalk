import 'dart:math';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../DataModel.dart';
import '../alias.dart';
import '../chat.dart';
import '../const.dart';

//好友信息界面
class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();

  //当前用户的手机号
  final String currentUserNo;
  //对方用户的信息
  final DataModel model;
  //未读消息的数量
  final int unread;
  //对方用户
  final Map<String, dynamic> peeruser;

  //接受四个参数
  Profile(
      {Key key,
      @required this.currentUserNo,
      @required this.peeruser,
      @required this.model,
      @required this.unread});
}

class _ProfileState extends State<Profile> {
  static Random random = Random();

  //四个文本控制器，分别是姓名，性别，生日和邮箱
  TextEditingController _name = TextEditingController();
  TextEditingController _sex = TextEditingController();
  TextEditingController _birthday = TextEditingController();
  TextEditingController _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    //沉浸式状态栏
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    //如果目标用户不为空就获取他的信息并填充到文本中
    if(widget.peeruser!=null){

      _sex.text = widget.peeruser[Sex];
      _birthday.text = widget.peeruser[BIRTHDAY];
      if (widget.peeruser[EMAIL] == null) {
        _email.text = "此用户还没有留下他的邮箱哦";
      } else {
        if (widget.peeruser[EMAIL].toString().isEmpty) {
          _email.text = "此用户还没有留下他的邮箱哦";
        } else {
          _email.text = widget.peeruser[EMAIL];
        }
      }
      if (widget.peeruser[ALIAS_NAME] == null) {
        _name.text = "";
      } else {
        if (widget.peeruser[ALIAS_NAME].toString().isEmpty) {
          _name.text = "";
        } else {
          _name.text = widget.peeruser[ALIAS_NAME];
        }
      }
    }
  }

  //定义一个文本输入框
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

  //构建界面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: Stack(//绝对布局
          alignment: Alignment.center,
          children: <Widget>[
            //背景图片，如果用户头像不是空的话就加载用户的头像否则加载默认图片
            Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: (widget.peeruser == null)
                      ? AssetImage("assets/proBg.jpg")
                      : widget.peeruser[PHOTO_URL].toString().isEmpty
                          ? AssetImage("assets/proBg.jpg")
                          : NetworkImage(widget.peeruser[PHOTO_URL]),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Colors.black26, BlendMode.multiply),
                ),
              ),
            ),

            Container(//遮罩层
              color: Colors.black.withOpacity(0.1),
            ),
            SingleChildScrollView(child: Container(//可以滚动的View 用于放用户信息
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(height: 40),
                  CircleAvatar(//头像，如果有头像就加载头像，没有就加载默认图标
                    child: (widget.peeruser == null)
                        ? Image.asset("assets/avatar.png",
                        width: 150, height: 150, fit: BoxFit.cover)
                        : widget.peeruser[PHOTO_URL].toString().isEmpty
                        ? Image.asset("assets/avatar.png",
                        width: 150, height: 150, fit: BoxFit.cover)
                        : Image.network(widget.peeruser[PHOTO_URL],
                        width: 150, height: 150, fit: BoxFit.cover),
                    radius: 50,
                  ),
                  SizedBox(height: 10),
                  Text(//用户的名字
                    (widget.peeruser == null)
                        ? "ceshi"
                        : widget.peeruser[NICKNAME],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white),
                  ),
                  SizedBox(height: 3),
                  Text(//用户的座右铭
                    (widget.peeruser == null)
                        ? "ceshi"
                        : (widget.peeruser[ABOUT_ME] == null)
                        ? "他很懒还没有留下座右铭哦"
                        : widget.peeruser[ABOUT_ME].toString().isEmpty
                        ? "他很懒还没有留下座右铭哦"
                        : widget.peeruser[ABOUT_ME],
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Row(//聊天按钮
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FlatButton(
                        child: Icon(
                          Icons.message,
                          color: Colors.white,
                        ),
                        color: Theme.of(context).accentColor,
                        onPressed: () {//聊天按钮的点击事件
                          //获取用户的信息然后跳转到聊天界面
                          Firestore.instance
                              .collection(USERS)
                              .document(widget.peeruser[PHONE])
                              .get()
                              .then((user) {
                            widget.model.addUser(user);
                            Navigator.pushReplacement(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => new ChatScreen(
                                        unread: 0,
                                        currentUserNo: widget.currentUserNo,
                                        model: widget.model,
                                        peerNo: user[PHONE])));
                          });
                        },
                      ),
                    ],
                  ),
                  ListTile( //性别信息框
                      title: TextFormField(
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        showCursor: false,
                        autofocus: false,
                        enabled: false,
                        controller: _sex,
                        decoration: InputDecoration(
                            labelText: '性别',
                            disabledBorder: new UnderlineInputBorder(
                                borderSide: new BorderSide(color: Colors.white)),
                            labelStyle: TextStyle(
                              color: Colors.white,
                            )),
                      )),
                  ListTile(//生日信息框
                      title: TextFormField(
                        showCursor: false,
                        enabled: false,
                        autofocus: false,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        controller: _birthday,
                        decoration: InputDecoration(
                            labelText: '生日',
                            disabledBorder: new UnderlineInputBorder(
                                borderSide: new BorderSide(color: Colors.white)),
                            fillColor: Colors.white,
                            labelStyle: TextStyle(
                              color: Colors.white,
                            )),
                      )),
                  GestureDetector(//点击组件，用于放备注
                    onTap: () {//点击事件，点击后显示添加备注的弹出框
                      showDialog(
                          context: context,
                          builder: (context) {

                            return AliasForm(widget.peeruser, widget.model);
                          });
                    },
                    child: ListTile(//备注信息框
                        title: TextFormField(
                          showCursor: false,
                          enabled: false,
                          autofocus: false,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                          controller: _name,
                          decoration: InputDecoration(
                            disabledBorder: new UnderlineInputBorder(
                                borderSide: new BorderSide(color: Colors.white)),
                            labelStyle: TextStyle(
                              color: Colors.white,
                            ),
                            labelText: '备注',
                          ),
                        )),
                  ),
                  ListTile(
                      title: TextFormField(//邮箱信息框
                        showCursor: false,
                        autofocus: false,
                        enabled: false,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        controller: _email,
                        decoration: InputDecoration(
                            labelText: '邮箱',
                            disabledBorder: new UnderlineInputBorder(
                                borderSide: new BorderSide(color: Colors.white)),
                            labelStyle: TextStyle(
                              color: Colors.white,
                            )),
                      )),
                ],
              ),
            ),),
            Positioned(//返回按钮
              top: 50,
              left: 20,
              child: GestureDetector(
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onTap: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}
