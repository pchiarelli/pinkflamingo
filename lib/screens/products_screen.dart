import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sheet.dart';
import '../widgets/common.dart';
import '../widgets/pink_header.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var products = state.searchProducts(_query);
    if (_categoryFilter != null) {
      products =
          products.where((p) => p.category == _categoryFilter).toList();
    }
    products = [...products]..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        PinkHeader(
          title: 'Produtos',
          onTitleLongPress: () => showAdminSheet(context),
          onAdd: state.isAdmin ? () => _openForm(context) : null,
          bottom: Row(
            children: [
              Expanded(
                child: HeaderSearchField(
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(
                active: _categoryFilter != null,
                onTap: () => _openFilter(context, state),
              ),
            ],
          ),
        ),
        if (_categoryFilter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Chip(
                  label: Text(_categoryFilter!),
                  onDeleted: () => setState(() => _categoryFilter = null),
                  backgroundColor: AppColors.pinkLight.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () => state.syncIfNeeded(),
            child: products.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.search_off,
                        message: 'Nenhum produto encontrado.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) => _ProductTile(product: products[i]),
                  ),
          ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
  }

  void _openFilter(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Filtrar por categoria',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Todas as categorias'),
                trailing: _categoryFilter == null
                    ? const Icon(Icons.check, color: AppColors.magenta)
                    : null,
                onTap: () {
                  setState(() => _categoryFilter = null);
                  Navigator.pop(context);
                },
              ),
              for (final c in state.categories)
                ListTile(
                  title: Text(c.name),
                  trailing: _categoryFilter == c.name
                      ? const Icon(Icons.check, color: AppColors.magenta)
                      : null,
                  onTap: () {
                    setState(() => _categoryFilter = c.name);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(
            active ? Icons.filter_alt : Icons.tune,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Thumbnail(icon: Icons.celebration, imageUrl: product.imageUrl),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.category,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(
            formatPrice(product.price),
            style: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.more_horiz, color: AppColors.textGrey),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
    );
  }
}
