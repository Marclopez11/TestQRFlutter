import 'package:flutter/material.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            LanguageDropdown(
                onLanguageChanged: (language) => _changeLanguage(context,
                    language)), // Pasa el context y el lenguaje seleccionado
          if (!showLanguageDropdown)
            Spacer(), // Añade un espacio flexible a la derecha si no se muestra el dropdown
        ],
      ),
    );
  }
}

class LanguageDropdown extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const LanguageDropdown({Key? key, required this.onLanguageChanged})
      : super(key: key);

  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language')?.toUpperCase() ?? 'ES';
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language.toUpperCase();
    });
    widget.onLanguageChanged(language.toLowerCase());
    _saveLanguage(language);
  }

  Future<void> _saveLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      onChanged: (String? newValue) {
        _changeLanguage(newValue!);
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

void _changeLanguage(BuildContext context, String language) {
  final apiService = ApiService();
  apiService.setLanguage(language);

  // Notificar el cambio de idioma a la página de inicio
  final homePage = HomePage.of(context);
  homePage?.reloadData();
}
