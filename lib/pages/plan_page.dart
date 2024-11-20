import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:felanitx/models/plan_item.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:felanitx/l10n/app_translations.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:timeline_tile/timeline_tile.dart';

class PlanPage extends StatefulWidget {
  @override
  _PlanPageState createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final ApiService _apiService = ApiService();
  String _currentLanguage = 'ca';
  List<PlanItem> _planItems = [];
  bool _isLoading = true;

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
    }
  }

  Future<void> _initialize() async {
    await _loadCurrentLanguage();
    await _loadPlanItems();
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
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('plan_items');

      if (itemsJson != null) {
        final List<dynamic> decodedItems = json.decode(itemsJson);
        setState(() {
          _planItems = decodedItems
              .map((item) => PlanItem.fromJson(item))
              .toList()
            ..sort((a, b) => (a.plannedDate ?? DateTime.now())
                .compareTo(b.plannedDate ?? DateTime.now()));
        });
      }
    } catch (e) {
      print('Error loading plan items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlanItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('plan_items',
          json.encode(_planItems.map((item) => item.toJson()).toList()));
    } catch (e) {
      print('Error saving plan items: $e');
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
        final item = _planItems[index];

        // Remove with animation
        setState(() {
          _planItems.removeAt(index);
        });

        // Show a sliding animation
        AnimatedList.of(context).removeItem(
          index,
          (context, animation) => SlideTransition(
            position: animation.drive(Tween(
              begin: Offset(-1.0, 0.0),
              end: Offset.zero,
            )),
            child: FadeTransition(
              opacity: animation,
              child: TimelineTile(
                isFirst: index == 0,
                isLast: index == _planItems.length - 1,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                beforeLineStyle: LineStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                endChild: Container(
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
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          item.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editPlanItem(item),
                                  color: Colors.blue,
                                ),
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
                ),
              ),
            ),
          ),
          duration: Duration(milliseconds: 300),
        );

        await _savePlanItems();
      }
    }
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
    return AnimatedList(
      key: GlobalKey<AnimatedListState>(),
      padding: EdgeInsets.all(16),
      initialItemCount: _planItems.length,
      itemBuilder: (context, index, animation) {
        final item = _planItems[index];
        final isFirst = index == 0;
        final isLast = index == _planItems.length - 1;

        return SlideTransition(
          position: animation.drive(Tween(
            begin: Offset(1.0, 0.0),
            end: Offset.zero,
          )),
          child: FadeTransition(
            opacity: animation,
            child: TimelineTile(
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
              endChild: Container(
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
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        item.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                                icon: Icon(Icons.edit),
                                onPressed: () => _editPlanItem(item),
                                color: Colors.blue,
                              ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
