import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _supabase = SupabaseService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _success;

  // Tema Warna Neumorphism & Fintech
  final Color _bgColor = const Color(0xFFF0F4F8);
  final Color _shadowDark = const Color(0xFFD1D9E6);
  final Color _shadowLight = Colors.white;
  final Color _primaryText = const Color(0xFF1E293B);
  final Color _secondaryText = const Color(0xFF64748B);

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    // Validasi
    if (email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = 'Semua field wajib diisi.');
      return;
    }

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }

    if (pass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _error = 'Password dan konfirmasi password tidak sama.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final response = await _supabase.signUp(email, pass);

      if (!mounted) return;

      // Jika Supabase memerlukan konfirmasi email
      if (response.session == null && response.user != null) {
        setState(() {
          _success =
              'Registrasi berhasil! Silakan cek email kamu untuk konfirmasi akun.';
          _isLoading = false;
        });
        return;
      }

      // Jika langsung login
      if (response.session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg;
        final msg = e.toString().toLowerCase();

        if (msg.contains('over_email_send_limit') ||
            msg.contains('email rate limit')) {
          errorMsg = 'Terlalu banyak percobaan. Tunggu beberapa saat.';
        } else if (msg.contains('already registered') ||
            msg.contains('already exists')) {
          errorMsg = 'Email sudah terdaftar. Silakan masuk.';
        } else if (msg.contains('invalid email')) {
          errorMsg = 'Format email tidak valid.';
        } else if (msg.contains('password')) {
          errorMsg = 'Password terlalu lemah. Minimal 6 karakter.';
        } else {
          errorMsg = 'Registrasi gagal. Coba lagi.';
        }

        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  InputDecoration _softInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: _secondaryText.withOpacity(0.6), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF3B82F6), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _shadowDark.withOpacity(0.5),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: _shadowLight,
                              offset: const Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF1E293B)),
                      ),
                    ),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer for centering
                  ],
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowDark.withOpacity(0.4),
                        offset: const Offset(10, 10),
                        blurRadius: 24,
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-10, -10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Us!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _primaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start finding your nearest photocopies\nwith a modern touch.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Email Address',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryText),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(fontSize: 15, color: _primaryText),
                        decoration: _softInputDecoration(
                          hintText: 'e.g. hello@fintech.com',
                          prefixIcon: Icons.email_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Password',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryText),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(fontSize: 15, color: _primaryText),
                        decoration: _softInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _secondaryText,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Confirm Password',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryText),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPassController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        style: TextStyle(fontSize: 15, color: _primaryText),
                        decoration: _softInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _secondaryText,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 20, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Color(0xFFB91C1C), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_success != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 20, color: Color(0xFF22C55E)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _success!,
                                  style: const TextStyle(
                                      color: Color(0xFF15803D), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.4),
                              offset: const Offset(0, 8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading || _success != null ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: _secondaryText, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}