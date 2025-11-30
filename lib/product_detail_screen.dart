import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'provider.dart';
import 'models/product.dart';
import 'models/variant.dart';
import 'widgets/smart_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  Variant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    // Debug: Log product info when screen loads
    print('ProductDetailScreen: Product name: ${widget.product.name}');
    print('ProductDetailScreen: Has variants: ${widget.product.hasVariants}');
    print('ProductDetailScreen: Variants count: ${widget.product.variants.length}');
    if (widget.product.variants.isNotEmpty) {
      print('ProductDetailScreen: First variant: ${widget.product.variants.first.displayName}');
    }
    
    // Auto-select first available variant if product has variants
    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      final availableVariants = widget.product.availableVariants;
      if (availableVariants.isNotEmpty) {
        _selectedVariant = availableVariants.first;
        print('ProductDetailScreen: Auto-selected variant: ${_selectedVariant!.displayName}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.green,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // Navigate to cart screen
                    },
                  ),
                  if (provider.cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${provider.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image - show variant image if selected, otherwise product image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: SmartImage(
                imageUrl: _getDisplayImageUrl(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            ),
            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price - show selected variant price or product price
                  Text(
                    '₱${(_selectedVariant?.price ?? widget.product.price).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Variant Selection (Shopee/TikTok Shop style)
                  if (widget.product.hasVariants) ...[
                    _buildVariantSection(),
                    const SizedBox(height: 16),
                  ],
                  // Stock status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStockColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStockText(),
                      style: TextStyle(
                        color: _getStockTextColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category
                  if (widget.product.category != null) ...[
                    Row(
                      children: [
                        const Text(
                          'Category: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.product.category!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Description
                  if (widget.product.description != null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Quantity selector
                  if (!_isOutOfStock()) ...[
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 ? () {
                            setState(() {
                              _quantity--;
                            });
                          } : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < _getMaxStock() ? () {
                            setState(() {
                              _quantity++;
                            });
                          } : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Max: ${_getMaxStock()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isOutOfStock()
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Total price
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₱${((_selectedVariant?.price ?? widget.product.price) * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add to cart button
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        onPressed: () {
                          // If product has variants and one is selected, add with variant
                          if (widget.product.hasVariants && _selectedVariant != null) {
                            provider.addToCart(
                              widget.product,
                              quantity: _quantity,
                              variant: _selectedVariant,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${widget.product.name} (${_selectedVariant!.displayName}) (x$_quantity) added to cart',
                                ),
                                backgroundColor: Colors.green,
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Navigate to cart
                                  },
                                ),
                              ),
                            );
                          } else {
                            // No variants or no variant selected, add directly to cart
                            provider.addToCart(
                              widget.product, 
                              quantity: _quantity,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${widget.product.name} (x$_quantity) added to cart',
                                ),
                                backgroundColor: Colors.green,
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Navigate to cart
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Build variant selection section
  Widget _buildVariantSection() {
    // Debug: Check if variants exist
    print('Building variant section. Product has ${widget.product.variants.length} variants');
    
    if (widget.product.variants.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Variant:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        // Variant chips/buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            final isOutOfStock = variant.isOutOfStock;
            
            return GestureDetector(
              onTap: isOutOfStock ? null : () {
                setState(() {
                  _selectedVariant = variant;
                  _quantity = 1; // Reset quantity when variant changes
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.grey[200]
                      : isSelected
                          ? Colors.green
                          : Colors.white,
                  border: Border.all(
                    color: isOutOfStock
                        ? Colors.grey[300]!
                        : isSelected
                            ? Colors.green
                            : Colors.grey[400]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Variant image thumbnail if available
                    if (variant.hasImage) ...[
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SmartImage(
                            imageUrl: variant.imageUrl!,
                            fit: BoxFit.cover,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      variant.displayName,
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.grey[600]
                            : isSelected
                                ? Colors.white
                                : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                    if (isOutOfStock) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Out of Stock)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Show selected variant details
        if (_selectedVariant != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedVariant!.displayName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedVariant!.sku != null && _selectedVariant!.sku!.isNotEmpty)
                        Text(
                          'SKU: ${_selectedVariant!.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₱${_selectedVariant!.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Helper methods for stock management
  bool _isOutOfStock() {
    if (widget.product.hasVariants) {
      if (_selectedVariant == null) {
        return widget.product.isOutOfStock;
      }
      return _selectedVariant!.isOutOfStock;
    }
    return widget.product.isOutOfStock;
  }

  int _getMaxStock() {
    if (widget.product.hasVariants && _selectedVariant != null) {
      return _selectedVariant!.stock;
    }
    return widget.product.stock;
  }

  Color _getStockColor() {
    if (_isOutOfStock()) {
      return Colors.red[100]!;
    }
    if (widget.product.hasVariants && _selectedVariant != null) {
      return _selectedVariant!.isLowStock
          ? Colors.orange[100]!
          : Colors.green[100]!;
    }
    return widget.product.isLowStock
        ? Colors.orange[100]!
        : Colors.green[100]!;
  }

  Color _getStockTextColor() {
    if (_isOutOfStock()) {
      return Colors.red[800]!;
    }
    if (widget.product.hasVariants && _selectedVariant != null) {
      return _selectedVariant!.isLowStock
          ? Colors.orange[800]!
          : Colors.green[800]!;
    }
    return widget.product.isLowStock
        ? Colors.orange[800]!
        : Colors.green[800]!;
  }

  String _getStockText() {
    if (_isOutOfStock()) {
      return 'Out of Stock';
    }
    final stock = _getMaxStock();
    if (widget.product.hasVariants && _selectedVariant != null) {
      if (_selectedVariant!.isLowStock) {
        return 'Low Stock ($stock left)';
      }
      return 'In Stock ($stock available)';
    }
    if (widget.product.isLowStock) {
      return 'Low Stock ($stock left)';
    }
    return 'In Stock ($stock available)';
  }
  
  // Get image URL - prioritize variant image if selected, otherwise product image
  String? _getDisplayImageUrl() {
    if (_selectedVariant != null && _selectedVariant!.hasImage) {
      return _selectedVariant!.imageUrl;
    }
    return widget.product.imageUrl ?? widget.product.thumbnailUrl ?? widget.product.image;
  }

}
