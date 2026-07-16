class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double quantity;
  final String unit;
  final String farmer;
  final String? farmerLocation;
  final int farmerId;
  final String? imageUrl;
  final String status;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.farmer,
    this.farmerLocation,
    required this.farmerId,
    this.imageUrl,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['product_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      unit: json['unit'] ?? 'kg',
      farmer: json['farmer'] ?? '',
      farmerLocation: json['farmer_location'] ?? json['location'],
      farmerId: json['farmer_id'] ?? 0,
      imageUrl: json['image_url'] != null &&
              json['image_url'] != 'null' &&
              json['image_url'] != ''
          ? json['image_url']
          : null,
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'farmer': farmer,
      'farmer_id': farmerId,
      'image_url': imageUrl,
      'status': status,
    };
  }
}
