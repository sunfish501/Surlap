import 'app_lang.dart';

/// 한국어 원문 → 언어별 번역. 한국어는 원문을 그대로 쓰므로 맵엔 en/ja/zh/es만.
/// 없는 키는 tr()이 한국어로 폴백 → 점진적으로 채워도 앱이 깨지지 않는다.
const Map<String, Map<AppLang, String>> kTranslations = {
  // ── 언어 선택 화면 ──
  '언어를 선택하세요': {
    AppLang.en: 'Select your language',
    AppLang.ja: '言語を選択してください',
    AppLang.zh: '请选择语言',
    AppLang.es: 'Selecciona tu idioma',
  },
  '나중에 설정에서 바꿀 수 있어요': {
    AppLang.en: 'You can change this later in settings',
    AppLang.ja: 'あとで設定から変更できます',
    AppLang.zh: '稍后可在设置中更改',
    AppLang.es: 'Puedes cambiarlo luego en ajustes',
  },
  '언어': {
    AppLang.en: 'Language',
    AppLang.ja: '言語',
    AppLang.zh: '语言',
    AppLang.es: 'Idioma',
  },

  // ── 로그인 화면/모달 ──
  '오늘의 시간을 정리해볼까요?': {
    AppLang.en: 'Shall we organize your day?',
    AppLang.ja: '今日の時間を整理しましょう',
    AppLang.zh: '来整理今天的时间吧',
    AppLang.es: '¿Organizamos tu día?',
  },
  '로그인하면 일정·시간표·캘린더가\n모든 기기에서 안전하게 동기화돼요': {
    AppLang.en: 'Sign in to sync your events, timetable\nand calendars safely across devices',
    AppLang.ja: 'ログインすると予定・時間割・カレンダーが\n全ての端末で安全に同期されます',
    AppLang.zh: '登录后，日程·课程表·日历\n将在所有设备间安全同步',
    AppLang.es: 'Inicia sesión para sincronizar eventos,\nhorario y calendarios en tus dispositivos',
  },
  'Google로 계속하기': {
    AppLang.en: 'Continue with Google',
    AppLang.ja: 'Googleで続行',
    AppLang.zh: '使用 Google 继续',
    AppLang.es: 'Continuar con Google',
  },
  'Google로 로그인': {
    AppLang.en: 'Sign in with Google',
    AppLang.ja: 'Googleでログイン',
    AppLang.zh: '使用 Google 登录',
    AppLang.es: 'Iniciar sesión con Google',
  },
  '아이디로 로그인': {
    AppLang.en: 'Sign in with ID',
    AppLang.ja: 'IDでログイン',
    AppLang.zh: '使用账号登录',
    AppLang.es: 'Iniciar sesión con ID',
  },
  '나중에 하기': {
    AppLang.en: 'Maybe later',
    AppLang.ja: 'あとで',
    AppLang.zh: '稍后再说',
    AppLang.es: 'Más tarde',
  },
  '사용 방식을 선택해주세요': {
    AppLang.en: 'Choose how to use the app',
    AppLang.ja: '利用方法を選んでください',
    AppLang.zh: '请选择使用方式',
    AppLang.es: 'Elige cómo usar la app',
  },
  '또는': {
    AppLang.en: 'or',
    AppLang.ja: 'または',
    AppLang.zh: '或',
    AppLang.es: 'o',
  },
  '로그인 없이 사용': {
    AppLang.en: 'Use without signing in',
    AppLang.ja: 'ログインせずに使う',
    AppLang.zh: '不登录直接使用',
    AppLang.es: 'Usar sin iniciar sesión',
  },
  '아이디': {
    AppLang.en: 'ID',
    AppLang.ja: 'ID',
    AppLang.zh: '账号',
    AppLang.es: 'ID',
  },
  '비밀번호': {
    AppLang.en: 'Password',
    AppLang.ja: 'パスワード',
    AppLang.zh: '密码',
    AppLang.es: 'Contraseña',
  },
  '처음이면 새 아이디 등록': {
    AppLang.en: 'New here? Creates an account',
    AppLang.ja: '初めてなら新規登録',
    AppLang.zh: '首次使用将注册新账号',
    AppLang.es: '¿Nuevo? Crea una cuenta',
  },
  '4자 이상': {
    AppLang.en: 'At least 4 characters',
    AppLang.ja: '4文字以上',
    AppLang.zh: '至少4个字符',
    AppLang.es: 'Mínimo 4 caracteres',
  },
  '아이디와 비밀번호를 입력해주세요': {
    AppLang.en: 'Please enter your ID and password',
    AppLang.ja: 'IDとパスワードを入力してください',
    AppLang.zh: '请输入账号和密码',
    AppLang.es: 'Ingresa tu ID y contraseña',
  },
  '로그인에 실패했어요. 잠시 후 다시 시도해주세요': {
    AppLang.en: 'Sign-in failed. Please try again shortly',
    AppLang.ja: 'ログインに失敗しました。しばらくして再試行してください',
    AppLang.zh: '登录失败，请稍后再试',
    AppLang.es: 'Error al iniciar sesión. Inténtalo de nuevo',
  },

  // ── 공통 버튼/단어 ──
  '확인': {AppLang.en: 'OK', AppLang.ja: '確認', AppLang.zh: '确定', AppLang.es: 'Aceptar'},
  '취소': {AppLang.en: 'Cancel', AppLang.ja: 'キャンセル', AppLang.zh: '取消', AppLang.es: 'Cancelar'},
  '저장': {AppLang.en: 'Save', AppLang.ja: '保存', AppLang.zh: '保存', AppLang.es: 'Guardar'},
  '삭제': {AppLang.en: 'Delete', AppLang.ja: '削除', AppLang.zh: '删除', AppLang.es: 'Eliminar'},
  '닫기': {AppLang.en: 'Close', AppLang.ja: '閉じる', AppLang.zh: '关闭', AppLang.es: 'Cerrar'},
  '뒤로': {AppLang.en: 'Back', AppLang.ja: '戻る', AppLang.zh: '返回', AppLang.es: 'Atrás'},
  '다음': {AppLang.en: 'Next', AppLang.ja: '次へ', AppLang.zh: '下一步', AppLang.es: 'Siguiente'},
  '시작하기': {AppLang.en: 'Get started', AppLang.ja: 'はじめる', AppLang.zh: '开始使用', AppLang.es: 'Empezar'},
  '다시 시도': {AppLang.en: 'Retry', AppLang.ja: '再試行', AppLang.zh: '重试', AppLang.es: 'Reintentar'},
  '추가': {AppLang.en: 'Add', AppLang.ja: '追加', AppLang.zh: '添加', AppLang.es: 'Añadir'},
  '오늘로': {AppLang.en: 'Today', AppLang.ja: '今日へ', AppLang.zh: '回到今天', AppLang.es: 'Hoy'},
  '일정 검색': {AppLang.en: 'Search events', AppLang.ja: '予定を検索', AppLang.zh: '搜索日程', AppLang.es: 'Buscar eventos'},

  // ── 뷰 세그먼트(연·월·주·일) ──
  '연': {AppLang.en: 'Y', AppLang.ja: '年', AppLang.zh: '年', AppLang.es: 'A'},
  '월': {AppLang.en: 'M', AppLang.ja: '月', AppLang.zh: '月', AppLang.es: 'M'},
  '주': {AppLang.en: 'W', AppLang.ja: '週', AppLang.zh: '周', AppLang.es: 'S'},
  '일': {AppLang.en: 'D', AppLang.ja: '日', AppLang.zh: '日', AppLang.es: 'D'},

  // ── FAB 스피드다이얼 ──
  '공유 캘린더': {AppLang.en: 'Shared calendar', AppLang.ja: '共有カレンダー', AppLang.zh: '共享日历', AppLang.es: 'Calendario compartido'},
  '일정 추가': {AppLang.en: 'Add event', AppLang.ja: '予定を追加', AppLang.zh: '添加日程', AppLang.es: 'Añadir evento'},
  '할 일 추가': {AppLang.en: 'Add to-do', AppLang.ja: 'ToDoを追加', AppLang.zh: '添加待办', AppLang.es: 'Añadir tarea'},
  '기록 템플릿': {AppLang.en: 'Record template', AppLang.ja: '記録テンプレート', AppLang.zh: '记录模板', AppLang.es: 'Plantilla de registro'},
  '위젯 추가': {AppLang.en: 'Add widget', AppLang.ja: 'ウィジェット追加', AppLang.zh: '添加小组件', AppLang.es: 'Añadir widget'},
  '이날 자세히 보기': {AppLang.en: 'View this day', AppLang.ja: 'この日を詳しく', AppLang.zh: '查看当天', AppLang.es: 'Ver este día'},

  // ── 빈 상태/급식 ──
  '이 달은 아직 비어 있어요': {
    AppLang.en: 'This month is empty',
    AppLang.ja: '今月はまだ空です',
    AppLang.zh: '本月还是空的',
    AppLang.es: 'Este mes está vacío',
  },
  '아래 + 버튼으로 일정을 추가해 보세요': {
    AppLang.en: 'Tap + below to add an event',
    AppLang.ja: '下の＋ボタンで予定を追加',
    AppLang.zh: '点击下方 + 添加日程',
    AppLang.es: 'Toca + abajo para añadir',
  },
  '오늘 급식': {AppLang.en: "Today's meals", AppLang.ja: '今日の給食', AppLang.zh: '今日餐食', AppLang.es: 'Comidas de hoy'},
  '조식': {AppLang.en: 'Breakfast', AppLang.ja: '朝食', AppLang.zh: '早餐', AppLang.es: 'Desayuno'},
  '중식': {AppLang.en: 'Lunch', AppLang.ja: '昼食', AppLang.zh: '午餐', AppLang.es: 'Almuerzo'},
  '석식': {AppLang.en: 'Dinner', AppLang.ja: '夕食', AppLang.zh: '晚餐', AppLang.es: 'Cena'},
  '오늘 급식 정보가 없어요': {
    AppLang.en: 'No meal info for today',
    AppLang.ja: '今日の給食情報はありません',
    AppLang.zh: '今天暂无餐食信息',
    AppLang.es: 'Sin info de comidas hoy',
  },
  '학교 연결하기': {AppLang.en: 'Connect school', AppLang.ja: '学校を連携', AppLang.zh: '关联学校', AppLang.es: 'Conectar escuela'},
  '학교 미연결': {AppLang.en: 'No school linked', AppLang.ja: '学校未連携', AppLang.zh: '未关联学校', AppLang.es: 'Sin escuela'},
  '급식 정보를 불러오지 못했어요': {
    AppLang.en: "Couldn't load meal info",
    AppLang.ja: '給食情報を取得できませんでした',
    AppLang.zh: '无法加载餐食信息',
    AppLang.es: 'No se pudieron cargar las comidas',
  },

  // ── 설정 행 ──
  '지난 날 표시': {AppLang.en: 'Show past days', AppLang.ja: '過去の日を表示', AppLang.zh: '显示过去日期', AppLang.es: 'Mostrar días pasados'},
  '알림': {AppLang.en: 'Notifications', AppLang.ja: '通知', AppLang.zh: '通知', AppLang.es: 'Notificaciones'},
  '연속 보기': {AppLang.en: 'Continuous view', AppLang.ja: '連続表示', AppLang.zh: '连续视图', AppLang.es: 'Vista continua'},
  '주 시작일': {AppLang.en: 'Week starts on', AppLang.ja: '週の開始日', AppLang.zh: '每周起始日', AppLang.es: 'Inicio de semana'},
  '월요일': {AppLang.en: 'Monday', AppLang.ja: '月曜日', AppLang.zh: '周一', AppLang.es: 'Lunes'},
  '일요일': {AppLang.en: 'Sunday', AppLang.ja: '日曜日', AppLang.zh: '周日', AppLang.es: 'Domingo'},
  '토요일': {AppLang.en: 'Saturday', AppLang.ja: '土曜日', AppLang.zh: '周六', AppLang.es: 'Sábado'},
  '사용법 안내': {AppLang.en: 'How to use', AppLang.ja: '使い方', AppLang.zh: '使用指南', AppLang.es: 'Cómo usar'},
  '기능 둘러보기': {AppLang.en: 'Feature tour', AppLang.ja: '機能ツアー', AppLang.zh: '功能介绍', AppLang.es: 'Recorrido'},
  '생일 챙기기': {AppLang.en: 'Birthdays', AppLang.ja: '誕生日', AppLang.zh: '生日', AppLang.es: 'Cumpleaños'},
  '학교 연결 (NEIS)': {AppLang.en: 'Connect school (NEIS)', AppLang.ja: '学校連携 (NEIS)', AppLang.zh: '关联学校 (NEIS)', AppLang.es: 'Escuela (NEIS)'},
  '더보기': {AppLang.en: 'More', AppLang.ja: 'もっと見る', AppLang.zh: '更多', AppLang.es: 'Más'},

  // ── 사용자 유형 ──
  '일반인': {AppLang.en: 'General', AppLang.ja: '一般', AppLang.zh: '普通用户', AppLang.es: 'General'},
  '초등학생': {AppLang.en: 'Elementary', AppLang.ja: '小学生', AppLang.zh: '小学生', AppLang.es: 'Primaria'},
  '중학생': {AppLang.en: 'Middle school', AppLang.ja: '中学生', AppLang.zh: '初中生', AppLang.es: 'Secundaria'},
  '고등학생': {AppLang.en: 'High school', AppLang.ja: '高校生', AppLang.zh: '高中生', AppLang.es: 'Bachillerato'},
  '대학생': {AppLang.en: 'University', AppLang.ja: '大学生', AppLang.zh: '大学生', AppLang.es: 'Universidad'},

  // ── 홈 인사말 ──
  '늦은 밤이에요': {AppLang.en: 'Late night', AppLang.ja: '夜更けです', AppLang.zh: '夜深了', AppLang.es: 'Buenas noches'},
  '좋은 아침이에요': {AppLang.en: 'Good morning', AppLang.ja: 'おはようございます', AppLang.zh: '早上好', AppLang.es: 'Buenos días'},
  '좋은 오후예요': {AppLang.en: 'Good afternoon', AppLang.ja: 'こんにちは', AppLang.zh: '下午好', AppLang.es: 'Buenas tardes'},
  '좋은 저녁이에요': {AppLang.en: 'Good evening', AppLang.ja: 'こんばんは', AppLang.zh: '晚上好', AppLang.es: 'Buenas tardes'},

  // ── 홈 카드 ──
  '다음 일정': {AppLang.en: 'Up next', AppLang.ja: '次の予定', AppLang.zh: '下一个日程', AppLang.es: 'Próximo'},
  '오늘 일정': {AppLang.en: "Today's events", AppLang.ja: '今日の予定', AppLang.zh: '今日日程', AppLang.es: 'Eventos de hoy'},
  '오늘 할 일': {AppLang.en: "Today's to-dos", AppLang.ja: '今日のToDo', AppLang.zh: '今日待办', AppLang.es: 'Tareas de hoy'},
  '이번 주': {AppLang.en: 'This week', AppLang.ja: '今週', AppLang.zh: '本周', AppLang.es: 'Esta semana'},
  '오늘 예정된 일정이 없어요': {AppLang.en: 'No events today', AppLang.ja: '今日の予定はありません', AppLang.zh: '今天没有日程', AppLang.es: 'Sin eventos hoy'},
  '남은 일정이 없어요': {AppLang.en: 'No events left', AppLang.ja: '残りの予定はありません', AppLang.zh: '没有剩余日程', AppLang.es: 'Nada más por hoy'},
  '새 일정을 추가하면 이곳에 표시돼요': {
    AppLang.en: 'New events will show up here',
    AppLang.ja: '新しい予定はここに表示されます',
    AppLang.zh: '新日程会显示在这里',
    AppLang.es: 'Los nuevos eventos aparecerán aquí',
  },
  '아직 할 일이 없어요': {AppLang.en: 'No to-dos yet', AppLang.ja: 'まだToDoがありません', AppLang.zh: '还没有待办', AppLang.es: 'Aún no hay tareas'},
  '오른쪽 아래 + 버튼으로 추가해보세요': {
    AppLang.en: 'Tap + at bottom right to add',
    AppLang.ja: '右下の＋で追加できます',
    AppLang.zh: '点击右下角 + 添加',
    AppLang.es: 'Toca + abajo a la derecha',
  },
  '등록된 일정이 없어요': {AppLang.en: 'No events', AppLang.ja: '予定はありません', AppLang.zh: '暂无日程', AppLang.es: 'Sin eventos'},
  '오늘 {0}개': {AppLang.en: 'Today: {0}', AppLang.ja: '今日 {0}件', AppLang.zh: '今日 {0} 个', AppLang.es: 'Hoy: {0}'},
  '개': {AppLang.en: '', AppLang.ja: '件', AppLang.zh: '个', AppLang.es: ''},
  '탭해서 오늘 보기': {AppLang.en: 'Tap to view today', AppLang.ja: 'タップして今日を表示', AppLang.zh: '点击查看今天', AppLang.es: 'Toca para ver hoy'},

  // ── 필터칩(내장 카테고리) ──
  '전체': {AppLang.en: 'All', AppLang.ja: 'すべて', AppLang.zh: '全部', AppLang.es: 'Todos'},
  '공휴일': {AppLang.en: 'Holidays', AppLang.ja: '祝日', AppLang.zh: '节假日', AppLang.es: 'Festivos'},
  '학사일정': {AppLang.en: 'School schedule', AppLang.ja: '学事日程', AppLang.zh: '校历', AppLang.es: 'Calendario escolar'},
  '생일': {AppLang.en: 'Birthdays', AppLang.ja: '誕生日', AppLang.zh: '生日', AppLang.es: 'Cumpleaños'},
};
