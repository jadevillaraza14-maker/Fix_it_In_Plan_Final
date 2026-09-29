import 'package:flutter/material.dart';
import 'api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    contactController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (fullNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ApiService.register(
      name: fullNameController.text.trim(),
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      contact: contactController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Registration failed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004437),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
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
                              const Color(0xFF004437).withOpacity(0.45),
                              const Color(0xFF004437),
                            ],
                            stops: const [
                              0.30,
                              0.70,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 25,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.65),
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

                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
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

              Container(
                width: double.infinity,
                color: const Color(0xFF004437),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  5,
                  24,
                  25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Create your account to get started.',
                      style: TextStyle(
                        color: Color(0xFFB8CBC6),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildLabel('Full Name'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: fullNameController,
                      hintText: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 13),

                    _buildLabel('Username'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: usernameController,
                      hintText: 'Enter your username',
                      icon: Icons.account_circle_outlined,
                    ),

                    const SizedBox(height: 13),

                    _buildLabel('Email'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 13),

                    _buildLabel('Contact Number'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: contactController,
                      hintText: 'Enter your contact number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 13),

                    _buildLabel('Password'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: hidePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFD2DEDA),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 7),
                    _buildTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm your password',
                      icon: Icons.lock_outline,
                      obscureText: hideConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hideConfirmPassword =
                            !hideConfirmPassword;
                          });
                        },
                        icon: Icon(
                          hideConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFD2DEDA),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF63C47A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF63C47A)
                              .withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: Color(0xFFB8CBC6),
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color(0xFF9BE889),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CB5AE),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFD2DEDA),
            size: 24,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF155447),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF759B92),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF8FE388),
              width: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}