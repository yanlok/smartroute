enum NoticeSeverity { info, warning, severe }

enum NoticeSource { official, smartRoute }

enum NoticeStatus { draft, published, archived }

class ServiceNotice {
  final String id;
  final String title;
  final String body;
  final NoticeSeverity severity;
  final NoticeSource source;
  final String routeId;
  final DateTime startsAt;
  final DateTime? endsAt;
  final NoticeStatus status;
  final String createdBy;
  final DateTime updatedAt;

  const ServiceNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.source,
    required this.routeId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.createdBy,
    required this.updatedAt,
  });

  bool isActiveAt(DateTime time) =>
      status == NoticeStatus.published &&
      !startsAt.isAfter(time) &&
      (endsAt == null || endsAt!.isAfter(time));
}

class SourceHealth {
  final String id;
  final String displayName;
  final String type;
  final String status;
  final DateTime checkedAt;
  final DateTime? dataTimestamp;
  final int? recordCount;
  final String details;

  const SourceHealth({
    required this.id,
    required this.displayName,
    required this.type,
    required this.status,
    required this.checkedAt,
    required this.dataTimestamp,
    required this.recordCount,
    required this.details,
  });
}

class AdminUserSummary {
  final String id;
  final String fullName;
  final DateTime createdAt;

  const AdminUserSummary({
    required this.id,
    required this.fullName,
    required this.createdAt,
  });
}
