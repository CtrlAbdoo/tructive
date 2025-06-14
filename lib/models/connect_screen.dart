// ignore_for_file: use_key_in_widget_constructors

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
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
  bool hasPermissions = false;

  // إضافات جديدة لحل المشاكل
  StreamSubscription<Uint8List>? dataSubscription;
  Timer? keepAliveTimer;
  Timer? reconnectTimer;
  BluetoothDevice? currentDevice; // حفظ الجهاز الحالي للإعادة الاتصال
  int reconnectAttempts = 0;
  final int maxReconnectAttempts = 5;
  bool shouldReconnect = true; // للتحكم في إعادة الاتصال

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Check and request required permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final Map<String, dynamic> args = {};
        final MethodChannel permissionChannel = MethodChannel('flutter_bluetooth_serial/permissions');
        final bool? result = await permissionChannel.invokeMethod<bool>('requestPermissions', args);

        if (mounted) {
          setState(() {
            hasPermissions = result ?? false;
          });
        }

        if (hasPermissions) {
          await FlutterBluetoothSerial.instance.requestEnable();
        } else {
          _showPermissionDeniedDialog();
        }
      } else {
        if (mounted) {
          setState(() {
            hasPermissions = true;
          });
        }
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      print("Error requesting permissions: $e");
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

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
              _checkAndRequestPermissions();
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
      if (mounted) {
        setState(() {
          devices = [];
        });
      }

      List<BluetoothDevice> bondedDevices =
      await FlutterBluetoothSerial.instance.getBondedDevices();

      if (mounted) {
        setState(() {
          devices = bondedDevices;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${devices.length} paired devices'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error discovering devices: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Connect to specific device مع معالجة أفضل للأخطاء
  void _connectToDevice(BluetoothDevice device) async {
    if (isConnecting || !mounted) return;

    if (mounted) {
      setState(() {
        isConnecting = true;
        currentDevice = device; // حفظ الجهاز للإعادة الاتصال
        shouldReconnect = true;
        reconnectAttempts = 0;
      });
    }

    try {
      // محاولة الاتصال مع timeout
      BluetoothConnection newConnection = await BluetoothConnection.toAddress(
        device.address,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout after 10 seconds');
        },
      );

      if (mounted) {
        setState(() {
          connection = newConnection;
          isConnected = true;
          isConnecting = false;
          reconnectAttempts = 0;
        });

        // إعداد الـ data listener مع معالجة أفضل للأخطاء
        _setupDataListener();

        // بدء الـ keep-alive timer
        _startKeepAlive();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name ?? "Unknown Device"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
      print("Error connecting to device: $e");

      // إعادة المحاولة التلقائية
      if (shouldReconnect && reconnectAttempts < maxReconnectAttempts && mounted) {
        _scheduleReconnect();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // إعداد الـ data listener مع معالجة أفضل للأخطاء
  void _setupDataListener() {
    if (connection?.input == null || !mounted) return;

    dataSubscription?.cancel(); // إلغاء الـ subscription السابق

    dataSubscription = connection!.input!.listen(
          (Uint8List data) {
        print("Received data: ${String.fromCharCodes(data)}");
        // معالجة البيانات هنا
      },
      onError: (error) {
        print("Data stream error: $error");
        _handleConnectionLoss();
      },
      onDone: () {
        print("Data stream closed");
        _handleConnectionLoss();
      },
      cancelOnError: false, // مهم: عدم إلغاء الـ stream عند حدوث خطأ
    );
  }

  // معالجة انقطاع الاتصال
  void _handleConnectionLoss() {
    if (!mounted) return;

    setState(() {
      isConnected = false;
    });

    _stopKeepAlive();

    // إعادة المحاولة التلقائية
    if (shouldReconnect && currentDevice != null && reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  // جدولة إعادة الاتصال
  void _scheduleReconnect() {
    if (!mounted) return;

    reconnectAttempts++;
    print("Scheduling reconnect attempt $reconnectAttempts/$maxReconnectAttempts");

    reconnectTimer?.cancel();
    reconnectTimer = Timer(Duration(seconds: 2 * reconnectAttempts), () {
      if (shouldReconnect && currentDevice != null && !isConnected && mounted) {
        print("Attempting reconnect...");
        _connectToDevice(currentDevice!);
      }
    });
  }

  // Keep-alive mechanism
  void _startKeepAlive() {
    _stopKeepAlive(); // إيقاف الـ timer السابق

    keepAliveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (connection != null && isConnected && mounted) {
        try {
          // إرسال ping بسيط للحفاظ على الاتصال
          connection!.output.add(Uint8List.fromList([0x00])); // ping byte
          print("Keep-alive ping sent");
        } catch (e) {
          print("Keep-alive error: $e");
          _handleConnectionError();
        }
      }
    });
  }

  // معالجة خطأ الاتصال
  void _handleConnectionError() {
    if (!mounted) return;
    _handleConnectionLoss();
  }

  // إيقاف الـ keep-alive
  void _stopKeepAlive() {
    keepAliveTimer?.cancel();
    keepAliveTimer = null;
  }

  // قطع الاتصال
  void _disconnect() async {
    shouldReconnect = false; // منع إعادة الاتصال التلقائية

    // إيقاف الـ timers
    _stopKeepAlive();
    reconnectTimer?.cancel();

    // إلغاء الـ data subscription
    dataSubscription?.cancel();
    dataSubscription = null;

    // قطع الاتصال
    if (connection != null) {
      try {
        await connection!.finish();
      } catch (e) {
        print("Error during disconnect: $e");
      }
      connection = null;
    }

    if (mounted) {
      setState(() {
        isConnected = false;
        currentDevice = null;
        reconnectAttempts = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // إرسال البيانات مع معالجة الأخطاء
  Future<bool> sendData(String data) async {
    if (connection == null || !isConnected) {
      print("No active connection");
      return false;
    }

    try {
      connection!.output.add(Uint8List.fromList(data.codeUnits));
      print("Data sent successfully: $data");
      return true;
    } catch (e) {
      print("Error sending data: $e");
      _handleConnectionLoss();
      return false;
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
                        'Connected to: ${currentDevice?.name ?? "Unknown Device"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Address: ${currentDevice?.address ?? "Unknown"}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      if (reconnectAttempts > 0)
                        Text(
                          'Reconnect attempts: $reconnectAttempts/$maxReconnectAttempts',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _disconnect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Disconnect'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => sendData("TEST\n"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Test Send'),
                            ),
                          ),
                        ],
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
    bool isThisDeviceConnected = isConnected && currentDevice?.address == device.address;

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
    shouldReconnect = false;

    // تنظيف كل الـ resources
    _stopKeepAlive();
    reconnectTimer?.cancel();
    dataSubscription?.cancel();

    if (connection != null) {
      connection!.finish();
    }

    super.dispose();
  }
}