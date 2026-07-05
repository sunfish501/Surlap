import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surlap/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 클라우드(user_data)/백업에서 받은 값은 웹 형식이라 bool/int도 문자열로
  // 저장된다. 타입 게터가 이를 관대하게 읽어야 settings_provider의 getBool 이
  // "type 'String' is not a subtype of type 'bool?'" 로 크래시하지 않는다.
  test('getBool/getInt tolerate string-encoded values', () async {
    SharedPreferences.setMockInitialValues({
      'b_true_str': 'true',
      'b_false_str': 'false',
      'b_real': true,
      'b_one': '1',
      'i_str': '5',
      'i_real': 7,
    });
    await LocalStore.init();
    final s = LocalStore.instance;

    // 문자열로 저장된 bool 도 크래시 없이 변환
    expect(s.getBool('b_true_str'), isTrue);
    expect(s.getBool('b_false_str'), isFalse);
    expect(s.getBool('b_one'), isTrue);
    // 실제 bool 도 그대로
    expect(s.getBool('b_real'), isTrue);
    // 없는 키는 null
    expect(s.getBool('missing'), isNull);

    // int 도 문자열/실제값 모두 처리
    expect(s.getInt('i_str'), 5);
    expect(s.getInt('i_real'), 7);

    // getString 은 어떤 타입이든 문자열로 (push 시 bool→"true")
    expect(s.getString('b_real'), 'true');
    expect(s.getString('b_true_str'), 'true');
  });
}
