import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sheet.dart';
import '../widgets/common.dart';
import '../widgets/pink_header.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = state.searchCategories(_query);

    return Column(
      children: [
        PinkHeader(
          title: 'Categorias',
          onTitleLongPress: () => showAdminSheet(context),
          bottom: HeaderSearchField(
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: categories.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  message: 'Nenhuma categoria encontrada.',
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    CardList(
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          _CategoryTile(
                            category: categories[i],
                            count: state.countInCategory(categories[i].name),
                          ),
                          if (i != categories.length - 1)
                            const Divider(
                                height: 1, color: AppColors.divider),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int count;
  const _CategoryTile({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: const Thumbnail(icon: Icons.category_outlined),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        category.description,
        style: const TextStyle(color: AppColors.textGrey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: const TextStyle(
                  color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textGrey),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(category: category),
        ),
      ),
    );
  }
}
