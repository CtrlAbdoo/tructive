import 'dart:async';

import 'package:flutter/material.dart';

import '../register/login_view.dart';

class Splash_Screen extends StatelessWidget {
  static const String routeName = "splash";

  const Splash_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, LoginView.routeName);
    });

    var mediaQuery = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF1E1E2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/image/tructive-high-resolution-logo-transparent (4) 2.png",
                width: mediaQuery.width,
                height: mediaQuery.height,
                 // fit: BoxFit.cover,
               ),
              SizedBox(height: 20),
              Text(
                '"Ready to Transform Your Fleet Operations?"',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
