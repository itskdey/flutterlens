import 'lens_build_mode.dart';

class LensRuntimeInfo {
  const LensRuntimeInfo({
    required this.buildMode,
    required this.inspectorAvailable,
    required this.dtdAvailable,
    this.flutterVersion,
    this.dartSdkVersion,
    this.operatingSystem,
    this.vmName,
    this.mainIsolateName,
    this.mainIsolateId,
  });

  final String? flutterVersion;
  final String? dartSdkVersion;
  final String? operatingSystem;
  final String? vmName;
  final String? mainIsolateName;
  final String? mainIsolateId;
  final LensBuildMode buildMode;
  final bool inspectorAvailable;
  final bool dtdAvailable;

  @override
  bool operator ==(Object other) {
    return other is LensRuntimeInfo &&
        other.flutterVersion == flutterVersion &&
        other.dartSdkVersion == dartSdkVersion &&
        other.operatingSystem == operatingSystem &&
        other.vmName == vmName &&
        other.mainIsolateName == mainIsolateName &&
        other.mainIsolateId == mainIsolateId &&
        other.buildMode == buildMode &&
        other.inspectorAvailable == inspectorAvailable &&
        other.dtdAvailable == dtdAvailable;
  }

  @override
  int get hashCode => Object.hash(
    flutterVersion,
    dartSdkVersion,
    operatingSystem,
    vmName,
    mainIsolateName,
    mainIsolateId,
    buildMode,
    inspectorAvailable,
    dtdAvailable,
  );
}
