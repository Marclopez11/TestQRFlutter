import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaxonomyService {
  static final TaxonomyService _instance = TaxonomyService._internal();
  factory TaxonomyService() => _instance;
  TaxonomyService._internal();

  Future<Map<String, String>> getTaxonomyTerms(String vocabulary,
      {String language = 'ca'}) async {
    try {
      //print(
      //    'Getting taxonomy terms for $vocabulary in language $language'); // Debug log

      // Primero intentamos obtener del almacenamiento local
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${vocabulary}_$language';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        //print('Found cached data for $cacheKey'); // Debug log
        try {
          final List<dynamic> decodedData = json.decode(cachedData);
          final Map<String, String> terms = {};

          for (var term in decodedData) {
            final id = term['tid'][0]['value'].toString();
            final name = term['name'][0]['value'];
            terms[id] = name;
          }

          //print('Cached terms: $terms'); // Debug log
          return terms;
        } catch (e) {
          print('Error parsing cached data: $e');
          // Si hay error al parsear la caché, la eliminamos
          await prefs.remove(cacheKey);
        }
      }

      // Si no hay datos en caché o hubo error al parsearlos, hacemos la petición a la API
      print(
          'Fetching fresh data from API for $vocabulary in $language'); // Debug log
      final response = await http.get(
        Uri.parse(
            'https://felanitx.drupal.auroracities.com/${vocabulary}_$language'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Map<String, String> terms = {};

        for (var term in data) {
          final id = term['tid'][0]['value'].toString();
          final name = term['name'][0]['value'];
          terms[id] = name;
        }

        // Guardamos los datos originales en caché
        await prefs.setString(cacheKey, json.encode(data));
        //print('Saved new data to cache for $cacheKey'); // Debug log
        //print('Fresh terms: $terms'); // Debug log

        return terms;
      } else {
        throw Exception(
            'Failed to load taxonomy terms: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error getting taxonomy terms: $e');

      // Último intento de obtener datos en caché si hay un error
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = '${vocabulary}_$language';
        final cachedData = prefs.getString(cacheKey);

        if (cachedData != null) {
          final List<dynamic> decodedData = json.decode(cachedData);
          final Map<String, String> terms = {};

          for (var term in decodedData) {
            final id = term['tid'][0]['value'].toString();
            final name = term['name'][0]['value'];
            terms[id] = name;
          }

          print('Recovered terms from cache after error: $terms'); // Debug log
          return terms;
        }
      } catch (e) {
        print('Error getting cached taxonomy terms: $e');
      }

      return {};
    }
  }

  // Método para limpiar la caché cuando cambia el idioma
  Future<void> clearCache(String vocabulary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languages = ['ca', 'es', 'en', 'fr', 'de'];

      for (var language in languages) {
        final cacheKey = '${vocabulary}_$language';
        await prefs.remove(cacheKey);
        print('Cleared cache for $cacheKey'); // Debug log
      }
    } catch (e) {
      print('Error clearing taxonomy cache: $e');
    }
  }

  // Método para verificar el contenido de la caché
  Future<void> debugCache(String vocabulary, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${vocabulary}_$language';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        print('Cache content for $cacheKey:');
        print(cachedData);
      } else {
        print('No cache found for $cacheKey');
      }
    } catch (e) {
      print('Error debugging cache: $e');
    }
  }
}
