import 'dart:io';
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
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?q=${widget.item.position.latitude},${widget.item.position.longitude}'
        : 'geo:${widget.item.position.latitude},${widget.item.position.longitude}?q=${widget.item.position.latitude},${widget.item.position.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir la aplicación de mapas'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _shareContent() {
    Share.share(
      'Mira este lugar interesante: ${widget.item.title}\n\nhttps://www.google.com/maps/dir/?api=1&destination=${widget.item.position.latitude},${widget.item.position.longitude}',
      subject: widget.item.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.title,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _shareContent,
            icon: Icon(Icons.share, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.item.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.categoryName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.item.description,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => launch(
                            'https://www.instagram.com/your_instagram_profile'),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/1200px-Instagram_logo_2016.svg.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => launch(
                            'https://www.linkedin.com/in/your_linkedin_profile'),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/LinkedIn_logo_initials.png/640px-LinkedIn_logo_initials.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => launch(
                            'https://www.facebook.com/your_facebook_profile'),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/1200px-Facebook_Logo_%282019%29.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 15),
                      GestureDetector(
                        onTap: () =>
                            launch('https://twitter.com/your_twitter_profile'),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Logo_of_Twitter.svg/512px-Logo_of_Twitter.svg.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => launch(
                            'https://www.youtube.com/your_youtube_channel'),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/1280px-YouTube_full-color_icon_%282017%29.svg.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        center: widget.item.position,
                        zoom: 15.0,
                        interactiveFlags: InteractiveFlag.none,
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
                                builder: (_) => GestureDetector(
                                  onTap: _openInMaps,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                ),
                                anchorPos: AnchorPos.align(AnchorAlign.top),
                              ),
                            ],
                            popupDisplayOptions: PopupDisplayOptions(
                              builder: (BuildContext context, Marker marker) {
                                return GestureDetector(
                                  onTap: _openInMaps,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          color: Theme.of(context).primaryColor,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Abrir en Maps',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
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
                  SizedBox(height: 20),
                  Text(
                    'Comentarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          SizedBox(height: 10),
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
                          SizedBox(height: 10),
                          Text(
                            'Valoración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
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
                          SizedBox(height: 20),
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
                                backgroundColor: Theme.of(context).primaryColor,
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
