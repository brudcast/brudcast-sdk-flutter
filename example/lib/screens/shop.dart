import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../router.dart';

/// The product list.
class ShopScreen extends StatelessWidget {
  /// Creates the screen.
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shop')),
    body: ListView(
      children: [
        for (final product in Catalog.products)
          ListTile(
            key: Key('product-${product.id}'),
            title: Text(product.name),
            subtitle: Text(product.description),
            trailing: Text(product.priceLabel),
            onTap: () => Navigator.of(context).pushNamed(Routes.product, arguments: product.id),
          ),
      ],
    ),
  );
}

/// One product. Tracks `product_viewed`.
class ProductScreen extends StatefulWidget {
  /// Creates the screen. The route's argument is the product id.
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Product _product = Catalog.product(ModalRoute.of(context)?.settings.arguments as String?);
  bool _viewed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewed) return;
    _viewed = true;
    Brudcast.track('product_viewed', {'product': _product.id, 'price': _product.price});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_product.name)),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_product.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text(_product.priceLabel, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          FilledButton(
            key: const Key('checkout'),
            onPressed: () => Navigator.of(context).pushNamed(Routes.checkout, arguments: _product.id),
            child: const Text('Check out'),
          ),
        ],
      ),
    ),
  );
}

/// Checkout. Tracks `checkout_started` on arrival and `order_completed` on Place order.
class CheckoutScreen extends StatefulWidget {
  /// Creates the screen. The route's argument is the product id, or the featured product's.
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final Product _product = Catalog.product(ModalRoute.of(context)?.settings.arguments as String?);
  bool _started = false;
  bool _placed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    Brudcast.track('checkout_started', {'product': _product.id, 'total': _product.price});
  }

  Future<void> _place() async {
    await Brudcast.track('order_completed', {'product': _product.id, 'total': _product.price});
    setState(() => _placed = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_product.name}, ${_product.priceLabel}', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (_placed)
            const Text('Thanks for your order', textAlign: TextAlign.center)
          else
            FilledButton(key: const Key('placeOrder'), onPressed: _place, child: const Text('Place order')),
        ],
      ),
    ),
  );
}
