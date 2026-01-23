import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/auth/pages/forgot_password.dart';
import 'package:libraryapp/auth/pages/signup_page.dart';
import 'package:libraryapp/auth/providers/asgardeo_auth_provider.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithAsgardeo() async {
    final asgardeoAuth = ref.read(asgardeoAuthProvider.notifier);

    final success = await asgardeoAuth.login();

    if (success && mounted) {
      // Fetch user details after successful login
      await asgardeoAuth.retrieveUserDetails();
      // The app will automatically navigate to home because
      // main.dart watches the auth state
    }
  }

  @override
  Widget build(BuildContext context) {
    final asgardeoState = ref.watch(asgardeoAuthProvider);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              const Text("Sign In", style: TextStyle(fontSize: 64)),
              const SizedBox(height: 30),

              // Show error if any
              if (asgardeoState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    asgardeoState.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: "User name"),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(hintText: "Password"),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text("Forgot password?")],
                ),
              ),

              const SizedBox(height: 16),

              // Standard Login Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.btnBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Login"),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Divider with "OR"
              Row(
                children: [
                  Expanded(child: Divider(color: Pallete.textSecondary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Pallete.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: Pallete.textSecondary)),
                ],
              ),

              const SizedBox(height: 16),

              // Asgardeo Login Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: asgardeoState.isLoading
                        ? null
                        : _loginWithAsgardeo,
                    icon: asgardeoState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      asgardeoState.isLoading
                          ? "Signing in..."
                          : "Sign in with Asgardeo",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              RichText(
                text: TextSpan(
                  text: "Don't you have an account? ",
                  style: TextStyle(color: Pallete.textPrimary),
                  children: [
                    TextSpan(
                      text: "SignUp",
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
