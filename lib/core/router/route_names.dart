abstract final class RouteNames {
  static const login = '/login';
  static const workOrderList = '/work-orders';
  static const workOrderNew = '/work-orders/new';
  static const workOrderDetail = '/work-orders/:id';
  static const auditLog = '/audit-log';

  static String workOrderDetailPath(String id) => '/work-orders/$id';
}
