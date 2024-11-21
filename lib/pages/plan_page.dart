import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:felanitx/models/plan_item.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:felanitx/pages/route_detail_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:felanitx/models/route.dart';
import 'package:felanitx/models/interest.dart';
import 'package:felanitx/pages/detail/interest_detail_page.dart';
import 'package:felanitx/pages/detail/population_detail_page.dart';
import 'package:felanitx/models/population.dart';
import 'package:felanitx/pages/detail/accommodation_detail_page.dart';
import 'package:felanitx/models/accommodation.dart';
import 'package:felanitx/pages/detail/calendar_detail_page.dart';
import 'package:felanitx/models/calendar_event.dart';

class PlanPage extends StatefulWidget {
  @override
  _PlanPageState createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final ApiService _apiService = ApiService();
  String _currentLanguage = 'ca';
  List<PlanItem> _planItems = [];
  bool _isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Añadir una constante para el límite de items
  static const int MAX_PLAN_ITEMS = 20;

  @override
  void initState() {
    super.initState();
    _initialize();
    _subscribeToLanguageChanges();
  }

  @override
  void dispose() {
    _unsubscribeFromLanguageChanges();
    super.dispose();
  }

  void _subscribeToLanguageChanges() {
    ApiService().languageStream.listen((_) {
      _loadCurrentLanguage();
      _loadPlanItems();
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
      _loadPlanItems();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadCurrentLanguage();
      await _loadPlanItems();
    } catch (e) {
      print('Error in initialization: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final language = await _apiService.getCurrentLanguage();
      if (mounted && language != _currentLanguage) {
        setState(() {
          _currentLanguage = language;
        });
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> _loadPlanItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('plan_items');

      if (itemsJson != null) {
        final List<dynamic> decodedItems = json.decode(itemsJson);
        if (mounted) {
          setState(() {
            _planItems =
                decodedItems.map((item) => PlanItem.fromJson(item)).toList();
            _sortAndUpdateItems();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _planItems = [];
          });
        }
      }
    } catch (e) {
      print('Error loading plan items: $e');
      if (mounted) {
        setState(() {
          _planItems = [];
        });
      }
    }
  }

  Future<void> _savePlanItems() async {
    try {
      // Limitar la cantidad de items
      if (_planItems.length > MAX_PLAN_ITEMS) {
        _planItems = _planItems.take(MAX_PLAN_ITEMS).toList();
      }

      // Limpiar datos innecesarios antes de guardar
      final cleanItems = _planItems.map((item) {
        final cleanItem = {
          'id': item.id,
          'title': item.title,
          'type': item.type,
          'imageUrl': item.imageUrl,
          'plannedDate': item.plannedDate?.toIso8601String(),
          'notes': item.notes,
          // Solo guardar los datos esenciales del originalItem
          'originalItem': {
            'id': item.originalItem['id'],
            'type': item.originalItem['type'],
          },
        };
        return cleanItem;
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('plan_items', json.encode(cleanItems));
    } catch (e) {
      print('Error saving plan items: $e');
      // Mostrar mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.translate('error_saving', _currentLanguage),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlanItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(AppTranslations.translate('confirm_delete', _currentLanguage)),
        content: Text(
            AppTranslations.translate('delete_confirmation', _currentLanguage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppTranslations.translate('cancel', _currentLanguage)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppTranslations.translate('delete', _currentLanguage),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final index = _planItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        setState(() {
          _planItems.removeAt(index);
        });
        await _savePlanItems();

        // Mostrar feedback al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.translate('item_deleted', _currentLanguage),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Extraer el widget del item a un método separado para reutilizarlo
  Widget _buildTimelineItem(PlanItem item) {
    return Container(
      margin: EdgeInsets.only(left: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.plannedDate != null)
                  Text(
                    DateFormat.yMMMd(_currentLanguage)
                        .add_Hm()
                        .format(item.plannedDate!),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.notes?.isNotEmpty == true) ...[
                  SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility),
                      onPressed: () => _openItemDetail(item),
                      color: Theme.of(context).primaryColor,
                    ),
                    if (item.type != 'event') ...[
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editPlanItem(item),
                        color: Colors.blue,
                      ),
                    ],
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deletePlanItem(item.id),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Añadir este nuevo método para manejar la apertura del detalle
  void _openItemDetail(PlanItem item) {
    if (item.type == 'route') {
      final routeData = item.originalItem['data'];
      if (routeData != null) {
        final route = RouteModel(
          id: routeData['uuid'][0]['value'],
          title: routeData['title'][0]['value'],
          description: routeData['field_route_description'][0]['value'],
          mainImage: routeData['field_route_main_image'][0]['url'],
          location: LatLng(
            double.parse(
                routeData['field_route_location'][0]['value'].split(',')[0]),
            double.parse(
                routeData['field_route_location'][0]['value'].split(',')[1]),
          ),
          distance: double.parse(
              routeData['field_route_distance'][0]['value'].toString()),
          hours:
              int.parse(routeData['field_route_hour'][0]['value'].toString()),
          minutes: int.parse(
              routeData['field_route_minutes'][0]['value'].toString()),
          positiveElevation: double.parse(
              routeData['field_route_positive_elevation'][0]['value']
                  .toString()),
          negativeElevation: double.parse(
              routeData['field_route_negative_elevation'][0]['value']
                  .toString()),
          difficultyId: int.parse(
              routeData['field_route_difficulty'][0]['target_id'].toString()),
          circuitTypeId: int.parse(
              routeData['field_route_circuit_type'][0]['target_id'].toString()),
          routeTypeId: int.parse(
              routeData['field_route_type'][0]['target_id'].toString()),
          gpxFile: routeData['field_route_gpx']?.isNotEmpty == true
              ? routeData['field_route_gpx'][0]['url']
              : null,
          kmlUrl: routeData['field_route_kml']?.isNotEmpty == true
              ? routeData['field_route_kml'][0]['url']
              : null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailPage(route: route),
          ),
        );
      }
    } else if (item.type == 'interest') {
      final interestData = item.originalItem['data'];
      if (interestData != null) {
        final interest = Interest(
          id: interestData['uuid'][0]['value'],
          title: interestData['title'][0]['value'],
          description: interestData['field_place_description'][0]['value'],
          address: interestData['field_place_address'][0]['value'],
          location: LatLng(
            double.parse(interestData['field_interest_location'][0]['value']
                .split(',')[0]),
            double.parse(interestData['field_interest_location'][0]['value']
                .split(',')[1]),
          ),
          categoryId: int.parse(
              interestData['field_place_categoria'][0]['target_id'].toString()),
          featured: interestData['field_place_featured'][0]['value'] ?? false,
          imageGallery: (interestData['field_place_image_gallery'] as List)
              .map((img) => img['url'] as String)
              .toList(),
          mainImage: interestData['field_interest_main_image'][0]['url'],
          langcode: _currentLanguage,
          audioUrl: interestData['field_place_audio']?.isNotEmpty == true
              ? interestData['field_place_audio'][0]['url']
              : null,
          facebookUrl: interestData['field_place_facebook']?.isNotEmpty == true
              ? interestData['field_place_facebook'][0]['value']
              : null,
          instagramUrl:
              interestData['field_place_instagram']?.isNotEmpty == true
                  ? interestData['field_place_instagram'][0]['value']
                  : null,
          twitterUrl: interestData['field_place_twitter']?.isNotEmpty == true
              ? interestData['field_place_twitter'][0]['value']
              : null,
          websiteUrl: interestData['field_place_web']?.isNotEmpty == true
              ? interestData['field_place_web'][0]['value']
              : null,
          phoneNumber:
              interestData['field_place_phone_number']?.isNotEmpty == true
                  ? interestData['field_place_phone_number'][0]['value']
                  : null,
          videoUrl: interestData['field_place_video']?.isNotEmpty == true
              ? interestData['field_place_video'][0]['url']
              : null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterestDetailPage(interest: interest),
          ),
        );
      }
    } else if (item.type == 'population') {
      final populationData = item.originalItem['data'];
      if (populationData != null) {
        final population = Population(
          id: populationData['uuid'][0]['value'],
          title: populationData['title'][0]['value'],
          mainImage: populationData['field_population_main_image'][0]['url'],
          location: LatLng(
            double.parse(populationData['field_population_location'][0]['value']
                .split(',')[0]),
            double.parse(populationData['field_population_location'][0]['value']
                .split(',')[1]),
          ),
          title1: populationData['field_population_title1']?.isNotEmpty == true
              ? populationData['field_population_title1'][0]['value']
              : null,
          title2: populationData['field_population_title2']?.isNotEmpty == true
              ? populationData['field_population_title2'][0]['value']
              : null,
          title3: populationData['field_population_title3']?.isNotEmpty == true
              ? populationData['field_population_title3'][0]['value']
              : null,
          description1:
              populationData['field_population_description1']?.isNotEmpty ==
                      true
                  ? populationData['field_population_description1'][0]['value']
                  : null,
          description2:
              populationData['field_population_description2']?.isNotEmpty ==
                      true
                  ? populationData['field_population_description2'][0]['value']
                  : null,
          description3:
              populationData['field_population_description3']?.isNotEmpty ==
                      true
                  ? populationData['field_population_description3'][0]['value']
                  : null,
          imageGallery:
              populationData['field_population_image_gallery']?.isNotEmpty ==
                      true
                  ? List<String>.from(
                      populationData['field_population_image_gallery']
                          .map((img) => img['url']))
                  : [],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PopulationDetailPage(population: population),
          ),
        );
      }
    } else if (item.type == 'accommodation') {
      final accommodationData = item.originalItem['data'];
      if (accommodationData != null) {
        final accommodation = Accommodation(
          id: accommodationData['uuid'][0]['value'],
          title: accommodationData['title'][0]['value'],
          description: accommodationData['field_hotel_description'][0]['value'],
          mainImage: accommodationData['field_hotel_main_image'][0]['url'],
          location: LatLng(
            double.parse(accommodationData['field_hotel_location'][0]['value']
                .split(',')[0]),
            double.parse(accommodationData['field_hotel_location'][0]['value']
                .split(',')[1]),
          ),
          hotelType: int.parse(accommodationData['field_hotel_hoteltype'][0]
                  ['target_id']
              .toString()),
          hotelServices:
              accommodationData['field_hotel_hotelservices']?.isNotEmpty == true
                  ? List<int>.from(
                      accommodationData['field_hotel_hotelservices']
                          .map((service) => service['target_id']))
                  : [],
          web: accommodationData['field_hotel_web']?.isNotEmpty == true
              ? accommodationData['field_hotel_web'][0]['value']
              : null,
          twitter: accommodationData['field_hotel_twitter']?.isNotEmpty == true
              ? accommodationData['field_hotel_twitter'][0]['value']
              : null,
          instagram:
              accommodationData['field_hotel_instagram']?.isNotEmpty == true
                  ? accommodationData['field_hotel_instagram'][0]['value']
                  : null,
          facebook:
              accommodationData['field_hotel_facebook']?.isNotEmpty == true
                  ? accommodationData['field_hotel_facebook'][0]['value']
                  : null,
          address: accommodationData['field_hotel_address'][0]['value'],
          phoneNumber: accommodationData['field_hotel_phone_number'][0]
              ['value'],
          phoneNumber2:
              accommodationData['field_hotel_phone_number2']?.isNotEmpty == true
                  ? accommodationData['field_hotel_phone_number2'][0]['value']
                  : null,
          email: accommodationData['field_hotel_email']?.isNotEmpty == true
              ? accommodationData['field_hotel_email'][0]['value']
              : '',
          imageGallery:
              accommodationData['field_hotel_image_gallery']?.isNotEmpty == true
                  ? List<String>.from(
                      accommodationData['field_hotel_image_gallery']
                          .map((image) => image['url']))
                  : [],
          stars: accommodationData['field_hotel_stars']?.isNotEmpty == true
              ? accommodationData['field_hotel_stars'][0]['value']
              : null,
          categoryId: int.parse(accommodationData['field_hotel_hoteltype'][0]
                  ['target_id']
              .toString()),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AccommodationDetailPage(accommodation: accommodation),
          ),
        );
      }
    } else if (item.type == 'event') {
      final eventData = item.originalItem['data'];
      if (eventData != null) {
        final event = CalendarEvent(
          title: eventData['title'][0]['value'],
          date: DateTime.parse(eventData['field_calendar_date'][0]['value']),
          mainImage: eventData['field_calendar_main_image']?.isNotEmpty == true
              ? eventData['field_calendar_main_image'][0]['url']
              : null,
          location: eventData['field_calendar_location']?.isNotEmpty == true
              ? LatLng(
                  double.parse(eventData['field_calendar_location'][0]['value']
                      .split(',')[0]),
                  double.parse(eventData['field_calendar_location'][0]['value']
                      .split(',')[1]),
                )
              : null,
          imageGallery:
              eventData['field_calendar_image_gallery']?.isNotEmpty == true
                  ? List<String>.from(eventData['field_calendar_image_gallery']
                      .map((img) => img['url']))
                  : [],
          longDescription:
              eventData['field_calendar_description']?.isNotEmpty == true
                  ? eventData['field_calendar_description'][0]['value']
                  : '',
          shortDescription:
              eventData['field_calendar_short_description']?.isNotEmpty == true
                  ? eventData['field_calendar_short_description'][0]['value']
                  : '',
          link: eventData['field_calendar_link']?.isNotEmpty == true
              ? eventData['field_calendar_link'][0]['value']
              : '',
          langcode: eventData['langcode']?[0]?['value'] ?? _currentLanguage,
          featured: eventData['field_calendar_featured']?[0]?['value'] ?? false,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarDetailPage(event: event),
          ),
        );
      }
    }
    // Aquí puedes añadir más casos para otros tipos de items
  }

  // Add this method to sort plan items
  void _sortPlanItems() {
    _planItems.sort((a, b) => (a.plannedDate ?? DateTime.now())
        .compareTo(b.plannedDate ?? DateTime.now()));
  }

  Future<void> _editPlanItem(PlanItem item) async {
    DateTime selectedDate = item.plannedDate ?? DateTime.now();
    TimeOfDay selectedTime = item.plannedDate != null
        ? TimeOfDay.fromDateTime(item.plannedDate!)
        : TimeOfDay.now();
    String notes = item.notes ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Theme(
              data: Theme.of(context).copyWith(
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                            'edit_plan', _currentLanguage),
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
                            // Date picker
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                            // ... (same date picker theme as in population_detail_page)
                                            ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setModalState(() => selectedDate = date);
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
                                          color: Theme.of(context).primaryColor,
                                          size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        DateFormat.yMMMd(_currentLanguage)
                                            .format(selectedDate),
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Time picker
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
                                            // ... (same time picker theme as in population_detail_page)
                                            ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setModalState(() => selectedTime = time);
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
                                          color: Theme.of(context).primaryColor,
                                          size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        selectedTime.format(context),
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
                        onPressed: () {
                          final DateTime combinedDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          setState(() {
                            final index =
                                _planItems.indexWhere((i) => i.id == item.id);
                            if (index != -1) {
                              _planItems[index] = item.copyWith(
                                plannedDate: combinedDateTime,
                                notes: notes,
                              );
                              _sortPlanItems(); // Sort items after updating
                            }
                          });

                          _savePlanItems();
                          Navigator.pop(context);
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
                          AppTranslations.translate('save', _currentLanguage),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header simplificado
            Container(
              height: 60,
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 16),
              margin: EdgeInsets.only(bottom: 8),
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
            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _planItems.isEmpty
                      ? _buildEmptyState()
                      : _buildTimelineList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      await _apiService.setLanguage(language);

      if (mounted) {
        setState(() {
          _currentLanguage = language;
        });
        await _loadPlanItems(); // Recargar los items para actualizar el formato de las fechas
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              AppTranslations.translate('no_saved_items', _currentLanguage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppTranslations.translate('start_adding', _currentLanguage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _planItems.length,
      itemBuilder: (context, index) {
        final item = _planItems[index];
        final isFirst = index == 0;
        final isLast = index == _planItems.length - 1;

        return TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
          beforeLineStyle: LineStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          endChild: _buildTimelineItem(item),
        );
      },
    );
  }

  void _sortAndUpdateItems() {
    setState(() {
      _planItems.sort((a, b) => (a.plannedDate ?? DateTime.now())
          .compareTo(b.plannedDate ?? DateTime.now()));
    });
  }
}
