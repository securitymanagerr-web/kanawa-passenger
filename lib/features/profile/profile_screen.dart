// KANAWA - Perfil do utilizador
// v1.2 — Botões ligados a EditProfile, ChangePassword, ForgotPassword

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const blueSoft = Color(0xFFE8F0FE);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFF0FDF4);
  static const amber = Color(0xFFD97706);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFFFAFAFA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgSoft = Color(0xFFF4F4F5);
  static const border = Color(0xFFE4E4E7);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  final List<Map<String, String>> _favoriteAddresses = [
    {'label': 'Casa', 'address': 'Bairro Txizainga 1, Saurimo'},
    {'label': 'Trabalho', 'address': 'Governo Provincial, Centro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/auth/me/');
      if (!mounted) return;

      if (response.success && response.data is Map) {
        setState(() {
          _user = User.fromJson(response.data as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Terminar sessão?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: _C.textStrong,
          ),
        ),
        content: Text(
          'Vais precisar de fazer login de novo para pedir viagens.',
          style: GoogleFonts.inter(
            color: _C.textMuted,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: _C.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sair',
              style: GoogleFonts.inter(
                color: _C.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiClient.clearTokens();
    await ApiClient.clearPendingVerification();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════════════════
  // ABRIR EDIÇÃO DE PERFIL
  // ═══════════════════════════════════════════════════════
  Future<void> _openEditProfile() async {
    if (_user == null) {
      _showSnack('A carregar perfil...');
      return;
    }
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user!),
      ),
    );
    if (updated == true && mounted) {
      _loadUser();
    }
  }

  // ═══════════════════════════════════════════════════════
  // ABRIR ALTERAR PASSWORD
  // ═══════════════════════════════════════════════════════
  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // OUTRAS AÇÕES (por agora SnackBar)
  // ═══════════════════════════════════════════════════════
  void _openPaymentMethods() {
    _showSnack('Métodos de pagamento em breve');
  }

  void _addFavoriteAddress() {
    _showSnack('Adicionar endereço em breve');
  }

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'KANAWA',
      applicationVersion: '1.0.0',
      applicationLegalese: 'MBSoft · Benvindo Mersh · 2026\nAngola 🇦🇴',
      children: [
        const SizedBox(height: 12),
        Text(
          'Plataforma de transporte por aplicativo desenvolvida para Angola.',
          style: GoogleFonts.inter(fontSize: 13, color: _C.textMuted),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: _C.blueDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _C.red),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildPersonalInfo(),
                    const SizedBox(height: 16),
                    _buildPaymentMethods(),
                    const SizedBox(height: 16),
                    _buildFavoriteAddresses(),
                    const SizedBox(height: 16),
                    _buildSettings(),
                    const SizedBox(height: 16),
                    _buildLogout(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════
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
            'Perfil',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _C.textStrong,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: _C.textStrong,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER COM AVATAR
  // ═══════════════════════════════════════════════════════
  Widget _buildProfileHeader() {
    final firstName = _user?.firstName ?? '';
    final lastName = _user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'K';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.red, _C.redDark],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _C.red.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _C.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : 'Utilizador KANAWA',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _user?.phone ?? '—',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  if (_user?.email != null && _user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _user!.email!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // INFO PESSOAL
  // ═══════════════════════════════════════════════════════
  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Section(
        title: 'Informação pessoal',
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nome completo',
            value:
                '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim(),
            onTap: _openEditProfile,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: _user?.phone ?? '—',
            onTap: null,
          ),
          if (_user?.email != null && _user!.email!.isNotEmpty)
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _user!.email!,
              onTap: _openEditProfile,
            ),
          _InfoRow(
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            value: '••••••••',
            trailing: 'Alterar',
            onTap: _openChangePassword,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MÉTODOS DE PAGAMENTO
  // ═══════════════════════════════════════════════════════
  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Section(
        title: 'Métodos de pagamento',
        children: [
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Dinheiro',
            value: 'Predefinido',
            trailing: 'Alterar',
            onTap: _openPaymentMethods,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ENDEREÇOS FAVORITOS
  // ═══════════════════════════════════════════════════════
  Widget _buildFavoriteAddresses() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Section(
        title: 'Endereços favoritos',
        children: [
          ..._favoriteAddresses.map(
            (addr) => _InfoRow(
              icon: addr['label'] == 'Casa'
                  ? Icons.home_outlined
                  : Icons.work_outline_rounded,
              label: addr['label']!,
              value: addr['address']!,
              onTap: null,
            ),
          ),
          _AddRow(
            label: 'Adicionar endereço',
            onTap: _addFavoriteAddress,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CONFIGURAÇÕES
  // ═══════════════════════════════════════════════════════
  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Section(
        title: 'Sobre',
        children: [
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Sobre o KANAWA',
            value: 'Versão 1.0.0',
            onTap: _openAbout,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════
  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _handleLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: _C.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Terminar sessão',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Center(
      child: Text(
        'MBSoft · Benvindo Mersh',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: _C.textSubtle,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.bgSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _C.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _C.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _C.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.blue,
                ),
              )
            else if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _C.textSubtle,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.blueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: _C.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _C.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}