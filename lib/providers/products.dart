import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import 'product.dart';

class Products with ChangeNotifier {
  static const baseUrl =
      'https://flutter1-complete-course-default-rtdb.europe-west1.firebasedatabase.app';
  List<Product> _items = [];
  final String token;
  final String userId;

  Products(this._items, {this.token, this.userId});

  List<Product> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> fetchProducts([bool filterByUser = false]) async {
    try {
      final filter =
          filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
      final res = await http.get('$baseUrl/products.json?auth=$token&$filter');
      final response = json.decode(res.body) as Map<String, dynamic>;
      if (response == null) {
        return;
      }
      final favRes =
          await http.get('$baseUrl/favorites/$userId.json?auth=$token');
      final favResponse = json.decode(favRes.body) as Map<String, dynamic>;

      final List<Product> products = [];
      response.forEach((id, product) {
        products.add(Product(
          id: id,
          title: product['title'],
          description: product['description'],
          imageUrl: product['imageUrl'],
          price: product['price'],
          isFavorite: favResponse == null ? false : favResponse[id] ?? false,
        ));
      });
      _items = products;
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  List<Product> get favorites {
    return _items.where((product) => product.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((product) => product.id == id);
  }

  Future<void> addProduct(Product product) async {
    try {
      final res = await http.post(
        '$baseUrl/products.json?auth=$token',
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
        }),
      );
      final response = json.decode(res.body);
      var newProduct = Product(
        id: response['name'],
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    await http.patch(
      '$baseUrl/products/$id.json?auth=$token',
      body: json.encode({
        'title': newProduct.title,
        'description': newProduct.description,
        'imageUrl': newProduct.imageUrl,
        'price': newProduct.price
      }),
    );
    final prodIndex = _items.indexWhere((product) => product.id == id);
    _items[prodIndex] = newProduct;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    final prodIndex = _items.indexWhere((product) => product.id == id);
    var product = _items[prodIndex];
    _items.removeAt(prodIndex);
    notifyListeners();
    try {
      final response =
          await http.delete('$baseUrl/products/$id.json?auth=$token');
      if (response.statusCode >= 400) {
        throw HttpException('Could not delete product!');
      }
      product = null;
    } catch (error) {
      _items.insert(prodIndex, product);
      notifyListeners();
      throw error.toString();
    }
  }
}
