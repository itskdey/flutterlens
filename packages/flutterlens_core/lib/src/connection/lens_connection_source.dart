import '../models/lens_connection_snapshot.dart';

typedef LensConnectionListener = void Function();

abstract interface class LensConnectionSource {
  LensConnectionSnapshot get current;

  void addListener(LensConnectionListener listener);

  void removeListener(LensConnectionListener listener);
}
