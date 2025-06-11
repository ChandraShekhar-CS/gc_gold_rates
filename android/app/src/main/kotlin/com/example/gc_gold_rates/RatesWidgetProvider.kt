import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class RatesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Loop through all active widgets
        for (appWidgetId in appWidgetIds) {
            try {
                // Get the data saved by your Flutter app
                val widgetData = HomeWidgetPlugin.getData(context)

                // Extract all the data points, providing default values
                val goldRate = widgetData.getString("gold_rate", "...")
                val silverRate = widgetData.getString("silver_rate", "...")
                val timestamp = widgetData.getString("widget_timestamp", "")

                // Create the RemoteViews object for your widget layout
                val views = RemoteViews(context.packageName, R.layout.widget_layout)

                // Update all the text views in your new widget layout
                views.setTextViewText(R.id.gold_rate, goldRate)
                views.setTextViewText(R.id.silver_rate, silverRate)
                views.setTextViewText(R.id.widget_timestamp, timestamp)

                // Instruct the AppWidgetManager to update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e("RatesWidgetProvider", "Widget update failed", e)
            }
        }
    }
}