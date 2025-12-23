import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/auth/pages/forgot_password.dart';
import 'package:libraryapp/auth/pages/signup_page.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              Text("Sign In", style: TextStyle(fontSize: 64)),
              SizedBox(height: 30),
              TextFormField(
                decoration: InputDecoration(hintText: "User name"),
              ),
              const SizedBox(height: 30),
              TextFormField(
                decoration: InputDecoration(hintText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 10),
          
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPassword(),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text("Forgot password?")],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.btnBackground,
                  ),
                  child: Text("Login"),
                ),
              ),
              RichText(
                text: TextSpan(
                  text: "Don't you have an account? ",
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "SignUp",
                      style: TextStyle(color: Colors.red),
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
