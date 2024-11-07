import 'package:flutter/material.dart';
import 'package:felanitx/services/api_service.dart';

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
          if (showLanguageDropdown) LanguageDropdown(),
          if (!showLanguageDropdown) Spacer(),
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
  String? _selectedLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    setState(() {
      _selectedLanguage = language.toUpperCase();
      _isLoading = false;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language.toUpperCase();
    });
    ApiService().setLanguage(language.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SizedBox(width: 24, height: 24)
        : DropdownButton<String>(
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
