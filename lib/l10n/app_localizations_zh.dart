// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Haven';

  @override
  String get navToday => '今天';

  @override
  String get navCommunity => '社区';

  @override
  String get navCalm => '平静';

  @override
  String get navProfile => '我的';

  @override
  String get welcomeTagline => '你的安全港湾。';

  @override
  String get welcomeSubtitle => '不评判，不着急，按你自己的节奏来。';

  @override
  String get welcomeFeaturePrivate => '只属于你的私密日记，只有你能看到自己的记录。';

  @override
  String get welcomeFeatureCommunity => '来自同路人的温柔支持和连续打卡伙伴。';

  @override
  String get welcomeFeatureCalm => '为艰难时刻准备的呼吸练习、接地练习和简短的舒缓小游戏。';

  @override
  String get welcomeGoogle => '使用 Google 注册 / 登录';

  @override
  String get welcomeGoogleNote =>
      'Google 只用于验证你的身份，你的密码绝不会与 Haven 共享。其余的注册步骤我们会在这里一起完成。';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get stepProfile => '资料';

  @override
  String get stepAreas => '你的方面';

  @override
  String get stepCommunity => '社区';

  @override
  String get stepConsent => '同意';

  @override
  String get continueButton => '继续';

  @override
  String get backButton => '返回';

  @override
  String get enterHaven => '进入 Haven';

  @override
  String get profileTitle => '我们该怎么称呼你？';

  @override
  String get profileSubtitle => '你不必透露自己的身份。我们可以根据你选择的头像推荐一个可爱的昵称，你也可以自己填写。';

  @override
  String get anonymousOption => '我想保持匿名';

  @override
  String get anonymousOptionDesc => '我们会根据你的头像推荐昵称';

  @override
  String get namedOption => '我想使用我的名字';

  @override
  String get namedOptionDesc => '你可以填写名字或缩写';

  @override
  String get nicknameLabel => '昵称';

  @override
  String get nameLabel => '你的名字';

  @override
  String get chooseAvatar => '选择一个头像';

  @override
  String get suggestAnother => '换一个推荐';

  @override
  String get areasTitle => '你正在面对什么？';

  @override
  String get areasSubtitle => '可以多选。这些信息只属于你，随时可以更改。';

  @override
  String get communityTitle => '认识同路人';

  @override
  String get communitySubtitle =>
      '在 Haven 社区里，面临相似挑战的人们互相留下温暖的留言、看到彼此的连续记录并互相鼓励。';

  @override
  String get communityJoin => '我想加入社区';

  @override
  String get communityJoinDesc => '你可以随时在「我的」中更改。';

  @override
  String get consentTitle => '最后一步';

  @override
  String get consentSubtitle => '我们希望你了解 Haven 是如何运作的。';

  @override
  String get greetingMorning => '早上好';

  @override
  String get greetingDay => '你好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingNight => '晚安';

  @override
  String get dailyStreak => '天连续';

  @override
  String bestStreak(int days) {
    return '最佳：$days 天';
  }

  @override
  String get streakDoneToday => '今天已记录，你的连续记录仍在继续。';

  @override
  String get streakNotDone => '今天记录一下，让连续记录继续。错过一天不会中断。';

  @override
  String get quoteTitle => '今日一句';

  @override
  String get todayRecords => '今天的记录';

  @override
  String get monthLights => '本月之光';

  @override
  String get yourProgress => '你的进展';

  @override
  String get myNotes => '我的笔记';

  @override
  String get addNote => '添加笔记';

  @override
  String get noNotesYet => '还没有笔记。给自己留一句温柔的话吧？';

  @override
  String get kindDays => '温柔的日子';

  @override
  String get currentStreak => '当前连续';

  @override
  String get personalBest => '你的纪录';

  @override
  String get last30Days => '最近 30 天';

  @override
  String get imStruggling => '我现在很难受';

  @override
  String get quickBreath => '呼吸';

  @override
  String get quickGames => '游戏';

  @override
  String get quickCommunity => '社区';

  @override
  String get quickSupport => '寻求支持';

  @override
  String get wentWell => '还不错';

  @override
  String get wasHard => '很艰难';

  @override
  String get comebackTitle => '这只是一个小坎';

  @override
  String comebackBody(int past, int best) {
    return '上一次你坚持了 $past 天，进步得很好。那些日子依然属于你。现在我们来挑战你自己的纪录（$best 天）！';
  }

  @override
  String get raceTitle => '你在挑战自己的纪录';

  @override
  String raceBody(int left) {
    return '距离你的纪录还有 $left 天。不着急，按自己的节奏来。';
  }

  @override
  String get newRecordTitle => '新纪录！';

  @override
  String newRecordBody(int days) {
    return '$days 天！你超越了自己的纪录，为自己感到骄傲吧。';
  }

  @override
  String get calmTitle => '平静';

  @override
  String get calmIntro => '这里是你的安全空间。当冲动或焦虑来临时，几分钟的停顿能帮助浪潮过去。';

  @override
  String get emergencyTitle => '紧急支持';

  @override
  String get emergencyBody => '如果你感觉不安全，请立即拨打电话。寻求帮助需要勇气。';

  @override
  String get breathingTitle => '吸气 · 屏息 · 呼气';

  @override
  String get breathingDesc => '吸气 4 秒，屏息 4 秒，呼气 6 秒';

  @override
  String get breatheIn => '吸气';

  @override
  String get hold => '屏息';

  @override
  String get breatheOut => '慢慢呼气';

  @override
  String get gameBubbles => '戳泡泡';

  @override
  String get gameBubblesDesc => '给双手一个安全的事情做';

  @override
  String get gameColors => '颜色配对';

  @override
  String get gameColorsDesc => '配对颜色，让大脑休息';

  @override
  String get gameMemory => '记忆卡片';

  @override
  String get gameMemoryDesc => '温和地占据你的注意力';

  @override
  String get groundingTitle => '5-4-3-2-1 接地练习';

  @override
  String get groundingDesc => '回到当下';

  @override
  String get supportTitle => '寻求支持';

  @override
  String get supportDesc => '危机热线和专业帮助';

  @override
  String get notificationsTitle => '通知';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get noNotifications => '还没有通知。';

  @override
  String get giftsTitle => '我的礼物';

  @override
  String get giftsIntro => '每天回到自己身边，就会解锁新的礼物。你也可以通过观看一段简短的广告解锁，完全自愿。';

  @override
  String giftUnlockAt(int days) {
    return '连续 $days 天后解锁';
  }

  @override
  String giftDaysLeft(int left) {
    return '还剩 $left 天';
  }

  @override
  String get themes => '主题';

  @override
  String get avatars => '头像';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '设备语言';

  @override
  String get signOut => '退出登录';

  @override
  String get deleteAccount => '删除我的账户和所有数据';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String daysCount(int count) {
    return '$count 天';
  }

  @override
  String recordLabel(int count) {
    return '纪录：$count 天';
  }

  @override
  String get journeyStart => '你的旅程可以从今天开始。';

  @override
  String get recordReached => '你已追平纪录！明天可能就是新纪录。';

  @override
  String comebackShort(int best) {
    return '你的纪录是 $best 天。今天是重新开始的好日子。';
  }

  @override
  String get seeAll => '全部';

  @override
  String get beginning => '起点';
}
