import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// The rounded pink top bar used across the app.
///
/// Shows a leading menu button, a large title, an optional "+ Add" pill and an
/// optional search field / extra widget below the title row.
class PinkHeader extends StatelessWidget {
  final String title;
  final bool centerTitle;
  final VoidCallback? onAdd;
  final VoidCallback? onMenu;

  /// Discreet, hidden entry point (e.g. admin login) triggered by long-pressing
  /// the title. Not visible to regular users.
  final VoidCallback? onTitleLongPress;
  final Widget? bottom;

  const PinkHeader({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.onAdd,
    this.onMenu,
    this.onTitleLongPress,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.pinkLight, AppColors.pink],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                if (onMenu != null)
                  InkWell(
                    onTap: onMenu,
                    borderRadius: BorderRadius.circular(8),
                    child:
                        const Icon(Icons.menu, color: Colors.white, size: 26),
                  )
                else
                  const SizedBox(width: 26),
                if (centerTitle)
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (centerTitle) const SizedBox(width: 26),
              ],
            ),
          ),
          if (!centerTitle) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: HoldDetector(
                    onHold: onTitleLongPress,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (onAdd != null) _AddButton(onTap: onAdd!),
              ],
            ),
          ],
          if (bottom != null) ...[
            const SizedBox(height: 14),
            bottom!,
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.magenta, size: 20),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: AppColors.magenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded search field that sits on top of the pink header.
class HeaderSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const HeaderSearchField({
    super.key,
    this.hint = 'Procurar',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
