import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _addNote() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token de autenticación.';
          _isSubmitting = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/notes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Regresa a la pantalla anterior indicando éxito
      } else {
        setState(() {
          _errorMessage =
          'Error al agregar la nota: ${response.statusCode} - ${response.body}';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                if (_titleController.text.isEmpty ||
                    _bodyController.text.isEmpty) {
                  setState(() {
                    _errorMessage =
                    'Por favor completa todos los campos.';
                  });
                  return;
                }
                _addNote();
              },
              child: _isSubmitting
                  ? CircularProgressIndicator(
                color: Colors.white,
              )
                  : Text('Agregar Nota'),
            ),
          ],
        ),
      ),
    );
  }
}
