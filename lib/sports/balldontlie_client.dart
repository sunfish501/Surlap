import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/sports_config.dart';

/// BallDontLie API 저수준 GET 클라이언트.
/// 단일 호스트 + 종목별 path prefix. 인증은 Authorization 헤더(env 키).
class BallDontLieClient {
  const BallDontLieClient();

  /// [segment] = '' (NBA, /v1) | 'mlb' | 'nfl' | 'epl' ...
  /// 반환: 디코드된 JSON의 'data' 리스트(실패 시 빈 리스트).
  Future<List<dynamic>> getGames(
    String segment, {
    required Map<String, List<String>> query,
  }) async {
    if (!hasSportsApiKey) {
      debugPrint('[BallDontLie] API 키 없음 — env BALLDONTLIE_API_KEY 필요.');
      return const [];
    }
    final prefix = segment.isEmpty ? 'v1' : '$segment/v1';
    final uri = Uri.parse('$ballDontLieHost/$prefix/games')
        .replace(queryParameters: query);
    try {
      final res = await http.get(uri, headers: {
        'Authorization': ballDontLieApiKey,
        'Accept': 'application/json',
      });
      if (res.statusCode != 200) {
        debugPrint('[BallDontLie] ${res.statusCode} ${uri.path}: ${res.body}');
        return const [];
      }
      final body = jsonDecode(res.body);
      if (body is Map && body['data'] is List) return body['data'] as List;
      return const [];
    } catch (e) {
      debugPrint('[BallDontLie] 요청 실패: $e');
      return const [];
    }
  }
}
