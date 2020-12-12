import 'dart:async';
import 'dart:io';

import 'package:Enigma/login.dart';
import 'package:Enigma/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Enigma/const.dart';
import 'package:Enigma/util/const.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:Enigma/ImagePicker/image_picker.dart';

class Settings extends StatefulWidget {
  final bool biometricEnabled;
  final AuthenticationType type;

  Settings({this.biometricEnabled, this.type});

  @override
  State createState() => new SettingsState();
}

class SettingsState extends State<Settings> {
  //以下分别为姓名，座右铭，生日，性别和邮箱的控制器
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;
  TextEditingController birthdayController;
  TextEditingController sexController;
  TextEditingController emailControll=TextEditingController();

  SharedPreferences prefs;

  //定义姓名，座右铭，生日，性别和邮箱
  String phone = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  String birthday = '';
  String sex = '';
  String email='';

  //是否处于加载状态
  bool isLoading = false;
  //头像文件
  File avatarImageFile;

  //姓名和关于我
  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();

  @override
  void initState() {
    super.initState();
    //检查网络状态
    Enigma.internetLookUp();
    //读取本地信息
    readLocal();

  }

  //读取本地信息并设置到界面中
  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    phone = prefs.getString(PHONE) ?? '';
    nickname = prefs.getString(NICKNAME) ?? '';
    aboutMe = prefs.getString(ABOUT_ME) ?? '';
    photoUrl = prefs.getString(PHOTO_URL) ?? '';
    birthday = prefs.getString(BIRTHDAY) ?? '';
    sex = prefs.getString(Sex) ?? '';
    email = prefs.getString(EMAIL) ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);
    birthdayController = new TextEditingController(text: birthday);
    sexController = new TextEditingController(text: sex);
    emailControll.text=email;
    // Force refresh input
    setState(() {});
  }

  //获取到图片
  Future getImage(File image) async {
    if (image != null) {
      setState(() {
        avatarImageFile = image;
      });
    }
    return uploadFile();
  }

  //上传文件并获取到文件的地址
  Future uploadFile() async {
    String fileName = phone;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageTaskSnapshot uploading =
        await reference.putFile(avatarImageFile).onComplete;
    var s = await uploading.ref.getDownloadURL();

    return uploading.ref.getDownloadURL();
  }

  //更新数据
  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    nickname =
        controllerNickname.text.isEmpty ? nickname : controllerNickname.text;
    aboutMe = controllerAboutMe.text.isEmpty ? aboutMe : controllerAboutMe.text;
    email = emailControll.text.isEmpty ? email : emailControll.text;

    //更新用户的信息然后缓存到本地
    Firestore.instance.collection(USERS).document(phone).updateData({
      NICKNAME: nickname,
      ABOUT_ME: aboutMe,
      EMAIL:email
    }).then((data) async {
      await prefs.setString(NICKNAME, nickname);
      await prefs.setString(ABOUT_ME, aboutMe);
      await prefs.setString(EMAIL, email);
      setState(() {
        isLoading = false;
      });
      Enigma.toast("保存成功!");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Enigma.toast(err.toString());
    });
  }

  //构建用户界面
  @override
  Widget build(BuildContext context) {
    return Enigma.getNTPWrappedWidget(Theme(
        data: Constants.lightTheme,
        child: Scaffold(
            appBar: new AppBar(
              title: new Text( //标题
                'Settings',
              ),
              actions: <Widget>[ //保存按钮
                FlatButton(
                  textColor: Colors.blue,
                  onPressed: handleUpdateData,
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
            body: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // Avatar
                      Container(
                        child: Center(
                          child: Stack(
                            children: <Widget>[
                              (avatarImageFile == null)
                                  ? (photoUrl != ''
                                      ? Material(
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) =>
                                                Container(
                                                    child: Padding(
                                                        padding: EdgeInsets.all(
                                                            50.0),
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  enigmaBlue),
                                                        )),
                                                    width: 150.0,
                                                    height: 150.0),
                                            imageUrl: photoUrl,
                                            width: 150.0,
                                            height: 150.0,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(75.0)),
                                          clipBehavior: Clip.hardEdge,
                                        )
                                      : Icon(
                                          Icons.account_circle,
                                          size: 150.0,
                                          color: Colors.grey,
                                        ))
                                  : Material(
                                      child: Image.file(
                                        avatarImageFile,
                                        width: 150.0,
                                        height: 150.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(75.0)),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                              Positioned( //选择图片按钮
                                  bottom: 0,
                                  right: 0,
                                  child: FloatingActionButton(
                                      heroTag: "setting_pick",
                                      child: Icon(Icons.camera_alt),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HybridImagePicker(
                                                        title: 'Pick an image',
                                                        callback: getImage,
                                                        profile: true))).then(
                                            (url) {
                                          if (url != null) {
                                            photoUrl = url.toString();
                                            Firestore.instance
                                                .collection(USERS)
                                                .document(phone)
                                                .updateData({
                                              PHOTO_URL: photoUrl
                                            }).then((data) async {
                                              await prefs.setString(
                                                  PHOTO_URL, photoUrl);
                                              setState(() {
                                                isLoading = false;
                                              });
                                              Enigma.toast(
                                                  "Profile Picture Changed!");
                                            }).catchError((err) {
                                              setState(() {
                                                isLoading = false;
                                              });

                                              Enigma.toast(err.toString());
                                            });
                                          }
                                        });
                                      })),
                            ],
                          ),
                        ),
                        width: double.infinity,
                        margin: EdgeInsets.all(20.0),
                      ),
                      ListTile( //姓名
                          title: TextFormField(
                        autovalidate: true,
                        autofocus: false,
                        controller: controllerNickname,
                        validator: (v) {
                          return v.isEmpty ? 'Name cannot be empty!' : null;
                        },
                        decoration: InputDecoration(labelText: '昵称'),
                      )),
                      ListTile( //签名
                          title: TextFormField(
                        controller: controllerAboutMe,
                        autofocus: false,
                        decoration: InputDecoration(labelText: '座右铭'),
                      )),
                      ListTile( //生日
                          title: TextFormField(
                        enabled: false,
                        controller: birthdayController,
                        decoration: InputDecoration(
                          labelText: '生日',
                        ),
                      )),
                      ListTile( //性别
                          title: TextFormField(
                        enabled: false,
                        controller: sexController,
                        decoration: InputDecoration(labelText: '性别'),
                      )),
                      ListTile(//邮箱
                          title: TextFormField(
                        autofocus: false,
                        controller: emailControll,
                        decoration: InputDecoration(labelText: '邮箱'),
                      )),
                      SizedBox(
                        height: 20,
                      ),
                      ListTile(
                          title: Row(children: [
                        Expanded( //退出登录按钮
                            child: RaisedButton.icon(
                                icon: Icon(Icons.cancel),
                                label: Text('退出登录'),
                                color: Constants.darkAccent,
                                textColor: Colors.white,
                                onPressed: () async {
                                  var pf =
                                      await SharedPreferences.getInstance();
                                  await pf.clear();
                                  unawaited(Navigator.pushReplacement(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => new LoginScreen(
                                            title: 'Sign in to ZH')),
                                  ));
                                  ;
                                }))
                      ])),
                    ],
                  ),
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                ),
                // Loading
                Positioned( //进度条
                  child: isLoading
                      ? Container(
                          child: Center(
                            child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(enigmaBlue)),
                          ),
                          color: Colors.black.withOpacity(0.8),
                        )
                      : Container(),
                ),
              ],
            ))));
  }

  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  _onPasscodeEntered(String enteredPasscode) {
    bool isValid = enteredPasscode.length == 4;
    _verificationNotifier.add(isValid);
  }

  _onSubmit(String newPasscode) {
    setState(() {
      isLoading = true;
    });
    Firestore.instance
        .collection(USERS)
        .document(phone)
        .updateData({PASSCODE: Enigma.getHashedString(newPasscode)}).then((_) {
      prefs.setInt(ANSWER_TRIES, 0);
      prefs.setInt(PASSCODE_TRIES, 0);
      setState(() {
        isLoading = false;
        Enigma.toast('Updated!');
      });
    });
  }


}
