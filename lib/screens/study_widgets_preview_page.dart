import 'package:flutter/material.dart';
import '../widgets/app_page_scaffold.dart';
import '../widgets/study/study_time_input_card.dart';
import '../widgets/study/today_subject_study_card.dart';
import '../widgets/study/review_round_selector.dart';
import '../widgets/study/today_study_summary_card.dart';
import '../widgets/study/study_goal_card.dart';
import '../widgets/study/exam_prep_card.dart';
import '../widgets/study/study_routine_check_card.dart';

/// 학생용 공부 위젯 쇼케이스 — 데모 상태로 모든 위젯을 한 번에 확인.
/// 실제 nav에 바로 연결하지 않아도 되며, 필요 시 push로 연결 가능.
class StudyWidgetsPreviewPage extends StatefulWidget {
  const StudyWidgetsPreviewPage({super.key});

  @override
  State<StudyWidgetsPreviewPage> createState() =>
      _StudyWidgetsPreviewPageState();
}

class _StudyWidgetsPreviewPageState extends State<StudyWidgetsPreviewPage> {
  // ── 데모 상태 (preview 전용) ──
  Duration _studyTime = const Duration(hours: 3, minutes: 20);
  ReviewRound _round = ReviewRound.second;

  final _subjects = const [
    StudySubjectEntry(
        subject: '국어',
        duration: Duration(minutes: 50),
        color: Color(0xFFE8554E)),
    StudySubjectEntry(
        subject: '수학',
        duration: Duration(hours: 1, minutes: 20),
        color: Color(0xFF5A2DF4)),
    StudySubjectEntry(
        subject: '영어',
        duration: Duration(minutes: 45),
        color: Color(0xFF2E9E6B)),
    StudySubjectEntry(
        subject: '과학', color: Color(0xFFE7913F), active: false),
    StudySubjectEntry(
        subject: '사회', color: Color(0xFF3B82C4), active: false),
  ];

  List<StudyGoal> _goals = const [
    StudyGoal(title: '수학 문제집 30문제', done: true),
    StudyGoal(title: '영어 단어 80개'),
    StudyGoal(title: '국어 문학 복습'),
  ];

  final _exams = const [
    ExamItem(title: '영어 발표', dday: 3),
    ExamItem(title: '과학 보고서', dday: 5),
    ExamItem(title: '수학 단원평가', dday: 7),
  ];

  List<RoutineItem> _routines = const [
    RoutineItem(title: '아침 단어', done: true, streak: 12),
    RoutineItem(title: '학교 복습', streak: 5),
    RoutineItem(title: '수학 오답', done: true, streak: 8),
    RoutineItem(title: '자기 전 암기'),
  ];

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalProgress =
        _goals.isEmpty ? 0.0 : _goals.where((g) => g.done).length / _goals.length;

    return AppPageScaffold(
      title: '공부 위젯',
      subtitle: '학생용 기록·공부 위젯 미리보기',
      children: [
        TodayStudySummaryCard(
          studyTime: _studyTime,
          subjectCount: _subjects.where((s) => s.active).length,
          reviewLabel: _round.label,
          goalProgress: goalProgress,
        ),
        const SizedBox(height: 14),

        StudyTimeInputCard(
          studyTime: _studyTime,
          onChanged: (d) => setState(() => _studyTime = d),
          onManualInput: () => _snack('직접 입력은 준비 중이에요'),
        ),
        const SizedBox(height: 14),

        TodaySubjectStudyCard(
          subjects: _subjects,
          onSubjectTap: (s) => _snack('${s.subject} 상세는 준비 중이에요'),
          onAddSubject: () => _snack('과목 추가는 준비 중이에요'),
        ),
        const SizedBox(height: 14),

        ReviewRoundSelector(
          selectedRound: _round,
          onChanged: (r) => setState(() => _round = r),
        ),
        const SizedBox(height: 14),

        StudyGoalCard(
          goals: _goals,
          onToggle: (i) => setState(() {
            _goals = [
              for (int k = 0; k < _goals.length; k++)
                k == i ? _goals[k].copyWith(done: !_goals[k].done) : _goals[k],
            ];
          }),
          onAdd: () => _snack('목표 추가는 준비 중이에요'),
        ),
        const SizedBox(height: 14),

        ExamPrepCard(
          items: _exams,
          onTap: (e) => _snack('${e.title} 상세는 준비 중이에요'),
          onAdd: () => _snack('평가 추가는 준비 중이에요'),
        ),
        const SizedBox(height: 14),

        StudyRoutineCheckCard(
          routines: _routines,
          onToggle: (i) => setState(() {
            _routines = [
              for (int k = 0; k < _routines.length; k++)
                if (k == i)
                  RoutineItem(
                    title: _routines[k].title,
                    done: !_routines[k].done,
                    streak: _routines[k].streak,
                  )
                else
                  _routines[k],
            ];
          }),
          onAdd: () => _snack('루틴 추가는 준비 중이에요'),
        ),
      ],
    );
  }
}
