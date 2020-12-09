import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  static const baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
  static const apiKey = 'AIzaSyCgIE1Xed6ruX9I5gcjawqt29V2uHJokZI';
  String _userId;
  String _token;
  DateTime _expiryDate;
  Timer _authTimer;

  String get token {
    if (_token != null &&
        _expiryDate != null &&
        _expiryDate.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  bool get isAuth {
    return token != null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
    String email,
    String password,
    String path,
  ) async {
    try {
      final res = await http.post(
        '$baseUrl:$path?key=$apiKey',
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final response = json.decode(res.body);
      if (response['error'] != null) {
        throw HttpException(response['error']['message']);
      }
      _token = response['idToken'];
      _userId = response['localId'];
      _expiryDate = DateTime.now().add(
        Duration(seconds: int.parse(response['expiresIn'])),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'userData',
        json.encode({
          'token': _token,
          'expiryDate': _expiryDate.toIso8601String(),
          'userId': _userId,
        }),
      );
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> signup(String email, String password) {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> signin(String email, String password) {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final userData =
        json.decode(prefs.getString('userData')) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(userData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = userData['token'];
    _userId = userData['userId'];
    _expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  void logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now());
    _authTimer = Timer(timeToExpiry, logout);
  }
}
