import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../utils/habit_math.dart';

class HabitStore extends ChangeNotifier {
  static const _kHabits = 'habits';
  static const _kCompletedHabits = 'completedHabits';
  static const _kCompletions = 'completions';
  static const _kReflections = 'reflections';
  static const _kTodos = 'todos';
  static const _kUserName = 'habitTrackerUserName';
  static const _kNotifications = 'notificationsEnabled';
  static const _kNotificationTimes = 'notificationTimes';
  static const _kNotificationsPerDay = 'notificationsPerDay';
  static const _kNotifyHabits = 'notifyHabits';
  static const _kNotifyTodos = 'notifyTodos';
  static const _kHaptics = 'hapticsEnabled';
  static const _kDailyQuote = 'dailyQuote';
  static const _widgetChannel =
      MethodChannel('com.atomichabits.atomic_habits/widget');

  static const List<String> defaultNotificationTimes = [
    '09:00',
    '14:00',
    '18:00',
    '21:00',
  ];

  SharedPreferences? _prefs;
  bool _loaded = false;

  String _userName = '';
  bool _isEditingName = true;
  List<Habit> _habits = [];
  List<Habit> _completedHabits = [];
  Map<String, List<String>> _completions = {};
  Map<String, Map<String, String>> _reflections = {};
  List<TodoModel> _todos = [];
  bool _notificationsEnabled = true;
  List<String> _notificationTimes = List<String>.from(defaultNotificationTimes);
  int _notificationsPerDay = 2;
  bool _notifyHabits = true;
  bool _notifyTodos = true;
  bool _hapticsEnabled = true;
  DailyQuote? _quote;

  // Navigation & Filters
  AppTab _activeTab = AppTab.home;
  int _tabDirection = 1;
  String _selectedCategory = 'all';
  ActivityTimeframe _totalActivityTimeframe = ActivityTimeframe.week;
  Habit? _pendingCertificateHabit;

  bool get isLoaded => _loaded;
  String get userName => _userName;
  bool get isEditingName => _isEditingName;
  List<Habit> get habits => _habits;
  List<Habit> get completedHabits => _completedHabits;
  Map<String, List<String>> get completions => _completions;
  Map<String, Map<String, String>> get reflections => _reflections;
  List<TodoModel> get todos => _todos;
  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get notificationTimes => List.unmodifiable(_notificationTimes);
  List<String> get activeNotificationTimes =>
      _notificationTimes.take(_notificationsPerDay.clamp(1, 4)).toList();
  int get notificationsPerDay => _notificationsPerDay;
  bool get notifyHabits => _notifyHabits;
  bool get notifyTodos => _notifyTodos;
  bool get hapticsEnabled => _hapticsEnabled;
  DailyQuote? get quote => _quote;

  AppTab get activeTab => _activeTab;
  int get tabDirection => _tabDirection;
  String get selectedCategory => _selectedCategory;
  ActivityTimeframe get totalActivityTimeframe => _totalActivityTimeframe;
  Habit? get pendingCertificateHabit => _pendingCertificateHabit;

  List<Habit> get activeHabits =>
      _habits.where((h) => h.completedAt == null).toList();

  List<Habit> get allCompletedHabits {
    final fromHabits = _habits.where((h) => h.completedAt != null).toList();
    final combined = [...fromHabits];
    for (final ch in _completedHabits) {
      if (!combined.any((h) => h.id == ch.id)) {
        combined.add(ch);
      }
    }
    return combined;
  }

  List<HabitCategoryOption> get usedCategories {
    final cats = activeHabits.map((h) => h.category ?? 'other').toSet();
    return habitCategories.where((c) => cats.contains(c.value)).toList();
  }

  List<Habit> get filteredActiveHabits {
    if (_selectedCategory == 'all') return activeHabits;
    return activeHabits
        .where((h) =>
            h.category == _selectedCategory ||
            (h.category == null && _selectedCategory == 'other'))
        .toList();
  }

  List<List<Habit>> get chunkedHabits {
    final filtered = filteredActiveHabits;
    final chunks = <List<Habit>>[];
    for (var i = 0; i < filtered.length; i += 3) {
      final end = min(i + 3, filtered.length);
      chunks.add(filtered.sublist(i, end));
    }
    return chunks;
  }

  UserStats get stats =>
      computeStats(_habits, _completedHabits, _completions);

  String get averageStreak => getAverageStreak(_habits, _completions);

  List<IndividualHabitBadge> get individualBadges =>
      buildIndividualBadges(_habits, _completedHabits, _completions);

  static const _defaultFallbackQuote = DailyQuote(
    text: 'A journey of a thousand miles begins with a single step.',
    author: 'Lao Tzu',
  );

  Future<void> init({bool fetchRemoteQuote = true}) async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
    _loaded = true;
    notifyListeners();
    _syncHomeWidget();
    if (fetchRemoteQuote) {
      await fetchDailyQuote();
    } else {
      _quote ??= _defaultFallbackQuote;
      notifyListeners();
    }
  }

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;

    _userName = prefs.getString(_kUserName) ?? '';
    _isEditingName = _userName.isEmpty;

    _habits = _dedupeHabits(_decodeHabitList(prefs.getString(_kHabits)));
    _completedHabits =
        _dedupeHabits(_decodeHabitList(prefs.getString(_kCompletedHabits)));
    _completions = _decodeCompletions(prefs.getString(_kCompletions));
    _reflections = _decodeReflections(prefs.getString(_kReflections));
    _todos = _decodeTodos(prefs.getString(_kTodos));
    _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
    _notificationTimes =
        _decodeNotificationTimes(prefs.getString(_kNotificationTimes));
    _notificationsPerDay =
        (prefs.getInt(_kNotificationsPerDay) ?? 2).clamp(1, 4);
    _notifyHabits = prefs.getBool(_kNotifyHabits) ?? true;
    _notifyTodos = prefs.getBool(_kNotifyTodos) ?? true;
    _hapticsEnabled = prefs.getBool(_kHaptics) ?? true;
  }

  List<Habit> _dedupeHabits(List<Habit> list) {
    final map = <String, Habit>{};
    for (final h in list) {
      map[h.id] = h;
    }
    return map.values.toList();
  }

  List<Habit> _decodeHabitList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Map<String, List<String>> _decodeCompletions(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <String, List<String>>{};
        decoded.forEach((k, v) {
          if (v is List) {
            out[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
        return out;
      }
    } catch (_) {}
    return {};
  }

  Map<String, Map<String, String>> _decodeReflections(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <String, Map<String, String>>{};
        decoded.forEach((k, v) {
          if (v is Map) {
            final inner = <String, String>{};
            v.forEach((dk, dv) {
              inner[dk.toString()] = dv.toString();
            });
            out[k.toString()] = inner;
          }
        });
        return out;
      }
    } catch (_) {}
    return {};
  }

  List<TodoModel> _decodeTodos(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => TodoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  List<String> _decodeNotificationTimes(String? raw) {
    final result = List<String>.from(defaultNotificationTimes);
    if (raw == null || raw.isEmpty) return result;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (var i = 0; i < decoded.length && i < 4; i++) {
          final norm = TodoModel.normalizeReminderTime(decoded[i]?.toString());
          if (norm != null) {
            result[i] = norm;
          }
        }
      }
    } catch (_) {}
    return result;
  }

  Future<void> _saveAll() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kHabits,
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
    await prefs.setString(
      _kCompletedHabits,
      jsonEncode(_completedHabits.map((h) => h.toJson()).toList()),
    );
    await prefs.setString(_kCompletions, jsonEncode(_completions));
    await prefs.setString(_kReflections, jsonEncode(_reflections));
    await prefs.setString(
      _kTodos,
      jsonEncode(_todos.map((t) => t.toJson()).toList()),
    );
    await prefs.setString(_kUserName, _userName);
    await prefs.setBool(_kNotifications, _notificationsEnabled);
    await prefs.setString(
      _kNotificationTimes,
      jsonEncode(_notificationTimes),
    );
    await prefs.setInt(_kNotificationsPerDay, _notificationsPerDay);
    await prefs.setBool(_kNotifyHabits, _notifyHabits);
    await prefs.setBool(_kNotifyTodos, _notifyTodos);
    await prefs.setBool(_kHaptics, _hapticsEnabled);
    await _syncHomeWidget();
  }

  static MethodChannel get widgetChannel => _widgetChannel;

  /// Builds the JSON-serializable payload consumed by Android's home screen widget (top 3 rings).
  @visibleForTesting
  List<Map<String, dynamic>> buildHomeWidgetPayload() {
    return _buildRingsList(limit: 3);
  }

  List<Map<String, dynamic>> _buildRingsList({int? limit}) {
    final todayStr = formatDate(DateTime.now());
    final visible = limit != null ? activeHabits.take(limit).toList() : activeHabits;
    return List.generate(visible.length, (i) {
      final habit = visible[i];
      final colorHex = findHabitColor(habit.color, fallbackIndex: i).hex;
      final cat = (habit.category != null && habit.category != 'other')
          ? findHabitCategory(habit.category)
          : null;
      final habitComps = _completions[habit.id] ?? const [];
      final doneToday = isDateCompleted(habitComps, todayStr);
      final double progress;
      if (habit.targetDays > 0) {
        progress = (habitComps.length / habit.targetDays).clamp(0.0, 1.0);
      } else {
        progress = habitComps.isNotEmpty ? 1.0 : 0.0;
      }
      return {
        'id': habit.id,
        'name': habit.name.toUpperCase(),
        'color': colorHex,
        'category': cat?.value ?? 'other',
        'categoryLabel': cat?.label.toUpperCase() ?? '',
        'progress': progress,
        'doneToday': doneToday,
      };
    });
  }

  List<Map<String, dynamic>> _serializeTimingBars(ActivityTimeframe tf) {
    final pts = getTotalTimingChartData(
      tf,
      _habits,
      _completedHabits,
      _completions,
    );
    return pts
        .map((p) => {
              'label': p.label,
              'value': p.value,
              'max': p.max,
              'isToday': p.isToday,
              'isCompleted': p.isCompleted,
            })
        .toList();
  }

  /// Builds the combined payload for Rings, Motivation, To-Do, and Average Timing Android widgets.
  @visibleForTesting
  Map<String, dynamic> buildAllWidgetsPayload() {
    final quote = _quote ?? _defaultFallbackQuote;
    return {
      'rings': _buildRingsList(),
      'motivation': {
        'text': quote.text,
        'author': quote.author,
        'date': formatDate(DateTime.now()),
      },
      'todos': _todos.map((t) => t.toJson()).toList(),
      'timing': {
        'week': _serializeTimingBars(ActivityTimeframe.week),
        'month': _serializeTimingBars(ActivityTimeframe.month),
        'year': _serializeTimingBars(ActivityTimeframe.year),
      },
      'notifications': {
        'enabled': _notificationsEnabled,
        'perDay': _notificationsPerDay,
        'times': activeNotificationTimes,
        'allTimes': _notificationTimes,
        'notifyHabits': _notifyHabits,
        'notifyTodos': _notifyTodos,
      },
    };
  }

  Future<void> _syncHomeWidget() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _widgetChannel.invokeMethod<bool>(
        'updateWidgets',
        {'payload': jsonEncode(buildAllWidgetsPayload())},
      );
    } on MissingPluginException {
      // No host channel attached during headless Flutter tests.
    } catch (_) {}
  }

  /// Reloads todos and daily quote written directly by Android home screen widgets.
  Future<void> reloadExternalChanges() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.reload();
    } catch (_) {}

    var changed = false;
    final todosRaw = prefs.getString(_kTodos);
    if (todosRaw != null) {
      final decoded = _decodeTodos(todosRaw);
      final encodedCurrent = jsonEncode(_todos.map((t) => t.toJson()).toList());
      if (encodedCurrent != todosRaw) {
        _todos = decoded;
        changed = true;
      }
    }

    final quoteRaw = prefs.getString(_kDailyQuote);
    if (quoteRaw != null && quoteRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(quoteRaw);
        if (decoded is Map) {
          final nextText = (decoded['text'] ?? '').toString();
          final nextAuthor = (decoded['author'] ?? 'Unknown').toString();
          if (nextText.isNotEmpty &&
              (_quote?.text != nextText || _quote?.author != nextAuthor)) {
            _quote = DailyQuote(text: nextText, author: nextAuthor);
            changed = true;
          }
        }
      } catch (_) {}
    }

    if (changed) {
      notifyListeners();
    }
  }

  void triggerHaptic({bool heavy = false}) {
    if (!_hapticsEnabled) return;
    if (heavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> fetchDailyQuote() async {
    final today = formatDate(DateTime.now());
    final stored = _prefs?.getString(_kDailyQuote);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map && decoded['date'] == today) {
          _quote = DailyQuote(
            text: (decoded['text'] ?? '').toString(),
            author: (decoded['author'] ?? 'Unknown').toString(),
          );
          notifyListeners();
          _syncHomeWidget();
          return;
        }
      } catch (_) {}
    }

    try {
      final res = await http
          .get(Uri.parse('https://dummyjson.com/quotes/random'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['quote'] != null) {
          final newQuote = DailyQuote(
            text: data['quote'].toString(),
            author: (data['author'] ?? 'Unknown').toString(),
          );
          _quote = newQuote;
          await _prefs?.setString(
            _kDailyQuote,
            jsonEncode({
              'text': newQuote.text,
              'author': newQuote.author,
              'date': today,
            }),
          );
          notifyListeners();
          _syncHomeWidget();
          return;
        }
      }
    } catch (_) {}

    _quote = _defaultFallbackQuote;
    notifyListeners();
    _syncHomeWidget();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
    _saveAll();
  }

  void setEditingName(bool editing) {
    if (!editing && _userName.trim().isEmpty) return;
    _isEditingName = editing;
    notifyListeners();
  }

  void setActiveTab(AppTab tab) {
    if (_activeTab == tab) return;
    _tabDirection = tab.index > _activeTab.index ? 1 : -1;
    _activeTab = tab;
    triggerHaptic();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    triggerHaptic();
    notifyListeners();
  }

  void _ensureValidCategory() {
    if (_selectedCategory != 'all' &&
        !usedCategories.any((c) => c.value == _selectedCategory)) {
      _selectedCategory = 'all';
    }
  }

  void setTotalActivityTimeframe(ActivityTimeframe timeframe) {
    _totalActivityTimeframe = timeframe;
    triggerHaptic();
    notifyListeners();
  }

  void cycleTotalActivityTimeframe(int delta) {
    const order = ActivityTimeframe.values;
    final idx = order.indexOf(_totalActivityTimeframe);
    final nextIdx = (idx + delta + order.length) % order.length;
    setTotalActivityTimeframe(order[nextIdx]);
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    triggerHaptic();
    notifyListeners();
    _saveAll();
    if (enabled) {
      requestNotificationPermission();
    }
  }

  void setNotificationsPerDay(int count) {
    final clamped = count.clamp(1, 4);
    if (_notificationsPerDay == clamped) return;
    _notificationsPerDay = clamped;
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void setNotificationTime(int index, String hhmm) {
    if (index < 0 || index >= 4) return;
    final normalized = TodoModel.normalizeReminderTime(hhmm);
    if (normalized == null) return;
    final next = List<String>.from(_notificationTimes);
    next[index] = normalized;
    _notificationTimes = next;
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void setNotifyHabits(bool enabled) {
    _notifyHabits = enabled;
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void setNotifyTodos(bool enabled) {
    _notifyTodos = enabled;
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _widgetChannel
              .invokeMethod<bool>('requestNotificationPermission') ??
          true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTestNotification({String kind = 'habits'}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await _syncHomeWidget();
      return await _widgetChannel.invokeMethod<bool>(
            'testNotification',
            {'kind': kind},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    if (enabled) HapticFeedback.lightImpact();
    notifyListeners();
    _saveAll();
  }

  String _generateId() {
    final rng = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r = rng.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return '$ts-$r';
  }

  void addHabit({
    required String name,
    required String colorHex,
    required int targetDays,
    required String category,
    required String notes,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final newHabit = Habit(
      id: _generateId(),
      name: trimmed,
      color: colorHex,
      createdAt: DateTime.now().toIso8601String(),
      targetDays: targetDays,
      category: category,
      notes: notes.trim(),
    );
    _habits = [..._habits, newHabit];
    _completions = {..._completions, newHabit.id: []};
    triggerHaptic(heavy: true);
    notifyListeners();
    _saveAll();
  }

  void updateHabit({
    required String id,
    required String name,
    required String colorHex,
    required int targetDays,
    required String category,
    required String notes,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _habits = _habits
        .map((h) => h.id == id
            ? h.copyWith(
                name: trimmed,
                color: colorHex,
                targetDays: targetDays,
                category: category,
                notes: notes.trim(),
              )
            : h)
        .toList();
    _ensureValidCategory();
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void resetHabitProgress(String habitId) {
    _completions = {..._completions, habitId: []};
    _habits = _habits
        .map((h) => h.id == habitId
            ? h.copyWith(createdAt: DateTime.now().toIso8601String())
            : h)
        .toList();
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void deleteHabit(String habitId) {
    _habits = _habits.where((h) => h.id != habitId).toList();
    _completedHabits = _completedHabits.where((h) => h.id != habitId).toList();
    final updated = Map<String, List<String>>.from(_completions);
    updated.remove(habitId);
    _completions = updated;
    _ensureValidCategory();
    triggerHaptic(heavy: true);
    notifyListeners();
    _saveAll();
  }

  /// Returns true if completing this habit triggered goal mastery completion.
  bool toggleCompletion(String habitId, String dateStr) {
    final habitIdx = _habits.indexWhere((h) => h.id == habitId);
    if (habitIdx == -1) return false;
    final habit = _habits[habitIdx];

    final actualTodayStr = formatDate(DateTime.now());
    if (dateStr != actualTodayStr) return false;

    final habitCompletions = List<String>.from(_completions[habitId] ?? []);
    final currentStreak = calculateStreak(habitCompletions, habit.createdAt);

    if (currentStreak < 0 && !isDateCompleted(habitCompletions, dateStr)) {
      return false;
    }

    var mastered = false;
    if (isDateCompleted(habitCompletions, dateStr)) {
      _completions = {
        ..._completions,
        habitId: habitCompletions
            .where((d) => !isDateCompleted([d], dateStr))
            .toList(),
      };
      triggerHaptic();
    } else {
      final nowIso = DateTime.now().toIso8601String();
      final newCompletions = [...habitCompletions, nowIso];
      _completions = {
        ..._completions,
        habitId: newCompletions,
      };
      triggerHaptic(heavy: true);

      if (habit.targetDays > 0 && newCompletions.length >= habit.targetDays) {
        mastered = true;
        final completedHabit = habit.copyWith(completedAt: nowIso);
        _pendingCertificateHabit = completedHabit;
        _habits = _habits.where((h) => h.id != habitId).toList();
        if (!_completedHabits.any((h) => h.id == habitId)) {
          _completedHabits = [..._completedHabits, completedHabit];
        }
        _ensureValidCategory();
      }
    }

    notifyListeners();
    _saveAll();
    return mastered;
  }

  void clearPendingCertificate() {
    _pendingCertificateHabit = null;
    notifyListeners();
  }

  void saveReflection(String habitId, String date, String content) {
    final currentHabitRefs =
        Map<String, String>.from(_reflections[habitId] ?? {});
    currentHabitRefs[date] = content;
    _reflections = {
      ..._reflections,
      habitId: currentHabitRefs,
    };
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void addTodo(String text, {String? reminderTime}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final todo = TodoModel(
      id: _generateId(),
      text: trimmed,
      completed: false,
      createdAt: DateTime.now().toIso8601String(),
      reminderTime: TodoModel.normalizeReminderTime(reminderTime),
    );
    _todos = [todo, ..._todos];
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void updateTodo({
    required String id,
    required String text,
    String? reminderTime,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final normalized = TodoModel.normalizeReminderTime(reminderTime);
    var updated = false;
    _todos = _todos.map((t) {
      if (t.id != id) return t;
      updated = true;
      return t.copyWith(
        text: trimmed,
        reminderTime: normalized,
        clearReminderTime: normalized == null,
      );
    }).toList();
    if (!updated) return;
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void toggleTodo(String id) {
    _todos = _todos
        .map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t)
        .toList();
    triggerHaptic();
    notifyListeners();
    _saveAll();
  }

  void removeTodo(String id) {
    _todos = _todos.where((t) => t.id != id).toList();
    triggerHaptic(heavy: true);
    notifyListeners();
    _saveAll();
  }

  String exportBackupJson() {
    final payload = {
      'habits': _habits.map((h) => h.toJson()).toList(),
      'completedHabits': _completedHabits.map((h) => h.toJson()).toList(),
      'completions': _completions,
      'reflections': _reflections,
      'todos': _todos.map((t) => t.toJson()).toList(),
      'userName': _userName,
      'notificationsEnabled': _notificationsEnabled,
      'notificationTimes': _notificationTimes,
      'notificationsPerDay': _notificationsPerDay,
      'notifyHabits': _notifyHabits,
      'notifyTodos': _notifyTodos,
      'hapticsEnabled': _hapticsEnabled,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  bool importBackupJson(String jsonText) {
    try {
      final data = jsonDecode(jsonText);
      if (data is! Map) return false;

      if (data['habits'] is List) {
        _habits = _dedupeHabits(
          (data['habits'] as List)
              .whereType<Map>()
              .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      if (data['completedHabits'] is List) {
        _completedHabits = _dedupeHabits(
          (data['completedHabits'] as List)
              .whereType<Map>()
              .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      if (data['completions'] is Map) {
        final out = <String, List<String>>{};
        (data['completions'] as Map).forEach((k, v) {
          if (v is List) {
            out[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
        _completions = out;
      }
      if (data['reflections'] is Map) {
        final out = <String, Map<String, String>>{};
        (data['reflections'] as Map).forEach((k, v) {
          if (v is Map) {
            final inner = <String, String>{};
            v.forEach((dk, dv) {
              inner[dk.toString()] = dv.toString();
            });
            out[k.toString()] = inner;
          }
        });
        _reflections = out;
      }
      if (data['todos'] is List) {
        _todos = (data['todos'] as List)
            .whereType<Map>()
            .map((e) => TodoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['userName'] is String) {
        _userName = data['userName'] as String;
        _isEditingName = _userName.isEmpty;
      }
      if (data['notificationsEnabled'] is bool) {
        _notificationsEnabled = data['notificationsEnabled'] as bool;
      }
      if (data['notificationTimes'] is List) {
        final next = List<String>.from(defaultNotificationTimes);
        final rawList = data['notificationTimes'] as List;
        for (var i = 0; i < rawList.length && i < 4; i++) {
          final norm = TodoModel.normalizeReminderTime(rawList[i]?.toString());
          if (norm != null) next[i] = norm;
        }
        _notificationTimes = next;
      }
      if (data['notificationsPerDay'] is num) {
        _notificationsPerDay =
            (data['notificationsPerDay'] as num).toInt().clamp(1, 4);
      }
      if (data['notifyHabits'] is bool) {
        _notifyHabits = data['notifyHabits'] as bool;
      }
      if (data['notifyTodos'] is bool) {
        _notifyTodos = data['notifyTodos'] as bool;
      }
      if (data['hapticsEnabled'] is bool) {
        _hapticsEnabled = data['hapticsEnabled'] as bool;
      }

      _ensureValidCategory();
      triggerHaptic(heavy: true);
      notifyListeners();
      _saveAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    await _prefs?.clear();
    _habits = [];
    _completedHabits = [];
    _completions = {};
    _reflections = {};
    _todos = [];
    _userName = '';
    _isEditingName = true;
    _activeTab = AppTab.home;
    _selectedCategory = 'all';
    _pendingCertificateHabit = null;
    _notificationsEnabled = true;
    _notificationTimes = List<String>.from(defaultNotificationTimes);
    _notificationsPerDay = 2;
    _notifyHabits = true;
    _notifyTodos = true;
    _hapticsEnabled = true;
    triggerHaptic(heavy: true);
    notifyListeners();
    await _syncHomeWidget();
    await fetchDailyQuote();
  }
}
