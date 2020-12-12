import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'const.dart';
import 'seen_provider.dart';

//聊天的信息框
class Bubble extends StatelessWidget {
  const Bubble(
      {@required this.child,
      @required this.timestamp,
      @required this.delivered,
      @required this.isMe,
      @required this.isContinuing});

  final int timestamp;//聊天的时间
  final Widget child;//子组件
  final dynamic delivered;//分割线
  final bool isMe, isContinuing;//是否是我，是否继续

  //时间格式
  humanReadableTime() => DateFormat('hh:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  //获取最近的状态
  getSeenStatus(seen) {
    if (seen is bool) return true;
    if (seen is String) return true;
    return timestamp <= seen;
  }

  //构建界面
  @override
  Widget build(BuildContext context) {
    //获取最近的状态以及时间
    final bool seen = getSeenStatus(SeenProvider.of(context).value);
    final bg = isMe ? Theme.of(context).accentColor : Colors.grey[200];
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    dynamic icon = delivered is bool && delivered
        ? (seen ? Icons.done_all : Icons.done)
        : Icons.access_time;
    final color = isMe ? Colors.white : Colors.black;
    icon = Icon(icon, size: 13.0, color: seen ? Colors.greenAccent : color);
    if (delivered is Future) {
      icon = FutureBuilder(
          future: delivered,
          builder: (context, res) {
            switch (res.connectionState) {
              case ConnectionState.done:
                return Icon((seen ? Icons.done_all : Icons.done),
                    size: 13.0, color: seen ? Colors.greenAccent : color);
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
              default:
                return Icon(Icons.access_time,
                    size: 13.0, color: seen ? Colors.greenAccent : color);
            }
          });
    }
    dynamic radius = isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
            bottomRight: Radius.circular(10.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(5.0),
          );
    dynamic margin = const EdgeInsets.only(top: 20.0, bottom: 1.5);
    if (isContinuing) {
      radius = BorderRadius.all(Radius.circular(5.0));
      margin = const EdgeInsets.all(1.5);
    }

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
          margin: margin,
          padding: const EdgeInsets.all(8.0),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                  padding: child is Container
                      ? EdgeInsets.all(0.0)
                      : EdgeInsets.only(right: isMe ? 10.0 : 15.0),
                  child: child),

            ],
          ),
        ),
        Padding(
          padding: isMe
              ? EdgeInsets.only(
                  right: 0,
                  bottom: 10.0,
                )
              : EdgeInsets.only(
                  left: 10,
                  bottom: 10.0,
                ),
          child: Text(
            humanReadableTime().toString() + (isMe ? ' ' : ''),
            style: TextStyle(
              color: Colors.black,
              fontSize: 10.0,
            ),
          ),
        )
      ],
    ));
  }
}
