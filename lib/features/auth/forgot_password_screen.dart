// KANAWA - Esqueci-me da password
// v1.0 — 2 passos: pedir código + redefinir

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const green = Color(0xFF16A34A);
  static const blue = Color(0xFF1E5FE0);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const bgApp = Color(0xFFFAFAFA);
  static const bgCard = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E4E7);
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Passo 1 — pedir código
  final _identifierController = TextEditingController();

  // Passo 2 — inserir código + nova password
  final _codeController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 1;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Future<void> _requestCode() async {
    if (_isLoading) return;

    if (_identifierController.text.trim().isEmpty) {
      _showSnack('Introduz o telefone ou email', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/auth/forgot-password/',
        body: {'identifier': _identifierController.text.trim()},
        authenticated: false,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Código enviado! Verifica o email.');
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Erro ao enviar código', isError: true);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    if (_codeController.text.trim().length != 6) {
      _showSnack('O código tem 6 dígitos', isError: true);
      return;
    }
    if (!_validatePassword(_newController.text)) {
      _showSnack('Password fraca', isError: true);
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showSnack('As passwords não coincidem', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/auth/reset-password/',
        body: {
          'identifier': _identifierController.text.trim(),
          'code': _codeController.text.trim(),
          'new_password': _newController.text,
          'new_password_confirm': _confirmController.text,
        },
        authenticated: false,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Password redefinida! Já podes fazer login.');
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        setState(() => _isLoading = false);
        _showSnack(response.errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Erro ao redefinir', isError: true);
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
                child: _step == 1 ? _buildStep1() : _buildStep2(),
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
            _step == 1 ? 'Recuperar password' : 'Nova password',
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

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Esqueceste-te da password?',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _C.textStrong,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Introduz o teu telefone ou email. Enviaremos um código para redefinir.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 32),
        _buildField(
          label: 'Telefone ou email',
          controller: _identifierController,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _C.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'ENVIAR CÓDIGO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Código enviado',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _C.textStrong,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vê o código no email/consola e introduz abaixo.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 32),
        _buildField(
          label: 'Código de 6 dígitos',
          controller: _codeController,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Nova password',
          controller: _newController,
          icon: Icons.lock_outline_rounded,
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Confirmar nova password',
          controller: _confirmController,
          icon: Icons.lock_outline_rounded,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _C.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'REDEFINIR PASSWORD',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 1),
            child: Text(
              'Voltar',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
    VoidCallback? onToggle,
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
                  maxLength: maxLength,
                  obscureText: obscure,
                  enabled: !_isLoading,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textStrong,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (onToggle != null)
                IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: _C.textMuted,
                    size: 20,
                  ),
                  onPressed: onToggle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}