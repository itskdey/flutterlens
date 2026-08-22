import 'lens_connection_status.dart';

class LensConnectionSnapshot {
  const LensConnectionSnapshot({
    required this.status,
    this.isFlutterApp = false,
    this.vmServiceAvailable = false,
    this.message,
  });

  const LensConnectionSnapshot.disconnected()
      : this(
          status: LensConnectionStatus.disconnected,
          message: 'Waiting for Flutter application',
        );

  final LensConnectionStatus status;
  final bool isFlutterApp;
  final bool vmServiceAvailable;
  final String? message;

  bool get isConnected => status == LensConnectionStatus.connected;

  LensConnectionSnapshot copyWith({
    LensConnectionStatus? status,
    bool? isFlutterApp,
    bool? vmServiceAvailable,
    String? message,
  }) {
    return LensConnectionSnapshot(
      status: status ?? this.status,
      isFlutterApp: isFlutterApp ?? this.isFlutterApp,
      vmServiceAvailable: vmServiceAvailable ?? this.vmServiceAvailable,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LensConnectionSnapshot &&
        other.status == status &&
        other.isFlutterApp == isFlutterApp &&
        other.vmServiceAvailable == vmServiceAvailable &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        status,
        isFlutterApp,
        vmServiceAvailable,
        message,
      );
}
