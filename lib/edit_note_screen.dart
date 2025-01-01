import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditNoteScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  EditNoteScreen({required this.note});

  @override
  _EditNoteScreenState createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note['title'] ?? '';
    _bodyController.text = widget.note['body'] ?? '';
  }

  Future<void> _editNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final id = widget.note['id'];

      if (token == null) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor inicia sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/notes/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text,
          'body': _bodyController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Indica éxito al regresar a la pantalla anterior
      } else {
        setState(() {
          _errorMessage = 'Error al editar la nota: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final id = widget.note['id'];

      if (token == null) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor inicia sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/notes/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Indica éxito al regresar a la pantalla anterior
      } else {
        setState(() {
          _errorMessage = 'Error al eliminar la nota: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar esta nota? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el cuadro de diálogo
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el cuadro de diálogo
                _deleteNote(); // Llama al método para eliminar la nota
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Nota'),
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
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder()),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _editNote,
                    child: Text('Guardar'),
                  ),
                  ElevatedButton(
                  onPressed: () => _showDeleteConfirmationDialog(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Eliminar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
