import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'provider.dart';
import 'models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Colors.green,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.cart.isNotEmpty
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Cart'),
                            content: const Text(
                              'Are you sure you want to remove all items from your cart?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.clearCart();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: provider.cart.isNotEmpty ? Colors.white : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cart.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final cartItem = provider.cart[index];
                    return CartItemCard(cartItem: cartItem);
                  },
                ),
              ),
              // Cart summary
              Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Items:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${provider.cartItemCount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₱${provider.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: cartItem.product.hasImage && cartItem.product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: cartItem.product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cartItem.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${cartItem.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: cartItem.quantity > 1
                            ? () {
                                final provider = Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                );
                                provider.updateCartItemQuantity(
                                  cartItem.product,
                                  cartItem.quantity - 1,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: cartItem.quantity < cartItem.product.stock
                            ? () {
                                final provider = Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                );
                                provider.updateCartItemQuantity(
                                  cartItem.product,
                                  cartItem.quantity + 1,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button and total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    final provider = Provider.of<AppProvider>(
                      context,
                      listen: false,
                    );
                    provider.removeFromCart(cartItem.product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cartItem.product.name} removed from cart'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${cartItem.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
