import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'add_note_screen.dart';
import 'logout_service.dart';
import 'edit_note_screen.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final LogoutService _logoutService = LogoutService();
  List<dynamic> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _username;

  @override
  void initState() {
    super.initState();
    _validateTokenAndFetchNotes();
  }

  Future<void> _validateTokenAndFetchNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null) {
        print('Token no encontrado, redirigiendo al login.');
        _redirectToLogin();
        return;
      }

      // Validar el token
      final validationResponse = await http.get(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Respuesta del servidor: ${validationResponse.body}');
      print('Código de estado: ${validationResponse.statusCode}');

      if (validationResponse.statusCode != 200) {
        print('Token inválido o error en la validación.');
        _redirectToLogin();
        return;
      }

      final user = jsonDecode(validationResponse.body);


      setState(() {
        _username = user['username'] ?? 'Usuario';
      });

      // Verificar si hay un error en la respuesta
      if (user['error'] != null) {
        print('Error en la respuesta: ${user['error']}');
        _redirectToLogin();
        return;
      }

      // Si el token es válido, cargar notas
      print('Token válido, usuario autenticado.');
      await _fetchNotes(token);
    } catch (e) {
      print('Error durante la validación: $e');
      setState(() {
        _errorMessage = 'Ocurrió un error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final success = await _logoutService.logout();
    if (success) {
      _redirectToLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión. Inténtalo nuevamente.')),
      );
    }
  }

  Future<void> _fetchNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/notes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _notes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar las notas: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: $e';
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    _storage.delete(key: 'jwt_token'); // Eliminar token inválido
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${_username ?? 'Cargando...'}'),
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: _handleLogout,
        ),
      ),
      body: _isLoading
          ? ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
      )
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditNoteScreen(note: note),
                ),
              );
              if (result == true) {
                _validateTokenAndFetchNotes();
              }
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'] ?? 'Sin título',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      note['body'] ?? 'Sin contenido',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      note['date'] ?? 'Sin fecha',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNoteScreen()),
          );
          if (result == true) {
            _validateTokenAndFetchNotes();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
