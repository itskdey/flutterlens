import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensConnectionController extends ChangeNotifier {
  LensConnectionController(this._source) : _snapshot = _source.current {
    _source.addListener(_handleSourceChanged);
  }

  final LensConnectionSource _source;
  LensConnectionSnapshot _snapshot;

  LensConnectionSnapshot get snapshot => _snapshot;

  void _handleSourceChanged() {
    final next = _source.current;
    if (next == _snapshot) return;
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _source.removeListener(_handleSourceChanged);
    super.dispose();
  }
}
