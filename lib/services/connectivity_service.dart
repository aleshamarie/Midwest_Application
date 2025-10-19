import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isConnected = true;

  static bool get isConnected => _isConnected;

  static Future<void> initialize() async {
    // Check initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  static Widget buildOfflineBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isConnected ? 0 : 50,
      child: _isConnected
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: Colors.red,
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
