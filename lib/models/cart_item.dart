import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    print('CartItem.toJson: Product ${product.name} with ID ${product.id} (dart_hash: ${product.id})');
    return {
      'product_id': product.id,
      'quantity': quantity,
      'price': product.price,
      'total': totalPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json, Product product) {
    int quantity = 0;
    if (json['quantity'] != null) {
      if (json['quantity'] is String) {
        quantity = int.tryParse(json['quantity']) ?? 0;
      } else {
        quantity = json['quantity'] as int;
      }
    }

    return CartItem(
      product: product,
      quantity: quantity,
    );
  }
}
