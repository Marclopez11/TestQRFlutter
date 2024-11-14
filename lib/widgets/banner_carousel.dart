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
    final activeBanners =
        widget.banners.where((banner) => banner.isActive).toList();

    if (activeBanners.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 250,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 5),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          onPageChanged: (index, reason) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        items: activeBanners.map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                child: GestureDetector(
                  onTap: () => _handleBannerTap(context, banner),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
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
                              if (banner.type != 'banner') ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      banner.type == 'event'
                                          ? Icons.event
                                          : Icons.place,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      banner.type == 'event'
                                          ? 'Evento'
                                          : 'Punto de interés',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
