/// Direction a [LiveVehicle] is currently travelling along its line.
///
/// `forward` means positionFraction is increasing (towards the line's
/// terminal station). `reverse` means positionFraction is decreasing
/// (towards the line's origin station).
enum TransitDirection {
  forward,
  reverse;

  TransitDirection get opposite {
    switch (this) {
      case TransitDirection.forward:
        return TransitDirection.reverse;
      case TransitDirection.reverse:
        return TransitDirection.forward;
    }
  }
}
