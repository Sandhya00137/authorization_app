import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
    String? token;
    DateTime? expiryDate;
    String? userId;
    Timer? authTimer;

  bool get isAuth {
    return apiToken != '';
  }

  String get apiToken {
   if(expiryDate != null && expiryDate!.isAfter(DateTime.now()) && token != null) {
     return token!;
   }
    return '';
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCAzHZ2WHhyozq0aYM4IgwxZ3CuEORYzWI');
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );

      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        print(responseData['error']);
      }
      token = responseData['idToken'];
      userId = responseData['localId'];
      expiryDate = DateTime.now().add(Duration(seconds: int.parse(responseData['expiresIn'])));
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData  = json.encode({
        'token': token,
        'userId': userId,
        'expiryDate': expiryDate?.toIso8601String(),
      },);
      prefs.setString('userData', userData);
      print(responseData);
    } catch(error) {
      throw error;
        print('$error dataerror');
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async{
    final prefs = await SharedPreferences.getInstance();
    if(!prefs.containsKey('userData')) {
      return false;
    }
    final finalData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDatee = DateTime.parse(finalData['expiryDate']);

    if(expiryDate!.isAfter(DateTime.now())) {
      return false;
    }
    token = finalData['token'];
    userId = finalData['userId'];
    expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async{
    token = '';
    userId = null;
    expiryDate = null;
    if(authTimer != null) {
      authTimer?.cancel();
      authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if(authTimer != null) {
      authTimer?.cancel();
    }
    final time = expiryDate?.difference(DateTime.now()).inSeconds;
    authTimer = Timer(Duration(seconds: time!), logout);
  }
}
