import '../providers/birthdays_provider.dart';

// VCF 텍스트에서 생일 파싱
List<Birthday> parseVcf(String content) {
  final result = <Birthday>[];
  String? name;
  int? month;
  int? day;

  void flush() {
    if (name != null && month != null && day != null) {
      result.add(Birthday.create(name: name!, month: month!, day: day!));
    }
    name = null;
    month = null;
    day = null;
  }

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line.toUpperCase() == 'END:VCARD') {
      flush();
      continue;
    }

    final colonIdx = line.indexOf(':');
    if (colonIdx < 0) continue;
    final key = line.substring(0, colonIdx).toUpperCase().trim();
    final value = line.substring(colonIdx + 1).trim();

    // FN 또는 N 필드에서 이름 추출
    if (key == 'FN') {
      name = value.isNotEmpty ? value : name;
    } else if (key == 'N' && name == null) {
      // N:성;이름;... → 이름 조합
      final parts = value.split(';');
      final lastName = parts.isNotEmpty ? parts[0].trim() : '';
      final firstName = parts.length > 1 ? parts[1].trim() : '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        name = '$lastName$firstName'.trim();
      }
    }

    // BDAY 파싱: YYYYMMDD 또는 YYYY-MM-DD 또는 --MMDD
    if (key == 'BDAY' || key.startsWith('BDAY;')) {
      final bday = value.replaceAll('-', '');
      if (bday.length == 8) {
        // YYYYMMDD
        month = int.tryParse(bday.substring(4, 6));
        day = int.tryParse(bday.substring(6, 8));
      } else if (bday.length == 4) {
        // MMDD (no year)
        month = int.tryParse(bday.substring(0, 2));
        day = int.tryParse(bday.substring(2, 4));
      }
    }
  }
  flush();

  return result;
}
