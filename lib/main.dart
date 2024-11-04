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
import 'pages/category/restaurants_page.dart';

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
        '/agenda_page.dart': (context) => AgendaPage(title: ''),
<<<<<<< HEAD
        '/population_centers_page.dart': (context) =>
            PopulationCentersPage(title: ''),
        '/points_of_interest_page.dart': (context) =>
            PointsOfInterestPage(title: ''),
        '/routes_page.dart': (context) => RoutesPage(title: ''),
        '/accommodation_page.dart': (context) => AccommodationPage(title: ''),
        '/restaurants_page.dart': (context) => RestaurantsPage(title: ''),
=======
        '/population_centers_page.dart': (context) => PopulationCentersPage(),
        '/points_of_interest_page.dart': (context) => PointsOfInterestPage(),
        '/routes_page.dart': (context) => RoutesPage(),
        '/accommodation_page.dart': (context) => AccommodationPage(),
        '/restaurants_page.dart': (context) => RestaurantsPage(),
>>>>>>> 208a886 (agenda terminada)
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _buildWidgetOptions() {
    return <Widget>[
      HomePage(),
      MapPage(),
      CameraPage(),
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildWidgetOptions()[_selectedIndex],
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
