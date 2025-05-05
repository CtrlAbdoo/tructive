import 'dart:core';

/// Class representing a Bluetooth device
class BluetoothDevice {
  /// Bluetooth device name
  final String? name;

  /// MAC address of the device
  final String address;

  /// Type of bluetooth device
  final int? type;

  /// Is the device connected
  final bool? isConnected;

  /// Construct a Bluetooth Device
  BluetoothDevice({
    required this.name,
    required this.address,
    this.type,
    this.isConnected,
  });

  /// Creates a Bluetooth Device from a map (usually from platform code)
  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      name: map['name'],
      address: map['address'],
      type: map['type'],
      isConnected: map['isConnected'],
    );
  }
  
  /// Converts the Bluetooth Device to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'type': type,
      'isConnected': isConnected,
    };
  }

  @override
  String toString() {
    return 'BluetoothDevice{name: $name, address: $address, type: $type, isConnected: $isConnected}';
  }
} 