import 'dart:convert';

/// 지원 종목 (배드민턴 제외).
enum SportKind {
  soccer, // ⚽ 축구
  basketball, // 🏀 농구(NBA)
  baseball, // ⚾ 야구(MLB)
  football, // 🏈 미식축구(NFL)
  hockey, // 🏒 하키(NHL)
  f1, // 🏎️ F1
  tennis, // 🎾 테니스
  ufc, // 🥊 UFC·MMA
  golf, // ⛳ 골프(PGA)
  esports, // 🎮 e스포츠(LoL)
}

extension SportKindX on SportKind {
  String get key => name;
  static SportKind fromKey(String k) => SportKind.values.firstWhere(
        (e) => e.name == k,
        orElse: () => SportKind.soccer,
      );
}

/// 리그/대회.
class SportLeague {
  final String id;
  final String name;
  const SportLeague(this.id, this.name);
}

/// 팀 또는 선수.
class SportTeam {
  final String id;
  final String name;
  /// 팀 로고 이미지 URL(선택). 없으면 종목 이모지로 대체 표시.
  final String? logo;
  const SportTeam(this.id, this.name, [this.logo]);
}

/// 종목 메타(이모지·라벨·리그·기본 색·지원여부).
class SportInfo {
  final SportKind kind;
  final String emoji;
  final String label;
  final List<SportLeague> leagues;

  /// 현재 데이터 소스(BallDontLie)로 경기 일정을 받아올 수 있는지.
  /// 미지원 종목은 구독만 되고 경기는 비어 있음(소스 교체용 일반화 지점).
  final bool gamesSupported;

  /// 팀 대신 선수/대회 단위인지(F1·테니스·UFC·골프·LoL 등).
  final bool entityIsPlayer;

  const SportInfo({
    required this.kind,
    required this.emoji,
    required this.label,
    required this.leagues,
    this.gamesSupported = false,
    this.entityIsPlayer = false,
  });
}

// ─── 구독 ──────────────────────────────────────────────────────────────
class SportSubscription {
  final String id; // 'sport:leagueId:teamId'
  final String sport; // SportKind.name
  final String leagueId;
  final String leagueName;
  final String teamId;
  final String teamName;
  final String emoji;
  final int color; // ARGB
  final bool enabled;
  final int reminderMinutes; // 시작 N분 전 알림 (0=끔)

  const SportSubscription({
    required this.id,
    required this.sport,
    required this.leagueId,
    required this.leagueName,
    required this.teamId,
    required this.teamName,
    required this.emoji,
    required this.color,
    this.enabled = true,
    this.reminderMinutes = 30,
  });

  SportKind get kind => SportKindX.fromKey(sport);

  SportSubscription copyWith({bool? enabled, int? reminderMinutes, int? color}) =>
      SportSubscription(
        id: id,
        sport: sport,
        leagueId: leagueId,
        leagueName: leagueName,
        teamId: teamId,
        teamName: teamName,
        emoji: emoji,
        color: color ?? this.color,
        enabled: enabled ?? this.enabled,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sport': sport,
        'leagueId': leagueId,
        'leagueName': leagueName,
        'teamId': teamId,
        'teamName': teamName,
        'emoji': emoji,
        'color': color,
        'enabled': enabled,
        'reminderMinutes': reminderMinutes,
      };

  factory SportSubscription.fromJson(Map<String, dynamic> j) =>
      SportSubscription(
        id: (j['id'] ?? '').toString(),
        sport: (j['sport'] ?? 'soccer').toString(),
        leagueId: (j['leagueId'] ?? '').toString(),
        leagueName: (j['leagueName'] ?? '').toString(),
        teamId: (j['teamId'] ?? '').toString(),
        teamName: (j['teamName'] ?? '').toString(),
        emoji: (j['emoji'] ?? '🏅').toString(),
        color: (j['color'] as num?)?.toInt() ?? 0xFF6C63FF,
        enabled: j['enabled'] != false,
        reminderMinutes: (j['reminderMinutes'] as num?)?.toInt() ?? 30,
      );

  static List<SportSubscription> listFromJson(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(SportSubscription.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<SportSubscription> s) =>
      jsonEncode(s.map((e) => e.toJson()).toList());
}

// ─── 경기 일정(공통 이벤트 형식) ────────────────────────────────────────
class SportsEvent {
  final String id;
  final String subscriptionId;
  final String title; // "토트넘 vs 아스널"
  final DateTime startAt; // UTC
  final String sport;
  final String? streamUrl;

  const SportsEvent({
    required this.id,
    required this.subscriptionId,
    required this.title,
    required this.startAt,
    required this.sport,
    this.streamUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'title': title,
        'startAt': startAt.toUtc().toIso8601String(),
        'sport': sport,
        if (streamUrl != null) 'streamUrl': streamUrl,
      };

  factory SportsEvent.fromJson(Map<String, dynamic> j) => SportsEvent(
        id: (j['id'] ?? '').toString(),
        subscriptionId: (j['subscriptionId'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        startAt:
            DateTime.tryParse((j['startAt'] ?? '').toString())?.toUtc() ??
                DateTime.now().toUtc(),
        sport: (j['sport'] ?? '').toString(),
        streamUrl: j['streamUrl'] as String?,
      );
}
