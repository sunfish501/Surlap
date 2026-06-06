// BallDontLie API 설정.
// 빌드 시 --dart-define=BALLDONTLIE_API_KEY=xxx 로 주입(env 관리). 기본값 비움.
//   flutter run --dart-define=BALLDONTLIE_API_KEY=your_key
const String ballDontLieApiKey = String.fromEnvironment('BALLDONTLIE_API_KEY');

/// 종목별 BallDontLie base path. 단일 호스트, 종목별 prefix.
/// 어댑터에서 이 base 위에 /games 등을 붙인다.
const String ballDontLieHost = 'https://api.balldontlie.io';

bool get hasSportsApiKey => ballDontLieApiKey.isNotEmpty;
