import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

// Tema Warna Neumorphism & Fintech
const Color _bgColor = Color(0xFFF0F4F8);
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary = Color(0xFF3B82F6);
const Color _primaryDark = Color(0xFF1D4ED8);

class EditProfile extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final VoidCallback onProfileUpdated;

  const EditProfile({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _usernameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      setState(() => _error = 'Nama dan username tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = SupabaseService().currentUser;
      if (user != null) {
        // Update user metadata di Supabase Auth
        await SupabaseService().updateUserProfile(
          displayName: name,
          username: username,
        );

        if (mounted) {
          widget.onProfileUpdated();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil berhasil diperbarui'),
              backgroundColor: const Color(0xFF10B981), // Emerald Success
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(24),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Gagal memperbarui profil: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _softInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _secondaryText.withOpacity(0.6), fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 24,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_rounded, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded, color: _secondaryText, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Error Message ──
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Email Field (Read Only) ──
            const Text(
              'Email (Tetap)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              style: const TextStyle(fontSize: 14, color: _secondaryText),
              decoration: _softInputDecoration(
                hint: widget.currentEmail,
                icon: Icons.email_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // ── Name Field ──
            const Text(
              'Nama Lengkap',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              style: const TextStyle(fontSize: 15, color: _primaryText, fontWeight: FontWeight.w500),
              decoration: _softInputDecoration(
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // ── Username Field ──
            const Text(
              'Username',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              enabled: !_isLoading,
              style: const TextStyle(fontSize: 15, color: _primaryText, fontWeight: FontWeight.w500),
              decoration: _softInputDecoration(
                hint: 'Masukkan username',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 32),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: _secondaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.4),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}