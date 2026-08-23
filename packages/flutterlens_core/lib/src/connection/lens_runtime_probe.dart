import '../models/lens_runtime_info.dart';

abstract interface class LensRuntimeProbe {
  Future<LensRuntimeInfo> probe();
}
