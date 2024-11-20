class CategoryForItems {
  final int tid;
  final String name;
  final Map<String, String> translations;
  final int? parentId;

  CategoryForItems({
    required this.tid,
    required this.name,
    required this.translations,
    this.parentId,
  });

  factory CategoryForItems.fromJson(Map<String, dynamic> json) {
    try {
      return CategoryForItems(
        tid: json['tid'][0]['value'],
        name: json['name'][0]['value'],
        parentId:
            json['parent'].isNotEmpty ? json['parent'][0]['target_id'] : null,
        translations: {
          'en': json['field_nom_en']?[0]?['value'] ?? json['name'][0]['value'],
          'es': json['field_nom_es']?[0]?['value'] ?? json['name'][0]['value'],
          'fr': json['field_nom_fr']?[0]?['value'] ?? json['name'][0]['value'],
          'de': json['field_nom_gr']?[0]?['value'] ?? json['name'][0]['value'],
          'ca': json['name'][0]['value'],
        },
      );
    } catch (e) {
      print('Error parsing category: $e');
      // Devolvemos una categoría con valores por defecto en caso de error
      return CategoryForItems(
        tid: json['tid']?[0]?['value'] ?? 0,
        name: json['name']?[0]?['value'] ?? 'Unknown Category',
        translations: {'ca': json['name']?[0]?['value'] ?? 'Unknown Category'},
        parentId: null,
      );
    }
  }

  String getTranslatedName(String language) {
    return translations[language] ?? translations['ca'] ?? name;
  }

  // Método para convertir la categoría a JSON para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'tid': [
        {'value': tid}
      ],
      'name': [
        {'value': name}
      ],
      'parent': parentId != null
          ? [
              {'target_id': parentId}
            ]
          : [],
      'field_nom_en': [
        {'value': translations['en'] ?? name}
      ],
      'field_nom_es': [
        {'value': translations['es'] ?? name}
      ],
      'field_nom_fr': [
        {'value': translations['fr'] ?? name}
      ],
      'field_nom_gr': [
        {'value': translations['de'] ?? name}
      ],
    };
  }
}
