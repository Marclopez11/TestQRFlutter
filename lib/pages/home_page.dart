import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:testapp/pages/item_detail_page.dart';
import 'package:testapp/models/map_item.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MapItem> items = [];
  List<String> categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final response = await http
        .get(Uri.parse('https://felanitx.drupal.auroracities.com/lloc'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Fetch categories
      final categoriesResponse = await http.get(
          Uri.parse('https://felanitx.drupal.auroracities.com/categories'));
      final List<dynamic> categoriesData = json.decode(categoriesResponse.body);

      Map<int, String> categoryMap = {};
      for (var category in categoriesData) {
        int tid = category['tid'][0]['value'];
        String name = category['name'][0]['value'];
        categoryMap[tid] = name;
      }

      setState(() {
        items = data.map((item) {
          final location = item['field_place_location'][0];
          final image = item['field_place_main_image'][0];
          final categoryId = item['field_place_categoria'][0]['target_id'];
          return MapItem(
            id: item['nid'][0]['value'].toString(),
            title: item['title'][0]['value'],
            description: item['field_place_description'][0]['value'],
            position: LatLng(
              double.parse(location['lat'].toString()),
              double.parse(location['lng'].toString()),
            ),
            imageUrl: image['url'],
            categoryId: categoryId,
            categoryName: categoryMap[categoryId] ?? 'Unknown',
          );
        }).toList();

        categories = ['All'] + categoryMap.values.toSet().toList();
      });
    }
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category == 'All' ? null : category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = selectedCategory == null
        ? items
        : items.where((item) => item.categoryName == selectedCategory).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var category in categories)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => filterByCategory(category),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          category == selectedCategory ? Colors.blue : null,
                    ),
                    child: Text(category),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return ListTile(
                leading: Container(
                  width: 60, // Ancho fijo para todas las imágenes
                  height: 60, // Alto fijo para todas las imágenes
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(item.imageUrl),
                    ),
                  ),
                ),
                title: Text(item.title),
                subtitle: Text(item.categoryName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
