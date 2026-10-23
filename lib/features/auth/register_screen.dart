// KANAWA - Ecrã de Registo de Passageiro
// Design: MBSoft · Benvindo Mersh

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/phone_formatter.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';
import 'verify_code_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Tens de aceitar os Termos e Condições.';
      });
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final parts = _nameController.text.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      final response = await ApiClient.post(
        '/auth/register/',
        body: {
          'phone': normalizeAngolaPhone(_phoneController.text),
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text,
          'password_confirm': _confirmController.text,
          'first_name': firstName,
          'last_name': lastName,
          'user_type': 20,
          'country': 'AO',
        },
      );

      if (!mounted) return;

      if (response.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              phone: normalizeAngolaPhone(_phoneController.text),
              email: _emailController.text.trim().toLowerCase(),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado. Tenta novamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF18181B),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const KanawaLogoPin(size: 72, showShadow: true),

                const SizedBox(height: 20),

                Text(
                  'Cria a tua conta',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18181B),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Regista-te no KANAWA em menos de 30 segundos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF71717A),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                // NOME COMPLETO
                _FieldLabel(text: 'NOME COMPLETO'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                  decoration: _inputDecoration(
                    hint: 'João Silva',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Insere o teu nome completo';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Insere nome e sobrenome';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // TELEFONE
                _FieldLabel(text: 'TELEFONE'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4D4D8)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇦🇴', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              '+244',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          AngolaPhoneFormatter(),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                          letterSpacing: 0.5,
                        ),
                        decoration: _inputDecoration(
                          hint: '923 456 789',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insere o teu telefone';
                          }
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 9) {
                            return 'Telefone inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // EMAIL (OBRIGATÓRIO)
                _FieldLabel(text: 'EMAIL'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                  decoration: _inputDecoration(
                    hint: 'joao@exemplo.ao',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O email é obrigatório';
                    }
                    final email = value.trim();
                    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(email)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Vais receber um código de verificação por email',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // PASSWORD
                _FieldLabel(text: 'PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                    letterSpacing: 1.2,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Mínimo 8 caracteres',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFA1A1AA),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insere uma password';
                    }
                    if (value.length < 8) {
                      return 'A password deve ter pelo menos 8 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // CONFIRMAR PASSWORD
                _FieldLabel(text: 'CONFIRMAR PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                    letterSpacing: 1.2,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Repete a password',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFA1A1AA),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma a password';
                    }
                    if (value != _passwordController.text) {
                      return 'As passwords não coincidem';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // TERMOS
                GestureDetector(
                  onTap: () {
                    setState(() => _acceptTerms = !_acceptTerms);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: _acceptTerms
                              ? const Color(0xFFE01818)
                              : Colors.white,
                          border: Border.all(
                            color: _acceptTerms
                                ? const Color(0xFFE01818)
                                : const Color(0xFFD4D4D8),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _acceptTerms
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF71717A),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Aceito os '),
                              TextSpan(
                                text: 'Termos e Condições',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE01818),
                                ),
                              ),
                              const TextSpan(text: ' e a '),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE01818),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // BOTÃO CRIAR CONTA
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE01818),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFE01818).withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CRIAR CONTA',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // LINK LOGIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tens conta? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Entra',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE01818),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                const Center(child: KanawaSignature()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFFD4D4D8),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFFA1A1AA), size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4D4D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4D4D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE01818), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFDC2626)),
      suffixIcon: suffixIcon,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: const Color(0xFF71717A),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}