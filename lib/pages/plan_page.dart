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
    _loadCurrentLanguage().then((_) => _loadPlanItems());
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
      setState(() {
        _planItems.removeWhere((item) => item.id == itemId);
      });
      await _savePlanItems();
    }
  }

  Future<void> _editPlanItem(PlanItem item) async {
    DateTime selectedDate = item.plannedDate ?? DateTime.now();
    TimeOfDay selectedTime = item.plannedDate != null
        ? TimeOfDay.fromDateTime(item.plannedDate!)
        : TimeOfDay.now();
    String notes = item.notes ?? '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppTranslations.translate('edit_plan', _currentLanguage)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title:
                      Text(AppTranslations.translate('date', _currentLanguage)),
                  subtitle: Text(
                    DateFormat.yMMMd(_currentLanguage).format(selectedDate),
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  title:
                      Text(AppTranslations.translate('time', _currentLanguage)),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText:
                        AppTranslations.translate('notes', _currentLanguage),
                    hintText: AppTranslations.translate(
                        'add_notes', _currentLanguage),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: notes),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text(AppTranslations.translate('cancel', _currentLanguage)),
            ),
            TextButton(
              onPressed: () {
                final DateTime combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.pop(context, {
                  'date': combinedDateTime,
                  'notes': notes,
                });
              },
              child: Text(AppTranslations.translate('save', _currentLanguage)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final index = _planItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        setState(() {
          _planItems[index] = item.copyWith(
            plannedDate: result['date'],
            notes: result['notes'],
          );
        });
        await _savePlanItems();
      }
    }
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
      setState(() {
        _currentLanguage = language;
      });

      await _apiService.setLanguage(language);

      // Recargar los items del plan para actualizar las fechas formateadas
      setState(() {
        // Forzar actualización de la UI con el nuevo idioma
        _planItems = List.from(_planItems);
      });
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
        );
      },
    );
  }
}
