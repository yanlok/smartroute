/// The high-level public-transport mode a [TransitLine] belongs to.
///
/// These values are stable identifiers used in domain models, shared
/// contracts, and any cross-module references. They MUST NOT be renamed
/// without coordinating a contract change.
///
/// The [label] getter returns a user-facing string for UI display.
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
