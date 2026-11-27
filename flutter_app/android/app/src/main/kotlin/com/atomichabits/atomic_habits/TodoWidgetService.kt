package com.atomichabits.atomic_habits

import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoRemoteViewsFactory(applicationContext)
    }
}

private class TodoRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private var todos: List<WidgetStore.WidgetTodo> = emptyList()

    override fun onCreate() {
        todos = WidgetStore.loadTodos(context)
    }

    override fun onDataSetChanged() {
        todos = WidgetStore.loadTodos(context)
    }

    override fun onDestroy() {
        todos = emptyList()
    }

    override fun getCount(): Int = todos.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_todo_item)
        if (position < 0 || position >= todos.size) return views

        val item = todos[position]
        if (item.completed) {
            val struck = SpannableString(item.text).apply {
                setSpan(
                    StrikethroughSpan(),
                    0,
                    item.text.length,
                    Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
            }
            views.setTextViewText(R.id.widget_todo_item_text, struck)
            views.setTextColor(R.id.widget_todo_item_text, 0x7371717A)
            views.setInt(
                R.id.widget_todo_item_check_box,
                "setBackgroundResource",
                R.drawable.widget_todo_check_done
            )
            views.setViewVisibility(R.id.widget_todo_item_check_icon, View.VISIBLE)
        } else {
            views.setTextViewText(R.id.widget_todo_item_text, item.text)
            views.setTextColor(R.id.widget_todo_item_text, 0xFFE4E4E7.toInt())
            views.setInt(
                R.id.widget_todo_item_check_box,
                "setBackgroundResource",
                R.drawable.widget_todo_check_idle
            )
            views.setViewVisibility(R.id.widget_todo_item_check_icon, View.GONE)
        }

        val timeLabel = WidgetStore.formatTimeLabel(item.reminderTime)
        if (timeLabel != null) {
            views.setViewVisibility(R.id.widget_todo_item_reminder_row, View.VISIBLE)
            views.setTextViewText(R.id.widget_todo_item_reminder_text, timeLabel)
        } else {
            views.setViewVisibility(R.id.widget_todo_item_reminder_row, View.GONE)
        }

        val toggleFillIn = Intent().apply {
            putExtra(TodoWidgetProvider.EXTRA_ACTION_TYPE, "toggle")
            putExtra(TodoWidgetProvider.EXTRA_TODO_ID, item.id)
        }
        views.setOnClickFillInIntent(R.id.widget_todo_item_main, toggleFillIn)

        val editFillIn = Intent().apply {
            putExtra(TodoWidgetProvider.EXTRA_ACTION_TYPE, "edit")
            putExtra(TodoWidgetProvider.EXTRA_TODO_ID, item.id)
        }
        views.setOnClickFillInIntent(R.id.widget_todo_item_edit_btn, editFillIn)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
