import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Opens the admin panel: login form, or a logout option if already signed in.
Future<void> showAdminSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AdminSheet(),
  );
}

class _AdminSheet extends StatefulWidget {
  const _AdminSheet();

  @override
  State<_AdminSheet> createState() => _AdminSheetState();
}

class _AdminSheetState extends State<_AdminSheet> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login(AppState state) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await state.loginAdmin(_user.text.trim(), _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo administrador ativado.'),
          backgroundColor: AppColors.magenta,
        ),
      );
    } else {
      setState(() {
        _busy = false;
        _error = 'Usuário ou senha inválidos (ou servidor offline).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🦩', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                state.isAdmin ? 'Administrador' : 'Entrar como admin',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!state.online)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Servidor offline — mostrando o catálogo local.',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          if (state.isAdmin) ...[
            const Text(
              'Você está no modo administrador. Os botões “+ Add” de produtos e '
              'kits estão liberados, e a aba Pedidos mostra os pedidos recebidos.',
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                state.logoutAdmin();
                Navigator.pop(context);
              },
              child: const Text('Sair do modo admin'),
            ),
          ] else ...[
            TextField(
              controller: _user,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _login(state),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.magenta,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _busy ? null : () => _login(state),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ],
      ),
    );
  }
}
