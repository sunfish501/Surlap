// 스포츠 데이터 소스 API 설정.
// 키는 빌드 시 --dart-define-from-file=.dart_define 로 주입(env 관리).
//   flutter run --dart-define-from-file=.dart_define

// ── BallDontLie (🏀 NBA) ──
const String ballDontLieApiKey = String.fromEnvironment('BALLDONTLIE_API_KEY');
const String ballDontLieHost = 'https://api.balldontlie.io';
bool get hasSportsApiKey => ballDontLieApiKey.isNotEmpty;

// ── football-data.org (⚽ 축구: EPL 등) ──
const String footballDataApiKey =
    String.fromEnvironment('FOOTBALL_DATA_API_KEY');
const String footballDataHost = 'https://api.football-data.org/v4';
bool get hasFootballDataKey => footballDataApiKey.isNotEmpty;

// ── PandaScore (🎮 e스포츠: LoL) ──
const String pandascoreApiKey =
    String.fromEnvironment('PANDASCORE_API_KEY');
const String pandascoreHost = 'https://api.pandascore.co';
bool get hasPandascoreKey => pandascoreApiKey.isNotEmpty;

// ── Jolpica (🏎️ F1) — 무인증, 키 불필요 ──
const String jolpicaHost = 'https://api.jolpi.ca/ergast/f1';
