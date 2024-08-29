import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/map_item.dart';
import 'item_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<MapItem> _mapItems = [];
  List<MapItem> _filteredItems = [];
  List<String> _categories = ['All'];
  String? _selectedCategory;
  LatLng _centerPosition = LatLng(0, 0);
  double _zoomLevel = 5.0;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchMapItems();
  }

  Future<void> _fetchMapItems() async {
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
        _mapItems = data.map((item) {
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
        _filteredItems = _mapItems;
        _categories = ['All'] + categoryMap.values.toSet().toList();
        _centerPosition = _calculateCenterPosition();
        _zoomLevel = _calculateZoomLevel();
        _mapController.move(_centerPosition, _zoomLevel);
      });
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
      _filteredItems = _selectedCategory == null
          ? _mapItems
          : _mapItems
              .where((item) => item.categoryName == _selectedCategory)
              .toList();
      _centerPosition = _calculateCenterPosition();
      _zoomLevel = _calculateZoomLevel();
      _mapController.move(_centerPosition, _zoomLevel);
    });
  }

  LatLng _calculateCenterPosition() {
    if (_mapItems.isEmpty) {
      return LatLng(0, 0);
    }

    double minLatitude = _mapItems[0].position.latitude;
    double maxLatitude = _mapItems[0].position.latitude;
    double minLongitude = _mapItems[0].position.longitude;
    double maxLongitude = _mapItems[0].position.longitude;

    for (var item in _mapItems) {
      minLatitude = min(minLatitude, item.position.latitude);
      maxLatitude = max(maxLatitude, item.position.latitude);
      minLongitude = min(minLongitude, item.position.longitude);
      maxLongitude = max(maxLongitude, item.position.longitude);
    }

    double centerLatitude = (minLatitude + maxLatitude) / 2;
    double centerLongitude = (minLongitude + maxLongitude) / 2;

    return LatLng(centerLatitude, centerLongitude);
  }

  double _calculateZoomLevel() {
    if (_mapItems.isEmpty) {
      return 5;
    }

    double minLatitude = _mapItems[0].position.latitude;
    double maxLatitude = _mapItems[0].position.latitude;
    double minLongitude = _mapItems[0].position.longitude;
    double maxLongitude = _mapItems[0].position.longitude;

    for (var item in _mapItems) {
      minLatitude = min(minLatitude, item.position.latitude);
      maxLatitude = max(maxLatitude, item.position.latitude);
      minLongitude = min(minLongitude, item.position.longitude);
      maxLongitude = max(maxLongitude, item.position.longitude);
    }

    double latitudeDelta = maxLatitude - minLatitude;
    double longitudeDelta = maxLongitude - minLongitude;

    double zoomLevel = 5;

    if (latitudeDelta > 0 && longitudeDelta > 0) {
      double maxDelta = max(latitudeDelta, longitudeDelta);
      zoomLevel = 18 - log(maxDelta) / log(2);
    }

    return zoomLevel.clamp(3, 18);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => _filterByCategory(category),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        category == _selectedCategory ? Colors.blue : null,
                  ),
                  child: Text(category),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _centerPosition,
              zoom: _zoomLevel,
              minZoom: 3,
              maxZoom: 18,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _filteredItems.map((item) {
                  return Marker(
                    point: item.position,
                    builder: (ctx) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailPage(item: item),
                          ),
                        );
                      },
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
