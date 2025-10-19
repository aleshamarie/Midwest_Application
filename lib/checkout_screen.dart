import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _deliveryMethod = 'Pickup';
  String _paymentMethod = 'Cash';
  String? _paymentRef;
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_paymentMethod == 'GCash' && (_paymentRef == null || _paymentRef!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide GCash payment reference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final success = await provider.createOrder(
        customerName: _nameController.text,
        contact: _contactController.text,
        address: _addressController.text,
        paymentMethod: _paymentMethod,
        paymentRef: _paymentRef,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...provider.cart.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} x${item.quantity}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '₱${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Customer information
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number *',
                      hintText: 'Enter 11-digit phone number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your contact number';
                      }
                      if (value.length != 11) {
                        return 'Contact number must be exactly 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Delivery method
                  const Text(
                    'Delivery Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  RadioListTile<String>(
                    title: const Text('Pickup'),
                    subtitle: const Text('Pick up at store location'),
                    value: 'Pickup',
                    groupValue: _deliveryMethod,
                    onChanged: (value) {
                      setState(() {
                        _deliveryMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Delivery'),
                    subtitle: const Text('Home delivery service'),
                    value: 'Delivery',
                    groupValue: _deliveryMethod,
                    onChanged: (value) {
                      setState(() {
                        _deliveryMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment method
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery'),
                    subtitle: const Text('Pay when you receive your order'),
                    value: 'Cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                        _paymentRef = null;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('GCash'),
                    subtitle: const Text('Pay via GCash'),
                    value: 'GCash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  
                  // GCash payment details
                  if (_paymentMethod == 'GCash') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GCash Payment Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Account: Anna Melissa De Jesus',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Text(
                            'Number: 09171505564',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Payment Reference *',
                              hintText: 'Enter GCash reference number or screenshot link',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _paymentRef = value;
                            },
                            validator: (value) {
                              if (_paymentMethod == 'GCash' && (value == null || value.isEmpty)) {
                                return 'Please enter payment reference';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Place order button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing Order...'),
                              ],
                            )
                          : const Text(
                              'Place Order',
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
          );
        },
      ),
    );
  }
}
