import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendaPage extends StatefulWidget {
  final String title;

  AgendaPage({Key? key, required this.title}) : super(key: key);

  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  List<CalendarEvent> _events = [];
  String _currentLanguage = '';
  int _selectedNavIndex = 1;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await initializeDateFormatting();
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    final data = await apiService.loadData('agenda', language);
    setState(() {
      _events = data.map((item) => CalendarEvent.fromJson(item)).toList();
      _events.sort((a, b) => a.date.compareTo(b.date));
      _events = _events
          .where((event) =>
              event.date.isAfter(DateTime.now().subtract(Duration(days: 1))))
          .toList();
      _currentLanguage = language;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLanguageChange();
  }

  void _checkLanguageChange() async {
    final apiService = ApiService();
    final newLanguage = await apiService.getCurrentLanguage();
    if (newLanguage != _currentLanguage) {
      await _loadEvents();
    }
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
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _buildNavContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Eventos',
          ),
        ],
        currentIndex: _selectedNavIndex > 1 ? 1 : _selectedNavIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            setState(() {
              _selectedNavIndex = index;
            });
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mes actual
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM', _currentLanguage)
                          .format(_focusedDay)
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    if (_selectedDay != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Borrar selección',
                        onPressed: () {
                          setState(() {
                            _selectedDay = null;
                          });
                        },
                      ),
                  ],
                ),
                // Botones de vista
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildViewToggleButton(
                        'Semana',
                        CalendarFormat.week,
                        leftRadius: true,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildViewToggleButton(
                        'Mes',
                        CalendarFormat.month,
                        rightRadius: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Calendario modificado
          SingleChildScrollView(
            physics: _calendarFormat == CalendarFormat.month
                ? AlwaysScrollableScrollPhysics()
                : NeverScrollableScrollPhysics(),
            child: TableCalendar(
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
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red.shade400,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 6,
                cellMargin: EdgeInsets.all(6),
                cellPadding: EdgeInsets.all(0),
              ),
              headerVisible: false,
              daysOfWeekHeight: 40,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Leyenda del calendario
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  'Hoy',
                  BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16),
                _buildLegendItem(
                  'Evento',
                  BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade400, width: 2),
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _selectedDay != null
                  ? 'Eventos a partir del ${DateFormat('d MMMM', _currentLanguage).format(_selectedDay!)}'
                  : 'Próximos eventos',
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
                      onTap: event.link.isNotEmpty
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
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 20,
          child: Text(
            'Agenda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}