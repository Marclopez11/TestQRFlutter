import 'dart:convert';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/settings_page.dart';
import 'pages/map_page.dart'; // Añade esta importación
import 'package:http/http.dart' as http;
import '../models/map_item.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<State<StatefulWidget>>> _pageKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(), // Añade una nueva clave para MapPage
  ];

  List<MapItem> _mapItems = []; // Add this line

  @override
  void initState() {
    super.initState();
    fetchItems(); // Add this line
  }

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse(
        'https://jo3wdm44wdd7ij7hjauasqvc2i0fgzey.lambda-url.eu-central-1.on.aws/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _mapItems = data.map((item) {
          return MapItem(
            id: item['id'].toString(),
            title: item['name'],
            description: item['description'],
            position: LatLng(
              item['coordinates']['latitude'],
              item['coordinates']['longitude'],
            ),
          );
        }).toList();
      });
    }
  }

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      const HomePage(),
      const MapPage(), // Remove the 'items' parameter
      const CameraPage(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Mapa'; // Cambia el título para el índice 1
      case 2:
        return 'Cámara';

      case 3:
        return 'Ajustes';
      default:
        return 'Mi Aplicación';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex)),
        // Elimina el botón de retroceso, ya que no es necesario en la navegación principal
      ),
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: _buildWidgetOptions().asMap().entries.map((entry) {
            return KeyedSubtree(
              key: _pageKeys[entry.key],
              child: entry.value,
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map), // Cambia el icono a un mapa
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType
            .fixed, // Asegura que se muestren todos los ítems
      ),
    );
  }
}
