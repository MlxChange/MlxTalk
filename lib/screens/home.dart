import 'package:Enigma/screens/feed_five_page.dart';
import 'package:Enigma/util/SizeUtil.dart';
import 'package:Enigma/utils.dart';
import 'package:Enigma/widgets/post_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

import '../const.dart';

//分享界面
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //是否启用了搜索
  bool isSearch = false;
  //搜索的内容控制器
  TextEditingController searchController = TextEditingController();
  //默认的搜索时间
  String dropdownValue = "过去一小时";
  //是否启用了时间选择按钮
  bool isTimeSelect = false;
  //是否启动了时间搜索
  bool isTimeSearch = false;

  _buildList(BuildContext contxt, List<DocumentSnapshot> snapshot) {
    print(snapshot.length);
  }

  //获取最新的分享信息
  Stream<QuerySnapshot> getdata() {
    /*
      因为是Stream，所以可以实时的从firebase的数据库中同步信息
      首先是创建一个从firebase中读取信息的输入流，然后根据是否启用了搜索和时间选择来构建
    */

    var stream1 = Firestore.instance
        .collection(POST)
        .orderBy(POST_TIME, descending: true)
        .snapshots();
    if (isSearch && searchController.text.isNotEmpty) {
      stream1 = Firestore.instance
          .collection(POST)
          .where(POST_NICK_NAME, isEqualTo: searchController.text.trim())
          .orderBy(POST_TIME, descending: true)
          .snapshots();
    }
    if (isTimeSelect && isTimeSearch) {
      var time = 0;
      switch (dropdownValue) {
        case "过去一小时":
          {
            time = 60 * 60 * 1000;
            break;
          }
        case "过去一天":
          {
            time = 60 * 60 * 1000 * 24;
            break;
          }
        case "过去一周":
          {
            time = 60 * 60 * 1000 * 24 * 7;
            break;
          }
        case "过去一个月":
          {
            time = 60 * 60 * 1000 * 24 * 30;
            break;
          }
        case "过去一年":
          {
            time = 60 * 60 * 1000 * 24 * 365;
            break;
          }
      }
      if(isSearch && searchController.text.isNotEmpty){
        stream1 = Firestore.instance
            .collection(POST)
            .where(POST_NICK_NAME, isEqualTo: searchController.text.trim())
            .where(POST_TIME,
            isGreaterThanOrEqualTo:
            DateTime.now().millisecondsSinceEpoch - time)
            .orderBy(POST_TIME, descending: true)
            .snapshots();
      }else{
        stream1 = Firestore.instance
            .collection(POST)
            .where(POST_TIME,
            isGreaterThanOrEqualTo:
            DateTime.now().millisecondsSinceEpoch - time)
            .orderBy(POST_TIME, descending: true)
            .snapshots();
      }

    }

    return stream1;
  }

  //初始化状态，并且初始化搜索选择器
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchController.addListener(() {
      if (searchController.text.isEmpty) {
        this.setState(() {
          isSearch = false;
        });
      }
    });
  }

  //构建界面
  @override
  Widget build(BuildContext context) {
    SizeUtil.size = MediaQuery.of(context).size;//获取手机实际的大小
    //创建一个最中间的listview，用于填充数据和显示数据
    var home = StreamBuilder<QuerySnapshot>(
      stream: getdata(), //获取数据
      builder: (context, snapshot) {
        //如果没有数据就显示无数据
        if (!snapshot.hasData) {
          if (isSearch) {
            print("isserch:$isSearch");
            Enigma.toast("没有查询到结果哦");
          }
          return Container();
        }
        return Scaffold(//构建Listview并填充数据
          body: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (BuildContext context, int index) {
              var post = snapshot.data.documents[index];
              return PostItem(
                name: post.data[POST_NICK_NAME],
                avatar: post.data[POST_PHOTO_URL],
                content: post.data[POST_CONTENT],
                time: TimelineUtil.format(post.data[POST_TIME]),
                img: post.data[POST_IMAGE_URL],
                fileName: post.data[POST_FILE_NAME],
                filePath: post.data[POST_FILE_PATH],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(//添加分享的按钮，点击后进入分享界面
            heroTag: "btn1",
            child: Icon(
              Icons.add,
            ),
            onPressed: () {//点击事件
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FeedFivePage()));
            },
          ),
        );
      },
    );

    //构建搜索栏
    var searchBar = Container(
      width: 300,
      child: DropdownButton<String>(
        value: dropdownValue,
        isExpanded: true,
        icon: Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        hint: Text("请选择时间范围"),
        style: TextStyle(fontSize: 20, color: Colors.deepPurple),
        onChanged: (String newValue) {
          setState(() {
            isTimeSearch = true;
            dropdownValue = newValue;
          });
        },
        items: <String>[
          '过去一小时',
          '过去一天',
          '过去一周',
          '过去一个月',
          '过去一年',
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );

    //构建真正的界面，并且把搜索栏和列表放在一起
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onSubmitted: (value) {
            this.setState(() {
              isSearch = true;
            });
          },
          decoration: InputDecoration.collapsed(
            hintText: 'Search',
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.filter_list,
            ),
            onPressed: () {
              this.setState(() {
                if (isTimeSelect) {
                  isTimeSearch = false;
                }
                isTimeSelect = !isTimeSelect;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          isTimeSelect
              ? searchBar
              : SizedBox(
                  height: 0,
                ),
          Expanded(
            child: home,
          )
        ],
      ),
    );
  }
}
