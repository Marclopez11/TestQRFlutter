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
import 'package:felanitx/l10n/app_translations.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:felanitx/models/plan_item.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  String _currentLanguage = 'ca';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCurrentLanguage();
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
                                    child: Image.asset(
                                      'assets/images/marker-icon05.png',
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
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _showAddToPlanModal,
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
      '${AppTranslations.translate('look_interesting_place', _currentLanguage)}: ${widget.population.title}\n\nhttps://www.google.com/maps/dir/?api=1&destination=${widget.population.location.latitude},${widget.population.location.longitude}',
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
        SnackBar(
          content: Text(AppTranslations.translate(
              'could_not_open_maps', _currentLanguage)),
        ),
      );
    }
  }

  void _showAddToPlanModal() async {
    final now = DateTime.now();
    DateTime selectedDate = now;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(now);

    await initializeDateFormatting(_currentLanguage);
    final dateFormat = DateFormat.yMMMd(_currentLanguage);

    String _formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: Theme.of(context).copyWith(
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Localizations.override(
                context: context,
                locale: Locale(_currentLanguage),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          AppTranslations.translate(
                              'add_to_plan', _currentLanguage),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                      locale: Locale(_currentLanguage),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Theme.of(context)
                                                  .primaryColor,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: Colors.black,
                                            ),
                                            textButtonTheme:
                                                TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .primaryColor,
                                              ),
                                            ),
                                            dialogTheme: DialogTheme(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            datePickerTheme:
                                                DatePickerThemeData(
                                              backgroundColor: Colors.white,
                                              headerBackgroundColor:
                                                  Theme.of(context)
                                                      .primaryColor,
                                              headerForegroundColor:
                                                  Colors.white,
                                              weekdayStyle: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                              dayStyle: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                              todayBackgroundColor:
                                                  MaterialStateProperty.all(
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                              ),
                                              todayForegroundColor:
                                                  MaterialStateProperty.all(
                                                Theme.of(context).primaryColor,
                                              ),
                                              dayBackgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith(
                                                (states) {
                                                  if (states.contains(
                                                      MaterialState.selected)) {
                                                    return Theme.of(context)
                                                        .primaryColor;
                                                  }
                                                  return null;
                                                },
                                              ),
                                              dayForegroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith(
                                                (states) {
                                                  if (states.contains(
                                                      MaterialState.selected)) {
                                                    return Colors.white;
                                                  }
                                                  return null;
                                                },
                                              ),
                                              surfaceTintColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                          child: Localizations.override(
                                            context: context,
                                            locale: Locale(_currentLanguage),
                                            child: child!,
                                          ),
                                        );
                                      },
                                    );
                                    if (date != null) {
                                      setState(() => selectedDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          dateFormat.format(selectedDate),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            timePickerTheme:
                                                TimePickerThemeData(
                                              backgroundColor: Colors.white,
                                              hourMinuteShape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              dayPeriodShape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              dayPeriodColor: MaterialStateColor
                                                  .resolveWith((states) =>
                                                      states
                                                              .contains(
                                                                  MaterialState
                                                                      .selected)
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                          : Colors
                                                              .grey.shade200),
                                              dayPeriodTextColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          states.contains(
                                                                  MaterialState
                                                                      .selected)
                                                              ? Colors.white
                                                              : Colors.black),
                                              hourMinuteColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          states.contains(
                                                                  MaterialState
                                                                      .selected)
                                                              ? Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                              : Colors.grey
                                                                  .shade200),
                                              hourMinuteTextColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          states.contains(
                                                                  MaterialState
                                                                      .selected)
                                                              ? Colors.white
                                                              : Colors.black),
                                              dialHandColor: Theme.of(context)
                                                  .primaryColor,
                                              dialBackgroundColor:
                                                  Colors.grey.shade200,
                                              hourMinuteTextStyle: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              dayPeriodTextStyle: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              helpTextStyle: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              dialTextColor: MaterialStateColor
                                                  .resolveWith((states) =>
                                                      states.contains(
                                                              MaterialState
                                                                  .selected)
                                                          ? Colors.white
                                                          : Colors.black),
                                              entryModeIconColor:
                                                  Theme.of(context)
                                                      .primaryColor,
                                            ),
                                            textButtonTheme:
                                                TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .primaryColor,
                                              ),
                                            ),
                                          ),
                                          child: Localizations.override(
                                            context: context,
                                            locale: Locale(_currentLanguage),
                                            child: MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                alwaysUse24HourFormat: true,
                                              ),
                                              child: child!,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      setState(() => selectedTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          _formatTime(selectedTime),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final DateTime plannedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              final planItem = PlanItem(
                                title: widget.population.title,
                                type: 'population',
                                imageUrl: widget.population.mainImage,
                                plannedDate: plannedDateTime,
                                originalItem: {
                                  'id': widget.population.id,
                                  'type': 'population',
                                  'data': _populationToJson(widget.population),
                                },
                              );

                              await _savePlanItem(planItem);
                              Navigator.pop(context);

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
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppTranslations.translate(
                                'save_to_plan', _currentLanguage),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    }
  }

  Map<String, dynamic> _populationToJson(Population population) {
    return {
      'uuid': [
        {'value': population.id}
      ],
      'title': [
        {'value': population.title}
      ],
      'field_population_main_image': [
        {'url': population.mainImage}
      ],
      'field_population_location': [
        {
          'value':
              '${population.location.latitude},${population.location.longitude}'
        }
      ],
    };
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
