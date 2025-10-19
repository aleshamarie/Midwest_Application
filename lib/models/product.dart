class Product {
  final int id;
  final String name;
  final String? category;
  final String? description;
  final double price;
  final int stock;
  final String? image;
  final String? imageUrl;
  final String? placeholderUrl;
  final String? thumbnailUrl;
  final bool hasImage;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    this.category,
    this.description,
    required this.price,
    required this.stock,
    this.image,
    this.imageUrl,
    this.placeholderUrl,
    this.thumbnailUrl,
    this.hasImage = false,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle price as either string or number
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      } else {
        price = (json['price'] as num).toDouble();
      }
    }
    
    // Handle stock as either string or number
    int stock = 0;
    if (json['stock'] != null) {
      if (json['stock'] is String) {
        stock = int.tryParse(json['stock']) ?? 0;
      } else {
        stock = json['stock'] as int;
      }
    }

    // Handle ID as either MongoDB ObjectId (string) or integer
    int productId = 0;
    if (json['id'] != null) {
      if (json['id'] is String) {
        // For MongoDB ObjectId strings, use a hash of the string as int
        productId = json['id'].hashCode.abs();
      } else if (json['id'] is int) {
        productId = json['id'] as int;
      }
    }
    
    // Also check for _id field (MongoDB primary key)
    if (json['_id'] != null && productId == 0) {
      if (json['_id'] is String) {
        productId = json['_id'].hashCode.abs();
      }
    }

    return Product(
      id: productId,
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      price: price,
      stock: stock,
      image: json['image'],
      imageUrl: json['image_url'],
      placeholderUrl: json['placeholder_url'],
      thumbnailUrl: json['thumbnail_url'],
      hasImage: json['has_image'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
      'image_url': imageUrl,
      'placeholder_url': placeholderUrl,
      'thumbnail_url': thumbnailUrl,
      'has_image': hasImage,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    double? price,
    int? stock,
    String? image,
    String? imageUrl,
    String? placeholderUrl,
    String? thumbnailUrl,
    bool? hasImage,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      placeholderUrl: placeholderUrl ?? this.placeholderUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hasImage: hasImage ?? this.hasImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;
}
