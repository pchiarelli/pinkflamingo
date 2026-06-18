import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/kit.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Thin HTTP client for the Pink Flamingo API.
///
/// Base URL defaults to localhost (works on the iOS simulator, which shares the
/// host network). Override at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3333
class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3333',
            );

  final String baseUrl;
  String? _token;

  /// Called when an authenticated request is rejected (401) — e.g. the admin
  /// session was ended by a newer login or by lowering the session limit.
  void Function()? onUnauthorized;

  bool get isAuthenticated => _token != null;
  void setToken(String? token) => _token = token;

  /// Ends the current admin session on the server (best effort).
  Future<void> logout() async {
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await http.post(_uri('/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'});
    } catch (_) {}
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$baseUrl$path').replace(queryParameters: q);
  }

  // ---- Catalog (public) ---------------------------------------------------

  Future<List<Category>> fetchCategories() async {
    final res = await http.get(_uri('/api/categories'));
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> fetchProducts({String? category, String? query}) async {
    final res = await http.get(_uri('/api/products', {
      if (category != null) 'category': category,
      if (query != null && query.isNotEmpty) 'q': query,
    }));
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// The central catalog version — a single integer. Cheap to poll.
  Future<int> fetchVersion() async {
    final res = await http.get(_uri('/api/version'));
    _ensureOk(res);
    return (jsonDecode(res.body) as Map<String, dynamic>)['version'] as int;
  }

  /// Delta sync. `since` omitted → full snapshot. Returns
  /// `{ version, products: [{..., deleted}] }`.
  Future<Map<String, dynamic>> fetchSync({int? since}) async {
    final res = await http.get(_uri('/api/sync', {
      if (since != null) 'since': since,
    }));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Kit>> fetchKits() async {
    final res = await http.get(_uri('/api/kits'));
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Kit.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Orders -------------------------------------------------------------

  /// Submits the order and returns the created order (incl. `pix` + `total`).
  Future<Map<String, dynamic>> submitOrder(Order order) async {
    final res = await http.post(
      _uri('/api/orders'),
      headers: _headers,
      body: jsonEncode({
        'customerName': order.customerName,
        'eventDate': order.eventDate?.toIso8601String(),
        'items': order.items
            .map((i) => {
                  'productId': i.product.id,
                  'name': i.product.name,
                  'price': i.product.price,
                  'quantity': i.quantity,
                })
            .toList(),
      }),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---- Admin --------------------------------------------------------------

  Future<bool> login(String username, String password) async {
    final res = await http.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': username, 'password': password, 'client': 'app'}),
    );
    if (res.statusCode != 200) return false;
    _token = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
    return true;
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    required String category,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      return _productMultipart('POST', '/api/products',
          name: name, price: price, category: category, imagePath: imagePath);
    }
    final res = await http.post(
      _uri('/api/products'),
      headers: _headers,
      body: jsonEncode({'name': name, 'price': price, 'category': category}),
    );
    _ensureOk(res);
    return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Create/update a product sending the photo as multipart/form-data.
  Future<Product> _productMultipart(
    String method,
    String path, {
    required String name,
    required double price,
    required String category,
    required String imagePath,
  }) async {
    final req = http.MultipartRequest(method, _uri(path));
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.fields['name'] = name;
    req.fields['price'] = price.toString();
    req.fields['category'] = category;
    req.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final res = await http.Response.fromStream(await req.send());
    _ensureOk(res);
    return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required double price,
    required String category,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      return _productMultipart('PUT', '/api/products/$id',
          name: name, price: price, category: category, imagePath: imagePath);
    }
    final res = await http.put(
      _uri('/api/products/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'price': price, 'category': category}),
    );
    _ensureOk(res);
    return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    _ensureOk(await http.delete(_uri('/api/products/$id'), headers: _headers));
  }

  Future<void> deleteKit(int id) async {
    _ensureOk(await http.delete(_uri('/api/kits/$id'), headers: _headers));
  }

  /// Orders submitted by customers (admin only).
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final res = await http.get(_uri('/api/orders'), headers: _headers);
    _ensureOk(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setOrderDone(int id, bool done) async {
    _ensureOk(await http.patch(
      _uri('/api/orders/$id'),
      headers: _headers,
      body: jsonEncode({'done': done}),
    ));
  }

  Future<void> setOrderPaid(int id, bool paid) async {
    _ensureOk(await http.patch(
      _uri('/api/orders/$id'),
      headers: _headers,
      body: jsonEncode({'paid': paid}),
    ));
  }

  Future<void> deleteOrder(int id) async {
    _ensureOk(await http.delete(_uri('/api/orders/$id'), headers: _headers));
  }

  Future<Kit> createKit(String name) async {
    final res = await http.post(
      _uri('/api/kits'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    _ensureOk(res);
    return Kit.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode == 401 && _token != null) {
      _token = null;
      onUnauthorized?.call();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, _messageFrom(res));
    }
  }

  String _messageFrom(http.Response res) {
    try {
      return (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String? ??
          'Erro ${res.statusCode}';
    } catch (_) {
      return 'Erro ${res.statusCode}';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
