import 'package:flutter/material.dart';

import '../../l10n/tx.dart';
import 'app_constants.dart';

/// Ülkeye göre acil durum ve ruh sağlığı destek hatları.
///
/// UYARI: Yayından önce her numarayı resmi kaynağından yeniden doğrula.
/// Kaynaklar (2025): TR 112 / Yeşilay 115 · US 911 / 988 Lifeline ·
/// GB 999 / Samaritans 116 123 · ES 112 / 024 · MX 911 / Línea de la Vida ·
/// IN 112 / Tele-MANAS 14416 · CN 120 / 12356 ulusal psikolojik destek hattı ·
/// DE 112 / TelefonSeelsorge · FR 112 / 3114. Listede olmayan ülkeler için
/// findahelpline.com (dünya genelinde ücretsiz, gizli hatlar rehberi).
class CountrySupport {
  const CountrySupport(this.code, String name, this.emergency, this.lines, {this.isTurkey = false}) : nameTr = name;

  /// ISO ülke kodu ('XX' = diğer ülkeler).
  final String code;
  final String nameTr;
  final String emergency;
  final List<SupportLine> lines;
  final bool isTurkey;

  String get name => tx(nameTr);

  /// Acil numara + ülkenin destek hatları.
  List<SupportLine> get allLines => [
    SupportLine(
      name: 'Acil Çağrı Merkezi',
      number: emergency,
      description: 'Kendini güvende hissetmiyorsan. 7/24, ücretsiz.',
    ),
    ...lines,
  ];
}

const kFindAHelplineUrl = 'https://findahelpline.com';

const kCountrySupport = <CountrySupport>[
  CountrySupport('TR', 'Türkiye', '112', [
    SupportLine(
      name: 'Yeşilay Danışma Hattı (YEDAM)',
      number: '115',
      description: 'Sigara, alkol, madde, kumar ve teknoloji bağımlılığı için ücretsiz ve gizli destek.',
    ),
  ], isTurkey: true),
  CountrySupport('US', 'Amerika Birleşik Devletleri', '911', [
    SupportLine(
      name: '988 İntihar ve Kriz Hattı',
      number: '988',
      description: 'Arayabilir ya da mesaj atabilirsin. 7/24, ücretsiz ve gizli.',
    ),
  ]),
  CountrySupport('GB', 'Birleşik Krallık', '999', [
    SupportLine(
      name: 'Samaritans',
      number: '116123',
      description: 'Ne hissedersen hisset konuşabileceğin biri. 7/24, ücretsiz.',
    ),
  ]),
  CountrySupport('ES', 'İspanya', '112', [
    SupportLine(
      name: '024 Destek Hattı',
      number: '024',
      description: 'İntihar düşünceleri için destek hattı. 7/24, ücretsiz ve gizli.',
    ),
  ]),
  CountrySupport('MX', 'Meksika', '911', [
    SupportLine(
      name: 'Línea de la Vida',
      number: '8009112000',
      description: 'Ruh sağlığı ve bağımlılık için ücretsiz destek, 7/24.',
    ),
  ]),
  CountrySupport('IN', 'Hindistan', '112', [
    SupportLine(name: 'Tele-MANAS', number: '14416', description: 'Devletin ücretsiz ruh sağlığı destek hattı, 7/24.'),
  ]),
  CountrySupport('CN', 'Çin', '120', [
    SupportLine(name: '12356 Psikolojik Destek Hattı', number: '12356', description: 'Ulusal psikolojik destek hattı.'),
  ]),
  CountrySupport('DE', 'Almanya', '112', [
    SupportLine(name: 'TelefonSeelsorge', number: '08001110111', description: 'Ücretsiz ve gizli destek, 7/24.'),
  ]),
  CountrySupport('FR', 'Fransa', '112', [
    SupportLine(
      name: '3114 Ulusal Önleme Hattı',
      number: '3114',
      description: 'İntihar önleme hattı. Ücretsiz ve gizli, 7/24.',
    ),
  ]),
  CountrySupport('XX', 'Diğer ülkeler', '112', []),
];

CountrySupport countrySupportFor(String? code) =>
    kCountrySupport.firstWhere((c) => c.code == code, orElse: () => kCountrySupport.last);

/// Ülke bilinmiyorsa uygulama dilinden tahmin (en → diğer ülkeler: 112 + rehber).
String guessCountry(String? deviceCountry, String language) {
  if (deviceCountry != null && kCountrySupport.any((c) => c.code == deviceCountry)) return deviceCountry;
  return switch (language) {
    'tr' => 'TR',
    'zh' => 'CN',
    'hi' => 'IN',
    'es' => 'ES',
    _ => 'XX',
  };
}

/// Türkiye dışındaki kullanıcılar için genel profesyonel destek yolları.
const kHelpResourcesGlobal = <HelpResource>[
  HelpResource(
    Icons.local_hospital_outlined,
    'Aile hekimin ya da pratisyen hekimin',
    'Seni bir ruh sağlığı uzmanına yönlendirebilir.',
  ),
  HelpResource(
    Icons.school_outlined,
    'Üniversiten',
    'Öğrenciysen üniversitenin psikolojik danışmanlık merkezinden ücretsiz destek alabilirsin.',
  ),
  HelpResource(
    Icons.public_rounded,
    'Dünya genelinde yardım hatları',
    'findahelpline.com üzerinden ülkendeki ücretsiz ve gizli destek hatlarını bulabilirsin.',
  ),
];
