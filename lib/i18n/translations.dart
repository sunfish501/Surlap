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

  // ── 온보딩 슬라이드 ──
  '학교 시간표·급식,\n자동으로 채워져요': {
    AppLang.en: 'School timetable & meals,\nfilled in automatically',
    AppLang.ja: '学校の時間割・給食が\n自動で入ります',
    AppLang.zh: '校园课程表·餐食\n自动填入',
    AppLang.es: 'Horario y comidas\nse llenan solos',
  },
  '학년·반만 알려주면 시간표와 급식이 매일 들어와요. (NEIS 연동)': {
    AppLang.en: 'Just enter grade & class — timetable and meals arrive daily. (NEIS)',
    AppLang.ja: '学年・組を入れるだけで時間割と給食が毎日届きます。(NEIS連携)',
    AppLang.zh: '只需填写年级·班级，课程表与餐食每天自动更新。(NEIS)',
    AppLang.es: 'Indica curso y clase: horario y comidas cada día. (NEIS)',
  },
  '일정·할 일·기록을\n앱 하나로': {
    AppLang.en: 'Events, to-dos & notes\nin one app',
    AppLang.ja: '予定・ToDo・記録を\nひとつのアプリで',
    AppLang.zh: '日程·待办·记录\n一个应用搞定',
    AppLang.es: 'Eventos, tareas y notas\nen una sola app',
  },
  '달력, 할 일, 하루 기록까지 — 여러 앱을 오갈 필요 없어요.': {
    AppLang.en: 'Calendar, to-dos, daily notes — no app-switching.',
    AppLang.ja: 'カレンダー、ToDo、記録まで — アプリを行き来する必要なし。',
    AppLang.zh: '日历、待办、每日记录 — 无需在多个应用间切换。',
    AppLang.es: 'Calendario, tareas y notas — sin cambiar de app.',
  },
  '백호가 함께해요': {
    AppLang.en: 'The white tiger is with you',
    AppLang.ja: '白虎が一緒です',
    AppLang.zh: '白虎与你同行',
    AppLang.es: 'El tigre blanco te acompaña',
  },
  '오늘을 응원하고, 비어 있는 하루엔 쉼을 권하는 작은 친구.': {
    AppLang.en: 'A little friend cheering you on, and nudging you to rest.',
    AppLang.ja: '今日を応援し、空いた日には休息をすすめる小さな友達。',
    AppLang.zh: '为你的每一天加油，空闲时也提醒你休息的小伙伴。',
    AppLang.es: 'Un amiguito que te anima y te invita a descansar.',
  },
  '어떤 분이세요?': {
    AppLang.en: 'Who are you?',
    AppLang.ja: 'どんな方ですか?',
    AppLang.zh: '你是哪类用户?',
    AppLang.es: '¿Quién eres?',
  },
  '유형에 맞춰 화면을 채워드려요. 나중에 설정에서 바꿀 수 있어요.': {
    AppLang.en: "We'll tailor the app to you. Change it later in settings.",
    AppLang.ja: 'タイプに合わせて画面を整えます。あとで設定から変更できます。',
    AppLang.zh: '我们会按类型为你定制界面。稍后可在设置中更改。',
    AppLang.es: 'Adaptamos la app a ti. Puedes cambiarlo en ajustes.',
  },

  // ── 공통(모달 필드/단어) ──
  '날짜': {AppLang.en: 'Date', AppLang.ja: '日付', AppLang.zh: '日期', AppLang.es: 'Fecha'},
  '날짜 없음': {AppLang.en: 'No date', AppLang.ja: '日付なし', AppLang.zh: '无日期', AppLang.es: 'Sin fecha'},
  '시간 (선택)': {AppLang.en: 'Time (optional)', AppLang.ja: '時間 (任意)', AppLang.zh: '时间（可选）', AppLang.es: 'Hora (opcional)'},
  '우선순위': {AppLang.en: 'Priority', AppLang.ja: '優先度', AppLang.zh: '优先级', AppLang.es: 'Prioridad'},
  '없음': {AppLang.en: 'None', AppLang.ja: 'なし', AppLang.zh: '无', AppLang.es: 'Ninguno'},
  '지움': {AppLang.en: 'Clear', AppLang.ja: 'クリア', AppLang.zh: '清除', AppLang.es: 'Borrar'},
  '이름': {AppLang.en: 'Name', AppLang.ja: '名前', AppLang.zh: '名称', AppLang.es: 'Nombre'},

  // ── 일정 추가/편집 ── ('일정 추가'는 FAB 블록에 이미 있음)
  '일정 편집': {AppLang.en: 'Edit event', AppLang.ja: '予定を編集', AppLang.zh: '编辑日程', AppLang.es: 'Editar evento'},
  '일정 내용': {AppLang.en: 'Event details', AppLang.ja: '予定の内容', AppLang.zh: '日程内容', AppLang.es: 'Detalle del evento'},
  '제목을 입력해주세요': {AppLang.en: 'Please enter a title', AppLang.ja: 'タイトルを入力してください', AppLang.zh: '请输入标题', AppLang.es: 'Escribe un título'},
  '일정을 추가했어요': {AppLang.en: 'Event added', AppLang.ja: '予定を追加しました', AppLang.zh: '已添加日程', AppLang.es: 'Evento añadido'},
  '일정을 수정했어요': {AppLang.en: 'Event updated', AppLang.ja: '予定を更新しました', AppLang.zh: '已更新日程', AppLang.es: 'Evento actualizado'},
  '캘린더 (여러 개 선택 가능)': {AppLang.en: 'Calendars (multi-select)', AppLang.ja: 'カレンダー (複数選択可)', AppLang.zh: '日历（可多选）', AppLang.es: 'Calendarios (varios)'},

  // ── 할 일 추가/편집 ──
  '할 일 편집': {AppLang.en: 'Edit to-do', AppLang.ja: 'ToDoを編集', AppLang.zh: '编辑待办', AppLang.es: 'Editar tarea'},
  '할 일을 입력해주세요': {AppLang.en: 'Please enter a to-do', AppLang.ja: 'ToDoを入力してください', AppLang.zh: '请输入待办', AppLang.es: 'Escribe una tarea'},
  '할 일을 수정했어요': {AppLang.en: 'To-do updated', AppLang.ja: 'ToDoを更新しました', AppLang.zh: '已更新待办', AppLang.es: 'Tarea actualizada'},
  '좋아요! 할 일을 추가했어요': {AppLang.en: 'Nice! To-do added', AppLang.ja: 'いいね！ToDoを追加しました', AppLang.zh: '太好了！已添加待办', AppLang.es: '¡Bien! Tarea añadida'},

  // ── 검색 ──
  '일정·할 일 검색': {AppLang.en: 'Search events & to-dos', AppLang.ja: '予定・ToDoを検索', AppLang.zh: '搜索日程·待办', AppLang.es: 'Buscar eventos y tareas'},
  '일정과 할 일을 검색해요': {AppLang.en: 'Search your events and to-dos', AppLang.ja: '予定とToDoを検索します', AppLang.zh: '搜索你的日程与待办', AppLang.es: 'Busca tus eventos y tareas'},
  '무엇을 찾고 있나요?': {AppLang.en: 'What are you looking for?', AppLang.ja: '何をお探しですか?', AppLang.zh: '想找什么?', AppLang.es: '¿Qué buscas?'},
  '검색 결과가 없어요': {AppLang.en: 'No results', AppLang.ja: '検索結果がありません', AppLang.zh: '没有结果', AppLang.es: 'Sin resultados'},
  '다른 단어로 찾아볼까요?': {AppLang.en: 'Try another word?', AppLang.ja: '別の言葉で検索しますか?', AppLang.zh: '换个词试试?', AppLang.es: '¿Probar otra palabra?'},
  '일정': {AppLang.en: 'Event', AppLang.ja: '予定', AppLang.zh: '日程', AppLang.es: 'Evento'},
  '할 일': {AppLang.en: 'To-do', AppLang.ja: 'ToDo', AppLang.zh: '待办', AppLang.es: 'Tarea'},

  // ── 프로필 ──
  '프로필': {AppLang.en: 'Profile', AppLang.ja: 'プロフィール', AppLang.zh: '个人', AppLang.es: 'Perfil'},
  '계정': {AppLang.en: 'Account', AppLang.ja: 'アカウント', AppLang.zh: '账户', AppLang.es: 'Cuenta'},
  '앱': {AppLang.en: 'App', AppLang.ja: 'アプリ', AppLang.zh: '应用', AppLang.es: 'App'},
  '다크 모드': {AppLang.en: 'Dark mode', AppLang.ja: 'ダークモード', AppLang.zh: '深色模式', AppLang.es: 'Modo oscuro'},
  '로그아웃': {AppLang.en: 'Sign out', AppLang.ja: 'ログアウト', AppLang.zh: '退出登录', AppLang.es: 'Cerrar sesión'},
  '로그인': {AppLang.en: 'Sign in', AppLang.ja: 'ログイン', AppLang.zh: '登录', AppLang.es: 'Iniciar sesión'},
  '로그인하고 동기화하기': {AppLang.en: 'Sign in to sync', AppLang.ja: 'ログインして同期', AppLang.zh: '登录并同步', AppLang.es: 'Inicia sesión y sincroniza'},
  '로그인하여 클라우드 동기화': {AppLang.en: 'Sign in for cloud sync', AppLang.ja: 'ログインしてクラウド同期', AppLang.zh: '登录以云同步', AppLang.es: 'Inicia sesión para sincronizar'},
  '일정·시간표·캘린더를 기기 간 동기화': {
    AppLang.en: 'Sync events, timetable & calendars across devices',
    AppLang.ja: '予定・時間割・カレンダーを端末間で同期',
    AppLang.zh: '在设备间同步日程·课程表·日历',
    AppLang.es: 'Sincroniza eventos, horario y calendarios',
  },
  '정보 백업': {AppLang.en: 'Backup', AppLang.ja: 'バックアップ', AppLang.zh: '数据备份', AppLang.es: 'Copia de seguridad'},
  '회원 탈퇴': {AppLang.en: 'Delete account', AppLang.ja: '退会', AppLang.zh: '注销账户', AppLang.es: 'Eliminar cuenta'},
  '탈퇴': {AppLang.en: 'Delete', AppLang.ja: '退会', AppLang.zh: '注销', AppLang.es: 'Eliminar'},
  '계정이 삭제되었어요': {AppLang.en: 'Account deleted', AppLang.ja: 'アカウントを削除しました', AppLang.zh: '账户已删除', AppLang.es: 'Cuenta eliminada'},
  '계정과 클라우드에 저장된 데이터가 영구히 삭제돼요.\n이 작업은 되돌릴 수 없어요.': {
    AppLang.en: 'Your account and cloud data will be permanently deleted.\nThis cannot be undone.',
    AppLang.ja: 'アカウントとクラウドのデータが完全に削除されます。\nこの操作は元に戻せません。',
    AppLang.zh: '账户及云端数据将被永久删除。\n此操作无法撤销。',
    AppLang.es: 'Tu cuenta y datos en la nube se eliminarán para siempre.\nNo se puede deshacer.',
  },

  // ── 생일 ──
  '생일 알림': {AppLang.en: 'Birthday reminder', AppLang.ja: '誕生日通知', AppLang.zh: '生日提醒', AppLang.es: 'Recordatorio'},
  '생일 선택': {AppLang.en: 'Pick a date', AppLang.ja: '誕生日を選択', AppLang.zh: '选择生日', AppLang.es: 'Elige fecha'},
  '연도 포함': {AppLang.en: 'Include year', AppLang.ja: '年を含む', AppLang.zh: '包含年份', AppLang.es: 'Incluir año'},
  '직접 추가': {AppLang.en: 'Add manually', AppLang.ja: '手動で追加', AppLang.zh: '手动添加', AppLang.es: 'Añadir manual'},
  '당일만': {AppLang.en: 'On the day', AppLang.ja: '当日のみ', AppLang.zh: '仅当天', AppLang.es: 'El mismo día'},
  '며칠 전 알림': {AppLang.en: 'Days before', AppLang.ja: '何日前に通知', AppLang.zh: '提前几天', AppLang.es: 'Días antes'},
  '아직 등록된 생일이 없어요': {AppLang.en: 'No birthdays yet', AppLang.ja: 'まだ誕生日がありません', AppLang.zh: '还没有生日', AppLang.es: 'Aún no hay cumpleaños'},
  '위에서 직접 추가해 보세요': {AppLang.en: 'Add one above', AppLang.ja: '上から追加してください', AppLang.zh: '在上方添加', AppLang.es: 'Añade uno arriba'},
  '이름과 생일을 입력해 주세요': {AppLang.en: 'Enter a name and date', AppLang.ja: '名前と誕生日を入力してください', AppLang.zh: '请输入姓名和生日', AppLang.es: 'Escribe nombre y fecha'},
  '오늘 🎉': {AppLang.en: 'Today 🎉', AppLang.ja: '今日 🎉', AppLang.zh: '今天 🎉', AppLang.es: 'Hoy 🎉'},

  // ── 공유 캘린더(테마) ──
  '새 공유일정 생성하기': {AppLang.en: 'New shared calendar', AppLang.ja: '新しい共有予定', AppLang.zh: '新建共享日程', AppLang.es: 'Nuevo calendario compartido'},
  '캘린더 이름': {AppLang.en: 'Calendar name', AppLang.ja: 'カレンダー名', AppLang.zh: '日历名称', AppLang.es: 'Nombre del calendario'},
  '색상 선택': {AppLang.en: 'Pick a color', AppLang.ja: '色を選択', AppLang.zh: '选择颜色', AppLang.es: 'Elige color'},
  '공유 코드로 가져오기': {AppLang.en: 'Import by code', AppLang.ja: '共有コードで取得', AppLang.zh: '用分享码导入', AppLang.es: 'Importar por código'},
  '공유 코드 입력': {AppLang.en: 'Enter share code', AppLang.ja: '共有コードを入力', AppLang.zh: '输入分享码', AppLang.es: 'Escribe el código'},
  '가져오기': {AppLang.en: 'Import', AppLang.ja: '取得', AppLang.zh: '导入', AppLang.es: 'Importar'},
  '받기': {AppLang.en: 'Get', AppLang.ja: '受け取る', AppLang.zh: '获取', AppLang.es: 'Obtener'},
  '복제': {AppLang.en: 'Duplicate', AppLang.ja: '複製', AppLang.zh: '复制', AppLang.es: 'Duplicar'},
  '구독 중': {AppLang.en: 'Subscribed', AppLang.ja: '購読中', AppLang.zh: '已订阅', AppLang.es: 'Suscrito'},
  '구독 취소': {AppLang.en: 'Unsubscribe', AppLang.ja: '購読解除', AppLang.zh: '取消订阅', AppLang.es: 'Cancelar'},
  '공유': {AppLang.en: 'Share', AppLang.ja: '共有', AppLang.zh: '分享', AppLang.es: 'Compartir'},
  '공유 안 됨': {AppLang.en: 'Not shared', AppLang.ja: '未共有', AppLang.zh: '未分享', AppLang.es: 'No compartido'},
  '내 카테고리': {AppLang.en: 'My categories', AppLang.ja: 'マイカテゴリ', AppLang.zh: '我的分类', AppLang.es: 'Mis categorías'},
  '아직 만든 캘린더가 없어요': {AppLang.en: 'No calendars yet', AppLang.ja: 'まだカレンダーがありません', AppLang.zh: '还没有日历', AppLang.es: 'Aún no hay calendarios'},
  '캘린더를 만들어 일정을 색으로 구분해요': {
    AppLang.en: 'Create calendars to color-code your events',
    AppLang.ja: 'カレンダーを作って予定を色分けします',
    AppLang.zh: '创建日历，用颜色区分日程',
    AppLang.es: 'Crea calendarios para colorear tus eventos',
  },
  '로그인해야 이용할 수 있는 서비스입니다': {
    AppLang.en: 'Sign in to use this',
    AppLang.ja: 'ログインが必要です',
    AppLang.zh: '需要登录才能使用',
    AppLang.es: 'Inicia sesión para usar esto',
  },

  // ── 위젯(기록 템플릿) 시트 ──
  '아직 만든 위젯이 없어요. 새로 만들어 보세요.': {
    AppLang.en: 'No widgets yet. Create one.',
    AppLang.ja: 'まだウィジェットがありません。作成しましょう。',
    AppLang.zh: '还没有小组件，去创建吧。',
    AppLang.es: 'Aún no hay widgets. Crea uno.',
  },
  '추가할 위젯을 선택하세요.': {
    AppLang.en: 'Choose a widget to add.',
    AppLang.ja: '追加するウィジェットを選んでください。',
    AppLang.zh: '选择要添加的小组件。',
    AppLang.es: 'Elige un widget para añadir.',
  },
  '새 위젯 만들기': {AppLang.en: 'New widget', AppLang.ja: '新しいウィジェット', AppLang.zh: '新建小组件', AppLang.es: 'Nuevo widget'},

  // ── trf(치환) ──
  '이 날의 일정 ({0})': {AppLang.en: "Events ({0})", AppLang.ja: 'この日の予定 ({0})', AppLang.zh: '当天日程 ({0})', AppLang.es: 'Eventos ({0})'},
  '이 날의 할 일 ({0})': {AppLang.en: "To-dos ({0})", AppLang.ja: 'この日のToDo ({0})', AppLang.zh: '当天待办 ({0})', AppLang.es: 'Tareas ({0})'},
  '{0} 기록하기': {AppLang.en: 'Log {0}', AppLang.ja: '{0}を記録', AppLang.zh: '记录{0}', AppLang.es: 'Registrar {0}'},
  '{0}개 항목': {AppLang.en: '{0} fields', AppLang.ja: '{0}項目', AppLang.zh: '{0} 个项目', AppLang.es: '{0} campos'},
  '등록된 생일 ({0})': {AppLang.en: 'Birthdays ({0})', AppLang.ja: '登録した誕生日 ({0})', AppLang.zh: '已登记生日 ({0})', AppLang.es: 'Cumpleaños ({0})'},
  '할 일 (예: 내일 p1 빨래하기)': {
    AppLang.en: 'To-do (e.g. laundry tomorrow p1)',
    AppLang.ja: 'ToDo（例：明日 p1 洗濯）',
    AppLang.zh: '待办（例：明天 p1 洗衣服）',
    AppLang.es: 'Tarea (ej: lavar ropa mañana p1)',
  },
  '듣고 있어요… 말한 뒤 손을 떼세요': {
    AppLang.en: 'Listening… release when done',
    AppLang.ja: '聞いています…話し終えたら離してください',
    AppLang.zh: '正在聆听…说完后松开',
    AppLang.es: 'Escuchando… suelta al terminar',
  },
};
