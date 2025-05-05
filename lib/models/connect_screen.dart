// ignore_for_file: use_key_in_widget_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConnectScreen extends StatefulWidget {
  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<BluetoothDevice> devices = [];
  BluetoothConnection? connection;
  bool isConnected = false;
  bool isConnecting = false;
  bool hasPermissions = false; // Track permissions status

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Check and request required permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request permissions through platform channel
        final Map<String, dynamic> args = {};
        final MethodChannel permissionChannel = MethodChannel('flutter_bluetooth_serial/permissions');
        final bool? result = await permissionChannel.invokeMethod<bool>('requestPermissions', args);
        
        setState(() {
          hasPermissions = result ?? false;
        });
        
        if (hasPermissions) {
          // Request Bluetooth enable
          await FlutterBluetoothSerial.instance.requestEnable();
        } else {
          _showPermissionDeniedDialog();
        }
      } else {
        // For non-Android platforms
        setState(() {
          hasPermissions = true;
        });
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      print("Error requesting permissions: $e");
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bluetooth Permissions Required'),
        content: Text(
          'This app needs Bluetooth permissions to connect to devices. '
          'Please enable them in your device settings.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkAndRequestPermissions(); // Try requesting again
            },
            child: Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Search for available devices
  void _startDeviceDiscovery() async {
    if (!hasPermissions) {
      await _checkAndRequestPermissions();
      if (!hasPermissions) {
        _showPermissionDeniedDialog();
        return;
      }
    }
    
    try {
      // Clear previous devices
      setState(() {
        devices = [];
      });
      
      // Get bonded/paired devices
      List<BluetoothDevice> bondedDevices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      setState(() {
        devices = bondedDevices;
      });
      
      // Show a snackbar with device count
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${devices.length} paired devices'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error discovering devices: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Connect to specific device
  void _connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return;
    
    setState(() {
      isConnecting = true;
    });
    
    try {
      // Actual Bluetooth connection
      BluetoothConnection newConnection =
          await BluetoothConnection.toAddress(device.address);
      
      setState(() {
        connection = newConnection;
        isConnected = true;
        isConnecting = false;
      });

      // Listen for incoming data
      connection!.input!.listen((data) {
        print("Received data: ${String.fromCharCodes(data)}");
        // You can process the data here
      }).onDone(() {
        // Connection closed
        setState(() {
          isConnected = false;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name ?? "Unknown Device"}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isConnecting = false;
      });
      print("Error connecting to device: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnect() async {
    if (connection != null) {
      await connection!.finish();  // Using finish() instead of close()
      setState(() {
        isConnected = false;
        connection = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startDeviceDiscovery,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Devices',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startDeviceDiscovery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  'Scan for Paired Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: devices.isEmpty
                      ? const Center(
                          child: Text(
                            'No devices found\nPair devices in Bluetooth Settings first',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceItem(devices[index]);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected to: ${devices.firstWhere(
                          (d) {
                            // Extract address from BluetoothConnection string: "BluetoothConnection{address}"
                            String connStr = connection?.toString() ?? "";
                            String addr = "";
                            // Check if we have the expected format with {address}
                            if (connStr.contains("{") && connStr.contains("}")) {
                              addr = connStr.split("{")[1].split("}")[0];
                            }
                            return d.address == addr;
                          },
                          orElse: () => BluetoothDevice(
                            name: "Unknown", 
                            address: ""
                          )
                        ).name ?? "Unknown Device"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(BluetoothDevice device) {
    bool isThisDeviceConnected = isConnected && connection != null;
    
    if (isThisDeviceConnected) {
      // Extract address from BluetoothConnection string: "BluetoothConnection{address}"
      String connStr = connection?.toString() ?? "";
      String addr = "";
      // Check if we have the expected format with {address}
      if (connStr.contains("{") && connStr.contains("}")) {
        addr = connStr.split("{")[1].split("}")[0];
      }
      isThisDeviceConnected = device.address == addr;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isThisDeviceConnected
              ? Colors.green
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        onTap: isConnecting || isConnected ? null : () => _connectToDevice(device),
        title: Text(
          device.name ?? "Unknown Device",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Address: ${device.address}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: isConnecting 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isThisDeviceConnected
                ? const Icon(Icons.bluetooth_connected, color: Colors.green)
                : const Icon(Icons.bluetooth, color: Colors.blue),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up connection
    if (connection != null) {
      connection!.finish();  // Using finish() instead of dispose()
    }
    super.dispose();
  }
}