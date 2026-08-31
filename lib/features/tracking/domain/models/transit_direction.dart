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
