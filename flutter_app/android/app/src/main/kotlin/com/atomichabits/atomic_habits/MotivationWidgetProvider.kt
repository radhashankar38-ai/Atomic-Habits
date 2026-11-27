package com.atomichabits.atomic_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class MotivationWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_QUOTE) {
            val pendingResult = goAsync()
            Thread {
                try {
                    val current = WidgetStore.loadMotivation(context)
                    val fetched = fetchQuoteOrFallback(context, current.text)
                    WidgetStore.saveMotivationQuote(context, fetched)
                    updateAllWidgets(context)
                } finally {
                    pendingResult.finish()
                }
            }.start()
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

    private fun fetchQuoteOrFallback(
        context: Context,
        currentText: String
    ): WidgetStore.WidgetQuote {
        try {
            val conn = (URL("https://dummyjson.com/quotes/random").openConnection() as HttpURLConnection).apply {
                connectTimeout = 4000
                readTimeout = 4000
                requestMethod = "GET"
            }
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(body)
                val qText = json.optString("quote", "").trim()
                val qAuthor = json.optString("author", "Unknown").ifBlank { "Unknown" }
                if (qText.isNotEmpty() && qText != currentText) {
                    return WidgetStore.WidgetQuote(qText, qAuthor)
                }
            }
        } catch (_: Exception) {
        }
        return WidgetStore.nextOfflineQuote(context, currentText)
    }

    companion object {
        private const val ACTION_REFRESH_QUOTE = "com.atomichabits.atomic_habits.ACTION_REFRESH_QUOTE"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, MotivationWidgetProvider::class.java)
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
            val quote = WidgetStore.loadMotivation(context)
            val views = RemoteViews(context.packageName, R.layout.widget_motivation)

            views.setTextViewText(R.id.widget_motivation_quote, quote.text)
            views.setTextViewText(
                R.id.widget_motivation_author,
                "— ${quote.author.uppercase(Locale.US)}"
            )

            val openIntent = WidgetStore.buildOpenTabPendingIntent(
                context,
                requestCode = 4000 + appWidgetId,
                tab = "home"
            )
            views.setOnClickPendingIntent(R.id.widget_motivation_root, openIntent)

            val refreshIntent = Intent(context, MotivationWidgetProvider::class.java).apply {
                action = ACTION_REFRESH_QUOTE
            }
            views.setOnClickPendingIntent(
                R.id.widget_motivation_refresh,
                PendingIntent.getBroadcast(
                    context,
                    4500 + appWidgetId,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
                )
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
