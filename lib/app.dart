import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/gentle_states.dart';
import 'data/services/local_notifier.dart';
import 'features/auth/welcome_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/session/session_bootstrap.dart';
import 'features/shell/home_shell.dart';
import 'l10n/l10n.dart';
import 'l10n/tx.dart';
import 'providers.dart';

/// Bildirime dokunulunca doğru ekrana gitmek için.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class HavenApp extends ConsumerStatefulWidget {
  const HavenApp({super.key});

  @override
  ConsumerState<HavenApp> createState() => _HavenAppState();
}

class _HavenAppState extends ConsumerState<HavenApp> {
  @override
  void initState() {
    super.initState();
    LocalNotifier.onTap = _openFromNotification;
    LocalNotifier.launchPayload().then(_openFromNotification);
  }

  /// Topluluk bildirimleri bildirim merkezini açar; şefkatli hatırlatmalar
  /// sadece uygulamayı açar (Bugün sekmesi).
  void _openFromNotification(String? payload) {
    if (payload != 'inbox') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null || ref.read(uidProvider) == null) return;
      nav.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'notifications'),
          builder: (_) => const ScreenView(name: 'notifications', child: NotificationsScreen()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(themePresetProvider);
    final design = ref.watch(designProvider);
    final locale = ref.watch(localeProvider);
    // Koddaki metinler (tx) bu dili kullanır. Dil değişince ağacın tamamı
    // yeniden kurulsun diye ana sayfa dile göre anahtarlanır.
    Tx.code = locale.languageCode;
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Haven',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(design, preset),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: KeyedSubtree(key: ValueKey(locale.languageCode), child: const AuthGate()),
    );
  }
}

/// Tek yönlendirme noktası; ekran, durumdan türetilir:
///   oturum yok                 → Karşılama (Haven'ın kendi kayıt ekranı)
///   profil/alan seçilmemiş      → Kayıt akışı (avatar & anonimlik, alanlar, topluluk, rıza)
///   aksi halde                 → 4 sekmeli ana kabuk
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const GentleLoading(),
      error: (e, _) => GentleError(message: tx('Bir şeyler ters gitti. Uygulamayı yeniden açmayı dener misin?')),
      data: (user) {
        if (user == null) {
          return const ScreenView(name: 'welcome', child: WelcomeScreen());
        }
        return ref
            .watch(appUserProvider)
            .when(
              loading: () => const GentleLoading(),
              error: (e, _) => GentleError(message: tx('Verilerine şu an ulaşamadık. Biraz sonra tekrar dener misin?')),
              data: (appUser) => (appUser == null || !appUser.isOnboarded)
                  ? const ScreenView(name: 'onboarding', child: OnboardingFlow())
                  : const SessionBootstrap(child: HomeShell()),
            );
      },
    );
  }
}
