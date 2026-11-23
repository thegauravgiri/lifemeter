package np.com.gauravgiri.lifemeter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Countdown widget: the count (or the Life Clock) set in Big Shoulders on a
 * cobalt tile, percent lived, this year of life as 52 week squares, and
 * the user's "one thing".
 *
 * The Flutter app stores birth and estimated-end timestamps (see
 * lib/services/widget_sync.dart); everything else is computed here, so the
 * widget stays current on each periodic update without opening the app.
 *
 * Graphics are drawn as white alpha masks and tinted in XML with
 * `@color/lm_widget_*`. The launcher resolves those colours against the
 * current light/dark mode, so the widget re-themes itself without a redraw:
 * cobalt in both themes, with a slightly brighter pink "now" at night.
 */
class LifeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, widgetData))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val data = HomeWidgetPlugin.getData(context)
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetManager, appWidgetId, data),
        )
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.life_widget)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val birth = data.getString(KEY_BIRTH, null)?.toLongOrNull()
        val end = data.getString(KEY_END, null)?.toLongOrNull()
        if (birth == null || end == null || end <= birth) {
            views.setViewVisibility(R.id.content, View.GONE)
            views.setViewVisibility(R.id.empty, View.VISIBLE)
            return views
        }
        views.setViewVisibility(R.id.content, View.VISIBLE)
        views.setViewVisibility(R.id.empty, View.GONE)

        val now = System.currentTimeMillis()
        val total = end - birth
        val lived = (now - birth).coerceIn(0L, total)
        val fraction = lived.toDouble() / total
        val bonus = now > end
        val unit = data.getString(KEY_UNIT, null) ?: UNIT_SLIDESHOW
        val remaining = end - now
        val integer = NumberFormat.getIntegerInstance()

        // Narrow (about 2 cells wide, so two widgets fit side by side):
        // drop the brand word and shorten long labels.
        val options = manager.getAppWidgetOptions(widgetId)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val narrow = widthDp in 1 until NARROW_WIDTH_DP
        views.setViewVisibility(R.id.brand_text, if (narrow) View.INVISIBLE else View.VISIBLE)
        val secondsLabel = context.getString(
            if (narrow) R.string.widget_countdown_short else R.string.widget_countdown_left,
        )
        val chronoSp = if (narrow) 22f else 34f
        views.setTextViewTextSize(R.id.countdown, android.util.TypedValue.COMPLEX_UNIT_SP, chronoSp)
        views.setTextViewTextSize(R.id.slide_seconds_num, android.util.TypedValue.COMPLEX_UNIT_SP, chronoSp)

        val slideshow = unit == UNIT_SLIDESHOW && !bonus
        views.setViewVisibility(R.id.slides, if (slideshow) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.single, if (slideshow) View.GONE else View.VISIBLE)
        if (slideshow) {
            fillSlides(context, views, fraction, remaining, secondsLabel)
        } else if (unit == UNIT_SECONDS && !bonus) {
            // A system Chronometer counts down live; widget updates alone
            // can't tick every second.
            views.setViewVisibility(R.id.weeks_left, View.GONE)
            views.setViewVisibility(R.id.countdown, View.VISIBLE)
            views.setChronometer(R.id.countdown, SystemClock.elapsedRealtime() + remaining, null, true)
            views.setChronometerCountDown(R.id.countdown, true)
            views.setTextViewText(R.id.label, secondsLabel)
        } else {
            // Never show 0: past the estimate, count bonus weeks from one.
            val (digits, period) = WidgetArt.lifeClock(fraction)
            val (text, labelRes) = when {
                bonus -> integer.format(max(1L, (now - end) / WEEK_MS)) to R.string.widget_bonus_weeks
                unit == UNIT_CLOCK -> "$digits $period" to R.string.widget_in_your_life
                unit == UNIT_YEARS -> String.format(java.util.Locale.getDefault(), "%.1f", remaining / YEAR_MS) to R.string.widget_years_left
                unit == UNIT_DAYS -> integer.format(remaining / DAY_MS) to R.string.widget_days_left
                unit == UNIT_HOURS -> integer.format(remaining / HOUR_MS) to R.string.widget_hours_left
                else -> integer.format(remaining / WEEK_MS) to R.string.widget_weeks_left
            }
            val label = context.getString(labelRes)
            views.setViewVisibility(R.id.countdown, View.GONE)
            views.setViewVisibility(R.id.weeks_left, View.VISIBLE)
            val bitmap = if (unit == UNIT_CLOCK && !bonus) {
                WidgetArt.drawNumber(context, digits, NUMBER_SP, period)
            } else {
                WidgetArt.drawNumber(context, text, NUMBER_SP)
            }
            views.setImageViewBitmap(R.id.weeks_left, bitmap)
            views.setContentDescription(R.id.weeks_left, "$text $label")
            views.setTextViewText(R.id.label, label)
        }
        views.setTextViewText(
            R.id.percent,
            context.getString(
                R.string.widget_percent_lived,
                (fraction * 100).roundToInt().toString(),
            ),
        )

        // Short widgets show just the number; taller ones add the progress
        // bar, and taller still the one thing.
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        val showBar = !bonus && (heightDp == 0 || heightDp >= BAR_HEIGHT_DP)
        val showIntention = heightDp == 0 || heightDp >= INTENTION_HEIGHT_DP

        val intention = data.getString(KEY_INTENTION, null).orEmpty().trim()
        if (intention.isEmpty() || !showIntention) {
            views.setViewVisibility(R.id.intention, View.GONE)
        } else {
            views.setViewVisibility(R.id.intention, View.VISIBLE)
            views.setTextViewText(R.id.intention, context.getString(R.string.widget_one_thing, intention))
        }

        if (!showBar) {
            views.setViewVisibility(R.id.progress, View.GONE)
        } else {
            views.setViewVisibility(R.id.progress, View.VISIBLE)
            val masks = drawProgress(context, widthDp, fraction)
            views.setImageViewBitmap(R.id.progress_track, masks.track)
            views.setImageViewBitmap(R.id.progress_fill, masks.fill)
            views.setImageViewBitmap(R.id.progress_knob, masks.knob)
        }
        return views
    }

    /** One slide per time view; the ViewFlipper rotates them on its own. */
    private fun fillSlides(
        context: Context,
        views: RemoteViews,
        fraction: Double,
        remaining: Long,
        secondsLabel: String,
    ) {
        val integer = NumberFormat.getIntegerInstance()
        val (digits, period) = WidgetArt.lifeClock(fraction)
        views.setImageViewBitmap(R.id.slide_clock_num, WidgetArt.drawNumber(context, digits, NUMBER_SP, period))
        views.setTextViewText(R.id.slide_clock_label, context.getString(R.string.widget_in_your_life))
        val counts = listOf(
            Triple(R.id.slide_years_num, R.id.slide_years_label,
                String.format(java.util.Locale.getDefault(), "%.1f", remaining / YEAR_MS) to R.string.widget_years_left),
            Triple(R.id.slide_weeks_num, R.id.slide_weeks_label,
                integer.format(remaining / WEEK_MS) to R.string.widget_weeks_left),
            Triple(R.id.slide_days_num, R.id.slide_days_label,
                integer.format(remaining / DAY_MS) to R.string.widget_days_left),
            Triple(R.id.slide_hours_num, R.id.slide_hours_label,
                integer.format(remaining / HOUR_MS) to R.string.widget_hours_left),
        )
        for ((numId, labelId, value) in counts) {
            val (text, labelRes) = value
            views.setImageViewBitmap(numId, WidgetArt.drawNumber(context, text, NUMBER_SP))
            views.setContentDescription(numId, "$text ${context.getString(labelRes)}")
            views.setTextViewText(labelId, context.getString(labelRes))
        }
        views.setChronometer(R.id.slide_seconds_num, SystemClock.elapsedRealtime() + remaining, null, true)
        views.setChronometerCountDown(R.id.slide_seconds_num, true)
        views.setTextViewText(R.id.slide_seconds_label, secondsLabel)
    }

    private class ProgressMasks(val track: Bitmap, val fill: Bitmap, val knob: Bitmap)

    /**
     * The life meter, as in the app: a thick rounded bar, filled up to
     * [fraction], with a tall "now" knob ringed in the fill colour.
     */
    private fun drawProgress(context: Context, widthDp: Int, fraction: Double): ProgressMasks {
        val density = context.resources.displayMetrics.density
        // MIN_WIDTH is the portrait width; subtract 16dp padding on each side.
        val w = max(1, (((if (widthDp > 0) widthDp else DEFAULT_WIDTH_DP) - 32) * density).roundToInt())
        val h = max(1, (26 * density).roundToInt())
        fun blank() = Bitmap.createBitmap(w, h, Bitmap.Config.ALPHA_8)
        val track = blank()
        val fill = blank()
        val knob = blank()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }

        val bar = 12 * density
        val top = (h - bar) / 2
        val r = bar / 2
        val x = (w * fraction.toFloat()).coerceIn(r, w - r)
        Canvas(track).drawRoundRect(0f, top, w.toFloat(), top + bar, r, r, paint)
        val fillCanvas = Canvas(fill)
        fillCanvas.drawRoundRect(0f, top, x, top + bar, r, r, paint)

        // Knob: a ring in the fill colour, then the "now" pill on top.
        val kw = 8 * density
        val kh = h - 2 * density
        val ring = 2 * density
        fillCanvas.drawRoundRect(
            x - kw / 2 - ring, (h - kh) / 2 - ring + density,
            x + kw / 2 + ring, (h + kh) / 2 + ring - density,
            kw, kw, paint,
        )
        Canvas(knob).drawRoundRect(
            x - kw / 2, (h - kh) / 2 + density,
            x + kw / 2, (h + kh) / 2 - density,
            kw / 2, kw / 2, paint,
        )
        return ProgressMasks(track, fill, knob)
    }

    companion object {
        private const val KEY_BIRTH = "lm_birth_ms"
        private const val KEY_END = "lm_end_ms"
        private const val KEY_INTENTION = "lm_intention"
        private const val DAY_MS = 86_400_000L
        private const val WEEK_MS = 7 * DAY_MS
        private const val HOUR_MS = 3_600_000L
        private const val YEAR_MS = 365.2425 * DAY_MS
        private const val KEY_UNIT = "lm_unit"
        private const val UNIT_YEARS = "years"
        private const val UNIT_WEEKS = "weeks"
        private const val UNIT_DAYS = "days"
        private const val UNIT_HOURS = "hours"
        private const val UNIT_SECONDS = "seconds"
        private const val UNIT_CLOCK = "clock"
        private const val UNIT_SLIDESHOW = "slideshow"
        private const val WEEKS_PER_YEAR = 52
        private const val DEFAULT_WIDTH_DP = 320
        private const val NARROW_WIDTH_DP = 220
        private const val BAR_HEIGHT_DP = 120
        private const val INTENTION_HEIGHT_DP = 170
        private const val NUMBER_SP = 44f

    }
}
