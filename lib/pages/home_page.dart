import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:testapp/pages/item_detail_page.dart';
// Add this import
import 'package:testapp/models/map_item.dart'; // Adjust the path as needed
import 'package:latlong2/latlong.dart';

// Elimina la importación de map_page.dart

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> items = [];
  List<String> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse(
        'https://jo3wdm44wdd7ij7hjauasqvc2i0fgzey.lambda-url.eu-central-1.on.aws/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        items = List<Map<String, dynamic>>.from(data);
        categories =
            items.map((item) => item['category'] as String).toSet().toList();
      });
    }
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = selectedCategory.isEmpty
        ? items
        : items.where((item) => item['category'] == selectedCategory).toList();

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
                leading: Image.network('https://picsum.photos/50'),
                title: Text(item['name']),
                subtitle: Text(item['category']),
                onTap: () {
                  final mapItem = MapItem(
                    id: item['id'].toString(),
                    title: item['name'],
                    description: item['description'],
                    position: LatLng(
                      item['coordinates']['latitude'],
                      item['coordinates']['longitude'],
                    ),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: mapItem),
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
