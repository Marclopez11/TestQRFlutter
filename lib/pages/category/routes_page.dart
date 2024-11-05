import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/route.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/models/map_item.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  bool isGridView = false;
  String? selectedDifficulty;
  String? selectedCircuitType;
  String? selectedRouteType;
  List<RouteModel> routes = [];
  String pageTitle = 'Rutas';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadRoutes();
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
          route.difficulty != selectedDifficulty) {
        return false;
      }
      if (selectedCircuitType != null &&
          route.circuitType != selectedCircuitType) {
        return false;
      }
      if (selectedRouteType != null && route.routeType != selectedRouteType) {
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
      body: Column(
        children: [
          Padding(
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
          ),
          Expanded(
            child: routes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : isGridView
                    ? _buildGrid()
                    : _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
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
        onTap: (index) {
          if (index != 1) {
            Navigator.of(context).pop();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
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
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(route: route),
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
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${route.distance} km - ${route.hours}h ${route.minutes}min',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          '${route.positiveElevation}m',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.trending_down, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          '${route.negativeElevation}m',
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
                          route.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: _getDifficultyColor(route.difficulty),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (route.kmlUrl != null)
                          IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () => _downloadKML(route.kmlUrl!),
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

  Future<void> _downloadKML(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildGridItem(RouteModel route) {
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
              builder: (context) => ItemDetailPage(route: route),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: route.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    route.mainImage ?? '',
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
                    route.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${route.distance} km - ${route.hours}h ${route.minutes}min',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '${route.positiveElevation}m',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.trending_down, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        '${route.negativeElevation}m',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        route.difficulty.toUpperCase(),
                        style: TextStyle(
                          color: _getDifficultyColor(route.difficulty),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (route.kmlUrl != null)
                        IconButton(
                          icon: Icon(Icons.download, size: 20),
                          onPressed: () => _downloadKML(route.kmlUrl!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final difficulties =
        routes.map((route) => route.difficulty).toSet().toList();
    final circuitTypes =
        routes.map((route) => route.circuitType).toSet().toList();
    final routeTypes = routes.map((route) => route.routeType).toSet().toList();

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterSection(
                        'Dificultad', difficulties, selectedDifficulty,
                        (value) {
                      setModalState(() {
                        selectedDifficulty = value as String?;
                      });
                      setState(() {});
                    }),
                    SizedBox(height: 20),
                    _buildFilterSection(
                        'Tipo de circuito', circuitTypes, selectedCircuitType,
                        (value) {
                      setModalState(() {
                        selectedCircuitType = value as String?;
                      });
                      setState(() {});
                    }),
                    SizedBox(height: 20),
                    _buildFilterSection(
                        'Tipo de ruta', routeTypes, selectedRouteType, (value) {
                      setModalState(() {
                        selectedRouteType = value as String?;
                      });
                      setState(() {});
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(String title, List<String> options,
      String? selectedValue, Function(String?) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilterChip(
              label: Text('Todos'),
              selected: selectedValue == null,
              onSelected: (selected) {
                onSelected(null);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: selectedValue == null
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              ),
            ),
            ...options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: selectedValue == option,
                onSelected: (selected) {
                  onSelected(selected ? option : null);
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selectedValue == option
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                ),
              );
            }).toList(),
          ],
        ),
      ],
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
}
