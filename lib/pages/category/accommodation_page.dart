import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/accommodation.dart';
import 'package:felanitx/pages/detail/accommodation_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:felanitx/main.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:felanitx/models/category_for_items.dart';
import 'package:felanitx/services/taxonomy_service.dart';

class AccommodationPage extends StatefulWidget {
  final String title;

  const AccommodationPage({Key? key, this.title = ''}) : super(key: key);

  @override
  _AccommodationPageState createState() => _AccommodationPageState();
}

class _AccommodationPageState extends State<AccommodationPage> {
  final ApiService _apiService = ApiService();
  final TaxonomyService _taxonomyService = TaxonomyService();
  bool isGridView = false;
  List<String> selectedCategories = [];
  int _selectedNavIndex = 1;
  MapController _mapController = MapController();
  List<Accommodation> _accommodations = [];
  bool _isLoading = true;
  String _currentLanguage = 'ca';
  String _title = 'Alojamientos';
  List<CategoryForItems> _categories = [];
  Map<String, String> _hotelTypes = {};

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
    _loadPreferences();
  }

  Future<void> _loadInitialLanguage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final language = await _apiService.getCurrentLanguage();
      _currentLanguage = language;

      // Primero cargamos los tipos de hotel
      await _loadHotelTypes();

      // Luego cargamos los alojamientos
      await _loadAccommodations();

      setState(() {
        _currentLanguage = language;
        _title = AppTranslations.translate('accommodations', language);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading initial language: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHotelTypes() async {
    try {
      print('Loading hotel types for language: $_currentLanguage'); // Debug log

      final hotelTypes = await _taxonomyService.getTaxonomyTerms('tipushotel',
          language: _currentLanguage);

      print('Loaded hotel types: $hotelTypes'); // Debug log

      if (mounted) {
        setState(() {
          _hotelTypes = hotelTypes;
        });
      }
    } catch (e) {
      print('Error loading hotel types: $e');
    }
  }

  Future<void> _loadAccommodations() async {
    try {
      final data = await _apiService.loadData('hotel', _currentLanguage);

      print('Datos recibidos de la API: $data');

      if (data != null && data is List) {
        setState(() {
          _accommodations =
              data.map((item) => Accommodation.fromJson(item)).toList();
        });
        print('Número de alojamientos cargados: ${_accommodations.length}');
      } else {
        print('Error: Los datos recibidos no son una lista válida');
        setState(() {
          _accommodations = [];
        });
      }
    } catch (e, stackTrace) {
      print('Error loading accommodations: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _accommodations = [];
      });
    }
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? false;
    });
  }

  List<Accommodation> get filteredItems {
    if (selectedCategories.isEmpty) return _accommodations;
    return _accommodations
        .where((item) => selectedCategories.contains(item.hotelType.toString()))
        .toList();
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
      body: SafeArea(
        child: _buildNavContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppTranslations.translate('home', _currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: AppTranslations.translate('map', _currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: AppTranslations.translate('camera', _currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: AppTranslations.translate('plan', _currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppTranslations.translate('settings', _currentLanguage),
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

  Widget _buildFiltersAndViewToggle() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.map_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        _showMapModal(context);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
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
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (selectedCategories.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedCategories
                  .map(
                    (categoryId) => Chip(
                      label: Text(_getCategoryName(int.parse(categoryId))),
                      onDeleted: () {
                        setState(() {
                          selectedCategories.remove(categoryId);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredItems.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildListItem(Accommodation item) {
    return SizedBox(
      height: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AccommodationDetailPage(accommodation: item),
              ),
            );
          },
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Image.network(
                    item.mainImage,
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description != null) ...[
                        SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _openInMaps(item),
                            child: Icon(
                              Icons.map,
                              size: 16,
                              color: Colors.grey[600],
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
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
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

  Widget _buildGridItem(Accommodation item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AccommodationDetailPage(accommodation: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  item.mainImage,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (item.description != null) ...[
                      Expanded(
                        child: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openInMaps(item),
                          child: Icon(
                            Icons.map,
                            size: 16,
                            color: Colors.grey[600],
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
    );
  }

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
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                child: _buildMapView(),
              ),
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
                            AppTranslations.translate(
                                'accommodations_map', _currentLanguage),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Spacer(),
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
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(centerMapPosition, 13.0);
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

  void _openInMaps(Accommodation item) async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${item.location.latitude},${item.location.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${item.location.latitude},${item.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  LatLng get centerMapPosition {
    if (_accommodations.isEmpty) {
      return LatLng(39.4699, 3.1150); // Coordenadas por defecto de Felanitx
    }

    double sumLat = 0;
    double sumLng = 0;
    int count = _accommodations.length;

    for (var item in _accommodations) {
      sumLat += item.location.latitude;
      sumLng += item.location.longitude;
    }

    return LatLng(sumLat / count, sumLng / count);
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: centerMapPosition,
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
          markers: _accommodations.map((item) {
            return Marker(
              point: item.location,
              width: 40,
              height: 40,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  _showMarkerPreview(context, item);
                },
                child: Image.asset(
                  'assets/images/marker-icon04.png',
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

  void _showMarkerPreview(BuildContext context, Accommodation item) {
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
                      item.mainImage,
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
                      item.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccommodationDetailPage(
                                    accommodation: item),
                              ),
                            );
                          },
                          icon: Icon(Icons.info_outline),
                          label: Text(AppTranslations.translate(
                              'see_details', _currentLanguage)),
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
                            _openInMaps(item);
                          },
                          icon: Icon(Icons.map_outlined),
                          label: Text(AppTranslations.translate(
                              'how_to_get_there', _currentLanguage)),
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

  void _showFilterBottomSheet() {
    final List<String> categoryIds = _accommodations
        .map((e) => e.hotelType.toString())
        .toSet()
        .toList()
      ..sort();

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
                        AppTranslations.translate(
                            'filter_by_hotel_type', _currentLanguage),
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
                    child: ListView(
                      children: categoryIds.map((categoryId) {
                        final isSelected =
                            selectedCategories.contains(categoryId);
                        final categoryName =
                            _getCategoryName(int.parse(categoryId));
                        return ListTile(
                          title: Text(categoryName),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: Theme.of(context).primaryColor)
                              : null,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedCategories.remove(categoryId);
                              } else {
                                selectedCategories.add(categoryId);
                              }
                            });
                            this.setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (selectedCategories.isNotEmpty)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCategories.clear();
                          });
                          this.setState(() {});
                        },
                        child: Text(AppTranslations.translate(
                            'clear_filters', _currentLanguage)),
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

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      setState(() {
        _currentLanguage = language;
        _isLoading = true;
      });

      await _apiService.setLanguage(language);

      // Primero cargamos los tipos de hotel
      await _loadHotelTypes();

      try {
        final freshData = await _apiService.loadFreshData('hotel', language);
        setState(() {
          _accommodations =
              freshData.map((item) => Accommodation.fromJson(item)).toList();
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading fresh data: $e');

        final cachedData = await _apiService.loadCachedData('hotel', language);
        if (cachedData.isNotEmpty) {
          setState(() {
            _accommodations =
                cachedData.map((item) => Accommodation.fromJson(item)).toList();
          });
        }
        setState(() {
          _isLoading = false;
        });
      }

      if (mounted) {
        final homePage = HomePage.of(context);
        homePage?.reloadData();
      }
    }
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
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
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
                        SizedBox(height: 4),
                        Container(
                          width: 200,
                          height: 16,
                          color: Colors.white,
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
          childAspectRatio: 0.75,
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
                          width: 100,
                          height: 14,
                          color: Colors.white,
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

  String _getCategoryName(int categoryId) {
    return _hotelTypes[categoryId.toString()] ?? 'Hotel Type $categoryId';
  }
}
