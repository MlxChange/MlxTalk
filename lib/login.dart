import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:Enigma/main.dart';
import 'package:Enigma/utils.dart';
import 'package:Enigma/widgets/signup_apbar.dart';
import 'package:Enigma/widgets/signup_arrow_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Enigma/E2EE/e2ee.dart' as e2ee;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ImagePicker/image_picker.dart';
import 'const.dart';

//登录界面
class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  //firebase的用户验证
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;
  //手机号
  final _phoneNo = TextEditingController();
 //手机号的国际码，国内为+86
  String phoneCode = '+86';
  //用户存储
  final storage = new FlutterSecureStorage();
  //手机号和短信验证码
  String phone;
  String smsCode;
  //用户名和密码 在本页面中是手机号和验证码
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();

  //以下五个为颜色渐变，分别为注册时候的各种颜色渐变
  LinearGradient SIGNUP_BACKGROUND = LinearGradient(
    begin: FractionalOffset(0.0, 0.4), end: FractionalOffset(0.9, 0.7),
    // Add one stop for each color. Stops should increase from 0 to 1
    stops: [0.1, 0.9], colors: [Color(0xfffbed96), Color(0xffabecd6)],
  );
  LinearGradient SIGNUP_CARD_BACKGROUND = LinearGradient(
    tileMode: TileMode.clamp,
    begin: FractionalOffset.centerLeft,
    end: FractionalOffset.centerRight,
    stops: [0.1, 1.0],
    colors: [Color(0xffffc2a1), Color(0xffffb1bb)],
  );
  LinearGradient SIGNUP_CIRCLE_BUTTON_BACKGROUND = LinearGradient(
    tileMode: TileMode.clamp,
    begin: FractionalOffset.centerLeft,
    end: FractionalOffset.centerRight,
    // Add one stop for each color. Stops should increase from 0 to 1
    stops: [0.4, 1],
    colors: [Colors.black, Colors.black54],
  );
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
  LinearGradient SIGNUP_SIX_TWITTER_BG = LinearGradient(
    begin: FractionalOffset.centerLeft,
    end: FractionalOffset.centerRight,
    // Add one stop for each color. Stops should increase from 0 to 1
    stops: [0.2, 0.6],
    colors: [
      Color(0xFFc2e9fb),
      Color(0xFFa1c4fd),
    ],
  );



  //验证id
  String verificationId;
  bool isLoading = false;//是否处于加载状态
  dynamic isLoggedIn = false;//是否处于登录状态
  FirebaseUser currentUser;//当前登录用户

  bool tosign = false;//是否跳转到注册页面

  bool showLoginCode = false;//是否严重验证码框

  /*
  *   注册
  */
  String _currentDate = '选择日期';


  //手机号，验证码，邮箱和用户名
  TextEditingController _controller = TextEditingController();
  TextEditingController _Passcontroller = TextEditingController();
  TextEditingController _Emailcontroller = TextEditingController();
  TextEditingController _Codecontroller = TextEditingController();

  //头像
  File avatarImageFile;
  String avatartImageUrl;//头像的url

  bool showCodeBox = false;//注册界面的是否显示验证码



  //选择时间
  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: new DateTime.now(),
        firstDate: new DateTime(2016),
        lastDate: new DateTime(2050));

    if (picked != null)

      setState(
        () => _currentDate = "${picked.year}-${picked.month}-${picked.day}",
      );
  }

  bool _male = true; //男
  bool _famele = false;//女

  @override
  void initState() {
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    super.initState();
  }

  //获取图像
  Future getImage(File image) async {
    if (image != null) {
      setState(() {
        avatarImageFile = image;
      });
    }
  }

  //验证手机号
  Future<void> verifyPhoneNumber() async {
    //定义验证完成的回调函数
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      //跳转到登录/注册上
      handleSignIn(authCredential: phoneAuthCredential);
    };

    //定义验证失败的回调函数
    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      Enigma.reportError(
          '${authException.message} Phone: ${_phoneNo.text} Country Code: $phoneCode ',
          authException.code);
      setState(() {
        isLoading = false;
      });

      Enigma.toast('验证失败 - ${authException.message}. 请重新尝试');
    };

    //定义发送验证码的回调函数
    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      setState(() {
        isLoading = false;
      });

      this.verificationId = verificationId;
    };

    //定义验证码超时函数
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      setState(() {
        isLoading = false;
      });

      this.verificationId = verificationId;
    };

    //firebase的用户验证手机号
    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: (phoneCode + phone).trim(),
        timeout: const Duration(minutes: 2),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  //登录/注册函数
  Future<Null> handleSignIn({AuthCredential authCredential}) async {
    prefs = await SharedPreferences.getInstance();
    if (isLoading == false) {
      this.setState(() {
        isLoading = true;
      });
    }

    //拼接手机号
    var phoneNo = (phoneCode + _Emailcontroller.text).trim();

    //验证码校验
    AuthCredential credential;
    if (authCredential == null) if (_password.text.isNotEmpty ||
        _Codecontroller.text.isNotEmpty) {
      credential = PhoneAuthProvider.getCredential(
        verificationId: verificationId,
        smsCode: _password.text.isEmpty ? _Codecontroller.text : _password.text,
      );
    } else {
      Enigma.toast("验证码不能为空");
    }
    else
      credential = authCredential;
    FirebaseUser firebaseUser;
    try {
      //获取用户信息
      firebaseUser = await firebaseAuth
          .signInWithCredential(credential)
          .catchError((err) async {
        await Enigma.reportError(err, 'signInWithCredential');
        Enigma.toast(
            '验证码输入错误，请重试');
        return;
      });
    } catch (e) {
      await Enigma.reportError(e, 'signInWithCredential catch block');
      Enigma.toast(
          'Make sure your Phone Number/OTP Code is correct and try again later.');


      return;
    }

    //如果用户信息不为空的话就继续，否则是验证失败
    if (firebaseUser != null) {
      // 检查是否已经注册
      final QuerySnapshot result = await Firestore.instance
          .collection(USERS)
          .where(ID, isEqualTo: firebaseUser.uid)
          .getDocuments();
      //获得用户信息并且加密后存储
      final List<DocumentSnapshot> documents = result.documents;
      final pair = await e2ee.X25519().generateKeyPair();
      await storage.write(key: PRIVATE_KEY, value: pair.secretKey.toBase64());
      //如果用户信息为空的话就代表是新用户，就注册
      if (documents.isEmpty) {
        // 注册新用户
        await Firestore.instance.collection(USERS).document(phoneNo).setData({
          PUBLIC_KEY: pair.publicKey.toBase64(),
          COUNTRY_CODE: phoneCode,
          NICKNAME: _controller.text.trim(),
          PHOTO_URL: avatartImageUrl?.trim(),
          ID: firebaseUser.uid,
          PHONE: phoneNo,
          Sex: _male ? "男" : "女",
          BIRTHDAY: _currentDate,
          EMAIL: _Passcontroller.text.trim(),
          AUTHENTICATION_TYPE: AuthenticationType.passcode.index,
          ABOUT_ME: ''
        }, merge: true);

        // 写入数据到本地
        currentUser = firebaseUser;
        await prefs.setString(ID, currentUser.uid);
        await prefs.setString(NICKNAME, _controller.text.trim());
        await prefs.setString(Sex, _male ? "男" : "女");
        await prefs.setString(BIRTHDAY, _currentDate);
        await prefs.setString(PHOTO_URL, currentUser.photoUrl);
        await prefs.setString(PHONE, phoneNo);
        await prefs.setString(COUNTRY_CODE, phoneCode);
        await prefs.setString(EMAIL, _Passcontroller.text.trim());

        //如果用户头像不为孔德华就上传头像，并将头像的url更新到用户的数据中，并再次写入本地
        if(avatarImageFile!=null){
          var url=await uploadFile();
          if (url != null) {
            var photoUrl = url.toString();
            print("photourl:$photoUrl");
            await Firestore.instance
                .collection(USERS)
                .document(phoneNo)
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

              Enigma.toast(err.toString());
            });
          }
        }

        unawaited(Navigator.pushReplacement(context,
            new MaterialPageRoute(builder: (context) => EnigmaWrapper())));
      } else {
        //如果不为空的话就是登录
        await Firestore.instance.collection(USERS).document(phoneNo).setData({
          AUTHENTICATION_TYPE: AuthenticationType.passcode.index,
          PUBLIC_KEY: pair.publicKey.toBase64()
        }, merge: true);
        // 写入用户数据到本地
        await prefs.setString(ID, documents[0][ID]);
        await prefs.setString(NICKNAME, documents[0][NICKNAME]);
        await prefs.setString(Sex, documents[0][Sex]);
        await prefs.setString(BIRTHDAY, documents[0][BIRTHDAY]);
        await prefs.setString(PHOTO_URL, documents[0][PHOTO_URL]);
        await prefs.setString(ABOUT_ME, documents[0][ABOUT_ME] ?? '');
        await prefs.setString(PHONE, documents[0][PHONE]);
        await prefs.setString(EMAIL, documents[0][EMAIL]);
        unawaited(Navigator.pushReplacement(context,
            new MaterialPageRoute(builder: (context) => EnigmaWrapper())));
        Enigma.toast('欢迎回来');
      }
    } else {
      Enigma.toast("登录失败，请重试");
    }
  }

  //上传文件
  Future uploadFile() async {
    String fileName = _Emailcontroller.text;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageTaskSnapshot uploading =
        await reference.putFile(avatarImageFile).onComplete;

    return await uploading.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final _media = MediaQuery.of(context).size;


    //构建登录界面
    var login = Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: SIGNUP_BACKGROUND,
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 60.0, horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Image.asset(
                            "assets/logo_signup.png",
                            height: _media.height / 7,
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          "WELCOME BACK!",
                          style: TextStyle(
                            letterSpacing: 4,
                            fontFamily: "Mlx",
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0,
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Log in',
                          style: TextStyle(
                              fontFamily: "Mlx",
                              fontWeight: FontWeight.w400,
                              fontSize: 40),
                        ),
                        Text(
                          'to continue.',
                          style: TextStyle(
                              fontFamily: "Mlx",
                              fontWeight: FontWeight.w200,
                              fontSize: 40),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Container(
                          height: _media.height / 6,
                          decoration: BoxDecoration(
                            gradient: SIGNUP_CARD_BACKGROUND,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              children: <Widget>[
                                showLoginCode
                                    ? Container(
                                        height: 0,
                                      )
                                    : Expanded(
                                        child: inputText(
                                            "手机号", '', _username, false),
                                      ),
                                showLoginCode
                                    ? Expanded(
                                        child: inputText(
                                            "验证码", '', _password, true))
                                    : Container(
                                        height: 0,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "没有账号？",
                        style: TextStyle(color: Color(0xFF303030)),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () => this.setState(() {
                          print(tosign);
                          tosign = true;
                        }),
                        child: Text("注册"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50,
                  )
                ],
              ),
              Positioned(
                bottom: _media.height / 6.3,
                right: 15,
                child: SignUpArrowButton(
                  icon: IconData(0xe901, fontFamily: 'Icons'),
                  iconSize: 9,
                  onTap: () async {
                    if (!showLoginCode) {
                      if (_username.text.isNotEmpty) {
                        this.setState(() {
                          isLoading = true;
                        });
                        phone=_username.text.toString();
                        await verifyPhoneNumber();
                        this.setState(() {
                          showLoginCode = true;
                          isLoading = false;
                        });
                      } else {
                        Enigma.toast("手机号不能为空");
                      }
                    } else {
                      if (_password.text.length == 6) {
                        handleSignIn();
                      } else {
                        Enigma.toast("x`验证码不能为空");
                      }
                    }
                  },
                ),
              ),
              isLoading
                  ? SpinKitCubeGrid(
                color: Colors.white,
                size: 50.0,
              )
                  : SizedBox(
                height: 0,
              )
            ],
          ),
        ),
      ),
    );
    //构建注册界面
    var sign = Scaffold(
      appBar: SignupApbar(
        title: "创建帐户",
        tap: () => this.setState(() => tosign = false),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              height: _media.height,
              width: _media.width,
              decoration: BoxDecoration(
                gradient: SIGNUP_BACKGROUND,
              ),
            ),
            Column(
              children: <Widget>[
                SizedBox(
                  height: 30,
                ),
                (avatarImageFile == null)
                    ? SignUpArrowButton(
                        height: 70,
                        width: 70,
                        icon: IconData(0xe903, fontFamily: 'Icons'),
                        iconSize: 30,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HybridImagePicker(
                                      title: 'Pick an image',
                                      callback: getImage,
                                      profile: true)));
                        },
                      )
                    : GestureDetector(
                        child: Material(
                          child: Image.file(
                            avatarImageFile,
                            width: 150.0,
                            height: 150.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(75.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HybridImagePicker(
                                      title: 'Pick an image',
                                      callback: getImage,
                                      profile: true)));
                        },
                      ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  "上传头像",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                fieldColorBox(SIGNUP_BACKGROUND, "USERNAME", "",
                    TextInputType.text, _controller),
                fieldColorBox(SIGNUP_CARD_BACKGROUND, "Email", "",
                    TextInputType.emailAddress, _Passcontroller),
                fieldColorBox(SIGNUP_SIX_FACEBOOK_BG, "PHONE", "",
                    TextInputType.phone, _Emailcontroller),
                dateColorBox(
                    SIGNUP_SIX_TWITTER_BG, "生日", _currentDate, _selectDate),
                shadowColorBox(SIGNUP_CARD_BACKGROUND, "性别", "男", "女"),
                showCodeBox
                    ? fieldColorBox(SIGNUP_SIX_FACEBOOK_BG, "验证码", "",
                        TextInputType.number, _Codecontroller)
                    : Container(
                        height: 0,
                      ),
                SizedBox(
                  height: 20,
                ),
                nexButton("next"),
              ],
            ),
            isLoading
                ? SpinKitCubeGrid(
              color: Colors.white,
              size: 50.0,
            )
                : Container(),
          ],
        ),
      ),
    );

    //根据是否跳转注册 显示注册/登录界面
    if (tosign) {
      return sign;
    } else {
      return login;
    }
  }

  //构建输入框
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



  //注册界面的信息框
  Widget shadowColorBox(
      Gradient gradient, String title, String male, String famale) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 30.0,
        right: 30,
        bottom: 8,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 30,
              offset: Offset(1.0, 9.0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 30,
            ),
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 2,
              child: Wrap(
                children: <Widget>[
                  GestureDetector(
                    child: Text(
                      male,
                      style: TextStyle(
                        fontSize: 14,
                        color: _male ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() {
                        _famele = false;
                        _male = true;
                      });
                    },
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  GestureDetector(
                    child: Text(
                      famale,
                      style: TextStyle(
                        fontSize: 14,
                        color: _famele ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() {
                        _famele = true;
                        _male = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  Widget fieldColorBox(Gradient gradient, String title, String text,
      TextInputType type, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 30.0,
        right: 30,
        bottom: 8,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 30,
              offset: Offset(1.0, 9.0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 30,
            ),
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 2,
              child: Wrap(
                children: <Widget>[
                  TextField(
                    controller: controller,
                    keyboardType: type,
                    autofocus: false,
                    obscureText:
                        type == TextInputType.visiblePassword ? true : false,
                    decoration: InputDecoration(
                        hintText: text,
                        border: InputBorder.none,
                        hintStyle:
                            TextStyle(fontSize: 14.0, color: Colors.black)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateColorBox(
      Gradient gradient, String title, String data, Function function) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 30.0,
        right: 30,
        bottom: 8,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 30,
            ),
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 2,
              child: Wrap(
                children: <Widget>[
                  FlatButton(
                    child: Text(
                      data,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: function,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  //按钮
  Widget nexButton(String text) {
    return InkWell(
      child: Container(
        alignment: Alignment.center,
        height: 45,
        width: 120,
        decoration: BoxDecoration(
          gradient: SIGNUP_CIRCLE_BUTTON_BACKGROUND,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xfffbed96),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
          ),
        ),
      ),
      onTap: () async {
        //注册按钮
        if (!showCodeBox) {
          if (_Emailcontroller.text.isNotEmpty &&
              _controller.text.isNotEmpty &&
              _Passcontroller.text.isNotEmpty &&
              _currentDate.isNotEmpty) {
            this.setState(() => showCodeBox = true);

            String _phone = _Emailcontroller.text.toString().trim();
            RegExp e164 = new RegExp(r'^\+[1-9]\d{1,14}$');
            if (_phone.isNotEmpty && e164.hasMatch("+86" + _phone)) {
              setState(() {
                isLoading = true;
              });
              phone = _phone;
              await verifyPhoneNumber();
              setState(() {
                isLoading = false;
              });
            } else {
              Enigma.toast('请输入正确的手机号码.');
            }
          } else {
            Enigma.toast("个人信息不能为空");
          }
        } else {
          if (_Codecontroller.text.length == 6) {
            setState(() {
              isLoading = true;
            });
            await handleSignIn();
          }
        }
      },
    );
  }
}
