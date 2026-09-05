import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';

void main() {
  TrackingStation makeStation({
    String id = 'kj-kl-sentral',
    String name = 'KL Sentral',
    String lineId = 'kj',
    int sequence = 13,
    double latitude = 3.1340,
    double longitude = 101.6868,
  }) {
    return TrackingStation(
      id: id,
      name: name,
      lineId: lineId,
      sequence: sequence,
      latitude: latitude,
      longitude: longitude,
    );
  }

  group('TrackingStation', () {
    test('latitude and longitude default to 0.0 when not provided', () {
      const station = TrackingStation(
        id: 'kj-gombak',
        name: 'Gombak',
        lineId: 'kj',
        sequence: 0,
      );
      expect(station.latitude, 0.0);
      expect(station.longitude, 0.0);
    });

    test('stores all required fields', () {
      final s = makeStation();
      expect(s.id, 'kj-kl-sentral');
      expect(s.name, 'KL Sentral');
      expect(s.lineId, 'kj');
      expect(s.sequence, 13);
      expect(s.latitude, 3.1340);
      expect(s.longitude, 101.6868);
    });

    test('copyWith updates only the specified fields', () {
      final original = makeStation();
      final updated = original.copyWith(name: 'Renamed', sequence: 99);
      expect(updated.id, original.id);
      expect(updated.lineId, original.lineId);
      expect(updated.name, 'Renamed');
      expect(updated.sequence, 99);
      expect(updated.latitude, original.latitude);
      expect(updated.longitude, original.longitude);
    });

    test('equality is value-based across all fields', () {
      expect(makeStation(), equals(makeStation()));
      expect(makeStation(id: 'other'), isNot(equals(makeStation())));
      expect(
        makeStation(sequence: 14),
        isNot(equals(makeStation(sequence: 15))),
      );
      expect(
        makeStation(latitude: 3.0000),
        isNot(equals(makeStation(latitude: 3.0001))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(makeStation().hashCode, makeStation().hashCode);
    });

    test('toString includes id, name, lineId, and sequence', () {
      final s = makeStation().toString();
      expect(s, contains('kj-kl-sentral'));
      expect(s, contains('KL Sentral'));
      expect(s, contains('kj'));
      expect(s, contains('13'));
    });
  });
}
