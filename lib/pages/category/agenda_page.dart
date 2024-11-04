import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../models/event.dart';

class AgendaPage extends StatelessWidget {
  final String title;

  AgendaPage({Key? key, required this.title}) : super(key: key);

  final List<Event> events = List.generate(
    3,
    (index) => Event(
      description:
          '<b>Feria de San Agustín:</b> Feria nocturna con verbena, al paseo Ramon Llull. La fiesta más popular de Felanitx en honor de San Agustín de Hipona.',
      date: DateTime(2023, 8, 27),
      link: 'https://viufelanitx.com/upload/images/07_2019/6121_20074.jpg',
    ),
  );

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
          title,
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
            SizedBox(height: 50), // Aumentado el margen inferior
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context) {
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
        itemCount: events.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            contentPadding: EdgeInsets.fromLTRB(
                15, 15, 15, 15), // Aumentado el padding inferior a 15
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0) ...[
                  Text(
                    'Agosto',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                Row(
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
                            data: event.description,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(14),
                              ),
                            },
                          ),
                          if (event.link != null) ...[
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement web navigation in the future
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize:
                                    Size(0, 30), // Altura mínima más pequeña

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Text(
                                'Más información',
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
              ],
            ),
          );
        },
      ),
    );
  }
}
