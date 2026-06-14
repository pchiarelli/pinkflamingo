import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'pix_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.order.customerName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: Text(order.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              state.removeOrder(order);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => state.updateOrder(order, customerName: v),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.textGrey),
            ),
            leading: const Icon(Icons.event, color: AppColors.magenta),
            title: Text(order.eventDate == null
                ? 'Data do evento'
                : DateFormat('dd/MM/yyyy', 'pt_BR').format(order.eventDate!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickDate(context, state, order),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Itens',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${order.itemCount} item(ns)',
                  style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nenhum item. Adicione produtos pela tela de Produtos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          else
            for (final item in order.items) _ItemRow(order: order, item: item),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                formatPrice(order.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.magenta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.magenta,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: order.items.isEmpty || _submitting
                ? null
                : () => _submit(context, state, order),
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(order.done ? Icons.check_circle : Icons.send),
            label: Text(order.done ? 'Pedido enviado' : 'Enviar pedido'),
          ),
        ],
      ),
    );
  }

  bool _submitting = false;

  Future<void> _submit(BuildContext context, AppState state, Order order) async {
    setState(() => _submitting = true);
    try {
      final result = await state.submitOrder(order);
      if (!context.mounted) return;
      final pix = result['pix'] as String?;
      final total = (result['total'] as num?)?.toDouble() ?? order.total;
      final id = (result['id'] as num?)?.toInt() ?? 0;
      if (pix != null && pix.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PixScreen(pixCode: pix, total: total, orderId: id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado com sucesso! 🦩'),
            backgroundColor: AppColors.magenta,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate(
      BuildContext context, AppState state, Order order) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: order.eventDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) state.updateOrder(order, eventDate: picked);
  }
}

class _ItemRow extends StatelessWidget {
  final Order order;
  final OrderItem item;
  const _ItemRow({required this.order, required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Thumbnail(size: 40, icon: Icons.celebration),
      title: Text(item.product.name),
      subtitle: Text(formatPrice(item.product.price),
          style: const TextStyle(color: AppColors.magenta)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => item.quantity > 1
                ? state.setOrderItemQuantity(item, item.quantity - 1)
                : state.removeOrderItem(order, item),
          ),
          Text('${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                state.setOrderItemQuantity(item, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}
