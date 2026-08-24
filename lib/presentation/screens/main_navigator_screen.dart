import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../localization/app_localizations.dart';
import 'category_container_screen.dart';

class MainNavigatorScreen extends StatefulWidget {
  const MainNavigatorScreen({super.key});

  @override
  State<MainNavigatorScreen> createState() => MainNavigatorScreenState();
}

class MainNavigatorScreenState extends State<MainNavigatorScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _shakeController;
  Timer? _shakeTimer;

  late final Stream<List<CategoryItem>> _categoriesStream =
      sl<CategoryRepository>().watchAll();
  late final Stream<List<Product>> _productsStream =
      sl<ProductRepository>().watchAll();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Primera sacudida al entrar y repetición cada 10 segundos.
    _shakeController.forward();
    _shakeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _shakeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return StreamBuilder<List<CategoryItem>>(
      stream: _categoriesStream,
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? const <CategoryItem>[];
        return StreamBuilder<List<Product>>(
          stream: _productsStream,
          builder: (context, productSnapshot) {
            final products = productSnapshot.data ?? const <Product>[];

            final categoryKeys = categories.map((c) => c.key).toSet();
            final buyProductsCount = products
                .where((p) => p.isToBuy == true && categoryKeys.contains(p.categoryKey))
                .length;
            final stockProductsCount = products
                .where((p) => p.isToBuy == false && categoryKeys.contains(p.categoryKey))
                .length;

            return Scaffold(
              body: CategoryContainerScreen(
                isBuyScreen: _currentIndex == 0,
                products: products,
                categories: categories,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentIndex == 0 ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentIndex == 0
                                ? Icons.shopping_cart
                                : Icons.shopping_cart_outlined,
                            size: 26,
                            color: _currentIndex == 0 ? Colors.red.shade700 : Colors.blueGrey.shade400,
                          ),
                        ),
                        if (buyProductsCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                // Oscilación horizontal durante los 3 segundos.
                                final angle =
                                    _shakeController.value * 6 * 2 * math.pi;
                                return Transform.translate(
                                  offset: Offset(math.sin(angle) * 4, 0),
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$buyProductsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: t.navBuy,
                  ),
                  NavigationDestination(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentIndex == 1 ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentIndex == 1
                                ? Icons.home_rounded
                                : Icons.home_outlined,
                            size: 26,
                            color: _currentIndex == 1 ? Colors.green.shade700 : Colors.blueGrey.shade400,
                          ),
                        ),
                        if (stockProductsCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$stockProductsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: t.navStock,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
