import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Para emulador Android
  // static const String baseUrl = "http://127.0.0.1:8000/api"; // Para Web o iOS

  /// 🔹 Obtener el token almacenado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// 🔹 Método genérico para manejar respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      if (kDebugMode) {
        print("❌ Error ${response.statusCode}: ${response.body}");
      }
      throw Exception("Error en la solicitud: ${response.statusCode}");
    }
  }

  /// 🔹 Login del usuario
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"uss_email": email, "uss_clave": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", data["token"]); // ✅ Guarda el token
      return true; // ✅ Login exitoso
    } else {
      return false; // ❌ Error en login
    }
  }

  /// 🔹 Logout del usuario
  Future<void> logout() async {
    final String? token = await _getToken();

    if (token != null) {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("auth_token"); // ✅ Eliminar el token
      } else {
        if (kDebugMode) {
          print("❌ Error al cerrar sesión: ${response.body}");
        }
      }
    }
  }

  /// 🔹 Obtener las actividades con autenticación
  Future<List<Map<String, dynamic>>> fetchActividades() async {
    final String? token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/actividades"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response).cast<Map<String, dynamic>>();
  }

  /// 🔹 Obtener los ciclos activos (sin `ci_fechafin`)
  Future<List<Map<String, dynamic>>> fetchCiclos() async {
    final String? token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/ciclos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response)
        .where((ciclo) => ciclo["ci_fechafin"] == null) // ✅ Solo ciclos activos
        .toList()
        .cast<Map<String, dynamic>>();
  }

  /// 🔹 Obtener los lotes
  Future<List<Map<String, dynamic>>> fetchLotes() async {
    final String? token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/lotes"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response).cast<Map<String, dynamic>>();
  }

  /// 🔹 Obtener los insumos
  Future<List<Map<String, dynamic>>> fetchInsumos() async {
    final String? token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/insumos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response).cast<Map<String, dynamic>>();
  }

  /// 🔹 Agregar una nueva actividad a la API
  Future<bool> addActivity(Map<String, dynamic> activityData) async {
    final String? token = await _getToken(); // ✅ Obtener token del usuario autenticado

    final response = await http.post(
      Uri.parse("$baseUrl/actividades"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(activityData),
    );

    if (response.statusCode == 201) {
      return true; // ✅ Actividad creada con éxito
    } else {
      if (kDebugMode) {
        print("❌ Error al agregar actividad: ${response.body}");
      }
      return false; // ❌ Fallo al crear actividad
    }
  }

    /// 🔹 Obtener los tipos de actividades desde la API
  Future<List<Map<String, dynamic>>> fetchTiposActividades() async {
    final String? token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tipos/actividades"), // ✅ Endpoint para obtener tipos de actividades
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response).cast<Map<String, dynamic>>();
  }
  
    /// 🔹 Obtener los tipos de cultivos desde la API
Future<List<Map<String, dynamic>>> fetchTiposCultivos() async {
  final String? token = await _getToken();
  final response = await http.get(
    Uri.parse("$baseUrl/tipos/cultivo"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    if (kDebugMode) {
      print("🔍 Tipos de Cultivo recibidos: $data");
    } // ✅ Imprimir en consola
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception("Error al obtener tipos de cultivos");
  }
}

  /// 🔹 Obtener las variedades de un tipo de cultivo
  Future<List<Map<String, dynamic>>> fetchVariedades(int tpCulId) async {
    final response = await http.get(Uri.parse("$baseUrl/variedades/$tpCulId")); // ✅ Ahora envía el ID correcto

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      return data.cast<Map<String, dynamic>>();
    } else {
      if (kDebugMode) {
        print("❌ Error en fetchVariedades(): ${response.body}");
      }
      throw Exception("Error al obtener variedades");
    }
  }

  /// 🔹 Agregar un nuevo ciclo a la API
  Future<bool> addCiclo(Map<String, dynamic> cicloData) async {
    final String? token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/ciclos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(cicloData),
    );

    return response.statusCode == 201;
  }

  /// 🔹 Agregar una nueva variedad a la API
  Future<int?> addVariedad(String nombre, String cultivoId) async {
    final String? token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/tipos/variedad"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "tpCult_id": int.parse(cultivoId),
        "var_nombre": nombre,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["var_id"]; // Retorna el ID de la nueva variedad
    }
    return null;
  }

  /// 🔹 Obtener el ID del usuario autenticado
  Future<int?> getLoggedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id"); // Asegúrate de guardar el ID del usuario en SharedPreferences
  }

}
