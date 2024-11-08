import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/route.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/models/map_item.dart';
import 'package:felanitx/pages/route_detail_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:felanitx/services/taxonomy_service.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  bool isGridView = false;
  int? selectedDifficulty;
  int? selectedCircuitType;
  int? selectedRouteType;
  List<RouteModel> routes = [];
  String pageTitle = 'Rutas';
  Map<String, String> _difficultyTerms = {};
  Map<String, String> _circuitTypeTerms = {};
  Map<String, String> _routeTypeTerms = {};
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadRoutes();
    _loadTaxonomyTerms();
    _setPageTitle();
  }

  Future<void> _loadRoutes() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    final data = await apiService.loadData('routes', language);
    setState(() {
      routes = data.map((item) => RouteModel.fromJson(item)).toList();
    });
  }

  void _setPageTitle() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    setState(() {
      switch (language) {
        case 'es':
          pageTitle = 'Rutas';
          break;
        case 'en':
          pageTitle = 'Routes';
          break;
        case 'ca':
          pageTitle = 'Rutes';
          break;
        case 'de':
          pageTitle = 'Routen';
          break;
        case 'fr':
          pageTitle = 'Itinéraires';
          break;
        default:
          pageTitle = 'Rutas';
      }
    });
  }

  List<RouteModel> get filteredItems {
    return routes.where((route) {
      if (selectedDifficulty != null &&
          route.difficultyId != selectedDifficulty) {
        return false;
      }
      if (selectedCircuitType != null &&
          route.circuitTypeId != selectedCircuitType) {
        return false;
      }
      if (selectedRouteType != null && route.routeTypeId != selectedRouteType) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? false;
    });
  }

  Future<void> _loadTaxonomyTerms() async {
    final taxonomyService = TaxonomyService();
    _difficultyTerms = await taxonomyService.getTaxonomyTerms('dificultat');
    _circuitTypeTerms = await taxonomyService.getTaxonomyTerms('tipuscircuit');
    _routeTypeTerms = await taxonomyService.getTaxonomyTerms('tipusruta');
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
              child: routes.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : isGridView
                      ? _buildGrid()
                      : _buildList(),
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
              child: routes.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : isGridView
                      ? _buildGrid()
                      : _buildList(),
            ),
          ],
        );
    }
  }

  Widget _buildFiltersAndViewToggle() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            pageTitle,
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

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        center: _calculateMapCenter(),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: filteredItems.map((route) {
            return Marker(
              point: route.location,
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

  Widget _buildFavorites() {
    // Implement favorites view here
    return Center(
      child: Text('Favorites coming soon'),
    );
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
          pageTitle,
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

  Widget _buildListItem(RouteModel route) {
    return SizedBox(
      height: 150,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteDetailPage(route: route),
              ),
            );
          },
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  child: Image.network(
                    route.mainImage ?? '',
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
                        route.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${route.distance.toStringAsFixed(2)} km - ${route.hours}h ${route.minutes}min',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.trending_up,
                              size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            '${route.positiveElevation.toStringAsFixed(0)}m',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.trending_down,
                              size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            '${route.negativeElevation.toStringAsFixed(0)}m',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _difficultyTerms[route.difficultyId.toString()] ??
                                '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () => _openInMaps(route),
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
      ),
    );
  }

  Widget _buildGridItem(RouteModel route) {
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteDetailPage(route: route),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    route.mainImage ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${route.distance.toStringAsFixed(2)} km - ${route.hours}h ${route.minutes}min',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _difficultyTerms[route.difficultyId.toString()] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.map, size: 20),
                          onPressed: () => _openInMaps(route),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facil':
        return Colors.green;
      case 'moderat':
        return Colors.orange;
      case 'dificil':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet() {
    final difficulties =
        routes.map((route) => route.difficultyId).toSet().toList();
    final circuitTypes =
        routes.map((route) => route.circuitTypeId).toSet().toList();
    final routeTypes =
        routes.map((route) => route.routeTypeId).toSet().toList();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dificultad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: difficulties.map((difficulty) {
                      return FilterChip(
                        label:
                            Text(_difficultyTerms[difficulty.toString()] ?? ''),
                        selected: selectedDifficulty == difficulty,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedDifficulty = selected ? difficulty : null;
                          });
                          setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selectedDifficulty == difficulty
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tipo de circuito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: circuitTypes.map((circuitType) {
                      return FilterChip(
                        label: Text(
                            _circuitTypeTerms[circuitType.toString()] ?? ''),
                        selected: selectedCircuitType == circuitType,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedCircuitType = selected ? circuitType : null;
                          });
                          setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selectedCircuitType == circuitType
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tipo de ruta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: routeTypes.map((routeType) {
                      return FilterChip(
                        label:
                            Text(_routeTypeTerms[routeType.toString()] ?? ''),
                        selected: selectedRouteType == routeType,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedRouteType = selected ? routeType : null;
                          });
                          setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selectedRouteType == routeType
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openInMaps(RouteModel route) async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${route.location.latitude},${route.location.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${route.location.latitude},${route.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  LatLng _calculateMapCenter() {
    if (filteredItems.isEmpty) {
      return LatLng(39.4699, 3.1150); // Felanitx default coordinates
    }

    double sumLat = 0;
    double sumLng = 0;
    int count = filteredItems.length;

    for (var route in filteredItems) {
      sumLat += route.location.latitude;
      sumLng += route.location.longitude;
    }

    return LatLng(sumLat / count, sumLng / count);
  }
}
