// This is a forwarder library that simply re-exports all the symbols from the original package
// This allows us to maintain compatibility while fixing namespace issues

library flutter_bluetooth_serial;

export 'src/bluetooth_connection.dart';
export 'src/bluetooth_device.dart';
export 'src/bluetooth_discovery.dart';
export 'src/bluetooth_bond_state.dart';
export 'src/bluetooth_state.dart';
export 'src/flutter_bluetooth_serial.dart'; 