import 'dart:ui';

import 'package:flutter/material.dart';

//定义了颜色，文字的常量类

const MAIN_COLOR = Color(0xFF303030);
const DARK_COLOR = Color(0xFFBDBDBD);
const BOTTOM_COLORS = [MAIN_COLOR, DARK_COLOR];
const YELLOW = Color(0xfffbed96);
const BLUE = Color(0xffabecd6);
const BLUE_DEEP = Color(0xffA8CBFD);
const BLUE_LIGHT = Color(0xffAED3EA);
const PURPLE = Color(0xffccc3fc);
const SIGNUP_LIGHT_RED = Color(0xffffc2a1);
const SIGNUP_RED = Color(0xffffb1bb);
const RED = Color(0xffF2A7B3);
const GREEN = Color(0xffc7e5b4);
const RED_LIGHT = Color(0xffFFC3A0);
const TEXT_BLACK = Color(0xFF353535);
const TEXT_BLACK_LIGHT = Color(0xFF34323D);

final enigmaBlack = Colors.white;
final enigmaBlue = new Color(0xFFE0E0E0);
final enigmaGreen = new Color(0xFFE0E0E0);
final enigmaWhite = Colors.white;
const IS_TOKEN_GENERATED = 'isTokenGenerated';
const NOTIFICATION_TOKENS = 'notificationTokens';
const PHOTO_URL = 'photoUrl';
const USERS = 'users';
const MESSAGES = 'messages';
const ANSWER_TRIES = 'answerTries';
const PASSCODE_TRIES = 'passcodeTries';
const ABOUT_ME = 'aboutMe';
const NICKNAME = 'nickname';
const TYPE = 'type';
const FROM = 'from';
const CHAT_FILENAME="chatFileName";
const TO = 'to';
const CONTENT = 'content';
const CHATS_WITH = 'chatsWith';
const CHAT_STATUS = 'chatStatus';
const LAST_SEEN = 'lastSeen';
const PHONE = 'phone';
const PASS="pass";
const Sex="sex";
const ID = 'id';
const BIRTHDAY="birthday";
const EMAIL="email";
const ANSWER = 'answer';
const QUESTION = 'question';
const PASSCODE = 'passcode';
const HIDDEN = 'hidden';
const LOCKED = 'locked';
const DELETE_UPTO = 'deleteUpto';
const TIMESTAMP = 'timestamp';
const LAST_ANSWERED = 'lastAnswered';
const LAST_ATTEMPT = 'lastAttempt';
const AUTHENTICATION_TYPE = 'authenticationType';
const CACHED_CONTACTS = 'cachedContacts';
const SAVED = 'saved';
const ALIAS_NAME = 'aliasName';
const ALIAS_AVATAR = 'aliasAvatar';
const PUBLIC_KEY = 'publicKey';
const PRIVATE_KEY = 'privateKey';
const PRIVACY_POLICY_URL =
    'https://amitjoki.github.io/Enigma/Privacy_Policy';
const COUNTRY_CODE = 'countryCode';
const WALLPAPER = 'wallpaper';
const CRC_SEPARATOR = '&';
const TRIES_THRESHOLD = 3;
const TIME_BASE = 2;
const POST="post";

const POST_CONTENT="postContent";
const POST_FILE_PATH="postFilePath";
const POST_IMAGE_URL="postImageUrl";
const POST_FILE_NAME="postFileName";
const POST_NICK_NAME="postNickName";
const POST_PHOTO_URL="postPhotoUrl";
const POST_PHONE="postPhone";
const POST_TIME="postTime";


//Colors for theme
const Color lightPrimary = Color(0xfffcfcff);
const Color darkPrimary = Colors.black;
const Color lightAccent = Colors.blue;
const Color darkAccent = Colors.blueAccent;
const Color lightBG = Color(0xfffcfcff);
const Color darkBG = Colors.black;
const Color badgeColor = Colors.red;

final EnigmaTheme = ThemeData(
  backgroundColor: lightBG,
  primaryColor: lightPrimary,
  accentColor:  lightAccent,
  cursorColor: lightAccent,
  scaffoldBackgroundColor: lightBG,
  appBarTheme: AppBarTheme(
    elevation: 0,
    textTheme: TextTheme(
      title: TextStyle(
        color: darkBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
  buttonColor: enigmaBlue,
  dialogBackgroundColor: Colors.white,
  primaryColorDark: Colors.white,
  indicatorColor: enigmaBlue.withOpacity(0.8),
  primarySwatch: Colors.blue,
  dialogTheme: DialogTheme(backgroundColor: Colors.white, elevation: 48.0),
  primaryColorBrightness: Brightness.dark,
  brightness: Brightness.dark,

);

enum ChatStatus { blocked, waiting, requested, accepted }
enum MessageType { text, image ,file}
enum AuthenticationType { passcode, biometric }
void unawaited(Future<void> future) {}
