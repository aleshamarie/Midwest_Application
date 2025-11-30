import 'variant.dart';

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
  final List<Variant> variants;

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
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle price as either string or number
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      } else if (json['price'] is num) {
        final numValue = json['price'] as num;
        // Check for Infinity or NaN
        if (numValue.isFinite) {
          price = numValue.toDouble();
        } else {
          print('Product ${json['name']}: Invalid price value (Infinity/NaN), using 0.0');
          price = 0.0;
        }
      }
    }
    
    // Handle stock as either string or number
    int stock = 0;
    if (json['stock'] != null) {
      if (json['stock'] is String) {
        stock = int.tryParse(json['stock']) ?? 0;
      } else if (json['stock'] is num) {
        final numValue = json['stock'] as num;
        // Check for Infinity or NaN
        if (numValue.isFinite) {
          stock = numValue.toInt();
        } else {
          print('Product ${json['name']}: Invalid stock value (Infinity/NaN), using 0');
          stock = 0;
        }
      } else if (json['stock'] is int) {
        stock = json['stock'] as int;
      }
    }

    // Handle ID as either MongoDB ObjectId (string) or integer
    int productId = 0;
    if (json['id'] != null) {
      if (json['id'] is String) {
        // For MongoDB ObjectId strings, use a hash of the string as int
        productId = json['id'].hashCode.abs();
        print('Product ${json['name']}: ObjectId ${json['id']} -> dart_hash: $productId');
      } else if (json['id'] is int) {
        productId = json['id'] as int;
        print('Product ${json['name']}: Using integer ID: $productId');
      }
    }
    
    // Also check for _id field (MongoDB primary key)
    if (json['_id'] != null && productId == 0) {
      if (json['_id'] is String) {
        productId = json['_id'].hashCode.abs();
      }
    }

    // Handle image URL - prioritize image_url (Cloudinary), then image (legacy), then thumbnail_url
    String? finalImageUrl = json['image_url'] ?? json['image'] ?? json['thumbnail_url'];
    
    // Debug: Print all image-related fields
    print('Product ${json['name']}:');
    print('  - image_url: ${json['image_url']}');
    print('  - image: ${json['image']}');
    print('  - thumbnail_url: ${json['thumbnail_url']}');
    print('  - has_image: ${json['has_image']}');
    print('  - Final imageUrl: $finalImageUrl');
    
    // Check if it's a valid image URL
    bool hasImage = false;
    if (finalImageUrl != null && finalImageUrl.isNotEmpty) {
      hasImage = true;
      
      // Check the type of image URL
      if (finalImageUrl.startsWith('https://res.cloudinary.com/')) {
        print('Product ${json['name']}: Found Cloudinary URL');
      } else if (finalImageUrl.startsWith('data:')) {
        print('Product ${json['name']}: Found base64 data URL (legacy)');
      } else if (finalImageUrl.startsWith('http')) {
        print('Product ${json['name']}: Found HTTP URL');
      } else {
        // This is likely a relative path, we'll let ApiService.getImageUrl handle it
        print('Product ${json['name']}: Found relative image path: $finalImageUrl');
      }
    } else {
      print('Product ${json['name']}: No image URL found');
    }

    // Parse variants if they exist
    List<Variant> variants = [];
    if (json['variants'] != null && json['variants'] is List) {
      variants = (json['variants'] as List)
          .map((v) => Variant.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: productId,
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      price: price,
      stock: stock,
      image: json['image'],
      imageUrl: finalImageUrl,
      placeholderUrl: json['placeholder_url'],
      thumbnailUrl: json['thumbnail_url'],
      hasImage: hasImage,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      variants: variants,
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
      'variants': variants.map((v) => v.toJson()).toList(),
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
    List<Variant>? variants,
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
      variants: variants ?? this.variants,
    );
  }

  bool get isOutOfStock => variants.isNotEmpty 
      ? variants.every((v) => v.isOutOfStock)
      : stock <= 0;
  bool get isLowStock => variants.isNotEmpty
      ? variants.any((v) => v.isLowStock) && !isOutOfStock
      : stock > 0 && stock <= 5;
  
  // Get available variants (not out of stock)
  List<Variant> get availableVariants => variants.where((v) => !v.isOutOfStock).toList();
  
  // Check if product has variants
  bool get hasVariants => variants.isNotEmpty;
}
