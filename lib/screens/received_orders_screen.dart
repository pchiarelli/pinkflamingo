import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// List of orders submitted by customers (admin). Reusable as a tab body or a
/// standalone screen. Pull down to refresh.
class ReceivedOrdersBody extends StatefulWidget {
  const ReceivedOrdersBody({super.key});

  @override
  State<ReceivedOrdersBody> createState() => _ReceivedOrdersBodyState();
}

class _ReceivedOrdersBodyState extends State<ReceivedOrdersBody> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().fetchReceivedOrders();
  }

  Future<void> _reload() async {
    final f = context.read<AppState>().fetchReceivedOrders();
    setState(() => _future = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return RefreshIndicator(
      color: AppColors.magenta,
      onRefresh: _reload,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.cloud_off,
                message: 'Não foi possível carregar.\nVerifique o servidor.',
              ),
            ]);
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Nenhum pedido recebido ainda.',
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _OrderCard(
              order: orders[i],
              onChanged: _reload,
              onTogglePaid: (paid) => state.setReceivedOrderPaid(
                  orders[i]['id'] as int, paid),
              onToggleDone: (done) => state.setReceivedOrderDone(
                  orders[i]['id'] as int, done),
              onDelete: () =>
                  state.deleteReceivedOrder(orders[i]['id'] as int),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChanged;
  final Future<void> Function(bool paid) onTogglePaid;
  final Future<void> Function(bool done) onToggleDone;
  final Future<void> Function() onDelete;

  const _OrderCard({
    required this.order,
    required this.onChanged,
    required this.onTogglePaid,
    required this.onToggleDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final done = order['done'] == true;
    final paid = order['paid'] == true;
    final name = (order['customerName'] as String?)?.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name == null || name.isEmpty ? 'Pedido #${order['id']}' : name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _Tag(
                label: paid ? 'pago' : 'aguardando',
                color: paid ? const Color(0xFF2ECC71) : const Color(0xFFE0A800),
              ),
              if (done) ...[
                const SizedBox(width: 6),
                const _Tag(label: 'concluído', color: AppColors.pink),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  '${it['quantity']}× ${it['name']}  ·  ${formatPrice((it['price'] as num).toDouble())}',
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              )),
          if (order['eventDate'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Evento: ${_fmtDate(order['eventDate'])}',
                  style: const TextStyle(color: AppColors.textGrey)),
            ),
          const Divider(height: 18),
          Row(
            children: [
              Text(
                formatPrice((order['total'] as num).toDouble()),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.magenta),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await onTogglePaid(!paid);
                  onChanged();
                },
                child: Text(paid ? 'Não pago' : 'Marcar pago'),
              ),
              TextButton(
                onPressed: () async {
                  await onToggleDone(!done);
                  onChanged();
                },
                child: Text(done ? 'Reabrir' : 'Concluir'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await onDelete();
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(dynamic iso) {
    final d = DateTime.tryParse(iso.toString());
    return d != null ? DateFormat('dd/MM/yyyy').format(d) : iso.toString();
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
