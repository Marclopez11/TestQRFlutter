import 'package:flutter/material.dart';
import 'package:felanitx/pages/item_detail_page.dart';
import 'package:felanitx/models/map_item.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/app_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:felanitx/pages/agenda_page.dart';
import 'package:felanitx/pages/points_of_interest_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentCarouselIndex = 0;

  final List<MapItem> featuredItems = [
    MapItem(
      id: '1',
      title: 'Can Cabestre',
      description:
          'Can Cabestre és un edifici històric situat al centre de Felanitx, construït al segle XIX i que destaca per la seva arquitectura tradicional mallorquina',
      position: LatLng(0, 0),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/Can%20Cabestre.jpg',
      categoryId: 1,
      categoryName: 'Llocs d\'interès',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '2',
      title: 'Mercat de Felanitx',
      description:
          'El Mercat de Felanitx és un mercat situat al centre de la ciutat, construït en 1928 i que destaca per la seva arquitectura noucentista. Actualment, acull diverses botigues i serveis locals, convertint-se en un punt de trobada per a la població.',
      position: LatLng(0, 0),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/mercat.jpg',
      categoryId: 1,
      categoryName: 'Llocs d\'interès',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '3',
      title: 'Església de Sant Miquel',
      description:
          'L\'església parroquial de Sant Miquel és un dels edificis més emblemàtics de Felanitx. Construïda al segle XIII i reformada posteriorment als segles XVI i XVII, destaca per la seva arquitectura gòtica i el seu campanar, que domina l\'skyline de la ciutat. A l\'interior es poden admirar diverses obres d\'art religiós i retaules d\'gran valor històric.',
      position: LatLng(0, 0),
      imageUrl:
          'https://felanitx.drupal.auroracities.com/sites/default/files/2024-09/forner.jpg',
      categoryId: 1,
      categoryName: 'Llocs d\'interès',
      averageRating: 0.0,
      commentCount: 0,
    ),
  ];

  final List<MapItem> items = [
    MapItem(
      id: '1',
      title: 'Agenda',
      description: 'Descripción de Agenda',
      position: LatLng(0, 0),
      imageUrl: 'https://viufelanitx.com/upload/images/07_2019/6121_20074.jpg',
      categoryId: 1,
      categoryName: 'Agenda',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '2',
      title: 'Núcleos de población',
      description: 'Descripción de Núcleos de población',
      position: LatLng(0, 0),
      imageUrl:
          'https://mallorcatechnews.com/wp-content/uploads/2021/10/The-Balearic-Islands-has-a-new-app-to-manage-regional-taxes.jpg',
      categoryId: 2,
      categoryName: 'Núcleos de población',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '3',
      title: 'Puntos de interés',
      description: 'Descripción de Puntos de interés',
      position: LatLng(0, 0),
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTgvT-lRIgddrFNmwjqoshFPVLn7mymV6FJhnu32OqA7OwDaFcy',
      categoryId: 3,
      categoryName: 'Llocs d\'interès',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '4',
      title: 'Ruta a pie y en bicicleta',
      description: 'Descripción de Ruta a pie y en bicicleta',
      position: LatLng(0, 0),
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjicIRYcdF50zOaUDwG2OwQoJsOV-bp3TjOnysntVNitE97FMv',
      categoryId: 4,
      categoryName: 'Ruta a pie y en bicicleta',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '5',
      title: '¿Donde dormir?',
      description: 'Descripción de ¿Donde dormir?',
      position: LatLng(0, 0),
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcReL435y3O4mq7XJz79AWnJvR3PNp-eKM-ugaNOIEZrKnAU2p6Y',
      categoryId: 5,
      categoryName: '¿Donde dormir?',
      averageRating: 0.0,
      commentCount: 0,
    ),
    MapItem(
      id: '6',
      title: '¿Donde comer?',
      description: 'Descripción de ¿Donde comer?',
      position: LatLng(0, 0),
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqXuNGUOLOsoE2uthWKeL5k6exEp9iMPDqy-v3wkswM3-e-Lxx',
      categoryId: 6,
      categoryName: '¿Donde comer?',
      averageRating: 0.0,
      commentCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedSlider(),
            SizedBox(height: 30),
            _buildItemsGrid(),
            SizedBox(height: 20),
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (item.title == 'Agenda') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgendaPage(),
                ),
              );
            } else if (item.title == 'Puntos de interés') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PointsOfInterestPage(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailPage(item: item),
                ),
              );
            }
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
                      item.imageUrl,
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
                        item.title,
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
