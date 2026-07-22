import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/modals/theme_manager_modal.dart';
import 'package:surlap/models/calendar_theme.dart';

void main() {
  test('new shared schedules rotate through distinct palette colors', () {
    final first = nextSharedThemeColorHex(const []);
    final second = nextSharedThemeColorHex([
      CalendarTheme(id: 'one', name: '첫 일정', color: first),
    ]);
    final third = nextSharedThemeColorHex([
      CalendarTheme(id: 'one', name: '첫 일정', color: first),
      CalendarTheme(id: 'two', name: '둘째 일정', color: second),
    ]);

    expect(first, isNot('#5b9bd5'));
    expect({first, second, third}.length, 3);
  });
}
