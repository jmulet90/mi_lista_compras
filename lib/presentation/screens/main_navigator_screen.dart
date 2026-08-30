import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../services/main_tab_controller.dart';
import '../widgets/floating_nav_bar.dart';
import 'category_container_screen.dart';

class MainNavigatorScreen extends StatefulWidget {
  const MainNavigatorScreen({super.key});

  @override
  State<MainNavigatorScreen> createState() => MainNavigatorScreenState();
}

class MainNavigatorScreenState extends State<MainNavigatorScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = MainTabController.index.value;

  late final AnimationController _shakeController;
  Timer? _shakeTimer;

  late final Stream<List<CategoryItem>> _categoriesStream =
      sl<CategoryRepository>().watchAll();
  late final Stream<List<Product>> _productsStream =
      sl<ProductRepository>().watchAll();

  void _handleTabChanged() {
    if (mounted) setState(() => _currentIndex = MainTabController.index.value);
  }

  @override
  void initState() {
    super.initState();
    MainTabController.index.addListener(_handleTabChanged);
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
    MainTabController.index.removeListener(_handleTabChanged);
    _shakeTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryItem>>(
      stream: _categoriesStream,
      builder: (context, categorySnapshot) {
        final categoriesLoading = !categorySnapshot.hasData;
        final categories = categorySnapshot.data ?? const <CategoryItem>[];
        return StreamBuilder<List<Product>>(
          stream: _productsStream,
          builder: (context, productSnapshot) {
            final productsLoading = !productSnapshot.hasData;
            final products = productSnapshot.data ?? const <Product>[];
            final isLoading = categoriesLoading || productsLoading;

            final categoryKeys = categories.map((c) => c.key).toSet();
            final buyProductsCount = products
                .where((p) => p.isToBuy == true && categoryKeys.contains(p.categoryKey))
                .length;
            final stockProductsCount = products
                .where((p) => p.isToBuy == false && categoryKeys.contains(p.categoryKey))
                .length;

return Scaffold(
              extendBody: true,
              body: CategoryContainerScreen(
                isBuyScreen: _currentIndex == 0,
                products: products,
                categories: categories,
                isLoading: isLoading,
              ),
              bottomNavigationBar: FloatingNavBar(
                currentIndex: _currentIndex,
                buyCount: buyProductsCount,
                stockCount: stockProductsCount,
                shake: _shakeController,
                onBuyTap: () => MainTabController.switchTo(0),
                onStockTap: () => MainTabController.switchTo(1),
              ),
            );
          },
        );
      },
);
  }
}

