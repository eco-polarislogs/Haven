import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Topluluk paylaşımlarını CİHAZ ÜSTÜNDE çevirir (Google ML Kit).
///
/// Gizlilik: metin hiçbir sunucuya gönderilmez; dil modeli bir kez indirilir
/// (dil başına ~30 MB) ve sonra çevrimdışı çalışır. Çeviriler oturum boyunca
/// önbellekte tutulur.
abstract final class PostTranslator {
  static final _cache = <String, String>{};
  static final _models = OnDeviceTranslatorModelManager();

  static TranslateLanguage? _language(String code) => switch (code) {
    'tr' => TranslateLanguage.turkish,
    'en' => TranslateLanguage.english,
    'es' => TranslateLanguage.spanish,
    'zh' => TranslateLanguage.chinese,
    'hi' => TranslateLanguage.hindi,
    _ => null,
  };

  /// Bu dil çifti çevrilebilir mi? (Web'de ML Kit yok.)
  static bool supports(String from, String to) =>
      !kIsWeb && from != to && _language(from) != null && _language(to) != null;

  /// Çeviri; model indirilemezse ya da hata olursa null.
  static Future<String?> translate(String text, {required String from, required String to}) async {
    if (!supports(from, to)) return null;
    final key = '$from>$to:$text';
    final cached = _cache[key];
    if (cached != null) return cached;
    final source = _language(from)!;
    final target = _language(to)!;
    try {
      for (final l in {source, target}) {
        if (!await _models.isModelDownloaded(l.bcpCode)) {
          final ok = await _models.downloadModel(l.bcpCode, isWifiRequired: false);
          if (!ok) return null;
        }
      }
      final translator = OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
      try {
        final out = await translator.translateText(text);
        _cache[key] = out;
        return out;
      } finally {
        await translator.close();
      }
    } catch (e) {
      debugPrint('Çeviri yapılamadı: $e');
      return null;
    }
  }
}
