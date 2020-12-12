import 'dart:core';
import 'dart:async';
import 'package:Enigma/DataModel.dart';
import 'package:Enigma/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Enigma/const.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//聊天管理类
class ChatController {


  //聊天的请求
  static request(currentUserNo, peerNo) {
    Firestore.instance
        .collection(USERS)
        .document(currentUserNo)
        .collection(CHATS_WITH)
        .document(CHATS_WITH)
        .setData({'$peerNo': ChatStatus.waiting.index}, merge: true);
    Firestore.instance
        .collection(USERS)
        .document(peerNo)
        .collection(CHATS_WITH)
        .document(CHATS_WITH)
        .setData({'$currentUserNo': ChatStatus.requested.index}, merge: true);
  }

  //接受聊天请求
  static accept(currentUserNo, peerNo) {
    Firestore.instance
        .collection(USERS)
        .document(currentUserNo)
        .collection(CHATS_WITH)
        .document(CHATS_WITH)
        .setData({'$peerNo': ChatStatus.accepted.index}, merge: true);
  }

  //拒绝聊天请求
  static block(currentUserNo, peerNo) {
    Firestore.instance
        .collection(USERS)
        .document(currentUserNo)
        .collection(CHATS_WITH)
        .document(CHATS_WITH)
        .setData({'$peerNo': ChatStatus.blocked.index}, merge: true);
    Firestore.instance
        .collection(MESSAGES)
        .document(Enigma.getChatId(currentUserNo, peerNo))
        .setData({'$currentUserNo': DateTime.now().millisecondsSinceEpoch},
            merge: true);
    Enigma.toast('Blocked.');
  }

  //获取聊天的状态
  static Future<ChatStatus> getStatus(currentUserNo, peerNo) async {
    var doc = await Firestore.instance
        .collection(USERS)
        .document(currentUserNo)
        .collection(CHATS_WITH)
        .document(CHATS_WITH)
        .get();
    return ChatStatus.values[doc[peerNo]];
  }

  //隐藏聊天
  static hideChat(currentUserNo, peerNo) {
    Firestore.instance.collection(USERS).document(currentUserNo).setData({
      HIDDEN: FieldValue.arrayUnion([peerNo])
    }, merge: true);
    Enigma.toast('Chat hidden.');
  }

  //显示聊天
  static unhideChat(currentUserNo, peerNo) {
    Firestore.instance.collection(USERS).document(currentUserNo).setData({
      HIDDEN: FieldValue.arrayRemove([peerNo])
    }, merge: true);
    Enigma.toast('Chat is visible.');
  }

  //锁定聊天
  static lockChat(currentUserNo, peerNo) {
    Firestore.instance.collection(USERS).document(currentUserNo).setData({
      LOCKED: FieldValue.arrayUnion([peerNo])
    }, merge: true);
    Enigma.toast('Chat locked.');
  }

  //解锁聊天
  static unlockChat(currentUserNo, peerNo) {
    Firestore.instance.collection(USERS).document(currentUserNo).setData({
      LOCKED: FieldValue.arrayRemove([peerNo])
    }, merge: true);
    Enigma.toast('Chat unlocked.');
  }

  //聊天的消息验证
  static void authenticate(DataModel model, String caption,
      {@required NavigatorState state,
      AuthenticationType type = AuthenticationType.passcode,
      @required SharedPreferences prefs,
      @required Function onSuccess,
      @required bool shouldPop}) {
    Map<String, dynamic> user = model.currentUser;
    if (user != null && model != null) {

    }
  }
}
