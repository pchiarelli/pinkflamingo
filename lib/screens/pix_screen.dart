import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shows the Pix QR code + copia-e-cola for a submitted order.
class PixScreen extends StatelessWidget {
  final String pixCode;
  final double total;
  final int orderId;

  const PixScreen({
    super.key,
    required this.pixCode,
    required this.total,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text('Pagamento Pix'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle, color: AppColors.magenta, size: 56),
          const SizedBox(height: 8),
          const Text(
            'Pedido enviado! 🦩',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido #$orderId · ${formatPrice(total)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const Text(
            'Escaneie o QR no app do seu banco ou use o copia e cola:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: QrImageView(
                data: pixCode,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pixCode,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.magenta,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pixCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código Pix copiado!'),
                  backgroundColor: AppColors.magenta,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código Pix'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Após o pagamento, a Pink Flamingo confirma o recebimento. '
            'Qualquer dúvida, fale com a gente!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}
