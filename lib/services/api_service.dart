import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:felanitx/models/category_for_items.dart';

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
    'dificultat': {
      'ca': 'https://felanitx.drupal.auroracities.com/dificultat_ca',
      'es': 'https://felanitx.drupal.auroracities.com/dificultat_es',
      'en': 'https://felanitx.drupal.auroracities.com/dificultat_en',
      'fr': 'https://felanitx.drupal.auroracities.com/dificultat_fr',
      'de': 'https://felanitx.drupal.auroracities.com/dificultat_de',
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
            //print('Data fetched and saved successfully for $apiName in $language');
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

  Future<List<dynamic>> loadCachedData(String apiName, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${apiName}_$language';

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    return [];
  }

  Future<List<dynamic>> loadFreshData(String apiName, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${apiName}_$language';

    try {
      final url = _apiUrls[apiName]?[language];
      if (url == null) {
        return [];
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 10)); // Añadimos timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Guardar en caché
        await prefs.setString(cacheKey, json.encode(data));
        return data;
      } else {
        // Si hay error en la respuesta, intentamos devolver datos en caché
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          return json.decode(cachedData);
        }
        return [];
      }
    } catch (e) {
      print('Error in loadFreshData: $e');
      // Si hay error de conexión, intentamos devolver datos en caché
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      }
      return [];
    }
  }

  Future<List<dynamic>> loadData(String apiName, String language) async {
    try {
      // Primero intentamos obtener los datos de la caché
      final cachedData = await loadCachedData(apiName, language);
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Solo si no hay datos en caché, intentamos cargar datos frescos
      try {
        final freshData = await loadFreshData(apiName, language);
        return freshData;
      } catch (e) {
        print('Error loading fresh data: $e');
        // Si falla la carga de datos frescos, devolvemos los datos en caché
        // aunque estén vacíos
        return cachedData;
      }
    } catch (e) {
      print('Error in loadData: $e');
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

  Future<List<CategoryForItems>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('categories');

      // Primero intentamos usar los datos en caché
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData
            .map((json) => CategoryForItems.fromJson(json))
            .toList();
      }

      // Solo si no hay caché, intentamos hacer la petición
      try {
        final response = await http
            .get(
              Uri.parse('https://felanitx.drupal.auroracities.com/categoria'),
            )
            .timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          await prefs.setString('categories', json.encode(data));
          return data.map((json) => CategoryForItems.fromJson(json)).toList();
        }
      } catch (e) {
        print('Error getting fresh categories: $e');
      }

      // Si la petición falla, intentamos usar la caché una vez más
      final lastResortCache = prefs.getString('categories');
      if (lastResortCache != null) {
        final List<dynamic> decodedData = json.decode(lastResortCache);
        return decodedData
            .map((json) => CategoryForItems.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error in getCategories: $e');
    }
    return [];
  }

  String getCategoryName(
      List<CategoryForItems> categories, int categoryId, String language) {
    try {
      final category = categories.firstWhere((cat) => cat.tid == categoryId);
      return category.getTranslatedName(language);
    } catch (e) {
      return 'Category $categoryId';
    }
  }

  // Método para actualizar las categorías en segundo plano
  Future<void> updateCategoriesInBackground() async {
    try {
      final response = await http.get(
        Uri.parse('https://felanitx.drupal.auroracities.com/categoria'),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('categories', response.body);

        // Actualizamos la fecha de última actualización
        await prefs.setString(
            'categories_last_update', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error updating categories in background: $e');
    }
  }

  // Método para verificar si necesitamos actualizar las categorías
  Future<void> checkCategoriesUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('categories_last_update');

      if (lastUpdate == null) {
        await updateCategoriesInBackground();
        return;
      }

      final lastUpdateDate = DateTime.parse(lastUpdate);
      final now = DateTime.now();

      // Actualizamos si han pasado más de 24 horas
      if (now.difference(lastUpdateDate).inHours > 24) {
        await updateCategoriesInBackground();
      }
    } catch (e) {
      print('Error checking categories update: $e');
    }
  }
}
