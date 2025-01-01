import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'notes_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas Personales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> _isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.data == true) {
            return NotesScreen();
          } else {
            return LoginScreen();
          }
        }
      },
    );
  }
}