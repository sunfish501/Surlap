package com.kev208dev.Surlap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

// Surlap "지금 / 다음" 위젯. home_widget(Flutter) 가 적은 SharedPreferences 키를 읽음.
//   nowName, nowStart, nowEnd, nextName, nextStart, minutesRemaining, currentIndex, periods(JSON)
// receiver(클래스) 이름 변경 시 홈화면에 배치된 기존 위젯은 사라짐(재배치 필요). 미출시 상태라 안전.
class SurlapWidgetProvider : HomeWidgetProvider() {

    private companion object {
        const val SEG_COUNT = 7
        // 미래 교시 기본 주얼톤 (과목 색이 없을 때 폴백).
        val JEWEL = intArrayOf(
            0xFF3A3A78.toInt(), 0xFF2F4E7A.toInt(), 0xFF1F5A5A.toInt(),
            0xFF243A6E.toInt(), 0xFF3E2E72.toInt(), 0xFF5A2E62.toInt(),
            0xFF5A2E4E.toInt()
        )
        const val ACCENT = 0xFFA98BFF.toInt()
        const val IDLE_BG = 0xFF2F2A4A.toInt()
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.surlap_widget)

            // 위젯 탭 → 앱 열기 (시간표 view 로 이동하면 좋음 — 일단 메인).
            val pi = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            val nowName = widgetData.getString("nowName", "") ?: ""
            val nowStart = widgetData.getString("nowStart", "") ?: ""
            val nowEnd = widgetData.getString("nowEnd", "") ?: ""
            val nextName = widgetData.getString("nextName", "") ?: ""
            val nextStart = widgetData.getString("nextStart", "") ?: ""
            val minutesRemaining = widgetData.getInt("minutesRemaining", 0)
            val currentIndex = widgetData.getInt("currentIndex", -1)
            val periodsJson = widgetData.getString("periods", "[]") ?: "[]"

            views.setTextViewText(
                R.id.widget_now_name,
                if (nowName.isBlank()) "수업 없음" else nowName
            )
            val nowTime = if (nowStart.isBlank()) "—" else
                if (nowEnd.isBlank()) nowStart else "$nowStart – $nowEnd"
            views.setTextViewText(R.id.widget_now_time, nowTime)
            views.setTextViewText(
                R.id.widget_next_name,
                if (nextName.isBlank()) "—" else nextName
            )
            views.setTextViewText(R.id.widget_next_time, if (nextStart.isBlank()) "—" else nextStart)

            val remainingText = when {
                currentIndex < 0 -> if (nextName.isNotBlank()) "다음 수업 $nextStart" else "오늘 예정된 수업이 없어요"
                else -> "종료까지 ${minutesRemaining}분 남음"
            }
            views.setTextViewText(R.id.widget_remaining, remainingText)

            // 교시 세그먼트 바 — 최대 7칸. 보이는 개수만 표시, 나머지 GONE.
            val periods = parsePeriods(periodsJson)
            applyPeriodBar(views, periods, currentIndex)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun parsePeriods(raw: String): List<Pair<String, Int>> {
        return try {
            val arr = JSONArray(raw)
            val out = ArrayList<Pair<String, Int>>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val name = o.optString("name", "")
                val colorHex = o.optString("color", "")
                val color = parseHex(colorHex) ?: JEWEL[i % JEWEL.size]
                out.add(name to color)
            }
            out
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun parseHex(hex: String): Int? {
        if (hex.isBlank()) return null
        val s = hex.removePrefix("#")
        return try {
            val v = s.toLong(16)
            when (s.length) {
                6 -> (0xFF000000 or v).toInt()
                8 -> v.toInt()
                else -> null
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun applyPeriodBar(
        views: RemoteViews,
        periods: List<Pair<String, Int>>,
        currentIndex: Int
    ) {
        val segIds = intArrayOf(
            R.id.widget_seg_0, R.id.widget_seg_1, R.id.widget_seg_2,
            R.id.widget_seg_3, R.id.widget_seg_4, R.id.widget_seg_5,
            R.id.widget_seg_6
        )
        val tickIds = intArrayOf(
            R.id.widget_seg_0_tick, R.id.widget_seg_1_tick, R.id.widget_seg_2_tick,
            R.id.widget_seg_3_tick, R.id.widget_seg_4_tick, R.id.widget_seg_5_tick,
            R.id.widget_seg_6_tick
        )
        for (i in 0 until SEG_COUNT) {
            if (i >= periods.size) {
                views.setViewVisibility(segIds[i], View.GONE)
                views.setViewVisibility(tickIds[i], View.GONE)
                continue
            }
            views.setViewVisibility(segIds[i], View.VISIBLE)
            val isCurrent = i == currentIndex
            val baseColor = periods[i].second
            val color = when {
                isCurrent -> ACCENT
                i < currentIndex -> dim(baseColor, 0.5f)
                else -> baseColor
            }
            // RemoteViews 는 GradientDrawable 직접 설정 못 함 → setInt 로 background tint.
            views.setInt(segIds[i], "setBackgroundColor", color)
            views.setViewVisibility(
                tickIds[i],
                if (isCurrent) View.VISIBLE else View.GONE
            )
        }
    }

    private fun dim(color: Int, factor: Float): Int {
        val a = Color.alpha(color)
        val r = (Color.red(color) * factor).toInt().coerceIn(0, 255)
        val g = (Color.green(color) * factor).toInt().coerceIn(0, 255)
        val b = (Color.blue(color) * factor).toInt().coerceIn(0, 255)
        return Color.argb(a, r, g, b)
    }
}
