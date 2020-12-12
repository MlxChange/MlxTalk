import 'dart:io';

import 'package:Enigma/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';

class PostItem extends StatefulWidget {
  final String avatar;
  final String name;
  final String time;
  final String content;
  final String img;
  final String filePath;
  final String fileName;

  PostItem(
      {Key key,
      @required this.avatar,
      @required this.name,
      @required this.time,
      @required this.content,
      @required this.img,
      @required this.filePath,
      @required this.fileName})
      : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.avatar.isEmpty
                    ? AssetImage(
                        "assets/avatar.png",
                      )
                    : NetworkImage(widget.avatar),
              ),
              contentPadding: EdgeInsets.all(0),
              title: Text(
                widget.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Text(
                widget.time,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 11,
                ),
              ),
            ),
            SizedBox(height: 10,),
            Text(
              widget.content,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 20),
            ),
            widget.img.isEmpty
                ? SizedBox(
              height: 0,
            )
                : SizedBox(
              height: 20,
            ),
            widget.img.isEmpty
                ? SizedBox(
                    height: 0,
                  )
                : Image.network(
                    widget.img,
                    height: 170,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
            SizedBox(
              height: 15,
            ),
            widget.fileName.isEmpty
                ? SizedBox(
                    height: 0,
                  )
                : GestureDetector(
                    onTap: () async{
                      var dio=Dio();
                      Enigma.toast("开始下载");

                      var save=Directory("/storage/emulated/0/ZH/");
                      if(!save.existsSync()){
                        await save.create(recursive: true);
                      }
                      try{
                        var response=await dio.download(widget.filePath,"${save.path}${widget.fileName}");
                        if(response.statusCode==200){
                          Enigma.toast("已下载到${save.path}");
                        }
                      }catch(e){
                        print("${e}");
                          Enigma.toast("下载失败:错误${e}");
                      }
                    },
                    child: Row(children: <Widget>[
                      Icon(
                        Icons.file_download,
                        color: Colors.blueAccent,
                      ),
                      Container(

                        width: 300,
                        child: Text(
                          widget.fileName,
                          softWrap: true,
                          maxLines: 2,
                          style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                        ),
                      )
                    ]),
                  )
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
