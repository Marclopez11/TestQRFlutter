import 'package:flutter/material.dart';
import 'header.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({
    Key? key,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Header(),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
