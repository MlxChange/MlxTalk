import 'package:Enigma/open_settings.dart';
import 'package:Enigma/utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:Enigma/save.dart';
import 'package:permission_handler/permission_handler.dart';

//大图显示的界面
class PhotoViewWrapper extends StatelessWidget {
  const PhotoViewWrapper(
      {this.imageProvider,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      @required this.tag});

  final String tag; //标记
  //图片提供者
  final ImageProvider imageProvider;
  //加载进度条
  final Widget loadingChild;
  //背景颜色
  final Decoration backgroundDecoration;
  final dynamic minScale;//最小尺寸
  final dynamic maxScale;//最大尺寸

  @override
  Widget build(BuildContext context) {
    return Enigma.getNTPWrappedWidget(Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //检查存储权限，如果有的话就保存到内存卡中，没有的话就提示用户没有权限
            Enigma.checkAndRequestPermission(PermissionGroup.storage)
                .then((res) {
              if (res) {
                Save.saveToDisk(imageProvider, tag);
                Enigma.toast('Saved!');
              } else {
                Enigma.showRationale(
                    '需要存储权限才可以保存图片哦');
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => OpenSettings()));
              }
            });
          },
          child: Icon(Icons.file_download),
        ),
        body: Container( //显示大图
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            child: PhotoView(
              imageProvider: imageProvider,
              loadingChild: loadingChild,
              backgroundDecoration: backgroundDecoration,
              minScale: minScale,
              maxScale: maxScale,
              heroTag: tag,
            ))));
  }
}
