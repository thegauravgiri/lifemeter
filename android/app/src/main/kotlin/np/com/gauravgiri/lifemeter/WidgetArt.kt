package np.com.gauravgiri.lifemeter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.util.TypedValue
import java.util.Calendar
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Shared drawing for LifeMeter's widgets. Everything is a white alpha mask
 * tinted in XML (`tintMode="src_in"`), so the launcher re-themes it for
 * light/dark mode without a redraw.
 */
object WidgetArt {
    const val KEY_BIRTH = "lm_birth_ms"
    const val KEY_END = "lm_end_ms"
    const val DAY_MS = 86_400_000L
    const val WEEK_MS = 7 * DAY_MS
    const val YEAR_MS = 365.2425 * DAY_MS
    const val WEEKS_PER_YEAR = 52

    /** Big Shoulders Display ships in the Flutter bundle; fall back to condensed bold. */
    private const val DISPLAY_ASSET = "flutter_assets/assets/fonts/BigShouldersDisplay-900.ttf"

    @Volatile private var displayCache: Typeface? = null

    fun display(context: Context): Typeface =
        displayCache ?: runCatching { Typeface.createFromAsset(context.assets, DISPLAY_ASSET) }
            .getOrElse { Typeface.create("sans-serif-condensed", Typeface.BOLD) }
            .also { displayCache = it }

    /** Life Clock: [fraction] of a life mapped onto one day, as ("10:48", "AM"). */
    fun lifeClock(fraction: Double): Pair<String, String> {
        val minutes = (fraction.coerceIn(0.0, 1.0) * 1440 + 1e-6).toInt().coerceIn(0, 1439)
        val h = minutes / 60
        val m = minutes % 60
        val h12 = if (h % 12 == 0) 12 else h % 12
        return "$h12:${m.toString().padStart(2, '0')}" to (if (h < 12) "AM" else "PM")
    }

    /** Poster numerals as a mask: [big] at [sp], then [small] at 40% beside it. */
    fun drawNumber(context: Context, big: String, sp: Float, small: String? = null): Bitmap {
        val metrics = context.resources.displayMetrics
        val size = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, metrics)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = display(context)
            textSize = size
            letterSpacing = -0.01f
        }
        val smallPaint = Paint(paint).apply { textSize = size * 0.4f; letterSpacing = 0f }
        val bounds = android.graphics.Rect()
        paint.getTextBounds(big, 0, big.length, bounds)
        val gap = if (small == null) 0f else size * 0.06f
        val bigW = paint.measureText(big)
        val width = max(1, ceil(bigW + gap + (small?.let { smallPaint.measureText(it) } ?: 0f)).toInt() + 2)
        val top = bounds.top.toFloat()
        val height = max(1, ceil(bounds.bottom - top).toInt() + 2)
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also {
            val canvas = Canvas(it)
            canvas.drawText(big, 0f, -top, paint)
            if (small != null) canvas.drawText(small, bigW + gap, -top, smallPaint)
        }
    }

    /** The sun path: (line mask, sun mask), sun at [fraction] of the arc. */
    fun sunArc(context: Context, widthDp: Int, heightDp: Int, fraction: Double): Pair<Bitmap, Bitmap> {
        val d = context.resources.displayMetrics.density
        val w = max(1, (widthDp * d).toInt())
        val h = max(1, (heightDp * d).toInt())
        val line = Bitmap.createBitmap(w, h, Bitmap.Config.ALPHA_8)
        val sun = Bitmap.createBitmap(w, h, Bitmap.Config.ALPHA_8)
        val sunR = min(8 * d, h * 0.2f)
        val horizon = h - d
        val rx = w / 2f - sunR
        val ry = h - sunR - 2 * d
        val oval = RectF(w / 2f - rx, horizon - ry, w / 2f + rx, horizon + ry)
        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 2 * d
            strokeCap = Paint.Cap.ROUND
        }
        val c = Canvas(line)
        val sweep = (180 * fraction.coerceIn(0.0, 1.0)).toFloat()
        stroke.alpha = 90
        c.drawArc(oval, 180f, 180f, false, stroke)
        c.drawLine(0f, horizon, w.toFloat(), horizon, stroke)
        stroke.alpha = 255
        if (sweep > 0) c.drawArc(oval, 180f, sweep, false, stroke)
        val a = PI + PI * fraction.coerceIn(0.0, 1.0)
        val x = (w / 2f + rx * cos(a)).toFloat()
        val y = (horizon + ry * sin(a)).toFloat()
        Canvas(sun).drawCircle(x, y, sunR, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE })
        return line to sun
    }

    fun fullYears(birth: Long, now: Long): Int {
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
    fun weekOfYear(birth: Long, now: Long): Int {
        val age = fullYears(birth, now)
        val last = Calendar.getInstance().apply {
            timeInMillis = birth
            add(Calendar.YEAR, age)
        }
        return ((now - last.timeInMillis) / WEEK_MS).toInt().coerceIn(0, WEEKS_PER_YEAR - 1)
    }
}
