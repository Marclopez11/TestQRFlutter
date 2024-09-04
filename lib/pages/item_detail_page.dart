import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_item.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:share_plus/share_plus.dart';

/// La classe `ItemDetailPage` és un `StatelessWidget` que representa la pàgina de detall d'un element del mapa.
class ItemDetailPage extends StatefulWidget {
  final MapItem item;

  const ItemDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailPageState createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  double _rating = 0;

  void _openInMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.item.position.latitude},${widget.item.position.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  void _shareContent() {
    Share.share(
      'Mira este lugar interesante: ${widget.item.title}\n\n${widget.item.description}\n\nhttps://www.google.com/maps/dir/?api=1&destination=${widget.item.position.latitude},${widget.item.position.longitude}',
      subject: widget.item.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.item.imageUrl,
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
                    widget.item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(widget.item.description),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            center: widget.item.position,
                            zoom: 15.0,
                            interactiveFlags: InteractiveFlag
                                .none, // Deshabilita la interacción con el mapa
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
                                    point: widget.item.position,
                                    width: 40,
                                    height: 40,
                                    builder: (_) =>
                                        const Icon(Icons.location_on, size: 40),
                                    anchorPos: AnchorPos.align(AnchorAlign.top),
                                  ),
                                ],
                                popupDisplayOptions: PopupDisplayOptions(
                                  builder:
                                      (BuildContext context, Marker marker) {
                                    return Container(
                                      width: 120,
                                      margin: EdgeInsets.only(
                                          bottom:
                                              20), // Aumentamos el margen inferior
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                                              widget.item.imageUrl,
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
                                                  widget.item.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                                SizedBox(height: 4.0),
                                                Text(
                                                  widget.item.categoryName,
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
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton(
                            onPressed: _shareContent,
                            child: Icon(Icons.share),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deja tu comentario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Comentario',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu comentario';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Valoración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 1; i <= 5; i++)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rating = i.toDouble();
                                    });
                                  },
                                  child: Icon(
                                    i <= _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Aquí puedes enviar el comentario y la valoración a tu backend o realizar alguna acción
                                  print('Nombre: ${_nameController.text}');
                                  print(
                                      'Comentario: ${_commentController.text}');
                                  print('Valoración: $_rating');
                                  _nameController.clear();
                                  _commentController.clear();
                                  setState(() {
                                    _rating = 0;
                                  });
                                }
                              },
                              child: Text('Enviar comentario'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
