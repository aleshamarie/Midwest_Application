import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/product.dart';
import 'models/order.dart';
import 'models/cart_item.dart';
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
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + quantity,
      );
    } else {
      _cart.add(CartItem(product: product, quantity: quantity));
    }
    
    _saveCartToStorage();
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cart.removeWhere((item) => item.product.id == product.id);
    _saveCartToStorage();
    notifyListeners();
  }

  void updateCartItemQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }

    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
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

  Future<bool> createOrder({
    required String customerName,
    required String contact,
    required String address,
    required String paymentMethod,
    String? paymentRef,
  }) async {
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

      final response = await ApiService.createOrder(orderData);
      if (response['order'] != null) {
        final newOrder = Order.fromJson(response['order']);
        _orders.insert(0, newOrder);
        
        // Show notification for order placed
        await NotificationService.showOrderPlacedNotification(
          orderId: newOrder.orderCode,
          total: newOrder.netTotal.toStringAsFixed(2),
        );
        
        clearCart();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating order: $e');
      return false;
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