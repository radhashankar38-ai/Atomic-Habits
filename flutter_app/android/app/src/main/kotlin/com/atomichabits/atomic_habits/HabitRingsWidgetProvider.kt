package com.atomichabits.atomic_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.util.Locale
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

class HabitRingsWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_NEXT_CHUNK, ACTION_PREV_CHUNK -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID
                )
                val delta = if (intent.action == ACTION_NEXT_CHUNK) 1 else -1
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val habits = WidgetStore.loadActiveHabits(context)
                    val totalChunks = (habits.size + 2) / 3
                    if (totalChunks > 1) {
                        val cur = WidgetStore.getRingsPage(context, widgetId)
                        val next = ((cur + delta) % totalChunks + totalChunks) % totalChunks
                        WidgetStore.setRingsPage(context, widgetId, next)
                    }
                    updateAppWidget(
                        context,
                        AppWidgetManager.getInstance(context),
                        widgetId
                    )
                }
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) {
            WidgetStore.clearWidgetPrefs(context, id)
        }
    }

    companion object {
        const val PREFS_NAME = WidgetStore.PREFS_NAME
        const val KEY_PAYLOAD = WidgetStore.KEY_PAYLOAD
        private const val ACTION_NEXT_CHUNK = "com.atomichabits.atomic_habits.ACTION_NEXT_RINGS_CHUNK"
        private const val ACTION_PREV_CHUNK = "com.atomichabits.atomic_habits.ACTION_PREV_RINGS_CHUNK"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, HabitRingsWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
        }

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val allHabits = WidgetStore.loadActiveHabits(context)
            val chunks = allHabits.chunked(3)
            val views = RemoteViews(context.packageName, R.layout.widget_habit_rings)

            val launchIntent = WidgetStore.buildOpenTabPendingIntent(
                context,
                requestCode = 1000 + appWidgetId,
                tab = "home"
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            views.setOnClickPendingIntent(R.id.widget_rings_right_area, launchIntent)

            if (chunks.isEmpty()) {
                views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                views.setViewVisibility(R.id.widget_habits_column, View.GONE)
                views.setImageViewBitmap(
                    R.id.widget_rings_image,
                    renderRingsBitmap(emptyList(), sizePx = 280)
                )
                views.setOnClickPendingIntent(R.id.widget_rings_image, launchIntent)
            } else {
                views.setViewVisibility(R.id.widget_empty_text, View.GONE)
                views.setViewVisibility(R.id.widget_habits_column, View.VISIBLE)

                val savedPage = WidgetStore.getRingsPage(context, appWidgetId)
                val pageIndex = savedPage % chunks.size
                if (pageIndex != savedPage) {
                    WidgetStore.setRingsPage(context, appWidgetId, pageIndex)
                }
                val chunk = chunks[pageIndex]

                // Crisp 280x280 bitmap (~313 KB) stays safely below Android's Binder IPC limit.
                views.setImageViewBitmap(
                    R.id.widget_rings_image,
                    renderRingsBitmap(chunk, sizePx = 280)
                )

                val totalDone = allHabits.count { it.doneToday }
                val totalActive = allHabits.size
                val statusText = if (totalDone == totalActive) {
                    "ALL $totalActive DONE"
                } else {
                    "$totalDone/$totalActive TODAY"
                }
                views.setTextViewText(R.id.widget_rings_today_pill, statusText)
                views.setTextColor(
                    R.id.widget_rings_today_pill,
                    if (totalDone == totalActive) 0xFF34C759.toInt() else 0xFF0A84FF.toInt()
                )

                if (chunks.size > 1) {
                    views.setViewVisibility(R.id.widget_rings_pager, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_rings_page_label,
                        "${pageIndex + 1}/${chunks.size}"
                    )

                    val prevIntent = Intent(context, HabitRingsWidgetProvider::class.java).apply {
                        action = ACTION_PREV_CHUNK
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val nextIntent = Intent(context, HabitRingsWidgetProvider::class.java).apply {
                        action = ACTION_NEXT_CHUNK
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val nextPending = PendingIntent.getBroadcast(
                        context,
                        3000 + appWidgetId,
                        nextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
                    )
                    views.setOnClickPendingIntent(
                        R.id.widget_rings_prev_btn,
                        PendingIntent.getBroadcast(
                            context,
                            2000 + appWidgetId,
                            prevIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
                        )
                    )
                    views.setOnClickPendingIntent(R.id.widget_rings_next_btn, nextPending)
                    views.setOnClickPendingIntent(R.id.widget_rings_image, nextPending)
                } else {
                    views.setViewVisibility(R.id.widget_rings_pager, View.GONE)
                    views.setOnClickPendingIntent(R.id.widget_rings_image, launchIntent)
                }

                val slots = arrayOf(
                    SlotIds(
                        R.id.widget_habit_1,
                        R.id.widget_habit_1_name,
                        R.id.widget_habit_1_done_icon,
                        R.id.widget_habit_1_cat_row,
                        R.id.widget_habit_1_cat_icon,
                        R.id.widget_habit_1_cat_label
                    ),
                    SlotIds(
                        R.id.widget_habit_2,
                        R.id.widget_habit_2_name,
                        R.id.widget_habit_2_done_icon,
                        R.id.widget_habit_2_cat_row,
                        R.id.widget_habit_2_cat_icon,
                        R.id.widget_habit_2_cat_label
                    ),
                    SlotIds(
                        R.id.widget_habit_3,
                        R.id.widget_habit_3_name,
                        R.id.widget_habit_3_done_icon,
                        R.id.widget_habit_3_cat_row,
                        R.id.widget_habit_3_cat_icon,
                        R.id.widget_habit_3_cat_label
                    )
                )

                for (i in slots.indices) {
                    val slot = slots[i]
                    if (i < chunk.size) {
                        val habit = chunk[i]
                        views.setViewVisibility(slot.container, View.VISIBLE)
                        views.setTextViewText(slot.name, habit.name.uppercase(Locale.US))
                        views.setTextColor(slot.name, habit.colorInt)
                        views.setViewVisibility(
                            slot.doneIcon,
                            if (habit.doneToday) View.VISIBLE else View.GONE
                        )

                        val catDrawable = WidgetStore.resolveCategoryDrawable(habit.category)
                        if (catDrawable != null && habit.categoryLabel.isNotEmpty()) {
                            views.setViewVisibility(slot.catRow, View.VISIBLE)
                            views.setImageViewResource(slot.catIcon, catDrawable)
                            views.setTextViewText(
                                slot.catLabel,
                                habit.categoryLabel.uppercase(Locale.US)
                            )
                        } else {
                            views.setViewVisibility(slot.catRow, View.GONE)
                        }
                    } else {
                        views.setViewVisibility(slot.container, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private data class SlotIds(
            val container: Int,
            val name: Int,
            val doneIcon: Int,
            val catRow: Int,
            val catIcon: Int,
            val catLabel: Int
        )

        internal fun renderRingsBitmap(
            habits: List<WidgetStore.WidgetHabit>,
            sizePx: Int
        ): Bitmap {
            val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val center = sizePx / 2f
            val strokeWidth = sizePx * 0.088f
            val outerGlowBlur = sizePx * 0.024f

            val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
            }

            val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth * 1.05f
                strokeCap = Paint.Cap.ROUND
                maskFilter = BlurMaskFilter(outerGlowBlur, BlurMaskFilter.Blur.NORMAL)
            }

            val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                strokeCap = Paint.Cap.ROUND
            }

            val tipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
            }

            if (habits.isEmpty()) {
                val ghostColor = 0xFFFFFFFF.toInt()
                for (i in 0 until 3) {
                    val radius = sizePx * ((43.5f - (i * 10.2f)) / 100f)
                    trackPaint.color = WidgetStore.colorWithAlpha(ghostColor, 14)
                    canvas.drawCircle(center, center, radius, trackPaint)
                }
                return bitmap
            }

            val count = min(3, habits.size)
            for (i in 0 until count) {
                val habit = habits[i]
                val radiusRatio = (43.5f - (i * 10.2f)) / 100f
                val radius = sizePx * radiusRatio
                val rect = RectF(
                    center - radius,
                    center - radius,
                    center + radius,
                    center + radius
                )

                trackPaint.color = WidgetStore.colorWithAlpha(habit.colorInt, 32)
                canvas.drawCircle(center, center, radius, trackPaint)

                if (habit.progress > 0.001f) {
                    val clamped = habit.progress.coerceIn(0f, 1f)
                    val sweepAngle = 360f * clamped

                    glowPaint.color = WidgetStore.colorWithAlpha(habit.colorInt, 88)
                    canvas.drawArc(rect, -90f, sweepAngle, false, glowPaint)

                    progressPaint.color = habit.colorInt
                    canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)

                    val endRad = Math.toRadians((-90f + sweepAngle).toDouble())
                    val tipX = center + (radius * cos(endRad)).toFloat()
                    val tipY = center + (radius * sin(endRad)).toFloat()
                    tipPaint.color = 0x55FFFFFF
                    canvas.drawCircle(tipX, tipY, strokeWidth * 0.24f, tipPaint)
                }
            }

            return bitmap
        }
    }
}
