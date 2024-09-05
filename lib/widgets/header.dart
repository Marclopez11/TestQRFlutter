import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context)
          .scaffoldBackgroundColor, // Usar el color de fondo de la aplicación
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Image.network(
          'https://citapreviafelanitx.intricom.es/content/images/logoFelanitx.png',
          height: 40,
        ),
      ),
    );
  }
}
