import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:felanitx/main.dart';
import 'package:felanitx/pages/detail/calendar_detail_page.dart';
import 'package:felanitx/pages/home_page.dart';
import 'package:felanitx/l10n/app_translations.dart';

class AgendaPage extends StatefulWidget {
  final String title;

  const AgendaPage({Key? key, this.title = ''}) : super(key: key);

  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final ApiService _apiService = ApiService();
  List<CalendarEvent> _events = [];
  String _currentLanguage = 'ca';
  String _title = 'Agenda';
  int _selectedNavIndex = 1;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting(_currentLanguage, null);
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final language = await _apiService.getCurrentLanguage();
      final data = await _apiService.loadData('agenda', language);

      if (data != null && data is List) {
        setState(() {
          _events = data.map((item) => CalendarEvent.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        print('Error: Los datos recibidos no son una lista válida');
        setState(() {
          _events = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _events = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitialLanguage() async {
    try {
      final language = await _apiService.getCurrentLanguage();
      setState(() {
        _currentLanguage = language;
        _updateTitleForLanguage(language);
      });
    } catch (e) {
      print('Error loading initial language: $e');
    }
  }

  void _updateTitleForLanguage(String language) {
    setState(() {
      _title = AppTranslations.translate('agenda', language);
    });
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      setState(() {
        _currentLanguage = language;
        _isLoading = true;
      });

      await _apiService.setLanguage(language);
      _updateTitleForLanguage(language);

      if (mounted) {
        final homePage = HomePage.of(context);
        homePage?.reloadData();
      }

      try {
        final cachedData = await _apiService.loadCachedData('agenda', language);
        if (cachedData.isNotEmpty) {
          setState(() {
            _events =
                cachedData.map((item) => CalendarEvent.fromJson(item)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading cached data: $e');
      }

      try {
        final freshData = await _apiService.loadFreshData('agenda', language);
        setState(() {
          _events =
              freshData.map((item) => CalendarEvent.fromJson(item)).toList();
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading fresh data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            final homePage = HomePage.of(context);
            homePage?.reloadData();
            Navigator.of(context).pop();
          },
        ),
        title: Image.asset(
          'assets/images/logo_felanitx.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          _isLoading
              ? SizedBox(width: 24, height: 24)
              : DropdownButton<String>(
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
          SizedBox(width: 16),
        ],
        centerTitle: true,
      ),
      body: _buildNavContent(),
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

  Widget _buildNavContent() {
    if (_selectedNavIndex == 0) return Container();
    return _buildCalendarView();
  }

  Widget _buildCalendarView() {
    return ListView(
      children: [
        _buildHeader(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCalendarCard(),
              _buildEventsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 15,
            spreadRadius: -5,
            offset: Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade100.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM', _currentLanguage)
                      .format(_focusedDay)
                      .toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: _selectedDay != null
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Borrar selección',
                          onPressed: () {
                            setState(() {
                              _selectedDay = null;
                            });
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now().subtract(Duration(days: 365)),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              return _events
                  .where((event) => isSameDay(event.date, day))
                  .toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: _calendarFormat == CalendarFormat.month,
              weekendTextStyle: TextStyle(color: Colors.black87),
              holidayTextStyle: TextStyle(color: Colors.black87),
              defaultTextStyle: TextStyle(color: Colors.black87),
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[400]!,
                    Colors.blue[300]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              todayTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.blue[600]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              markerDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[300]!,
                    Colors.blue[400]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue[300]!.withOpacity(0.3),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              markersMaxCount: 1,
              markerSize: 7,
              cellMargin: EdgeInsets.all(6),
              cellPadding: EdgeInsets.all(0),
            ),
            headerVisible: false,
            daysOfWeekHeight: 40,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue[100]!,
                    width: 2,
                  ),
                ),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextFormatter: (date, locale) {
                return '${AppTranslations.getMonth(_currentLanguage, date.month)} ${date.year}';
              },
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final weekDays = AppTranslations.getWeekDays(_currentLanguage);
                return Center(
                  child: Text(
                    weekDays[day.weekday - 1].substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  AppTranslations.translate('today', _currentLanguage),
                  BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16),
                _buildLegendItem(
                  AppTranslations.translate('event', _currentLanguage),
                  BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue[300]!,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(String text, CalendarFormat format,
      {bool leftRadius = false, bool rightRadius = false}) {
    final isSelected = _calendarFormat == format;
    return InkWell(
      onTap: () {
        setState(() {
          _calendarFormat = format;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(leftRadius ? 20 : 0),
            right: Radius.circular(rightRadius ? 20 : 0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, BoxDecoration decoration) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: decoration,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getLocale() {
    // Mapear los códigos de idioma a los locales de Intl
    final localeMap = {
      'es': 'es_ES',
      'ca': 'ca_ES',
      'en': 'en_US',
      'fr': 'fr_FR',
      'de': 'de_DE',
    };
    return localeMap[_currentLanguage] ?? 'es_ES';
  }

  Widget _buildEventsList() {
    List<CalendarEvent> selectedEvents;
    if (_selectedDay != null) {
      selectedEvents = _events
          .where((event) =>
              event.date.isAfter(_selectedDay!.subtract(Duration(days: 1))) ||
              isSameDay(event.date, _selectedDay!))
          .toList();
    } else {
      selectedEvents = _events;
    }

    final locale = _getLocale();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _selectedDay != null
                  ? '${AppTranslations.translate('events_from', _currentLanguage)} ${DateFormat('d MMMM', locale).format(_selectedDay!)}'
                  : AppTranslations.translate(
                      'upcoming_events', _currentLanguage),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: selectedEvents.length,
            itemBuilder: (context, index) {
              final event = selectedEvents[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: event.longDescription.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CalendarDetailPage(event: event),
                                ),
                              );
                            }
                          : event.link.isNotEmpty
                              ? () async {
                                  if (await canLaunch(event.link)) {
                                    await launch(event.link);
                                  }
                                }
                              : null,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('MMM', _currentLanguage)
                                        .format(event.date)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${event.date.day}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Html(
                                    data: event.shortDescription,
                                    style: {
                                      "body": Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                        fontSize: FontSize(16),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    },
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        DateFormat('EEEE', _currentLanguage)
                                            .format(event.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (event.link.isNotEmpty) ...[
                                        Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ],
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
              );
            },
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Image.network(
          'https://viufelanitx.com/upload/images/07_2019/6121_20074.jpg',
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      AppTranslations.translate('week', _currentLanguage),
                      CalendarFormat.week,
                      leftRadius: true,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildViewToggleButton(
                      AppTranslations.translate('month', _currentLanguage),
                      CalendarFormat.month,
                      rightRadius: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
