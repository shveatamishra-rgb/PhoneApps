package app.bhaktiangan.core.media

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.content.FileProvider
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.model.Verse
import java.io.File

/**
 * Renders a shareable Gita-verse card as a Bitmap (Android port of the iOS `VerseShareCard`):
 * a Krishna backdrop + legibility scrim + Om + Sanskrit + gold rule + meaning + source +
 * brand, in a gold frame. Devanagari is shaped by Android's text stack (Canvas/StaticLayout),
 * which handles conjuncts correctly. 1080x1350 (2x of the iOS 540x675).
 */
object VerseShareCard {

    private const val W = 1080
    private const val H = 1350
    private val GOLD = Color.rgb(204, 163, 74)
    private val GOLD_LIGHT = Color.rgb(230, 212, 166)

    // iOS background order: r_krishna_gita then bundled Krishna; Android ships day4/day23_krishna.
    private val bgNames = listOf("r_krishna_gita", "day4_krishna", "day23_krishna", "day42_krishna")

    fun render(context: Context, verse: Verse, lang: Lang): Bitmap {
        val bmp = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)

        // Backdrop: Krishna art (center-crop) or a plum->teal gradient.
        val bg = loadBackground(context)
        if (bg != null) {
            val scale = maxOf(W.toFloat() / bg.width, H.toFloat() / bg.height)
            val dw = (bg.width * scale).toInt(); val dh = (bg.height * scale).toInt()
            val left = (W - dw) / 2; val top = (H - dh) / 2
            c.drawBitmap(bg, null, Rect(left, top, left + dw, top + dh), Paint(Paint.FILTER_BITMAP_FLAG))
        } else {
            val p = Paint().apply { shader = LinearGradient(0f, 0f, 0f, H.toFloat(), Color.rgb(61, 20, 41), Color.rgb(20, 60, 60), Shader.TileMode.CLAMP) }
            c.drawRect(0f, 0f, W.toFloat(), H.toFloat(), p)
        }
        // Scrim for legibility.
        val scrim = Paint().apply {
            shader = LinearGradient(0f, 0f, 0f, H.toFloat(),
                intArrayOf(Color.argb((0.62f * 255).toInt(), 0, 0, 0), Color.argb((0.42f * 255).toInt(), 0, 0, 0), Color.argb((0.72f * 255).toInt(), 0, 0, 0)),
                floatArrayOf(0f, 0.5f, 1f), Shader.TileMode.CLAMP)
        }
        c.drawRect(0f, 0f, W.toFloat(), H.toFloat(), scrim)

        val serif = Typeface.create(Typeface.SERIF, Typeface.NORMAL)
        val serifBold = Typeface.create(Typeface.SERIF, Typeface.BOLD)
        val sans = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        val pad = 88
        val contentW = W - pad * 2

        val om = textLayout("ॐ", serif, 80f, Color.argb((0.92f * 255).toInt(), 255, 255, 255), contentW)
        val sanskrit = textLayout(verse.sanskrit, serifBold, 54f, Color.WHITE, contentW, lineSpacingMult = 1.25f)
        val meaning = textLayout(verse.meaning(lang), serif, 40f, Color.argb((0.96f * 255).toInt(), 255, 255, 255), contentW, lineSpacingMult = 1.15f)
        val source = textLayout(verse.source(lang), sans, 32f, GOLD_LIGHT, contentW)
        val brand = textLayout(if (lang == Lang.HI) "भक्ति आँगन" else "Bhakti Angan", sans, 34f, Color.argb((0.92f * 255).toInt(), 255, 255, 255), contentW)

        val ruleH = 4; val gap = 34
        val blockH = om.height + gap + sanskrit.height + gap + ruleH + gap + meaning.height + gap + source.height
        var y = (H - blockH) / 2f - 40   // slight upward bias; brand sits near the bottom

        y = drawCentered(c, om, y) + gap
        y = drawCentered(c, sanskrit, y) + gap
        // gold rule
        val rp = Paint().apply { color = GOLD; strokeWidth = ruleH.toFloat() }
        c.drawRect((W - 120) / 2f, y, (W + 120) / 2f, y + ruleH, rp)
        y += ruleH + gap
        y = drawCentered(c, meaning, y) + gap
        drawCentered(c, source, y)

        // brand near the bottom
        drawCentered(c, brand, H - pad - brand.height.toFloat())

        // gold frame
        val fp = Paint().apply { style = Paint.Style.STROKE; color = Color.argb((0.55f * 255).toInt(), 204, 163, 74); strokeWidth = 3f; isAntiAlias = true }
        c.drawRect(RectF(28f, 28f, W - 28f, H - 28f), fp)
        return bmp
    }

    private fun loadBackground(context: Context): Bitmap? {
        for (n in bgNames) {
            val id = context.resources.getIdentifier(n, "drawable", context.packageName)
            if (id != 0) return runCatching { BitmapFactory.decodeResource(context.resources, id) }.getOrNull()
        }
        return null
    }

    private fun textLayout(text: String, tf: Typeface, sizePx: Float, color: Int, width: Int, lineSpacingMult: Float = 1.0f): StaticLayout {
        val tp = TextPaint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color; textSize = sizePx; typeface = tf }
        return StaticLayout.Builder.obtain(text, 0, text.length, tp, width)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setLineSpacing(0f, lineSpacingMult)
            .setIncludePad(false)
            .build()
    }

    private fun drawCentered(c: Canvas, layout: StaticLayout, top: Float): Float {
        c.save(); c.translate((W - layout.width) / 2f, top); layout.draw(c); c.restore()
        return top + layout.height
    }

    /** Renders the card and fires a share sheet (image + text). */
    fun share(context: Context, verse: Verse, lang: Lang) {
        val bmp = render(context, verse, lang)
        val dir = File(context.cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "gita_verse.png")
        file.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, verse.shareText(lang))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(intent, null).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
    }
}
