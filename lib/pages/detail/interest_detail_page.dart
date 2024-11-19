import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:felanitx/models/interest.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:felanitx/main.dart';

class InterestDetailPage extends StatefulWidget {
  final Interest interest;

  const InterestDetailPage({Key? key, required this.interest})
      : super(key: key);

  @override
  _InterestDetailPageState createState() => _InterestDetailPageState();
}

class _InterestDetailPageState extends State<InterestDetailPage> {
  int _currentImageIndex = 0;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  bool _isDescriptionExpanded = false;
  bool _isVideoControlsVisible = true;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.interest.videoUrl != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.interest.videoUrl!);
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
    }
    _audioPlayer.stop();
    _audioPlayer.dispose();
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
                  widget.interest.mainImage,
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
                        widget.interest.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Categoría ${widget.interest.categoryId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.interest.imageGallery.isNotEmpty)
                  _buildImageCarousel(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExpandableDescription(),
                      if (_hasSocialLinks) ...[
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.interest.websiteUrl != null)
                              _buildSocialButton(
                                FontAwesomeIcons.globe,
                                widget.interest.websiteUrl!,
                                Colors.blue,
                              ),
                            if (widget.interest.twitterUrl != null)
                              _buildSocialButton(
                                FontAwesomeIcons.twitter,
                                widget.interest.twitterUrl!,
                                Color(0xFF1DA1F2),
                              ),
                            if (widget.interest.instagramUrl != null)
                              _buildSocialButton(
                                FontAwesomeIcons.instagram,
                                widget.interest.instagramUrl!,
                                Color(0xFFE4405F),
                              ),
                            if (widget.interest.facebookUrl != null)
                              _buildSocialButton(
                                FontAwesomeIcons.facebook,
                                widget.interest.facebookUrl!,
                                Color(0xFF1877F2),
                              ),
                          ],
                        ),
                      ],
                      SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            center: widget.interest.location,
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
                                  point: widget.interest.location,
                                  width: 40,
                                  height: 40,
                                  builder: (_) => Image.asset(
                                    'assets/images/marker-icon01.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.interest.address,
                        style: TextStyle(fontSize: 16),
                      ),
                      if (widget.interest.videoUrl != null) _buildVideoPlayer(),
                      if (widget.interest.audioUrl != null) _buildAudioPlayer(),
                      SizedBox(height: 24),
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

  Widget _buildImageCarousel() {
    final List<String> images = widget.interest.imageGallery.isNotEmpty
        ? widget.interest.imageGallery
        : [widget.interest.mainImage];

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
          items: images.map((imageUrl) {
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
          children: images.asMap().entries.map((entry) {
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

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: widget.interest.imageGallery.isNotEmpty
              ? widget.interest.imageGallery
              : [widget.interest.mainImage],
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String url, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 24),
        onPressed: () async {
          if (await canLaunch(url)) {
            await launch(url);
          }
        },
      ),
    );
  }

  void _openInMaps() async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?q=${widget.interest.location.latitude},${widget.interest.location.longitude}'
        : 'geo:${widget.interest.location.latitude},${widget.interest.location.longitude}?q=${widget.interest.location.latitude},${widget.interest.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la aplicación de mapas')),
      );
    }
  }

  void _shareContent() {
    Share.share(
      'Mira este lugar interesante: ${widget.interest.title}\n\nhttps://www.google.com/maps/dir/?api=1&destination=${widget.interest.location.latitude},${widget.interest.location.longitude}',
      subject: widget.interest.title,
    );
  }

  bool get _hasSocialLinks =>
      widget.interest.facebookUrl != null ||
      widget.interest.instagramUrl != null ||
      widget.interest.twitterUrl != null ||
      widget.interest.websiteUrl != null;

  Widget _buildExpandableDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.interest.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
          maxLines: _isDescriptionExpanded ? null : 8,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.interest.description.length > 500)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Ver menos' : 'Ver más',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 24),
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              _VideoControls(controller: _videoController!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(
                  UrlSource(widget.interest.audioUrl!),
                );
              }
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
          SizedBox(width: 16),
          Text(
            _isPlaying ? 'Reproduciendo...' : 'Reproducir audio',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
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

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({Key? key, required this.controller}) : super(key: key);

  @override
  __VideoControlsState createState() => __VideoControlsState();
}

class __VideoControlsState extends State<_VideoControls> {
  bool _hideControls = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hideControls = !_hideControls;
        });
      },
      child: AnimatedOpacity(
        opacity: _hideControls ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        if (widget.controller.value.isPlaying) {
                          widget.controller.pause();
                        } else {
                          widget.controller.play();
                        }
                      });
                    },
                  ),
                ],
              ),
              VideoProgressIndicator(
                widget.controller,
                allowScrubbing: true,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
