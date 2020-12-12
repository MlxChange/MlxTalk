import 'package:Enigma/util/color_const.dart';
import 'package:Enigma/widgets/signup_arrow_button.dart';
import 'package:flutter/material.dart';


class SignupApbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  Function tap;
  SignupApbar({this.title,this.tap});
  @override
  Widget build(BuildContext context) {
    final double statusbarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: statusbarHeight),
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: FractionalOffset(0.5, 0.0), end: FractionalOffset(0.6, 0.8),
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.0, 0.9], colors: [YELLOW, BLUE],
      )),
      child: NavigationToolbar(
        leading: Align(
          alignment: Alignment(-0.5, 4),
          child: SignUpArrowButton(
            onTap: tap==null?() => Navigator.maybePop(context):tap,
            icon: IconData(
              0xe900,
              fontFamily: "Icons",
            ),
            iconSize: 9,
            height: 48,
            width: 48,
          ),
        ),
        centerMiddle: true,
        middle: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
