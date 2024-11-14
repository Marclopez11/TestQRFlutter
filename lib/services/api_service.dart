import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const _updateInterval = Duration(seconds: 5);

  Timer? _timer;
  String _currentLanguage = 'es';

  final _languageController = StreamController<String>.broadcast();
  Stream<String> get languageStream => _languageController.stream;

  final Map<String, Map<String, String>> _apiUrls = {
    'banner': {
      'ca': 'https://felanitx.drupal.auroracities.com/banner_ca',
      'es': 'https://felanitx.drupal.auroracities.com/banner_es',
      'en': 'https://felanitx.drupal.auroracities.com/banner_en',
      'fr': 'https://felanitx.drupal.auroracities.com/banner_fr',
      'de': 'https://felanitx.drupal.auroracities.com/banner_de',
    },
    'categories': {
      'ca': 'https://felanitx.drupal.auroracities.com/apartats_ca',
      'es': 'https://felanitx.drupal.auroracities.com/apartats_es',
      'en': 'https://felanitx.drupal.auroracities.com/apartats_en',
      'fr': 'https://felanitx.drupal.auroracities.com/apartats_fr',
      'de': 'https://felanitx.drupal.auroracities.com/apartats_de',
    },
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
    'points_of_interest': {
      'ca': 'https://felanitx.drupal.auroracities.com/lloc_ca',
      'es': 'https://felanitx.drupal.auroracities.com/lloc_es',
      'en': 'https://felanitx.drupal.auroracities.com/lloc_en',
      'fr': 'https://felanitx.drupal.auroracities.com/lloc_fr',
      'de': 'https://felanitx.drupal.auroracities.com/lloc_de',
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

    // Opcional: Limpiar la caché de datos al cambiar el idioma
    final bannersKey = 'banner_$language';
    await prefs.remove(bannersKey);
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
    final cacheKey = '${apiName}_$language';

    try {
      final url = _apiUrls[apiName]?[language];
      if (url == null) {
        print('URL not found for $apiName in language $language');
        return [];
      }

      print('Fetching data from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Guardar en caché
        await prefs.setString(cacheKey, json.encode(data));
        return data;
      } else {
        print('Error fetching data: ${response.statusCode}');
        // Intentar usar datos en caché si hay error
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          return json.decode(cachedData);
        }
        return [];
      }
    } catch (e) {
      print('Error in loadData: $e');
      // Intentar usar datos en caché si hay error
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      }
      return [];
    }
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
