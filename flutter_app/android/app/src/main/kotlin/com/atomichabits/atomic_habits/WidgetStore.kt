package com.atomichabits.atomic_habits

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

object WidgetStore {
    const val PREFS_NAME = "AtomicHabitsWidgetPrefs"
    const val KEY_PAYLOAD = "widget_payload"
    const val KEY_ALL_PAYLOAD = "all_widgets_payload"
    const val KEY_TIMING_TF_PREFIX = "timing_timeframe_"
    const val KEY_RINGS_PAGE_PREFIX = "rings_page_"
    const val KEY_FALLBACK_QUOTE_IDX = "fallback_quote_idx"

    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val FLUTTER_KEY_HABITS = "flutter.habits"
    private const val FLUTTER_KEY_COMPLETED_HABITS = "flutter.completedHabits"
    private const val FLUTTER_KEY_COMPLETIONS = "flutter.completions"
    private const val FLUTTER_KEY_TODOS = "flutter.todos"
    private const val FLUTTER_KEY_QUOTE = "flutter.dailyQuote"
    private const val FLUTTER_KEY_NOTIF_ENABLED = "flutter.notificationsEnabled"
    private const val FLUTTER_KEY_NOTIF_TIMES = "flutter.notificationTimes"
    private const val FLUTTER_KEY_NOTIF_PER_DAY = "flutter.notificationsPerDay"
    private const val FLUTTER_KEY_NOTIFY_HABITS = "flutter.notifyHabits"
    private const val FLUTTER_KEY_NOTIFY_TODOS = "flutter.notifyTodos"

    const val EXTRA_OPEN_TAB = "open_tab"
    const val EXTRA_EDIT_TODO_ID = "edit_todo_id"

    private val DEFAULT_NOTIFICATION_TIMES = listOf("09:00", "14:00", "18:00", "21:00")

    private val FALLBACK_COLORS = intArrayOf(
        0xFFFA114F.toInt(),
        0xFF92FF00.toInt(),
        0xFF00F2FF.toInt()
    )

    private val OFFLINE_QUOTES = listOf(
        WidgetQuote(
            "A journey of a thousand miles begins with a single step.",
            "Lao Tzu"
        ),
        WidgetQuote(
            "You have power over your mind—not outside events. Realize this, and you will find strength.",
            "Marcus Aurelius"
        ),
        WidgetQuote(
            "First say to yourself what you would be; and then do what you have to do.",
            "Epictetus"
        ),
        WidgetQuote(
            "It is not that we have a short time to live, but that we waste a lot of it.",
            "Seneca"
        ),
        WidgetQuote(
            "Well done is better than well said.",
            "Benjamin Franklin"
        ),
        WidgetQuote(
            "No man is free who is not master of himself.",
            "Epictetus"
        )
    )

    data class WidgetHabit(
        val id: String,
        val name: String,
        val colorInt: Int,
        val category: String,
        val categoryLabel: String,
        val progress: Float,
        val doneToday: Boolean
    )

    data class WidgetQuote(
        val text: String,
        val author: String
    )

    data class WidgetTodo(
        val id: String,
        val text: String,
        val completed: Boolean,
        val createdAt: String,
        val reminderTime: String? = null
    )

    data class NotificationConfig(
        val enabled: Boolean,
        val perDay: Int,
        val times: List<String>,
        val notifyHabits: Boolean,
        val notifyTodos: Boolean
    )

    data class WidgetTimingPoint(
        val label: String,
        val value: Float,
        val max: Float,
        val isToday: Boolean,
        val isCompleted: Boolean
    )

    fun saveAllPayloads(context: Context, jsonStr: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALL_PAYLOAD, jsonStr)
            .apply()
    }

    fun saveLegacyRingsPayload(context: Context, jsonStr: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PAYLOAD, jsonStr)
            .apply()
    }

    fun updateAllWidgets(context: Context) {
        HabitRingsWidgetProvider.updateAllWidgets(context)
        MotivationWidgetProvider.updateAllWidgets(context)
        TodoWidgetProvider.updateAllWidgets(context)
        TimingWidgetProvider.updateAllWidgets(context)
    }

    fun buildOpenTabPendingIntent(
        context: Context,
        requestCode: Int,
        tab: String
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_OPEN_TAB, tab)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )
    }

    fun buildOpenTodoEditorPendingIntent(
        context: Context,
        requestCode: Int,
        todoId: String
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_OPEN_TAB, "todo")
            putExtra(EXTRA_EDIT_TODO_ID, todoId)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )
    }

    fun formatTimeLabel(hhmm: String?): String? {
        if (hhmm.isNullOrBlank()) return null
        val parts = hhmm.trim().split(":")
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        if (hour !in 0..23 || minute !in 0..59) return null
        val period = if (hour >= 12) "PM" else "AM"
        val displayHour = if (hour % 12 == 0) 12 else hour % 12
        val displayMin = String.format(Locale.US, "%02d", minute)
        return "$displayHour:$displayMin $period"
    }

    fun loadNotificationConfig(context: Context): NotificationConfig {
        val bundle = readBundleJson(context)
        val notifObj = bundle?.optJSONObject("notifications")
        if (notifObj != null) {
            val times = mutableListOf<String>()
            val arr = notifObj.optJSONArray("times")
            val allArr = notifObj.optJSONArray("allTimes")
            val sourceArr = allArr ?: arr
            if (sourceArr != null) {
                for (i in 0 until sourceArr.length()) {
                    val t = sourceArr.optString(i, "").trim()
                    if (t.isNotEmpty() && t != "null") times.add(t)
                }
            }
            return NotificationConfig(
                enabled = notifObj.optBoolean("enabled", true),
                perDay = notifObj.optInt("perDay", 2).coerceIn(1, 4),
                times = if (times.isNotEmpty()) times else DEFAULT_NOTIFICATION_TIMES,
                notifyHabits = notifObj.optBoolean("notifyHabits", true),
                notifyTodos = notifObj.optBoolean("notifyTodos", true)
            )
        }

        val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
        val allMap = flutterPrefs.all
        val enabled = (allMap[FLUTTER_KEY_NOTIF_ENABLED] as? Boolean) ?: true
        val perDay = ((allMap[FLUTTER_KEY_NOTIF_PER_DAY] as? Number)?.toInt() ?: 2).coerceIn(1, 4)
        val notifyHabits = (allMap[FLUTTER_KEY_NOTIFY_HABITS] as? Boolean) ?: true
        val notifyTodos = (allMap[FLUTTER_KEY_NOTIFY_TODOS] as? Boolean) ?: true
        val timesRaw = allMap[FLUTTER_KEY_NOTIF_TIMES] as? String
        val times = mutableListOf<String>()
        if (!timesRaw.isNullOrEmpty()) {
            try {
                val arr = JSONArray(timesRaw)
                for (i in 0 until arr.length()) {
                    val t = arr.optString(i, "").trim()
                    if (t.isNotEmpty() && t != "null") times.add(t)
                }
            } catch (_: Exception) {
            }
        }
        return NotificationConfig(
            enabled = enabled,
            perDay = perDay,
            times = if (times.isNotEmpty()) times else DEFAULT_NOTIFICATION_TIMES,
            notifyHabits = notifyHabits,
            notifyTodos = notifyTodos
        )
    }

    fun immutableFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

    fun mutableFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0

    private fun readBundleJson(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_ALL_PAYLOAD, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun loadActiveHabits(context: Context): List<WidgetHabit> {
        val bundle = readBundleJson(context)
        if (bundle != null && bundle.has("rings")) {
            return parseRingsArray(bundle.optJSONArray("rings"))
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (prefs.contains(KEY_PAYLOAD)) {
            val raw = prefs.getString(KEY_PAYLOAD, "[]") ?: "[]"
            return try {
                parseRingsArray(JSONArray(raw))
            } catch (_: Exception) {
                emptyList()
            }
        }

        return loadRingsFromFlutterPrefs(context)
    }

    private fun parseRingsArray(array: JSONArray?): List<WidgetHabit> {
        if (array == null) return emptyList()
        val result = mutableListOf<WidgetHabit>()
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val name = obj.optString("name", "").trim()
            if (name.isEmpty()) continue
            val id = obj.optString("id", "h_$i")
            val colorInt = parseColor(obj.optString("color", ""), i)
            val category = obj.optString("category", "other").lowercase(Locale.US)
            val categoryLabel =
                obj.optString("categoryLabel", resolveCategoryLabel(category))
            val progress = obj.optDouble("progress", 0.0).toFloat().coerceIn(0f, 1f)
            val doneToday = obj.optBoolean("doneToday", false)
            result.add(
                WidgetHabit(
                    id = id,
                    name = name.uppercase(Locale.US),
                    colorInt = colorInt,
                    category = category,
                    categoryLabel = categoryLabel,
                    progress = progress,
                    doneToday = doneToday
                )
            )
        }
        return result
    }

    private fun loadRingsFromFlutterPrefs(context: Context): List<WidgetHabit> {
        val result = mutableListOf<WidgetHabit>()
        try {
            val flutterPrefs = context.getSharedPreferences(
                FLUTTER_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val habitsRaw = flutterPrefs.getString(FLUTTER_KEY_HABITS, null) ?: return result
            val completionsRaw = flutterPrefs.getString(FLUTTER_KEY_COMPLETIONS, null)
            val completionsObj = if (!completionsRaw.isNullOrEmpty()) {
                JSONObject(completionsRaw)
            } else {
                null
            }
            val todayStr = todayDateStr()
            val array = JSONArray(habitsRaw)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val hasCompletedAt = !obj.isNull("completedAt") &&
                    obj.optString("completedAt", "").isNotEmpty()
                if (hasCompletedAt) continue

                val id = obj.optString("id", "")
                val name = obj.optString("name", "").trim()
                if (name.isEmpty()) continue

                val colorInt = parseColor(obj.optString("color", ""), result.size)
                val category = if (obj.isNull("category")) {
                    "other"
                } else {
                    obj.optString("category", "other").lowercase(Locale.US)
                }
                val targetDays = obj.optInt("targetDays", 0)
                val compArr = completionsObj?.optJSONArray(id)
                val compsCount = compArr?.length() ?: 0
                var doneToday = false
                if (compArr != null) {
                    for (j in 0 until compArr.length()) {
                        if (compArr.optString(j, "").startsWith(todayStr)) {
                            doneToday = true
                            break
                        }
                    }
                }
                val progress = when {
                    targetDays > 0 -> min(1f, compsCount.toFloat() / targetDays.toFloat())
                    compsCount > 0 -> 1f
                    else -> 0f
                }
                result.add(
                    WidgetHabit(
                        id = id,
                        name = name.uppercase(Locale.US),
                        colorInt = colorInt,
                        category = category,
                        categoryLabel = resolveCategoryLabel(category),
                        progress = progress,
                        doneToday = doneToday
                    )
                )
            }
        } catch (_: Exception) {
        }
        return result
    }

    fun loadMotivation(context: Context): WidgetQuote {
        val bundle = readBundleJson(context)
        val motObj = bundle?.optJSONObject("motivation")
        if (motObj != null) {
            val text = motObj.optString("text", "").trim()
            if (text.isNotEmpty()) {
                return WidgetQuote(
                    text = text,
                    author = motObj.optString("author", "Unknown").ifBlank { "Unknown" }
                )
            }
        }

        try {
            val flutterPrefs = context.getSharedPreferences(
                FLUTTER_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val raw = flutterPrefs.getString(FLUTTER_KEY_QUOTE, null)
            if (!raw.isNullOrEmpty()) {
                val obj = JSONObject(raw)
                val text = obj.optString("text", "").trim()
                if (text.isNotEmpty()) {
                    return WidgetQuote(
                        text = text,
                        author = obj.optString("author", "Unknown").ifBlank { "Unknown" }
                    )
                }
            }
        } catch (_: Exception) {
        }

        return OFFLINE_QUOTES.first()
    }

    fun saveMotivationQuote(context: Context, quote: WidgetQuote) {
        val today = todayDateStr()
        val bundle = readBundleJson(context) ?: JSONObject()
        val motJson = JSONObject().apply {
            put("text", quote.text)
            put("author", quote.author)
            put("date", today)
        }
        bundle.put("motivation", motJson)
        saveAllPayloads(context, bundle.toString())

        context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(FLUTTER_KEY_QUOTE, motJson.toString())
            .apply()
    }

    fun nextOfflineQuote(context: Context, currentText: String): WidgetQuote {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var nextIdx = (prefs.getInt(KEY_FALLBACK_QUOTE_IDX, 0) + 1) % OFFLINE_QUOTES.size
        if (OFFLINE_QUOTES[nextIdx].text == currentText) {
            nextIdx = (nextIdx + 1) % OFFLINE_QUOTES.size
        }
        prefs.edit().putInt(KEY_FALLBACK_QUOTE_IDX, nextIdx).apply()
        return OFFLINE_QUOTES[nextIdx]
    }

    fun loadTodos(context: Context): List<WidgetTodo> {
        val bundle = readBundleJson(context)
        if (bundle != null && bundle.has("todos")) {
            return parseTodosArray(bundle.optJSONArray("todos"))
        }
        try {
            val flutterPrefs = context.getSharedPreferences(
                FLUTTER_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val raw = flutterPrefs.getString(FLUTTER_KEY_TODOS, null) ?: return emptyList()
            return parseTodosArray(JSONArray(raw))
        } catch (_: Exception) {
        }
        return emptyList()
    }

    private fun parseTodosArray(arr: JSONArray?): List<WidgetTodo> {
        if (arr == null) return emptyList()
        val out = mutableListOf<WidgetTodo>()
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            val id = obj.optString("id", "")
            val text = obj.optString("text", "").trim()
            if (id.isEmpty() || text.isEmpty()) continue
            val reminder = if (obj.isNull("reminderTime")) {
                null
            } else {
                obj.optString("reminderTime", "").trim().ifEmpty { null }
            }
            out.add(
                WidgetTodo(
                    id = id,
                    text = text,
                    completed = obj.optBoolean("completed", false),
                    createdAt = obj.optString("createdAt", ""),
                    reminderTime = reminder
                )
            )
        }
        return out
    }

    fun toggleTodoById(context: Context, todoId: String) {
        val current = loadTodos(context)
        if (current.isEmpty()) return
        var changed = false
        val jsonArr = JSONArray()
        for (item in current) {
            val toggled = if (item.id == todoId) {
                changed = true
                !item.completed
            } else {
                item.completed
            }
            jsonArr.put(
                JSONObject().apply {
                    put("id", item.id)
                    put("text", item.text)
                    put("completed", toggled)
                    if (item.createdAt.isNotEmpty()) put("createdAt", item.createdAt)
                    if (!item.reminderTime.isNullOrEmpty()) {
                        put("reminderTime", item.reminderTime)
                    }
                }
            )
        }
        if (!changed) return

        val bundle = readBundleJson(context) ?: JSONObject()
        bundle.put("todos", jsonArr)
        saveAllPayloads(context, bundle.toString())

        context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(FLUTTER_KEY_TODOS, jsonArr.toString())
            .apply()

        NotificationScheduler.rescheduleAll(context)
    }

    fun getTimingTimeframe(context: Context, appWidgetId: Int): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$KEY_TIMING_TF_PREFIX$appWidgetId", "week") ?: "week"
    }

    fun setTimingTimeframe(context: Context, appWidgetId: Int, timeframe: String) {
        val normalized = when (timeframe.lowercase(Locale.US)) {
            "month" -> "month"
            "year" -> "year"
            else -> "week"
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString("$KEY_TIMING_TF_PREFIX$appWidgetId", normalized)
            .apply()
    }

    fun getRingsPage(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt("$KEY_RINGS_PAGE_PREFIX$appWidgetId", 0).coerceAtLeast(0)
    }

    fun setRingsPage(context: Context, appWidgetId: Int, page: Int) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putInt("$KEY_RINGS_PAGE_PREFIX$appWidgetId", page.coerceAtLeast(0))
            .apply()
    }

    fun clearWidgetPrefs(context: Context, appWidgetId: Int) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove("$KEY_TIMING_TF_PREFIX$appWidgetId")
            .remove("$KEY_RINGS_PAGE_PREFIX$appWidgetId")
            .apply()
    }

    fun loadTimingBars(context: Context, timeframe: String): List<WidgetTimingPoint> {
        val bundle = readBundleJson(context)
        val timingObj = bundle?.optJSONObject("timing")
        val tfArray = timingObj?.optJSONArray(timeframe)
        if (tfArray != null && tfArray.length() > 0) {
            val out = mutableListOf<WidgetTimingPoint>()
            for (i in 0 until tfArray.length()) {
                val obj = tfArray.optJSONObject(i) ?: continue
                out.add(
                    WidgetTimingPoint(
                        label = obj.optString("label", ""),
                        value = obj.optDouble("value", 0.0).toFloat(),
                        max = obj.optDouble("max", 1.0).toFloat().coerceAtLeast(1f),
                        isToday = obj.optBoolean("isToday", false),
                        isCompleted = obj.optBoolean("isCompleted", false)
                    )
                )
            }
            if (out.isNotEmpty()) return out
        }

        return computeTimingFromFlutterPrefs(context, timeframe)
    }

    private fun computeTimingFromFlutterPrefs(
        context: Context,
        timeframe: String
    ): List<WidgetTimingPoint> {
        val habitIds = mutableListOf<String>()
        val completionDates = mutableListOf<List<String>>()
        try {
            val flutterPrefs = context.getSharedPreferences(
                FLUTTER_PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val habitsArr = JSONArray(flutterPrefs.getString(FLUTTER_KEY_HABITS, "[]") ?: "[]")
            val compHabitsArr = JSONArray(
                flutterPrefs.getString(FLUTTER_KEY_COMPLETED_HABITS, "[]") ?: "[]"
            )
            for (i in 0 until habitsArr.length()) {
                habitsArr.optJSONObject(i)?.optString("id", "")?.takeIf { it.isNotEmpty() }
                    ?.let { habitIds.add(it) }
            }
            for (i in 0 until compHabitsArr.length()) {
                compHabitsArr.optJSONObject(i)?.optString("id", "")?.takeIf { it.isNotEmpty() }
                    ?.let { if (!habitIds.contains(it)) habitIds.add(it) }
            }
            val compObj = JSONObject(
                flutterPrefs.getString(FLUTTER_KEY_COMPLETIONS, "{}") ?: "{}"
            )
            for (id in habitIds) {
                val arr = compObj.optJSONArray(id)
                val list = mutableListOf<String>()
                if (arr != null) {
                    for (j in 0 until arr.length()) {
                        list.add(arr.optString(j, ""))
                    }
                }
                completionDates.add(list)
            }
        } catch (_: Exception) {
        }

        val cal = Calendar.getInstance()
        val todayStr = todayDateStr()
        val weekLabels = arrayOf("S", "M", "T", "W", "T", "F", "S")
        val monthLabels = arrayOf("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")

        return when (timeframe) {
            "month" -> {
                val maxVal = max(10, habitIds.size * 7).toFloat()
                val todayCal = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val weeks = intArrayOf(3, 2, 1, 0)
                weeks.mapIndexed { idx, offset ->
                    var count = 0
                    for (list in completionDates) {
                        for (iso in list) {
                            val d = parseIsoLocal(iso) ?: continue
                            val dStart = Calendar.getInstance().apply {
                                time = d
                                set(Calendar.HOUR_OF_DAY, 0)
                                set(Calendar.MINUTE, 0)
                                set(Calendar.SECOND, 0)
                                set(Calendar.MILLISECOND, 0)
                            }
                            val diffDays = ((todayCal.timeInMillis - dStart.timeInMillis) /
                                86_400_000L).toInt()
                            if (diffDays >= offset * 7 && diffDays < (offset + 1) * 7) {
                                count++
                            }
                        }
                    }
                    WidgetTimingPoint(
                        label = "W${idx + 1}",
                        value = count.toFloat(),
                        max = maxVal,
                        isToday = offset == 0,
                        isCompleted = count > 0
                    )
                }
            }

            "year" -> {
                val curYear = cal.get(Calendar.YEAR)
                val curMonth = cal.get(Calendar.MONTH)
                val maxVal = max(20, habitIds.size * 31).toFloat()
                (0 until 12).map { mIdx ->
                    var count = 0
                    for (list in completionDates) {
                        for (iso in list) {
                            val d = parseIsoLocal(iso) ?: continue
                            val dc = Calendar.getInstance().apply { time = d }
                            if (dc.get(Calendar.YEAR) == curYear &&
                                dc.get(Calendar.MONTH) == mIdx
                            ) {
                                count++
                            }
                        }
                    }
                    WidgetTimingPoint(
                        label = monthLabels[mIdx],
                        value = count.toFloat(),
                        max = maxVal,
                        isToday = mIdx == curMonth,
                        isCompleted = count > 0
                    )
                }
            }

            else -> {
                val sunday = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    val dow = get(Calendar.DAY_OF_WEEK) // Sun=1..Sat=7
                    add(Calendar.DAY_OF_MONTH, -(dow - Calendar.SUNDAY))
                }
                val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                (0 until 7).map { i ->
                    val dayCal = (sunday.clone() as Calendar).apply {
                        add(Calendar.DAY_OF_MONTH, i)
                    }
                    val dateStr = fmt.format(dayCal.time)
                    val times = mutableListOf<Float>()
                    for (list in completionDates) {
                        val match = list.firstOrNull { it.startsWith(dateStr) } ?: continue
                        val d = parseIsoLocal(match) ?: continue
                        val dc = Calendar.getInstance().apply { time = d }
                        val hr = dc.get(Calendar.HOUR_OF_DAY) +
                            dc.get(Calendar.MINUTE) / 60f
                        times.add(24f - hr)
                    }
                    val avg = if (times.isEmpty()) 0f else times.sum() / times.size
                    WidgetTimingPoint(
                        label = weekLabels[i],
                        value = avg,
                        max = 24f,
                        isToday = dateStr == todayStr,
                        isCompleted = avg > 0f
                    )
                }
            }
        }
    }

    private fun parseIsoLocal(raw: String): Date? {
        if (raw.isEmpty()) return null
        val patterns = arrayOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        )
        for (p in patterns) {
            try {
                val sdf = SimpleDateFormat(p, Locale.US)
                if (p.endsWith("'Z'")) {
                    sdf.timeZone = TimeZone.getTimeZone("UTC")
                }
                return sdf.parse(raw)
            } catch (_: Exception) {
            }
        }
        return null
    }

    fun todayDateStr(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    fun parseColor(hex: String?, fallbackIndex: Int): Int {
        val fallback = FALLBACK_COLORS[fallbackIndex % FALLBACK_COLORS.size]
        if (hex.isNullOrBlank()) return fallback
        return try {
            val normalized = hex.trim()
            val colorStr = when {
                normalized.startsWith("#") -> normalized
                normalized.startsWith("0x", ignoreCase = true) -> "#${normalized.substring(2)}"
                else -> "#$normalized"
            }
            Color.parseColor(colorStr)
        } catch (_: Exception) {
            fallback
        }
    }

    fun resolveCategoryLabel(category: String): String {
        return when (category.lowercase(Locale.US)) {
            "health" -> "HEALTH"
            "work" -> "WORK"
            "learning" -> "LEARNING"
            "productivity" -> "PRODUCTIVITY"
            "personal" -> "PERSONAL"
            "fitness" -> "FITNESS"
            "finance" -> "FINANCE"
            "social" -> "SOCIAL"
            else -> ""
        }
    }

    fun resolveCategoryDrawable(category: String): Int? {
        return when (category.lowercase(Locale.US)) {
            "health" -> R.drawable.ic_cat_health
            "work" -> R.drawable.ic_cat_work
            "learning" -> R.drawable.ic_cat_learning
            "productivity" -> R.drawable.ic_cat_productivity
            "personal" -> R.drawable.ic_cat_personal
            "fitness" -> R.drawable.ic_cat_fitness
            "finance" -> R.drawable.ic_cat_finance
            "social" -> R.drawable.ic_cat_social
            else -> null
        }
    }

    fun colorWithAlpha(color: Int, alpha: Int): Int {
        return Color.argb(
            alpha.coerceIn(0, 255),
            Color.red(color),
            Color.green(color),
            Color.blue(color)
        )
    }
}
