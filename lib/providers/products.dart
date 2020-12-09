import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import 'product.dart';

class Products with ChangeNotifier {
  static const baseUrl =
      'https://flutter1-complete-course-default-rtdb.europe-west1.firebasedatabase.app';
  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> fetchProducts() async {
    try {
      final res = await http.get('$baseUrl/products.json');
      final response = json.decode(res.body) as Map<String, dynamic>;
      if (response == null) {
        return;
      }
      final List<Product> products = [];
      response.forEach((id, product) {
        products.add(Product(
          id: id,
          title: product['title'],
          description: product['description'],
          imageUrl: product['imageUrl'],
          price: product['price'],
          isFavorite: product['isFavorite'],
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
        '$baseUrl/products.json',
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavorite,
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
      '$baseUrl/products/$id.json',
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
      final response = await http.delete('$baseUrl/products/$id.json');
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
