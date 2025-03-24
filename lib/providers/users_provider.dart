// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:mspaa/services/api_service.dart';

class UsersProvider with ChangeNotifier {
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>>? _users;
  List<Map<String, dynamic>> _roles = []; // Inicializa con una lista vacía

  Map<String, dynamic>? get userData => _userData;
  List<Map<String, dynamic>>? get users => _users;
  List<Map<String, dynamic>> get roles => _roles;

  // Función para obtener los datos del usuario actual
  Future<void> fetchUserData() async {
    try {
      final ApiService apiService = ApiService();
      _userData = await apiService.getUserInfo();
      notifyListeners(); // Notifica a la UI que los datos se han actualizado
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener datos del usuario: $e");
      }
      _userData = {}; // Si hay error, asegura que _userData no sea null
      notifyListeners();
    }
  }

  // Método para obtener los datos de un usuario por su ID
  Future<void> fetchUserByID(int id) async {
    try {
      final ApiService apiService = ApiService();
      _userData = await apiService.getUserByID(id);
      notifyListeners(); // Notifica que los datos se han actualizado
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener datos del usuario por ID: $e");
      }
      _userData = {}; // Si hay error, asegura que _userData no sea null
      notifyListeners();
    }
  }

  // Método para obtener los datos de un usuario por su ID pero sin tocar _userData
  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      final ApiService apiService = ApiService();
      final user = await apiService.getUserByID(id);
      return user;
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener datos del usuario por ID: $e");
      }
      return null;
    }
  }

  // Método para obtener la lista de usuarios
  Future<void> fetchUsers() async {
    try {
      final ApiService apiService = ApiService();
      _users = await apiService.getUsers();
      notifyListeners(); // Notifica que la lista de usuarios se ha actualizado
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener la lista de usuarios: $e");
      }
      _users = []; // Si hay error, asegura que _users no sea null
      notifyListeners();
    }
  }

  // Función para agregar un nuevo usuario
  Future<bool> addUser(String name, String email, int role, String password) async {
    final ApiService apiService = ApiService();
    try {
      bool success = await apiService.addUser(name, email, role, password);
      if (success) {
        // Si la adición fue exitosa, recargar los usuarios
        await fetchUsers();
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print("Error al agregar usuario: $e");
      }
      return false;
    }
  }

  // Método para actualizar los datos del usuario
  Future<bool> updateUser(int userId, String name, String email, int role) async {
    final ApiService apiService = ApiService();
    try {
      // Llama al método para actualizar el usuario en el backend
      bool success = await apiService.updateUser(userId, name, email, role);
      if (success) {
        // Si la actualización fue exitosa, recargar los usuarios
        await fetchUsers();
      }
      return success;
    } catch (e) {
      print("Error al actualizar el usuario: $e");
      return false;
    }
  }

  // Función para obtener los roles desde el backend
  Future<void> fetchRoles() async {
    try {
      final ApiService apiService = ApiService();
      _roles = await apiService.getRoles(); // Llamamos al servicio para obtener los roles
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener los roles: $e");
      }
      _roles = []; // Si ocurre un error, aseguramos que _roles no sea null
      notifyListeners();
    }
  }

  // Función para eliminar un usuario
  Future<bool> deleteUser(int userId) async {
    try {
      final ApiService apiService = ApiService();
      bool isDeleted = await apiService.deleteUser(userId);

      if (isDeleted) {
        // Actualizar la lista de usuarios después de eliminar
        _users = _users?.where((user) => user['uss_id'] != userId).toList();
        notifyListeners();  // Notificar a la UI para que se actualice
      }

      return isDeleted;
    } catch (e) {
      print("Error al eliminar el usuario: $e");
      return false;
    }
  }

  // Función para verificar si el usuario tiene los permisos requeridos
  bool hasPermissions(List<int> requiredIds) {
    final userPerms = userData?["permisos"] ?? [];
    final userPermIds = userPerms.map<int>((perm) => perm["perm_id"] as int).toSet();

    return requiredIds.every(userPermIds.contains);
  }

}
