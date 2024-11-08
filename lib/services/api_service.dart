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
    'agenda': {
      'ca': 'https://felanitx.drupal.auroracities.com/agenda_ca',
      'es': 'https://felanitx.drupal.auroracities.com/agenda_es',
      'en': 'https://felanitx.drupal.auroracities.com/agenda_en',
      'fr': 'https://felanitx.drupal.auroracities.com/agenda_fr',
      'de': 'https://felanitx.drupal.auroracities.com/agenda_de',
    },
    'population_centers': {
      'ca': 'https://felanitx.drupal.auroracities.com/nuclis_ca',
      'es': 'https://felanitx.drupal.auroracities.com/nuclis_es',
      'en': 'https://felanitx.drupal.auroracities.com/nuclis_en',
      'fr': 'https://felanitx.drupal.auroracities.com/nuclis_fr',
      'de': 'https://felanitx.drupal.auroracities.com/nuclis_de',
    },
    'points_of_interest': {
      'ca': 'https://felanitx.drupal.auroracities.com/punts_interes_ca',
      'es': 'https://felanitx.drupal.auroracities.com/punts_interes_es',
      'en': 'https://felanitx.drupal.auroracities.com/punts_interes_en',
      'fr': 'https://felanitx.drupal.auroracities.com/punts_interes_fr',
      'de': 'https://felanitx.drupal.auroracities.com/punts_interes_de',
    },
    'routes': {
      'ca': 'https://felanitx.drupal.auroracities.com/ruta_ca',
      'es': 'https://felanitx.drupal.auroracities.com/ruta_es',
      'en': 'https://felanitx.drupal.auroracities.com/ruta_en',
      'fr': 'https://felanitx.drupal.auroracities.com/ruta_fr',
      'de': 'https://felanitx.drupal.auroracities.com/ruta_de',
    },
    'accommodation': {
      'ca': 'https://felanitx.drupal.auroracities.com/allotjament_ca',
      'es': 'https://felanitx.drupal.auroracities.com/allotjament_es',
      'en': 'https://felanitx.drupal.auroracities.com/allotjament_en',
      'fr': 'https://felanitx.drupal.auroracities.com/allotjament_fr',
      'de': 'https://felanitx.drupal.auroracities.com/allotjament_de',
    },
    'restaurants': {
      'ca': 'https://felanitx.drupal.auroracities.com/restaurants_ca',
      'es': 'https://felanitx.drupal.auroracities.com/restaurants_es',
      'en': 'https://felanitx.drupal.auroracities.com/restaurants_en',
      'fr': 'https://felanitx.drupal.auroracities.com/restaurants_fr',
      'de': 'https://felanitx.drupal.auroracities.com/restaurants_de',
    },
    'dificultat': {
      'ca': 'https://felanitx.drupal.auroracities.com/dificultat_ca',
      'es': 'https://felanitx.drupal.auroracities.com/dificultat_es',
      'en': 'https://felanitx.drupal.auroracities.com/dificultat_en',
      'fr': 'https://felanitx.drupal.auroracities.com/dificultat_fr',
      'de': 'https://felanitx.drupal.auroracities.com/dificultat_de',
    },
    'tipuscircuit': {
      'ca': 'https://felanitx.drupal.auroracities.com/tipuscircuit_ca',
      'es': 'https://felanitx.drupal.auroracities.com/tipuscircuit_es',
      'en': 'https://felanitx.drupal.auroracities.com/tipuscircuit_en',
      'fr': 'https://felanitx.drupal.auroracities.com/tipuscircuit_fr',
      'de': 'https://felanitx.drupal.auroracities.com/tipuscircuit_de',
    },
    'tipusruta': {
      'ca': 'https://felanitx.drupal.auroracities.com/tipusruta_ca',
      'es': 'https://felanitx.drupal.auroracities.com/tipusruta_es',
      'en': 'https://felanitx.drupal.auroracities.com/tipusruta_en',
      'fr': 'https://felanitx.drupal.auroracities.com/tipusruta_fr',
      'de': 'https://felanitx.drupal.auroracities.com/tipusruta_de',
    },
  };

  static const _updateInterval = Duration(minutes: 1);

  Timer? _timer;
  String _currentLanguage = 'ca';

  final _languageController = StreamController<String>.broadcast();
  Stream<String> get languageStream => _languageController.stream;

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