// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Haven';

  @override
  String get navToday => 'Hoy';

  @override
  String get navCommunity => 'Comunidad';

  @override
  String get navCalm => 'Calma';

  @override
  String get navProfile => 'Perfil';

  @override
  String get welcomeTagline => 'Tu puerto seguro.';

  @override
  String get welcomeSubtitle => 'Sin juicios, sin prisas; a tu propio ritmo.';

  @override
  String get welcomeFeaturePrivate =>
      'Un diario privado solo para ti. Solo tú puedes ver tus registros.';

  @override
  String get welcomeFeatureCommunity =>
      'Apoyo amable y amigos de racha de quienes recorren el mismo camino.';

  @override
  String get welcomeFeatureCalm =>
      'Respiración, anclaje y juegos breves para los momentos difíciles.';

  @override
  String get welcomeGoogle => 'Regístrate / inicia sesión con Google';

  @override
  String get welcomeGoogleNote =>
      'Google solo verifica tu identidad; tu contraseña nunca se comparte con Haven. Completaremos el resto del registro aquí, juntos.';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get stepProfile => 'Perfil';

  @override
  String get stepAreas => 'Tus áreas';

  @override
  String get stepCommunity => 'Comunidad';

  @override
  String get stepConsent => 'Consentimiento';

  @override
  String get continueButton => 'Continuar';

  @override
  String get backButton => 'Atrás';

  @override
  String get enterHaven => 'Entrar a Haven';

  @override
  String get profileTitle => '¿Cómo te llamamos?';

  @override
  String get profileSubtitle =>
      'No tienes que compartir quién eres. Podemos sugerirte un apodo tierno según tu avatar, o puedes escribir el tuyo.';

  @override
  String get anonymousOption => 'Quiero ser anónimo/a';

  @override
  String get anonymousOptionDesc => 'Te sugerimos un apodo según tu avatar';

  @override
  String get namedOption => 'Quiero usar mi nombre';

  @override
  String get namedOptionDesc => 'Puedes escribir tu nombre o iniciales';

  @override
  String get nicknameLabel => 'Apodo';

  @override
  String get nameLabel => 'Tu nombre';

  @override
  String get chooseAvatar => 'Elige un avatar';

  @override
  String get suggestAnother => 'Otra sugerencia';

  @override
  String get areasTitle => '¿Con qué estás lidiando?';

  @override
  String get areasSubtitle =>
      'Puedes elegir más de una. Esto es privado y puedes cambiarlo cuando quieras.';

  @override
  String get communityTitle => 'Conoce a quienes recorren el mismo camino';

  @override
  String get communitySubtitle =>
      'En la comunidad de Haven, personas con desafíos similares se dejan notas amables, ven sus rachas y se animan.';

  @override
  String get communityJoin => 'Quiero unirme a la comunidad';

  @override
  String get communityJoinDesc => 'Puedes cambiarlo cuando quieras en Perfil.';

  @override
  String get consentTitle => 'Un último paso';

  @override
  String get consentSubtitle => 'Queremos que sepas cómo funciona Haven.';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingDay => 'Hola';

  @override
  String get greetingEvening => 'Buenas tardes';

  @override
  String get greetingNight => 'Buenas noches';

  @override
  String get dailyStreak => 'días de racha';

  @override
  String bestStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Mejor: $_temp0';
  }

  @override
  String get streakDoneToday => 'Hoy ya te registraste; tu racha continúa.';

  @override
  String get streakNotDone =>
      'Regístrate hoy para mantener tu racha. Saltarte un día no la rompe.';

  @override
  String get quoteTitle => 'Frase del día';

  @override
  String get todayRecords => 'Registros de hoy';

  @override
  String get monthLights => 'Las luces de este mes';

  @override
  String get yourProgress => 'Tu progreso';

  @override
  String get myNotes => 'Mis notas';

  @override
  String get addNote => 'Añadir nota';

  @override
  String get noNotesYet => 'Aún no tienes notas. ¿Te dejas una nota amable?';

  @override
  String get kindDays => 'días amables';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get personalBest => 'Tu récord';

  @override
  String get last30Days => 'Últimos 30 días';

  @override
  String get imStruggling => 'Me cuesta ahora mismo';

  @override
  String get quickBreath => 'Respirar';

  @override
  String get quickGames => 'Juegos';

  @override
  String get quickCommunity => 'Comunidad';

  @override
  String get quickSupport => 'Pedir apoyo';

  @override
  String get wentWell => 'Fue bien';

  @override
  String get wasHard => 'Fue difícil';

  @override
  String get comebackTitle => 'Es solo un pequeño bache';

  @override
  String comebackBody(int past, int best) {
    return 'La última vez avanzaste muy bien durante $past días. Esos días siguen siendo tuyos. ¡Ahora competimos con tu propio récord ($best días)!';
  }

  @override
  String get raceTitle => 'Compites con tu propio récord';

  @override
  String raceBody(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'faltan $left días',
      one: 'falta 1 día',
    );
    return 'Te $_temp0 para tu récord. Sin prisa, a tu ritmo.';
  }

  @override
  String get newRecordTitle => '¡Nuevo récord!';

  @override
  String newRecordBody(int days) {
    return '¡$days días! Superaste tu propio récord. Siéntete orgulloso/a.';
  }

  @override
  String get calmTitle => 'Calma';

  @override
  String get calmIntro =>
      'Este es tu espacio seguro. Cuando llega un impulso o la ansiedad, unos minutos de pausa ayudan a que pase la ola.';

  @override
  String get emergencyTitle => 'Apoyo urgente';

  @override
  String get emergencyBody =>
      'Si no te sientes a salvo, llama ahora. Pedir ayuda requiere fuerza.';

  @override
  String get breathingTitle => 'Inhala · sostén · exhala';

  @override
  String get breathingDesc => 'Inhala 4, sostén 4, exhala 6';

  @override
  String get breatheIn => 'Inhala';

  @override
  String get hold => 'Sostén';

  @override
  String get breatheOut => 'Exhala despacio';

  @override
  String get gameBubbles => 'Explota burbujas';

  @override
  String get gameBubblesDesc => 'Una tarea segura para tus manos';

  @override
  String get gameColors => 'Empareja colores';

  @override
  String get gameColorsDesc => 'Empareja colores, descansa la mente';

  @override
  String get gameMemory => 'Cartas de memoria';

  @override
  String get gameMemoryDesc => 'Ocupa tu mente con suavidad';

  @override
  String get groundingTitle => 'Anclaje 5-4-3-2-1';

  @override
  String get groundingDesc => 'Vuelve al presente';

  @override
  String get supportTitle => 'Pedir apoyo';

  @override
  String get supportDesc => 'Líneas de crisis y ayuda profesional';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get noNotifications => 'Aún no hay notificaciones.';

  @override
  String get giftsTitle => 'Mis regalos';

  @override
  String get giftsIntro =>
      'Se desbloquean nuevos regalos a medida que vuelves a ti cada día. También puedes desbloquearlos con un anuncio corto; es totalmente opcional.';

  @override
  String giftUnlockAt(int days) {
    return 'Se desbloquea con una racha de $days días';
  }

  @override
  String giftDaysLeft(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Faltan $left días',
      one: 'Falta 1 día',
    );
    return '$_temp0';
  }

  @override
  String get themes => 'Temas';

  @override
  String get avatars => 'Avatares';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del dispositivo';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar mi cuenta y todos mis datos';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String recordLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Récord: $_temp0';
  }

  @override
  String get journeyStart => 'Tu camino puede empezar hoy.';

  @override
  String get recordReached =>
      '¡Alcanzaste tu récord! Mañana puede haber uno nuevo.';

  @override
  String comebackShort(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: '$best días',
      one: '1 día',
    );
    return 'Tu récord es de $_temp0. Un buen día para empezar de nuevo.';
  }

  @override
  String get seeAll => 'Todo';

  @override
  String get beginning => 'Comienzo';
}
