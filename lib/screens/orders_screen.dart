import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sheet.dart';
import '../widgets/common.dart';
import '../widgets/pink_header.dart';
import 'order_detail_screen.dart';
import 'received_orders_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Admin sees the orders RECEIVED from customers; a regular customer sees
    // their own order-building flow.
    if (state.isAdmin) {
      return Column(
        children: [
          PinkHeader(
            title: 'Pedidos recebidos',
            onTitleLongPress: () => showAdminSheet(context),
          ),
          const Expanded(child: ReceivedOrdersBody()),
        ],
      );
    }

    final orders = state.orders;
    return Column(
      children: [
        PinkHeader(
          title: 'Pedidos',
          onTitleLongPress: () => showAdminSheet(context),
          onAdd: () {
            final order = state.createOrder();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            );
          },
        ),
        Expanded(
          child: orders.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Nenhum pedido ainda.\nToque em “+ Add” para criar.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) =>
                      _OrderTile(order: orders[i]),
                ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final date = order.eventDate;
    final subtitleParts = <String>[
      '${order.itemCount} item(ns)',
      formatPrice(order.total),
      if (date != null) DateFormat('dd/MM/yyyy', 'pt_BR').format(date),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: GestureDetector(
        onTap: () => state.toggleOrderDone(order),
        child: CircleAvatar(
          radius: 16,
          backgroundColor:
              order.done ? AppColors.magenta : AppColors.pinkLight,
          child: Icon(
            order.done ? Icons.check : Icons.check,
            size: 18,
            color: order.done ? Colors.white : Colors.white70,
          ),
        ),
      ),
      title: Text(
        order.customerName.isEmpty ? order.id : order.customerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitleParts.join('  ·  '),
          style: const TextStyle(color: AppColors.textGrey)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      ),
    );
  }
}
