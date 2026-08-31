import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/line_picker_controller.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';
import 'package:smartroute/features/tracking/domain/models/line_operational_status.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';

class FakeDirectoryRepository implements LineDirectoryRepository {
  List<TransitLine> linesResult = const [
    TransitLine(
      id: 'kj',
      code: 'KJ',
      name: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorToken: 'kjLine',
      orderedStationIds: <String>[],
    ),
  ];
  int getLinesCallCount = 0;
  bool shouldThrow = false;

  @override
  Future<List<TransitLine>> getLines() async {
    getLinesCallCount++;
    if (shouldThrow) {
      throw const TrackingRepositoryException('catalog boom');
    }
    return linesResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTrackingRepository implements TrackingRepository {
  Map<String, LineStatus> statusResults = <String, LineStatus>{};
  int getLineStatusCallCount = 0;
  bool shouldThrowOnStatus = false;

  @override
  Future<LineStatus> getLineStatus(String lineId) async {
    getLineStatusCallCount++;
    if (shouldThrowOnStatus) {
      throw const TrackingRepositoryException('status boom');
    }
    return statusResults[lineId] ??
        LineStatus(
          lineId: lineId,
          status: LineOperationalStatus.onTime,
          delayMinutes: 0,
          lastUpdated: DateTime.utc(2026, 1, 1),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDirectoryRepository directoryRepo;
  late FakeTrackingRepository trackingRepo;
  late LinePickerController controller;

  setUp(() {
    directoryRepo = FakeDirectoryRepository();
    trackingRepo = FakeTrackingRepository();
    controller = LinePickerController(
      directoryRepository: directoryRepo,
      trackingRepository: trackingRepo,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('LinePickerController', () {
    test('initial state is empty and not loaded', () {
      expect(controller.lines, isEmpty);
      expect(controller.statuses, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.hasLoaded, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('load() populates lines and statuses', () async {
      await controller.load();
      expect(controller.lines, hasLength(1));
      expect(controller.lines.first.id, 'kj');
      expect(controller.statuses['kj'], isNotNull);
      expect(controller.statuses['kj']!.status, LineOperationalStatus.onTime);
      expect(controller.hasLoaded, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('load() handles directory error and exposes errorMessage', () async {
      directoryRepo.shouldThrow = true;
      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'catalog boom');
      expect(controller.hasLoaded, isFalse);
    });

    test('a failing status does not fail the whole load', () async {
      trackingRepo.shouldThrowOnStatus = true;
      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.hasLoaded, isTrue);

      expect(controller.lines, hasLength(1));
    });

    test('refresh forces another directory fetch', () async {
      await controller.load();
      expect(directoryRepo.getLinesCallCount, 1);
      await controller.refresh();
      expect(directoryRepo.getLinesCallCount, 2);
    });
  });
}
