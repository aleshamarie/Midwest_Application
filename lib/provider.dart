import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'models/product.dart';
import 'models/order.dart';
import 'models/cart_item.dart';
import 'models/variant.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/device_service.dart';

class AppProvider with ChangeNotifier {
  // Products
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoadingProducts = false;
  bool _isLoadingMoreProducts = false;
  int _currentProductsPage = 1;
  final int _productsPageSize = 20;
  bool _hasMoreProducts = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';

  // Cart
  List<CartItem> _cart = [];
  bool _isLoadingCart = false;

  // Orders
  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  bool _isCreatingOrder = false;

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;

  List<CartItem> get cart => _cart;
  bool get isLoadingCart => _isLoadingCart;
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  List<Order> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isCreatingOrder => _isCreatingOrder;

  // Product methods
  Future<void> loadProducts({String search = '', bool reset = false}) async {
    if (reset) {
      _products = [];
      _filteredProducts = [];
      _currentProductsPage = 1;
      _hasMoreProducts = true;
    }
    _isLoadingProducts = true;
    notifyListeners();

    try {
      final response = await ApiService.getProducts(
        page: _currentProductsPage,
        pageSize: _productsPageSize,
        search: search,
      );
      final productsData = (response['products'] as List<dynamic>? ) ?? [];
      final fetched = productsData.map((json) => Product.fromJson(json)).toList();

      if (_currentProductsPage == 1) {
        _products = fetched;
      } else {
        _products.addAll(fetched);
      }

      // If returned less than page size, no more
      if (fetched.length < _productsPageSize) {
        _hasMoreProducts = false;
      }

      _filterProducts();
    } catch (e) {
      print('Error loading products: $e');
      if (_currentProductsPage == 1) _products = [];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;
    _isLoadingMoreProducts = true;
    _currentProductsPage += 1;
    notifyListeners();
    try {
      final response = await ApiService.getProducts(
        page: _currentProductsPage,
        pageSize: _productsPageSize,
        search: _searchQuery,
      );
      final productsData = (response['products'] as List<dynamic>? ) ?? [];
      final fetched = productsData.map((json) => Product.fromJson(json)).toList();
      _products.addAll(fetched);
      if (fetched.length < _productsPageSize) {
        _hasMoreProducts = false;
      }
      _filterProducts();
    } catch (e) {
      print('Error loading more products: $e');
      // roll back page on failure
      _currentProductsPage = (_currentProductsPage > 1) ? _currentProductsPage - 1 : 1;
    } finally {
      _isLoadingMoreProducts = false;
      notifyListeners();
    }
  }

  void searchProducts(String query) {
    _searchQuery = query.trim();
    
    // If search query is empty, show all products
    if (_searchQuery.isEmpty) {
      _filterProducts();
      notifyListeners();
      return;
    }
    
    // Load products from server with search query
    loadProducts(search: _searchQuery, reset: true);
  }

  void clearSearch() {
    _searchQuery = '';
    // Reset to show all products
    loadProducts(reset: true);
  }

  void filterByCategory(String category) {
    // Ensure the category exists in our list
    final availableCategories = categories;
    if (availableCategories.contains(category)) {
      _selectedCategory = category;
      _selectedBrand = 'All';
      _filterProducts();
      notifyListeners();
    } else {
      // If category doesn't exist, reset to 'All'
      _selectedCategory = 'All';
      _selectedBrand = 'All';
      _filterProducts();
      notifyListeners();
    }
  }

  void filterByBrand(String brand) {
    _selectedBrand = brand;
    _filterProducts();
    notifyListeners();
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesCategory = _selectedCategory == 'All' ||
          (product.category?.toLowerCase() == _selectedCategory.toLowerCase());
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    // Ensure selected category is still valid after filtering
    final availableCategories = categories;
    if (!availableCategories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
      _selectedBrand = 'All';
    }
  }

  List<String> get categories {
    final cats = <String>{'All'};
    for (var product in _products) {
      if (product.category != null && product.category!.isNotEmpty) {
        // Trim whitespace and ensure no duplicates
        final category = product.category!.trim();
        if (category.isNotEmpty) {
          cats.add(category);
        }
      }
    }
    final result = cats.toList()..sort();
    print('Categories found: $result');
    
    // Ensure we always have at least 'All' category
    if (result.isEmpty) {
      return ['All'];
    }
    
    // Ensure no duplicates and valid values
    final uniqueResult = result.toSet().toList()..sort();
    return uniqueResult;
  }

  List<String> get brands {
    final brands = <String>{'All'};
    for (var product in _products) {
      // Assuming brand is part of category or name for now
      if (product.category != null && product.category!.isNotEmpty) {
        final brand = product.category!.trim();
        if (brand.isNotEmpty) {
          brands.add(brand);
        }
      }
    }
    final result = brands.toList()..sort();
    print('Brands found: $result');
    return result;
  }

  // Cart methods
  void addToCart(Product product, {int quantity = 1, Variant? variant}) {
    final newItem = CartItem(product: product, quantity: quantity, variant: variant);
    final existingIndex = _cart.indexWhere((item) => item.isSameItem(newItem));
    
    if (existingIndex >= 0) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + quantity,
      );
    } else {
      _cart.add(newItem);
    }
    
    _saveCartToStorage();
    notifyListeners();
  }

  void removeFromCart(Product product, {Variant? variant}) {
    if (variant != null) {
      _cart.removeWhere((item) => 
        item.product.id == product.id && item.variant?.id == variant.id
      );
    } else {
      _cart.removeWhere((item) => item.product.id == product.id && item.variant == null);
    }
    _saveCartToStorage();
    notifyListeners();
  }

  void updateCartItemQuantity(Product product, int quantity, {Variant? variant}) {
    if (quantity <= 0) {
      removeFromCart(product, variant: variant);
      return;
    }

    final newItem = CartItem(product: product, quantity: quantity, variant: variant);
    final existingIndex = _cart.indexWhere((item) => item.isSameItem(newItem));
    if (existingIndex >= 0) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: quantity);
      _saveCartToStorage();
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _saveCartToStorage();
    notifyListeners();
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _cart.map((item) => {
        'product': item.product.toJson(),
        'quantity': item.quantity,
      }).toList();
      await prefs.setString('cart', json.encode(cartJson));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('cart');
      if (cartString != null) {
        final cartJson = json.decode(cartString) as List<dynamic>;
        _cart = cartJson.map((item) {
          final product = Product.fromJson(item['product']);
          return CartItem.fromJson(item, product);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Order methods
  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    notifyListeners();

    try {
      final response = await ApiService.getOrders();
      final ordersData = response['orders'] as List<dynamic>;
      final baseOrders = ordersData.map((json) => Order.fromJson(json)).toList();

      // Fetch items for each order (details endpoint returns items)
      final enriched = await Future.wait<Order>(baseOrders.map((o) async {
        try {
          final detail = await ApiService.getOrder(o.id, objectId: o.objectId);
          final orderJson = detail['order'] as Map<String, dynamic>?;
          if (orderJson != null && orderJson['items'] is List) {
            final items = (orderJson['items'] as List<dynamic>)
                .map((it) => OrderItem.fromJson(it as Map<String, dynamic>))
                .toList();
            return o.copyWith(items: items);
          }
        } catch (_) {}
        return o;
      }));

      _orders = enriched;
    } catch (e) {
      print('Error loading orders: $e');
      _orders = [];
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // Periodic polling for order status changes
  DateTime? _lastOrdersFetchedAt;
  Map<int, String> _lastKnownStatusById = {};

  void startOrderStatusPolling({Duration interval = const Duration(seconds: 20)}) {
    // Initialize last known statuses
    for (final o in _orders) {
      _lastKnownStatusById[o.id] = o.status;
    }
    // Kick off periodic timer
    Future.doWhile(() async {
      await Future.delayed(interval);
      try {
        final response = await ApiService.getOrders(page: 1, pageSize: 50);
        final ordersData = response['orders'] as List<dynamic>;
        final fresh = ordersData.map((j) => Order.fromJson(j)).toList();

        // Detect changes and notify
        for (final o in fresh) {
          final prev = _lastKnownStatusById[o.id];
          if (prev != null && prev != o.status) {
            await NotificationService.showOrderStatusUpdateNotification(
              orderId: o.orderCode,
              status: o.status,
            );
          }
          _lastKnownStatusById[o.id] = o.status;
        }

        _orders = fresh;
        _lastOrdersFetchedAt = DateTime.now();
        notifyListeners();
      } catch (e) {
        // Network errors are ignored for polling; will retry next interval
      }
      return true; // continue looping
    });
  }

  Future<String?> createOrder({
    required String customerName,
    required String contact,
    required String address,
    required String paymentMethod,
    String? paymentRef,
  }) async {
    // Prevent duplicate order creation
    if (_isCreatingOrder) {
      print('Order creation already in progress, ignoring duplicate request');
      return null;
    }

    if (_cart.isEmpty) {
      print('Cannot create order: cart is empty');
      return null;
    }

    _isCreatingOrder = true;
    notifyListeners();

    try {
      // Debug: Log cart contents
      print('=== ORDER CREATION DEBUG ===');
      print('Cart length: ${_cart.length}');
      print('Cart total: $cartTotal');
      for (int i = 0; i < _cart.length; i++) {
        print('Cart item $i: ${_cart[i].toJson()}');
      }
      print('============================');
      
      final orderData = {
        'name': customerName,
        'contact': contact,
        'address': address,
        'payment': paymentMethod,
        'ref': paymentRef,
        'totalPrice': cartTotal,
        'discount': 0.0,
        'net_total': cartTotal,
        'status': 'Pending',
        'type': 'Online',
        'items': _cart.map((item) => item.toJson()).toList(),
      };

      // Wait for server response with proper timeout handling
      print('Sending order to server...');
      final response = await ApiService.createOrder(orderData);
      print('Received response from server');
      
      print('API Response: $response');
      print('Response type: ${response.runtimeType}');
      print('Response keys: ${response.keys.toList()}');
      
      // Additional debugging for order response
      if (response['order'] != null) {
        print('Order object found in response');
        print('Order object type: ${response['order'].runtimeType}');
        print('Order object keys: ${(response['order'] as Map).keys.toList()}');
      }
      
      // Check for order in response - server returns { order: {...} }
      Map<String, dynamic>? orderResponseData;
      if (response['order'] != null) {
        orderResponseData = response['order'] as Map<String, dynamic>;
        print('Order found in response[\'order\'], parsing...');
      } else {
        print('No order found in response');
        print('Available keys in response: ${response.keys.toList()}');
        print('Full response: $response');
        
        // Check if response indicates success even without order object
        if (response['message'] != null && response['message'].toString().toLowerCase().contains('success')) {
          print('Server indicates success via message, assuming order created');
          clearCart();
          notifyListeners();
          // Try to get order ID from response if available
          return response['order_id']?.toString() ?? response['id']?.toString();
        }
        
        // If no order in response, this is likely an error
        print('ERROR: Server response does not contain order data');
        return null;
      }
      
      if (orderResponseData != null) {
        print('Order data: $orderResponseData');
        print('Order data type: ${orderResponseData.runtimeType}');
        print('Order data keys: ${orderResponseData.keys.toList()}');
        try {
          final newOrder = Order.fromJson(orderResponseData);
          print('Order parsed successfully: ${newOrder.orderCode}');
          _orders.insert(0, newOrder);
          
          // Show notification for order placed
          await NotificationService.showOrderPlacedNotification(
            orderId: newOrder.orderCode,
            total: newOrder.netTotal.toStringAsFixed(2),
          );
          
          clearCart();
          notifyListeners();
          return newOrder.objectId ?? newOrder.id.toString();
        } catch (parseError) {
          print('Error parsing order: $parseError');
          print('Stack trace: ${StackTrace.current}');
          
          // Even if parsing fails, the order might have been created successfully
          // Try to refresh orders to see if it appears
          try {
            print('Attempting to refresh orders to check if order was created...');
            await loadOrders();
            if (_orders.isNotEmpty) {
              print('Order appears to have been created successfully (found ${_orders.length} orders)');
              final latestOrder = _orders.first;
              clearCart();
              notifyListeners();
              return latestOrder.objectId ?? latestOrder.id.toString();
            }
          } catch (refreshError) {
            print('Error refreshing orders: $refreshError');
          }
          
          // If we can't parse the order but got a 201 response, try to get ID from response
          // Prefer _id (MongoDB ObjectId) over id
          final orderId = orderResponseData['_id']?.toString() ?? 
                         orderResponseData['id']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            print('Got order ID from response: $orderId');
            clearCart();
            notifyListeners();
            return orderId;
          }
          
          // If we can't parse the order but got a 201 response, assume success
          print('Assuming order was created successfully despite parsing error');
          clearCart();
          notifyListeners();
          return null; // Can't return ID if we can't parse it
        }
      } else {
        // This should not happen based on the logic above, but just in case
        print('ERROR: orderResponseData is null but we expected it to have a value');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      
      // Check if it's a network timeout or connection issue
      if (e.toString().contains('timeout') || e.toString().contains('connection')) {
        print('Network issue detected, but order might have been created on server');
        // Try to refresh orders to check if order was created despite the error
        try {
          await loadOrders();
          if (_orders.isNotEmpty) {
            print('Order found after network error - assuming success');
            final latestOrder = _orders.first;
            clearCart();
            notifyListeners();
            return latestOrder.objectId ?? latestOrder.id.toString();
          }
        } catch (refreshError) {
          print('Error refreshing orders after network error: $refreshError');
        }
      }
      
      return null;
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      await ApiService.updateOrderStatus(orderId, status, objectId: order.objectId);
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex >= 0) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: status);
        
        // Show notification for status update
        await NotificationService.showOrderStatusUpdateNotification(
          orderId: order.orderCode,
          status: status,
        );
        
        notifyListeners();
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> refreshOrderStatus(int orderId) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final response = await ApiService.getOrder(orderId, objectId: order.objectId);
      if (response['order'] != null) {
        final updatedOrder = Order.fromJson(response['order']);
        final orderIndex = _orders.indexWhere((order) => order.id == orderId);
        if (orderIndex >= 0) {
          _orders[orderIndex] = updatedOrder;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error refreshing order status: $e');
    }
  }

  // Initialize app
  Future<void> initialize() async {
    try {
      // Initialize device service first
      await DeviceService.getDeviceId();
      await _loadCartFromStorage();
      await loadProducts();
      await loadOrders();
      
      // Ensure selected category is valid
      final availableCategories = categories;
      if (!availableCategories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
        _selectedBrand = 'All';
      }
      
      // Start polling for server-side order status updates
      startOrderStatusPolling();
    } catch (e) {
      print('App provider initialization error: $e');
      // Set safe defaults
      _selectedCategory = 'All';
      _selectedBrand = 'All';
    }
  }

}