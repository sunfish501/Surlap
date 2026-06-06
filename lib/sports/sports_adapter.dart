import 'package:flutter/foundation.dart';
import '../models/sports.dart';
import 'balldontlie_client.dart';

/// 종목별 어댑터 인터페이스 — 응답을 공통 SportsEvent로 변환.
/// 나중에 종목 단위로 다른 API(국내리그 등)로 갈아끼울 수 있게 일반화한 계층.
abstract class SportsAdapter {
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  });
}

/// 종목 → 어댑터 매핑(레지스트리). 종목별로 교체 가능.
SportsAdapter adapterForSport(SportKind kind) {
  switch (kind) {
    case SportKind.basketball:
      return const BallDontLieAdapter(segment: '');
    case SportKind.baseball:
      return const BallDontLieAdapter(segment: 'mlb');
    case SportKind.football:
      return const BallDontLieAdapter(segment: 'nfl');
    case SportKind.soccer:
      return const BallDontLieAdapter(segment: 'epl');
    // 아래 종목은 BallDontLie 미커버 — 소스 추가 시 어댑터만 교체.
    case SportKind.hockey:
    case SportKind.f1:
    case SportKind.tennis:
    case SportKind.ufc:
    case SportKind.golf:
    case SportKind.esports:
      return const _UnsupportedAdapter();
  }
}

String _dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// BallDontLie 공통 어댑터 — NBA(v1)/MLB/NFL/EPL의 /games 응답을 변환.
class BallDontLieAdapter implements SportsAdapter {
  final String segment; // '' | 'mlb' | 'nfl' | 'epl'
  const BallDontLieAdapter({required this.segment});

  @override
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  }) async {
    const client = BallDontLieClient();
    final query = <String, List<String>>{
      'start_date': [_dk(from)],
      'end_date': [_dk(to)],
      'per_page': ['100'],
    };
    // 팀 id가 숫자(NBA 등)면 team_ids 필터 적용. 슬러그면 클라이언트 측에서 이름 필터.
    final numericTeam = int.tryParse(sub.teamId);
    if (numericTeam != null) {
      query['team_ids[]'] = [sub.teamId];
    }

    final raw = await client.getGames(segment, query: query);
    final out = <SportsEvent>[];
    for (final g in raw) {
      if (g is! Map) continue;
      final home = _teamName(g['home_team']);
      final away = _teamName(g['visitor_team'] ?? g['away_team']);
      if (home == null || away == null) continue;

      // 슬러그 구독이면 이름으로 우리 팀 포함 경기만 추림.
      if (numericTeam == null && !_matchesSlug(sub, home, away)) continue;

      final start = _parseStart(g);
      if (start == null) continue;
      final title = '$home vs $away';
      out.add(SportsEvent(
        id: '${sub.id}:${g['id'] ?? title}',
        subscriptionId: sub.id,
        title: title,
        startAt: start.toUtc(),
        sport: sub.sport,
      ));
    }
    debugPrint('[BallDontLie] ${sub.teamName} 경기 ${out.length}건');
    return out;
  }

  String? _teamName(dynamic t) {
    if (t is Map) {
      return (t['full_name'] ?? t['name'] ?? t['display_name'])?.toString();
    }
    return null;
  }

  bool _matchesSlug(SportSubscription sub, String home, String away) {
    final n = sub.teamName.toLowerCase();
    final h = home.toLowerCase();
    final a = away.toLowerCase();
    // 한글 팀명은 영문 응답과 직접 매칭 어려움 → 슬러그 일부로 느슨 매칭.
    final slug = sub.teamId.toLowerCase();
    return h.contains(slug) ||
        a.contains(slug) ||
        h.contains(n) ||
        a.contains(n);
  }

  DateTime? _parseStart(Map g) {
    // datetime(시간 포함) 우선, 없으면 date(자정).
    final iso = (g['datetime'] ?? g['date'] ?? g['game_time'])?.toString();
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}

/// 미지원 종목 — 빈 결과(구독은 가능, 경기는 없음).
class _UnsupportedAdapter implements SportsAdapter {
  const _UnsupportedAdapter();
  @override
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  }) async {
    debugPrint('[Sports] ${sub.sport} 미지원 소스 — 경기 없음.');
    return const [];
  }
}
