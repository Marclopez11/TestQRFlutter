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
    final response = await http.get(Uri.parse(
        'https://jo3wdm44wdd7ij7hjauasqvc2i0fgzey.lambda-url.eu-central-1.on.aws/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _mapItems = data.map((item) {
          return MapItem(
            id: item['id'].toString(),
            title: item['name'],
            description: item['description'],
            position: LatLng(
              item['coordinates']['latitude'],
              item['coordinates']['longitude'],
            ),
          );
        }).toList();
        _centerPosition = _calculateCenterPosition();
        _zoomLevel = _calculateZoomLevel();
        _mapController.move(_centerPosition, _zoomLevel);
      });
    }
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
    return FlutterMap(
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
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: _mapItems.map((item) {
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
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
