import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'provider.dart';
import 'config/api_config.dart';

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
  File? _paymentProofImage;
  Uint8List? _paymentProofImageBytes; // For web platform
  bool _agreedToTerms = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions and Privacy Policy to place your order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_paymentMethod == 'GCash' && (_paymentRef == null || _paymentRef!.isEmpty) && 
        (kIsWeb ? _paymentProofImageBytes == null : _paymentProofImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide GCash payment reference or upload payment proof screenshot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Prevent multiple rapid submissions
    if (provider.isCreatingOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order is already being processed. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      print('Starting order creation process...');
      final orderId = await provider.createOrder(
        customerName: _nameController.text,
        contact: _contactController.text,
        address: _addressController.text,
        paymentMethod: _paymentMethod,
        paymentRef: _paymentRef,
      );

      print('Order creation result: $orderId');

      if (orderId != null) {
        // Upload payment proof image if available
        if ((kIsWeb ? _paymentProofImageBytes != null : _paymentProofImage != null) && _paymentMethod == 'GCash') {
          try {
            await _uploadPaymentProof(orderId);
          } catch (e) {
            print('Error uploading payment proof: $e');
            // Don't fail the order if image upload fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order created but payment proof upload failed: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
        
        if (mounted) {
          print('Order created successfully, showing success message');
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
          print('Order creation failed, showing error message');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place order. Please check your internet connection and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Exception during order creation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickPaymentProofImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // On web, read bytes directly
          final bytes = await image.readAsBytes();
          setState(() {
            _paymentProofImageBytes = bytes;
          });
        } else {
          // On mobile, use File
          setState(() {
            _paymentProofImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPaymentProof(String orderId) async {
    if (kIsWeb) {
      if (_paymentProofImageBytes == null) return;
    } else {
      if (_paymentProofImage == null) return;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/payment-proof/public');
      final request = http.MultipartRequest('POST', uri);
      
      if (kIsWeb) {
        // On web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _paymentProofImageBytes!,
            filename: 'payment_proof.jpg',
            contentType: http.MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // On mobile, use file path
        // Get file extension to determine mimetype
        final filePath = _paymentProofImage!.path;
        final extension = filePath.split('.').last.toLowerCase();
        String mimeSubtype = 'jpeg'; // default
        
        if (extension == 'png') {
          mimeSubtype = 'png';
        } else if (extension == 'gif') {
          mimeSubtype = 'gif';
        } else if (extension == 'webp') {
          mimeSubtype = 'webp';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          mimeSubtype = 'jpeg';
        }
        
        // Ensure filename has proper extension
        final filename = filePath.split('/').last;
        final finalFilename = filename.contains('.') ? filename : '$filename.jpg';
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            filePath,
            filename: finalFilename,
            contentType: http.MediaType('image', mimeSubtype),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Payment proof uploaded successfully');
      } else {
        throw Exception('Failed to upload payment proof: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error uploading payment proof: $e');
      rethrow;
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
                              labelText: 'Payment Reference',
                              hintText: 'Enter GCash reference number (optional if uploading screenshot)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _paymentRef = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Payment Proof Screenshot',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickPaymentProofImage,
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: (kIsWeb ? _paymentProofImageBytes != null : _paymentProofImage != null)
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: kIsWeb
                                              ? Image.memory(
                                                  _paymentProofImageBytes!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : Image.file(
                                                  _paymentProofImage!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black54,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (kIsWeb) {
                                                  _paymentProofImageBytes = null;
                                                } else {
                                                  _paymentProofImage = null;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to select screenshot',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if ((kIsWeb ? _paymentProofImageBytes == null : _paymentProofImage == null) && 
                              (_paymentRef == null || _paymentRef!.isEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Please provide either payment reference or upload screenshot',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Terms and conditions agreement checkbox
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CheckboxListTile(
                        title: const Text(
                          'I agree to the Terms and Conditions and Privacy Policy',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'By checking this box, you confirm that you have read and agree to our terms and privacy policy',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Place order button
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (provider.isCreatingOrder || !_agreedToTerms) ? null : _processOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: provider.isCreatingOrder
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
                        );
                      },
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
