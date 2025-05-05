import 'dart:async';

import 'package:flutter/services.dart';

/// Represents an established connection to a Bluetooth device
class BluetoothConnection {
  /// The connection handle that is used by platform 
  /// specific code to maintain connection.
  final int? _connectionHandle;

  /// The address of the connected device
  final String address;

  /// Input stream controller (from the device)
  final StreamController<Uint8List> _inputStreamController = 
      StreamController<Uint8List>.broadcast();

  /// Output stream controller (to the device)
  final StreamController<Uint8List> _outputStreamController = 
      StreamController<Uint8List>();

  /// Channel for handling the incoming messages from device
  static const MethodChannel _methodChannel =
      MethodChannel('flutter_bluetooth_serial');

  /// Is the connection currently established?
  bool _isConnected = true;

  /// Stream sink for sending data to the device
  StreamSink<Uint8List> get output => _outputStreamController.sink;

  /// Stream of data received from the device
  Stream<Uint8List> get input => _inputStreamController.stream;

  /// Constructs a BluetoothConnection object from a handle
  BluetoothConnection._fromHandle(this._connectionHandle, this.address) {
    // Set up output stream listener to forward data to platform
    _outputStreamController.stream.listen((data) {
      if (_isConnected) {
        _methodChannel.invokeMethod('write', {
          'address': address,
          'data': data,
        });
      }
    });

    // Register this connection for receiving data
    _registerForDataReceived();
  }

  void _registerForDataReceived() {
    // Set up method call handler for incoming data
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDataReceived':
          final Map<dynamic, dynamic> args = call.arguments;
          if (args['address'] == address) {
            final Uint8List data = args['data'];
            _inputStreamController.add(data);
          }
          break;
        case 'onDeviceDisconnected':
          final Map<dynamic, dynamic> args = call.arguments;
          if (args['address'] == address) {
            _isConnected = false;
            // Close streams but don't complete them yet to allow buffered data to be read
            await finish();
          }
          break;
      }
      return null;
    });
  }

  /// Establishes a connection to a Bluetooth device
  static Future<BluetoothConnection> toAddress(String address) async {
    try {
      final handle = await _methodChannel.invokeMethod<int>(
        'connect', 
        {'address': address}
      );
      
      if (handle != null) {
        return BluetoothConnection._fromHandle(handle, address);
      } else {
        throw 'Failed to connect to device: unknown error';
      }
    } catch (e) {
      throw 'Cannot connect to device: $e';
    }
  }

  /// Checks if the connection is still active
  Future<bool> get isConnected async {
    try {
      final connected = await _methodChannel.invokeMethod<bool>(
        'isConnected', 
        {'address': address}
      );
      _isConnected = connected ?? false;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Disconnects from the device
  Future<void> finish() async {
    _isConnected = false;
    
    try {
      // Try to disconnect on the platform side
      await _methodChannel.invokeMethod(
        'disconnect', 
        {'address': address}
      );
    } catch (e) {
      print('Error disconnecting: $e');
    }
    
    // Close the streams
    if (!_inputStreamController.isClosed) {
      await _inputStreamController.close();
    }
    
    if (!_outputStreamController.isClosed) {
      await _outputStreamController.close();
    }
  }

  @override
  String toString() => 'BluetoothConnection{$address}';
} 