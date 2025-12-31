import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              Text("Sign Up", style: TextStyle(fontSize: 64)),
              SizedBox(height: 30),
              TextFormField(decoration: InputDecoration(hintText: "Name")),
              const SizedBox(height: 30),
              TextFormField(decoration: InputDecoration(hintText: "User name")),
              const SizedBox(height: 30),
              TextFormField(
                decoration: InputDecoration(hintText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.btnBackground,
                  ),
                  child: Text("Sign Up"),
                ),
              ),
              RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(color: Pallete.textPrimary),
                  children: [
                    TextSpan(
                      text: "Login",
                      style: TextStyle(color: Pallete.textLink),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          );
                        },
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
}
