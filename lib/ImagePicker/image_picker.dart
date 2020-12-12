import 'dart:io';

import 'package:Enigma/open_settings.dart';
import 'package:Enigma/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:Enigma/const.dart';
import 'package:permission_handler/permission_handler.dart';

//图片选择界面
class HybridImagePicker extends StatefulWidget {
  HybridImagePicker(
      {Key key,
      @required this.title,
      @required this.callback,
      this.profile = false})
      : super(key: key);


  //页面标题
  final String title;
  //回调
  final Function callback;
  //
  final bool profile;

  @override
  _HybridImagePickerState createState() => new _HybridImagePickerState();
}

class _HybridImagePickerState extends State<HybridImagePicker> {
  //选择到的图片文件
  File _imageFile;

  //是否加载进度条
  bool isLoading = false;

  @override
  void initState() {
    //状态栏透明
    SystemUiOverlayStyle systemUiOverlayStyle =
    SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    super.initState();

  }

  //将选择到的图片文件设置到属性中
  void captureImage(ImageSource captureMode) async {
    try {
      var imageFile = await ImagePicker.pickImage(source: captureMode);
      setState(() {
        _imageFile = imageFile;
      });
    } catch (e) {}
  }

  //返回image组件
  Widget _buildImage() {
    if (_imageFile != null) {
      return new Image.file(_imageFile);
    } else {
      return new Text('Take an image to start',
          style: new TextStyle(fontSize: 18.0, color: enigmaWhite));
    }
  }

  //裁剪图片
  Future<Null> _cropImage() async {
    double x, y;
    if (widget.profile) {
      x = 1.0;
      y = 1.0;
    }
    //选择裁剪后的图片
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: _imageFile.path);
    setState(() {
      if (croppedFile != null) _imageFile = croppedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Enigma.getNTPWrappedWidget(WillPopScope(
      child: Scaffold(
        backgroundColor: enigmaBlack,//背景颜色
        appBar: new AppBar( //app的标题栏
            title: new Text(widget.title),//标题文字
            backgroundColor: Colors.blueAccent,//背景颜色
            actions: _imageFile != null//如果图片文件不为空的话就显示两个图标按钮，一个裁剪，一个确定
                ? <Widget>[
                    IconButton(
                        icon: Icon(Icons.edit, color: Colors.black),
                        disabledColor: Colors.transparent,
                        onPressed: () {
                          //裁剪按钮的点击事件
                          _cropImage();
                        }),
                    IconButton(
                        icon: Icon(Icons.check, color: Colors.black),
                        onPressed: () {
                          //确定按钮的点击事件
                          setState(() {
                            isLoading = true;
                          });
                          //调用传来的回调，把文件传过去，让调用者自己处理
                          widget.callback(_imageFile).then((imageUrl) {
                            Navigator.pop(context, imageUrl);
                          });
                        }),
                    SizedBox(
                      width: 8.0,
                    )
                  ]
                : []),
        body: Stack(children: [//绝对布局
          new Column(children: [//一列
            new Expanded(child: new Center(child: _buildImage())),
            _buildButtons()
          ]),
          Positioned( //进度条
            child: isLoading //如果正在家在的话就显示进度条，如果没有的话就什么都不显示
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(enigmaBlue)),
                    ),
                    color: enigmaBlack.withOpacity(0.8),
                  )
                : Container(),
          )
        ]),
      ),
      onWillPop: () => Future.value(!isLoading),
    ));
  }

  //构建按钮
  Widget _buildButtons() {
    //一个约束盒子
    return new ConstrainedBox(
      //高度60
        constraints: BoxConstraints.expand(height: 60.0),
        //新的一行
        child: new Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              //左下角选择图片按钮
              _buildActionButton(new Key('retake'), Icons.photo_library, () {
                //检查权限
                Enigma.checkAndRequestPermission(PermissionGroup.storage)
                    .then((res) {
                  if (res) {
                    captureImage(ImageSource.gallery);
                  } else {
                    Enigma.showRationale(
                        'Permission to access gallery needed to send photos to your friends.');
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => OpenSettings()));
                  }
                });
              }),
              //右下角选择拍照按钮
              _buildActionButton(new Key('upload'), Icons.photo_camera, () {
                //检查权限
                Enigma.checkAndRequestPermission(PermissionGroup.camera)
                    .then((res) {
                  if (res) {
                    captureImage(ImageSource.camera);
                  } else {
                    Enigma.showRationale(
                        'Permission to access camera needed to take photos to share with your friends.');
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => OpenSettings()));
                  }
                });
              }),
            ]));
  }

  Widget _buildActionButton(Key key, IconData icon, Function onPressed) {
    return new Expanded(
      child: new RaisedButton(
          key: key,
          child: Icon(icon, size: 30.0),
          shape: new RoundedRectangleBorder(),
          color: Colors.blueAccent,
          textColor: Colors.white,
          onPressed: onPressed),
    );
  }
}
