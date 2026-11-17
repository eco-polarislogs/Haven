import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.navToday` kısayolu.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Desteklenen diller: Türkçe + dünyada en çok konuşulan 4 dil.
const kLanguageNames = {'tr': 'Türkçe', 'en': 'English', 'es': 'Español', 'zh': '中文', 'hi': 'हिन्दी'};
