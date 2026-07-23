import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    print("========== LOGIN ==========");
    print("Button Pressed");

    setState(() {
      isLoading = true;
    });

    try {
      print("Email: ${emailController.text.trim()}");
      print("Trying Firebase Login...");

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Firebase Login SUCCESS");

      if (!mounted) {
        print("Widget not mounted");
        return;
      }

      print("Going to Home Page...");
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException");
      print("Code: ${e.code}");
      print("Message: ${e.message}");

      String message;

      switch (e.code) {
        case "user-not-found":
          message = "الحساب غير موجود";
          break;

        case "wrong-password":
          message = "كلمة المرور غير صحيحة";
          break;

        case "invalid-email":
          message = "البريد الإلكتروني غير صحيح";
          break;

        case "invalid-credential":
          message = "البريد أو كلمة المرور غير صحيحة";
          break;

        default:
          message = e.message ?? "حدث خطأ";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e, s) {
      print("UNKNOWN ERROR");
      print(e);
      print(s);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    print("========== END LOGIN ==========");
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              Image.asset(
                'assets/images/مدار باللون الاساسي بدون خلفية.png',
                height: 80,
              ),

              const SizedBox(height: 16),

              const Text(
                "مدار | Madar",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "إدارة ديون متجرك بسهولة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 45),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "البريد الإلكتروني",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "كلمة المرور",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff315052),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () {
                  context.push('/register');
                },
                child: const Text("إنشاء حساب جديد"),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}