import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/map_item.dart';
import 'item_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

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
  LatLng _centerPosition = LatLng(39.4697, 3.1483); // Coordenadas de Felanitx
  double _zoomLevel = 14.0; // Nivel de zoom fijo
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

        // Obtener las categorías únicas de los ítems
        _categories = ['All'] +
            _mapItems.map((item) => item.categoryName).toSet().toList();

        _filteredItems = _mapItems;
        _updateMapView(useAllItems: true);
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
      _updateMapView();
    });
  }

  void _updateMapView({bool useAllItems = false}) {
    List<MapItem> itemsToUse = useAllItems ? _mapItems : _filteredItems;

    if (itemsToUse.isNotEmpty) {
      double minLat = itemsToUse[0].position.latitude;
      double maxLat = itemsToUse[0].position.latitude;
      double minLng = itemsToUse[0].position.longitude;
      double maxLng = itemsToUse[0].position.longitude;

      for (var item in itemsToUse) {
        minLat = min(minLat, item.position.latitude);
        maxLat = max(maxLat, item.position.latitude);
        minLng = min(minLng, item.position.longitude);
        maxLng = max(maxLng, item.position.longitude);
      }

      double centerLat = (minLat + maxLat) / 2;
      double centerLng = (minLng + maxLng) / 2;
      LatLng centerPosition = LatLng(centerLat, centerLng);

      double zoomLevel = _calculateZoomLevel(minLat, maxLat, minLng, maxLng);

      _mapController.move(centerPosition, zoomLevel);
    }
  }

  double _calculateZoomLevel(
      double minLat, double maxLat, double minLng, double maxLng) {
    const int zoomMax = 18;
    const int zoomMin = 3;

    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = max(latDiff, lngDiff);

    // Ajustamos estos valores para obtener un zoom más alejado
    if (maxDiff < 0.01)
      return 14.0; // Zoom más alejado para diferencias pequeñas
    if (maxDiff > 1) return zoomMin.toDouble();

    // Ajustamos la fórmula para obtener un zoom más alejado en general
    double zoomLevel = 15 - log(maxDiff * 111) / log(2);
    return max(zoomLevel.clamp(zoomMin.toDouble(), zoomMax.toDouble()), 10.0);
  }

  String get _mapTileUrl {
    if (Platform.isIOS) {
      print('iOS map tile URL: https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    } else if (Platform.isAndroid) {
      return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    } else {
      return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _openInMaps(MapItem item) async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${item.position.latitude},${item.position.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${item.position.latitude},${item.position.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
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
                urlTemplate: _mapTileUrl,
                subdomains:
                    Platform.isAndroid ? ['0', '1', '2', '3'] : ['a', 'b', 'c'],
              ),
              PopupMarkerLayerWidget(
                options: PopupMarkerLayerOptions(
                  markers: _filteredItems.map((item) {
                    return Marker(
                      point: item.position,
                      width: 40,
                      height: 40,
                      builder: (_) => const Icon(Icons.location_on, size: 40),
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                    );
                  }).toList(),
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, Marker marker) {
                      final item = _filteredItems.firstWhere(
                        (item) => item.position == marker.point,
                      );
                      return Container(
                        width: 200,
                        child: Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(item.title),
                                subtitle: Text(item.categoryName),
                              ),
                              ButtonBar(
                                children: [
                                  TextButton(
                                    child: Text('Ver detalle'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ItemDetailPage(item: item),
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Abrir en mapa'),
                                    onPressed: () {
                                      _openInMaps(item);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
