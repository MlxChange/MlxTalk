import 'package:Enigma/main.dart';


import 'package:Enigma/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home.dart';

//主界面，负责加载聊天界面，分享界面和个人设置界面
class MainScreen2 extends StatefulWidget {
  MainScreen2({Key key, this.mainUI}) : super(key: key);

  MainScreen mainUI;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen2> {
  PageController _pageController;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    //构建一个界面
    return Scaffold(
      //背景颜色
      backgroundColor: Colors.transparent,
      //内容是一个pageview，主要用来加载三个界面，类似Android中的viewpager
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,//页面控制器
        onPageChanged: onPageChanged,//当页面改变以后的监听事件
        children: <Widget>[
          //加载三个界面
          widget.mainUI,
          Home(),
          Settings(),
        ],
      ),
      bottomNavigationBar: Theme(//底部导航按钮
        data: Theme.of(context).copyWith(//主题
          // sets the background color of the `BottomNavigationBar`
          canvasColor: Theme.of(context).primaryColor,
          // sets the active color of the `BottomNavigationBar` if `Brightness` is light
          primaryColor: Theme.of(context).accentColor,
          textTheme: Theme.of(context).textTheme.copyWith(
                caption: TextStyle(color: Colors.grey[500]),
              ),
        ),
        child: BottomNavigationBar(//底部三个导航按钮
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.message,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.share,
              ),
              title: Container(
                height: 0.0,
                child: Text("分享"),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
              ),
              title: Container(
                height: 0.0,
                child: Text("我的"),
              ),
            ),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
      ),
    );
  }

  //页面跳转逻辑
  void navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  @override
  void initState() {
    super.initState();
    //沉浸式状态栏
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    //初始界面为聊天界面
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }
}
