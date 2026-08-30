import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_up.dart';
import '../localization/app_localizations.dart';

enum _AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  _AuthMode _mode = _AuthMode.login;
  bool _obscure = true;
  bool _submitting = false;
  bool _googleBusy = false;
  String? _errorText;
  VoidCallback? _errorAction;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  AppLocalizations get t => AppLocalizations.of(context);

  bool get _busy => _submitting || _googleBusy;

  void _clearError() {
    if (_errorText == null && _errorAction == null) return;
    setState(() {
      _errorText = null;
      _errorAction = null;
    });
  }

  void _switchMode(_AuthMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _clearError();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return t.authRequiredField;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return t.errorInvalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return t.authRequiredField;
    if (_mode == _AuthMode.register && password.length < 6) {
      return t.errorWeakPassword;
    }
    return null;
  }

  Future<void> _submitEmail() async {
    _clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      if (_mode == _AuthMode.login) {
        await sl<SignInUseCase>()(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await sl<SignUpUseCase>()(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      setState(() => _submitting = false);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _showFailure(failure);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = t.errorGenericAuth;
        _errorAction = null;
      });
    }
  }

  void _showResetPasswordDialog() {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: Icon(Icons.lock_reset_rounded,
                  size: 36, color: scheme.primary),
              title: Text(t.resetPasswordTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.resetPasswordSubtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: t.emailShort,
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 21),
                      filled: true,
                      fillColor: scheme.onSurface.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.cancel),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = controller.text.trim();
                          if (email.isEmpty ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                            return;
                          }
                          setDialogState(() => sending = true);
                          try {
                            await sl<ResetPasswordUseCase>()(email: email);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.resetPasswordSuccess),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } on Failure catch (failure) {
                            setDialogState(() => sending = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(failure.message),
                                backgroundColor: scheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() => sending = false);
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.resetPasswordButton),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      try {
        controller.dispose();
      } catch (_) {}
    });
  }

  Future<void> _signInWithGoogle() async {
    _clearError();
    setState(() => _googleBusy = true);
    try {
      await sl<SignInWithGoogleUseCase>()();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _showFailure(failure));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = t.errorGenericAuth);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showFailure(Failure failure) {
    final code = failure is AuthFailure ? failure.code : null;
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        _errorText = t.errorWrongPassword;
        _errorAction = null;
        break;
      case 'user-not-found':
        _errorText = t.errorUserNotFound;
        _errorAction = () => _switchMode(_AuthMode.register);
        break;
      case 'email-already-in-use':
        _errorText = t.errorEmailInUse;
        _errorAction = () => _switchMode(_AuthMode.login);
        break;
      case 'weak-password':
        _errorText = t.errorWeakPassword;
        _errorAction = null;
        break;
      case 'invalid-email':
        _errorText = t.errorInvalidEmail;
        _errorAction = null;
        break;
      case 'network-request-failed':
        _errorText = t.errorNetwork;
        _errorAction = null;
        break;
      default:
        _errorText = t.errorGenericAuth;
        _errorAction = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    _buildCard(context),
                    const SizedBox(height: 26),
                    _buildDivider(context),
                    const SizedBox(height: 18),
                    _buildGoogleButton(context),
                    const SizedBox(height: 24),
                    Text(
                      t.authTermsNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.authTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_AuthMode>(
            segments: [
              ButtonSegment(
                value: _AuthMode.login,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(t.authTabLogin),
              ),
              ButtonSegment(
                value: _AuthMode.register,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(t.authTabRegister),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => _switchMode(selection.first),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    onChanged: (_) => _clearError(),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    decoration: _inputDecoration(
                      context,
                      label: t.emailShort,
                      prefix: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    validator: _validatePassword,
                    onChanged: (_) => _clearError(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submitEmail(),
                    decoration: _inputDecoration(
                      context,
                      label: t.authPasswordLabel,
                      prefix: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: scheme.onSurfaceVariant,
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_mode == _AuthMode.login)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _showResetPasswordDialog,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  t.forgotPassword,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _errorText != null
                ? _ErrorBanner(
                    message: _errorText!,
                    actionLabel: _errorAction != null
                        ? (_mode == _AuthMode.login
                            ? t.authTabRegister
                            : t.authTabLogin)
                        : null,
                    onAction: _errorAction,
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submitEmail,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(_mode == _AuthMode.login
                    ? t.authLoginButton
                    : t.authRegisterButton),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            t.authOrContinue,
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        foregroundColor: scheme.onSurface,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: _googleBusy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: scheme.onSurfaceVariant,
              ),
            )
          : const _GoogleLogo(size: 20),
      label: Text(t.authGoogleButton),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData prefix,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefix, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.6)),
      focusedBorder: border(scheme.primary),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 19, color: scheme.onErrorContainer),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: scheme.onErrorContainer,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: Text(actionLabel!),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.width;
    final double strokeWidth = side * 0.20;
    final Offset center = Offset(side / 2, side / 2);
    final Rect box = Rect.fromCircle(
      center: center,
      radius: (side - strokeWidth) / 2,
    );

    void arc(double fromDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color;
      canvas.drawArc(
        box,
        fromDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        paint,
      );
    }

    arc(180, 135, _red);
    arc(140, 40, _yellow);
    arc(0, 140, _green);
    arc(315, 45, _blue);

    final barPaint = Paint()..color = _blue;
    final double barHeight = strokeWidth * 0.92;
    final double barTop = center.dy - barHeight / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx,
          barTop,
          box.right - center.dx + strokeWidth / 2,
          barHeight,
        ),
        Radius.circular(barHeight / 2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
