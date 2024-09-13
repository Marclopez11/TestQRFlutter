import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:felanitx/models/map_item.dart';
import 'package:latlong2/latlong.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MapItem> items = [];
  List<String> categories = [];
  List<MapItem> featuredItems = [];
  int _currentCarouselIndex = 0;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _fetchDataFromAPI();
      fetchItems();
    });
  }

  Future<void> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('itemsData');
    final cachedCategoriesData = prefs.getString('categoriesData');
    final cachedAverageRatings = prefs.getString('averageRatings');

    if (cachedData != null &&
        cachedCategoriesData != null &&
        cachedAverageRatings != null) {
      try {
        final List<dynamic> data = json.decode(cachedData);
        final List<dynamic> categoriesData = json.decode(cachedCategoriesData);
        final List<dynamic> averageRatingsData =
            json.decode(cachedAverageRatings);

        final averageRatings = Map.fromIterable(
          averageRatingsData,
          key: (item) => item['nid'].toString(),
          value: (item) => {
            'average_rating': item['average_rating'].toDouble(),
            'comment_count': item['comment_count'],
          },
        );

        _processData(data, categoriesData, averageRatings);
      } catch (e) {
        print('Error parsing cached data: $e');
      }
    } else {
      setState(() {
        _isLoading = true;
      });
    }
  }

  Future<void> _fetchDataFromAPI() async {
    try {
      final itemsResponse = await http
          .get(Uri.parse('https://felanitx.drupal.auroracities.com/lloc'));
      final categoriesResponse = await http.get(
          Uri.parse('https://felanitx.drupal.auroracities.com/categories'));
      final averageRatingsResponse = await http.get(Uri.parse(
          'https://v5zl55fl4h.execute-api.eu-central-1.amazonaws.com/comment'));

      if (itemsResponse.statusCode == 200 &&
          categoriesResponse.statusCode == 200 &&
          averageRatingsResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(itemsResponse.body);
        final List<dynamic> categoriesData =
            json.decode(categoriesResponse.body);
        final List<dynamic> averageRatingsData =
            json.decode(averageRatingsResponse.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('itemsData', itemsResponse.body);
        await prefs.setString('categoriesData', categoriesResponse.body);
        await prefs.setString('averageRatings', averageRatingsResponse.body);

        final averageRatings = Map.fromIterable(
          averageRatingsData,
          key: (item) => item['nid'].toString(),
          value: (item) => {
            'average_rating': item['average_rating'].toDouble(),
            'comment_count': item['comment_count'],
          },
        );

        _processData(data, categoriesData, averageRatings);
      } else {
        _showErrorAndUseCachedData();
      }
    } catch (e) {
      print('Error fetching data from API: $e');
      _showErrorAndUseCachedData();
    }
  }

  void _showErrorAndUseCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('itemsData');
    final cachedCategoriesData = prefs.getString('categoriesData');
    final cachedAverageRatings = prefs.getString('averageRatings');

    if (cachedData != null &&
        cachedCategoriesData != null &&
        cachedAverageRatings != null) {
      final List<dynamic> data = json.decode(cachedData);
      final List<dynamic> categoriesData = json.decode(cachedCategoriesData);
      final Map<String, dynamic> averageRatings =
          json.decode(cachedAverageRatings);
      _processData(data, categoriesData, averageRatings);
    } else {
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _processData(List<dynamic> data, List<dynamic> categoriesData,
      Map<String, dynamic> averageRatings) {
    Map<int, String> categoryMap = {};
    for (var category in categoriesData) {
      int tid = category['tid'][0]['value'];
      String name = category['name'][0]['value'];
      categoryMap[tid] = name;
    }

    setState(() {
      items = data.map((item) {
        final location = item['field_place_location'][0];
        final image = item['field_place_main_image'][0];
        final categoryId = item['field_place_categoria'][0]['target_id'];
        final featured = item['field_place_featured']?.isNotEmpty == true
            ? item['field_place_featured'][0]['value']
            : false;
        final facebookUrl = item['field_place_facebook']?.isNotEmpty == true
            ? item['field_place_facebook'][0]['value']
            : null;
        final instagramUrl = item['field_place_instagram']?.isNotEmpty == true
            ? item['field_place_instagram'][0]['value']
            : null;
        final twitterUrl = item['field_place_twitter']?.isNotEmpty == true
            ? item['field_place_twitter'][0]['value']
            : null;
        final websiteUrl = item['field_place_web']?.isNotEmpty == true
            ? item['field_place_web'][0]['value']
            : null;
        final whatsappNumber = item['field_place_whatsapp']?.isNotEmpty == true
            ? item['field_place_whatsapp'][0]['value']
            : null;
        final phoneNumber = item['field_place_phone_number']?.isNotEmpty == true
            ? item['field_place_phone_number'][0]['value']
            : null;
        final email = item['field_place_email']?.isNotEmpty == true
            ? item['field_place_email'][0]['value']
            : null;
        final averageRating = averageRatings[item['nid'][0]['value'].toString()]
                ?['average_rating'] ??
            0.0;
        final commentCount = averageRatings[item['nid'][0]['value'].toString()]
                ?['comment_count'] ??
            0;
        return MapItem(
          id: item['nid'][0]['value'].toString(),
          title: item['title'][0]['value'],
          description: item['field_place_description'][0]['value'],
          position: LatLng(
            double.parse(location['lat'].toString()),
            double.parse(location['lng'].toString()),
          ),
          imageUrl: image['url'],
          categoryId: categoryId,
          categoryName: categoryMap[categoryId] ?? 'Unknown',
          averageRating: averageRating,
          featured: featured,
          facebookUrl: facebookUrl,
          instagramUrl: instagramUrl,
          twitterUrl: twitterUrl,
          websiteUrl: websiteUrl,
          whatsappNumber: whatsappNumber,
          phoneNumber: phoneNumber,
          email: email,
          commentCount: commentCount,
        );
      }).toList();

      // Obtener las categorías únicas de los ítems
      categories =
          ['All'] + items.map((item) => item.categoryName).toSet().toList();

      // Select featured items based on the 'featured' property
      featuredItems = items.where((item) => item.featured).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _isLoading
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featuredItems.isNotEmpty) _buildFeaturedSlider(),
                  SizedBox(height: 20),
                  for (var category in categories.where((c) => c != 'All'))
                    _buildCategorySection(category),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 350,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            for (int i = 0; i < 3; i++)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 24,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 200,
                            margin: EdgeInsets.only(left: 20, bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSlider() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 350.0,
            autoPlay: true,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: featuredItems.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(item: item),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8)
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          item.categoryName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      if (item.averageRating > 0)
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      if (item.averageRating > 0)
                                        SizedBox(width: 5),
                                      if (item.averageRating > 0)
                                        Text(
                                          item.averageRating.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (item.commentCount > 0)
                                        SizedBox(width: 5),
                                      if (item.commentCount > 0)
                                        Text(
                                          '(${item.commentCount})',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: featuredItems.asMap().entries.map((entry) {
              return Container(
                width: 10.0,
                height: 10.0,
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(
                        _currentCarouselIndex == entry.key ? 0.9 : 0.4,
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryItems =
        items.where((item) => item.categoryName == category).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  margin: EdgeInsets.only(left: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(15)),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              item.categoryName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 10),
                            if (item.averageRating > 0)
                              _buildAverageRating(
                                  item.averageRating, item.commentCount),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAverageRating(double averageRating, int commentCount) {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 20,
        ),
        SizedBox(width: 4),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '($commentCount)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
