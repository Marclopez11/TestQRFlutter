import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryItemsPage extends StatefulWidget {
  final String categoryName;

  const CategoryItemsPage({Key? key, required this.categoryName})
      : super(key: key);

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  List<dynamic> items = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      final response = await http.get(Uri.parse(
          'https://jo3wdm44wdd7ij7hjauasqvc2i0fgzey.lambda-url.eu-central-1.on.aws/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data
              .where((item) => item['category'] == widget.categoryName)
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar los items';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los items: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(child: Text(errorMessage));
  }

  Widget _buildItemList() {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Image.network(
              'https://example.com/images/${item['imageName']}.jpg',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            title: Text(item['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['city']}, ${item['state']}'),
                const SizedBox(height: 4),
                Text(
                  item['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: isLoading
          ? _buildLoading()
          : errorMessage.isNotEmpty
              ? _buildError()
              : _buildItemList(),
    );
  }
}
