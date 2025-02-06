import 'package:flutter/material.dart';

import 'models/register/login_view.dart';
import 'models/splash_screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute:Splash_Screen.routeName ,
      routes:{
        Splash_Screen.routeName:(context) => const Splash_Screen(),
        LoginView.routeName: (context) => LoginView(),
      } ,

    );
  }
}

