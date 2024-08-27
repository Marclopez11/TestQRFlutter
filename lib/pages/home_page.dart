import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> categories = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // Función para obtener las categorías desde la API (simulada con datos hardcodeados)
  Future<void> fetchCategories() async {
    try {
      // Simular la respuesta de la API
      final response = '''
      [
        {
          "name": [{"value": "Negoci Local"}]
        },
        {
          "name": [{"value": "Alimentació"}]
        },
        {
          "name": [{"value": "Comerç i Moda"}]
        },
        {
          "name": [{"value": "Basar"}]
        },
        {
          "name": [{"value": "Serveis financers"}]
        },
        {
          "name": [{"value": "Enoteca"}]
        },
        {
          "name": [{"value": "Caixer automàtic"}]
        },
        {
          "name": [{"value": "Serveis mèdics"}]
        },
        {
          "name": [{"value": "Farmàcia"}]
        },
        {
          "name": [{"value": "Hospital privat"}]
        }
      ]
      ''';

      // Decodificar la respuesta simulada
      final List<dynamic> data = json.decode(response);
      setState(() {
        // Extraer los nombres de las categorías
        categories = data
            .map((category) => category['name'][0]['value'] as String)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar las categorías: $e';
        isLoading = false;
      });
    }
  }

  // Widget para mostrar el estado de carga
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  // Widget para mostrar el mensaje de error
  Widget _buildError() {
    return Center(child: Text(errorMessage));
  }

  // Widget para mostrar la lista de categorías
  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category,
                  size: 50,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  categories[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos el AppBar completamente
      body: isLoading
          ? _buildLoading()
          : errorMessage.isNotEmpty
              ? _buildError()
              : _buildCategoryGrid(),
      backgroundColor: Colors.grey[200],
    );
  }
}
