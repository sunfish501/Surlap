import '../models/sports.dart';

/// 지원 종목 카탈로그. 리그/팀 선택 UI의 데이터 소스.
/// 무료 소스로 실제 경기 일정을 받아오는 종목만 남김:
///   축구(football-data.org · EPL) / 농구(BallDontLie · NBA) /
///   F1(Jolpica) / e스포츠(PandaScore · LoL).
const List<SportInfo> kSports = [
  SportInfo(
    kind: SportKind.soccer,
    emoji: '⚽',
    label: '축구',
    gamesSupported: true, // football-data.org 무료(EPL)
    leagues: [
      SportLeague('epl', 'EPL (프리미어리그)'),
    ],
  ),
  SportInfo(
    kind: SportKind.basketball,
    emoji: '🏀',
    label: '농구',
    gamesSupported: true, // BallDontLie 무료(NBA)
    leagues: [SportLeague('nba', 'NBA')],
  ),
  SportInfo(
    kind: SportKind.f1,
    emoji: '🏎️',
    label: 'F1',
    gamesSupported: true, // Jolpica(무인증)
    entityIsPlayer: true,
    leagues: [SportLeague('f1', 'Formula 1')],
  ),
  SportInfo(
    kind: SportKind.esports,
    emoji: '🎮',
    label: 'e스포츠',
    gamesSupported: true, // PandaScore 무료(LoL)
    entityIsPlayer: true,
    leagues: [SportLeague('lol', 'LoL')],
  ),
];

SportInfo sportInfo(SportKind kind) =>
    kSports.firstWhere((s) => s.kind == kind);

/// 리그별 팀/선수 목록. NBA 팀 id는 BallDontLie 실제 id.
/// 그 외는 슬러그 id(어댑터가 팀 id 매핑/이름 매칭에 사용).
const Map<String, List<SportTeam>> _teams = {
  // ── 축구 (EPL) ──
  // 로고: ESPN CDN(축구 팀 id별 500px PNG). 기존 crests.football-data.org는
  // 호스트가 불통이라 빈 원으로 멈춰 ESPN으로 교체. (경기 데이터 매핑은
  // sports_adapter의 football-data id가 따로 담당 — 로고 URL만 바뀜)
  'epl': [
    SportTeam('tottenham', '토트넘', 'https://a.espncdn.com/i/teamlogos/soccer/500/367.png'),
    SportTeam('arsenal', '아스널', 'https://a.espncdn.com/i/teamlogos/soccer/500/359.png'),
    SportTeam('mancity', '맨체스터 시티', 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png'),
    SportTeam('manutd', '맨체스터 유나이티드', 'https://a.espncdn.com/i/teamlogos/soccer/500/360.png'),
    SportTeam('liverpool', '리버풀', 'https://a.espncdn.com/i/teamlogos/soccer/500/364.png'),
    SportTeam('chelsea', '첼시', 'https://a.espncdn.com/i/teamlogos/soccer/500/363.png'),
    SportTeam('newcastle', '뉴캐슬', 'https://a.espncdn.com/i/teamlogos/soccer/500/361.png'),
  ],
  // ── NBA (실제 BallDontLie team id) ──
  // 로고: ESPN CDN(팀 약자별 500px PNG).
  'nba': [
    SportTeam('2', '보스턴 셀틱스', 'https://a.espncdn.com/i/teamlogos/nba/500/bos.png'),
    SportTeam('14', 'LA 레이커스', 'https://a.espncdn.com/i/teamlogos/nba/500/lal.png'),
    SportTeam('10', '골든스테이트 워리어스', 'https://a.espncdn.com/i/teamlogos/nba/500/gs.png'),
    SportTeam('17', '밀워키 벅스', 'https://a.espncdn.com/i/teamlogos/nba/500/mil.png'),
    SportTeam('8', '덴버 너기츠', 'https://a.espncdn.com/i/teamlogos/nba/500/den.png'),
    SportTeam('20', '뉴욕 닉스', 'https://a.espncdn.com/i/teamlogos/nba/500/ny.png'),
    SportTeam('9', '디트로이트 피스턴스', 'https://a.espncdn.com/i/teamlogos/nba/500/det.png'),
  ],
  // ── F1 (Jolpica — 전체 그랑프리 일정) ──
  'f1': [SportTeam('f1-all', 'F1 그랑프리 전체')],
  // ── e스포츠 LoL (PandaScore) ──
  'lol': [
    SportTeam('t1', 'T1'),
    SportTeam('geng', 'Gen.G'),
    SportTeam('lol-all', 'LCK 전체'),
  ],
};

List<SportTeam> teamsForLeague(String leagueId) => _teams[leagueId] ?? const [];

/// 구독(리그id+팀id)으로 카탈로그에서 팀 로고 URL을 찾는다. 없으면 null.
String? teamLogoUrl(String leagueId, String teamId) {
  for (final t in teamsForLeague(leagueId)) {
    if (t.id == teamId) return t.logo;
  }
  return null;
}

/// 구독 색 팔레트 — 테마 색과 구분되는 선명한 톤.
const List<int> kSportColors = [
  0xFF4F8DFD, // blue
  0xFFE25563, // red
  0xFF35B97A, // green
  0xFFF2A33C, // amber
  0xFF9B6CF0, // purple
  0xFF14B8C4, // teal
  0xFFEC6AA8, // pink
  0xFFF06543, // coral
];

/// id 기반 결정적 색 선택(구독마다 안정적으로 다른 색).
int pickSportColor(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kSportColors[h % kSportColors.length];
}
