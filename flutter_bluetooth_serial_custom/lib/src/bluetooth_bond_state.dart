/// Enumeration of Bluetooth bonding states
class BluetoothBondState {
  /// State name
  final String name;
  
  /// State value
  final int value;

  /// Private constructor for predefined states
  const BluetoothBondState._internal(this.name, this.value);

  /// Factory constructor from a map
  factory BluetoothBondState.fromMap(Map map) {
    switch (map['state']) {
      case 10:
        return BOND_NONE;
      case 11:
        return BOND_BONDING;
      case 12:
        return BOND_BONDED;
      default:
        return UNKNOWN;
    }
  }

  @override
  String toString() => 'BluetoothBondState.$name($value)';

  @override
  bool operator ==(Object other) =>
      other is BluetoothBondState && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Device is not paired
  static const BluetoothBondState BOND_NONE = 
      BluetoothBondState._internal('BOND_NONE', 10);
      
  /// Device is in the process of pairing
  static const BluetoothBondState BOND_BONDING = 
      BluetoothBondState._internal('BOND_BONDING', 11);
      
  /// Device is paired
  static const BluetoothBondState BOND_BONDED = 
      BluetoothBondState._internal('BOND_BONDED', 12);
      
  /// Bond state is unknown
  static const BluetoothBondState UNKNOWN = 
      BluetoothBondState._internal('UNKNOWN', -1);
} 