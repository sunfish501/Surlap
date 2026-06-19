package com.kev208dev.Surlap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class HourSpaceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hourspace_widget)

            // 탭하면 앱 열기
            val pi = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            val raw = widgetData.getString("hs_widget", null)
            if (raw == null) {
                render(views, "오늘", "", "", "", true)
            } else {
                try {
                    val o = JSONObject(raw)
                    val dateLabel = o.optString("dateLabel", "오늘")
                    val todoCount = o.optInt("todoCount", 0)
                    val todoDone = o.optInt("todoDone", 0)
                    val eventCount = o.optInt("eventCount", 0)

                    val counts = "할 일 $todoDone/$todoCount · 일정 $eventCount"

                    val todoSb = StringBuilder()
                    val todos = o.optJSONArray("todos")
                    if (todos != null) {
                        for (i in 0 until todos.length()) {
                            val t = todos.getJSONObject(i)
                            val mark = if (t.optBoolean("done", false)) "☑" else "☐"
                            if (todoSb.isNotEmpty()) todoSb.append("\n")
                            todoSb.append("$mark ${t.optString("title", "")}")
                        }
                    }

                    val evSb = StringBuilder()
                    val events = o.optJSONArray("events")
                    if (events != null) {
                        for (i in 0 until events.length()) {
                            val e = events.getJSONObject(i)
                            val time = e.optString("time", "")
                            val prefix = if (time.isEmpty()) "•" else time
                            if (evSb.isNotEmpty()) evSb.append("\n")
                            evSb.append("$prefix  ${e.optString("title", "")}")
                        }
                    }

                    val empty = todoCount == 0 && eventCount == 0
                    render(views, dateLabel, counts, todoSb.toString(), evSb.toString(), empty)
                } catch (e: Exception) {
                    render(views, "오늘", "", "", "", true)
                }
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun render(
        views: RemoteViews,
        date: String,
        counts: String,
        todos: String,
        events: String,
        empty: Boolean
    ) {
        views.setTextViewText(R.id.widget_date, date)
        views.setTextViewText(R.id.widget_counts, counts)
        views.setTextViewText(R.id.widget_todos, todos)
        views.setTextViewText(R.id.widget_events, events)
        views.setViewVisibility(R.id.widget_todos, if (todos.isEmpty()) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_events, if (events.isEmpty()) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_empty, if (empty) View.VISIBLE else View.GONE)
    }
}
