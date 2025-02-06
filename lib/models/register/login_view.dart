import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  static String routeName = "login";

  LoginView({super.key});

  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Color(0xFF1E1E2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome To Tructive",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 32.0,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "Please sign in with your email",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 22.0,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "User Name",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: firstNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "User Name cannot be empty";
                    } else {
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Ex. Mohamed Nasser @gmail.com",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: lastNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password cannot be empty";
                    } else {
                      return null;
                    }
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                      hintText: "********************",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      )),
                ),
                const SizedBox(
                  height: 40,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Navigator.pushReplacementNamed(context,HomePage.routeName1);
                    }
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: LoginScreen(),
//     );
//   }
// }
//
// class LoginScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.black, Color(0xFF1E1E2E)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(height: 100),
//                 // Logo
//                 RichText(
//                   text: TextSpan(
//                     style: TextStyle(
//                       fontSize: 50,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                     children: [
//                       TextSpan(text: 'Truc'),
//                       WidgetSpan(
//                         child: Icon(Icons.lightbulb, color: Colors.blueAccent, size: 35),
//                       ),
//                       TextSpan(text: 'tive'),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 40),
//                 // Welcome Text
//                 Text(
//                   "Welcome Back To Tructive",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   "Please sign in with your email",
//                   style: TextStyle(color: Colors.white60),
//                 ),
//                 SizedBox(height: 40),
//                 // User Name Field
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "User Name",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 TextField(
//                   decoration: InputDecoration(
//                     hintText: "Ex. Mohamed Ibrahim",
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 // Password Field
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Password",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 TextField(
//                   obscureText: true,
//                   decoration: InputDecoration(
//                     hintText: "********************",
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 // Login Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: Text(
//                       "Login",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 // Checkbox & Text
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: false,
//                       onChanged: (value) {},
//                       checkColor: Colors.white,
//                       activeColor: Colors.blue,
//                     ),
//                     Expanded(
//                       child: Text(
//                         "Accept all the requirements that we have provided",
//                         style: TextStyle(color: Colors.white60),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
