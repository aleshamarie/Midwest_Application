import 'product.dart';
import 'variant.dart';

class CartItem {
  final Product product;
  final int quantity;
  final Variant? variant;

  CartItem({
    required this.product,
    required this.quantity,
    this.variant,
  });

  double get totalPrice => (variant?.price ?? product.price) * quantity;
  
  // Get display name with variant
  String get displayName {
    if (variant != null) {
      return '${product.name} (${variant!.displayName})';
    }
    return product.name;
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
    Variant? variant,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }

  Map<String, dynamic> toJson() {
    print('CartItem.toJson: Product ${product.name} with ID ${product.id} (dart_hash: ${product.id})');
    final price = variant?.price ?? product.price;
    return {
      'product_id': product.id,
      'quantity': quantity,
      'price': price,
      'total': totalPrice,
      'variant_id': variant?.id,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json, Product product) {
    int quantity = 0;
    if (json['quantity'] != null) {
      if (json['quantity'] is String) {
        quantity = int.tryParse(json['quantity']) ?? 0;
      } else if (json['quantity'] is num) {
        final numValue = json['quantity'] as num;
        if (numValue.isFinite) {
          quantity = numValue.toInt();
        } else {
          print('CartItem: Invalid quantity value (Infinity/NaN), using 0');
          quantity = 0;
        }
      } else if (json['quantity'] is int) {
        quantity = json['quantity'] as int;
      }
    }

    // Find variant if variant_id is provided
    Variant? variant;
    if (json['variant_id'] != null && product.variants.isNotEmpty) {
      variant = product.variants.firstWhere(
        (v) => v.id == json['variant_id'].toString(),
        orElse: () => product.variants.first,
      );
    }

    return CartItem(
      product: product,
      quantity: quantity,
      variant: variant,
    );
  }
  
  // Check if two cart items are the same (same product and variant)
  bool isSameItem(CartItem other) {
    if (product.id != other.product.id) return false;
    if (variant?.id != other.variant?.id) return false;
    return true;
  }
}
