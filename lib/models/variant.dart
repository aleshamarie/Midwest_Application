class Variant {
  final String? id;
  final String? name;
  final String? sku;
  final double price;
  final double cost;
  final int stock;
  final List<String> barcodes;
  final String? option1Name;
  final String? option1Value;
  final String? option2Name;
  final String? option2Value;
  final String? option3Name;
  final String? option3Value;
  final bool trackStock;
  final bool availableForSale;
  final int lowStockThreshold;
  final String? imageUrl;
  final String? imagePublicId;

  Variant({
    this.id,
    this.name,
    this.sku,
    required this.price,
    this.cost = 0.0,
    required this.stock,
    this.barcodes = const [],
    this.option1Name,
    this.option1Value,
    this.option2Name,
    this.option2Value,
    this.option3Name,
    this.option3Value,
    this.trackStock = true,
    this.availableForSale = true,
    this.lowStockThreshold = 5,
    this.imageUrl,
    this.imagePublicId,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    // Handle price
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      } else if (json['price'] is num) {
        final numValue = json['price'] as num;
        if (numValue.isFinite) {
          price = numValue.toDouble();
        } else {
          price = 0.0;
        }
      }
    }

    // Handle stock
    int stock = 0;
    if (json['stock'] != null) {
      if (json['stock'] is String) {
        stock = int.tryParse(json['stock']) ?? 0;
      } else if (json['stock'] is num) {
        final numValue = json['stock'] as num;
        if (numValue.isFinite) {
          stock = numValue.toInt();
        } else {
          stock = 0;
        }
      } else if (json['stock'] is int) {
        stock = json['stock'] as int;
      }
    }

    // Handle barcodes
    List<String> barcodes = [];
    if (json['barcodes'] != null && json['barcodes'] is List) {
      barcodes = (json['barcodes'] as List)
          .map((b) => b?.toString() ?? '')
          .where((b) => b.isNotEmpty)
          .toList()
          .cast<String>();
    }

    return Variant(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
      price: price,
      cost: (json['cost'] is num) ? (json['cost'] as num).toDouble() : 0.0,
      stock: stock,
      barcodes: barcodes,
      option1Name: json['option1_name']?.toString(),
      option1Value: json['option1_value']?.toString(),
      option2Name: json['option2_name']?.toString(),
      option2Value: json['option2_value']?.toString(),
      option3Name: json['option3_name']?.toString(),
      option3Value: json['option3_value']?.toString(),
      trackStock: json['track_stock'] ?? true,
      availableForSale: json['available_for_sale'] ?? true,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      imageUrl: json['image_url']?.toString(),
      imagePublicId: json['image_public_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'cost': cost,
      'stock': stock,
      'barcodes': barcodes,
      'option1_name': option1Name,
      'option1_value': option1Value,
      'option2_name': option2Name,
      'option2_value': option2Value,
      'option3_name': option3Name,
      'option3_value': option3Value,
      'track_stock': trackStock,
      'available_for_sale': availableForSale,
      'low_stock_threshold': lowStockThreshold,
      'image_url': imageUrl,
      'image_public_id': imagePublicId,
    };
  }
  
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;

  // Get display name for variant (combines option values)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    final parts = <String>[];
    if (option1Value != null && option1Value!.isNotEmpty) {
      parts.add(option1Value!);
    }
    if (option2Value != null && option2Value!.isNotEmpty) {
      parts.add(option2Value!);
    }
    if (option3Value != null && option3Value!.isNotEmpty) {
      parts.add(option3Value!);
    }
    return parts.isEmpty ? 'Default' : parts.join(' / ');
  }
}

