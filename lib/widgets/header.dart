import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final bool showLanguageDropdown;

  const Header({Key? key, this.showLanguageDropdown = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo_felanitx.png',
            height: 40,
          ),
          if (showLanguageDropdown)
            LanguageDropdown(), // Utiliza el widget LanguageDropdown
          if (!showLanguageDropdown)
            Spacer(), // Añade un espacio flexible a la derecha si no se muestra el dropdown
        ],
      ),
    );
  }
}

class LanguageDropdown extends StatefulWidget {
  const LanguageDropdown({Key? key}) : super(key: key);

  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  String _selectedLanguage = 'ES';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      onChanged: (String? newValue) {
        setState(() {
          _selectedLanguage = newValue!;
        });
      },
      items: <String>['ES', 'EN', 'CA', 'DE', 'FR'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      underline: Container(),
      icon: Icon(Icons.arrow_drop_down),
    );
  }
}
