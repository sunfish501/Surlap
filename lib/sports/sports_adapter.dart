import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/sports_config.dart';
import '../models/sports.dart';
import 'balldontlie_client.dart';

/// 종목별 어댑터 인터페이스 — 응답을 공통 SportsEvent로 변환.
/// 나중에 종목 단위로 다른 API로 갈아끼울 수 있게 일반화한 계층.
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
      return const BallDontLieAdapter(segment: ''); // NBA
    case SportKind.soccer:
      return const FootballDataAdapter(); // EPL 등
    case SportKind.f1:
      return const JolpicaAdapter(); // 무인증
    case SportKind.esports:
      return const PandaScoreAdapter(); // LoL
    // 무료 소스 없음 — 구독은 되지만 경기는 비어 있음.
    case SportKind.baseball:
    case SportKind.football:
    case SportKind.hockey:
    case SportKind.tennis:
    case SportKind.ufc:
    case SportKind.golf:
      return const _UnsupportedAdapter();
  }
}

String _dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ════════════════════════════════════════════════════════════════════════
// 🏀 BallDontLie 어댑터 — NBA(v1)의 /games 응답을 변환.
// ════════════════════════════════════════════════════════════════════════
class BallDontLieAdapter implements SportsAdapter {
  final String segment; // '' = NBA
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
      final start = _parseStart(g);
      if (start == null) continue;
      out.add(SportsEvent(
        id: '${sub.id}:${g['id'] ?? '$home vs $away'}',
        subscriptionId: sub.id,
        title: '$home vs $away',
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

  DateTime? _parseStart(Map g) {
    final iso = (g['datetime'] ?? g['date'] ?? g['game_time'])?.toString();
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}

// ════════════════════════════════════════════════════════════════════════
// ⚽ football-data.org 어댑터 — /teams/{id}/matches.
// ════════════════════════════════════════════════════════════════════════
class FootballDataAdapter implements SportsAdapter {
  const FootballDataAdapter();

  /// EPL 팀 슬러그 → football-data.org 팀 ID.
  static const Map<String, int> _teamIds = {
    'tottenham': 73,
    'arsenal': 57,
    'mancity': 65,
    'manutd': 66,
    'liverpool': 64,
    'chelsea': 61,
    'newcastle': 67,
  };

  @override
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  }) async {
    if (!hasFootballDataKey) {
      debugPrint('[FootballData] API 키 없음 — FOOTBALL_DATA_API_KEY 필요.');
      return const [];
    }
    final teamId = _teamIds[sub.teamId];
    if (teamId == null) {
      debugPrint('[FootballData] ${sub.teamName}(${sub.teamId}) 팀 id 매핑 없음.');
      return const [];
    }
    final uri = Uri.parse('$footballDataHost/teams/$teamId/matches').replace(
      queryParameters: {'dateFrom': _dk(from), 'dateTo': _dk(to)},
    );
    try {
      final res =
          await http.get(uri, headers: {'X-Auth-Token': footballDataApiKey});
      if (res.statusCode != 200) {
        debugPrint('[FootballData] ${res.statusCode}: ${res.body}');
        return const [];
      }
      final body = jsonDecode(res.body);
      final matches = (body is Map && body['matches'] is List)
          ? body['matches'] as List
          : const [];
      final out = <SportsEvent>[];
      for (final m in matches) {
        if (m is! Map) continue;
        final home = _name(m['homeTeam']);
        final away = _name(m['awayTeam']);
        final iso = m['utcDate']?.toString();
        if (home == null || away == null || iso == null) continue;
        final start = DateTime.tryParse(iso);
        if (start == null) continue;
        out.add(SportsEvent(
          id: '${sub.id}:${m['id'] ?? iso}',
          subscriptionId: sub.id,
          title: '$home vs $away',
          startAt: start.toUtc(),
          sport: sub.sport,
        ));
      }
      debugPrint('[FootballData] ${sub.teamName} 경기 ${out.length}건');
      return out;
    } catch (e) {
      debugPrint('[FootballData] 요청 실패: $e');
      return const [];
    }
  }

  String? _name(dynamic t) {
    if (t is Map) return (t['shortName'] ?? t['name'] ?? t['tla'])?.toString();
    return null;
  }
}

// ════════════════════════════════════════════════════════════════════════
// 🏎️ Jolpica(Ergast) 어댑터 — 현재 시즌 F1 일정. 무인증.
// ════════════════════════════════════════════════════════════════════════
class JolpicaAdapter implements SportsAdapter {
  const JolpicaAdapter();

  @override
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$jolpicaHost/current/races.json');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) {
        debugPrint('[Jolpica] ${res.statusCode}: ${res.body}');
        return const [];
      }
      final body = jsonDecode(res.body);
      // 중첩 추출(널 안전) — 삼항 안에서 ?[] 쓰면 파서가 리스트로 오해함.
      dynamic races;
      if (body is Map) {
        final mrData = body['MRData'];
        final raceTable = mrData is Map ? mrData['RaceTable'] : null;
        races = raceTable is Map ? raceTable['Races'] : null;
      }
      if (races is! List) return const [];
      final out = <SportsEvent>[];
      for (final r in races) {
        if (r is! Map) continue;
        final date = r['date']?.toString();
        if (date == null || date.isEmpty) continue;
        final time = r['time']?.toString(); // "13:00:00Z" (있을 수도)
        final iso = (time != null && time.isNotEmpty)
            ? '${date}T$time'
            : '${date}T00:00:00Z';
        final start = DateTime.tryParse(iso);
        if (start == null) continue;
        if (start.isBefore(from) || start.isAfter(to)) continue;
        final name = (r['raceName'] ?? 'F1 그랑프리').toString();
        out.add(SportsEvent(
          id: '${sub.id}:${r['season'] ?? ''}-${r['round'] ?? name}',
          subscriptionId: sub.id,
          title: name,
          startAt: start.toUtc(),
          sport: sub.sport,
        ));
      }
      debugPrint('[Jolpica] F1 경기 ${out.length}건');
      return out;
    } catch (e) {
      debugPrint('[Jolpica] 요청 실패: $e');
      return const [];
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// 🎮 PandaScore 어댑터 — LoL 다가오는 경기, 팀으로 필터.
// ════════════════════════════════════════════════════════════════════════
class PandaScoreAdapter implements SportsAdapter {
  const PandaScoreAdapter();

  /// 팀 슬러그 → 매칭용 키워드(소문자).
  static const Map<String, List<String>> _match = {
    't1': ['t1'],
    'geng': ['gen.g', 'geng', 'gen g'],
  };

  @override
  Future<List<SportsEvent>> fetchGames({
    required SportSubscription sub,
    required DateTime from,
    required DateTime to,
  }) async {
    if (!hasPandascoreKey) {
      debugPrint('[PandaScore] API 키 없음 — PANDASCORE_API_KEY 필요.');
      return const [];
    }
    final uri = Uri.parse('$pandascoreHost/lol/matches/upcoming').replace(
      queryParameters: {'sort': 'begin_at', 'per_page': '100'},
    );
    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $pandascoreApiKey',
        'Accept': 'application/json',
      });
      if (res.statusCode != 200) {
        debugPrint('[PandaScore] ${res.statusCode}: ${res.body}');
        return const [];
      }
      final body = jsonDecode(res.body);
      if (body is! List) return const [];
      final wantAll = sub.teamId == 'lol-all';
      final needles = _match[sub.teamId] ?? [sub.teamName.toLowerCase()];
      final out = <SportsEvent>[];
      for (final m in body) {
        if (m is! Map) continue;
        final iso = (m['begin_at'] ?? m['scheduled_at'])?.toString();
        if (iso == null || iso.isEmpty) continue;
        final start = DateTime.tryParse(iso);
        if (start == null) continue;
        if (start.isBefore(from) || start.isAfter(to)) continue;

        final names = <String>[];
        final opps = m['opponents'];
        if (opps is List) {
          for (final o in opps) {
            final op = (o is Map) ? o['opponent'] : null;
            final nm =
                (op is Map) ? (op['name'] ?? op['acronym'])?.toString() : null;
            if (nm != null) names.add(nm);
          }
        }
        if (!wantAll) {
          final hay = names.join(' ').toLowerCase();
          if (!needles.any(hay.contains)) continue;
        }
        final title = names.length >= 2
            ? '${names[0]} vs ${names[1]}'
            : (m['name'] ?? 'LoL 경기').toString();
        out.add(SportsEvent(
          id: '${sub.id}:${m['id'] ?? iso}',
          subscriptionId: sub.id,
          title: title,
          startAt: start.toUtc(),
          sport: sub.sport,
        ));
      }
      debugPrint('[PandaScore] ${sub.teamName} 경기 ${out.length}건');
      return out;
    } catch (e) {
      debugPrint('[PandaScore] 요청 실패: $e');
      return const [];
    }
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
