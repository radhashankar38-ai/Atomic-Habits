package com.atomichabits.atomic_habits

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

object NotificationScheduler {
    const val CHANNEL_DAILY_CHECKIN = "atomic_habits_daily_v1"
    const val CHANNEL_TASK_TIMED = "atomic_task_timed_v1"

    const val ACTION_DAILY_DIGEST = "com.atomichabits.atomic_habits.ACTION_DAILY_DIGEST"
    const val ACTION_TASK_REMINDER = "com.atomichabits.atomic_habits.ACTION_TASK_REMINDER"
    const val ACTION_MARK_TODO_DONE = "com.atomichabits.atomic_habits.ACTION_MARK_TODO_DONE"

    const val EXTRA_SLOT_INDEX = "slot_index"
    const val EXTRA_SLOT_TIME = "slot_time"
    const val EXTRA_TODO_ID = "todo_id"
    const val EXTRA_TODO_TEXT = "todo_text"
    const val EXTRA_TODO_TIME = "todo_time"

    private const val PREF_SCHEDULED_TASK_CODES = "scheduled_task_req_codes"
    private const val SLOT_REQ_BASE = 7100
    private const val MAX_DAILY_SLOTS = 4
    private const val TASK_REQ_BASE = 8000

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return

        val dailyChannel = NotificationChannel(
            CHANNEL_DAILY_CHECKIN,
            "Daily Habit & Task Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Scheduled daily summaries for your active habits and pending tasks."
            enableVibration(true)
        }

        val timedTaskChannel = NotificationChannel(
            CHANNEL_TASK_TIMED,
            "Task Time Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts for To-Do tasks that have a specific reminder time set."
            enableVibration(true)
        }

        nm.createNotificationChannels(listOf(dailyChannel, timedTaskChannel))
    }

    fun rescheduleAll(context: Context) {
        ensureChannels(context)
        val appCtx = context.applicationContext
        val alarmManager = appCtx.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return

        cancelExistingAlarms(appCtx, alarmManager)

        val config = WidgetStore.loadNotificationConfig(appCtx)
        if (!config.enabled) return

        // 1. Schedule user-configured daily digest notification slots (1..4 times/day)
        val activeTimes = config.times.take(config.perDay.coerceIn(1, MAX_DAILY_SLOTS))
        activeTimes.forEachIndexed { index, hhmm ->
            val hm = parseHourMinute(hhmm) ?: return@forEachIndexed
            val triggerAt = nextTriggerMillis(hm.first, hm.second)
            val pi = buildDailySlotPendingIntent(appCtx, index, hhmm)
            scheduleAlarm(alarmManager, triggerAt, pi)
        }

        // 2. Schedule per-task timed reminders for incomplete tasks
        val todos = WidgetStore.loadTodos(appCtx)
        val trackedCodes = mutableSetOf<String>()
        for (todo in todos) {
            if (todo.completed) continue
            val rt = todo.reminderTime ?: continue
            val hm = parseHourMinute(rt) ?: continue
            val reqCode = taskRequestCode(todo.id)
            trackedCodes.add(reqCode.toString())
            val triggerAt = nextTriggerMillis(hm.first, hm.second)
            val pi = buildTaskPendingIntent(
                context = appCtx,
                reqCode = reqCode,
                todoId = todo.id,
                todoText = todo.text,
                todoTime = rt
            )
            scheduleAlarm(alarmManager, triggerAt, pi)
        }

        appCtx.getSharedPreferences(WidgetStore.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(PREF_SCHEDULED_TASK_CODES, trackedCodes)
            .apply()
    }

    private fun cancelExistingAlarms(context: Context, alarmManager: AlarmManager) {
        for (i in 0 until MAX_DAILY_SLOTS) {
            val intent = Intent(context, NotificationReceiver::class.java).apply {
                action = ACTION_DAILY_DIGEST
            }
            val pi = PendingIntent.getBroadcast(
                context,
                SLOT_REQ_BASE + i,
                intent,
                PendingIntent.FLAG_NO_CREATE or WidgetStore.immutableFlag()
            )
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        }

        val prefs = context.getSharedPreferences(WidgetStore.PREFS_NAME, Context.MODE_PRIVATE)
        val savedCodes = prefs.getStringSet(PREF_SCHEDULED_TASK_CODES, emptySet()) ?: emptySet()
        for (raw in savedCodes) {
            val code = raw.toIntOrNull() ?: continue
            val intent = Intent(context, NotificationReceiver::class.java).apply {
                action = ACTION_TASK_REMINDER
            }
            val pi = PendingIntent.getBroadcast(
                context,
                code,
                intent,
                PendingIntent.FLAG_NO_CREATE or WidgetStore.immutableFlag()
            )
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        }
        prefs.edit().remove(PREF_SCHEDULED_TASK_CODES).apply()
    }

    private fun buildDailySlotPendingIntent(
        context: Context,
        slotIndex: Int,
        slotTime: String
    ): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_DAILY_DIGEST
            putExtra(EXTRA_SLOT_INDEX, slotIndex)
            putExtra(EXTRA_SLOT_TIME, slotTime)
        }
        return PendingIntent.getBroadcast(
            context,
            SLOT_REQ_BASE + slotIndex,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
        )
    }

    private fun buildTaskPendingIntent(
        context: Context,
        reqCode: Int,
        todoId: String,
        todoText: String,
        todoTime: String
    ): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TASK_REMINDER
            putExtra(EXTRA_TODO_ID, todoId)
            putExtra(EXTRA_TODO_TEXT, todoText)
            putExtra(EXTRA_TODO_TIME, todoTime)
        }
        return PendingIntent.getBroadcast(
            context,
            reqCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or WidgetStore.immutableFlag()
        )
    }

    private fun scheduleAlarm(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        operation: PendingIntent
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                alarmManager.canScheduleExactAlarms()
            ) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    operation
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    operation
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    operation
                )
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    operation
                )
            }
        }
    }

    fun taskRequestCode(todoId: String): Int =
        TASK_REQ_BASE + (todoId.hashCode() and 0x0FFF)

    fun parseHourMinute(hhmm: String?): Pair<Int, Int>? {
        if (hhmm.isNullOrBlank()) return null
        val parts = hhmm.trim().split(":")
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        if (hour !in 0..23 || minute !in 0..59) return null
        return hour to minute
    }

    private fun nextTriggerMillis(hour: Int, minute: Int): Long {
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= now + 5_000L) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }
}
