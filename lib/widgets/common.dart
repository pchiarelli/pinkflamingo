import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Fires [onHold] only after the child is pressed and held for [duration]
/// (default 5s). Used as a hidden admin entry point.
class HoldDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onHold;
  final Duration duration;

  const HoldDetector({
    super.key,
    required this.child,
    this.onHold,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<HoldDetector> createState() => _HoldDetectorState();
}

class _HoldDetectorState extends State<HoldDetector> {
  Timer? _timer;

  void _start(_) {
    if (widget.onHold == null) return;
    _timer = Timer(widget.duration, () {
      HapticFeedback.mediumImpact();
      widget.onHold?.call();
    });
  }

  void _cancel([_]) {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _start,
      onTapUp: _cancel,
      onTapCancel: _cancel,
      child: widget.child,
    );
  }
}

final NumberFormat _currency =
    NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

String formatPrice(double value) => _currency.format(value);

/// Rounded grey placeholder used where a product/kit image would go.
class Thumbnail extends StatelessWidget {
  final double size;
  final IconData? icon;
  final String? imageUrl;

  const Thumbnail({super.key, this.size = 48, this.icon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: const Color(0xFFF1F1F3),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: AppColors.pink, size: size * 0.5)
          : null,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl == null
          ? placeholder
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Empty-state placeholder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.pinkLight),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// White card that wraps a scrollable list, matching the app's framed look.
class CardList extends StatelessWidget {
  final List<Widget> children;
  const CardList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Column(children: children),
      ),
    );
  }
}
