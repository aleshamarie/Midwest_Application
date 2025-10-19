import 'package:flutter/material.dart';

class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  final List<Map<String, dynamic>> allProducts = [
{
  'name': 'Migwest Grocery Store',
  'desc': 'Midwest Grocery Store',
  'price': 0,
  'stock': '0',
  'image': 'Photo',
  'category': 'Midewest',
  'brand': 'Midewest'
},

    // Add more products with 'brand' and 'category' as needed
  ];

  final List<String> categories = [
    'Midwest',
  ];

  String selectedCategory = 'All';
  String selectedBrand = 'All';

  final Map<String, int> cart = {};
  final List<Map<String, dynamic>> orders = [];
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(allProducts);
  }

  List<String> getBrandsForCategory(String category) {
    final brands = <String>{};
    for (var p in allProducts) {
      if ((category == 'All' || (p['category']?.toLowerCase() == category.toLowerCase())) && p['brand'] != null) {
        brands.add(p['brand']);
      }
    }
    return ['All', ...brands.toList()..sort()];
  }

  void addToCart(Map<String, dynamic> product) {
    final name = product['name'];
    setState(() {
      final index = allProducts.indexWhere((p) => p['name'] == name && p['desc'] == product['desc']);
      if (index != -1 && allProducts[index]['stock'] > 0) {
        allProducts[index]['stock'] -= 1;
        cart[name] = (cart[name] ?? 0) + 1;
        filterProducts(isSearching ? searchController.text : '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added to cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more stock for $name')),
        );
      }
    });
  }

  void removeFromCart(String name) {
    setState(() {
      if (cart.containsKey(name) && cart[name]! > 0) {
        cart[name] = cart[name]! - 1;
        final index = allProducts.indexWhere((p) => p['name'] == name);
        if (index != -1) {
          allProducts[index]['stock'] += 1;
        }
        if (cart[name] == 0) {
          cart.remove(name);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from cart')),
        );
      }
    });
  }

  double get totalPrice {
    double total = 0.0;
    cart.forEach((name, qty) {
      final item = allProducts.firstWhere((p) => p['name'] == name);
      total += item['price'] * qty;
    });
    return total;
  }

  int get cartCount => cart.values.fold(0, (sum, val) => sum + val);

  void startSearch() => setState(() => isSearching = true);

  void stopSearch() {
    setState(() {
      isSearching = false;
      searchController.clear();
      filterProducts('');
    });
  }

  void filterProducts(String keyword) {
    setState(() {
      filteredProducts = allProducts.where((p) {
        final matchesCategory = selectedCategory == 'All' ||
            (p['category']?.toLowerCase() == selectedCategory.toLowerCase());
        final matchesBrand = selectedBrand == 'All' ||
            (p['brand']?.toLowerCase() == selectedBrand.toLowerCase());
        final matchesKeyword = p['name'].toLowerCase().contains(keyword.toLowerCase());
        return matchesCategory && matchesBrand && matchesKeyword;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: stopSearch,
                  ),
                ),
                onChanged: filterProducts,
              )
            : const Text('Browse Products'),
        backgroundColor: Colors.green,
        actions: [
          if (!isSearching)
            IconButton(icon: const Icon(Icons.search), onPressed: startSearch),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 10),
                        if (orders.isEmpty)
                          const Text('No orders yet.')
                        else
                          ...orders.asMap().entries.map((entry) {
                            final order = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer: ${order['customer']}'),
                                Text('Contact: ${order['contact']}'),
                                Text('Address: ${order['address']}'),
                                Text('Method: ${order['method']}'),
                                Text(
                                  'Status: ${order['status']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: order['status'] == 'Delivered'
                                        ? Colors.green
                                        : order['status'] == 'Shipped'
                                            ? Colors.blue
                                            : order['status'] == 'Processing'
                                                ? Colors.orange
                                                : Colors.red,
                                  ),
                                ),
                                ...List.from(order['items']).map((item) => Text(
                                    '• ${item['qty']}x ${item['name']} @ ₱${item['price']} = ₱${item['total']}')),
                                Text('Total: ₱${order['total'].toStringAsFixed(2)}'),
                                const Divider(),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart), onPressed: openCart),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Category:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                          selectedBrand = 'All';
                          filterProducts(isSearching ? searchController.text : '');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedCategory != 'All' && getBrandsForCategory(selectedCategory).length > 1) ...[
                  const Text(
                    'Select Brand:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: selectedBrand,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: getBrandsForCategory(selectedCategory).map((brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedBrand = value;
                            filterProducts(isSearching ? searchController.text : '');
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.asset(
                            product['image'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(product['desc'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('₱${product['price']}'),
                        Text('Stock: ${product['stock']}'),
                        Text(
                          'Category: ${product['category'] ?? "N/A"}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (product['brand'] != null)
                          Text(
                            'Brand: ${product['brand']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: product['stock'] > 0 ? () => addToCart(product) : null,
                            child: Text(product['stock'] > 0 ? 'Add to Cart' : 'Out of Stock'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void openCart() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (cart.isEmpty)
                const Text('Your cart is empty.')
              else
                ...cart.entries.map((entry) {
                  final product = allProducts.firstWhere((p) => p['name'] == entry.key);
                  return ListTile(
                    title: Text('${entry.key} (${product['desc']})'),
                    subtitle: Text('₱${product['price']} x ${entry.value}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Cancel item',
                      onPressed: () => removeFromCart(entry.key),
                    ),
                  );
                }),
              const Divider(),
              const Text('Customer Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      validator: (value) => value == null || value.isEmpty ? 'Contact number is required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) => value == null || value.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ₱${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          _showDeliveryOption(
                            name: nameController.text,
                            contact: contactController.text,
                            address: addressController.text,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Continue to Delivery Method'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryOption({required String name, required String contact, required String address}) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Delivery Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Pickup'),
              onTap: () {
                Navigator.pop(context);
                _showPaymentOption(
                  name: name,
                  contact: contact,
                  address: address,
                  method: 'Pickup',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text('Delivery'),
              onTap: () {
                Navigator.pop(context);
                _showPaymentOption(
                  name: name,
                  contact: contact,
                  address: address,
                  method: 'Delivery',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentOption({
    required String name,
    required String contact,
    required String address,
    required String method,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash on Delivery'),
              onTap: () {
                Navigator.pop(context);
                _addOrder(name, contact, address, '$method - Cash on Delivery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('GCash'),
              onTap: () {
                Navigator.pop(context);
                _showGCashPayment(
                  name: name,
                  contact: contact,
                  address: address,
                  method: method,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGCashPayment({
    required String name,
    required String contact,
    required String address,
    required String method,
  }) {
    final proofController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GCash Payment Owner: Anna Melissa De Jesus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Send payment to:\nGCash Number: 09171505564',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text('Upload Proof of Payment'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: proofController,
                  decoration: const InputDecoration(
                    labelText: 'Proof of Payment (Reference No. or Screenshot Link)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please provide proof of payment'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _addOrder(
                        name,
                        contact,
                        address,
                        '$method - GCash (Paid, Proof: ${proofController.text})',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Confirm Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addOrder(String name, String contact, String address, String method) {
    final List<Map<String, dynamic>> orderItems = cart.entries.map((entry) {
      final product = allProducts.firstWhere((p) => p['name'] == entry.key);
      return {
        'name': entry.key,
        'qty': entry.value,
        'price': product['price'],
        'total': product['price'] * entry.value
      };
    }).toList();

    setState(() {
      orders.add({
        'customer': name,
        'contact': contact,
        'address': address,
        'method': method,
        'items': orderItems,
        'total': totalPrice,
        'status': 'Pending',
      });
      cart.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order confirmed for $method')),
    );
  }

  Widget buildOrderStatus(String status) {
    int step = 0;
    switch (status) {
      case 'Pending':
        step = 0;
        break;
      case 'Processing':
        step = 1;
        break;
      case 'Delivered':
        step = 2;
        break;
    }
    return Stepper(
      currentStep: step,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      steps: const [
        Step(title: Text('Pending'), content: SizedBox.shrink()),
        Step(title: Text('Processing'), content: SizedBox.shrink()),
        Step(title: Text('Delivered'), content: SizedBox.shrink()),
      ],
    );
  }
}