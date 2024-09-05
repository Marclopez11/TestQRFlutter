import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:testapp/pages/item_detail_page.dart';
import 'package:testapp/models/map_item.dart';
import 'package:latlong2/latlong.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/app_scaffold.dart'; // Importa el widget AppScaffold

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MapItem> items = [];
  List<String> categories = [];
  List<MapItem> featuredItems = [];
  int _currentCarouselIndex = 0;

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

        // Obtener las categorías únicas de los ítems
        categories =
            ['All'] + items.map((item) => item.categoryName).toSet().toList();

        // Select some items as featured (you might want to add a 'featured' field to your API)
        featuredItems = items.take(5).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedSlider(),
            SizedBox(height: 20),
            for (var category in categories.where((c) => c != 'All'))
              _buildCategorySection(category),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSlider() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 350.0,
            autoPlay: true,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: featuredItems.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(item: item),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8)
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.categoryName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: featuredItems.asMap().entries.map((entry) {
              return Container(
                width: 10.0,
                height: 10.0,
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(
                        _currentCarouselIndex == entry.key ? 0.9 : 0.4,
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryItems =
        items.where((item) => item.categoryName == category).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  margin: EdgeInsets.only(left: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(15)),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              item.categoryName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
