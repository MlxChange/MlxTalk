import 'dart:io';
import 'dart:ui';

import 'package:Enigma/ImagePicker/image_picker.dart';
import 'package:Enigma/util/GradientUtil.dart';
import 'package:Enigma/util/SizeUtil.dart';
import 'package:Enigma/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

///
import "package:flutter/material.dart";
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';


//发布分享页面
class FeedFivePage extends StatefulWidget {
  @override
  _FeedFiveState createState() => _FeedFiveState();
}

class _FeedFiveState extends State<FeedFivePage> {

  var _value = "";

  //内容控制器，用来控制文本的输入和获取
  TextEditingController _content = TextEditingController();
  //图片
  File imgFile;
  //选择的文件
  File selectFile;
  //是否显示加载框
  bool isLoading = false;
  //获取图片
  void getImage(File image) async {
    if (image != null) {
      setState(() {
        imgFile = image;
      });
    }
  }

  //图片选择框
  Widget _content2() => Container(
        margin: EdgeInsets.symmetric(
          vertical: SizeUtil.getAxisY(50),
        ),
        child: GestureDetector(//点击事件组件
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HybridImagePicker(
                        title: 'Pick an image',
                        callback: getImage,
                        profile: true)));
          },
          child: Row(
            children: <Widget>[
              SizedBox(width: SizeUtil.getAxisX(22)),
              Icon(
                Icons.camera_alt,
                size: SizeUtil.getAxisBoth(28),
              ),
              SizedBox(width: SizeUtil.getAxisX(64)),
              Text("分享照片", style: TextStyle(color: TEXT_BLACK)),
              Expanded(
                  child: Container(
                constraints: BoxConstraints.expand(
                  height: SizeUtil.getAxisBoth(78),
                ),
                alignment: Alignment.centerRight,
                child: Container(
                  height: SizeUtil.getAxisBoth(78),
                  width: SizeUtil.getAxisBoth(78),
                  child: imgFile == null
                      ? Icon(
                          Icons.add_a_photo,
                          color: Colors.black,
                        )
                      : SizedBox(
                          height: 0,
                        ),
                  decoration: imgFile == null
                      ? BoxDecoration(borderRadius: BorderRadius.circular(4))
                      : BoxDecoration(
                          image: DecorationImage(
                              image: FileImage(imgFile), fit: BoxFit.fill),
                          borderRadius: BorderRadius.circular(4)),
                ),
              ))
            ],
          ),
        ),
      );

  //获取本地文件
  Future<File> _getLocalFile() async {
    // 获取应用目录
    File selectfile = await FilePicker.getFile();
    this.setState(() => this.selectFile = selectfile);
  }

  //上传文件
  Future uploadFile(String name, File file) async {
    //firebase上传文件并获取文件的下载地址
    StorageReference reference = FirebaseStorage.instance.ref().child(name);
    StorageTaskSnapshot uploading = await reference.putFile(file).onComplete;
    var s = await uploading.ref.getDownloadURL();
    return s;
  }

  //文件选择框
  Widget _content3() => Container(
        margin: EdgeInsets.symmetric(
          vertical: SizeUtil.getAxisY(50),
        ),
        child: GestureDetector(//点击事件，用于获得本地文件
          onTap: () {
            _getLocalFile();
          },
          child: Row(
            children: <Widget>[
              SizedBox(width: SizeUtil.getAxisX(22)),
              Icon(
                Icons.file_upload,
                size: SizeUtil.getAxisBoth(28),
              ),
              SizedBox(width: SizeUtil.getAxisX(64)),
              Text(
                "分享文件",
                style: TextStyle(color: TEXT_BLACK),
              ),
              SizedBox(
                width: 30,
              ),
              Expanded(
                child: Container(
                  constraints: BoxConstraints.expand(
                    height: SizeUtil.getAxisBoth(78),
                  ),
                  alignment: Alignment.centerRight,
                  child: selectFile == null//如果选择的文件不为空就显示文件的名字，否则显示默认图标
                      ? Icon(
                          Icons.cloud_upload,
                          color: Colors.black,
                        )
                      : Text(
                          path.basename(selectFile.path),
                          softWrap: true,
                          maxLines: 1,
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              )
            ],
          ),
        ),
      );

  //文本编辑框
  Widget _content4() => Container(
        margin: EdgeInsets.symmetric(
          vertical: SizeUtil.getAxisY(50),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(width: SizeUtil.getAxisX(22)),
            Icon(
              Icons.mode_edit,
              size: SizeUtil.getAxisBoth(28),
            ),
            SizedBox(width: SizeUtil.getAxisX(64)),
            Text(
              "写下此时的心情吧",
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );

  //文本编辑框
  Widget _upContent() => Container(
        constraints: BoxConstraints.expand(height: SizeUtil.getAxisY(900)),
        margin: EdgeInsets.symmetric(
          vertical: SizeUtil.getAxisY(48),
          horizontal: SizeUtil.getAxisX(44),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeUtil.getAxisX(38),
          vertical: SizeUtil.getAxisY(50),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _content2(),
              _content3(),
              _content4(),
              TextField(
                controller: _content,
                maxLines: 3,
                maxLength: 140,
                autofocus: false,
                decoration: InputDecoration(hintText: "随便写写"),
              ),
              nexButton("发布")//发布按钮
            ],
          ),
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: GradientUtil.greenPurple()),
      );

  //构建用户界面
  @override
  Widget build(BuildContext context) {
    //带appbar的用户界面
    return Scaffold(
      body: Stack(//绝对定位
        alignment: Alignment.center,
        children: <Widget>[
          Container(//容器
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(//绝对定位
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(//容器
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/share.jpeg"),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                                Colors.black26, BlendMode.multiply),
                          ),
                        ),
                      ),
                      _upContent(),
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(//返回按钮
            top: 50,
            left: 30,
            child: GestureDetector(
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          isLoading //是否处于加载状态，是的话显示进度条
              ? SpinKitCubeGrid(
                  color: Colors.white,
                  size: 50.0,
                )
              : SizedBox(
                  height: 0,
                )
        ],
      ),
    );
  }

  //完成按钮
  Widget nexButton(String text) {
    return InkWell(
      child: Container(
        alignment: Alignment.center,
        height: 45,
        width: 120,
        decoration: BoxDecoration(
          gradient: GradientUtil.greenPurple(),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
          ),
        ),
      ),
      onTap: () async { //点击事件
        //先获取到当前登陆用户的信息，如果没有就无权限发布
        var prefs = await SharedPreferences.getInstance();
        var nickname = prefs.getString(NICKNAME) ?? '';
        var phone = prefs.getString(PHONE) ?? '';
        var photoUrl = prefs.getString(PHOTO_URL) ?? '';
        print(nickname);
        if (nickname.isEmpty || phone.isEmpty) {
          Enigma.toast("当前状态无权限发布");
          return;
        }
        //内容不能为空
        if (_content.text.isEmpty) {
          Enigma.toast("总要写点什么吧亲~~");
        } else {
          //设置处于加载状态，同时如果有图片的话就上传图片，有文件的话就上传文件，拿回文件和图片的URL以后，组装分享的model
          //然后发布到firebase的实时数据库中
          String imgUrl = "", fileUrl = "";
          setState(() {
            isLoading = true;
          });
          if (imgFile != null) {
            imgUrl = await uploadFile(
                "${DateTime.now().millisecondsSinceEpoch}${path.extension(imgFile.path)}",
                imgFile);
          }
          if (selectFile != null) {
            fileUrl = await uploadFile(
                "${path.basename(selectFile.path)}", selectFile);
          }

          //firebase发布到数据库中
          var result = await Firestore.instance.collection(POST).add({
            POST_PHOTO_URL: photoUrl??"",
            POST_NICK_NAME: nickname,
            POST_PHONE: phone,
            POST_TIME: DateTime.now().millisecondsSinceEpoch,
            POST_CONTENT: _content.text,
            POST_IMAGE_URL: imgUrl,
            POST_FILE_NAME:
                selectFile == null ? "" : path.basename(selectFile.path),
            POST_FILE_PATH: fileUrl,
          }).catchError((e) {
            Enigma.toast("发布失败:错误:${e.toString()}");
          });

          setState(() {
            isLoading = false;
          });
          if (result != null) {
            Enigma.toast("发布成功");
            Navigator.pop(context);
          }
        }
      },
    );
  }
}
