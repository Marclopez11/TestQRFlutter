import 'package:flutter/material.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:felanitx/main.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:felanitx/pages/category/agenda_page.dart';
import 'package:felanitx/models/plan_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarDetailPage extends StatefulWidget {
  final CalendarEvent event;

  const CalendarDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  _CalendarDetailPageState createState() => _CalendarDetailPageState();
}

class _CalendarDetailPageState extends State<CalendarDetailPage> {
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  String _currentLanguage = 'ca';
  final ApiService _apiService = ApiService();
  bool _isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadCurrentLanguage();
  }

  Future<void> _initializeLocale() async {
    final localeMap = {
      'es': 'es_ES',
      'ca': 'ca_ES',
      'en': 'en_US',
      'fr': 'fr_FR',
      'de': 'de_DE',
    };

    await initializeDateFormatting(localeMap[_currentLanguage] ?? 'es_ES');
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentLanguage() async {
    setState(() {
      _isLoadingLanguage = true;
    });

    try {
      final language = await _apiService.getCurrentLanguage();
      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _isLoadingLanguage = false;
        });
      }
    } catch (e) {
      print('Error loading language: $e');
      if (mounted) {
        setState(() {
          _isLoadingLanguage = false;
        });
      }
    }
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      setState(() {
        _currentLanguage = language;
      });
      await _apiService.setLanguage(language);
      await _initializeLocale();

      // Notificar a HomePage del cambio de idioma
      if (mounted) {
        final homePage = HomePage.of(context);
        homePage?.reloadData();
      }
    }
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
              onPressed: () {
                // Simplemente volver atrás
                Navigator.of(context).pop();

                // Opcional: Recargar los datos de la página anterior si es necesario
                if (mounted) {
                  final homePage = HomePage.of(context);
                  homePage?.reloadData();
                }
              },
            ),
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
                if (widget.event.mainImage != null)
                  Image.network(
                    widget.event.mainImage!,
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
                        widget.event.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMMM yyyy', widget.event.langcode)
                                .format(widget.event.date),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.event.imageGallery.isNotEmpty) _buildImageGallery(),
                if (widget.event.longDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.longDescription,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          maxLines: _isDescriptionExpanded ? null : 8,
                          overflow: _isDescriptionExpanded
                              ? null
                              : TextOverflow.ellipsis,
                        ),
                        if (widget.event.longDescription.length > 500)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              _isDescriptionExpanded ? 'Ver menos' : 'Ver más',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (widget.event.location != null)
                  SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        center: widget.event.location,
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
                              point: widget.event.location!,
                              width: 40,
                              height: 40,
                              builder: (_) => Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (widget.event.link.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _launchURL(widget.event.link),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppTranslations.translate(
                                  'see_more_info', _currentLanguage),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.open_in_new),
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final planItem = PlanItem(
                            title: widget.event.title,
                            type: 'event',
                            imageUrl: widget.event.mainImage ?? '',
                            plannedDate: widget.event.date,
                            originalItem: {
                              'type': 'event',
                              'data': {
                                'title': [
                                  {'value': widget.event.title}
                                ],
                                'field_calendar_main_image':
                                    widget.event.mainImage != null
                                        ? [
                                            {'url': widget.event.mainImage}
                                          ]
                                        : [],
                                'field_calendar_location':
                                    widget.event.location != null
                                        ? [
                                            {
                                              'value':
                                                  '${widget.event.location!.latitude},${widget.event.location!.longitude}'
                                            }
                                          ]
                                        : [],
                                'field_calendar_date': [
                                  {'value': widget.event.date.toIso8601String()}
                                ],
                                'field_calendar_description': [
                                  {'value': widget.event.longDescription}
                                ],
                                'field_calendar_short_description': [
                                  {'value': widget.event.shortDescription}
                                ],
                                'field_calendar_link':
                                    widget.event.link.isNotEmpty
                                        ? [
                                            {'value': widget.event.link}
                                          ]
                                        : [],
                                'field_calendar_image_gallery': widget
                                    .event.imageGallery
                                    .map((url) => {'url': url})
                                    .toList(),
                                'field_calendar_featured': [
                                  {'value': widget.event.featured}
                                ],
                                'langcode': [
                                  {'value': widget.event.langcode}
                                ],
                              }
                            },
                          );

                          await _savePlanItem(planItem);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.translate(
                                    'saved_to_plan', _currentLanguage),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          print('Error saving plan item: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.translate(
                                    'error_saving', _currentLanguage),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
          items: widget.event.imageGallery.map((imageUrl) {
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
          children: widget.event.imageGallery.asMap().entries.map((entry) {
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
          galleryItems: widget.event.imageGallery,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _savePlanItem(PlanItem newItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('plan_items') ?? '[]';
      final List<dynamic> items = json.decode(itemsJson);

      items.add(newItem.toJson());
      await prefs.setString('plan_items', json.encode(items));
    } catch (e) {
      print('Error saving plan item: $e');
      throw e;
    }
  }
}

// GalleryPhotoViewWrapper widget (igual que en AccommodationDetailPage)

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final int initialIndex;

  GalleryPhotoViewWrapper({
    required this.galleryItems,
    this.initialIndex = 0,
  });

  @override
  State<StatefulWidget> createState() => _GalleryPhotoViewWrapperState();
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
