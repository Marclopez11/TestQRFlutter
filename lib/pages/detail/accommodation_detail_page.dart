import 'dart:io';
import 'package:flutter/material.dart';
import 'package:felanitx/models/accommodation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:felanitx/services/taxonomy_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:felanitx/main.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:felanitx/services/api_service.dart';

class AccommodationDetailPage extends StatefulWidget {
  final Accommodation accommodation;

  const AccommodationDetailPage({Key? key, required this.accommodation})
      : super(key: key);

  @override
  _AccommodationDetailPageState createState() =>
      _AccommodationDetailPageState();
}

class _AccommodationDetailPageState extends State<AccommodationDetailPage> {
  String _currentLanguage = 'ca';
  final ApiService _apiService = ApiService();
  final TaxonomyService _taxonomyService = TaxonomyService();
  Map<String, String> _hotelTypes = {};
  Map<String, String> _hotelServices = {};
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage().then((_) {
      _loadTaxonomyData();
    });
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final language = await _apiService.getCurrentLanguage();
      setState(() {
        _currentLanguage = language;
      });
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> _loadTaxonomyData() async {
    try {
      print('Loading hotel types for language: $_currentLanguage');

      // Cargar tipos de hotel
      final hotelTypes = await _taxonomyService.getTaxonomyTerms('tipushotel',
          language: _currentLanguage);

      // Cargar servicios de hotel
      final services = await _taxonomyService.getTaxonomyTerms('serveishotel',
          language: _currentLanguage);

      print('Loaded hotel types: $hotelTypes');
      print('Hotel type ID: ${widget.accommodation.hotelType}');

      if (mounted) {
        setState(() {
          _hotelTypes = hotelTypes;
          _hotelServices = services;
        });
      }
    } catch (e) {
      print('Error loading taxonomy data: $e');
    }
  }

  String _getHotelTypeName() {
    final typeId = widget.accommodation.hotelType.toString();
    final name = _hotelTypes[typeId];
    print('Getting hotel type name for ID $typeId: $name');
    return name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
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
                onPressed: () {
                  // Implementar compartir
                },
              ),
            ],
            title: Image.asset(
              'assets/images/logo_felanitx.png',
              height: 40,
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  widget.accommodation.mainImage,
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
                        widget.accommodation.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getHotelTypeName(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildImageGallery(),
                _buildDescription(),
                _buildSocialLinks(),
                if (_hotelServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Text(
                          AppTranslations.translate(
                              'available_services', _currentLanguage),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _hotelServices.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: Icon(
                                      _getServiceIcon(_hotelServices.values
                                          .elementAt(index)),
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        _hotelServices.values.elementAt(index),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      center: widget.accommodation.location,
                      zoom: 15.0,
                      interactiveFlags: InteractiveFlag.none,
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
                            point: widget.accommodation.location,
                            width: 40,
                            height: 40,
                            builder: (_) => GestureDetector(
                              onTap: _openInMaps,
                              child: Image.asset(
                                'assets/images/marker-icon04.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.translate(
                            'contact_info', _currentLanguage),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Dirección
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.accommodation.address,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Teléfono principal
                      InkWell(
                        onTap: () =>
                            launch('tel:${widget.accommodation.phoneNumber}'),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.accommodation.phoneNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Teléfono secundario (si existe)
                      if (widget.accommodation.phoneNumber2 != null) ...[
                        SizedBox(height: 12),
                        InkWell(
                          onTap: () => launch(
                              'tel:${widget.accommodation.phoneNumber2}'),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.accommodation.phoneNumber2!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Email
                      if (widget.accommodation.email.isNotEmpty) ...[
                        SizedBox(height: 12),
                        InkWell(
                          onTap: () =>
                              launch('mailto:${widget.accommodation.email}'),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.accommodation.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Lógica para guardar en plan de viaje
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppTranslations.translate(
                              'save_to_trip', _currentLanguage)),
                          SizedBox(width: 8),
                          Icon(Icons.bookmark),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
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

  Widget _buildImageGallery() {
    if (widget.accommodation.imageGallery.isEmpty) return SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: widget.accommodation.imageGallery.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _openGallery(context),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              widget.accommodation.imageGallery.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .primaryColor
                    .withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: widget.accommodation.imageGallery.isNotEmpty
              ? widget.accommodation.imageGallery
              : [widget.accommodation.mainImage],
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.accommodation.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            maxLines: _isDescriptionExpanded ? null : 8,
            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          if (widget.accommodation.description.length > 500)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded
                    ? AppTranslations.translate('see_less', _currentLanguage)
                    : AppTranslations.translate('see_more', _currentLanguage),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.accommodation.web != null)
            _buildSocialIcon(
              FontAwesomeIcons.globe,
              widget.accommodation.web!,
              Colors.blue,
            ),
          if (widget.accommodation.twitter != null)
            _buildSocialIcon(
              FontAwesomeIcons.twitter,
              widget.accommodation.twitter!,
              Color(0xFF1DA1F2),
            ),
          if (widget.accommodation.instagram != null)
            _buildSocialIcon(
              FontAwesomeIcons.instagram,
              widget.accommodation.instagram!,
              Color(0xFFE4405F),
            ),
          if (widget.accommodation.facebook != null)
            _buildSocialIcon(
              FontAwesomeIcons.facebook,
              widget.accommodation.facebook!,
              Color(0xFF1877F2),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url, Color color) {
    return IconButton(
      icon: FaIcon(icon, color: color),
      onPressed: () async {
        String formattedUrl = url;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          formattedUrl = 'https://$url';
        }

        try {
          if (await canLaunch(formattedUrl)) {
            await launch(
              formattedUrl,
              forceSafariVC: false,
              forceWebView: false,
              enableJavaScript: true,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppTranslations.translate(
                    'could_not_open_link', _currentLanguage)),
              ),
            );
          }
        } catch (e) {
          print('Error al abrir la URL: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.translate(
                  'error_opening_link', _currentLanguage)),
            ),
          );
        }
      },
    );
  }

  void _openInMaps() async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?q=${widget.accommodation.location.latitude},${widget.accommodation.location.longitude}'
        : 'geo:${widget.accommodation.location.latitude},${widget.accommodation.location.longitude}?q=${widget.accommodation.location.latitude},${widget.accommodation.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppTranslations.translate(
                'could_not_open_maps', _currentLanguage))),
      );
    }
  }

  IconData _getServiceIcon(String service) {
    // Map services to icons based on current language
    final serviceIcons = {
      // Català
      'Wi-Fi': Icons.wifi,
      'Piscina': Icons.pool,
      'Pàrquing': Icons.local_parking,
      'Bar/Cafeteria': Icons.local_bar,
      'Gimnàs': Icons.fitness_center,
      'Spa': Icons.spa,
      'Restaurant': Icons.restaurant,
      'Recepció 24 hores': Icons.access_time,
      'Accés adaptat': Icons.accessible,
      'Accepta mascotes': Icons.pets,
      'Només adults': Icons.person,

      // Español
      'Aparcamiento': Icons.local_parking,
      'Bar/Cafetería': Icons.local_bar,
      'Gimnasio': Icons.fitness_center,
      'Restaurante': Icons.restaurant,
      'Recepción 24 horas': Icons.access_time,
      'Acceso adaptado': Icons.accessible,
      'Acepta mascotas': Icons.pets,
      'Solo adultos': Icons.person,

      // English
      'Pool': Icons.pool,
      'Parking': Icons.local_parking,
      'Gym': Icons.fitness_center,
      '24-hour Reception': Icons.access_time,
      'Accessible': Icons.accessible,
      'Pet-friendly': Icons.pets,
      'Adults only': Icons.person,

      // Français
      'Piscine': Icons.pool,
      'Bar/Cafétéria': Icons.local_bar,
      'Gymnase': Icons.fitness_center,
      'Réception 24 heures': Icons.access_time,
      'Accès adapté': Icons.accessible,
      'Animaux acceptés': Icons.pets,
      'Réservé aux adultes': Icons.person,

      // Deutsch
      'Schwimmbad': Icons.pool,
      'Parkplatz': Icons.local_parking,
      'Bar/Café': Icons.local_bar,
      'Fitnessstudio': Icons.fitness_center,
      '24-Stunden-Rezeption': Icons.access_time,
      'Barrierefrei': Icons.accessible,
      'Haustierfreundlich': Icons.pets,
      'Nur für Erwachsene': Icons.person,
    };

    return serviceIcons[service] ?? Icons.check_circle_outline;
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      setState(() {
        _currentLanguage = language;
      });

      await _apiService.setLanguage(language);

      // Limpiar la caché antes de recargar
      await _taxonomyService.clearCache('tipushotel');
      await _taxonomyService.clearCache('serveishotel');

      // Recargar los datos
      await _loadTaxonomyData();
    }
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final int initialIndex;

  GalleryPhotoViewWrapper({
    required this.galleryItems,
    this.initialIndex = 0,
  });

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions.customChild(
                child: Image.network(
                  widget.galleryItems[index],
                  fit: BoxFit.contain,
                ),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes:
                    PhotoViewHeroAttributes(tag: widget.galleryItems[index]),
              );
            },
            itemCount: widget.galleryItems.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(),
            ),
            pageController: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            backgroundDecoration: BoxDecoration(
              color: Colors.black,
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    "${currentIndex + 1}/${widget.galleryItems.length}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
