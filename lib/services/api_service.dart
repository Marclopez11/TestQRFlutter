import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const _updateInterval = Duration(minutes: 1);

  Timer? _timer;
  String _currentLanguage = 'es';

  final _languageController = StreamController<String>.broadcast();
  Stream<String> get languageStream => _languageController.stream;

  final Map<String, Map<String, String>> _apiUrls = {
    'agenda': {
      'ca': 'https://felanitx.drupal.auroracities.com/agenda_ca',
      'es': 'https://felanitx.drupal.auroracities.com/agenda_es',
      'en': 'https://felanitx.drupal.auroracities.com/agenda_en',
      'fr': 'https://felanitx.drupal.auroracities.com/agenda_fr',
      'de': 'https://felanitx.drupal.auroracities.com/agenda_de',
    },
    'poblacio': {
      'ca': 'https://felanitx.drupal.auroracities.com/poblacio_ca',
      'es': 'https://felanitx.drupal.auroracities.com/poblacio_es',
      'en': 'https://felanitx.drupal.auroracities.com/poblacio_en',
      'fr': 'https://felanitx.drupal.auroracities.com/poblacio_fr',
      'de': 'https://felanitx.drupal.auroracities.com/poblacio_de',
    },
    'rutes': {
      'ca': 'https://felanitx.drupal.auroracities.com/ruta_ca',
      'es': 'https://felanitx.drupal.auroracities.com/ruta_es',
      'en': 'https://felanitx.drupal.auroracities.com/ruta_en',
      'fr': 'https://felanitx.drupal.auroracities.com/ruta_fr',
      'de': 'https://felanitx.drupal.auroracities.com/ruta_de',
    },
    'hotel': {
      'ca': 'https://felanitx.drupal.auroracities.com/hotel_ca',
      'es': 'https://felanitx.drupal.auroracities.com/hotel_es',
      'en': 'https://felanitx.drupal.auroracities.com/hotel_en',
      'fr': 'https://felanitx.drupal.auroracities.com/hotel_fr',
      'de': 'https://felanitx.drupal.auroracities.com/hotel_de',
    },
    'tipushotel': {
      'ca': 'https://felanitx.drupal.auroracities.com/tipushotel_ca',
      'es': 'https://felanitx.drupal.auroracities.com/tipushotel_es',
      'en': 'https://felanitx.drupal.auroracities.com/tipushotel_en',
      'fr': 'https://felanitx.drupal.auroracities.com/tipushotel_fr',
      'de': 'https://felanitx.drupal.auroracities.com/tipushotel_de',
    },
    'serveishotel': {
      'ca': 'https://felanitx.drupal.auroracities.com/serveishotel_ca',
      'es': 'https://felanitx.drupal.auroracities.com/serveishotel_es',
      'en': 'https://felanitx.drupal.auroracities.com/serveishotel_en',
      'fr': 'https://felanitx.drupal.auroracities.com/serveishotel_fr',
      'de': 'https://felanitx.drupal.auroracities.com/serveishotel_de',
    },
  };

  void startService() {
    _loadLanguage();
    _timer = Timer.periodic(_updateInterval, (_) => _fetchData());
  }

  void stopService() {
    _timer?.cancel();
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    _currentLanguage = language;
    _languageController.add(language);
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
    final language = prefs.getString('language');
    if (language != null) {
      _currentLanguage = language;
    }
    return _currentLanguage;
  }
}
