import 'package:flutter/foundation.dart' hide Category;

import '../data/seed_data.dart';
import '../models/category.dart';
import '../models/kit.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// Application state.
///
/// Starts with the bundled seed data so the UI renders instantly, then refreshes
/// from the API. If the API is unreachable it transparently keeps the seed data
/// (offline-friendly). Admin-only mutations go through the API.
class AppState extends ChangeNotifier {
  AppState({ApiService? api}) : api = api ?? ApiService() {
    // Server ended our admin session (newer login / lower limit) → drop admin.
    this.api.onUnauthorized = () {
      if (_isAdmin) {
        _isAdmin = false;
        _sessionKicked = true;
        notifyListeners();
      }
    };
  }

  final ApiService api;

  /// True once after the admin session was revoked by the server, so the UI
  /// can show a "logged in elsewhere" message. Read-and-clear via [consumeSessionKicked].
  bool _sessionKicked = false;
  bool consumeSessionKicked() {
    if (!_sessionKicked) return false;
    _sessionKicked = false;
    return true;
  }

  List<Product> _products = [...seedProducts];
  List<Category> _categories = [...seedCategories];
  List<Kit> _kits = [...seedKits];
  final List<Order> _orders = [];

  bool _loading = false;
  bool _online = true;
  bool _isAdmin = false;
  int _orderCounter = 0;

  /// Last central catalog version we have applied (-1 = never synced).
  int _catalogVersion = -1;

  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Kit> get kits => List.unmodifiable(_kits);
  List<Order> get orders => List.unmodifiable(_orders);
  bool get loading => _loading;
  bool get online => _online;
  bool get isAdmin => _isAdmin;

  /// Full load from the API (catalog + categories + kits). Falls back to the
  /// bundled seed data on failure so the app never shows a blank screen.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final categories = await api.fetchCategories();
      final kits = await api.fetchKits();
      final sync = await api.fetchSync(); // full snapshot + version
      _categories = categories;
      _kits = kits;
      _products = (sync['products'] as List)
          .cast<Map<String, dynamic>>()
          .where((m) => m['deleted'] != true)
          .map(Product.fromJson)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _catalogVersion = sync['version'] as int;
      _online = true;
    } catch (_) {
      _online = false; // keep seed data
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Lightweight refresh: check the central version; if it advanced, pull only
  /// the products that changed (the delta) and patch them in. Cheap to call on
  /// app resume / pull-to-refresh.
  Future<void> syncIfNeeded() async {
    try {
      final serverVersion = await api.fetchVersion();
      _online = true;
      if (serverVersion == _catalogVersion) return; // nothing changed
      final sync = await api.fetchSync(
        since: _catalogVersion < 0 ? null : _catalogVersion,
      );
      _applyDelta((sync['products'] as List).cast<Map<String, dynamic>>());
      _catalogVersion = sync['version'] as int;
      // Category counts derive from _products, but refresh descriptions too.
      try {
        _categories = await api.fetchCategories();
      } catch (_) {}
      notifyListeners();
    } catch (_) {
      _online = false;
    }
  }

  void _applyDelta(List<Map<String, dynamic>> items) {
    for (final m in items) {
      final id = m['id'] as int;
      if (m['deleted'] == true) {
        _products.removeWhere((p) => p.id == id);
      } else {
        final prod = Product.fromJson(m);
        final i = _products.indexWhere((p) => p.id == id);
        if (i >= 0) {
          _products[i] = prod;
        } else {
          _products.add(prod);
        }
      }
    }
    _products.sort((a, b) => a.name.compareTo(b.name));
  }

  // ---- Products -----------------------------------------------------------

  List<Product> productsByCategory(String category) =>
      _products.where((p) => p.category == category).toList();

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return products;
    final q = _normalize(query);
    return _products
        .where((p) =>
            _normalize(p.name).contains(q) ||
            _normalize(p.category).contains(q))
        .toList();
  }

  int countInCategory(String category) =>
      _products.where((p) => p.category == category).length;

  Future<void> addProduct({
    required String name,
    required double price,
    required String category,
    String? imagePath,
  }) async {
    if (_online && api.isAuthenticated) {
      final created = await api.createProduct(
          name: name, price: price, category: category, imagePath: imagePath);
      _products.add(created);
    } else {
      _products.add(Product(name: name, price: price, category: category));
    }
    _products.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateProduct(
    Product original, {
    required String name,
    required double price,
    required String category,
    String? imagePath,
  }) async {
    Product updated;
    if (_online && api.isAuthenticated && original.id != null) {
      updated = await api.updateProduct(
          id: original.id!,
          name: name,
          price: price,
          category: category,
          imagePath: imagePath);
    } else {
      updated = original.copyWith(name: name, price: price, category: category);
    }
    final i = _products.indexWhere((p) => identical(p, original) || p.id == original.id);
    if (i >= 0) _products[i] = updated;
    _products.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteProduct(Product product) async {
    if (_online && api.isAuthenticated && product.id != null) {
      await api.deleteProduct(product.id!);
    }
    _products.removeWhere((p) => identical(p, product) || p.id == product.id);
    notifyListeners();
  }

  // ---- Kits ---------------------------------------------------------------

  List<Kit> searchKits(String query) {
    if (query.trim().isEmpty) return kits;
    final q = _normalize(query);
    return _kits.where((k) => _normalize(k.name).contains(q)).toList();
  }

  Future<void> addKit(String name) async {
    if (_online && api.isAuthenticated) {
      _kits.add(await api.createKit(name));
    } else {
      _kits.add(Kit(name: name));
    }
    _kits.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> removeKit(Kit kit) async {
    if (_online && api.isAuthenticated && kit.id != null) {
      await api.deleteKit(kit.id!);
    }
    _kits.removeWhere((k) => identical(k, kit) || k.id == kit.id);
    notifyListeners();
  }

  // ---- Admin: received orders --------------------------------------------

  Future<List<Map<String, dynamic>>> fetchReceivedOrders() =>
      api.fetchOrders();

  Future<void> setReceivedOrderDone(int id, bool done) =>
      api.setOrderDone(id, done);

  Future<void> setReceivedOrderPaid(int id, bool paid) =>
      api.setOrderPaid(id, paid);

  Future<void> deleteReceivedOrder(int id) => api.deleteOrder(id);

  // ---- Categories ---------------------------------------------------------

  List<Category> searchCategories(String query) {
    if (query.trim().isEmpty) return categories;
    final q = _normalize(query);
    return _categories
        .where((c) =>
            _normalize(c.name).contains(q) ||
            _normalize(c.description).contains(q))
        .toList();
  }

  // ---- Admin --------------------------------------------------------------

  Future<bool> loginAdmin(String username, String password) async {
    final ok = await api.login(username, password);
    if (ok) {
      _isAdmin = true;
      notifyListeners();
    }
    return ok;
  }

  void logoutAdmin() {
    _isAdmin = false;
    api.logout(); // ends the session server-side (best effort)
    notifyListeners();
  }

  // ---- Orders -------------------------------------------------------------

  Order createOrder() {
    _orderCounter++;
    final order = Order(id: 'PED-${_orderCounter.toString().padLeft(4, '0')}');
    _orders.add(order);
    notifyListeners();
    return order;
  }

  void addProductToOrder(Order order, Product product) {
    final existing = order.items
        .where((i) => i.product.name == product.name)
        .cast<OrderItem?>()
        .firstWhere((_) => true, orElse: () => null);
    if (existing != null) {
      existing.quantity++;
    } else {
      order.items.add(OrderItem(product: product));
    }
    notifyListeners();
  }

  void removeOrderItem(Order order, OrderItem item) {
    order.items.remove(item);
    notifyListeners();
  }

  void setOrderItemQuantity(OrderItem item, int quantity) {
    item.quantity = quantity.clamp(1, 999);
    notifyListeners();
  }

  void toggleOrderDone(Order order) {
    order.done = !order.done;
    notifyListeners();
  }

  void updateOrder(Order order, {String? customerName, DateTime? eventDate}) {
    if (customerName != null) order.customerName = customerName;
    if (eventDate != null) order.eventDate = eventDate;
    notifyListeners();
  }

  void removeOrder(Order order) {
    _orders.remove(order);
    notifyListeners();
  }

  /// Send the order to the backend (customer checkout). Returns the created
  /// order data, including the `pix` copia-e-cola and the server-side `total`.
  Future<Map<String, dynamic>> submitOrder(Order order) async {
    final result = await api.submitOrder(order);
    order.done = true;
    notifyListeners();
    return result;
  }
}

/// Lowercase + strip Portuguese accents so search is accent-insensitive
/// (e.g. "abo" matches "Abóbora").
const Map<String, String> _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String _normalize(String s) {
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString();
}
