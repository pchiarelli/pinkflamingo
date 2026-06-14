import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

/// Shows every product within a category.
class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.productsByCategory(category.name)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: Text(category.name),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.pink.withValues(alpha: 0.12),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Text(
              category.description,
              style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: 'Nenhum produto nesta categoria ainda.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ListTile(
                        leading: Thumbnail(
                            icon: Icons.celebration, imageUrl: p.imageUrl),
                        title: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          formatPrice(p.price),
                          style: const TextStyle(
                            color: AppColors.magenta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textGrey),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
