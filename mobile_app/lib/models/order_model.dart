class Order {
  final int id;
  final int buyerId;
  final int productId;
  final int farmerId;
  final String productName;
  final String farmerName;
  final double quantity;
  final String unit;
  final double totalPrice;
  final String status;
  final String? deliveryAddress;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.farmerId,
    required this.productName,
    required this.farmerName,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    required this.status,
    this.deliveryAddress,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      farmerId: json['farmer_id'] ?? 0,
      productName: json['product_name'] ?? '',
      farmerName: json['farmer_name'] ?? '',
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      unit: json['unit'] ?? 'kg',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'confirmed':
        return '✅ Confirmed';
      case 'processing':
        return '🚚 Processing';
      case 'shipped':
        return '📦 Shipped';
      case 'delivered':
        return '🏠 Delivered';
      case 'cancelled':
        return '❌ Cancelled';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'processing':
        return '🚚';
      case 'shipped':
        return '📦';
      case 'delivered':
        return '🏠';
      case 'cancelled':
        return '❌';
      default:
        return '📋';
    }
  }
}
