package com.example.lifemeter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Calendar
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * "Your life in weeks" home-screen widget: one row per year, 52 squares per
 * row. Lived weeks are cobalt, weeks with a memory pink, this week a larger
 * pink square with a ring, the rest pale (matching lib/widgets/weeks_grid.dart).
 *
 * Each state is a separate white alpha mask tinted in XML with
 * `@color/lm_weeks_*`, so the launcher re-themes it for light/dark mode
 * without a redraw. Reads the same timestamps as [LifeWidgetProvider].
 */
class LifeWeeksWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager.getAppWidgetOptions(id), widgetData))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, newOptions, HomeWidgetPlugin.getData(context)),
        )
    }

    private fun buildViews(context: Context, options: Bundle, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.weeks_widget)
        views.setOnClickPendingIntent(
            R.id.weeks_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val birth = data.getString(KEY_BIRTH, null)?.toLongOrNull()
        val end = data.getString(KEY_END, null)?.toLongOrNull()
        if (birth == null || end == null || end <= birth) {
            views.setViewVisibility(R.id.weeks_content, View.GONE)
            views.setViewVisibility(R.id.weeks_empty, View.VISIBLE)
            return views
        }
        views.setViewVisibility(R.id.weeks_content, View.VISIBLE)
        views.setViewVisibility(R.id.weeks_empty, View.GONE)

        val now = System.currentTimeMillis()
        val age = fullYears(birth, now)
        val week = weekOfYear(birth, now, age)
        val expectedYears = (end - birth) / YEAR_MS
        val rows = max(ceil(expectedYears).toInt(), age + 1)
        val left = max(0L, (end - now) / WEEK_MS)

        val integer = NumberFormat.getIntegerInstance()
        // Narrow (about 2 cells wide, beside another widget): one short title.
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val narrow = widthDp in 1 until NARROW_WIDTH_DP
        views.setViewVisibility(R.id.weeks_summary, if (narrow) View.GONE else View.VISIBLE)
        views.setTextViewText(
            R.id.weeks_title,
            if (narrow) {
                context.getString(R.string.weeks_widget_title_short, integer.format(left))
            } else {
                context.getString(R.string.weeks_widget_title)
            },
        )
        views.setTextViewText(
            R.id.weeks_summary,
            context.getString(
                R.string.weeks_widget_summary,
                integer.format(age * WEEKS_PER_YEAR + week + 1),
                integer.format(left),
            ),
        )

        val marked = data.getString(KEY_MARKED, null).orEmpty()
            .split(',').mapNotNull { it.trim().toIntOrNull() }.toSet()
        val masks = drawMasks(context, options, rows, age, week, marked)
        LAYERS.forEachIndexed { i, id -> views.setImageViewBitmap(id, masks[i]) }
        return views
    }

    /**
     * Masks in [LAYERS] order: future, lived, marked, ring, now. Sized to
     * the widget's portrait width so squares stay square and crisp.
     */
    private fun drawMasks(
        context: Context,
        options: Bundle,
        rows: Int,
        age: Int,
        week: Int,
        marked: Set<Int>,
    ): List<Bitmap> {
        val density = context.resources.displayMetrics.density
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            .takeIf { it > 0 } ?: DEFAULT_WIDTH_DP
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            .takeIf { it > 0 } ?: DEFAULT_HEIGHT_DP
        // Fit the grid inside the space left after padding and the header.
        val availW = max(1f, (widthDp - 28) * density)
        val availH = max(1f, (heightDp - 28 - 34) * density)
        val cell = max(2f, min(availW / WEEKS_PER_YEAR, availH / rows))
        val width = max(1, (cell * WEEKS_PER_YEAR).roundToInt())
        val height = max(1, (cell * rows).roundToInt())

        val bitmaps = List(LAYERS.size) { Bitmap.createBitmap(width, height, Bitmap.Config.ALPHA_8) }
        val canvases = bitmaps.map { Canvas(it) }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
        val side = cell * 0.78f
        val inset = (cell - side) / 2
        val radius = min(2 * density, side * 0.3f)
        val nowIndex = age * WEEKS_PER_YEAR + week

        fun square(layer: Int, x: Float, top: Float, grow: Float) =
            canvases[layer].drawRoundRect(
                x - grow, top - grow, x + side + grow, top + side + grow, radius, radius, fill,
            )

        for (y in 0 until rows) {
            for (w in 0 until WEEKS_PER_YEAR) {
                val index = y * WEEKS_PER_YEAR + w
                val x = w * cell + inset
                val top = y * cell + inset
                when {
                    index == nowIndex -> {
                        // Larger, with a ring in the background colour, so it
                        // stands out without relying on colour alone.
                        square(RING, x, top, cell * 0.25f + 2 * density)
                        square(NOW, x, top, cell * 0.25f)
                    }
                    index < nowIndex && index in marked -> square(MARKED, x, top, side * 0.12f)
                    index < nowIndex -> square(LIVED, x, top, 0f)
                    else -> square(FUTURE, x, top, 0f)
                }
            }
        }
        return bitmaps
    }

    private fun fullYears(birth: Long, now: Long): Int {
        val b = Calendar.getInstance().apply { timeInMillis = birth }
        val n = Calendar.getInstance().apply { timeInMillis = now }
        var years = n.get(Calendar.YEAR) - b.get(Calendar.YEAR)
        val beforeBirthday = n.get(Calendar.MONTH) < b.get(Calendar.MONTH) ||
            (n.get(Calendar.MONTH) == b.get(Calendar.MONTH) &&
                n.get(Calendar.DAY_OF_MONTH) < b.get(Calendar.DAY_OF_MONTH))
        if (beforeBirthday) years--
        return max(0, years)
    }

    /** Week (0–51) within the current year of life, as the app counts it. */
    private fun weekOfYear(birth: Long, now: Long, age: Int): Int {
        val b = Calendar.getInstance().apply { timeInMillis = birth }
        val last = Calendar.getInstance().apply {
            timeInMillis = birth
            add(Calendar.YEAR, age)
            set(Calendar.HOUR_OF_DAY, b.get(Calendar.HOUR_OF_DAY))
        }
        return ((now - last.timeInMillis) / WEEK_MS).toInt().coerceIn(0, WEEKS_PER_YEAR - 1)
    }

    companion object {
        private const val KEY_BIRTH = "lm_birth_ms"
        private const val KEY_END = "lm_end_ms"
        private const val DAY_MS = 86_400_000L
        private const val WEEK_MS = 7 * DAY_MS
        private const val YEAR_MS = 365.2425 * DAY_MS
        private const val WEEKS_PER_YEAR = 52
        private const val DEFAULT_WIDTH_DP = 300
        private const val NARROW_WIDTH_DP = 220
        private const val DEFAULT_HEIGHT_DP = 300

        private const val KEY_MARKED = "lm_marked"
        private const val FUTURE = 0
        private const val LIVED = 1
        private const val MARKED = 2
        private const val RING = 3
        private const val NOW = 4

        private val LAYERS = intArrayOf(
            R.id.weeks_future,
            R.id.weeks_lived,
            R.id.weeks_marked,
            R.id.weeks_ring,
            R.id.weeks_now_mark,
        ).toList()
    }
}
