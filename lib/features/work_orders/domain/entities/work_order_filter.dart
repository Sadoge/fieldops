import 'package:equatable/equatable.dart';
import 'work_order_status.dart';

class WorkOrderFilter extends Equatable {
  const WorkOrderFilter({this.status, this.searchQuery});

  final WorkOrderStatus? status;
  final String? searchQuery;

  WorkOrderFilter copyWith({
    WorkOrderStatus? status,
    String? searchQuery,
    bool clearStatus = false,
  }) =>
      WorkOrderFilter(
        status: clearStatus ? null : status ?? this.status,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  bool get isEmpty => status == null && (searchQuery?.isEmpty ?? true);

  @override
  List<Object?> get props => [status, searchQuery];
}
