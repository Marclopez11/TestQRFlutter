import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/map_item.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

class PointsOfInterestPage extends StatefulWidget {
  final String title;

  const PointsOfInterestPage({Key? key, this.title = ''}) : super(key: key);

  @override
  _PointsOfInterestPageState createState() => _PointsOfInterestPageState();
}

class _PointsOfInterestPageState extends State<PointsOfInterestPage> {
  bool isGridView = false;
  String? selectedCategory;
  int _selectedNavIndex = 1;

  final List<MapItem> pointsOfInterest = [
    MapItem(
      id: '1',
      title: 'Castell de Santueri',
      description: 'Castell històric amb vistes panoràmiques',
      position: LatLng(39.4271, 3.1551),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/galeria.jpg',
      categoryId: 1,
      categoryName: 'Monuments',
      averageRating: 5.0,
      commentCount: 0,
    ),
    MapItem(
      id: '2',
      title: 'Estació de Tren',
      description: 'Antiga estació de tren',
      position: LatLng(39.4704, 3.1474),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/estacio.jpg',
      categoryId: 2,
      categoryName: 'Edificis històrics',
      averageRating: 4.5,
      commentCount: 2,
    ),
    MapItem(
      id: '3',
      title: 'Cementiri Municipal',
      description: 'Cementiri històric de Felanitx',
      position: LatLng(39.4704, 3.1474),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/cementiri.jpg',
      categoryId: 3,
      categoryName: 'Patrimoni',
      averageRating: 4.0,
      commentCount: 1,
    ),
    MapItem(
      id: '4',
      title: 'Sindicat',
      description: 'Antic edifici del Sindicat',
      position: LatLng(39.4704, 3.1474),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/sindicat.jpg',
      categoryId: 2,
      categoryName: 'Edificis històrics',
      averageRating: 4.8,
      commentCount: 3,
    ),
    MapItem(
      id: '5',
      title: 'Església de Sant Miquel',
      description: 'Església principal de Felanitx',
      position: LatLng(39.4704, 3.1474),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/esglesia.jpg',
      categoryId: 1,
      categoryName: 'Monuments',
      averageRating: 5.0,
      commentCount: 4,
    ),
    MapItem(
      id: '6',
      title: 'Plaça de Felanitx',
      description: 'Plaça principal del municipi',
      position: LatLng(39.4704, 3.1474),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/plac%CC%A7a_0.jpg',
      categoryId: 4,
      categoryName: 'Places',
      averageRating: 4.7,
      commentCount: 5,
    ),
  ];

  List<MapItem> get filteredItems {
    if (selectedCategory == null) return pointsOfInterest;
    return pointsOfInterest
        .where((item) => item.categoryName == selectedCategory)
        .toList();
  }

  LatLng get _centerPosition {
    if (filteredItems.isEmpty) {
      return LatLng(39.4699, 3.1150); // Default Felanitx coordinates
    }

    double sumLat = 0;
    double sumLng = 0;

    for (var item in filteredItems) {
      sumLat += item.position.latitude;
      sumLng += item.position.longitude;
    }

    return LatLng(sumLat / filteredItems.length, sumLng / filteredItems.length);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? false;
    });
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
        title: Text(
          'Puntos de interés',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _buildNavContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
        ],
        currentIndex: _selectedNavIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            setState(() {
              _selectedNavIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildNavContent() {
    switch (_selectedNavIndex) {
      case 0:
        return Container();
      case 1:
        return Column(
          children: [
            _buildFiltersAndViewToggle(),
            Expanded(
              child: isGridView ? _buildGrid() : _buildList(),
            ),
          ],
        );
      case 2:
        return _buildMapView();
      default:
        return Column(
          children: [
            _buildFiltersAndViewToggle(),
            Expanded(
              child: isGridView ? _buildGrid() : _buildList(),
            ),
          ],
        );
    }
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: filteredItems.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildGridItem(item);
      },
    );
  }

  Widget _buildListItem(MapItem item) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(item: item),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.categoryName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (item.averageRating > 0) ...[
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '${item.averageRating} (${item.commentCount})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () {
                              _openInMaps(item);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(MapItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: item.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.categoryName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (item.averageRating > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${item.averageRating.toStringAsFixed(1)} (${item.commentCount})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.map, size: 20),
                          onPressed: () {
                            _openInMaps(item);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final categories =
        pointsOfInterest.map((item) => item.categoryName).toSet().toList();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtrar por categoría',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilterChip(
                        label: Text('Todas'),
                        selected: selectedCategory == null,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedCategory = null;
                          });
                          setState(() {});
                          Navigator.pop(context);
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selectedCategory == null
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      ),
                      ...categories.map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (selected) {
                            setModalState(() {
                              selectedCategory = category;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: selectedCategory == category
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        center: _centerPosition,
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: filteredItems.map((item) {
            return Marker(
              point: item.position,
              builder: (ctx) => Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFiltersAndViewToggle() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Puntos de interés',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isGridView ? Icons.view_list : Icons.grid_view,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () async {
                  setState(() {
                    isGridView = !isGridView;
                  });
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool('isGridView', isGridView);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
