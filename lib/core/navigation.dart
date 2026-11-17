import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Ekranı açar ve Analytics'e `screen_view` olarak kaydeder.
/// Uygulamadaki TÜM sayfa geçişleri bu fonksiyondan geçmeli.
Future<T?> pushScreen<T>(BuildContext context, String name, Widget page) {
  return Navigator.of(context).push<T>(MaterialPageRoute(
    settings: RouteSettings(name: name),
    builder: (_) => ScreenView(name: name, child: page),
  ));
}

/// Ekran ilk kez göründüğünde bir kez `screen_view` kaydeder
/// (her yeniden çizimde değil).
class ScreenView extends ConsumerStatefulWidget {
  const ScreenView({super.key, required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  ConsumerState<ScreenView> createState() => _ScreenViewState();
}

class _ScreenViewState extends ConsumerState<ScreenView> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).screen(widget.name);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
