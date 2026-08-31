enum TransitMode {
  lrt,
  mrt,
  monorail,
  brt,
  bus;

  String get label {
    switch (this) {
      case TransitMode.lrt:
        return 'LRT';
      case TransitMode.mrt:
        return 'MRT';
      case TransitMode.monorail:
        return 'Monorail';
      case TransitMode.brt:
        return 'BRT';
      case TransitMode.bus:
        return 'Bus';
    }
  }
}
