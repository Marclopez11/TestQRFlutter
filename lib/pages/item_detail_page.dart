import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_item.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.black),
                onPressed: _shareContent,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 105,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.title,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                widget.item.averageRating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Image.network(
              'https://citapreviafelanitx.intricom.es/content/images/logoFelanitx.png',
              height: 40,
            ),
            centerTitle: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
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
                        if (widget.item.facebookUrl != null)
                          GestureDetector(
                            onTap: () => launch(widget.item.facebookUrl!),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.facebook,
                                  size: 30, color: Color(0xFF1877F2)),
                            ),
                          ),
                        if (widget.item.instagramUrl != null)
                          GestureDetector(
                            onTap: () => launch(widget.item.instagramUrl!),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.instagram,
                                  size: 30, color: Color(0xFFE4405F)),
                            ),
                          ),
                        if (widget.item.twitterUrl != null)
                          GestureDetector(
                            onTap: () => launch(widget.item.twitterUrl!),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.twitter,
                                  size: 30, color: Color(0xFF1DA1F2)),
                            ),
                          ),
                        if (widget.item.websiteUrl != null)
                          GestureDetector(
                            onTap: () => launch(widget.item.websiteUrl!),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.globe,
                                  size: 30, color: Colors.blue),
                            ),
                          ),
                        if (widget.item.whatsappNumber != null)
                          GestureDetector(
                            onTap: () => Share.share(
                              widget.item.whatsappNumber!,
                              subject: 'Mensaje de ${widget.item.title}',
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.whatsapp,
                                  size: 30, color: Color(0xFF25D366)),
                            ),
                          ),
                        if (widget.item.phoneNumber != null)
                          GestureDetector(
                            onTap: () =>
                                launch('tel:${widget.item.phoneNumber}'),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.phone,
                                  size: 30, color: Colors.green),
                            ),
                          ),
                        if (widget.item.email != null)
                          GestureDetector(
                            onTap: () => launch('mailto:${widget.item.email}'),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FaIcon(FontAwesomeIcons.envelope,
                                  size: 30, color: Colors.red),
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
                                            color:
                                                Colors.black.withOpacity(0.2),
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
                                            color:
                                                Theme.of(context).primaryColor,
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
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
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
            ]),
          ),
        ],
      ),
    );
  }
}
