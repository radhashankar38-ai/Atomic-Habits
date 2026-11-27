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
import android.widget.RemoteViews
import kotlin.math.max

class TimingWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_SET_TIMEFRAME) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            val tf = intent.getStringExtra(EXTRA_TIMEFRAME) ?: "week"
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                WidgetStore.setTimingTimeframe(context, widgetId, tf)
                updateAppWidget(
                    context,
                    AppWidgetManager.getInstance(context),
                    widgetId
                )
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

    companion object {
        private const val ACTION_SET_TIMEFRAME = "com.atomichabits.atomic_habits.ACTION_SET_TIMING_TIMEFRAME"
        private const val EXTRA_TIMEFRAME = "timeframe"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TimingWidgetProvider::class.java)
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
            val timeframe = WidgetStore.getTimingTimeframe(context, appWidgetId)
            val points = WidgetStore.loadTimingBars(context, timeframe)
            val views = RemoteViews(context.packageName, R.layout.widget_timing)

            bindTabPill(context, views, appWidgetId, R.id.widget_timing_tab_week, "week", timeframe == "week", 6100)
            bindTabPill(context, views, appWidgetId, R.id.widget_timing_tab_month, "month", timeframe == "month", 6200)
            bindTabPill(context, views, appWidgetId, R.id.widget_timing_tab_year, "year", timeframe == "year", 6300)

            val chartBitmap = renderTimingChartBitmap(points, widthPx = 640, heightPx = 230)
            views.setImageViewBitmap(R.id.widget_timing_chart_image, chartBitmap)

            val openProgressIntent = WidgetStore.buildOpenTabPendingIntent(
                context,
                requestCode = 6000 + appWidgetId,
                tab = "progress"
            )
            views.setOnClickPendingIntent(R.id.widget_timing_chart_image, openProgressIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun bindTabPill(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            viewId: Int,
            tf: String,
            selected: Boolean,
            requestBase: Int
        ) {
            views.setTextColor(viewId, if (selected) 0xFFFFFFFF.toInt() else 0xFF71717A.toInt())
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (selected) R.drawable.widget_tab_active else 0
            )
            val intent = Intent(context, TimingWidgetProvider::class.java).apply {
                action = ACTION_SET_TIMEFRAME
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra(EXTRA_TIMEFRAME, tf)
            }
            views.setOnClickPendingIntent(
                viewId,
                PendingIntent.getBroadcast(
                    context,
                    requestBase + appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
                )
            )
        }

        private fun renderTimingChartBitmap(
            points: List<WidgetStore.WidgetTimingPoint>,
            widthPx: Int,
            heightPx: Int
        ): Bitmap {
            val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val leftMargin = 62f
            val rightPad = 8f
            val topPad = 14f
            val bottomLabelH = 34f
            val chartBottom = heightPx - bottomLabelH
            val chartHeight = chartBottom - topPad
            val chartWidth = widthPx - leftMargin - rightPad

            val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0x12FFFFFF
                strokeWidth = 1.5f
            }

            val axisTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFF71717A.toInt()
                textSize = 16f
                isFakeBoldText = true
            }

            val yPositions = floatArrayOf(topPad, topPad + chartHeight * 0.5f, chartBottom)
            val yLabels = arrayOf("12AM", "12PM", "11PM")
            for (i in yPositions.indices) {
                val y = yPositions[i]
                canvas.drawLine(leftMargin, y, widthPx - rightPad, y, gridPaint)
                canvas.drawText(yLabels[i], 0f, y + 6f, axisTextPaint)
            }

            if (points.isEmpty()) return bitmap

            val slotCount = points.size
            val slotW = chartWidth / slotCount
            val barGap = if (slotCount > 8) 6f else 12f
            val barW = max(8f, slotW - barGap)
            val cornerR = if (slotCount > 8) 4f else 8f

            val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
            }
            val barGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0x350A84FF
                style = Paint.Style.FILL
                maskFilter = BlurMaskFilter(10f, BlurMaskFilter.Blur.NORMAL)
            }
            val todayStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0x55FFFFFF
                style = Paint.Style.STROKE
                strokeWidth = 1.5f
            }
            val xLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textAlign = Paint.Align.CENTER
                textSize = 18f
                isFakeBoldText = true
            }

            for (i in points.indices) {
                val p = points[i]
                val barLeft = leftMargin + i * slotW + (slotW - barW) / 2f
                val ratio = (p.value / p.max).coerceIn(0f, 1f)
                val barFactor = if (p.isCompleted) max(ratio * 0.90f, 0.08f) else 0.06f
                val barH = chartHeight * barFactor
                val barTop = chartBottom - barH
                val rect = RectF(barLeft, barTop, barLeft + barW, chartBottom)

                if (p.isCompleted) {
                    canvas.drawRoundRect(rect, cornerR, cornerR, barGlowPaint)
                    barPaint.color = 0xFF0A84FF.toInt()
                    canvas.drawRoundRect(rect, cornerR, cornerR, barPaint)
                    if (p.isToday) {
                        canvas.drawRoundRect(rect, cornerR, cornerR, todayStrokePaint)
                    }
                } else {
                    barPaint.color = 0x16FFFFFF
                    canvas.drawRoundRect(rect, cornerR, cornerR, barPaint)
                }

                xLabelPaint.color = if (p.isToday) 0xFFFFFFFF.toInt() else 0xFF71717A.toInt()
                canvas.drawText(
                    p.label,
                    barLeft + barW / 2f,
                    heightPx - 6f,
                    xLabelPaint
                )
            }

            return bitmap
        }
    }
}
