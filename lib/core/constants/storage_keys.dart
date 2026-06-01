// 웹 localStorage 키와 완전히 동일하게 유지 — 절대 변경 금지.
abstract final class StorageKeys {
  static const events        = 'handwriting-calendar-events-v1';
  static const eventsMirror  = 'calendar-events-v1';
  static const themes        = 'calendar-themes-v1';
  static const colorPreset   = 'calendar-color-preset-v1';
  static const motto         = 'calendar-motto-v1';
  static const mottoIcon     = 'calendar-motto-icon-v1';
  static const starred       = 'calendar-starred-dates-v1';
  static const memos         = 'calendar-memos-v1';
  static const circles       = 'calendar-circles-v1';
  static const continuousView = 'calendar-continuous-view-v1';
  static const weekStart     = 'calendar-week-start-v1';
  static const notifyEnabled = 'calendar-notify-enabled-v1';
  static const themeFilter   = 'calendar-theme-filter-v1';
  static const dayTemplates  = 'calendar-day-templates-v1';
  static const dayWidgetValues = 'calendar-day-widget-values-v1';
  static const timetableTemplate  = 'calendar-timetable-template-v1';
  static const timetableOverrides = 'calendar-timetable-overrides-v1';
  static const cellDesign    = 'calendar-cell-design-v1';
  static const neisSchool    = 'calendar-neis-school-v1';
  static const birthdays     = 'calendar-birthdays-v1';
  static const userProfile   = 'calendar-user-profile-v2';
  static const backupConfig  = 'calendar-backup-config-v1';
  static const supabaseHashes = 'calendar_supabase_hashes_v1';
}
