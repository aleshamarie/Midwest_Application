import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'device_service.dart';
import 'fcm_service.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Products endpoints
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 25,
    String search = '',
  }) async {
    // Prefer public paginated endpoint; fallback to lazy public and slice client-side
    try {
      final publicUri = Uri.parse('$baseUrl/products/public').replace(queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (search.isNotEmpty) 'search': search,
      });
      final publicRes = await http.get(publicUri);
      if (publicRes.statusCode == 200) {
        return json.decode(publicRes.body);
      }
    } catch (_) {}

    try {
      final lazyUri = Uri.parse('$baseUrl/products/lazy/public').replace(queryParameters: {
        if (search.isNotEmpty) 'search': search,
      });
      final lazyRes = await http.get(lazyUri);
      if (lazyRes.statusCode == 200) {
        final decoded = json.decode(lazyRes.body) as Map<String, dynamic>;
        final list = (decoded['products'] as List<dynamic>? ) ?? [];
        final start = (page - 1) * pageSize;
        final end = start + pageSize;
        final sliced = start < list.length ? list.sublist(start, end > list.length ? list.length : end) : <dynamic>[];
        return { 'products': sliced };
      } else {
        throw Exception('Failed to load products: ${lazyRes.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getAllProducts({String search = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/lazy/public')
          .replace(queryParameters: {
        if (search.isNotEmpty) 'search': search,
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Orders endpoints
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      // Add device ID and unique client timestamp to order data
      final deviceId = await DeviceService.getDeviceId();
      final fcmToken = await FcmService.getToken();
      final clientTimestamp = DateTime.now().millisecondsSinceEpoch;
      final orderDataWithDevice = {
        ...orderData,
        'device_id': deviceId,
        'client_timestamp': clientTimestamp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
      
      print('Creating order with device_id: $deviceId, client_timestamp: $clientTimestamp');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/public'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderDataWithDevice),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );
      
      print('HTTP Status Code: ${response.statusCode}');
      print('HTTP Response Body: ${response.body}');
      print('HTTP Response Headers: ${response.headers}');
      
      if (response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        print('Decoded response: $decodedResponse');
        return decodedResponse;
      } else if (response.statusCode == 200) {
        // Some servers return 200 instead of 201 for successful creation
        final decodedResponse = json.decode(response.body);
        print('Decoded response (200): $decodedResponse');
        return decodedResponse;
      } else {
        print('Error response body: ${response.body}');
        print('Error response headers: ${response.headers}');
        throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Add device ID to filter orders for this device only
      final deviceId = await DeviceService.getDeviceId();
      final uri = Uri.parse('$baseUrl/orders/public')
          .replace(queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'device_id': deviceId,
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getOrder(int orderId, {String? objectId}) async {
    try {
      // Add device ID to ensure user can only access their own orders
      final deviceId = await DeviceService.getDeviceId();
      
      // Use ObjectId string if available, otherwise fall back to integer ID
      final idParam = objectId ?? orderId.toString();
      final uri = Uri.parse('$baseUrl/orders/$idParam/public')
          .replace(queryParameters: {
        'device_id': deviceId,
      });
      
      print('Fetching order from: $uri');
      print('Using ID: $idParam (objectId: $objectId, orderId: $orderId)');
      final response = await http.get(uri);
      print('Order response status: ${response.statusCode}');
      print('Order response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getOrderItems(int orderId, {String? objectId}) async {
    try {
      // Add device ID to ensure user can only access their own orders
      final deviceId = await DeviceService.getDeviceId();
      
      // Use ObjectId string if available, otherwise fall back to integer ID
      final idParam = objectId ?? orderId.toString();
      final uri = Uri.parse('$baseUrl/orders/$idParam/items/public')
          .replace(queryParameters: {
        'device_id': deviceId,
      });
      
      print('Fetching order items from: $uri');
      print('Using ID: $idParam (objectId: $objectId, orderId: $orderId)');
      final response = await http.get(uri);
      print('Order items response status: ${response.statusCode}');
      print('Order items response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load order items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order items: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {String? objectId}) async {
    try {
      // Add device ID to ensure user can only update their own orders
      final deviceId = await DeviceService.getDeviceId();
      
      // Use ObjectId string if available, otherwise fall back to integer ID
      final idParam = objectId ?? orderId.toString();
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$idParam/payment/public'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'device_id': deviceId,
        }),
      );
      
      print('Update order status response: ${response.statusCode}');
      print('Update order status body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Network error: $e');
    }
  }

  // Supplier Products endpoints
  static Future<Map<String, dynamic>> getProductSuppliers(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier-products/product/$productId')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product suppliers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getSupplierProducts(int supplierId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier-products/supplier/$supplierId')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load supplier products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllSupplierProducts({
    int page = 1,
    int pageSize = 25,
    int? supplierId,
    int? productId,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (supplierId != null) 'supplier_id': supplierId.toString(),
        if (productId != null) 'product_id': productId.toString(),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/supplier-products').replace(queryParameters: queryParams)
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load supplier products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Helper method to get full image URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '${ApiConfig.baseHost}/assets/images/Midwest.jpg';
    }
    
    // Handle base64 data URLs (legacy from MongoDB base64 storage)
    if (imagePath.startsWith('data:')) {
      print('ApiService: Found base64 data URL');
      return imagePath;
    }
    
    // Handle Cloudinary URLs (new format)
    if (imagePath.startsWith('https://res.cloudinary.com/')) {
      print('ApiService: Found Cloudinary URL: $imagePath');
      return imagePath;
    }
    
    // Handle regular HTTP URLs
    if (imagePath.startsWith('http')) {
      print('ApiService: Found HTTP URL: $imagePath');
      return imagePath;
    }
    
    // Handle relative paths (legacy file system)
    final fullUrl = '${ApiConfig.baseHost}$imagePath';
    print('ApiService: Constructed full URL: $fullUrl');
    return fullUrl;
  }
}
