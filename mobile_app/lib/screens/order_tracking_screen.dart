import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String _orderStatus = 'confirmed';

  final List<Map<String, dynamic>> _steps = [
    {'label': 'Order Placed', 'icon': Icons.shopping_cart, 'completed': true},
    {'label': 'Confirmed', 'icon': Icons.check_circle, 'completed': false},
    {'label': 'Preparing', 'icon': Icons.factory, 'completed': false},
    {
      'label': 'Out for Delivery',
      'icon': Icons.delivery_dining,
      'completed': false
    },
    {'label': 'Delivered', 'icon': Icons.home, 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Status Timeline
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ..._steps
                      .asMap()
                      .entries
                      .map((entry) => _buildTimelineStep(entry.key)),
                ],
              ),
            ),

            // Map Placeholder
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text('Live tracking map will appear here'),
                  ],
                ),
              ),
            ),

            // Delivery Info
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF9B59B6),
                  child: Icon(Icons.delivery_dining, color: Colors.white),
                ),
                title: const Text('Delivery Person'),
                subtitle: const Text('Assigning driver...'),
                trailing: const Icon(Icons.phone, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int index) {
    final step = _steps[index];
    final isActive =
        index <= _steps.indexWhere((s) => s['label'] == _orderStatus);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : Colors.grey.shade300,
              ),
              child: Icon(step['icon'], color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step['label'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        if (index < _steps.length - 1)
          Container(
            margin: const EdgeInsets.only(left: 20),
            width: 2,
            height: 30,
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
      ],
    );
  }
}
