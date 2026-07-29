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
