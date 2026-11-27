package com.atomichabits.atomic_habits

import android.Manifest
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class NotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appCtx = context.applicationContext
        when (intent.action) {
            NotificationScheduler.ACTION_DAILY_DIGEST -> {
                val slotIdx = intent.getIntExtra(NotificationScheduler.EXTRA_SLOT_INDEX, 0)
                val slotTime = intent.getStringExtra(NotificationScheduler.EXTRA_SLOT_TIME)
                NotificationScheduler.rescheduleAll(appCtx)
                dispatchDailyDigest(appCtx, slotIdx, slotTime, isPreview = false)
            }

            NotificationScheduler.ACTION_TASK_REMINDER -> {
                val todoId = intent.getStringExtra(NotificationScheduler.EXTRA_TODO_ID) ?: return
                val fallbackText = intent.getStringExtra(NotificationScheduler.EXTRA_TODO_TEXT) ?: ""
                val fallbackTime = intent.getStringExtra(NotificationScheduler.EXTRA_TODO_TIME)
                NotificationScheduler.rescheduleAll(appCtx)
                dispatchTimedTaskReminder(appCtx, todoId, fallbackText, fallbackTime)
            }

            NotificationScheduler.ACTION_MARK_TODO_DONE -> {
                val todoId = intent.getStringExtra(NotificationScheduler.EXTRA_TODO_ID) ?: return
                WidgetStore.toggleTodoById(appCtx, todoId)
                TodoWidgetProvider.updateAllWidgets(appCtx)
                NotificationScheduler.rescheduleAll(appCtx)
                val nm = appCtx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.cancel(timedNotificationId(todoId))
            }
        }
    }

    companion object {
        private const val HABITS_NOTIF_BASE = 1100
        private const val TODOS_NOTIF_BASE = 2100
        private const val TIMED_NOTIF_BASE = 3100

        fun canPostNotifications(context: Context): Boolean {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                return context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED
            }
            return true
        }

        fun sendTestNotifications(context: Context) {
            val appCtx = context.applicationContext
            NotificationScheduler.ensureChannels(appCtx)
            if (!canPostNotifications(appCtx)) return
            val config = WidgetStore.loadNotificationConfig(appCtx)
            val firstTime = config.times.firstOrNull() ?: "09:00"
            dispatchDailyDigest(appCtx, slotIndex = 0, slotTime = firstTime, isPreview = true)

            val timedTodo = WidgetStore.loadTodos(appCtx)
                .firstOrNull { !it.completed && !it.reminderTime.isNullOrBlank() }
            if (timedTodo != null) {
                dispatchTimedTaskReminder(
                    appCtx,
                    timedTodo.id,
                    timedTodo.text,
                    timedTodo.reminderTime
                )
            }
        }

        fun dispatchDailyDigest(
            context: Context,
            slotIndex: Int,
            slotTime: String?,
            isPreview: Boolean
        ) {
            NotificationScheduler.ensureChannels(context)
            if (!canPostNotifications(context)) return

            val config = WidgetStore.loadNotificationConfig(context)
            if (!config.enabled && !isPreview) return

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return
            val formattedTime = WidgetStore.formatTimeLabel(slotTime)

            if (config.notifyHabits) {
                val habits = WidgetStore.loadActiveHabits(context)
                val pendingHabits = habits.filter { !it.doneToday }
                if (pendingHabits.isNotEmpty() || isPreview) {
                    val title = buildString {
                        append("Daily Habits Reminder")
                        if (formattedTime != null) append(" • $formattedTime")
                    }
                    val body = when {
                        pendingHabits.isNotEmpty() -> {
                            val names = pendingHabits.take(3).joinToString(", ") {
                                it.name.lowercase().replaceFirstChar { ch -> ch.uppercase() }
                            }
                            val extra = if (pendingHabits.size > 3) " +${pendingHabits.size - 3} more" else ""
                            "${pendingHabits.size} habit${if (pendingHabits.size == 1) "" else "s"} left today: $names$extra."
                        }
                        habits.isNotEmpty() ->
                            "All ${habits.size} active habits are complete today! Keep your streak alive."
                        else ->
                            "Time to build small daily wins! Open Atomic Habits to check in."
                    }

                    val openHomePi = WidgetStore.buildOpenTabPendingIntent(
                        context,
                        requestCode = HABITS_NOTIF_BASE + slotIndex,
                        tab = "home"
                    )
                    nm.notify(
                        HABITS_NOTIF_BASE + slotIndex,
                        buildNotification(
                            context = context,
                            channelId = NotificationScheduler.CHANNEL_DAILY_CHECKIN,
                            title = title,
                            body = body,
                            accentColor = 0xFF0A84FF.toInt(),
                            contentIntent = openHomePi
                        )
                    )
                }
            }

            if (config.notifyTodos) {
                val pendingTodos = WidgetStore.loadTodos(context).filter { !it.completed }
                if (pendingTodos.isNotEmpty() || isPreview) {
                    val title = buildString {
                        append("Daily To-Do Check-In")
                        if (formattedTime != null) append(" • $formattedTime")
                    }
                    val body = if (pendingTodos.isNotEmpty()) {
                        val lines = pendingTodos.take(3).joinToString("\n") { t ->
                            val rt = WidgetStore.formatTimeLabel(t.reminderTime)
                            if (rt != null) "• ${t.text} ($rt)" else "• ${t.text}"
                        }
                        val tail = if (pendingTodos.size > 3) "\n+${pendingTodos.size - 3} more pending tasks" else ""
                        "$lines$tail"
                    } else {
                        "Your To-Do checklist is ready! Add daily action items to stay focused."
                    }

                    val openTodoPi = WidgetStore.buildOpenTabPendingIntent(
                        context,
                        requestCode = TODOS_NOTIF_BASE + slotIndex,
                        tab = "todo"
                    )
                    nm.notify(
                        TODOS_NOTIF_BASE + slotIndex,
                        buildNotification(
                            context = context,
                            channelId = NotificationScheduler.CHANNEL_DAILY_CHECKIN,
                            title = title,
                            body = body,
                            accentColor = 0xFF34C759.toInt(),
                            contentIntent = openTodoPi
                        )
                    )
                }
            }
        }

        fun dispatchTimedTaskReminder(
            context: Context,
            todoId: String,
            fallbackText: String,
            fallbackTime: String?
        ) {
            NotificationScheduler.ensureChannels(context)
            if (!canPostNotifications(context)) return

            val config = WidgetStore.loadNotificationConfig(context)
            if (!config.enabled) return

            val liveTodo = WidgetStore.loadTodos(context).firstOrNull { it.id == todoId }
            if (liveTodo != null && liveTodo.completed) return
            val text = liveTodo?.text ?: fallbackText
            if (text.isBlank()) return
            val timeLabel = WidgetStore.formatTimeLabel(liveTodo?.reminderTime ?: fallbackTime)

            val title = buildString {
                append("Task Reminder")
                if (timeLabel != null) append(" • $timeLabel")
            }
            val body = "$text\nTap to edit or check off this task."

            val openTodoPi = WidgetStore.buildOpenTodoEditorPendingIntent(
                context = context,
                requestCode = timedNotificationId(todoId),
                todoId = todoId
            )

            val doneIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = NotificationScheduler.ACTION_MARK_TODO_DONE
                putExtra(NotificationScheduler.EXTRA_TODO_ID, todoId)
            }
            val donePi = PendingIntent.getBroadcast(
                context,
                9000 + (todoId.hashCode() and 0x0FFF),
                doneIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
            )

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return
            val notif = buildNotification(
                context = context,
                channelId = NotificationScheduler.CHANNEL_TASK_TIMED,
                title = title,
                body = body,
                accentColor = 0xFFFF9F0A.toInt(),
                contentIntent = openTodoPi,
                doneActionPendingIntent = donePi
            )
            nm.notify(timedNotificationId(todoId), notif)
        }

        private fun timedNotificationId(todoId: String): Int =
            TIMED_NOTIF_BASE + (todoId.hashCode() and 0x0FFF)

        @Suppress("DEPRECATION")
        private fun buildNotification(
            context: Context,
            channelId: String,
            title: String,
            body: String,
            accentColor: Int,
            contentIntent: PendingIntent,
            doneActionPendingIntent: PendingIntent? = null
        ): Notification {
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, channelId)
            } else {
                Notification.Builder(context)
            }
            builder.setSmallIcon(R.drawable.ic_stat_pulse)
                .setContentTitle(title)
                .setContentText(body.lines().firstOrNull() ?: body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setColor(accentColor)
                .setContentIntent(contentIntent)
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)

            if (doneActionPendingIntent != null) {
                builder.addAction(
                    Notification.Action.Builder(
                        R.drawable.ic_stat_pulse,
                        "Mark Done",
                        doneActionPendingIntent
                    ).build()
                )
            }
            return builder.build()
        }
    }
}
