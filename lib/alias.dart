import 'dart:io';

import 'package:Enigma/DataModel.dart';
import 'package:Enigma/const.dart';
import 'package:Enigma/util/const.dart';
import 'package:Enigma/utils.dart';
import 'package:flutter/material.dart';
import 'package:Enigma/ImagePicker/image_picker.dart';

//修改备注的弹出框
class AliasForm extends StatefulWidget {
  final Map<String, dynamic> user;//用户信息
  final DataModel model;//数据模型
  AliasForm(this.user, this.model);

  @override
  _AliasFormState createState() => _AliasFormState();
}

class _AliasFormState extends State<AliasForm> {

  //文本控制器，用于获得备注
  TextEditingController _alias;

  //头像文件
  File _imageFile;

  @override
  void initState() {
    super.initState();
    _alias = new TextEditingController(text: Enigma.getNickname(widget.user));
  }

  //获得图片
  Future getImage(File image) {
    setState(() {
      _imageFile = image;
    });
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    String name = Enigma.getNickname(widget.user);
    return Theme(
        child: AlertDialog(
          actions: <Widget>[
            //两个按钮，一个是添加备注，一个是删除备注
            FlatButton(
                child: Text(
                  '删除备注',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: widget.user[ALIAS_NAME] != null ||
                        widget.user[ALIAS_AVATAR] != null
                    ? () {
                  //删除备注
                        widget.model.removeAlias(widget.user[PHONE]);
                        Navigator.pop(context);
                      }
                    : null),
            FlatButton(
                child: Text(
                  '添加备注',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (_alias.text.isNotEmpty) {
                    if (_alias.text != name || _imageFile != null) {
                      //添加备注
                      widget.model.setAlias(
                          _alias.text, _imageFile, widget.user[PHONE]);
                    }
                    Navigator.pop(context);
                  }
                })
          ],
          contentPadding: EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 120,
                  height: 120,
                  child: Stack(children: [
                    Center( //头像
                        child: Enigma.avatar(widget.user,
                            image: _imageFile, radius: 50)),
                    Positioned(//修改按钮
                        bottom: 0,
                        right: 0,
                        child: FloatingActionButton(
                          mini: true,
                          child: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridImagePicker(
                                          title: 'Pick an image',
                                          callback: getImage,
                                          profile: true,
                                        )));
                          },
                        )),
                  ])),
              TextFormField( //备注文本的输入框
                autovalidate: true,
                controller: _alias,
                decoration: InputDecoration(hintText: '备注'),
                validator: (val) {
                  if (val.trim().isEmpty) return '备注不能为空!';
                  return null;
                },
              )
            ]),
          ),
        ),
        data: Constants.lightTheme);
  }
}
