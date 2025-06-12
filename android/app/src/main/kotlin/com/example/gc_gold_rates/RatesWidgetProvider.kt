package com.example.flutter_application_1

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class RatesWidgetProvider : AppWidgetProvider() {
    private val job = SupervisorJob()
    private val coroutineScope = CoroutineScope(Dispatchers.IO + job)
    companion object {
        const val ACTION_UPDATE_WIDGET = "com.yourcompany.rateswidget.ACTION_UPDATE_WIDGET"
        private const val REFRESH_INTERVAL = 5 * 60 * 1000L
    }
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, isRefreshAction = false)
        }
        scheduleNextUpdate(context)
    }
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (ACTION_UPDATE_WIDGET == intent.action) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = intent.component ?: return
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (widgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId, isRefreshAction = true)
            }
            scheduleNextUpdate(context)
        }
    }
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextUpdate(context)
    }
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelScheduledUpdates(context)
        job.cancel()
    }
    private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            isRefreshAction: Boolean
    ) {
        val views = RemoteViews(context.packageName, R.layout.rates_widget_layout)
        views.setOnClickPendingIntent(R.id.refresh_button, getRefreshPendingIntent(context))
        if (isRefreshAction) {
            views.setViewVisibility(R.id.refresh_button, View.GONE)
            views.setViewVisibility(R.id.refresh_progress_image, View.VISIBLE)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } else {
            views.setViewVisibility(R.id.refresh_button, View.VISIBLE)
            views.setViewVisibility(R.id.refresh_progress_image, View.GONE)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        coroutineScope.launch { fetchAndApplyRates(context, appWidgetManager, appWidgetId) }
    }
    private suspend fun fetchAndApplyRates(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
    ) {
        val repository = RatesRepository()
        val result = repository.fetchExtendedRates()
        withContext(Dispatchers.Main) {
            val views = RemoteViews(context.packageName, R.layout.rates_widget_layout)
            views.setOnClickPendingIntent(R.id.refresh_button, getRefreshPendingIntent(context))
            when (result) {
                is RatesRepository.Result.Success -> {
                    val formattedGoldRate = "₹ ${result.data.gold995Sell}"
                    val formattedSilverRate = "₹ ${result.data.silverFutureSell}"
                    val currentTime =
                            SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())
                    views.setTextViewText(R.id.gold_rate, formattedGoldRate)
                    views.setTextViewText(R.id.silver_rate, formattedSilverRate)
                    views.setTextViewText(R.id.rates_updated_time, currentTime)
                }
                is RatesRepository.Result.Error -> {
                    views.setTextViewText(R.id.gold_rate, "₹ --")
                    views.setTextViewText(R.id.silver_rate, "₹ --")
                    println("Error fetching rates: ${result.errorMessage}")
                }
            }
            views.setViewVisibility(R.id.refresh_progress_image, View.GONE)
            views.setViewVisibility(R.id.refresh_button, View.VISIBLE)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    private fun getRefreshPendingIntent(context: Context): PendingIntent {
        val refreshIntent =
                Intent(context, RatesWidgetProvider::class.java).apply {
                    action = ACTION_UPDATE_WIDGET
                    component =
                            android.content.ComponentName(context, RatesWidgetProvider::class.java)
                }
        val flags =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
        return PendingIntent.getBroadcast(context, 0, refreshIntent, flags)
    }
    private fun scheduleNextUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = getRefreshPendingIntent(context)
        val triggerAtMillis = System.currentTimeMillis() + REFRESH_INTERVAL
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()
        ) {
            alarmManager.set(AlarmManager.RTC, triggerAtMillis, pendingIntent)
        } else {
            alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
            )
        }
    }
    private fun cancelScheduledUpdates(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = getRefreshPendingIntent(context)
        alarmManager.cancel(pendingIntent)
    }
}
