# Surlap 위젯 / Live Activity 통합 가이드

> 이 문서는 Phase 5–7(네이티브 위젯) 통합용 메모. Flutter 측은 모두 자동 빌드되지만,
> iOS Widget Extension / Android Glance / 알림 채널은 Xcode·Android Studio·플러그인
> 설정이 필요. 아래 절차로 한 번만 셋업하면 됨.

## 1. iOS — WidgetKit + Live Activity

### 1.1 새 파일 (이미 작성됨, Xcode 타깃 추가 필요)
- `ios/HourSpaceWidget/SurlapTheme.swift` — 위젯 디자인 토큰
- `ios/HourSpaceWidget/PeriodBar.swift` — 교시 세그먼트 바
- `ios/HourSpaceWidget/NowNextCard.swift` — 지금/다음 카드 모듈
- `ios/HourSpaceWidget/SurlapLiveActivity.swift` — Live Activity + Dynamic Island

### 1.2 Xcode 단계
1. Xcode에서 `ios/Runner.xcworkspace` 열기.
2. 좌측 트리에서 `HourSpaceWidget` 폴더 우클릭 → "Add Files to Runner..." → 위 4개 파일 선택.
   타깃은 **HourSpaceWidget** 만 체크(Runner 제외).
3. Signing & Capabilities → HourSpaceWidget 타깃 → Capabilities + 버튼 →
   **App Groups** + **Push Notifications**(Live Activity 원격 갱신용) 추가.
4. `Info.plist`에 `NSSupportsLiveActivities = YES` 추가(Runner 측, 메인 앱).
5. WidgetBundle 에 `SurlapLiveActivity()` 추가 — 기존 `HourSpaceWidget.swift` 의
   `HourSpaceWidgetBundle` 안에 한 줄.
   ```swift
   @main
   struct HourSpaceWidgetBundle: WidgetBundle {
       var body: some Widget {
           HourSpaceWidget()
           if #available(iOS 16.1, *) { SurlapLiveActivity() }
       }
   }
   ```
6. App Group 식별자 통일 — 현재 `group.com.spacehour.spacehour`. 새 브랜드에 맞게
   `group.com.kev208dev.Surlap` 등으로 바꾸려면:
   - HourSpaceWidget.entitlements + Runner.entitlements 둘 다 갱신
   - Apple Developer Portal에서 App Group 등록 → 두 앱 ID에 활성화
   - `lib/home_widget/widget_bridge.dart` 의 `appGroupId` 동일하게 갱신
   - 미사용/임시 데이터 마이그레이션 필요(다른 그룹의 SharedPreferences 분리).

### 1.3 Live Activity 시작/종료 — Flutter 측
`live_activities` 플러그인 또는 직접 MethodChannel. 예시 채널명 `surlap/live_activity`,
메서드 `start`/`update`/`end` + ContentState JSON.
교시 전환 감지 후 호출하면 됨(시간표 provider watch).

## 2. Android — Glance App Widget + 진행 중 알림

### 2.1 Glance 활성화 (build.gradle)
`android/app/build.gradle.kts` 의 `dependencies` 블록에 추가:
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.compose.runtime:runtime:1.7.5")
    implementation("androidx.datastore:datastore-preferences:1.1.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
}
```
또한 `plugins` 에 `id("org.jetbrains.kotlin.plugin.serialization") version "..."`.

### 2.2 Glance 위젯 스캐폴드 (Kotlin)
아래 스니펫을 `android/app/src/main/kotlin/com/kev208dev/Surlap/SurlapPeriodWidget.kt`
에 넣고 `AndroidManifest.xml` 에 receiver 등록:
```xml
<receiver android:name=".SurlapPeriodWidgetReceiver"
          android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data android:name="android.appwidget.provider"
               android:resource="@xml/surlap_period_widget_info"/>
</receiver>
```

```kotlin
package com.kev208dev.Surlap

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.color.ColorProvider
import androidx.glance.background

object SurlapTheme {
    val surfaceTop = Color(0xFF1E1638)
    val accent = Color(0xFFA98BFF)
    val labelMuted = Color(0xFF8E8C97)
    val caption = Color(0xFFA4A2AD)
    val jewel = listOf(
        Color(0xFF3A3A78), Color(0xFF2F4E7A), Color(0xFF1F5A5A),
        Color(0xFF243A6E), Color(0xFF3E2E72), Color(0xFF5A2E62)
    )
}

class SurlapPeriodWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            Column(GlanceModifier.fillMaxSize()
                .background(SurlapTheme.surfaceTop).cornerRadius(28.dp)
                .padding(18.dp)) {
                Row { Text("지금"); Spacer(GlanceModifier.defaultWeight()); Text("다음") }
                // ... NowNextCard 본문(SwiftUI 와 1:1)
            }
        }
    }
}
class SurlapPeriodWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = SurlapPeriodWidget()
}
```

### 2.3 진행 중 알림 (교시 알림)
NotificationChannel 한 번 생성 + Foreground/ongoing notification 으로 교시 시작 시 띄움.
```kotlin
val ch = NotificationChannel("now_class", "지금 수업", NotificationManager.IMPORTANCE_LOW)
NotificationManagerCompat.from(ctx).createNotificationChannel(ch)

val n = NotificationCompat.Builder(ctx, "now_class")
    .setSmallIcon(R.drawable.ic_surlap)
    .setColor(0xFFA98BFF.toInt())
    .setContentTitle(nowName)
    .setContentText("$start – $end · ${periodIdx}교시")
    .setSubText("Surlap · 지금 수업")
    .setProgress(100, progress01_100, false)
    .setOngoing(true).setOnlyAlertOnce(true)
    .build()
NotificationManagerCompat.from(ctx).notify(1001, n)
```
교시 전환마다 갱신 / 종료 시 `cancel(1001)`. WorkManager(주기) + AlarmManager(정확 알람) 조합.

### 2.4 Material You 변형
Android 12+ 다이내믹 컬러는 `system_accent1_*`, `system_neutral1_*` 토큰 사용:
- surface = `system_neutral1_100`
- onSurface = `system_neutral1_900`
- primary(= current period) = `system_accent1_600`
사용자 설정으로 브랜드 고정 / Material You 자동 분기.

## 3. 폰트 (Pretendard)

### iOS Widget 타깃
1. `assets/fonts/Pretendard-Bold.otf` 등을 `ios/HourSpaceWidget/Fonts/` 로 복사.
2. Xcode → HourSpaceWidget 타깃 → "Build Phases" → "Copy Bundle Resources" 에 추가.
3. `Info.plist` → `Fonts provided by application` 에 파일명 등록.
4. SwiftUI 에서 `.font(.custom("Pretendard-Bold", size: 24))` 로 교체.

### Android Widget
`android/app/src/main/res/font/pretendard_bold.ttf` 배치 후 Glance `TextStyle(fontFamily = FontFamily("pretendard_bold"))`.

## 4. Flutter 데이터 브리지 확장 (TODO)

`lib/home_widget/widget_bridge.dart` 에 시간표 periods 직렬화 추가:
```dart
'periods': periodsToday.map((p) => {
  'name': p.name,
  'start': p.startHHmm,
  'end': p.endHHmm,
  'color': '#${(p.color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
}).toList(),
'currentIndex': periodCurrentIdx,
'progress': periodProgress01,
'minutesRemaining': periodMinutesLeft,
'nowName': currentPeriod?.name,
'nextName': nextPeriod?.name,
```
교시 정보는 `lib/screens/timetable_view/` + `lib/providers/neis_cache_provider.dart` 에
이미 있음. 시간표 갱신 시 + 분 단위 타이머로 sync 호출.
