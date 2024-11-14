import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:felanitx/models/banner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:felanitx/pages/calendar_detail_page.dart';
import 'package:felanitx/pages/interest_detail_page.dart';
import 'package:felanitx/models/map_item.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const BannerCarousel({Key? key, required this.banners}) : super(key: key);

  @override
  _BannerCarouselState createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;

  void _handleBannerTap(BuildContext context, BannerModel banner) async {
    print('Banner tapped - Type: ${banner.type}');

    switch (banner.type) {
      case 'banner':
        if (banner.webLink != null) {
          print('Opening banner link: ${banner.webLink}');
          if (await canLaunch(banner.webLink!)) {
            await launch(banner.webLink!);
          }
        }
        break;

      case 'interest':
        print('Opening interest detail');
        if (banner.originalInterest != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterestDetailPage(
                interest: banner.originalInterest!,
              ),
            ),
          );
        }
        break;

      case 'event':
        print('Opening calendar detail');
        if (banner.originalEvent != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarDetailPage(
                event: banner.originalEvent!,
              ),
            ),
          );
        }
        break;

      default:
        print('Unknown banner type: ${banner.type}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBanners = widget.banners;
    final activeBanners = widget.banners.where((banner) {
      final isActive = banner.isActive;
      print('Banner "${banner.title}":');
      print('- Type: ${banner.type}');
      print('- Is Published: ${banner.isPublished}');
      print('- Is Expired: ${banner.isExpired}');
      print('- Publication Date: ${banner.publicationDate}');
      print('- Expiration Date: ${banner.expirationDate}');
      print('- Is Active: $isActive');
      print('---');
      return isActive;
    }).toList();

    print('BannerCarousel - Total banners: ${allBanners.length}');
    print('BannerCarousel - Active banners: ${activeBanners.length}');
    print(
        'BannerCarousel - Inactive banners: ${allBanners.length - activeBanners.length}');

    if (activeBanners.isEmpty) {
      print('BannerCarousel - No active banners to display');
      return SizedBox.shrink();
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: activeBanners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _handleBannerTap(context, banner),
                  child: Stack(
                    children: [
                      Image.network(
                        banner.imageUrl,
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading banner image: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Text(
                            banner.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
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
            );
          }).toList(),
        ),
        if (activeBanners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: activeBanners.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .primaryColor
                      .withOpacity(_currentIndex == entry.key ? 0.9 : 0.4),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
