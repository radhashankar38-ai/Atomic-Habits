package com.atomichabits.atomic_habits

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val WIDGET_CHANNEL = "com.atomichabits.atomic_habits/widget"
        private const val REQ_POST_NOTIFICATIONS = 4091
    }

    private var widgetChannel: MethodChannel? = null
    private var pendingOpenTab: String? = null
    private var pendingEditTodoId: String? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractOpenArgs(intent)
        NotificationScheduler.ensureChannels(applicationContext)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val tab = intent.getStringExtra(WidgetStore.EXTRA_OPEN_TAB)
        val editTodoId = intent.getStringExtra(WidgetStore.EXTRA_EDIT_TODO_ID)
        if (tab.isNullOrEmpty() && editTodoId.isNullOrEmpty()) return

        val ch = widgetChannel
        if (ch != null) {
            ch.invokeMethod(
                "openTab",
                mapOf(
                    "tab" to (tab ?: "todo"),
                    "editTodoId" to editTodoId
                )
            )
        } else {
            if (!tab.isNullOrEmpty()) pendingOpenTab = tab
            if (!editTodoId.isNullOrEmpty()) pendingEditTodoId = editTodoId
        }
    }

    private fun extractOpenArgs(intent: Intent?) {
        val tab = intent?.getStringExtra(WidgetStore.EXTRA_OPEN_TAB)
        val editTodoId = intent?.getStringExtra(WidgetStore.EXTRA_EDIT_TODO_ID)
        if (!tab.isNullOrEmpty()) {
            pendingOpenTab = tab
        }
        if (!editTodoId.isNullOrEmpty()) {
            pendingEditTodoId = editTodoId
            if (pendingOpenTab.isNullOrEmpty()) {
                pendingOpenTab = "todo"
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            if (granted) {
                NotificationScheduler.rescheduleAll(applicationContext)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    val payload = call.argument<String>("payload") ?: "{}"
                    WidgetStore.saveAllPayloads(applicationContext, payload)
                    WidgetStore.updateAllWidgets(applicationContext)
                    NotificationScheduler.rescheduleAll(applicationContext)
                    result.success(true)
                }

                "updateWidget" -> {
                    val payload = call.argument<String>("payload") ?: "[]"
                    WidgetStore.saveLegacyRingsPayload(applicationContext, payload)
                    HabitRingsWidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                }

                "consumePendingLaunch" -> {
                    val tab = pendingOpenTab
                    val editTodoId = pendingEditTodoId
                    pendingOpenTab = null
                    pendingEditTodoId = null
                    if (tab == null && editTodoId == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "tab" to tab,
                                "editTodoId" to editTodoId
                            )
                        )
                    }
                }

                "consumePendingTab" -> {
                    val tab = pendingOpenTab
                    pendingOpenTab = null
                    pendingEditTodoId = null
                    result.success(tab)
                }

                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                        NotificationScheduler.rescheduleAll(applicationContext)
                        result.success(true)
                    } else if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        NotificationScheduler.rescheduleAll(applicationContext)
                        result.success(true)
                    } else {
                        pendingPermissionResult?.success(false)
                        pendingPermissionResult = result
                        requestPermissions(
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            REQ_POST_NOTIFICATIONS
                        )
                    }
                }

                "testNotification" -> {
                    val permitted = NotificationReceiver.canPostNotifications(applicationContext)
                    if (!permitted) {
                        result.success(false)
                    } else {
                        NotificationReceiver.sendTestNotifications(applicationContext)
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
