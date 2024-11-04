import 'package:flutter/material.dart';
import 'header.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showLanguageDropdown;

  const AppScaffold({
    Key? key,
    required this.body,
    this.showLanguageDropdown = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Header(showLanguageDropdown: showLanguageDropdown),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
