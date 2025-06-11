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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RatesWidgetProvider : AppWidgetProvider() {

    // A custom scope for coroutines that will be cancelled when the provider is destroyed
    private val job = SupervisorJob()
    private val coroutineScope = CoroutineScope(Dispatchers.IO + job)

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.yourcompany.rateswidget.ACTION_UPDATE_WIDGET"
        // 1 minute in milliseconds (was 5 * 60 * 1000L)
        private const val REFRESH_INTERVAL = 1 * 60 * 1000L
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
            // Re-schedule the next update after a manual refresh
            scheduleNextUpdate(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Schedule the first update when the widget is enabled
        scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel all scheduled updates when the widget is disabled
        cancelScheduledUpdates(context)
        job.cancel() // Cancel the coroutine scope to prevent leaks
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        isRefreshAction: Boolean
    ) {
        val views = RemoteViews(context.packageName, R.layout.rates_widget_layout)

        // Set up the refresh button click intent
        views.setOnClickPendingIntent(R.id.refresh_button, getRefreshPendingIntent(context))

        // Show loading indicator and animation if it's a manual refresh or initial load
        if (isRefreshAction) {
            views.setViewVisibility(R.id.refresh_button, View.GONE)
            views.setViewVisibility(R.id.refresh_progress_image, View.VISIBLE) // Use ImageView for animation
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } else {
            // For periodic updates, ensure progress is hidden and button is visible initially
            views.setViewVisibility(R.id.refresh_button, View.VISIBLE)
            views.setViewVisibility(R.id.refresh_progress_image, View.GONE) // Use ImageView for animation
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // Fetch rates in a background coroutine
        coroutineScope.launch {
            fetchAndApplyRates(context, appWidgetManager, appWidgetId)
        }
    }

    private suspend fun fetchAndApplyRates(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val repository = RatesRepository()
        val result = repository.fetchExtendedRates()

        // Switch to the Main thread to update the UI
        withContext(Dispatchers.Main) {
            val views = RemoteViews(context.packageName, R.layout.rates_widget_layout)
            // Re-attach the click listener in case the RemoteViews was re-created
            views.setOnClickPendingIntent(R.id.refresh_button, getRefreshPendingIntent(context))

            when (result) {
                is RatesRepository.Result.Success -> {
                    val formattedGoldRate = "₹ ${result.data.gold995Sell}"
                    val formattedSilverRate = "₹ ${result.data.silverFutureSell}"
                    val currentTime = SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())

                    views.setTextViewText(R.id.gold_rate, formattedGoldRate)
                    views.setTextViewText(R.id.silver_rate, formattedSilverRate)
                    views.setTextViewText(R.id.rates_updated_time, currentTime)

                    // Removed setAnimation calls as RemoteViews do not support it directly
                }
                is RatesRepository.Result.Error -> {
                    views.setTextViewText(R.id.gold_rate, "₹ --")
                    views.setTextViewText(R.id.silver_rate, "₹ --")
                    // Log the error for debugging, or show a more prominent message to the user
                    println("Error fetching rates: ${result.errorMessage}")
                }
            }

            // Hide progress animation and show refresh button
            views.setViewVisibility(R.id.refresh_progress_image, View.GONE) // Use ImageView for animation
            views.setViewVisibility(R.id.refresh_button, View.VISIBLE)


            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getRefreshPendingIntent(context: Context): PendingIntent {
        val refreshIntent = Intent(context, RatesWidgetProvider::class.java).apply {
            action = ACTION_UPDATE_WIDGET
            // Explicitly set the component to ensure the broadcast is delivered
            component = android.content.ComponentName(context, RatesWidgetProvider::class.java)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
             // For Android 12+ where exact alarms permission might not be granted
             // Fallback to inexact alarm if exact alarms are not permitted
            alarmManager.set(AlarmManager.RTC, triggerAtMillis, pendingIntent)
        } else {
            // This works for all versions if permission is granted, and for older versions.
            // setExactAndAllowWhileIdle is crucial for reliable updates even in Doze mode
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
