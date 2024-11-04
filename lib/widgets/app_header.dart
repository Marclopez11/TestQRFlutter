import 'package:flutter/material.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:felanitx/pages/map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppHeader extends StatelessWidget {
  final bool showLanguageDropdown;

  const AppHeader({Key? key, this.showLanguageDropdown = true})
      : super(key: key);

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
          if (showLanguageDropdown) LanguageDropdown(),
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
    final apiService = ApiService();
    apiService.setLanguage(language);
    setState(() {
      _selectedLanguage = language.toUpperCase();
    });

    // Notificar el cambio de idioma a todas las páginas
    _notifyLanguageChange(context, language);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      onChanged: (String? newValue) {
        _changeLanguage(newValue!.toLowerCase());
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

void _notifyLanguageChange(BuildContext context, String language) {
  final homePage = HomePage.of(context);
  homePage?.reloadData();

  final mapPage = MapPage.of(context);
  mapPage?.reloadData();
}
