import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:felanitx/services/api_service.dart';

class TaxonomyService {
  final ApiService _apiService = ApiService();
  Map<String, String> _categoryTerms = {};

  Future<Map<String, String>> getTaxonomyTerms(String taxonomy,
      {String? language}) async {
    try {
      // Caso especial para categorías
      if (taxonomy == 'categoria') {
        _categoryTerms = await _loadCategories();
        return _categoryTerms;
      }

      // Get current language if not provided
      language = language ?? await _apiService.getCurrentLanguage();

      // Primero intentamos obtener datos frescos
      try {
        final freshData = await _apiService.loadFreshData(taxonomy, language);
        if (freshData.isNotEmpty) {
          return _parseTerms(freshData);
        }
      } catch (e) {
        print('No se pudieron cargar datos frescos, usando caché: $e');
      }

      // Si no hay datos frescos, usamos la caché
      final cachedData = await _apiService.loadCachedData(taxonomy, language);
      return _parseTerms(cachedData);
    } catch (e) {
      print('Error loading taxonomy terms for $taxonomy: $e');
      return {};
    }
  }

  Future<Map<String, String>> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('categories');

      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        return _parseCategoryTerms(decodedData);
      }

      final response = await http.get(
        Uri.parse('https://felanitx.drupal.auroracities.com/categoria'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await prefs.setString('categories', json.encode(data));
        return _parseCategoryTerms(data);
      }

      return {};
    } catch (e) {
      print('Error loading categories: $e');
      return {};
    }
  }

  Map<String, String> _parseCategoryTerms(List<dynamic> data) {
    Map<String, String> terms = {};
    for (var category in data) {
      final id = category['tid']?[0]?['value']?.toString();
      final nameCa = category['name_ca']?[0]?['value']?.toString();
      final nameEs = category['name_es']?[0]?['value']?.toString();
      final nameEn = category['name_en']?[0]?['value']?.toString();
      final nameFr = category['name_fr']?[0]?['value']?.toString();
      final nameDe = category['name_de']?[0]?['value']?.toString();

      if (id != null) {
        // Guardamos todas las traducciones
        terms['${id}_ca'] = nameCa ?? '';
        terms['${id}_es'] = nameEs ?? '';
        terms['${id}_en'] = nameEn ?? '';
        terms['${id}_fr'] = nameFr ?? '';
        terms['${id}_de'] = nameDe ?? '';
      }
    }
    return terms;
  }

  Map<String, String> _parseTerms(List<dynamic> data) {
    Map<String, String> terms = {};
    for (var term in data) {
      final id = term['tid']?[0]?['value']?.toString();
      final name = term['name']?[0]?['value']?.toString();

      if (id != null && name != null) {
        terms[id] = name;
      }
    }
    return terms;
  }

  String getCategoryName(String id, String language) {
    if (_categoryTerms.isEmpty) {
      // Si las categorías no están cargadas, las cargamos
      _loadCategories().then((terms) {
        _categoryTerms = terms;
      });
      return id; // Devolvemos el ID mientras se cargan
    }
    return _categoryTerms['${id}_$language'] ?? id;
  }
}
