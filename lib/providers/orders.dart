import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime createdAt;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.createdAt,
  });
}

class Orders with ChangeNotifier {
  static const baseUrl =
      'https://flutter1-complete-course-default-rtdb.europe-west1.firebasedatabase.app';
  List<OrderItem> _orders = [];

  Future<void> fetchOrders() async {
    try {
      final res = await http.get('$baseUrl/orders.json');
      final response = json.decode(res.body) as Map<String, dynamic>;
      if (response == null) {
        return;
      }
      final List<OrderItem> orders = [];
      response.forEach((id, order) {
        orders.add(OrderItem(
          id: id,
          amount: order['amount'],
          products: (order['products'] as List<dynamic>)
              .map(
                (cartItem) => CartItem(
                  id: cartItem['id'],
                  title: cartItem['title'],
                  price: cartItem['price'],
                  quantity: cartItem['quantity'],
                ),
              )
              .toList(),
          createdAt: DateTime.parse(order['createdAt']),
        ));
      });
      _orders = orders;
    } catch (error) {
      print(error);
      throw error;
    } finally {
      notifyListeners();
    }
  }

  List<OrderItem> get orders {
    return [..._orders];
  }

  int get ordersCount {
    return _orders.length;
  }

  Future<void> addOrder(List<CartItem> products, double total) async {
    try {
      final timestamp = DateTime.now();
      final res = await http.post(
        '$baseUrl/orders.json',
        body: json.encode({
          'amount': total,
          'products': products
              .map(
                (product) => {
                  'id': product.id,
                  'title': product.title,
                  'quantity': product.quantity,
                  'price': product.price,
                },
              )
              .toList(),
          'createdAt': timestamp.toIso8601String(),
        }),
      );
      final response = json.decode(res.body);
      _orders.insert(
        0,
        OrderItem(
          id: response['name'],
          amount: total,
          products: products,
          createdAt: timestamp,
        ),
      );
    } catch (error) {
      print(error);
      throw error;
    } finally {
      notifyListeners();
    }
  }
}
