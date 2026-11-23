package np.com.gauravgiri.lifemeter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The Life Clock widget: "10:48 AM in your life" on cobalt, with the pink
 * sun on its arc. Computed from the stored birth and end timestamps, so it
 * moves on its own between app launches.
 */
class LifeClockWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, build(context, appWidgetManager.getAppWidgetOptions(id), widgetData))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        appWidgetManager.updateAppWidget(appWidgetId, build(context, newOptions, HomeWidgetPlugin.getData(context)))
    }

    private fun build(context: Context, options: Bundle, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.life_clock_widget)
        views.setOnClickPendingIntent(
            R.id.clock_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        val birth = data.getString(WidgetArt.KEY_BIRTH, null)?.toLongOrNull()
        val end = data.getString(WidgetArt.KEY_END, null)?.toLongOrNull()
        if (birth == null || end == null || end <= birth) {
            views.setViewVisibility(R.id.clock_content, View.GONE)
            views.setViewVisibility(R.id.clock_empty, View.VISIBLE)
            return views
        }
        views.setViewVisibility(R.id.clock_content, View.VISIBLE)
        views.setViewVisibility(R.id.clock_empty, View.GONE)

        val now = System.currentTimeMillis()
        val fraction = ((now - birth).toDouble() / (end - birth)).coerceIn(0.0, 1.0)
        val bonus = now > end
        val (digits, period) = WidgetArt.lifeClock(fraction)
        val number = if (bonus) WidgetArt.drawNumber(context, "Bonus", 40f)
        else WidgetArt.drawNumber(context, digits, 46f, period)
        views.setImageViewBitmap(R.id.clock_time, number)
        val label = context.getString(if (bonus) R.string.widget_bonus_time else R.string.widget_in_your_life)
        views.setContentDescription(R.id.clock_time, if (bonus) label else "$digits $period $label")
        views.setTextViewText(R.id.clock_label, label)

        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).takeIf { it > 0 } ?: 150
        val (line, sun) = WidgetArt.sunArc(context, (widthDp - 32).coerceAtLeast(60), 34, fraction)
        views.setImageViewBitmap(R.id.clock_arc, line)
        views.setImageViewBitmap(R.id.clock_sun, sun)
        return views
    }
}
