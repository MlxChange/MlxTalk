import 'dart:core';
import 'dart:async';
import 'dart:io';
import 'package:Enigma/const.dart';
import 'package:Enigma/utils.dart';
import 'package:async/async.dart' show StreamGroup;
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localstorage/localstorage.dart';

//数据模型类
class DataModel extends Model {
  //用户的数据以键值对形式存放
  Map<String, Map<String, dynamic>> userData =
      new Map<String, Map<String, dynamic>>();

  Map<String, Future> _messageStatus = new Map<String, Future>();

  _getMessageKey(String peerNo, int timestamp) => '$peerNo$timestamp';

  getMessageStatus(String peerNo, int timestamp) {
    final key = _getMessageKey(peerNo, timestamp);
    return _messageStatus[key] ?? true;
  }

  bool _loaded = false;

  LocalStorage _storage = LocalStorage('model');

  //添加消息
  addMessage(String peerNo, int timestamp, Future future) {
    final key = _getMessageKey(peerNo, timestamp);
    future.then((_) {
      _messageStatus.remove(key);
    });
    _messageStatus[key] = future;
  }

  //添加用户
  addUser(DocumentSnapshot user) {
    userData[user.data[PHONE]] = user.data;
    notifyListeners();
  }

  //添加壁纸
  setWallpaper(String phone, File image) async {
    if (image != null) {
      final dir = await getDir();
      int now = DateTime.now().millisecondsSinceEpoch;
      String path = '${dir.path}/WALLPAPER-$phone-$now';
      await image.copy(path);
      userData[phone][WALLPAPER] = path;
      updateItem(phone, {WALLPAPER: path});
      notifyListeners();
    }
  }

  //移出壁纸
  removeWallpaper(String phone) {
    userData[phone][WALLPAPER] = null;
    String path = userData[phone][ALIAS_AVATAR];
    if (path != null) {
      File(path).delete();
      userData[phone][WALLPAPER] = null;
    }
    updateItem(phone, {WALLPAPER: null});
    notifyListeners();
  }

  getDir() async {
    return await getApplicationDocumentsDirectory();
  }

  //更新条目
  updateItem(String key, Map<String, dynamic> value) {
    Map<String, dynamic> old = _storage.getItem(key) ?? Map<String, dynamic>();
    ;
    old.addAll(value);
    _storage.setItem(key, old);
  }

  //设置备注
  setAlias(String aliasName, File image, String phone) async {
    userData[phone][ALIAS_NAME] = aliasName ?? null;
    if (image != null) {
      final dir = await getDir();
      int now = DateTime.now().millisecondsSinceEpoch;
      String path = '${dir.path}/$phone-$now';
      await image.copy(path);
      userData[phone][ALIAS_AVATAR] = path;
    }
    updateItem(phone, {
      ALIAS_NAME: userData[phone][ALIAS_NAME],
      ALIAS_AVATAR: userData[phone][ALIAS_AVATAR],
    });
    notifyListeners();
  }

  //移除备注
  removeAlias(String phone) {
    userData[phone][ALIAS_NAME] = null;
    String path = userData[phone][ALIAS_AVATAR];
    if (path != null) {
      File(path).delete();
      userData[phone][ALIAS_AVATAR] = null;
    }
    updateItem(phone, {ALIAS_NAME: null, ALIAS_AVATAR: null});
    notifyListeners();
  }

  bool get loaded => _loaded;

  Map<String, dynamic> get currentUser => _currentUser;

  Map<String, dynamic> _currentUser;

  Map<String, int> get lastSpokenAt => _lastSpokenAt;

  Map<String, int> _lastSpokenAt = {};

  //获取聊天的顺序
  getChatOrder(List<String> chatsWith, String currentUserNo) {
    List<Stream<QuerySnapshot>> messages = List<Stream<QuerySnapshot>>();
    chatsWith.forEach((otherNo) {
      String chatId = Enigma.getChatId(currentUserNo, otherNo);
      messages.add(Firestore.instance
          .collection(MESSAGES)
          .document(chatId)
          .collection(chatId)
          .snapshots());
    });
    StreamGroup.merge(messages).listen((snapshot) {
      if (snapshot.documents.isNotEmpty) {
        DocumentSnapshot message = snapshot.documents.last;
        _lastSpokenAt[message[FROM] == currentUserNo
            ? message[TO]
            : message[FROM]] = message[TIMESTAMP];
        notifyListeners();
      }
    });
  }

  //根据传入的当前用户的手机号获取当前用户的最新数据
  DataModel(String currentUserNo) {
    //从firebase实时数据库中同步数据
    Firestore.instance
        .collection(USERS)
        .document(currentUserNo)
        .snapshots()
        .listen((user) {
      _currentUser = user.data;
      notifyListeners();
    });
    //缓存数据
    _storage.ready.then((ready) {
      if (ready) {
        //监听聊天的数据变化
        Firestore.instance
            .collection(USERS)
            .document(currentUserNo)
            .collection(CHATS_WITH)
            .document(CHATS_WITH)
            .snapshots()
            .listen((_chatsWith) {
          if (_chatsWith?.data != null) {
            List<Stream<DocumentSnapshot>> users =
                new List<Stream<DocumentSnapshot>>();
            List<String> peers = [];
            _chatsWith.data.entries.forEach((_data) {
              peers.add(_data.key);
              users.add(Firestore.instance
                  .collection(USERS)
                  .document(_data.key)
                  .snapshots());
              if (userData[_data.key] != null) {
                userData[_data.key][CHAT_STATUS] = _chatsWith[_data.key];
              }
            });
            getChatOrder(peers, currentUserNo);
            notifyListeners();
            Map<String, Map<String, dynamic>> newData =
                Map<String, Map<String, dynamic>>();
            StreamGroup.merge(users).listen((user) {
              if (user.data != null) {
                newData[user[PHONE]] = user.data;
                newData[user[PHONE]][CHAT_STATUS] = _chatsWith[user[PHONE]];
                Map<String, dynamic> _stored = _storage.getItem(user[PHONE]);
                if (_stored != null) {
                  newData[user[PHONE]].addAll(_stored);
                }
              }
              userData = Map.from(newData);
              notifyListeners();
            });
          }
          if (!_loaded) {
            _loaded = true;
            notifyListeners();
          }
        });
      }
    });
  }
}
