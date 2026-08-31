import '../models/transit_models.dart';

abstract class TransitNetworkRepository {
  Future<TransitNetwork> loadNetwork();
}
