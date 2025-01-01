import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LogoutService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> logout() async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null) {
        print('No se encontró un token para cerrar sesión.');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://api.notas.rodrigocarreon.com/api/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print('Cierre de sesión exitoso en el servidor.');
        await _storage.delete(key: 'jwt_token'); // Eliminar el token localmente
        return true;
      } else {
        print('Error al cerrar sesión: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ocurrió un error al cerrar sesión: $e');
      return false;
    }
  }
}
