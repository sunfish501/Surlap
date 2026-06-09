import 'app_lang.dart';
import 'strings.dart';

/// 현재 언어 기준 날짜/요일 표기 헬퍼.
/// (intl 로케일 데이터 초기화 없이도 동작하도록 직접 테이블로 구성)

// DateTime.weekday: 1=월 .. 7=일
const Map<AppLang, List<String>> _weekdayFull = {
  AppLang.ko: ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
  AppLang.en: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  AppLang.ja: ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
  AppLang.zh: ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'],
  AppLang.es: ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'],
};

const Map<AppLang, List<String>> _weekdayShort = {
  AppLang.ko: ['월', '화', '수', '목', '금', '토', '일'],
  AppLang.en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  AppLang.ja: ['月', '火', '水', '木', '金', '土', '日'],
  AppLang.zh: ['一', '二', '三', '四', '五', '六', '日'],
  AppLang.es: ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'],
};

const List<String> _monthShortEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _monthShortEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// 요일 풀네임. (weekday: 1=월..7=일)
String weekdayFull(int weekday) => _weekdayFull[currentLang]![weekday - 1];

/// 요일 약자(달력 헤더용). (weekday: 1=월..7=일)
String weekdayShort(int weekday) => _weekdayShort[currentLang]![weekday - 1];

/// 0=일 시작 인덱스로 약자(월간 그리드 요일 헤더가 0=일 기준일 때).
String weekdayShortFromSun(int sunIndex) {
  // sunIndex 0=일,1=월,... → DateTime weekday(1=월..7=일)
  const map = [7, 1, 2, 3, 4, 5, 6];
  return weekdayShort(map[sunIndex % 7]);
}

/// "오늘" 헤더용 풀 날짜. ko/ja/zh는 'M월 d일 요일', en/es는 로케일형.
String fullDate(DateTime d) {
  switch (currentLang) {
    case AppLang.ko:
      return '${d.month}월 ${d.day}일 ${weekdayFull(d.weekday)}';
    case AppLang.ja:
      return '${d.month}月${d.day}日 ${weekdayFull(d.weekday)}';
    case AppLang.zh:
      return '${d.month}月${d.day}日 ${weekdayFull(d.weekday)}';
    case AppLang.en:
      return '${weekdayFull(d.weekday)}, ${_monthShortEn[d.month - 1]} ${d.day}';
    case AppLang.es:
      return '${weekdayFull(d.weekday)}, ${d.day} ${_monthShortEs[d.month - 1]}';
  }
}

/// 월 이름(상단 헤더용). ko='6월', ja/zh='6月', en='Jun', es='jun'.
String monthName(int month) {
  switch (currentLang) {
    case AppLang.ko:
      return '$month월';
    case AppLang.ja:
    case AppLang.zh:
      return '$month月';
    case AppLang.en:
      return _monthShortEn[month - 1];
    case AppLang.es:
      return _monthShortEs[month - 1];
  }
}

/// '년' 표기(연간 헤더). en/es는 빈 문자열(연도 숫자만).
String get yearWord {
  switch (currentLang) {
    case AppLang.ko:
      return '년';
    case AppLang.ja:
    case AppLang.zh:
      return '年';
    case AppLang.en:
    case AppLang.es:
      return '';
  }
}

/// 짧은 날짜 'M월 d일' 형태(일간 헤더 등).
String monthDay(DateTime d) {
  switch (currentLang) {
    case AppLang.ko:
      return '${d.month}월 ${d.day}일';
    case AppLang.ja:
    case AppLang.zh:
      return '${d.month}月${d.day}日';
    case AppLang.en:
      return '${_monthShortEn[d.month - 1]} ${d.day}';
    case AppLang.es:
      return '${d.day} ${_monthShortEs[d.month - 1]}';
  }
}
