import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  const Photo({
    required this.id,
    required this.workOrderId,
    required this.localPath,
    required this.capturedAt,
    required this.capturedBy,
    required this.fileSizeBytes,
    this.remoteUrl,
    this.isSynced = false,
  });

  final String id;
  final String workOrderId;
  final String localPath;
  final String? remoteUrl;
  final DateTime capturedAt;
  final String capturedBy;
  final int fileSizeBytes;
  final bool isSynced;

  Photo copyWith({
    String? id,
    String? workOrderId,
    String? localPath,
    String? remoteUrl,
    DateTime? capturedAt,
    String? capturedBy,
    int? fileSizeBytes,
    bool? isSynced,
  }) =>
      Photo(
        id: id ?? this.id,
        workOrderId: workOrderId ?? this.workOrderId,
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        capturedAt: capturedAt ?? this.capturedAt,
        capturedBy: capturedBy ?? this.capturedBy,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  List<Object?> get props => [
        id, workOrderId, localPath, remoteUrl,
        capturedAt, capturedBy, fileSizeBytes, isSynced,
      ];
}
