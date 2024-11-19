import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/route.dart';
import 'package:felanitx/pages/detail/item_detail_page.dart';
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
import 'package:shimmer/shimmer.dart';
import 'package:felanitx/pages/home_page.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final ApiService _apiService = ApiService();
  bool isGridView = false;
  int? selectedDifficulty;
  int? selectedCircuitType;
  int? selectedRouteType;
  List<RouteModel> routes = [];
  String _currentLanguage = 'ca';
  String _title = 'Rutas';
  Map<String, String> _difficultyTerms = {};
  Map<String, String> _circuitTypeTerms = {};
  Map<String, String> _routeTypeTerms = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
    _loadPreferences();
    _loadRoutes();
    _loadTaxonomyTerms();
  }

  Future<void> _loadInitialLanguage() async {
    try {
      final language = await _apiService.getCurrentLanguage();
      setState(() {
        _currentLanguage = language;
        _updateTitleForLanguage(language);
      });
    } catch (e) {
      print('Error loading initial language: $e');
    }
  }

  void _updateTitleForLanguage(String language) {
    setState(() {
      switch (language) {
        case 'ca':
          _title = 'Rutes';
          break;
        case 'es':
          _title = 'Rutas';
          break;
        case 'en':
          _title = 'Routes';
          break;
        case 'fr':
          _title = 'Itinéraires';
          break;
        case 'de':
          _title = 'Routen';
          break;
        default:
          _title = 'Rutas';
      }
    });
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      setState(() {
        _currentLanguage = language;
        _isLoading = true;
      });

      await _apiService.setLanguage(language);
      _updateTitleForLanguage(language);

      if (mounted) {
        final homePage = HomePage.of(context);
        homePage?.reloadData();
      }

      try {
        final cachedData = await _apiService.loadCachedData('rutes', language);
        if (cachedData.isNotEmpty) {
          setState(() {
            routes =
                cachedData.map((item) => RouteModel.fromJson(item)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading cached data: $e');
      }

      try {
        final freshData = await _apiService.loadFreshData('rutes', language);
        setState(() {
          routes = freshData.map((item) => RouteModel.fromJson(item)).toList();
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading fresh data: $e');
      }

      // Recargar los términos de taxonomía en el nuevo idioma
      await _loadTaxonomyTerms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            final homePage = HomePage.of(context);
            homePage?.reloadData();
            Navigator.of(context).pop();
          },
        ),
        title: Image.asset(
          'assets/images/logo_felanitx.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          _isLoading
              ? SizedBox(width: 24, height: 24)
              : DropdownButton<String>(
                  value: _currentLanguage.toUpperCase(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _handleLanguageChange(newValue.toLowerCase());
                    }
                  },
                  items: <String>['ES', 'EN', 'CA', 'DE', 'FR']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down),
                ),
          SizedBox(width: 16),
        ],
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

  Widget _buildNavContent() {
    if (_isLoading) {
      return Column(
        children: [
          _buildShimmerFiltersAndViewToggle(),
          Expanded(
            child: isGridView ? _buildShimmerGrid() : _buildShimmerList(),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildFiltersAndViewToggle(),
        Expanded(
          child: isGridView ? _buildGrid() : _buildList(),
        ),
      ],
    );
  }

  Widget _buildShimmerFiltersAndViewToggle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 16),
                            Container(
                              width: 60,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 80,
                              height: 16,
                              color: Colors.white,
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 14,
                          color: Colors.white,
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 60,
                              height: 14,
                              color: Colors.white,
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
          );
        },
      ),
    );
  }

  Widget _buildFiltersAndViewToggle() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _title,
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
        ),
        MarkerLayer(
          markers: filteredItems.map((route) {
            return Marker(
              point: route.location,
              width: 40,
              height: 40,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  _showMarkerPreview(context, route);
                },
                child: Image.asset(
                  route.routeTypeId == 254 || route.routeTypeId == 255
                      ? 'assets/images/marker-icon03.png'
                      : 'assets/images/marker-icon02.png',
                  width: 40,
                  height: 40,
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
          width: double.infinity,
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
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
    final List<String> difficulties =
        routes.map((e) => e.difficultyId.toString()).toSet().toList()..sort();
    final List<String> circuitTypes =
        routes.map((e) => e.circuitTypeId.toString()).toSet().toList()..sort();
    final List<String> routeTypes =
        routes.map((e) => e.routeTypeId.toString()).toSet().toList()..sort();

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (difficulties.isNotEmpty) ...[
                            Text(
                              'Dificultad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: difficulties.map((difficulty) {
                                final isSelected =
                                    selectedDifficulty == int.parse(difficulty);
                                return FilterChip(
                                  label:
                                      Text(_difficultyTerms[difficulty] ?? ''),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedDifficulty = selected
                                          ? int.parse(difficulty)
                                          : null;
                                    });
                                    this.setState(() {});
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 24),
                          ],
                          if (circuitTypes.isNotEmpty) ...[
                            Text(
                              'Tipo de circuito',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: circuitTypes.map((type) {
                                final isSelected =
                                    selectedCircuitType == int.parse(type);
                                return FilterChip(
                                  label: Text(_circuitTypeTerms[type] ?? ''),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedCircuitType =
                                          selected ? int.parse(type) : null;
                                    });
                                    this.setState(() {});
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 24),
                          ],
                          if (routeTypes.isNotEmpty) ...[
                            Text(
                              'Tipo de ruta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: routeTypes.map((type) {
                                final isSelected =
                                    selectedRouteType == int.parse(type);
                                return FilterChip(
                                  label: Text(_routeTypeTerms[type] ?? ''),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedRouteType =
                                          selected ? int.parse(type) : null;
                                    });
                                    this.setState(() {});
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text('Aplicar'),
                        ),
                      ],
                    ),
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

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final language = await _apiService.getCurrentLanguage();
      final data = await _apiService.loadData('rutes', language);

      if (data != null && data is List) {
        setState(() {
          routes = data.map((item) => RouteModel.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        print('Error: Los datos recibidos no son una lista válida');
        setState(() {
          routes = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading routes: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        routes = [];
        _isLoading = false;
      });
    }
  }
}
