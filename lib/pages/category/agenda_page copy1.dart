import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:felanitx/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

class AgendaPage extends StatefulWidget {
  final String title;

  AgendaPage({Key? key, required this.title}) : super(key: key);

  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  List<CalendarEvent> _events = [];
  String _currentLanguage = '';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  'https://viufelanitx.com/upload/images/07_2019/6121_20074.jpg',
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
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
            ),
            SizedBox(height: 30),
            _buildEventList(context),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context) {
    final groupedEvents = _groupEventsByMonth();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: groupedEvents.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final month = groupedEvents.keys.elementAt(index);
          final events = groupedEvents[month]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  DateFormat.MMMM(_currentLanguage).format(month).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 15),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${event.date.day}',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
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
                                    fontSize: FontSize(14),
                                  ),
                                },
                              ),
                              if (event.link.isNotEmpty) ...[
                                SizedBox(height: 10),
                                TextButton(
                                  onPressed: () async {
                                    if (await canLaunch(event.link)) {
                                      await launch(event.link);
                                    } else {
                                      print(
                                          'No se pudo abrir el enlace: ${event.link}');
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                    'Més informació',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByMonth() {
    final groupedEvents = <DateTime, List<CalendarEvent>>{};

    for (final event in _events) {
      final month = DateTime(event.date.year, event.date.month);
      if (groupedEvents.containsKey(month)) {
        groupedEvents[month]!.add(event);
      } else {
        groupedEvents[month] = [event];
      }
    }

    return groupedEvents;
  }
}
