package com.kori.moneytracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home-screen widget. Every string and amount is formatted on the Flutter side
 * (HomeWidgetService) in the user's language, currency and numerals, so this
 * only lays them out.
 *
 * The figures are a snapshot from the last time the app ran. If that snapshot
 * is from an earlier day (or month) the widget shows the stored zero instead,
 * so it never presents yesterday's spending as today's.
 */
class PoisaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val zero = widgetData.getString("zero_amount", null) ?: "0"
        val sameDay = widgetData.getString("snapshot_day", null) == today
        val sameMonth =
            System.currentTimeMillis() < (widgetData.getString("month_end_ms", null)?.toLongOrNull() ?: 0L)

        val todayAmount = if (sameDay) widgetData.getString("today_amount", null) ?: zero else zero
        val monthAmount = if (sameMonth) widgetData.getString("month_amount", null) ?: zero else zero
        val monthLabel = widgetData.getString("month_label", null) ?: "This month"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.poisa_widget).apply {
                setTextViewText(R.id.widget_today_label, widgetData.getString("today_label", null) ?: "Spent today")
                setTextViewText(R.id.widget_today_amount, todayAmount)
                setTextViewText(R.id.widget_month, "$monthLabel  $monthAmount")
                setTextViewText(R.id.widget_add_expense, "+ " + (widgetData.getString("expense_label", null) ?: "Expense"))
                setTextViewText(R.id.widget_add_income, "+ " + (widgetData.getString("income_label", null) ?: "Income"))

                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("poisa://open")),
                )
                setOnClickPendingIntent(
                    R.id.widget_add_expense,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("poisa://add/expense")),
                )
                setOnClickPendingIntent(
                    R.id.widget_add_income,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("poisa://add/income")),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
