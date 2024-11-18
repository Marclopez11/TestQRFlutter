import 'package:flutter/material.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:felanitx/models/category.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/app_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:felanitx/pages/category/agenda_page.dart';
import 'package:felanitx/pages/category/points_of_interest_page.dart';
import 'package:felanitx/pages/category/population_centers_page.dart';
import 'package:felanitx/pages/category/routes_page.dart';
import 'package:felanitx/pages/category/accommodation_page.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/models/banner.dart';
import 'package:felanitx/widgets/banner_carousel.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:felanitx/models/interest.dart';
import 'package:felanitx/widgets/app_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static _HomePageState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    return state;
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  int _currentCarouselIndex = 0;
  List<Category> _apiData = [];
  List<BannerModel> _banners = [];
  late String _currentLanguage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentLanguage = 'ca'; // Default language
    _loadData();
    _subscribeToLanguageChanges();
    _loadBanners();
  }

  @override
  void dispose() {
    _unsubscribeFromLanguageChanges();
    super.dispose();
  }

  void _subscribeToLanguageChanges() {
    ApiService().languageStream.listen((_) {
      _loadData();
      _loadBanners();
    });
  }

  void _unsubscribeFromLanguageChanges() {
    ApiService().languageStream.drain();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadCurrentLanguage();
    }
  }

  Future<void> _loadCurrentLanguage() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    if (mounted && language != _currentLanguage) {
      setState(() {
        _currentLanguage = language;
      });
      // Recargar los datos si el idioma ha cambiado
      await _loadData();
      await _loadBanners();
    }
  }

  Future<void> _loadData() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    final data = await apiService.loadData('categories', language);
    setState(() {
      _apiData = data.map((item) => Category.fromJson(item)).toList();
    });
  }

  Future<void> _loadBanners() async {
    try {
      final apiService = ApiService();
      final language = await apiService.getCurrentLanguage();
      print('Loading banners for language: $language');

      List<BannerModel> allBanners = [];

      // Cargar eventos destacados primero
      final eventData = await apiService.loadData('agenda', language);
      if (eventData is List) {
        print('Events loaded: ${eventData.length}');
        for (var item in eventData) {
          try {
            final event = CalendarEvent.fromJson(item);
            print('Event: ${event.title}');
            print(
                'Featured value in JSON: ${item['field_calendar_featured']?[0]?['value']}');
            print('Featured parsed: ${event.featured}');
            print('Has main image: ${event.mainImage != null}');

            if (event.featured && !event.isExpired && event.mainImage != null) {
              print('Adding featured event to banner: ${event.title}');
              allBanners.add(BannerModel.fromEvent(event));
            }
          } catch (e) {
            print('Error processing event: $e');
          }
        }
        print('Featured events added: ${allBanners.length}');
      }

      // Cargar banners regulares
      final bannerData = await apiService.loadData('banner', language);
      if (bannerData is List) {
        print('Regular banners loaded: ${bannerData.length}');
        allBanners.addAll(
          bannerData.map((item) => BannerModel.fromJson(item)).where(
              (banner) => banner.isActive && banner.langcode == language),
        );
      }

      // Cargar puntos de interés destacados
      final interestData =
          await apiService.loadData('points_of_interest', language);
      if (interestData is List) {
        print('Points of interest loaded: ${interestData.length}');
        final interests = interestData
            .map((item) => Interest.fromJson(item))
            .where((interest) {
          print('Interest ${interest.title} - Featured: ${interest.featured}');
          return interest.featured;
        }).map((interest) => BannerModel.fromInterest(interest));

        allBanners.addAll(interests);
      }

      print('Total banners to display: ${allBanners.length}');
      setState(() {
        _banners = allBanners;
      });
    } catch (e) {
      print('Error loading banners: $e');
    }
  }

  void reloadData() async {
    await _loadCurrentLanguage();
    await _loadData();
    await _loadBanners();
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      final apiService = ApiService();
      await apiService.setLanguage(language);

      setState(() {
        _currentLanguage = language;
      });

      // Recargar los datos con el nuevo idioma
      await _loadData();
      await _loadBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          // Header específico para HomePage
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
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BannerCarousel(banners: _banners),
                  SizedBox(height: 30),
                  _buildItemsGrid(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 15.0,
        mainAxisSpacing: 15.0,
      ),
      itemCount: _apiData.length,
      itemBuilder: (context, index) {
        final category = _apiData[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/${category.page}',
              arguments: category.title,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5.0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                    child: Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
