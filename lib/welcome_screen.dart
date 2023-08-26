import 'package:flutter/material.dart';
import 'rounded_button.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
                height:
                    20.0),
            // Adding the image from the lib directory.
            Center(
              child: Image.asset(
                'lib/image.png',
                width: 500, // Specify the desired width
                height: 500, // Specify the desired height
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
                height:
                    0.0), // Add some spacing between the image and the buttons.
            RoundedButton(
              colour: Colors.indigo,
              title: 'Log In',
              onPressed: () {
                Navigator.pushNamed(context, 'login_screen');
              },
            ),
            RoundedButton(
              colour: Colors.indigo[200]!,
              title: 'Register',
              onPressed: () {
                Navigator.pushNamed(context, 'registration_screen');
              },
            ),
          ],
        ),
      ),
    );
  }
}
