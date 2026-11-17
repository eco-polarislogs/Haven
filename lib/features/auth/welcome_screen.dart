import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/haven_logo.dart';
import '../../data/models/community.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';

/// Haven'ın kendi karşılama/kayıt ekranı. Google yalnızca kimliği doğrular
/// (Android'in tek dokunuşluk hesap paneli); kayıt sürecinin geri kalanı
/// (takma ad, avatar, alanlar, rıza) Haven'ın kendi ekranlarındadır.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _run(Future<UserCredential?> Function() signIn) async {
    setState(() => _busy = true);
    // Servisi await'ten ÖNCE al: giriş başarılı olunca bu ekran kalkar ve
    // sonrasında `ref` kullanmak hata verir (Riverpod 3).
    final repo = ref.read(repositoryProvider);
    try {
      final user = (await signIn())?.user;
      if (user != null) {
        await repo.ensureUserDoc(user);
        repo.addInbox(user.uid, InboxType.login);
      }
    } on AuthFailure catch (e) {
      _snack(e.message);
    } catch (e) {
      debugPrint('Giriş hatası: $e');
      _snack(
        'Giriş şu an tamamlanamadı. İnternet bağlantını kontrol edip tekrar dener misin?',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final text = Theme.of(context).textTheme;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final l = context.l10n;
    final p = HavenPalette.of(context);

    // Koyu zemin üzerinde açık renkli durum çubuğu simgeleri.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HavenColors.harborDeep,
                HavenColors.harbor,
                Color(0xFF3C7F86),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Center(child: HavenLogo(size: 128, lightColor: p.accent)),
                        const SizedBox(height: 16),
                        Text(
                          'Haven',
                          textAlign: TextAlign.center,
                          style: text.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Güvenli limanın.',
                          textAlign: TextAlign.center,
                          style: text.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Yargısız, acelesiz; kendi hızında.',
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 36),
                        const _Feature(
                          Icons.lock_outline_rounded,
                          'Sana özel, gizli bir günlük. Kayıtlarını yalnızca sen görürsün.',
                        ),
                        const _Feature(
                          Icons.groups_outlined,
                          'Aynı yolda yürüyenlerden içten destek ve seri arkadaşları.',
                        ),
                        const _Feature(
                          Icons.self_improvement_rounded,
                          'Zor anlar için nefes egzersizleri ve kısa sakinleştirici oyunlar.',
                        ),
                        const SizedBox(height: 36),
                        if (_busy)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: p.deep,
                            ),
                            onPressed: () => _run(auth.signInWithGoogle),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Flexible(child: Text(l.welcomeGoogle)),
                              ],
                            ),
                          ),
                          if (isIos) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _run(auth.signInWithApple),
                              icon: const Icon(Icons.apple),
                              label: const Text('Apple ile devam et'),
                            ),
                          ],
                        ],
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Google yalnızca kimliğini doğrular; şifren Haven ile asla paylaşılmaz. '
                                'Kaydın geri kalanını burada, birlikte tamamlayacağız.',
                                style: text.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              launchUrl(Uri.parse(kPrivacyPolicyUrl)),
                          child: Text(
                            'Gizlilik Politikası',
                            style: text.bodySmall?.copyWith(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
