import 'product.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

class Order {
  final String id;
  String customerName;
  DateTime? eventDate;
  final List<OrderItem> items;
  bool done;

  Order({
    required this.id,
    this.customerName = '',
    this.eventDate,
    List<OrderItem>? items,
    this.done = false,
  }) : items = items ?? [];

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
