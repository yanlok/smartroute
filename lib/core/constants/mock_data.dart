import '../../shared/models/app_models.dart';

/// Mock data matching the React SmartRoute application's hardcoded data.

const List<TransportLine> transportLines = [
  TransportLine(
    id: 'kjl',
    name: 'Kelana Jaya Line',
    shortName: 'KJ',
    color: '#009FE3',
    status: TransportStatus.onTime,
  ),
  TransportLine(
    id: 'spl',
    name: 'Sri Petaling Line',
    shortName: 'SP',
    color: '#00A550',
    status: TransportStatus.minorDelay,
    delay: 8,
  ),
  TransportLine(
    id: 'mrt-k',
    name: 'MRT Kajang Line',
    shortName: 'MK',
    color: '#003087',
    status: TransportStatus.onTime,
  ),
  TransportLine(
    id: 'mrt-p',
    name: 'MRT Putrajaya',
    shortName: 'MP',
    color: '#8B0000',
    status: TransportStatus.minorDelay,
    delay: 5,
  ),
  TransportLine(
    id: 'mono',
    name: 'KL Monorail',
    shortName: 'ML',
    color: '#7C3AED',
    status: TransportStatus.onTime,
  ),
  TransportLine(
    id: 'brt',
    name: 'BRT Sunway',
    shortName: 'BR',
    color: '#F59E0B',
    status: TransportStatus.onTime,
  ),
];

const List<StationInfo> nearbyStations = [
  StationInfo(
    id: 'asv',
    name: 'Asia Jaya',
    lines: ['KJ'],
    lineColors: ['#009FE3'],
    distance: '320m',
    walkTime: 4,
  ),
  StationInfo(
    id: 'taman',
    name: 'Taman Jaya',
    lines: ['KJ'],
    lineColors: ['#009FE3'],
    distance: '650m',
    walkTime: 8,
  ),
  StationInfo(
    id: 'subang',
    name: 'Subang Jaya',
    lines: ['KTM'],
    lineColors: ['#E8730A'],
    distance: '1.2km',
    walkTime: 15,
  ),
];

const List<RouteOption> routeOptions = [
  RouteOption(
    id: 'fastest',
    label: 'Fastest',
    labelColor: '#16A34A',
    duration: 28,
    fare: 2.50,
    transfers: 1,
    segments: [
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'Current Location',
        to: 'Asia Jaya LRT',
        duration: 4,
      ),
      RouteSegment(
        type: RouteSegmentType.lrt,
        from: 'Asia Jaya',
        to: 'KL Sentral',
        line: 'Kelana Jaya Line',
        lineColor: '#009FE3',
        duration: 18,
        stops: 6,
      ),
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'KL Sentral',
        to: 'Destination',
        duration: 6,
      ),
    ],
  ),
  RouteOption(
    id: 'cheapest',
    label: 'Cheapest',
    labelColor: '#1B4FD8',
    duration: 38,
    fare: 1.80,
    transfers: 2,
    segments: [
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'Current Location',
        to: 'Bus Stop T142',
        duration: 3,
      ),
      RouteSegment(
        type: RouteSegmentType.bus,
        from: 'SS15',
        to: 'Subang Parade',
        line: 'Bus 400',
        lineColor: '#F59E0B',
        duration: 15,
        stops: 5,
      ),
      RouteSegment(
        type: RouteSegmentType.lrt,
        from: 'Asia Jaya',
        to: 'KL Sentral',
        line: 'Kelana Jaya Line',
        lineColor: '#009FE3',
        duration: 14,
        stops: 5,
      ),
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'KL Sentral',
        to: 'Destination',
        duration: 6,
      ),
    ],
  ),
  RouteOption(
    id: 'direct',
    label: 'Direct',
    labelColor: '#7C3AED',
    duration: 42,
    fare: 3.20,
    transfers: 0,
    segments: [
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'Current Location',
        to: 'Subang Jaya LRT',
        duration: 3,
      ),
      RouteSegment(
        type: RouteSegmentType.lrt,
        from: 'Subang Jaya',
        to: 'KL Sentral',
        line: 'Kelana Jaya Line',
        lineColor: '#009FE3',
        duration: 32,
        stops: 10,
      ),
      RouteSegment(
        type: RouteSegmentType.walk,
        from: 'KL Sentral',
        to: 'Destination',
        duration: 7,
      ),
    ],
  ),
];

const List<AlertItem> alertsData = [
  AlertItem(
    id: '1',
    line: 'MRT Kajang Line',
    lineColor: '#003087',
    severity: AlertSeverity.warning,
    title: 'Minor service delay',
    description:
        'Trains running 5–8 minutes late between Semantan and Tun Razak Exchange due to an earlier signal fault.',
    time: '10 min ago',
  ),
  AlertItem(
    id: '2',
    line: 'Sri Petaling Line',
    lineColor: '#00A550',
    severity: AlertSeverity.info,
    title: 'Enhanced weekend service',
    description:
        'Additional trains deployed on Fridays 5–7 PM for increased passenger capacity during peak hours.',
    time: '1 hr ago',
  ),
  AlertItem(
    id: '3',
    line: 'Kelana Jaya Line',
    lineColor: '#009FE3',
    severity: AlertSeverity.info,
    title: 'Scheduled maintenance',
    description:
        'Track maintenance at Gombak depot this Sunday 1–5 AM. No passenger service impact expected.',
    time: '2 hr ago',
    read: true,
  ),
  AlertItem(
    id: '4',
    line: 'KL Monorail',
    lineColor: '#7C3AED',
    severity: AlertSeverity.critical,
    title: 'Temporary suspension',
    description:
        'Service suspended between Bukit Bintang and Titiwangsa. Bus replacement services are available at both stations.',
    time: '3 hr ago',
    read: true,
  ),
];

/// Journey planner: station stops on the Kelana Jaya Line.
const List<String> kjLineStops = [
  'Asia Jaya',
  'Taman Paramount',
  'Taman Jaya',
  'Universiti',
  'Bangsar',
  'KL Sentral',
];

/// Searchable Klang Valley locations used by the journey planner.
///
/// These are station and stop names, rather than free-form route results, so
/// the planner can keep the selected endpoints consistent with its results.
const List<Map<String, String>> plannerLocations = [
  {'name': 'Asia Jaya', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Kelana Jaya', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Taman Jaya', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Universiti', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Bangsar', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'KL Sentral', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'KLCC', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Pasar Seni', 'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  {'name': 'Kajang', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Bukit Bintang', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Tun Razak Exchange', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Merdeka', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Titiwangsa', 'mode': 'Monorail', 'line': 'KL Monorail'},
  {'name': 'Bukit Nanas', 'mode': 'Monorail', 'line': 'KL Monorail'},
  {'name': 'Medan Tuanku', 'mode': 'Monorail', 'line': 'KL Monorail'},
  {'name': 'SS15', 'mode': 'Bus', 'line': 'Rapid KL Bus'},
  {'name': 'Petaling Jaya', 'mode': 'Bus', 'line': 'Rapid KL Bus'},
  {'name': 'Sunway Pyramid', 'mode': 'BRT', 'line': 'BRT Sunway'},
  {'name': 'USJ 7', 'mode': 'BRT', 'line': 'BRT Sunway'},
  {'name': 'Subang Jaya', 'mode': 'KTM', 'line': 'KTM Komuter'},
  {'name': 'Pavilion Kuala Lumpur', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Pavilion Bukit Jalil', 'mode': 'LRT', 'line': 'Sri Petaling Line'},
  {
    'name': 'Pavilion Damansara Heights',
    'mode': 'MRT',
    'line': 'MRT Putrajaya Line',
  },
  {'name': 'Pavilion Square', 'mode': 'MRT', 'line': 'MRT Kajang Line'},
  {'name': 'Pavilion Embassy', 'mode': 'MRT', 'line': 'MRT Putrajaya Line'},
];

List<RouteOption> routeOptionsForJourney(String from, String to) {
  if (from == 'Subang Jaya' && to == 'KLCC') {
    return [
      RouteOption(
        id: 'subang-klcc-fastest',
        label: 'Fastest',
        labelColor: '#16A34A',
        duration: 39,
        fare: 3.60,
        transfers: 1,
        segments: [
          RouteSegment(
            type: RouteSegmentType.ktm,
            from: 'Subang Jaya',
            to: 'KL Sentral',
            line: 'KTM Komuter',
            lineColor: '#E8730A',
            duration: 25,
            stops: 5,
          ),
          RouteSegment(
            type: RouteSegmentType.lrt,
            from: 'KL Sentral',
            to: 'KLCC',
            line: 'Kelana Jaya Line',
            lineColor: '#009FE3',
            duration: 10,
            stops: 4,
          ),
        ],
      ),
      RouteOption(
        id: 'subang-klcc-budget',
        label: 'Cheapest',
        labelColor: '#1B4FD8',
        duration: 48,
        fare: 2.90,
        transfers: 1,
        segments: [
          RouteSegment(
            type: RouteSegmentType.bus,
            from: 'Subang Jaya',
            to: 'Pasar Seni',
            line: 'Rapid KL Bus',
            lineColor: '#F59E0B',
            duration: 34,
            stops: 12,
          ),
          RouteSegment(
            type: RouteSegmentType.lrt,
            from: 'Pasar Seni',
            to: 'KLCC',
            line: 'Kelana Jaya Line',
            lineColor: '#009FE3',
            duration: 10,
            stops: 3,
          ),
        ],
      ),
    ];
  }

  if (from == 'Asia Jaya' && to == 'KL Sentral') {
    return routeOptions;
  }

  final fromLocation = plannerLocations.firstWhere(
    (location) => location['name'] == from,
    orElse: () => {'mode': 'LRT', 'line': 'Kelana Jaya Line'},
  );
  final mode = fromLocation['mode'];
  final type = switch (mode) {
    'MRT' => RouteSegmentType.mrt,
    'Bus' || 'BRT' => RouteSegmentType.bus,
    'Monorail' => RouteSegmentType.monorail,
    'KTM' => RouteSegmentType.ktm,
    _ => RouteSegmentType.lrt,
  };
  final lineColor = switch (mode) {
    'MRT' => '#003087',
    'Bus' || 'BRT' => '#F59E0B',
    'Monorail' => '#7C3AED',
    'KTM' => '#E8730A',
    _ => '#009FE3',
  };
  return [
    RouteOption(
      id: 'journey-fastest',
      label: 'Fastest',
      labelColor: '#16A34A',
      duration: 28,
      fare: 2.50,
      transfers: 0,
      segments: [
        RouteSegment(
          type: type,
          from: from,
          to: to,
          line: fromLocation['line'],
          lineColor: lineColor,
          duration: 22,
          stops: 6,
        ),
      ],
    ),
  ];
}

/// Recent searches for the planner.
const List<Map<String, String>> recentSearches = [
  {'from': 'Asia Jaya', 'to': 'KL Sentral'},
  {'from': 'Subang Jaya', 'to': 'KLCC'},
  {'from': 'Kelana Jaya', 'to': 'Bukit Bintang'},
];

/// Popular destinations.
const List<Map<String, String>> popularDestinations = [
  {'name': 'KLCC', 'emoji': '🏙️'},
  {'name': 'Bukit Bintang', 'emoji': '🛍️'},
  {'name': 'KL Sentral', 'emoji': '🚉'},
  {'name': 'Petaling Jaya', 'emoji': '🏢'},
];

/// Favourite routes on the home screen.
const List<Map<String, String>> favouriteRoutes = [
  {
    'from': 'Asia Jaya',
    'to': 'KL Sentral',
    'duration': '28 min',
    'fare': 'RM 2.50',
    'via': 'KJ Line',
  },
  {
    'from': 'Subang Jaya',
    'to': 'KLCC',
    'duration': '35 min',
    'fare': 'RM 2.90',
    'via': 'KJ → Monorail',
  },
];
