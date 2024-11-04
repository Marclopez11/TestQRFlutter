import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _apiUrls = {
    'categories': {
      'ca': 'https://felanitx.drupal.auroracities.com/apartats_ca',
      'es': 'https://felanitx.drupal.auroracities.com/apartats_es',
      'en': 'https://felanitx.drupal.auroracities.com/apartats_en',
      'fr': 'https://felanitx.drupal.auroracities.com/apartats_fr',
      'de': 'https://felanitx.drupal.auroracities.com/apartats_de',
    },
    /*'otherApi1': {
      'ca': 'https://example.com/api1_ca',
      'es': 'https://example.com/api1_es',
      'en': 'https://example.com/api1_en',
      'fr': 'https://example.com/api1_fr',
      'de': 'https://example.com/api1_de',
    },
    'otherApi2': {
      'ca': 'https://example.com/api2_ca',
      'es': 'https://example.com/api2_es',
      'en': 'https://example.com/api2_en',
      'fr': 'https://example.com/api2_fr',
      'de': 'https://example.com/api2_de',
    },*/
  };

  static const _updateInterval = Duration(minutes: 1);

  Timer? _timer;
  String _currentLanguage = 'ca';

  void startService() {
    _loadLanguage();
    _timer = Timer.periodic(_updateInterval, (_) => _fetchData());
  }

  void stopService() {
    _timer?.cancel();
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    _saveLanguage();
    _fetchData();
  }

  Future<void> _fetchData() async {
    for (var apiName in _apiUrls.keys) {
      for (var language in _apiUrls[apiName]!.keys) {
        final url = _apiUrls[apiName]![language];
        try {
          final response = await http.get(Uri.parse(url!));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            await _saveData(apiName, language, data);
            print(
                'Data fetched and saved successfully for $apiName in $language');
          } else {
            print(
                'Failed to fetch data for $apiName in $language. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error fetching data for $apiName in $language: $e');
        }
      }
    }
  }

  Future<void> _saveData(
      String apiName, String language, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${apiName}_$language', json.encode(data));
  }

  Future<List<dynamic>> loadData(String apiName, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('${apiName}_$language');
    if (dataString != null) {
      return json.decode(dataString);
    }
    return [];
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language');
    if (language != null) {
      _currentLanguage = language;
    }
  }

  Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'ca';
  }
}
