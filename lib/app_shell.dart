import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/categories_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kits_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// Root scaffold holding the five tabs and the bottom navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _compact = false; // floating nav shrinks while scrolling

  late final List<Widget> _pages = [
    HomeScreen(onSelectTab: (i) => setState(() => _index = i)),
    const ProductsScreen(),
    const CategoriesScreen(),
    const KitsScreen(),
    const OrdersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back to foreground → check the central version and pull any delta.
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().syncIfNeeded();
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    // React to the finger movement itself (like Instagram): the instant you
    // drag down it shrinks; the instant you drag up it expands.
    if (n is ScrollUpdateNotification) {
      final d = n.scrollDelta ?? 0;
      if (d > 0.5 && !_compact && n.metrics.pixels > 6) {
        setState(() => _compact = true); // dragging down
      } else if (d < -0.5 && _compact) {
        setState(() => _compact = false); // dragging up
      }
    }
    // Always full at the very top.
    if (n.metrics.hasPixels && n.metrics.pixels <= 0 && _compact) {
      setState(() => _compact = false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // content scrolls behind the floating capsule
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        compact: _compact,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Bottom bar anchored at the foot: white, icon + label, magenta when active.
/// While scrolling it shrinks and hides the labels (icon-only).
class _NavBar extends StatelessWidget {
  final int index;
  final bool compact;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.index,
    required this.compact,
    required this.onTap,
  });

  static const _items = [
    [Icons.home, Icons.home_outlined, 'Início'],
    [Icons.storefront, Icons.storefront_outlined, 'Produtos'],
    [Icons.category, Icons.category_outlined, 'Categorias'],
    [Icons.celebration, Icons.celebration_outlined, 'Kits'],
    [Icons.receipt_long, Icons.receipt_long_outlined, 'Pedidos'],
  ];

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.sizeOf(context).width - 28;
    // The surround is transparent → content scrolls directly behind it.
    // heightFactor:1 keeps the bar's height hugging the pill (no tall block).
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.center,
            child: Container(
              // Subtle horizontal shrink on scroll; labels stay visible.
              width: compact ? fullWidth - 36 : fullWidth,
              padding: EdgeInsets.symmetric(
                  horizontal: 4, vertical: compact ? 6 : 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    spreadRadius: -2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavItem(
                      filled: _items[i][0] as IconData,
                      outline: _items[i][1] as IconData,
                      label: _items[i][2] as String,
                      selected: index == i,
                      compact: compact,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Active tab expands into a magenta pill showing its label; the others are
/// grey icons. While scrolling (compact) the label hides — icon-only.
class _NavItem extends StatelessWidget {
  final IconData filled;
  final IconData outline;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.filled,
    required this.outline,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.magenta : AppColors.textGrey;

    // Magenta highlight behind the active icon.
    // Subtle vertical shrink while scrolling — labels always stay visible.
    final iconChip = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.magenta : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        selected ? filled : outline,
        color: selected ? Colors.white : AppColors.textGrey,
        size: compact ? 21 : 23,
      ),
    );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconChip,
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
