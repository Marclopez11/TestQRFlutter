import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Image.asset(
          'assets/images/logo_felanitx.png',
          height: 40,
        ),
      ),
    );
  }
}
