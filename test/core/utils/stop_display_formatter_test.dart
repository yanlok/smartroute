import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/utils/transit_presentation.dart';

void main() {
  group('TransitPresentation.formatStopName', () {
    test('removes leading alphanumeric stop code prefixes', () {
      expect(
        TransitPresentation.formatStopName('Sj237 Terminal Puchong Utama'),
        'Terminal Puchong Utama',
      );
      expect(
        TransitPresentation.formatStopName('Kl101 Hub Lebuh Pudu'),
        'Hub Lebuh Pudu',
      );
      expect(
        TransitPresentation.formatStopName('Kj154 Taman Sri Nanding'),
        'Taman Sri Nanding',
      );
      expect(
        TransitPresentation.formatStopName('Aj256 Flat Intan'),
        'Flat Intan',
      );
      expect(
        TransitPresentation.formatStopName('Sb01 Sunway-Setia Jaya'),
        'Sunway-Setia Jaya',
      );
      expect(
        TransitPresentation.formatStopName('Kg01 Kwasa Damansara'),
        'Kwasa Damansara',
      );
      expect(
        TransitPresentation.formatStopName('Py01 Sungai Buloh'),
        'Sungai Buloh',
      );
    });

    test('removes (m) / (M3) prefixes combined with stop codes', () {
      expect(
        TransitPresentation.formatStopName('(m) Aj16 Transformer (opp)'),
        'Transformer',
      );
      expect(
        TransitPresentation.formatStopName('(m) Kj623 Lotus Semenyih (opp)'),
        'Lotus Semenyih',
      );
      expect(
        TransitPresentation.formatStopName(
          '(m) Kl152 Lrt Bandar Tasik Selatan',
        ),
        'Lrt Bandar Tasik Selatan',
      );
      expect(
        TransitPresentation.formatStopName(
          '(M3) Stesen LRT Bandar Tasik Selatan',
        ),
        'Stesen LRT Bandar Tasik Selatan',
      );
      expect(
        TransitPresentation.formatStopName('(m) Dewan Serbaguna Au5'),
        'Dewan Serbaguna Au5',
      );
    });

    test('removes trailing noise parentheticals', () {
      expect(
        TransitPresentation.formatStopName(
          'Kl1933 Pasar Seni (platform E1 - E3)',
        ),
        'Pasar Seni',
      );
      expect(
        TransitPresentation.formatStopName('Kj623 Lotus Semenyih (opp)'),
        'Lotus Semenyih',
      );
      expect(
        TransitPresentation.formatStopName('Kj623 Lotus Semenyih (opp.)'),
        'Lotus Semenyih',
      );
      expect(
        TransitPresentation.formatStopName('Kj623 Lotus Semenyih (opposite)'),
        'Lotus Semenyih',
      );
      expect(
        TransitPresentation.formatStopName(
          'Kl100 Stesen Monorail (Platform 1)',
        ),
        'Stesen Monorail',
      );
      expect(
        TransitPresentation.formatStopName('Kl200 Stesen MRT (Pintu A)'),
        'Stesen MRT',
      );
    });

    test('preserves clean official station and stop names untouched', () {
      expect(TransitPresentation.formatStopName('Pasar Seni'), 'Pasar Seni');
      expect(TransitPresentation.formatStopName('KL Sentral'), 'KL Sentral');
      expect(
        TransitPresentation.formatStopName('Origin Station'),
        'Origin Station',
      );
      expect(
        TransitPresentation.formatStopName('Destination Station'),
        'Destination Station',
      );
      expect(
        TransitPresentation.formatStopName('Sunway-Setia Jaya'),
        'Sunway-Setia Jaya',
      );
      expect(TransitPresentation.formatStopName('Mid Valley'), 'Mid Valley');
    });

    test('handles empty or whitespace strings safely', () {
      expect(TransitPresentation.formatStopName(''), '');
      expect(TransitPresentation.formatStopName('   '), '');
    });
  });
}
