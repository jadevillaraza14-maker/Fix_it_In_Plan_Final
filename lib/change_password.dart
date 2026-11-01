import 'package:flutter/material.dart';
import 'api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int clientId;

  const ChangePasswordScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final currentC = TextEditingController();
  final newC = TextEditingController();
  final confirmC = TextEditingController();

  bool loading = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    currentC.dispose();
    newC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> submit() async {
    final current = currentC.text;
    final newer = newC.text;
    final confirm = confirmC.text;

    if (current.isEmpty || newer.isEmpty || confirm.isEmpty) {
      _toast('Please complete all fields.');
      return;
    }

    if (newer.length < 6) {
      _toast('New password must be at least 6 characters.');
      return;
    }

    if (newer != confirm) {
      _toast('Passwords do not match.');
      return;
    }

    if (current == newer) {
      _toast('New password must be different.');
      return;
    }

    setState(() => loading = true);

    final result = await ApiService.changePassword(
      clientId: widget.clientId,
      oldPassword: current,
      newPassword: newer,
    );

    if (!mounted) return;

    setState(() => loading = false);

    final success = result['success'] == true;

    _toast(
      result['message']?.toString() ??
          (success
              ? 'Password changed successfully.'
              : 'Failed to change password.'),
    );

    if (success) {
      await Future.delayed(const Duration(milliseconds: 800));
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
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 25),

              const Icon(
                Icons.lock_outline,
                color: Color(0xFF63C47A),
                size: 70,
              ),

              const SizedBox(height: 20),

              const Text(
                'Update Your Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter your current password, then choose a new one.',
                style: TextStyle(
                  color: Color(0xFFBFD6D0),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              _field(
                label: 'Current Password',
                hint: 'Enter your current password',
                controller: currentC,
                icon: Icons.key_outlined,
                obscure: hideCurrent,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      hideCurrent = !hideCurrent;
                    });
                  },
                  icon: Icon(
                    hideCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFD2DEDA),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _field(
                label: 'New Password',
                hint: 'At least 6 characters',
                controller: newC,
                icon: Icons.lock_outline,
                obscure: hideNew,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      hideNew = !hideNew;
                    });
                  },
                  icon: Icon(
                    hideNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFD2DEDA),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _field(
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                controller: confirmC,
                icon: Icons.lock_outline,
                obscure: hideConfirm,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      hideConfirm = !hideConfirm;
                    });
                  },
                  icon: Icon(
                    hideConfirm
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
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF63C47A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Change Password',
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF759B92),
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
      ],
    );
  }
}