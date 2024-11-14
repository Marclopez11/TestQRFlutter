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
import 'package:felanitx/pages/category/restaurants_page.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/models/banner.dart';
import 'package:felanitx/widgets/banner_carousel.dart';

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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
      _loadData();
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

      final data = await apiService.loadData('banner', language);
      print('Banner data received: $data');

      if (data != null && data is List) {
        final loadedBanners = data
            .map((item) {
              try {
                return BannerModel.fromJson(item);
              } catch (e) {
                print('Error parsing banner item: $e');
                print('Problematic banner data: $item');
                return null;
              }
            })
            .whereType<BannerModel>()
            .where((banner) {
              final isCorrectLanguage = banner.langcode == language;
              final isNotExpired = !banner.isExpired;
              final isPublished = banner.isPublished;

              print(
                  'Banner ${banner.id} - Language: ${banner.langcode}, Current: $language');
              print(
                  'Banner ${banner.id} - Expired: ${banner.isExpired}, Published: ${banner.isPublished}');

              return isCorrectLanguage && isNotExpired && isPublished;
            })
            .toList();

        print('Number of banners loaded: ${loadedBanners.length}');
        print(
            'Active banners: ${loadedBanners.where((b) => b.isActive).length}');

        loadedBanners.forEach((banner) {
          print('Banner ID: ${banner.id}');
          print('Banner Title: ${banner.title}');
          print('Banner Language: ${banner.langcode}');
          print('Banner Image URL: ${banner.imageUrl}');
          print('Banner Web Link: ${banner.webLink}');
          print('Banner Expiration: ${banner.expirationDate}');
          print('Banner Publication: ${banner.publicationDate}');
          print('Banner is Active: ${banner.isActive}');
          print('---');
        });

        setState(() {
          _banners = loadedBanners;
        });
      } else {
        print('Error: Banner data is not a List or is null');
        print('Received data type: ${data.runtimeType}');
      }
    } catch (e, stackTrace) {
      print('Error loading banners: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void reloadData() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
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
