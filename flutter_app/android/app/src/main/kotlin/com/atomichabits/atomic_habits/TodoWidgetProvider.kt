package com.atomichabits.atomic_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

class TodoWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_TODO) {
            val todoId = intent.getStringExtra(EXTRA_TODO_ID)
            val actionType = intent.getStringExtra(EXTRA_ACTION_TYPE) ?: "toggle"
            if (!todoId.isNullOrEmpty()) {
                if (actionType == "edit") {
                    val editIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra(WidgetStore.EXTRA_OPEN_TAB, "todo")
                        putExtra(WidgetStore.EXTRA_EDIT_TODO_ID, todoId)
                    }
                    context.startActivity(editIntent)
                } else {
                    WidgetStore.toggleTodoById(context, todoId)
                    updateAllWidgets(context)
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
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_todo_list)
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
        const val ACTION_TOGGLE_TODO = "com.atomichabits.atomic_habits.ACTION_TOGGLE_TODO"
        const val EXTRA_TODO_ID = "todo_id"
        const val EXTRA_ACTION_TYPE = "action_type"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TodoWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
            manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_todo_list)
        }

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val todos = WidgetStore.loadTodos(context)
            val remaining = todos.count { !it.completed }
            val views = RemoteViews(context.packageName, R.layout.widget_todo)

            val countText = when {
                todos.isEmpty() -> "0 TASKS"
                remaining == 0 -> "ALL DONE"
                else -> "$remaining LEFT"
            }
            views.setTextViewText(R.id.widget_todo_count, countText)
            views.setTextColor(
                R.id.widget_todo_count,
                if (todos.isNotEmpty() && remaining == 0) 0xFF34C759.toInt()
                else 0xFF0A84FF.toInt()
            )

            val openTodoIntent = WidgetStore.buildOpenTabPendingIntent(
                context,
                requestCode = 5000 + appWidgetId,
                tab = "todo"
            )
            views.setOnClickPendingIntent(R.id.widget_todo_header, openTodoIntent)
            views.setOnClickPendingIntent(R.id.widget_todo_add_btn, openTodoIntent)
            views.setOnClickPendingIntent(R.id.widget_todo_empty, openTodoIntent)

            if (todos.isEmpty()) {
                views.setViewVisibility(R.id.widget_todo_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_todo_list, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_todo_empty, View.GONE)
                views.setViewVisibility(R.id.widget_todo_list, View.VISIBLE)

                val serviceIntent = Intent(context, TodoWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                @Suppress("DEPRECATION")
                views.setRemoteAdapter(R.id.widget_todo_list, serviceIntent)

                val toggleTemplateIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TODO
                }
                val toggleTemplatePendingIntent = PendingIntent.getBroadcast(
                    context,
                    5500 + appWidgetId,
                    toggleTemplateIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.mutableFlag()
                )
                views.setPendingIntentTemplate(R.id.widget_todo_list, toggleTemplatePendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
