/// A product the shop sells, so there is something to view and check out.
final class Product {
  /// Creates a product.
  const Product(this.id, this.name, this.description, this.price);

  /// The id events carry as `product`.
  final String id;

  /// The display name.
  final String name;

  /// One line about it.
  final String description;

  /// The price in US dollars.
  final int price;

  /// The price for display.
  String get priceLabel => '\$$price.00';
}

/// The products the sample's shop sells.
abstract final class Catalog {
  /// Every product.
  static const List<Product> products = [
    Product('sneakers', 'Canvas sneakers', 'Lightweight trainers for every day', 79),
    Product('backpack', 'Leather backpack', 'Fits a 16-inch laptop', 129),
    Product('beanie', 'Wool beanie', 'Merino wool, one size', 24),
  ];

  /// The product a `brudcast-sample://checkout` link checks out.
  static Product get featured => products.first;

  /// Finds a product, or the featured one when the id is unknown.
  static Product product(String? id) => products.firstWhere((product) => product.id == id, orElse: () => featured);
}
