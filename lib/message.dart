import 'package:Enigma/const.dart';
import 'package:flutter/material.dart';
import 'package:Enigma/seen_provider.dart';

//消息实体类，用于对应聊天消息
class Message {
  Message(Widget child,
      {@required this.timestamp,
      @required this.from,
      @required this.onTap,
      @required this.onDoubleTap,
      @required this.onDismiss,
      @required this.onLongPress,
      this.saved = false})
      : child = wrapMessage(
            child: child,
            onDismiss: onDismiss,
            onDoubleTap: onDoubleTap,
            onTap: onTap,
            onLongPress: onLongPress,
            saved: saved);

  final String from; //从哪里发出
  final Widget child;
  final int timestamp;//时间
  final VoidCallback onTap, onDoubleTap, onDismiss, onLongPress;//各种点击事件
  final bool saved;//是否保存了
  static Widget wrapMessage(
      {@required SeenProvider child,
      @required onDismiss,
      @required onDoubleTap,
      @required onTap,
      @required onLongPress,
      @required bool saved}) {
    return child.child.isMe
        ? GestureDetector(
            child: child,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress,
          )
        : Dismissible(
            background: Align(
              child: Icon(Icons.delete_sweep, color: enigmaWhite, size: 40),
              alignment: Alignment.bottomLeft,
            ),
            key: Key(child.timestamp),
            dismissThresholds: {DismissDirection.startToEnd: 0.9},
            child: GestureDetector(
              child: child,
              onDoubleTap: onDoubleTap,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
            onDismissed: (direction) {
              if (onDismiss != null) onDismiss();
            },
            direction: DismissDirection.startToEnd,
          );
  }
}
