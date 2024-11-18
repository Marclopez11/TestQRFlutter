import 'dart:io';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:felanitx/models/population.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:felanitx/main.dart';

class PopulationDetailPage extends StatefulWidget {
  final Population population;

  const PopulationDetailPage({Key? key, required this.population})
      : super(key: key);

  @override
  _PopulationDetailPageState createState() => _PopulationDetailPageState();
}

class _PopulationDetailPageState extends State<PopulationDetailPage> {
  int _currentImageIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
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
                onPressed: _shareContent,
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
                  widget.population.mainImage,
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
                        widget.population.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      if (widget.population.imageGallery.isNotEmpty) ...[
                        _buildImageGallery(),
                        SizedBox(height: 24),
                      ],
                      _buildDescriptionSection(),
                      SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            center: widget.population.location,
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
                                  point: widget.population.location,
                                  width: 40,
                                  height: 40,
                                  builder: (_) => GestureDetector(
                                    onTap: _openInMaps,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(20),
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
                                Text('Guardar a mi plan de viaje'),
                                SizedBox(width: 8),
                                Icon(Icons.bookmark),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Cámara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
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
    if (widget.population.imageGallery.isEmpty) return SizedBox.shrink();

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
          items: widget.population.imageGallery.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _openGallery(context),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.population.imageGallery.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(horizontal: 4.0),
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

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.population.title1 != null) ...[
          Text(
            widget.population.title1!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8),
          if (widget.population.description1 != null)
            Text(
              widget.population.description1!,
              style: TextStyle(fontSize: 16),
            ),
          SizedBox(height: 24),
        ],
        if (widget.population.title2 != null) ...[
          Text(
            widget.population.title2!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8),
          if (widget.population.description2 != null)
            Text(
              widget.population.description2!,
              style: TextStyle(fontSize: 16),
            ),
          SizedBox(height: 24),
        ],
        if (widget.population.title3 != null) ...[
          Text(
            widget.population.title3!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8),
          if (widget.population.description3 != null)
            Text(
              widget.population.description3!,
              style: TextStyle(fontSize: 16),
            ),
        ],
      ],
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: widget.population.imageGallery,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  void _shareContent() {
    Share.share(
      'Mira este lugar interesante: ${widget.population.title}\n\nhttps://www.google.com/maps/dir/?api=1&destination=${widget.population.location.latitude},${widget.population.location.longitude}',
      subject: widget.population.title,
    );
  }

  void _openInMaps() async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${widget.population.location.latitude},${widget.population.location.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${widget.population.location.latitude},${widget.population.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la aplicación de mapas')),
      );
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
