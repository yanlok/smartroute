/// Data models matching the React SmartRoute application's type definitions.

/// Represents a public transport line with its real-time status.
class TransportLine {
  final String id;
  final String name;
  final String shortName;
  final String color;
  final TransportStatus status;
  final int? delay; // in minutes

  const TransportLine({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.status,
    this.delay,
  });
}

enum TransportStatus {
  onTime,
  minorDelay,
  majorDelay,
  suspended;

  String get label {
    switch (this) {
      case TransportStatus.onTime:
        return 'On Time';
      case TransportStatus.minorDelay:
        return 'Minor Delay';
      case TransportStatus.majorDelay:
        return 'Major Delay';
      case TransportStatus.suspended:
        return 'Suspended';
    }
  }
}

/// Represents a nearby transit station.
class StationInfo {
  final String id;
  final String name;
  final List<String> lines;
  final List<String> lineColors;
  final String distance;
  final int walkTime; // in minutes

  const StationInfo({
    required this.id,
    required this.name,
    required this.lines,
    required this.lineColors,
    required this.distance,
    required this.walkTime,
  });
}

/// A segment of a journey route (walk, LRT, MRT, bus, or monorail).
class RouteSegment {
  final RouteSegmentType type;
  final String from;
  final String to;
  final String? line;
  final String? lineColor;
  final int duration; // in minutes
  final int? stops;

  const RouteSegment({
    required this.type,
    required this.from,
    required this.to,
    this.line,
    this.lineColor,
    required this.duration,
    this.stops,
  });
}

enum RouteSegmentType {
  walk,
  lrt,
  mrt,
  bus,
  monorail;

  String get icon {
    switch (this) {
      case RouteSegmentType.walk:
        return '🚶';
      case RouteSegmentType.lrt:
      case RouteSegmentType.mrt:
      case RouteSegmentType.monorail:
        return '🚆';
      case RouteSegmentType.bus:
        return '🚌';
    }
  }

  String get label {
    switch (this) {
      case RouteSegmentType.walk:
        return 'Walk';
      case RouteSegmentType.lrt:
        return 'LRT';
      case RouteSegmentType.mrt:
        return 'MRT';
      case RouteSegmentType.bus:
        return 'Bus';
      case RouteSegmentType.monorail:
        return 'Monorail';
    }
  }
}

/// A complete route option from origin to destination.
class RouteOption {
  final String id;
  final String label;
  final String labelColor;
  final int duration; // in minutes
  final double fare; // in RM
  final int transfers;
  final List<RouteSegment> segments;

  const RouteOption({
    required this.id,
    required this.label,
    required this.labelColor,
    required this.duration,
    required this.fare,
    required this.transfers,
    required this.segments,
  });
}

/// A service alert or notification.
class AlertItem {
  final String id;
  final String line;
  final String lineColor;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String time;
  final bool read;

  const AlertItem({
    required this.id,
    required this.line,
    required this.lineColor,
    required this.severity,
    required this.title,
    required this.description,
    required this.time,
    this.read = false,
  });

  AlertItem copyWith({bool? read}) {
    return AlertItem(
      id: id,
      line: line,
      lineColor: lineColor,
      severity: severity,
      title: title,
      description: description,
      time: time,
      read: read ?? this.read,
    );
  }
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}
