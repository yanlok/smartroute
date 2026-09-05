import '../../../../shared/models/journey_models.dart';

class FavoriteJourney {
  final String id;
  final String userId;
  final String label;
  final String originStopId;
  final String destinationStopId;
  final RouteObjective objective;
  final DateTime updatedAt;

  const FavoriteJourney({
    required this.id,
    required this.userId,
    required this.label,
    required this.originStopId,
    required this.destinationStopId,
    required this.objective,
    required this.updatedAt,
  });
}

class RecentJourney {
  final String id;
  final String userId;
  final String originStopId;
  final String destinationStopId;
  final DateTime searchedAt;

  const RecentJourney({
    required this.id,
    required this.userId,
    required this.originStopId,
    required this.destinationStopId,
    required this.searchedAt,
  });
}
