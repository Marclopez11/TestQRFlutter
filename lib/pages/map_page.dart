import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:math';
import '../models/map_item.dart';
import '../models/interest.dart';
import '../models/route.dart';
import '../models/accommodation.dart';
import 'detail/item_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:collection/collection.dart';
import '../widgets/app_scaffold.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../models/population.dart';
import '../services/taxonomy_service.dart';
import 'detail/interest_detail_page.dart';
import 'route_detail_page.dart';
import 'detail/population_detail_page.dart';
import 'detail/accommodation_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  List<MapItem> _mapItems = [];
  List<MapItem> _filteredItems = [];
  LatLng _centerPosition = LatLng(39.4697, 3.1483);
  double _zoomLevel = 15.0;
  late MapController _mapController;
  late PopupController _popupController;
  bool _isLoading = true;
  Map<String, bool> _activeFilters = {};
  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _popupController = PopupController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Cargar el idioma desde SharedPreferences antes de mostrar cualquier cosa
    final language = await _apiService.getCurrentLanguage();
    setState(() {
      _currentLanguage = language.toUpperCase();
    });

    // Después de tener el idioma, cargar los datos
    _loadAllItems();
    _setupLanguageListener();
  }

  void _setupLanguageListener() {
    _apiService.languageStream.listen((String newLanguage) {
      if (_currentLanguage.toLowerCase() != newLanguage.toLowerCase()) {
        setState(() {
          _currentLanguage = newLanguage.toUpperCase();
        });
        _reloadItemsPreservingFilters();
      }
    });
  }

  Future<void> _reloadItemsPreservingFilters() async {
    // Guardar el estado actual de los filtros
    final currentFilters = Map<String, bool>.from(_activeFilters);

    // Recargar items
    await _loadAllItems();

    // Restaurar filtros previos que aún existan
    setState(() {
      currentFilters.forEach((key, value) {
        if (_activeFilters.containsKey(key)) {
          _activeFilters[key] = value;
        }
      });
      _updateFilteredItems();
    });
  }

  Future<void> _loadAllItems() async {
    setState(() => _isLoading = true);
    try {
      final language = await _apiService.getCurrentLanguage();
      _currentLanguage = language.toUpperCase();
      final apiLanguage = language.toLowerCase();

      // Cargar puntos de interés
      final interestsData =
          await _apiService.loadData('points_of_interest', apiLanguage);
      print('Loaded interests data: ${interestsData.length}');
      final interests = interestsData
          .map((json) {
            try {
              return Interest.fromJson(json);
            } catch (e) {
              print('Error parsing interest: $e');
              print('JSON: $json');
              return null;
            }
          })
          .whereType<Interest>()
          .toList();

      final interestItems =
          interests.map((i) => MapItem.fromInterest(i)).toList();

      // Cargar rutas a pie con taxonomía
      final walkingRoutesData =
          await _apiService.loadData('rutes', apiLanguage);
      final walkingRoutes = walkingRoutesData
          .map((json) {
            try {
              return RouteModel.fromJson(json);
            } catch (e) {
              print('Error parsing walking route: $e');
              return null;
            }
          })
          .whereType<RouteModel>()
          .toList();

      final walkingItems = await Future.wait(
          walkingRoutes.map((r) => MapItem.fromRouteWithTaxonomy(r, false)));

      // Cargar rutas en bici con taxonomía
      final bikeRoutesData =
          await _apiService.loadData('rutes_bici', apiLanguage);
      final bikeRoutes = bikeRoutesData
          .map((json) {
            try {
              return RouteModel.fromJson(json);
            } catch (e) {
              print('Error parsing bike route: $e');
              return null;
            }
          })
          .whereType<RouteModel>()
          .toList();

      final bikeItems = await Future.wait(
          bikeRoutes.map((r) => MapItem.fromRouteWithTaxonomy(r, true)));

      // Cargar hoteles
      final accommodationsData =
          await _apiService.loadData('hotel', apiLanguage);
      final accommodations = accommodationsData
          .map((json) {
            try {
              return Accommodation.fromJson(json);
            } catch (e) {
              print('Error parsing accommodation: $e');
              print('JSON: $json');
              return null;
            }
          })
          .whereType<Accommodation>()
          .toList();

      final hotelItems =
          accommodations.map((a) => MapItem.fromAccommodation(a)).toList();

      // Cargar poblaciones
      final populationsData =
          await _apiService.loadData('poblacio', apiLanguage);
      final populations = populationsData
          .map((json) {
            try {
              return Population.fromJson(json);
            } catch (e) {
              print('Error parsing population: $e');
              print('JSON: $json');
              return null;
            }
          })
          .whereType<Population>()
          .toList();

      final populationItems =
          populations.map((p) => MapItem.fromPopulation(p)).toList();

      setState(() {
        _mapItems = [
          ...interestItems,
          ...walkingItems,
          ...bikeItems,
          ...hotelItems,
          ...populationItems,
        ];
        print('Total map items: ${_mapItems.length}');
        _updateFilteredItems();
        if (_mapItems.isNotEmpty) {
          _updateMapView(useAllItems: true);
        } else {
          print('No items loaded!');
        }
      });

      // Obtener nombres únicos de filtros de todos los items
      final filterNames = _mapItems.map((item) => item.filterName).toSet();

      // Inicializar filtros
      setState(() {
        _activeFilters =
            Map.fromEntries(filterNames.map((name) => MapEntry(name, true)));
        _updateFilteredItems();
      });
    } catch (e) {
      print('Error loading items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateFilteredItems() {
    setState(() {
      _filteredItems = _mapItems.where((item) {
        return _activeFilters[item.filterName] ?? false;
      }).toList();

      if (_filteredItems.isNotEmpty) {
        _updateMapView();
      }
    });
  }

  void _updateMapView({bool useAllItems = false}) {
    List<MapItem> itemsToUse = useAllItems ? _mapItems : _filteredItems;
    if (itemsToUse.isEmpty) {
      setState(() {
        _centerPosition = LatLng(39.4697, 3.1483);
        _zoomLevel = 15.0;
      });
      return;
    }

    double sumLat = 0;
    double sumLng = 0;
    double minLat = itemsToUse.first.position.latitude;
    double maxLat = itemsToUse.first.position.latitude;
    double minLng = itemsToUse.first.position.longitude;
    double maxLng = itemsToUse.first.position.longitude;

    for (var item in itemsToUse) {
      sumLat += item.position.latitude;
      sumLng += item.position.longitude;
      minLat = min(minLat, item.position.latitude);
      maxLat = max(maxLat, item.position.latitude);
      minLng = min(minLng, item.position.longitude);
      maxLng = max(maxLng, item.position.longitude);
    }

    double centerLat = sumLat / itemsToUse.length;
    double centerLng = sumLng / itemsToUse.length;
    double zoomLevel = _calculateZoomLevel(minLat, maxLat, minLng, maxLng);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(centerLat, centerLng), zoomLevel);
    });
  }

  double _calculateZoomLevel(
      double minLat, double maxLat, double minLng, double maxLng) {
    const int zoomMax = 18;
    const int zoomMin = 3;

    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = max(latDiff, lngDiff);

    if (maxDiff < 0.01) {
      return 15.0;
    }
    if (maxDiff > 1) return 12.0;

    double zoomLevel = 16 - log(maxDiff * 111) / log(2);
    return max(zoomLevel.clamp(12.0, zoomMax.toDouble()), 12.0);
  }

  String get _mapTileUrl {
    if (Platform.isIOS) {
      print('iOS map tile URL: https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    } else if (Platform.isAndroid) {
      return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    } else {
      return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
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

  @override
  Widget build(BuildContext context) {
    // Si aún no tenemos el idioma, mostrar un indicador de carga
    if (_currentLanguage.isEmpty) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppScaffold(
      body: Column(
        children: [
          Container(
            height: 60,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo_felanitx.png',
                  height: 40,
                ),
                DropdownButton<String>(
                  value: _currentLanguage,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _handleLanguageChange(newValue.toLowerCase());
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ES', child: Text('ES')),
                    DropdownMenuItem(value: 'EN', child: Text('EN')),
                    DropdownMenuItem(value: 'CA', child: Text('CA')),
                    DropdownMenuItem(value: 'DE', child: Text('DE')),
                    DropdownMenuItem(value: 'FR', child: Text('FR')),
                  ],
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _centerPosition,
                          zoom: _zoomLevel,
                          minZoom: 3,
                          maxZoom: 18,
                          interactiveFlags:
                              InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: Platform.isAndroid
                                ? 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: Platform.isAndroid
                                ? ['0', '1', '2', '3']
                                : ['a', 'b', 'c'],
                          ),
                          PopupMarkerLayerWidget(
                            options: PopupMarkerLayerOptions(
                              markers: _filteredItems
                                  .map((item) => Marker(
                                        point: item.position,
                                        width: 40,
                                        height: 40,
                                        builder: (_) => Image.asset(
                                          item.markerIcon,
                                          width: 40,
                                          height: 40,
                                        ),
                                        anchorPos:
                                            AnchorPos.align(AnchorAlign.top),
                                      ))
                                  .toList(),
                              popupController: _popupController,
                              popupDisplayOptions: PopupDisplayOptions(
                                builder: (_, Marker marker) {
                                  final item = _filteredItems.firstWhereOrNull(
                                    (item) => item.position == marker.point,
                                  );
                                  if (item == null) return SizedBox.shrink();

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
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(12)),
                                              child: Image.network(
                                                item.imageUrl,
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    height: 200,
                                                    color: Colors.grey[300],
                                                    child: Icon(Icons
                                                        .image_not_supported),
                                                  );
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Material(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  onTap: () {
                                                    _popupController
                                                        .hideAllPopups();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Icon(Icons.close,
                                                        size: 20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 20,
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
                                              SizedBox(height: 8),
                                              Text(
                                                item.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _navigateToDetail(item),
                                                    icon: Icon(
                                                        Icons.info_outline),
                                                    label: Text('Ver detalles'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      _popupController
                                                          .hideAllPopups();
                                                      _openInMaps(item);
                                                    },
                                                    icon: Icon(
                                                        Icons.map_outlined),
                                                    label: Text('Cómo llegar'),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      side: BorderSide(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
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
                                snap: PopupSnap.mapBottom,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 80,
                        right: 20,
                        child: FloatingActionButton(
                          onPressed: () => _showFilterSheet(),
                          child: Icon(Icons.filter_list),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setState) {
        final filterEntries = _activeFilters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final bool hasInactiveFilters = _activeFilters.values.any((v) => !v);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenedor de altura fija para el encabezado
              Container(
                height: 48, // Altura fija para evitar saltos
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtrar por tipo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: hasInactiveFilters ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: hasInactiveFilters
                            ? () {
                                setState(() {
                                  _activeFilters.forEach((key, value) {
                                    _activeFilters[key] = true;
                                  });
                                });
                                this.setState(() {
                                  _updateFilteredItems();
                                });
                              }
                            : null,
                        child: Text('Mostrar todos'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size(0, 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Lista de filtros con scroll
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: filterEntries.map((entry) {
                      final filterName = entry.key;
                      final isActive = entry.value;
                      final item = _mapItems.firstWhere(
                        (item) => item.filterName == filterName,
                        orElse: () => _mapItems.first,
                      );

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Row(
                            children: [
                              Image.asset(
                                item.getIconForFilter(),
                                width: 24,
                                height: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  filterName,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          value: isActive,
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          onChanged: (bool? value) {
                            setState(() {
                              _activeFilters[filterName] = value ?? false;
                            });
                            this.setState(() {
                              _updateFilteredItems();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(MapItem item) {
    _popupController.hideAllPopups();

    switch (item.type) {
      case 'interest':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterestDetailPage(
              interest: Interest(
                id: item.id,
                title: item.title,
                description: item.description,
                address: item.address ?? '',
                location: item.position,
                categoryId:
                    int.tryParse(item.categoryId?.toString() ?? '') ?? 0,
                featured: item.featured ?? false,
                imageGallery: item.imageGallery ?? [],
                mainImage: item.imageUrl,
                langcode: item.langcode ?? _currentLanguage,
                facebookUrl: item.facebookUrl,
                instagramUrl: item.instagramUrl,
                twitterUrl: item.twitterUrl,
                websiteUrl: item.websiteUrl,
                phoneNumber: item.phoneNumber,
                audioUrl: item.audioUrl,
                videoUrl: item.videoUrl,
              ),
            ),
          ),
        );
        break;

      case 'route_walk':
      case 'route_bike':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailPage(
              route: RouteModel(
                id: int.parse(item.id),
                title: item.title,
                description: item.description,
                mainImage: item.imageUrl,
                location: item.position,
                distance: item.distance ?? 0,
                hours: item.hours ?? 0,
                minutes: item.minutes ?? 0,
                positiveElevation: item.positiveElevation ?? 0,
                negativeElevation: item.negativeElevation ?? 0,
                difficultyId: item.difficultyId ?? 0,
                circuitTypeId: item.circuitTypeId ?? 0,
                routeTypeId:
                    item.routeTypeId ?? (item.type == 'route_bike' ? 255 : 257),
                gpxFile: item.gpxFile,
                kmlUrl: item.kmlUrl,
              ),
            ),
          ),
        );
        break;

      case 'hotel':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccommodationDetailPage(
              accommodation: Accommodation(
                id: item.id,
                title: item.title,
                description: item.description,
                mainImage: item.imageUrl,
                location: item.position,
                hotelType: item.hotelType ?? 0,
                hotelServices: item.hotelServices ?? [],
                address: item.address ?? '',
                phoneNumber: item.phoneNumber ?? '',
                phoneNumber2: item.phoneNumber2,
                email: item.email ?? '',
                imageGallery: item.imageGallery ?? [],
                categoryId:
                    int.tryParse(item.categoryId?.toString() ?? '') ?? 0,
                facebook: item.facebookUrl,
                instagram: item.instagramUrl,
                twitter: item.twitterUrl,
                web: item.websiteUrl,
                stars: item.stars,
              ),
            ),
          ),
        );
        break;

      case 'population':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PopulationDetailPage(
              population: Population(
                id: item.id,
                title: item.title,
                mainImage: item.imageUrl,
                imageGallery: item.imageGallery ?? [],
                location: item.position,
                description1: item.description,
                title1: item.title1,
                title2: item.title2,
                title3: item.title3,
                description2: item.description2,
                description3: item.description3,
              ),
            ),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    // Asegurarse de limpiar los listeners
    super.dispose();
  }

  // Añadir el método para manejar el cambio de idioma
  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage.toLowerCase() != language) {
      final apiService = ApiService();
      await apiService.setLanguage(language);

      setState(() {
        _currentLanguage = language.toUpperCase();
      });

      _reloadItemsPreservingFilters();
    }
  }
}
