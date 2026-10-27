import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthSession extends ChangeNotifier {
  AuthSession(this.service) {
    _subscription = service.changes.listen(
      (value) {
        user = value;
        waiting = false;
        error = null;
        if (!_authOperation) notifyListeners();
      },
      onError: (Object exception) {
        error = exception.toString();
        waiting = false;
        notifyListeners();
      },
    );
  }

  final AuthService service;
  late final StreamSubscription<ShelfUser?> _subscription;
  ShelfUser? user;
  bool waiting = true;
  bool _authOperation = false;
  String? error;
  String? notice;

  Future<void> register(String email, String password) async {
    _authOperation = true;
    try {
      await service.register(email, password);
      notice = 'Registration successful';
    } finally {
      _authOperation = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) =>
      service.login(email, password);

  Future<void> logout() async {
    await service.logout();
    notice = null;
  }

  void dismissNotice() {
    notice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
