import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sheet.dart';
import '../widgets/common.dart';
import 'category_detail_screen.dart';
import 'product_detail_screen.dart';

/// Sales-oriented landing: hero + CTA, search, featured products, categories
/// and theme kits.
class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onSelectTab;
  const HomeScreen({super.key, required this.onSelectTab});

  static const Map<String, String> categoryEmoji = {
    'Bandejas': '🍽️',
    'Boleiras': '🧁',
    'Bolos fakes': '🎂',
    'Bonecos': '🧸',
    'Displays': '🖼️',
    'Flores artificiais': '🌷',
    'Itens decorativos': '✨',
    'Leds': '💡',
    'Mesas': '🪑',
    'Painéis': '🎀',
    'Tapetes': '🧶',
    'Vasos': '🏺',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final featured = _featured(state.products);

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        color: AppColors.magenta,
        onRefresh: () => state.syncIfNeeded(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
              child: _TopBar(onAdminLongPress: () => showAdminSheet(context))),
          SliverToBoxAdapter(child: _Hero(onSeeCatalog: () => onSelectTab(1))),
          SliverToBoxAdapter(
            child: _SearchBar(onTap: () => onSelectTab(1)),
          ),
          if (featured.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '✨ Destaques',
                actionLabel: 'Ver tudo',
                onAction: () => onSelectTab(1),
              ),
            ),
            SliverToBoxAdapter(child: _FeaturedRow(products: featured)),
          ],
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Categorias',
              actionLabel: 'Ver todas',
              onAction: () => onSelectTab(2),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = state.categories[i];
                  return _CategoryCard(
                    category: c,
                    emoji: categoryEmoji[c.name] ?? '🎉',
                    count: state.countInCategory(c.name),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(category: c),
                      ),
                    ),
                  );
                },
                childCount: state.categories.length,
              ),
            ),
          ),
          if (state.kits.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '🎈 Kits por tema',
                actionLabel: 'Ver todos',
                onAction: () => onSelectTab(3),
              ),
            ),
            SliverToBoxAdapter(child: _KitsRow(state: state)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  List<Product> _featured(List<Product> all) {
    // Prefer products that already have a photo (most attractive).
    final withImg = all.where((p) => p.imageUrl != null).toList();
    if (withImg.isNotEmpty) return withImg.take(10).toList();
    // Otherwise spread picks across the catalog for variety, skipping the
    // "*" special items.
    final clean = all.where((p) => !p.name.startsWith('*')).toList();
    if (clean.isEmpty) return all.take(10).toList();
    final step = (clean.length / 10).ceil().clamp(1, clean.length);
    final picks = <Product>[];
    for (var i = 0; i < clean.length && picks.length < 10; i += step) {
      picks.add(clean[i]);
    }
    return picks;
  }
}

class _TopBar extends StatelessWidget {
  /// Hidden admin entry — hold the brand for 5s (invisible to regular users).
  final VoidCallback onAdminLongPress;
  const _TopBar({required this.onAdminLongPress});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pinkLight, AppColors.pink],
        ),
      ),
      padding: EdgeInsets.only(top: top + 10, left: 20, right: 20, bottom: 14),
      child: Center(
        child: HoldDetector(
          onHold: onAdminLongPress,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset('assets/images/flamingo.png'),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pink Flamingo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onSeeCatalog;
  const _Hero({required this.onSeeCatalog});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.magenta, Color(0xFFFF6FB3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.magenta.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decore a sua festa\ncom a gente! 🦩',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aluguel de peças e kits temáticos para festas inesquecíveis.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.magenta,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: onSeeCatalog,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ver catálogo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textGrey),
              SizedBox(width: 10),
              Text('O que você procura?',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: const TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  final List<Product> products;
  const _FeaturedRow({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = products[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            ),
            child: Container(
              width: 164,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: p.imageUrl != null
                        ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph())
                        : _ph(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                height: 1.15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatPrice(p.price),
                            style: const TextStyle(
                                color: AppColors.magenta,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ph() => Container(
        color: const Color(0xFFFDEAF5),
        alignment: Alignment.center,
        child: const Text('🎉', style: TextStyle(fontSize: 40)),
      );
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final String emoji;
  final int count;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.category,
    required this.emoji,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDEAF5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, height: 1.1),
                    ),
                    Text('$count peças',
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitsRow extends StatelessWidget {
  final AppState state;
  const _KitsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final kits = state.kits.take(12).toList();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.pinkLight),
          ),
          child: Text(
            kits[i].name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
      ),
    );
  }
}
