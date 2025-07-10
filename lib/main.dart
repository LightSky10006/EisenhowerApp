import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:math' as math;
//import 'package:hive_flutter/hive_flutter.dart';
//import 'package:path_provider/path_provider.dart' as path_provider;
//part 'task.g.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EisenhowerApp());
}

class Task {
  String title;
  int quadrant; // 0:重要且緊急, 1:重要不緊急, 2:不重要但緊急, 3:不重要不緊急
  int importance; // -5~+5
  int urgency; // -5~+5
  int? id;
  Task(this.title, this.quadrant, {this.importance = 0, this.urgency = 0, this.id});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'quadrant': quadrant,
    'importance': importance,
    'urgency': urgency,
  };
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    map['title'],
    map['quadrant'],
    importance: map['importance'],
    urgency: map['urgency'],
    id: map['id'],
  );
}

enum AppThemeMode { light, dark, system, cyberpunk }
enum AppLanguage { zh, en }

class EisenhowerApp extends StatefulWidget {
  const EisenhowerApp({super.key});
  @override
  State<EisenhowerApp> createState() => _EisenhowerAppState();
}

class _EisenhowerAppState extends State<EisenhowerApp> {
  AppThemeMode _themeMode = AppThemeMode.light;
  AppLanguage _language = AppLanguage.zh;
  int _currentIndex = 0;
  final List<Task> tasks = [];

  Database? _db;

  // 主題色定義集中管理
  static const cyberpunkPrimary = Color(0xFFFFF000); // 螢光黃
  static const cyberpunkSecondary = Color(0xFF00FFF7); // 螢光藍
  static const cyberpunkSurface = Color(0xFF2D1B3C); // 紫
  static const cyberpunkBackground = Color(0xFF1A1832); // 深藍紫

  void _setThemeMode(AppThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _savePreferences();
  }

  void _setLanguage(AppLanguage lang) {
    setState(() {
      _language = lang;
    });
    _savePreferences();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initDb();
    }
    _loadPreferences();
  }

  Future<void> _initDb() async {
    try {
      if (kIsWeb) return;
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tasks.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            quadrant INTEGER,
            importance INTEGER,
            urgency INTEGER
          )''');
        },
      );
      await _loadTasks();
    } catch (e, s) {
      print('DB INIT ERROR: $e\n$s');
    }
  }

  Future<void> _loadTasks() async {
    try {
      if (kIsWeb) return;
      if (_db == null) return;
      final list = await _db!.query('tasks');
      setState(() {
        tasks.clear();
        tasks.addAll(list.map((e) => Task.fromMap(e)).toList());
      });
    } catch (e, s) {
      print('LOAD TASKS ERROR: $e\n$s');
    }
  }

  Future<void> _saveTask(Task task) async {
    try {
      if (kIsWeb) {
        setState(() {
          if (task.id == null) {
            task.id = DateTime.now().millisecondsSinceEpoch;
            tasks.add(task);
          } else {
            final idx = tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) tasks[idx] = task;
          }
        });
        return;
      }
      if (_db == null) return;
      if (task.id == null) {
        task.id = await _db!.insert('tasks', task.toMap());
      } else {
        await _db!.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
      }
      await _loadTasks();
    } catch (e, s) {
      print('SAVE TASK ERROR: $e\n$s');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      if (kIsWeb) {
        setState(() {
          tasks.removeWhere((t) => t.id == task.id);
        });
        return;
      }
      if (_db == null || task.id == null) return;
      await _db!.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
      await _loadTasks();
    } catch (e, s) {
      print('DELETE TASK ERROR: $e\n$s');
    }
  }
  Future<void> _loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 0;
  final langIndex = prefs.getInt('language') ?? 0;
  setState(() {
    _themeMode = AppThemeMode.values[themeIndex];
    _language = AppLanguage.values[langIndex];
  });
}

Future<void> _savePreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeMode', _themeMode.index);
  await prefs.setInt('language', _language.index);
}

  ThemeMode get materialThemeMode {
    // 只在 cyberpunk 時回傳 null，讓 MaterialApp 用 highContrastTheme
    if (_themeMode == AppThemeMode.cyberpunk) {
      return ThemeMode.system; // 或 ThemeMode.light，並配合 highContrastTheme
    }
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  ThemeData get cyberpunkTheme => ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFFFFF000), // 螢光黃
          onPrimary: Colors.black,
          secondary: const Color(0xFF00FFF7), // 螢光藍
          onSecondary: Colors.black,
          error: Colors.pinkAccent,
          onError: Colors.black,
          surface: const Color(0xFF2D1B3C), // 紫
          onSurface: Colors.cyanAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1832),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF000),
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFF000)),
          bodyLarge: TextStyle(color: Color(0xFFFFF000)),
          titleLarge: TextStyle(color: Color(0xFF00FFF7)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF00FFF7)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFF000),
          foregroundColor: Colors.black,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isCyberpunk = _themeMode == AppThemeMode.cyberpunk;
    final isDark = _themeMode == AppThemeMode.dark;
    final lang = _language;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isCyberpunk) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: cyberpunkPrimary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ));
      } else if (isDark) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ));
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ));
      }
    });

    return MaterialApp(
      title: lang == AppLanguage.zh ? 'Eisenhower Matrix Todo' : 'Eisenhower Matrix Todo',
      theme: isCyberpunk ? cyberpunkTheme : ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        brightness: Brightness.light,
      ),
      darkTheme: isDark ? ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ) : null,
      themeMode: isCyberpunk ? ThemeMode.light : 
                isDark ? ThemeMode.dark : 
                _themeMode == AppThemeMode.system ? ThemeMode.system : ThemeMode.light,
      home: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: isCyberpunk ? cyberpunkBackground : null,
            body: IndexedStack(
              index: _currentIndex,
              children: [
                EisenhowerListScreen(
                  tasks: tasks,
                  onAdd: _showAddTaskDialog,
                  onEdit: _showEditTaskDialog,
                  onDelete: _deleteTask,
                  language: lang,
                ),
                QuadrantPlaneScreen(
                  tasks: tasks, 
                  isCyberpunk: isCyberpunk, 
                  language: lang,
                  onAdd: _showAddTaskDialog,
                  onEdit: _showEditTaskDialog,
                ),
                SettingsScreen(
                  themeMode: _themeMode,
                  onThemeChanged: _setThemeMode,
                  language: lang,
                  onLanguageChanged: _setLanguage,
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: isCyberpunk ? cyberpunkSurface : Theme.of(context).colorScheme.surface,
              selectedItemColor: isCyberpunk ? cyberpunkPrimary : Theme.of(context).colorScheme.primary,
              unselectedItemColor: isCyberpunk ? cyberpunkSecondary : Theme.of(context).unselectedWidgetColor,
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.list), label: lang == AppLanguage.zh ? '清單' : 'List'),
                BottomNavigationBarItem(icon: const Icon(Icons.grid_4x4), label: lang == AppLanguage.zh ? '座標' : 'Plane'),
                BottomNavigationBarItem(icon: const Icon(Icons.settings), label: lang == AppLanguage.zh ? '設定' : 'Settings'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, int quadrant, {double? coordinateImportance, double? coordinateUrgency}) async {
    final TextEditingController dialogController = TextEditingController();
    // 根據象限設定權重範圍
    int minImportance = -5, maxImportance = 5, minUrgency = -5, maxUrgency = 5;
    int defaultImportance = 0, defaultUrgency = 0;
    
    // 如果有提供座標值，使用座標值作為預設值
    if (coordinateImportance != null && coordinateUrgency != null) {
      defaultImportance = coordinateImportance.round().clamp(-5, 5);
      defaultUrgency = coordinateUrgency.round().clamp(-5, 5);
    } else {
      // 否則使用象限預設值
      switch (quadrant) {
        case 0: // 重要且緊急
          minImportance = 1;
          maxImportance = 5;
          minUrgency = 1;
          maxUrgency = 5;
          defaultImportance = 3;
          defaultUrgency = 3;
          break;
        case 1: // 重要不緊急
          minImportance = 1;
          maxImportance = 5;
          minUrgency = -5;
          maxUrgency = 0;
          defaultImportance = 3;
          defaultUrgency = -3;
          break;
        case 2: // 不重要但緊急
          minImportance = -5;
          maxImportance = 0;
          minUrgency = 1;
          maxUrgency = 5;
          defaultImportance = -3;
          defaultUrgency = 3;
          break;
        case 3: // 不重要不緊急
          minImportance = -5;
          maxImportance = 0;
          minUrgency = -5;
          maxUrgency = 0;
          defaultImportance = -3;
          defaultUrgency = -3;
          break;
      }
    }
    
    int importance = defaultImportance;
    int urgency = defaultUrgency;
    final lang = _language;
    final quadrantTitle = lang == AppLanguage.zh
        ? EisenhowerListScreen.quadrantTitlesZh[quadrant]
        : EisenhowerListScreen.quadrantTitlesEn[quadrant];
    final addTitle = coordinateImportance != null && coordinateUrgency != null
        ? (lang == AppLanguage.zh ? '新增待辦事項 ($defaultImportance, $defaultUrgency)' : 'Add Task ($defaultImportance, $defaultUrgency)')
        : (lang == AppLanguage.zh ? '新增到「$quadrantTitle」' : 'Add to "$quadrantTitle"');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(addTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dialogController,
                autofocus: true,
                decoration: InputDecoration(labelText: lang == AppLanguage.zh ? '輸入待辦事項' : 'Enter todo'),
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    final newTask = Task(value.trim(), quadrant, importance: importance, urgency: urgency);
                    await _saveTask(newTask);
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(lang == AppLanguage.zh ? '重要程度' : 'Importance'),
                  Expanded(
                    child: Slider(
                      value: importance.toDouble(),
                      min: minImportance.toDouble(),
                      max: maxImportance.toDouble(),
                      divisions: (maxImportance-minImportance),
                      label: importance.toString(),
                      onChanged: (v) {
                        importance = v.round();
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  Text(importance.toString()),
                ],
              ),
              Row(
                children: [
                  Text(lang == AppLanguage.zh ? '緊急程度' : 'Urgency'),
                  Expanded(
                    child: Slider(
                      value: urgency.toDouble(),
                      min: minUrgency.toDouble(),
                      max: maxUrgency.toDouble(),
                      divisions: (maxUrgency-minUrgency),
                      label: urgency.toString(),
                      onChanged: (v) {
                        urgency = v.round();
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  Text(urgency.toString()),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(lang == AppLanguage.zh ? '取消' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dialogController.text.trim().isNotEmpty) {
                  final newTask = Task(dialogController.text.trim(), quadrant, importance: importance, urgency: urgency);
                  await _saveTask(newTask);
                  Navigator.of(context).pop();
                }
              },
              child: Text(lang == AppLanguage.zh ? '新增' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    final TextEditingController dialogController = TextEditingController(text: task.title);
    final originalQuadrant = task.quadrant;
    
    // 根據象限設定權重範圍
    int minImportance = -5, maxImportance = 5, minUrgency = -5, maxUrgency = 5;
    switch (originalQuadrant) {
      case 0: // 重要且緊急
        minImportance = 1;
        maxImportance = 5;
        minUrgency = 1;
        maxUrgency = 5;
        break;
      case 1: // 重要不緊急
        minImportance = 1;
        maxImportance = 5;
        minUrgency = -5;
        maxUrgency = 0;
        break;
      case 2: // 不重要但緊急
        minImportance = -5;
        maxImportance = 0;
        minUrgency = 1;
        maxUrgency = 5;
        break;
      case 3: // 不重要不緊急
        minImportance = -5;
        maxImportance = 0;
        minUrgency = -5;
        maxUrgency = 0;
        break;
    }
    
    int importance = task.importance;
    int urgency = task.urgency;
    final lang = _language;
    final quadrantTitle = lang == AppLanguage.zh
        ? EisenhowerListScreen.quadrantTitlesZh[originalQuadrant]
        : EisenhowerListScreen.quadrantTitlesEn[originalQuadrant];
    final editTitle = lang == AppLanguage.zh ? '修改「$quadrantTitle」事項' : 'Edit "$quadrantTitle" Task';
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: lang == AppLanguage.zh ? '修改待辦事項' : 'Edit todo'),
                    onSubmitted: (value) async {
                      if (value.trim().isNotEmpty) {
                        task.title = value.trim();
                        task.importance = importance;
                        task.urgency = urgency;
                        await _saveTask(task);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(lang == AppLanguage.zh ? '重要程度' : 'Importance'),
                      Expanded(
                        child: Slider(
                          value: importance.toDouble(),
                          min: minImportance.toDouble(),
                          max: maxImportance.toDouble(),
                          divisions: (maxImportance-minImportance),
                          label: importance.toString(),
                          onChanged: (v) {
                            setDialogState(() {
                              importance = v.round();
                            });
                          },
                        ),
                      ),
                      Text(importance.toString()),
                    ],
                  ),
                  Row(
                    children: [
                      Text(lang == AppLanguage.zh ? '緊急程度' : 'Urgency'),
                      Expanded(
                        child: Slider(
                          value: urgency.toDouble(),
                          min: minUrgency.toDouble(),
                          max: maxUrgency.toDouble(),
                          divisions: (maxUrgency-minUrgency),
                          label: urgency.toString(),
                          onChanged: (v) {
                            setDialogState(() {
                              urgency = v.round();
                            });
                          },
                        ),
                      ),
                      Text(urgency.toString()),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(lang == AppLanguage.zh ? '取消' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _deleteTask(task);
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(lang == AppLanguage.zh ? '刪除' : 'Delete'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogController.text.trim().isNotEmpty) {
                      task.title = dialogController.text.trim();
                      task.importance = importance;
                      task.urgency = urgency;
                      await _saveTask(task);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(lang == AppLanguage.zh ? '儲存' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class EisenhowerListScreen extends StatelessWidget {
  static const quadrantTitlesZh = [
    '重要且緊急',
    '重要不緊急',
    '不重要但緊急',
    '不重要不緊急',
  ];
  static const quadrantTitlesEn = [
    'Important & Urgent',
    'Important, Not Urgent',
    'Not Important, Urgent',
    'Not Important, Not Urgent',
  ];
  final List<Task> tasks;
  final Future<void> Function(BuildContext, int quadrant, {double? coordinateImportance, double? coordinateUrgency}) onAdd;
  final Future<void> Function(BuildContext, Task) onEdit;
  final void Function(Task) onDelete;
  final AppLanguage language;
  const EisenhowerListScreen({super.key, required this.tasks, required this.onAdd, required this.onEdit, required this.onDelete, required this.language});

  @override
  Widget build(BuildContext context) {
    final titles = language == AppLanguage.zh ? quadrantTitlesZh : quadrantTitlesEn;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          // 2行2列，childAspectRatio = (每格寬/每格高)
          final aspect = (width / 2) / (height / 2);
          return GridView.builder(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspect,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: 4,
            itemBuilder: (context, i) {
              final quadrantTasks = tasks.where((t) => t.quadrant == i).toList();
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onAdd(context, i),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[i],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        Expanded(
                          child: quadrantTasks.isEmpty
                              ? Center(
                                  child: Text(
                                    language == AppLanguage.zh ? '點擊新增' : 'Tap to add',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: quadrantTasks.length,
                                  itemBuilder: (context, j) {
                                    final task = quadrantTasks[j];
                                    return Dismissible(
                                      key: Key('task_${task.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        color: Colors.red,
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(language == AppLanguage.zh ? '確認刪除' : 'Confirm Delete'),
                                            content: Text(language == AppLanguage.zh ? '確定要刪除這個待辦事項嗎？' : 'Are you sure you want to delete this task?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text(language == AppLanguage.zh ? '取消' : 'Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: Text(language == AppLanguage.zh ? '刪除' : 'Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ?? false;
                                      },
                                      onDismissed: (direction) {
                                        onDelete(task);
                                      },
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('${task.title} (${task.importance},${task.urgency})'),
                                        onTap: () => onEdit(context, task),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class QuadrantPlaneScreen extends StatefulWidget {
  final List<Task> tasks;
  final bool isCyberpunk;
  final AppLanguage language;
  final Future<void> Function(BuildContext, int, {double? coordinateImportance, double? coordinateUrgency})? onAdd;
  final Future<void> Function(BuildContext, Task)? onEdit;
  const QuadrantPlaneScreen({
    super.key, 
    required this.tasks, 
    this.isCyberpunk = false, 
    required this.language,
    this.onAdd,
    this.onEdit,
  });

  @override
  State<QuadrantPlaneScreen> createState() => _QuadrantPlaneScreenState();
}

class _QuadrantPlaneScreenState extends State<QuadrantPlaneScreen> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Size _lastSize;
  Offset? _lastTapPosition; // 記錄最後一次點擊位置
  
  // 將螢幕座標轉換為邏輯座標
  Offset _screenToLogicalCoordinate(Offset screenPos) {
    final margin = 30.0;
    final plotWidth = _lastSize.width - 2 * margin;
    final plotHeight = _lastSize.height - 2 * margin;
    final centerX = _lastSize.width / 2;
    final centerY = _lastSize.height / 2;
    
    // 計算座標系統的實際範圍（基於畫面比例）
    final aspectRatio = plotWidth / plotHeight;
    double xRange = 10.0;
    double yRange = 10.0;
    
    if (aspectRatio > 1) {
      xRange = 10.0 * aspectRatio;
    } else {
      yRange = 10.0 / aspectRatio;
    }
    
    // 考慮縮放和平移的逆變換
    final transformedX = (screenPos.dx - centerX - _offset.dx) / _scale + centerX;
    final transformedY = (screenPos.dy - centerY - _offset.dy) / _scale + centerY;
    
    // 轉換為邏輯座標
    final logicalX = (transformedX - centerX) / (plotWidth / xRange);
    final logicalY = -(transformedY - centerY) / (plotHeight / yRange);
    
    return Offset(logicalX, logicalY);
  }
  
  // 檢查點擊是否在任務點上
  Task? _hitTestTask(Offset screenPos) {
    final logicalPos = _screenToLogicalCoordinate(screenPos);
    const hitRadius = 0.8; // 在邏輯座標系中的點擊半徑
    
    for (final task in widget.tasks) {
      // 正確的座標映射：importance 對應 X 軸，urgency 對應 Y 軸
      final taskLogicalX = task.importance.toDouble();
      final taskLogicalY = task.urgency.toDouble();
      
      final distance = (Offset(taskLogicalX, taskLogicalY) - logicalPos).distance;
      if (distance <= hitRadius) {
        return task;
      }
    }
    return null;
  }
  
  // 處理點擊事件
  void _handleTap(BuildContext context) async {
    if (_lastTapPosition == null) return;
    
    final tappedTask = _hitTestTask(_lastTapPosition!);
    
    if (tappedTask != null) {
      // 點擊到任務點，編輯任務
      if (widget.onEdit != null) {
        await widget.onEdit!(context, tappedTask);
      }
    } else {
      // 點擊空白處，新增任務
      if (widget.onAdd != null) {
        final logicalPos = _screenToLogicalCoordinate(_lastTapPosition!);
        
        // 檢查座標是否超出範圍 (-5 到 +5)
        if (logicalPos.dx.abs() > 5.0 || logicalPos.dy.abs() > 5.0) {
          // 超出範圍，不允許新增，可以選擇顯示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.language == AppLanguage.zh 
                ? '請在有效範圍內點擊（-5 到 +5）' 
                : 'Please click within valid range (-5 to +5)'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // 將邏輯座標轉換回象限索引
        int quadrantIndex = 0;
        if (logicalPos.dx >= 0 && logicalPos.dy >= 0) {
          quadrantIndex = 0; // 右上：重要且緊急
        } else if (logicalPos.dx < 0 && logicalPos.dy >= 0) {
          quadrantIndex = 1; // 左上：重要不緊急
        } else if (logicalPos.dx < 0 && logicalPos.dy < 0) {
          quadrantIndex = 3; // 左下：不重要不緊急
        } else {
          quadrantIndex = 2; // 右下：不重要但緊急
        }
        
        // 傳遞實際的座標值作為重要程度和緊急程度
        await widget.onAdd!(context, quadrantIndex, 
          coordinateImportance: logicalPos.dx, 
          coordinateUrgency: logicalPos.dy);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: (details) {
            // 記錄點擊位置
            _lastTapPosition = details.localPosition;
          },
          onTap: () => _handleTap(context),
          onScaleStart: (details) {
            // 手勢開始時不需要特別處理
          },
          onScaleUpdate: (details) {
            setState(() {
              // 計算縮放中心
              final focalPoint = details.focalPoint;
              final center = Offset(_lastSize.width / 2, _lastSize.height / 2);
              
              // 記錄縮放前的狀態
              final oldScale = _scale;
              final oldOffset = _offset;
              
              // 更新縮放
              _scale = (_scale * details.scale).clamp(0.3, 8.0);
              
              // 計算縮放導致的偏移變化
              final scaleChange = _scale / oldScale;
              final focalPointInCanvas = focalPoint - center - oldOffset;
              final newFocalPointInCanvas = focalPointInCanvas * scaleChange;
              final scaleDelta = newFocalPointInCanvas - focalPointInCanvas;
              
              // 更新偏移：包含縮放補償和平移
              _offset = oldOffset - scaleDelta + details.focalPointDelta;
              
              // 限制平移範圍
              final maxOffset = 800.0 / _scale;
              _offset = Offset(
                _offset.dx.clamp(-maxOffset, maxOffset),
                _offset.dy.clamp(-maxOffset, maxOffset),
              );
            });
          },
          onDoubleTap: () {
            // 雙擊重置
            setState(() {
              _scale = 1.0;
              _offset = Offset.zero;
            });
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: widget.isCyberpunk 
                ? _EisenhowerAppState.cyberpunkBackground
                : (isDark ? Color(0xFF1E1E1E) : Color(0xFFFAFAFA)),
            ),
            child: CustomPaint(
              painter: QuadrantPainter(
                widget.tasks, 
                isDark: isDark, 
                isCyberpunk: widget.isCyberpunk, 
                language: widget.language,
                scale: _scale,
                offset: _offset,
              ),
              child: Container(),
            ),
          ),
        );
      },
    );
  }
}

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;
  final bool isDark;
  final bool isCyberpunk;
  final AppLanguage language;
  final double scale;
  final Offset offset;
  
  QuadrantPainter(
    this.tasks, {
    this.isDark = false, 
    this.isCyberpunk = false, 
    required this.language,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 顏色定義 - 完全 GeoGebra 風格
    final axisColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkPrimary
        : (isDark ? Colors.white : Colors.black);
    final labelColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkSecondary
        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85));
    final pointColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkSecondary
        : Color(0xFF1976D2); // 深藍色，更專業
    final gridColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkPrimary.withOpacity(0.15)
        : (isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.25));
    final minorGridColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkPrimary.withOpacity(0.08)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.15));
    final quadrantLabelColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkSecondary.withOpacity(0.4)
        : (isDark ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.4));
    final backgroundColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkBackground
        : (isDark ? Color(0xFF1E1E1E) : Color(0xFFFAFAFA));

    // 畫布設定 - 使用整個畫面
    final margin = 30.0;
    final plotWidth = size.width - 2 * margin;
    final plotHeight = size.height - 2 * margin;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 計算座標系統的實際範圍（基於畫面比例）
    final aspectRatio = plotWidth / plotHeight;
    double xRange = 10.0; // 基本範圍 -5 到 +5
    double yRange = 10.0;
    
    if (aspectRatio > 1) {
      // 寬屏，擴展 X 軸範圍
      xRange = 10.0 * aspectRatio;
    } else {
      // 高屏，擴展 Y 軸範圍
      yRange = 10.0 / aspectRatio;
    }

    // 1. 背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), 
      Paint()..color = backgroundColor);

    // 應用縮放和平移變換
    canvas.save();
    canvas.translate(centerX + offset.dx, centerY + offset.dy);
    canvas.scale(scale, scale);
    canvas.translate(-centerX, -centerY);

    // 2. 細網格線（0.5單位間隔）
    _drawMinorGrid(canvas, size, margin, plotWidth, plotHeight, minorGridColor, xRange, yRange);

    // 3. 主網格線（1單位間隔）
    _drawMajorGrid(canvas, size, margin, plotWidth, plotHeight, gridColor, xRange, yRange);

    // 4. 象限背景色
    _drawQuadrantBackgrounds(canvas, margin, plotWidth, plotHeight, isDark, isCyberpunk, centerX, centerY);

    // 5. 座標軸
    _drawAxes(canvas, centerX, centerY, plotWidth, plotHeight, axisColor);

    // 6. 刻度和數值
    _drawTicks(canvas, centerX, centerY, plotWidth, plotHeight, axisColor, labelColor, xRange, yRange);

    // 7. 軸標籤
    _drawAxisLabels(canvas, centerX, centerY, plotWidth, plotHeight, labelColor);

    // 8. 象限標籤
    _drawQuadrantLabels(canvas, centerX, centerY, plotWidth, plotHeight, quadrantLabelColor);

    // 9. 任務點
    _drawTasks(canvas, margin, plotWidth, plotHeight, pointColor, labelColor, axisColor, xRange, yRange);

    canvas.restore();
  }

  void _drawMinorGrid(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight, Color color, double xRange, double yRange) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5 / scale;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 計算網格間隔
    final xStep = plotWidth / xRange;
    final yStep = plotHeight / yRange;
    
    // 繪製垂直網格線
    for (double i = -xRange/2; i <= xRange/2; i += 0.5) {
      if (i == 0) continue; // 跳過中心軸
      final x = centerX + i * xStep;
      if (x >= margin && x <= size.width - margin) {
        canvas.drawLine(Offset(x, margin), Offset(x, size.height - margin), paint);
      }
    }
    
    // 繪製水平網格線
    for (double i = -yRange/2; i <= yRange/2; i += 0.5) {
      if (i == 0) continue; // 跳過中心軸
      final y = centerY - i * yStep;
      if (y >= margin && y <= size.height - margin) {
        canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
      }
    }
  }

  void _drawMajorGrid(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight, Color color, double xRange, double yRange) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0 / scale;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 計算網格間隔
    final xStep = plotWidth / xRange;
    final yStep = plotHeight / yRange;
    
    // 繪製垂直網格線
    for (int i = -(xRange/2).floor(); i <= (xRange/2).floor(); i++) {
      if (i == 0) continue; // 跳過中心軸
      final x = centerX + i * xStep;
      if (x >= margin && x <= size.width - margin) {
        canvas.drawLine(Offset(x, margin), Offset(x, size.height - margin), paint);
      }
    }
    
    // 繪製水平網格線
    for (int i = -(yRange/2).floor(); i <= (yRange/2).floor(); i++) {
      if (i == 0) continue; // 跳過中心軸
      final y = centerY - i * yStep;
      if (y >= margin && y <= size.height - margin) {
        canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
      }
    }
  }

  void _drawQuadrantBackgrounds(Canvas canvas, double margin, double plotWidth, double plotHeight, bool isDark, bool isCyberpunk, double centerX, double centerY) {
    // 淺色背景區分象限
    final colors = [
      (isCyberpunk ? _EisenhowerAppState.cyberpunkPrimary : Colors.red).withOpacity(0.03),
      (isCyberpunk ? _EisenhowerAppState.cyberpunkSecondary : Colors.orange).withOpacity(0.03),
      (isCyberpunk ? _EisenhowerAppState.cyberpunkPrimary : Colors.blue).withOpacity(0.03),
      (isCyberpunk ? _EisenhowerAppState.cyberpunkSecondary : Colors.green).withOpacity(0.03),
    ];

    // 象限矩形：右上、右下、左上、左下
    final quadrants = [
      Rect.fromLTWH(centerX, margin, (plotWidth + 2*margin - centerX), (centerY - margin)), // 右上
      Rect.fromLTWH(centerX, centerY, (plotWidth + 2*margin - centerX), (plotHeight + 2*margin - centerY)), // 右下
      Rect.fromLTWH(margin, margin, (centerX - margin), (centerY - margin)), // 左上
      Rect.fromLTWH(margin, centerY, (centerX - margin), (plotHeight + 2*margin - centerY)), // 左下
    ];

    for (int i = 0; i < 4; i++) {
      canvas.drawRect(quadrants[i], Paint()..color = colors[i]);
    }
  }

  void _drawAxes(Canvas canvas, double centerX, double centerY, double plotWidth, double plotHeight, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 / scale;

    // 主軸
    canvas.drawLine(Offset(centerX, centerY - plotHeight/2), Offset(centerX, centerY + plotHeight/2), paint);
    canvas.drawLine(Offset(centerX - plotWidth/2, centerY), Offset(centerX + plotWidth/2, centerY), paint);

    // 箭頭
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrowSize = 8.0 / scale;

    // X軸箭頭
    final xArrow = Path()
      ..moveTo(centerX + plotWidth/2, centerY)
      ..lineTo(centerX + plotWidth/2 - arrowSize, centerY - arrowSize/2)
      ..lineTo(centerX + plotWidth/2 - arrowSize, centerY + arrowSize/2)
      ..close();
    canvas.drawPath(xArrow, arrowPaint);

    // Y軸箭頭
    final yArrow = Path()
      ..moveTo(centerX, centerY - plotHeight/2)
      ..lineTo(centerX - arrowSize/2, centerY - plotHeight/2 + arrowSize)
      ..lineTo(centerX + arrowSize/2, centerY - plotHeight/2 + arrowSize)
      ..close();
    canvas.drawPath(yArrow, arrowPaint);
  }

  void _drawTicks(Canvas canvas, double centerX, double centerY, double plotWidth, double plotHeight, Color axisColor, Color labelColor, double xRange, double yRange) {
    final tickPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5 / scale;
    final tickSize = 8.0 / scale;
    final fontSize = (11.0 / scale).clamp(8.0, 16.0);

    // 計算刻度間隔
    final xStep = plotWidth / xRange;
    final yStep = plotHeight / yRange;

    // X軸刻度
    for (int i = -(xRange/2).floor(); i <= (xRange/2).floor(); i++) {
      if (i == 0) continue;
      final x = centerX + i * xStep;
      if (x >= centerX - plotWidth/2 && x <= centerX + plotWidth/2) {
        canvas.drawLine(Offset(x, centerY - tickSize/2), Offset(x, centerY + tickSize/2), tickPaint);
        
        // 刻度標籤
        final tp = TextPainter(
          text: TextSpan(text: i.toString(), style: TextStyle(fontSize: fontSize, color: labelColor, fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width/2, centerY + tickSize + 4 / scale));
      }
    }

    // Y軸刻度
    for (int i = -(yRange/2).floor(); i <= (yRange/2).floor(); i++) {
      if (i == 0) continue;
      final y = centerY - i * yStep;
      if (y >= centerY - plotHeight/2 && y <= centerY + plotHeight/2) {
        canvas.drawLine(Offset(centerX - tickSize/2, y), Offset(centerX + tickSize/2, y), tickPaint);
        
        // 刻度標籤
        final tp = TextPainter(
          text: TextSpan(text: i.toString(), style: TextStyle(fontSize: fontSize, color: labelColor, fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(centerX - tickSize - tp.width - 4 / scale, y - tp.height/2));
      }
    }

    // 原點
    final originTp = TextPainter(
      text: TextSpan(text: '0', style: TextStyle(fontSize: fontSize, color: labelColor, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    originTp.paint(canvas, Offset(centerX - tickSize - originTp.width - 4 / scale, centerY + 4 / scale));
  }

  void _drawAxisLabels(Canvas canvas, double centerX, double centerY, double plotWidth, double plotHeight, Color labelColor) {
    final fontSize = (13.0 / scale).clamp(10.0, 18.0);
    final labelStyle = TextStyle(fontSize: fontSize, color: labelColor, fontWeight: FontWeight.w600);

    // X軸標籤
    final xLabel = TextPainter(
      text: TextSpan(text: language == AppLanguage.zh ? '重要程度' : 'Importance', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(canvas, Offset(centerX + plotWidth/2 - xLabel.width, centerY + plotHeight/2 + 30 / scale));

    // Y軸標籤（旋轉）
    canvas.save();
    canvas.translate(centerX - plotWidth/2 - 35 / scale, centerY - plotHeight/2 + 10 / scale);
    canvas.rotate(-math.pi / 2);
    final yLabel = TextPainter(
      text: TextSpan(text: language == AppLanguage.zh ? '緊急程度' : 'Urgency', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    yLabel.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawQuadrantLabels(Canvas canvas, double centerX, double centerY, double plotWidth, double plotHeight, Color quadrantLabelColor) {
    final fontSize = (15.0 / scale).clamp(10.0, 20.0);
    final quadrantStyle = TextStyle(fontSize: fontSize, color: quadrantLabelColor, fontWeight: FontWeight.w700);
    final quadrantTitles = language == AppLanguage.zh
        ? ['重要且緊急', '重要不緊急', '不重要但緊急', '不重要不緊急']
        : ['Important & Urgent', 'Important & Not Urgent', 'Not Important & Urgent', 'Not Important & Not Urgent'];

    // 象限中心點
    final centers = [
      Offset(centerX + plotWidth/4, centerY - plotHeight/4), // 右上
      Offset(centerX + plotWidth/4, centerY + plotHeight/4), // 右下
      Offset(centerX - plotWidth/4, centerY - plotHeight/4), // 左上
      Offset(centerX - plotWidth/4, centerY + plotHeight/4), // 左下
    ];

    for (int i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(text: quadrantTitles[i], style: quadrantStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(centers[i].dx - tp.width/2, centers[i].dy - tp.height/2));
    }
  }

  void _drawTasks(Canvas canvas, double margin, double plotWidth, double plotHeight, Color pointColor, Color labelColor, Color axisColor, double xRange, double yRange) {
    // 根據縮放調整點大小和字體大小
    final pointSize = (6.0 / scale).clamp(3.0, 10.0);
    final fontSize = (11.0 / scale).clamp(8.0, 16.0);
    
    final centerX = plotWidth / 2 + margin;
    final centerY = plotHeight / 2 + margin;
    
    // 計算單位步長
    final xStep = plotWidth / xRange;
    final yStep = plotHeight / yRange;
    
    for (final task in tasks) {
      // 將任務的重要性和緊急程度映射到畫布座標
      final x = centerX + task.importance * xStep;
      final y = centerY - task.urgency * yStep;

      // 任務點陰影
      canvas.drawCircle(Offset(x + 1, y + 1), pointSize + 1, Paint()..color = Colors.black.withOpacity(0.2));

      // 任務點
      canvas.drawCircle(Offset(x, y), pointSize, Paint()..color = pointColor);

      // 任務點邊框
      canvas.drawCircle(Offset(x, y), pointSize, Paint()
        ..color = axisColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale);

      // 任務標籤背景
      final tp = TextPainter(
        text: TextSpan(
          text: task.title,
          style: TextStyle(fontSize: fontSize, color: labelColor, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelPadding = 6.0 / scale;
      final labelOffset = 18.0 / scale;
      
      final labelRect = Rect.fromLTWH(
        x - tp.width/2 - labelPadding,
        y - tp.height - labelOffset,
        tp.width + labelPadding * 2,
        tp.height + labelPadding,
      );

      // 標籤背景
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(6 / scale)),
        Paint()..color = Colors.white.withOpacity(0.9),
      );

      // 標籤邊框
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(6 / scale)),
        Paint()
          ..color = axisColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / scale,
      );

      // 標籤文字
      tp.paint(canvas, Offset(x - tp.width/2, y - tp.height - labelOffset + labelPadding/2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SettingsScreen extends StatelessWidget {
  final AppThemeMode themeMode;
  final void Function(AppThemeMode) onThemeChanged;
  final AppLanguage language;
  final void Function(AppLanguage) onLanguageChanged;
  const SettingsScreen({super.key, required this.themeMode, required this.onThemeChanged, required this.language, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(language == AppLanguage.zh ? '主題模式' : 'Theme Mode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '淺色' : 'Light'),
            value: AppThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '深色' : 'Dark'),
            value: AppThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '跟隨系統' : 'System'),
            value: AppThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '賽博朋克' : 'Cyberpunk'),
            value: AppThemeMode.cyberpunk,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          const SizedBox(height: 24),
          Text(language == AppLanguage.zh ? '語言' : 'Language', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<AppLanguage>(
            title: const Text('繁體中文'),
            value: AppLanguage.zh,
            groupValue: language,
            onChanged: (lang) { if (lang != null) onLanguageChanged(lang); },
          ),
          RadioListTile<AppLanguage>(
            title: const Text('English'),
            value: AppLanguage.en,
            groupValue: language,
            onChanged: (lang) { if (lang != null) onLanguageChanged(lang); },
          ),
        ],
      ),
    );
  }
}