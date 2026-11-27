import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atomic_habits/main.dart';
import 'package:atomic_habits/models/habit.dart';
import 'package:atomic_habits/state/habit_store.dart';
import 'package:atomic_habits/utils/habit_math.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('habit_math formulas match web app', () {
    test('calculateStreak positive quadratic formula ceil(n*n/2)', () {
      final now = DateTime(2026, 11, 26, 10, 0);
      expect(
        calculateStreak(['2026-11-26T09:00:00'], '2026-11-20T08:00:00', nowOverride: now),
        1,
      );
      expect(
        calculateStreak(
          ['2026-11-26T09:00:00', '2026-11-25T09:00:00'],
          '2026-11-20T08:00:00',
          nowOverride: now,
        ),
        2,
      );
      expect(
        calculateStreak(
          ['2026-11-26T09:00:00', '2026-11-25T09:00:00', '2026-11-24T09:00:00'],
          '2026-11-20T08:00:00',
          nowOverride: now,
        ),
        5,
      );
    });

    test('calculateStreak negative missed days locks habit up to 10 days', () {
      final now = DateTime(2026, 11, 26, 10, 0);
      // Created Nov 24, no completions -> missed Nov 25 & Nov 24 => -3
      expect(
        calculateStreak([], '2026-11-24T08:00:00', nowOverride: now),
        -3,
      );
      // Created Nov 26 (today) -> 0 missed days before today
      expect(
        calculateStreak([], '2026-11-26T08:00:00', nowOverride: now),
        0,
      );
      // Missed > 10 days -> returns 0
      expect(
        calculateStreak([], '2026-11-01T08:00:00', nowOverride: now),
        0,
      );
    });

    test('computeStats calculates points and ranks accurately', () {
      final now = DateTime(2026, 11, 26, 10, 0);
      final h = Habit(
        id: 'h1',
        name: 'Read',
        color: '#fa114f',
        createdAt: '2026-11-01T00:00:00',
        targetDays: 30,
      );
      final comps = {
        'h1': List.generate(10, (i) {
          final d = DateTime(2026, 11, 26 - i, 8, 30);
          return d.toIso8601String();
        }),
      };
      final stats = computeStats([h], [], comps, nowOverride: now);
      expect(stats.totalCompletionsCount, 10);
      expect(stats.maxStreakDays, 10);
      // 10 * 10 + ceil(10*10/2) = 100 + 50 = 150
      expect(stats.totalPoints, 150);
      expect(stats.rank, 'Achiever');
    });

    test('buildIndividualBadges awards completion bronze for targets < 3', () {
      final h = Habit(
        id: 'h2',
        name: 'Quick Sprint',
        color: '#0a84ff',
        createdAt: '2026-11-25T00:00:00',
        targetDays: 2,
        completedAt: '2026-11-26T09:00:00',
      );
      final badges = buildIndividualBadges([], [h], {
        'h2': ['2026-11-25T09:00:00', '2026-11-26T09:00:00'],
      });
      expect(badges.length, 1);
      expect(badges.first.id, 'habit_h2_completion_bronze');
      expect(badges.first.tier, 'Bronze');
    });
  });

  group('HabitStore persistence and workflows', () {
    test('add, complete to mastery, backup roundtrip, and clear', () async {
      SharedPreferences.setMockInitialValues({});
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);

      store.setUserName('Alex');
      store.addHabit(
        name: 'Meditate',
        colorHex: '#bf5af2',
        targetDays: 1,
        category: 'health',
        notes: '10 minutes morning',
      );
      expect(store.activeHabits.length, 1);
      final id = store.activeHabits.first.id;

      final mastered = store.toggleCompletion(id, formatDate(DateTime.now()));
      expect(mastered, isTrue);
      expect(store.activeHabits.length, 0);
      expect(store.allCompletedHabits.length, 1);
      expect(store.pendingCertificateHabit?.name, 'Meditate');

      store.addTodo('Buy book');
      expect(store.todos.length, 1);
      store.toggleTodo(store.todos.first.id);
      expect(store.todos.first.completed, isTrue);

      final backupJson = store.exportBackupJson();
      await store.clearAllData();
      expect(store.habits, isEmpty);
      expect(store.completedHabits, isEmpty);
      expect(store.todos, isEmpty);
      expect(store.userName, '');

      final ok = store.importBackupJson(backupJson);
      expect(ok, isTrue);
      expect(store.userName, 'Alex');
      expect(store.allCompletedHabits.length, 1);
      expect(store.todos.length, 1);
    });

    test('buildHomeWidgetPayload formats top 3 active habits and progress',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);

      expect(store.buildHomeWidgetPayload(), isEmpty);

      store.addHabit(
        name: 'Morning Run',
        colorHex: '#fa114f',
        targetDays: 10,
        category: 'health',
        notes: '',
      );
      store.addHabit(
        name: 'Deep Work',
        colorHex: '#92ff00',
        targetDays: 20,
        category: 'work',
        notes: '',
      );
      store.addHabit(
        name: 'Read 20 Pages',
        colorHex: '#00f2ff',
        targetDays: 5,
        category: 'learning',
        notes: '',
      );
      store.addHabit(
        name: 'Extra Habit',
        colorHex: '#bf5af2',
        targetDays: 7,
        category: 'other',
        notes: '',
      );

      final firstId = store.activeHabits.first.id;
      store.toggleCompletion(firstId, formatDate(DateTime.now()));

      final payload = store.buildHomeWidgetPayload();
      expect(payload.length, 3);
      expect(payload[0]['name'], 'MORNING RUN');
      expect(payload[0]['color'], '#fa114f');
      expect(payload[0]['category'], 'health');
      expect(payload[0]['categoryLabel'], 'HEALTH');
      expect(payload[0]['progress'], closeTo(0.1, 1e-6));

      expect(payload[1]['name'], 'DEEP WORK');
      expect(payload[1]['categoryLabel'], 'WORK');
      expect(payload[1]['progress'], 0.0);

      expect(payload[2]['name'], 'READ 20 PAGES');
      expect(payload[2]['categoryLabel'], 'LEARNING');

      store.addTodo('Pack gym bag');
      final bundle = store.buildAllWidgetsPayload();
      expect((bundle['rings'] as List).length, 4);
      expect((bundle['todos'] as List).length, 1);
      expect((bundle['motivation'] as Map)['text'], isNotEmpty);
      expect((bundle['timing'] as Map)['week'], hasLength(7));
      expect((bundle['timing'] as Map)['month'], hasLength(4));
      expect((bundle['timing'] as Map)['year'], hasLength(12));

      await store.clearAllData();
      expect(store.buildHomeWidgetPayload(), isEmpty);
    });

    test('handles lowered targetDays mastery and UTC completion timestamps',
        () async {
      final localMorning = DateTime(2026, 11, 27, 1, 0);
      final utcIso = localMorning.toUtc().toIso8601String();
      expect(isDateCompleted([utcIso], '2026-11-27'), isTrue);

      SharedPreferences.setMockInitialValues({});
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);
      store.addHabit(
        name: 'Stretch',
        colorHex: '#fa114f',
        targetDays: 5,
        category: 'fitness',
        notes: '',
      );
      final id = store.activeHabits.first.id;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      store.importBackupJson('''
      {
        "habits": [{"id": "$id", "name": "Stretch", "color": "#fa114f", "createdAt": "${yesterday.toIso8601String()}", "targetDays": 5, "category": "fitness"}],
        "completions": {"$id": ["${yesterday.toIso8601String()}", "${yesterday.subtract(const Duration(days: 1)).toIso8601String()}"]}
      }
      ''');
      store.updateHabit(
        id: id,
        name: 'Stretch',
        colorHex: '#fa114f',
        targetDays: 2,
        category: 'fitness',
        notes: '',
      );
      final mastered = store.toggleCompletion(id, formatDate(DateTime.now()));
      expect(mastered, isTrue);
      expect(store.activeHabits, isEmpty);
      expect(store.allCompletedHabits.length, 1);
    });
  });

  group('AtomicHabitsApp UI', () {
    testWidgets('renders home, adds habit, switches tabs, opens todo & settings',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'habitTrackerUserName': 'Sam',
      });
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);

      await tester.pumpWidget(AtomicHabitsApp(store: store));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Atomic Habits'), findsOneWidget);
      expect(find.text("Today's\nGoals"), findsOneWidget);
      expect(find.text('WEEKLY ACTIVITY'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      // Open Add Habit modal via '+' icon
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('New Habit'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Hydrate');
      await tester.enterText(find.byType(TextField).at(1), '7');
      await tester.pump();
      await tester.tap(find.text('Add'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(store.activeHabits.length, 1);
      expect(store.activeHabits.first.name, 'Hydrate');

      // Switch to Progress tab
      await tester.tap(find.byIcon(LucideIcons.activity).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Total Activity'), findsOneWidget);
      expect(find.text('HYDRATE'), findsOneWidget);

      // Switch to Badges tab
      await tester.tap(find.byIcon(LucideIcons.award));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('TOTAL POINTS'), findsOneWidget);
      expect(find.text('GLOBAL ACHIEVEMENTS'), findsOneWidget);

      // Switch to Done tab
      await tester.tap(find.byIcon(LucideIcons.checkCircle).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('COMPLETED ACHIEVEMENTS'), findsOneWidget);

      // Switch back to Home, then tap Home again to open To-Do overlay
      await tester.tap(find.byIcon(LucideIcons.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byIcon(LucideIcons.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('To-Do'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Add a new task...'), 'Drink water');
      await tester.tap(find.text('ADD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Drink water'), findsOneWidget);

      // Close To-Do overlay
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Settings tray
      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Import Data'), findsOneWidget);
      expect(find.text('Support Developer'), findsOneWidget);
      expect(find.text('Clear Data'), findsOneWidget);
      expect(find.text('saisriram Sr'), findsOneWidget);

      // Reveal hidden GPay QR inside Support Developer dialog
      expect(find.text('GPAY / UPI SUPPORT'), findsNothing);
      await tester.tap(find.text('Support Developer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('GPAY / UPI SUPPORT'), findsOneWidget);
      expect(find.text('Share QR'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('GPAY / UPI SUPPORT'), findsNothing);
    });
  });

  group('Todo reminders and customizable notifications', () {
    test('TodoModel reminderTime normalizes, formats, and serializes', () {
      expect(TodoModel.normalizeReminderTime('9:5'), '09:05');
      expect(TodoModel.normalizeReminderTime('24:00'), isNull);
      expect(TodoModel.normalizeReminderTime('null'), isNull);
      expect(TodoModel.formatReminderTime('09:30'), '9:30 AM');
      expect(TodoModel.formatReminderTime('00:05'), '12:05 AM');
      expect(TodoModel.formatReminderTime('14:15'), '2:15 PM');

      const todo = TodoModel(
        id: 't1',
        text: 'Read chapter 4',
        completed: false,
        createdAt: '2026-11-27T08:00:00',
        reminderTime: '20:00',
      );
      final json = todo.toJson();
      expect(json['reminderTime'], '20:00');
      final decoded = TodoModel.fromJson(json);
      expect(decoded.reminderTime, '20:00');
      expect(decoded.copyWith(clearReminderTime: true).reminderTime, isNull);
    });

    test('HabitStore manages notification schedule and todo edits with backup roundtrip',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);

      expect(store.notificationsEnabled, true);
      expect(store.notificationsPerDay, 2);
      expect(store.activeNotificationTimes, ['09:00', '14:00']);

      store.addTodo('Morning stretch', reminderTime: '07:30');
      final created = store.todos.first;
      expect(created.reminderTime, '07:30');

      store.updateTodo(
        id: created.id,
        text: 'Evening stretch',
        reminderTime: '19:45',
      );
      expect(store.todos.first.text, 'Evening stretch');
      expect(store.todos.first.reminderTime, '19:45');

      store.setNotificationsPerDay(3);
      store.setNotificationTime(0, '08:15');
      store.setNotifyTodos(false);

      expect(store.notificationsPerDay, 3);
      expect(store.activeNotificationTimes, ['08:15', '14:00', '18:00']);
      expect(store.notifyTodos, false);

      final notifPayload = store.buildAllWidgetsPayload()['notifications']
          as Map<String, dynamic>;
      expect(notifPayload['perDay'], 3);
      expect(notifPayload['times'], ['08:15', '14:00', '18:00']);
      expect(notifPayload['notifyHabits'], true);
      expect(notifPayload['notifyTodos'], false);

      final backup = store.exportBackupJson();
      await store.clearAllData();
      expect(store.notificationsPerDay, 2);
      expect(store.notifyTodos, true);

      expect(store.importBackupJson(backup), true);
      expect(store.notificationsPerDay, 3);
      expect(store.activeNotificationTimes, ['08:15', '14:00', '18:00']);
      expect(store.notifyTodos, false);
      expect(store.todos.first.reminderTime, '19:45');
    });

    testWidgets(
        'To-Do supports adding reminder time, long-press editing, and Settings notification customization',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'habitTrackerUserName': 'Tester'});
      final store = HabitStore();
      await store.init(fetchRemoteQuote: false);

      await tester.pumpWidget(AtomicHabitsApp(store: store));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Open To-Do overlay by tapping Home tab pill again
      await tester.tap(find.byIcon(LucideIcons.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('To-Do'), findsOneWidget);

      // Set reminder time on composer before adding
      await tester.tap(find.text('Set Reminder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Task Reminder Time'), findsOneWidget);
      await tester.tap(find.text('9:00 AM').last);
      await tester.pump();
      await tester.tap(find.text('Set Time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Remind 9:00 AM'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Add a new task...'), 'Review notes');
      await tester.tap(find.text('ADD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Review notes'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);

      // Long press task to edit text & reminder time
      await tester.longPress(find.text('Review notes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Edit Task'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Review notes'), 'Review biology notes');
      await tester.tap(find.text('CHANGE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('6:00 PM').last);
      await tester.pump();
      await tester.tap(find.text('Set Time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Review biology notes'), findsOneWidget);
      expect(find.text('6:00 PM'), findsOneWidget);

      // Close To-Do overlay and open Settings tray
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('DAILY FREQUENCY'), findsOneWidget);
      expect(find.text('2× per day'), findsOneWidget);
      expect(find.text('NOTIFICATION TIMINGS'), findsOneWidget);

      // Increase frequency to 3x and customize first timing
      await tester.tap(find.text('3×'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('3× per day'), findsOneWidget);
      expect(store.notificationsPerDay, 3);

      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Notification Time #1'), findsOneWidget);
      await tester.tap(find.text('8:00 AM').last);
      await tester.pump();
      await tester.tap(find.text('Set Time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(store.activeNotificationTimes.first, '08:00');
      expect(find.text('8:00 AM'), findsOneWidget);
    });
  });
}
