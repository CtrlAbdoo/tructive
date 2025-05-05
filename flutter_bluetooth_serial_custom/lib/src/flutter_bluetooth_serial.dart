import 'dart:async';

import 'package:flutter/services.dart';
import 'bluetooth_device.dart';
import 'bluetooth_state.dart';

/// Main class for handling Bluetooth Serial connections
class FlutterBluetoothSerial {
  /// Singleton instance
  static final FlutterBluetoothSerial _instance = FlutterBluetoothSerial._();

  /// Singleton accessor
  static FlutterBluetoothSerial get instance => _instance;

  /// Method channel for communication with the platform
  static const MethodChannel _methodChannel =
      MethodChannel('flutter_bluetooth_serial');

  /// Stream controller for Bluetooth state changes
  final StreamController<BluetoothState> _stateController = 
      StreamController<BluetoothState>.broadcast();

  /// Stream of Bluetooth state changes
  Stream<BluetoothState> get onStateChanged => _stateController.stream;

  /// Private constructor for singleton
  FlutterBluetoothSerial._() {
    // Set up method call handler for state changes
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStateChanged':
          final int state = call.arguments;
          _stateController.add(_stateFromInt(state));
          break;
      }
      return null;
    });
  }

  /// Request Bluetooth enable
  Future<bool> requestEnable() async {
    try {
      final bool? result = await _methodChannel.invokeMethod('requestEnable');
      return result ?? false;
    } catch (e) {
      print('Error requesting Bluetooth enable: $e');
      return false;
    }
  }

  /// Get current Bluetooth state
  Future<BluetoothState> get state async {
    try {
      final int? stateInt = await _methodChannel.invokeMethod('getState');
      return _stateFromInt(stateInt);
    } catch (e) {
      print('Error getting Bluetooth state: $e');
      return BluetoothState.ERROR;
    }
  }

  /// Convert integer state to BluetoothState enum
  BluetoothState _stateFromInt(int? state) {
    switch (state) {
      case 0:
        return BluetoothState.STATE_OFF;
      case 1:
        return BluetoothState.STATE_TURNING_ON;
      case 2:
        return BluetoothState.STATE_ON;
      case 3:
        return BluetoothState.STATE_TURNING_OFF;
      default:
        return BluetoothState.ERROR;
    }
  }

  /// Check if Bluetooth is available on this device
  Future<bool> get isAvailable async {
    try {
      final bool? available = await _methodChannel.invokeMethod('isAvailable');
      return available ?? false;
    } catch (e) {
      print('Error checking Bluetooth availability: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> get isEnabled async {
    try {
      final bool? enabled = await _methodChannel.invokeMethod('isEnabled');
      return enabled ?? false;
    } catch (e) {
      print('Error checking if Bluetooth is enabled: $e');
      return false;
    }
  }

  /// Get list of paired/bonded devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<dynamic>? deviceList = await _methodChannel.invokeMethod('getBondedDevices');
      
      if (deviceList == null) {
        return [];
      }
      
      return deviceList.map((device) {
        final Map<dynamic, dynamic> deviceMap = device as Map<dynamic, dynamic>;
        return BluetoothDevice(
          name: deviceMap['name'] as String?,
          address: deviceMap['address'] as String,
          type: deviceMap['type'] as int?,
          isConnected: deviceMap['isConnected'] as bool?,
        );
      }).toList();
    } catch (e) {
      print('Error getting bonded devices: $e');
      return [];
    }
  }
  
  /// Dispose of resources
  void dispose() {
    if (!_stateController.isClosed) {
      _stateController.close();
    }
  }
} 