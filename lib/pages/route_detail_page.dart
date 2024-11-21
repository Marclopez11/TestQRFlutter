import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route.dart';
import 'package:felanitx/services/taxonomy_service.dart';
import 'package:felanitx/main.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/models/plan_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteModel route;

  const RouteDetailPage({Key? key, required this.route}) : super(key: key);

  @override
  _RouteDetailPageState createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  String _currentLanguage = 'ca';
  final ApiService _apiService = ApiService();
  Map<String, String> _difficultyTerms = {};
  Map<String, String> _circuitTypeTerms = {};
  Map<String, String> _routeTypeTerms = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    _loadTaxonomyTerms();
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

  Future<void> _loadTaxonomyTerms() async {
    final taxonomyService = TaxonomyService();
    _difficultyTerms = await taxonomyService.getTaxonomyTerms('dificultat');
    _circuitTypeTerms = await taxonomyService.getTaxonomyTerms('tipuscircuit');
    _routeTypeTerms = await taxonomyService.getTaxonomyTerms('tipusruta');
    setState(() {}); // Trigger a rebuild after loading the terms
  }

  void _openInMaps() async {
    final url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${widget.route.location.latitude},${widget.route.location.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${widget.route.location.latitude},${widget.route.location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
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
                                          ),
                                          child: child!,
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
                                          child: child!,
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
                                title: widget.route.title,
                                type: 'route',
                                imageUrl: widget.route.mainImage ?? '',
                                plannedDate: plannedDateTime,
                                originalItem: {
                                  'id': widget.route.id,
                                  'type': 'route',
                                  'data': _routeToJson(widget.route),
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
      throw e;
    }
  }

  Map<String, dynamic> _routeToJson(RouteModel route) {
    return {
      'uuid': [
        {'value': route.id}
      ],
      'title': [
        {'value': route.title}
      ],
      'field_route_description': [
        {'value': route.description}
      ],
      'field_route_main_image': [
        {'url': route.mainImage}
      ],
      'field_route_location': [
        {'value': '${route.location.latitude},${route.location.longitude}'}
      ],
      'field_route_distance': [
        {'value': route.distance}
      ],
      'field_route_hour': [
        {'value': route.hours}
      ],
      'field_route_minutes': [
        {'value': route.minutes}
      ],
      'field_route_positive_elevation': [
        {'value': route.positiveElevation}
      ],
      'field_route_negative_elevation': [
        {'value': route.negativeElevation}
      ],
      'field_route_difficulty': [
        {'target_id': route.difficultyId}
      ],
      'field_route_circuit_type': [
        {'target_id': route.circuitTypeId}
      ],
      'field_route_type': [
        {'target_id': route.routeTypeId}
      ],
      'field_route_gpx': route.gpxFile != null
          ? [
              {'url': route.gpxFile}
            ]
          : [],
      'field_route_kml': route.kmlUrl != null
          ? [
              {'url': route.kmlUrl}
            ]
          : [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
        title: Image.asset(
          'assets/images/logo_felanitx.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Image.network(
              widget.route.mainImage ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.route.description,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoItem(
                          Icons.trending_up,
                          '${widget.route.positiveElevation.toStringAsFixed(0)}m',
                          'elevation_gain',
                          Colors.green,
                        ),
                        _buildInfoItem(
                          Icons.trending_down,
                          '${widget.route.negativeElevation.toStringAsFixed(0)}m',
                          'elevation_loss',
                          Colors.red,
                        ),
                        _buildInfoItem(
                          Icons.timer,
                          '${widget.route.hours}h ${widget.route.minutes}min',
                          'duration',
                          Colors.blue,
                        ),
                        _buildInfoItem(
                          Icons.route,
                          '${widget.route.distance.toStringAsFixed(2)} km',
                          'distance',
                          Colors.orange,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(
                          _difficultyTerms[
                                  widget.route.difficultyId.toString()] ??
                              '',
                        ),
                        _buildInfoChip(
                          _circuitTypeTerms[
                                  widget.route.circuitTypeId.toString()] ??
                              '',
                        ),
                        _buildInfoChip(
                          _routeTypeTerms[
                                  widget.route.routeTypeId.toString()] ??
                              '',
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          center: widget.route.location,
                          zoom: 15.0,
                          interactiveFlags: InteractiveFlag.none,
                          minZoom: 3.0,
                          maxZoom: 18.0,
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
                                point: widget.route.location,
                                width: 40,
                                height: 40,
                                builder: (_) => GestureDetector(
                                  onTap: _openInMaps,
                                  child: Image.asset(
                                    widget.route.routeTypeId == 254 ||
                                            widget.route.routeTypeId == 255
                                        ? 'assets/images/marker-icon03.png'
                                        : 'assets/images/marker-icon02.png',
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
                    if (widget.route.kmlUrl != null)
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: OutlinedButton(
                          onPressed: () async {
                            final url = widget.route.kmlUrl!;
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.translate(
                                        'error_opening_kml', _currentLanguage),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, size: 20),
                              SizedBox(width: 8),
                              Text(
                                AppTranslations.translate(
                                    'download_kml', _currentLanguage),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
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
                              Icon(Icons.calendar_today),
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
            ]),
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
            icon: Icon(Icons.calendar_today),
            label: AppTranslations.translate('plan', _currentLanguage),
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

  Widget _buildInfoItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppTranslations.translate(label, _currentLanguage),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String value) {
    return Chip(
      label: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
