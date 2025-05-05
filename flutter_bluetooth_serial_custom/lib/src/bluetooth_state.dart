/// Enumeration of Bluetooth states
class BluetoothState {
  /// State name
  final String name;
  
  /// State value
  final int value;

  /// Private constructor for predefined states
  const BluetoothState._internal(this.name, this.value);

  /// Factory constructor from a map
  factory BluetoothState.fromMap(Map map) {
    switch (map['state']) {
      case 0:
        return STATE_OFF;
      case 1:
        return STATE_TURNING_ON;
      case 2:
        return STATE_ON;
      case 3:
        return STATE_TURNING_OFF;
      default:
        return ERROR;
    }
  }

  /// State is enabled (ON)
  bool get isEnabled => value == 2;

  @override
  String toString() => 'BluetoothState.$name($value)';

  @override
  bool operator ==(Object other) =>
      other is BluetoothState && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Bluetooth is OFF
  static const BluetoothState STATE_OFF = 
      BluetoothState._internal('STATE_OFF', 0);
      
  /// Bluetooth is turning ON
  static const BluetoothState STATE_TURNING_ON = 
      BluetoothState._internal('STATE_TURNING_ON', 1);
      
  /// Bluetooth is ON
  static const BluetoothState STATE_ON = 
      BluetoothState._internal('STATE_ON', 2);
      
  /// Bluetooth is turning OFF
  static const BluetoothState STATE_TURNING_OFF = 
      BluetoothState._internal('STATE_TURNING_OFF', 3);
      
  /// Bluetooth state is unknown or error
  static const BluetoothState ERROR = 
      BluetoothState._internal('ERROR', -1);
} 