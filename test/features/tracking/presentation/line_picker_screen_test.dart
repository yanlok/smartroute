import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/line_picker_controller.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';
import 'package:smartroute/features/tracking/domain/models/line_operational_status.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:smartroute/features/tracking/presentation/screens/line_picker_screen.dart';

class FakeDirectory implements LineDirectoryRepository {
  List<TransitLine> lines = const [
    TransitLine(
      id: 'kj',
      code: 'KJ',
      name: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorToken: 'kjLine',
      orderedStationIds: <String>[],
    ),
  ];
  bool shouldThrow = false;
  int callCount = 0;

  @override
  Future<List<TransitLine>> getLines() async {
    callCount++;
    if (shouldThrow) {
      throw const TrackingRepositoryException('boom');
    }
    return lines;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTracking implements TrackingRepository {
  final DateTime _now = DateTime.utc(2026, 1, 1);
  late final Map<String, LineStatus> statuses = {
    'kj': LineStatus(
      lineId: 'kj',
      status: LineOperationalStatus.onTime,
      delayMinutes: 0,
      lastUpdated: _now,
    ),
  };

  @override
  Future<LineStatus> getLineStatus(String lineId) async =>
      statuses[lineId] ??
      LineStatus(
        lineId: lineId,
        status: LineOperationalStatus.onTime,
        delayMinutes: 0,
        lastUpdated: _now,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LinePickerController buildController({
  required FakeDirectory dir,
  required FakeTracking trk,
}) {
  return LinePickerController(
    directoryRepository: dir,
    trackingRepository: trk,
  );
}

void main() {
  group('LinePickerScreen', () {
    testWidgets('renders lines with status pills', (tester) async {
      final dir = FakeDirectory();
      final trk = FakeTracking();
      final controller = buildController(dir: dir, trk: trk);

      await tester.pumpWidget(
        MaterialApp(
          home: LinePickerScreen(
            onBack: () {},
            onNavigate: (_) {},
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelana Jaya Line'), findsOneWidget);
      expect(find.text('On Time'), findsOneWidget);
    });

    testWidgets('shows error + retry on directory failure', (tester) async {
      final dir = FakeDirectory()..shouldThrow = true;
      final trk = FakeTracking();
      final controller = buildController(dir: dir, trk: trk);

      await tester.pumpWidget(
        MaterialApp(
          home: LinePickerScreen(
            onBack: () {},
            onNavigate: (_) {},
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
