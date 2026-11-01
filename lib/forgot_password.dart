import 'package:flutter/material.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final accountC = TextEditingController();
  final newPasswordC = TextEditingController();
  final confirmPasswordC = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    accountC.dispose();
    newPasswordC.dispose();
    confirmPasswordC.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final account = accountC.text.trim();
    final newPassword = newPasswordC.text;
    final confirmPassword = confirmPasswordC.text;

    if (account.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields.'),
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 6 characters.',
          ),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match.',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result = await ApiService.resetPassword(
      account: account,
      newPassword: newPassword,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    final success = result['success'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (success
                  ? 'Password reset successfully.'
                  : 'Failed to reset password.'),
        ),
      ),
    );

    if (success) {
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004C40),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004C40),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 25),

              const Icon(
                Icons.lock_reset,
                color: Color(0xFF63C47A),
                size: 70,
              ),

              const SizedBox(height: 20),

              const Text(
                'Reset Your Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter your email or username and create a new password.',
                style: TextStyle(
                  color: Color(0xFFBFD6D0),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              _field(
                label: 'Email or Username',
                hint: 'Enter your email or username',
                controller: accountC,
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              _field(
                label: 'New Password',
                hint: 'Enter your new password',
                controller: newPasswordC,
                icon: Icons.lock_outline,
                obscure: hidePassword,
                suffix: IconButton(
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

              const SizedBox(height: 18),

              _field(
                label: 'Confirm Password',
                hint: 'Confirm your new password',
                controller: confirmPasswordC,
                icon: Icons.lock_outline,
                obscure: hideConfirmPassword,
                suffix: IconButton(
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

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                  loading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF63C47A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CB5AE),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFFD2DEDA),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF155447),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF759B92),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF8FE388),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}