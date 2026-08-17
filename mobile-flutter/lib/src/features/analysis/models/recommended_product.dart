class RecommendedProduct {
  const RecommendedProduct({
    required this.name,
    required this.brand,
    required this.price,
    required this.currency,
  });

  final String name;
  final String brand;
  final String price;
  final String currency;

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      name: json['name']?.toString() ?? 'Product',
      brand: json['brand']?.toString() ?? 'Skin Care',
      price: json['price']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
    );
  }
}
