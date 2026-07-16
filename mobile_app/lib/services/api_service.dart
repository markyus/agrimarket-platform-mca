import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userString = prefs.getString('user');
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // AUTHENTICATION
  // ============================================

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await saveToken(data['token']);
        final user = User.fromJson(data['user']);
        await saveUser(user);
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    required String location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
          'location': location,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ============================================
  // USERS
  // ============================================

  static Future<List<dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getPendingFarmers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pending-farmers'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pending farmers: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> approveFarmer(int farmerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/approve-farmer/$farmerId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error approving farmer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // PRODUCTS
  // ============================================

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String category,
    required double price,
    required double quantity,
    required String unit,
    required String description,
    required int farmerId,
    required String? imagePath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['quantity'] = quantity.toString();
      request.fields['unit'] = unit;
      request.fields['description'] = description;
      request.fields['farmerId'] = farmerId.toString();

      request.headers['Authorization'] = 'Bearer $token';

      if (imagePath != null && imagePath.isNotEmpty) {
        var imageFile = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(imageFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'product': data['product']
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to add product'
        };
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // STATS
  // ============================================

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return {};
    }
  }

  static Future<List<Product>> getRecentProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recent-products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching recent products: $e');
      return [];
    }
  }

  // ============================================
  // ORDERS
  // ============================================

  static Future<Map<String, dynamic>> createOrder({
    required int productId,
    required int farmerId,
    required double quantity,
    required String unit,
    required double totalPrice,
    required String deliveryAddress,
  }) async {
    try {
      final token = await getToken();
      final user = await getUser();

      if (token == null || user == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'buyerId': user.id,
          'productId': productId,
          'farmerId': farmerId,
          'quantity': quantity,
          'unit': unit,
          'totalPrice': totalPrice,
          'deliveryAddress': deliveryAddress,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error creating order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<Order>> getMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  static Future<List<Order>> getFarmerOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/farmer-orders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching farmer orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error updating order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: await _getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
