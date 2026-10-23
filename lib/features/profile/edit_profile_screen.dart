// KANAWA - Editar Perfil
// v1.0 — Usa PATCH /auth/me/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const green = Color(0xFF16A34A);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFFFAFAFA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgInput = Color(0xFFF4F4F5);
  static const border = Color(0xFFE4E4E7);
}

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _emailController.text = widget.user.email ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (_firstNameController.text.trim().isEmpty) {
      _showSnack('O nome não pode estar vazio', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      debugPrint('📤 PATCH /auth/me/ → $body');

      final response = await ApiClient.patch('/auth/me/', body: body);

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Data: ${response.data}');

      if (!mounted) return;

      if (response.success) {
        _showSnack('Perfil atualizado com sucesso!');
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        setState(() => _isSaving = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Erro ao guardar. Tenta novamente.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    _buildField(
                      label: 'Nome',
                      controller: _firstNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Sobrenome',
                      controller: _lastNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O telefone não pode ser alterado.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: _C.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _C.textStrong,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Editar perfil',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final name = _firstNameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _C.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _C.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: _C.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: _C.textMuted, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  enabled: !_isSaving,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textStrong,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _C.border,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'GUARDAR ALTERAÇÕES',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}