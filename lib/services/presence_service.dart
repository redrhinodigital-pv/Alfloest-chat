import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';

/// Service to handle real-time user presence tracking and periodic heartbeats.
class PresenceService with WidgetsBindingObserver {
  final String uid;
  final UserRepository _userRepo;

  Timer? _heartbeatTimer;
  bool _isInitialized = false;
  bool _isForeground = true;

  PresenceService({required this.uid, required UserRepository userRepo})
      : _userRepo = userRepo;

  /// Initialize lifecycle listeners and start periodic heartbeat.
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Register AppLifecycleState observer
    WidgetsBinding.instance.addObserver(this);

    // Initial heartbeat
    _sendPresenceUpdate(true);
    _startHeartbeat();
  }

  /// Clean up timers and status updates on logout or app termination.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    _setOfflineSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Realtime Presence: App lifecycle state changed to $state');
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      _sendPresenceUpdate(true);
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached ||
               state == AppLifecycleState.inactive) {
      _isForeground = false;
      _stopHeartbeat();
      _sendPresenceUpdate(false);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!_isForeground) return;
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isForeground) {
        _sendPresenceUpdate(true);
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendPresenceUpdate(bool isOnline) async {
    try {
      await _userRepo.setOnlineStatus(uid, isOnline);
      debugPrint('Realtime Presence: Heartbeat sent successfully (isOnline: $isOnline)');
    } catch (e) {
      debugPrint('Realtime Presence: Failed to send presence update (isOnline: $isOnline): $e');
    }
  }

  void _setOfflineSync() {
    _userRepo.setOnlineStatus(uid, false).catchError((e) {
      debugPrint('Realtime Presence: Offline update failed during dispose: $e');
    });
  }
}
