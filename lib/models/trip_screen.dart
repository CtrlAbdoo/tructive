import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TripScreen extends StatefulWidget {
  final BluetoothConnection connection;

  const TripScreen({required this.connection});

  @override
  _TripScreenState createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  StreamSubscription<Uint8List>? _subscription;
  String speed = "0";
  bool harshBraking = false;
  double? previousSpeed;
  DateTime? lastSpeedUpdateTime;
  final double harshBrakingThreshold = 10.0; // كمثال: 10 كم/س خلال ثانية

  @override
  void initState() {
    super.initState();
    _listenToOBDData();
    _sendOBDCommands();
  }

  void _sendOBDCommands() {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        bool connected = await widget.connection.isConnected;
        if (connected) {
          widget.connection.output.add(Uint8List.fromList("010D\r".codeUnits));
        } else {
          timer.cancel();
        }
      } catch (e) {
        print("Error checking connection or sending command: $e");
        timer.cancel();
      }
    });
  }


  void _listenToOBDData() {
    _subscription = widget.connection.input?.listen((Uint8List data) {
      final response = String.fromCharCodes(data).replaceAll('\r', '').trim();

      if (response.contains('41 0D')) {
        try {
          final parts = response.split(' ');
          final hexSpeed = parts.last;
          final intSpeed = int.parse(hexSpeed, radix: 16);
          final now = DateTime.now();

          if (previousSpeed != null && lastSpeedUpdateTime != null) {
            final deltaTime = now.difference(lastSpeedUpdateTime!).inSeconds;
            final speedDiff = previousSpeed! - intSpeed;

            if (deltaTime > 0 && speedDiff / deltaTime >= harshBrakingThreshold) {
              setState(() => harshBraking = true);
              print("Harsh braking detected!");
            } else {
              setState(() => harshBraking = false);
            }
          }

          previousSpeed = intSpeed.toDouble();
          lastSpeedUpdateTime = now;

          setState(() => speed = intSpeed.toString());
        } catch (e) {
          print("Error parsing speed: $e");
        }
      }
    }, onError: (error) {
      print("Error receiving data: $error");
    }, onDone: () {
      print("Connection closed.");
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Data'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Current Speed: $speed km/h',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              'Harsh Braking: ${harshBraking ? "Yes" : "No"}',
              style: TextStyle(
                fontSize: 20,
                color: harshBraking ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
