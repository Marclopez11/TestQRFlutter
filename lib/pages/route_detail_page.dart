import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route.dart';
import 'package:felanitx/services/taxonomy_service.dart';
import 'package:felanitx/main.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteModel route;

  const RouteDetailPage({Key? key, required this.route}) : super(key: key);

  @override
  _RouteDetailPageState createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  Map<String, String> _difficultyTerms = {};
  Map<String, String> _circuitTypeTerms = {};
  Map<String, String> _routeTypeTerms = {};

  @override
  void initState() {
    super.initState();
    _loadTaxonomyTerms();
  }

  Future<void> _loadTaxonomyTerms() async {
    final taxonomyService = TaxonomyService();
    _difficultyTerms = await taxonomyService.getTaxonomyTerms('dificultat');
    _circuitTypeTerms = await taxonomyService.getTaxonomyTerms('tipuscircuit');
    _routeTypeTerms = await taxonomyService.getTaxonomyTerms('tipusruta');
    setState(() {}); // Trigger a rebuild after loading the terms
  }

  void _openInMaps() async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${widget.route.location.latitude},${widget.route.location.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${widget.route.location.latitude},${widget.route.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
        title: Image.asset(
          'assets/images/logo_felanitx.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Image.network(
              widget.route.mainImage ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.route.description,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoItem(
                          Icons.trending_up,
                          '${widget.route.positiveElevation.toStringAsFixed(0)}m',
                          Colors.green,
                        ),
                        _buildInfoItem(
                          Icons.trending_down,
                          '${widget.route.negativeElevation.toStringAsFixed(0)}m',
                          Colors.red,
                        ),
                        _buildInfoItem(
                          Icons.timer,
                          '${widget.route.hours}h ${widget.route.minutes}min',
                          Colors.blue,
                        ),
                        _buildInfoItem(
                          Icons.route,
                          '${widget.route.distance.toStringAsFixed(2)} km',
                          Colors.orange,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(
                          _difficultyTerms[
                                  widget.route.difficultyId.toString()] ??
                              '',
                        ),
                        _buildInfoChip(
                          _circuitTypeTerms[
                                  widget.route.circuitTypeId.toString()] ??
                              '',
                        ),
                        _buildInfoChip(
                          _routeTypeTerms[
                                  widget.route.routeTypeId.toString()] ??
                              '',
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          center: widget.route.location,
                          zoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.route.location,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    if (widget.route.kmlUrl != null)
                      Center(
                        child: ElevatedButton(
                          onPressed: () => launch(widget.route.kmlUrl!),
                          child: Text('Descargar KML'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                          ),
                        ),
                      ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Cámara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    MainScreen(initialIndex: index),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 40,
          color: color,
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String value) {
    return Chip(
      label: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
