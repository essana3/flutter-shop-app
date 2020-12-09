import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

class Product with ChangeNotifier {
  static const baseUrl =
      'https://flutter1-complete-course-default-rtdb.europe-west1.firebasedatabase.app';

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.imageUrl,
    @required this.price,
    this.isFavorite = false,
  });

  Future<void> toggleFavorite(String token, String userId) async {
    isFavorite = !isFavorite;
    notifyListeners();
    try {
      final response = await http.put(
        '$baseUrl/favorites/$userId/$id.json?auth=$token',
        body: json.encode(isFavorite),
      );
      if (response.statusCode >= 400) {
        throw HttpException('Could not toggle favorite status!');
      }
    } catch (error) {
      isFavorite = !isFavorite;
      notifyListeners();
      throw error.toString();
    }
  }
}
