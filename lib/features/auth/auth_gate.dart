import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ibex_app/core/models/user_model.dart';
import 'package:ibex_app/core/services/auth_service.dart';
import 'package:ibex_app/core/services/realtime_service.dart';
import 'package:ibex_app/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the current user model to the widget tree.
/// Listens to auth state changes and re-fetches the user profile.
class AuthGate extends ChangeNotifier {
  final _authService = AuthService();
  final _realtimeService = RealtimeService();
  UserModel? _currentUser;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;

  AuthGate() {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get userRole => _currentUser?.role;

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((authState) async {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.initialSession) {
        if (authState.session != null) {
          await _loadUserProfile();
          // Initialize realtime when authenticated
          if (isAuthenticated) {
            _realtimeService.initialize();
            NotificationService.registerPushToken();
          }
        } else {
          _currentUser = null;
          _isLoading = false;
          _realtimeService.dispose();
          notifyListeners();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isLoading = false;
        _realtimeService.dispose();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentUserProfile();
    } catch (e) {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }
}
