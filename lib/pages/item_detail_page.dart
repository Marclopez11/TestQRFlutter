import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_item.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

/// La classe `ItemDetailPage` és un `StatelessWidget` que representa la pàgina de detall d'un element del mapa.
class ItemDetailPage extends StatelessWidget {
  final MapItem item;

  const ItemDetailPage({Key? key, required this.item}) : super(key: key);

  void _openInMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${item.position.latitude},${item.position.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              item.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: Text('Error al cargar la imagen')),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(item.description),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 250, // Aumentamos la altura del mapa
                    child: FlutterMap(
                      options: MapOptions(
                        center: item.position,
                        zoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        PopupMarkerLayerWidget(
                          options: PopupMarkerLayerOptions(
                            markers: [
                              Marker(
                                point: item.position,
                                width: 40,
                                height: 40,
                                builder: (_) =>
                                    const Icon(Icons.location_on, size: 40),
                                anchorPos: AnchorPos.align(AnchorAlign.top),
                              ),
                            ],
                            popupDisplayOptions: PopupDisplayOptions(
                              builder: (BuildContext context, Marker marker) {
                                return Container(
                                  width: 120,
                                  margin: EdgeInsets.only(
                                      bottom:
                                          20), // Aumentamos el margen inferior
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(8.0)),
                                        child: Image.network(
                                          item.imageUrl,
                                          width: 120,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            SizedBox(height: 4.0),
                                            Text(
                                              item.categoryName,
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10.0,
                                              ),
                                            ),
                                            SizedBox(height: 8.0),
                                            Center(
                                              child: IconButton(
                                                onPressed: _openInMaps,
                                                icon: Icon(Icons.map,
                                                    color: Colors.green,
                                                    size: 24),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
