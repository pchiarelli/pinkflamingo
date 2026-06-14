import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kit.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sheet.dart';
import '../widgets/common.dart';
import '../widgets/pink_header.dart';

class KitsScreen extends StatefulWidget {
  const KitsScreen({super.key});

  @override
  State<KitsScreen> createState() => _KitsScreenState();
}

class _KitsScreenState extends State<KitsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final kits = state.searchKits(_query);

    return Column(
      children: [
        PinkHeader(
          title: 'Kits',
          onTitleLongPress: () => showAdminSheet(context),
          onAdd: state.isAdmin ? () => _addKit(context, state) : null,
          bottom: HeaderSearchField(
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: kits.isEmpty
              ? const EmptyState(
                  icon: Icons.lightbulb_outline,
                  message: 'Nenhum kit encontrado.',
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    CardList(
                      children: [
                        for (var i = 0; i < kits.length; i++) ...[
                          _KitTile(
                            kit: kits[i],
                            onDelete:
                                state.isAdmin ? () => state.removeKit(kits[i]) : null,
                          ),
                          if (i != kits.length - 1)
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

  void _addKit(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo kit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome do tema/kit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await state.addKit(name);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível salvar: $e')),
          );
        }
      }
    }
  }
}

class _KitTile extends StatelessWidget {
  final Kit kit;
  final VoidCallback? onDelete;
  const _KitTile({required this.kit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: Thumbnail(
        icon: Icons.celebration_outlined,
        imageUrl: kit.imageUrl,
      ),
      title: Text(
        kit.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      trailing: onDelete == null
          ? const Icon(Icons.chevron_right, color: AppColors.textGrey)
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: AppColors.textGrey),
              onSelected: (v) {
                if (v == 'delete') onDelete!();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
    );
  }
}
