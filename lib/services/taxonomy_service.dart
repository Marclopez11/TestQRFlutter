import 'package:felanitx/services/api_service.dart';

class TaxonomyService {
  final ApiService _apiService = ApiService();

  Future<Map<String, String>> getTaxonomyTerms(String vocabulary) async {
    final language = await _apiService.getCurrentLanguage();
    final data = await _apiService.loadData(vocabulary, language);
    return Map.fromEntries(
      data.map((item) => MapEntry(
          item['tid'][0]['value'].toString(), item['name'][0]['value'])),
    );
  }
}
