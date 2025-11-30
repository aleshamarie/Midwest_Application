import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider.dart';
import 'models/order.dart';
import 'services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadOrders();
    });
  }

  void cancelOrder(Order order) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateOrderStatus(order.id, 'Cancelled');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order has been cancelled.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.green,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await provider.loadOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orders refreshed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingOrders) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your orders will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              return OrderCard(order: order, onCancel: cancelOrder);
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(Order) onCancel;

  const OrderCard({
    super.key,
    required this.order,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderCode}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customer: ${order.customerName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (order.contact != null) ...[
              const SizedBox(height: 4),
              Text(
                'Contact: ${order.contact}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (order.address != null) ...[
              const SizedBox(height: 4),
              Text(
                'Address: ${order.address}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Method: ${order.type}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Payment: ${order.payment}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            // GCash reference and payment proof
            if (order.payment == 'GCash' && order.ref != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'GCash Reference:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.ref!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Payment proof image
                    if (order.paymentProofImageUrl != null && order.paymentProofImageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Payment Proof:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Open image in full screen
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppBar(
                                    title: const Text('Payment Proof'),
                                    leading: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                  Expanded(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        order.paymentProofImageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Text('Failed to load image'),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            maxWidth: double.infinity,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              order.paymentProofImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            OrderStatusWidget(status: order.status),
            const SizedBox(height: 16),
            // Items list (auto-loads from server if empty)
            OrderItemsList(order: order),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₱${order.netTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (order.canCancel)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => onCancel(order),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Delivered':
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class OrderStatusWidget extends StatelessWidget {
  final String status;

  const OrderStatusWidget({super.key, required this.status});

  int getStepStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return 1;
      case 'Processing':
        return 2;
      case 'Delivered':
      case 'Completed':
        return 3;
      case 'Cancelled':
        return 0;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = getStepStatus(status);
    final List<String> steps = ['Pending', 'Processing', 'Delivered'];

    if (status == 'Cancelled') {
      return const Text(
        'Order Cancelled',
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    return Column(
      children: List.generate(steps.length, (index) {
        return OrderStep(
          stepNumber: index + 1,
          label: steps[index],
          isActive: (index + 1) <= currentStep,
        );
      }),
    );
  }
}

class OrderItemsList extends StatefulWidget {
  final Order order;
  const OrderItemsList({super.key, required this.order});

  @override
  State<OrderItemsList> createState() => _OrderItemsListState();
}

class _OrderItemsListState extends State<OrderItemsList> {
  bool _loading = false;
  List<OrderItem> _items = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _items = widget.order.items;
    if (_items.isEmpty) _fetch();
  }

  Future<void> _fetch() async {
    setState(() { 
      _loading = true; 
      _error = null;
    });
    try {
      print('Fetching order items for order ${widget.order.id}');
      final res = await ApiService.getOrder(widget.order.id, objectId: widget.order.objectId);
      print('Order response: $res');
      
      final json = res['order'] as Map<String, dynamic>?;
      if (json != null) {
        print('Order JSON: $json');
        final items = (json['items'] as List<dynamic>?)
                ?.map((it) {
                  print('Processing item: $it');
                  return OrderItem.fromJson(it as Map<String, dynamic>);
                })
                .toList() ??
            [];
        print('Parsed items: $items');
        
        if (items.isNotEmpty) {
          setState(() { _items = items; });
        } else {
          // Try the dedicated order items endpoint
          print('No items found in order, trying dedicated items endpoint...');
          try {
            final itemsRes = await ApiService.getOrderItems(widget.order.id, objectId: widget.order.objectId);
            print('Order items response: $itemsRes');
            
            final itemsList = (itemsRes['items'] as List<dynamic>?)
                ?.map((it) {
                  print('Processing item from items endpoint: $it');
                  return OrderItem.fromJson(it as Map<String, dynamic>);
                })
                .toList() ?? [];
            
            print('Parsed items from items endpoint: $itemsList');
            setState(() { _items = itemsList; });
          } catch (itemsError) {
            print('Error fetching from items endpoint: $itemsError');
            setState(() { _error = 'No items found in order'; });
          }
        }
      } else {
        setState(() { _error = 'No order data found'; });
      }
    } catch (e) {
      print('Error fetching order items: $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Error loading items: $_error',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
    
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No items found',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items Ordered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total')),
            ],
            rows: _items.map((it) {
              final total = (it.price * it.quantity);
              return DataRow(cells: [
                DataCell(SizedBox(width: 160, child: Text(it.name, overflow: TextOverflow.ellipsis))),
                DataCell(Text('${it.quantity}')),
                DataCell(Text('₱${it.price.toStringAsFixed(2)}')),
                DataCell(Text('₱${total.toStringAsFixed(2)}')),
              ]);
            }).toList(),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

class OrderStep extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;

  const OrderStep({
    super.key,
    required this.stepNumber,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor = isActive ? Colors.green : Colors.grey;
    final Color textColor = isActive ? Colors.black : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: circleColor,
              child: Text(
                '$stepNumber',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            if (stepNumber != 3)
              Container(
                height: 40,
                width: 2,
                color: Colors.grey[400],
              ),
          ],
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
      ],
    );
  }
}