import '../../domain/models/order_log.dart';

abstract class OrderLogRepository {
  const OrderLogRepository();

  Future<List<OrderLogEntry>> fetchLogs({
    required DateTime from,
    required DateTime to,
    String? query,
  });

  Future<OrderLogDetail?> fetchDetail(int orderId);
}
