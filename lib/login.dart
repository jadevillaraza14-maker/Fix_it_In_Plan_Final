import 'package:flutter/material.dart';
import 'api_service.dart';

import 'dashboard.dart';
import 'signup.dart';
import 'client_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool rememberMe = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your username/email and password.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ApiService.login(
      login: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    // ==========================================================
    // LOGIN SUCCESS
    // ==========================================================

    if (result['success'] == true) {
      final user = result['user'];

      final role = user['role'];

      // ========================================================
      // ADMIN
      // ========================================================

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );

        return;
      }

      // ========================================================
      // CLIENT
      // ========================================================

      if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientDashboardScreen(
              clientId:
              int.tryParse(
                user['id']?.toString() ?? '0',
              ) ??
                  0,
              clientName:
              user['name']?.toString() ?? 'Client',
              username:
              user['username']?.toString() ?? '',
              email:
              user['email']?.toString() ?? '',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // UNKNOWN ROLE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unknown account type.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // LOGIN FAILED
    // ==========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ?? 'Login failed.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004437),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // =================================================
              // HOUSE PHOTO
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 285,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/Loginpic.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF004437)
                                  .withOpacity(0.45),
                              const Color(0xFF004437),
                            ],
                            stops: const [
                              0.40,
                              0.75,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // LOGO
                    // =================================================

                    Positioned(
                      top: 18,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color:
                              Colors.white.withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                Colors.white.withOpacity(0.65),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.home_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),

                          const SizedBox(height: 7),

                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Fix It In Plan ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Plan',
                                  style: TextStyle(
                                    color: Color(0xFF8FE388),
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 2),

                          const Text(
                            'Build Your Dream Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // LOGIN FORM
              // =================================================

              Container(
                width: double.infinity,
                color: const Color(0xFF004437),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Login to continue',
                      style: TextStyle(
                        color: Color(0xFFB8CBC6),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Email or Username',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    SizedBox(
                      height: 55,
                      child: TextField(
                        controller: emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText:
                          'Enter your email or username',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CB5AE),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFFD2DEDA),
                            size: 24,
                          ),
                          filled: true,
                          fillColor:
                          const Color(0xFF155447),
                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFF759B92),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFF8FE388),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    const Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    SizedBox(
                      height: 55,
                      child: TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText:
                          'Enter your password',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CB5AE),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFD2DEDA),
                            size: 24,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword =
                                !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons
                                  .visibility_off_outlined
                                  : Icons
                                  .visibility_outlined,
                              color:
                              const Color(0xFFD2DEDA),
                              size: 24,
                            ),
                          ),
                          filled: true,
                          fillColor:
                          const Color(0xFF155447),
                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFF759B92),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFF8FE388),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // REMEMBER ME
                    // =================================================

                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe =
                                    value ?? false;
                              });
                            },
                            activeColor:
                            const Color(0xFF70C979),
                            checkColor:
                            const Color(0xFF004437),
                            side: const BorderSide(
                              color: Color(0xFFB5C8C2),
                              width: 1.5,
                            ),
                          ),

                          const Text(
                            'Remember me',
                            style: TextStyle(
                              color: Color(0xFFD1DEDA),
                              fontSize: 13,
                            ),
                          ),

                          const Spacer(),

                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF9BE889),
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // =================================================
                    // LOGIN BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                        isLoading ? null : login,
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF63C47A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF63C47A)
                              .withOpacity(0.6),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =================================================
                    // SIGN UP
                    // =================================================

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SignupScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                        ),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                "Don't have an account? ",
                                style: TextStyle(
                                  color:
                                  Color(0xFFB8CBC6),
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                  color:
                                  Color(0xFF9BE889),
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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