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
import 'package:felanitx/pages/map_page.dart';
import 'package:felanitx/main.dart';

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
    return Column(
      children: [
        _buildFiltersAndViewToggle(),
        Expanded(
          child: isGridView ? _buildGrid() : _buildList(),
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
                  Icons.map_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  _showMapModal(context);
                },
              ),
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
      mapController: _mapController,
      options: MapOptions(
        center: _calculateMapCenter(),
        zoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        keepAlive: true,
        interactiveFlags: InteractiveFlag.all,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          maxZoom: 19,
          userAgentPackageName: 'com.felanitx.app',
          tileProvider: NetworkTileProvider(),
        ),
        MarkerLayer(
          markers: filteredItems.map((route) {
            return Marker(
              point: route.location,
              width: 40,
              height: 40,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  _showMarkerPreview(ctx, route);
                },
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showMarkerPreview(BuildContext context, RouteModel route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  route.mainImage ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions_walk,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${route.distance.toStringAsFixed(2)} km',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${route.hours}h ${route.minutes}min',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          '${route.positiveElevation.toStringAsFixed(0)}m',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.trending_down, size: 16, color: Colors.red),
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
                    SizedBox(height: 8),
                    Text(
                      _difficultyTerms[route.difficultyId.toString()] ?? '',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RouteDetailPage(route: route),
                              ),
                            );
                          },
                          icon: Icon(Icons.info_outline),
                          label: Text('Ver detalles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openInMaps(route);
                          },
                          icon: Icon(Icons.map_outlined),
                          label: Text('Cómo llegar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            // Usar el mismo efecto que el botón de atrás
            Navigator.of(context).pop();
          } else {
            // Para los demás botones, mantener el comportamiento actual
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      MainScreen(initialIndex: index),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            });
          }
        },
      ),
    );
  }

  MapController _mapController = MapController();

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Mapa
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                child: _buildMapView(),
              ),

              // Barra superior con efecto de cristal
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Mapa de Rutas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Spacer(),
                          // Botón de cerrar con efecto de cristal
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Indicador de arrastre mejorado
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Botón flotante para centrar el mapa
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    // Centrar el mapa en la posición calculada
                    _mapController.move(_calculateMapCenter(), 13.0);
                  },
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final List<String> circuitTypes =
        routes.map((e) => e.circuitTypeId.toString()).toSet().toList()..sort();

    final List<String> routeTypes =
        routes.map((e) => e.routeTypeId.toString()).toSet().toList()..sort();

    final List<String> difficulties =
        routes.map((e) => e.difficultyId.toString()).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Dificultad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: difficulties.map((difficulty) {
                      final isSelected =
                          selectedDifficulty == int.parse(difficulty);
                      return FilterChip(
                        label: Text(_difficultyTerms[difficulty] ?? ''),
                        selected: isSelected,
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            selectedDifficulty =
                                selected ? int.parse(difficulty) : null;
                          });
                          this.setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        shape: StadiumBorder(),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tipo de circuito',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: circuitTypes.map((circuitType) {
                      final isSelected =
                          selectedCircuitType == int.parse(circuitType);
                      return FilterChip(
                        label: Text(_circuitTypeTerms[circuitType] ?? ''),
                        selected: isSelected,
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            selectedCircuitType =
                                selected ? int.parse(circuitType) : null;
                          });
                          this.setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        shape: StadiumBorder(),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tipo de ruta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: routeTypes.map((routeType) {
                      final isSelected =
                          selectedRouteType == int.parse(routeType);
                      return FilterChip(
                        label: Text(_routeTypeTerms[routeType] ?? ''),
                        selected: isSelected,
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            selectedRouteType =
                                selected ? int.parse(routeType) : null;
                          });
                          this.setState(() {});
                        },
                        backgroundColor: Colors.grey[200],
                        shape: StadiumBorder(),
                      );
                    }).toList(),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedDifficulty = null;
                            selectedCircuitType = null;
                            selectedRouteType = null;
                          });
                          this.setState(() {});
                        },
                        child: Text('Limpiar filtros'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Aplicar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
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
