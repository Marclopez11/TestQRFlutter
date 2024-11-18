import 'package:flutter/material.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:felanitx/pages/map_page.dart';

class AppHeader extends StatelessWidget {
  final bool showLanguageDropdown;
  final String currentLanguage;

  const AppHeader({
    Key? key,
    this.showLanguageDropdown = true,
    required this.currentLanguage,
  }) : super(key: key);

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
            LanguageDropdown(currentLanguage: currentLanguage),
          if (!showLanguageDropdown) Spacer(),
        ],
      ),
    );
  }
}

class LanguageDropdown extends StatefulWidget {
  final String currentLanguage;

  const LanguageDropdown({
    Key? key,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage.toUpperCase();
  }

  @override
  void didUpdateWidget(LanguageDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLanguage != widget.currentLanguage) {
      setState(() {
        _selectedLanguage = widget.currentLanguage.toUpperCase();
      });
    }
  }

  void _changeLanguage(String language) async {
    final apiService = ApiService();
    await apiService.setLanguage(language);
    setState(() {
      _selectedLanguage = language.toUpperCase();
    });

    if (mounted) {
      final homePage = HomePage.of(context);
      homePage?.reloadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      onChanged: (String? newValue) {
        if (newValue != null) {
          _changeLanguage(newValue.toLowerCase());
        }
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
