import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/map_page.dart';
import 'pages/camera_page.dart';
import 'pages/settings_page.dart';
import 'services/api_service.dart';
import 'pages/category/agenda_page.dart';
import 'pages/category/population_centers_page.dart';
import 'pages/category/points_of_interest_page.dart';
import 'pages/category/routes_page.dart';
import 'pages/category/accommodation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  apiService.startService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Color(0xFF1E88E5), // Azul corporativo
        // ... existing code ...
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/agenda_page.dart': (context) => AgendaPage(),
        '/population_centers_page.dart': (context) => PopulationCentersPage(),
        '/points_of_interest_page.dart': (context) => PointsOfInterestPage(),
        '/routes_page.dart': (context) => RoutesPage(),
        '/accommodation_page.dart': (context) => AccommodationPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      HomePage(),
      MapPage(),
      CameraPage(),
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildWidgetOptions(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
