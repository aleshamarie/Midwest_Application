class OrderItem {
  final int productId;
  final String name;
  final String? productSku;
  final String? productCategory;
  final int quantity;
  final double price;
  final double total;
  final double? productCost;
  final String? notes;

  OrderItem({
    required this.productId,
    required this.name,
    this.productSku,
    this.productCategory,
    required this.quantity,
    required this.price,
    required this.total,
    this.productCost,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    print('OrderItem.fromJson called with: $json');
    
    // Handle numeric fields as either string or number
    double price = 0.0;
    final dynamic rawPrice = json['price'] ?? json['unit_price'];
    if (rawPrice != null) {
      if (rawPrice is String) {
        price = double.tryParse(rawPrice) ?? 0.0;
      } else {
        price = (rawPrice as num).toDouble();
      }
    }
    
    double total = 0.0;
    if (json['total'] != null) {
      if (json['total'] is String) {
        total = double.tryParse(json['total']) ?? 0.0;
      } else {
        total = (json['total'] as num).toDouble();
      }
    }
    
    int quantity = 0;
    final dynamic rawQty = json['quantity'] ?? json['qty'];
    if (rawQty != null) {
      if (rawQty is String) {
        quantity = int.tryParse(rawQty) ?? 0;
      } else {
        quantity = (rawQty as num).toInt();
      }
    }

    // Handle product_id as either MongoDB ObjectId (string) or integer
    int productId = 0;
    if (json['product_id'] != null) {
      if (json['product_id'] is String) {
        productId = json['product_id'].hashCode.abs();
      } else if (json['product_id'] is int) {
        productId = json['product_id'] as int;
      }
    }

    // Handle nested product information
    String name = json['name'] ?? json['product_name'] ?? '';
    if (name.isEmpty && json['product_id'] is Map<String, dynamic>) {
      final productInfo = json['product_id'] as Map<String, dynamic>;
      name = productInfo['name'] ?? productInfo['product_name'] ?? '';
    }

    final result = OrderItem(
      productId: productId,
      name: name,
      productSku: json['product_sku'],
      productCategory: json['product_category'],
      quantity: quantity,
      price: price,
      total: total != 0.0 ? total : (price * quantity),
      productCost: json['product_cost']?.toDouble(),
      notes: json['notes'],
    );
    
    print('OrderItem.fromJson result: $result');
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'product_sku': productSku,
      'product_category': productCategory,
      'quantity': quantity,
      'price': price,
      'total': total,
      'product_cost': productCost,
      'notes': notes,
    };
  }
}

class Order {
  final int id;
  final String? objectId; // Store the original MongoDB ObjectId string
  final String orderCode;
  final String customerName;
  final String? contact;
  final String? address;
  final String status;
  final String type;
  final String payment;
  final String? ref;
  final double totalPrice;
  final double discount;
  final double netTotal;
  final List<OrderItem> items;
  final DateTime? createdAt;

  Order({
    required this.id,
    this.objectId,
    required this.orderCode,
    required this.customerName,
    this.contact,
    this.address,
    required this.status,
    required this.type,
    required this.payment,
    this.ref,
    required this.totalPrice,
    required this.discount,
    required this.netTotal,
    this.items = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('Order.fromJson called with: $json');
    
    // Handle numeric fields as either string or number
    double totalPrice = 0.0;
    if (json['totalPrice'] != null) {
      if (json['totalPrice'] is String) {
        totalPrice = double.tryParse(json['totalPrice']) ?? 0.0;
      } else {
        totalPrice = (json['totalPrice'] as num).toDouble();
      }
    }
    
    double discount = 0.0;
    if (json['discount'] != null) {
      if (json['discount'] is String) {
        discount = double.tryParse(json['discount']) ?? 0.0;
      } else {
        discount = (json['discount'] as num).toDouble();
      }
    }
    
    double netTotal = 0.0;
    if (json['net_total'] != null) {
      if (json['net_total'] is String) {
        netTotal = double.tryParse(json['net_total']) ?? 0.0;
      } else {
        netTotal = (json['net_total'] as num).toDouble();
      }
    }

    // Handle ID as either MongoDB ObjectId (string) or integer
    int orderId = 0;
    String? objectId;
    
    if (json['id'] != null) {
      if (json['id'] is String) {
        objectId = json['id'] as String;
        orderId = json['id'].hashCode.abs();
      } else if (json['id'] is int) {
        orderId = json['id'] as int;
      }
    }
    
    // Also check for _id field (MongoDB primary key)
    if (json['_id'] != null && objectId == null) {
      if (json['_id'] is String) {
        objectId = json['_id'] as String;
        orderId = json['_id'].hashCode.abs();
      }
    }

    return Order(
      id: orderId,
      objectId: objectId,
      orderCode: json['order_code'] ?? '',
      customerName: json['name'] ?? '',
      contact: json['contact'],
      address: json['address'],
      status: json['status'] ?? 'Pending',
      type: json['type'] ?? 'Online',
      payment: json['payment'] ?? 'Cash',
      ref: json['ref'],
      totalPrice: totalPrice,
      discount: discount,
      netTotal: netTotal,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : (json['created_at'] != null 
              ? DateTime.tryParse(json['created_at']) 
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'objectId': objectId,
      'order_code': orderCode,
      'name': customerName,
      'contact': contact,
      'address': address,
      'status': status,
      'type': type,
      'payment': payment,
      'ref': ref,
      'totalPrice': totalPrice,
      'discount': discount,
      'net_total': netTotal,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'Pending';
  bool get isProcessing => status == 'Processing';
  bool get isDelivered => status == 'Delivered' || status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get canCancel => isPending;

  // Convenience: number of items and a human-readable summary
  int get totalItems => items.fold(0, (sum, it) => sum + it.quantity);
  String get itemsSummary => items.isEmpty
      ? ''
      : items.map((it) => '${it.name} × ${it.quantity}').join(', ');
}

// Extension to add copyWith method to Order
extension OrderCopyWith on Order {
  Order copyWith({
    int? id,
    String? objectId,
    String? orderCode,
    String? customerName,
    String? contact,
    String? address,
    String? status,
    String? type,
    String? payment,
    String? ref,
    double? totalPrice,
    double? discount,
    double? netTotal,
    List<OrderItem>? items,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      status: status ?? this.status,
      type: type ?? this.type,
      payment: payment ?? this.payment,
      ref: ref ?? this.ref,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      netTotal: netTotal ?? this.netTotal,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
