import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'models/task.dart';
import 'models/app_enums.dart';
import 'services/database_service.dart';
import 'screens/eisenhower_list_screen.dart';
import 'screens/quadrant_plane_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EisenhowerApp());
}

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
  
  late final DatabaseService _databaseService;

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
    _databaseService = DatabaseService();
    _resetDatabaseIfNeeded();
    _loadData();
  }
  
  Future<void> _resetDatabaseIfNeeded() async {
    // 臨時解決方案：如果資料庫版本不匹配，重新創建資料庫
    try {
      await _databaseService.resetDatabase();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
  
  Future<void> _loadData() async {
    await _loadPreferences();
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final taskList = await _databaseService.getAllTasks();
      setState(() {
        tasks.clear();
        tasks.addAll(taskList);
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
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
      
      int result;
      if (task.id == null) {
        result = await _databaseService.insertTask(task);
        if (result > 0) {
          task.id = result;
        }
      } else {
        result = await _databaseService.updateTask(task);
      }
      
      if (result > 0) {
        await _loadTasks();
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
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
      
      if (task.id != null) {
        final result = await _databaseService.deleteTask(task.id!);
        if (result > 0) {
          await _loadTasks();
        }
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
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
          primary: Color(0xFFFFF000), // 螢光黃
          onPrimary: Colors.black,
          secondary: Color(0xFF00FFF7), // 螢光藍
          onSecondary: Colors.black,
          error: Colors.pinkAccent,
          onError: Colors.black,
          surface: Color(0xFF2D1B3C), // 紫
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
    final TextEditingController descriptionController = TextEditingController();
    // 根據象限設定權重範圍
    int minImportance = -5, maxImportance = 5, minUrgency = -5, maxUrgency = 5;
    int defaultImportance = 0, defaultUrgency = 0;
    
    // 如果有提供座標值，使用座標值作為預設值並擴展範圍
    if (coordinateImportance != null && coordinateUrgency != null) {
      defaultImportance = coordinateImportance.round().clamp(-5, 5);
      defaultUrgency = coordinateUrgency.round().clamp(-5, 5);
      // 使用完整範圍，不受象限限制
      minImportance = -5;
      maxImportance = 5;
      minUrgency = -5;
      maxUrgency = 5;
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
    
    // 根據座標計算正確的象限
    int actualQuadrant = quadrant;
    if (coordinateImportance != null && coordinateUrgency != null) {
      // 根據座標重新計算象限
      if (coordinateImportance >= 0 && coordinateUrgency >= 0) {
        actualQuadrant = 0; // 右上：重要且緊急
      } else if (coordinateImportance < 0 && coordinateUrgency >= 0) {
        actualQuadrant = 1; // 左上：重要不緊急
      } else if (coordinateImportance < 0 && coordinateUrgency < 0) {
        actualQuadrant = 3; // 左下：不重要不緊急
      } else {
        actualQuadrant = 2; // 右下：不重要但緊急
      }
    }
    
    final quadrantTitle = lang == AppLanguage.zh
        ? EisenhowerListScreen.quadrantTitlesZh[actualQuadrant]
        : EisenhowerListScreen.quadrantTitlesEn[actualQuadrant];
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
                maxLength: 72,
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.zh ? '輸入待辦事項' : 'Enter todo',
                  counterText: '',
                ),
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty && value.trim().length <= 72) {
                    final newTask = Task(value.trim(), actualQuadrant, 
                      description: descriptionController.text.trim(),
                      importance: importance, 
                      urgency: urgency
                    );
                    await _saveTask(newTask);
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLength: 400,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.zh ? '備註（選填）' : 'Description (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
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
                if (dialogController.text.trim().isNotEmpty && dialogController.text.trim().length <= 72) {
                  final newTask = Task(dialogController.text.trim(), actualQuadrant, 
                    description: descriptionController.text.trim(),
                    importance: importance, 
                    urgency: urgency
                  );
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
    final TextEditingController descriptionController = TextEditingController(text: task.description);
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
                    maxLength: 72,
                    decoration: InputDecoration(
                      labelText: lang == AppLanguage.zh ? '修改待辦事項' : 'Edit todo',
                      counterText: '',
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isNotEmpty && value.trim().length <= 72) {
                        task.title = value.trim();
                        task.description = descriptionController.text.trim();
                        task.importance = importance;
                        task.urgency = urgency;
                        await _saveTask(task);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLength: 400,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: lang == AppLanguage.zh ? '備註' : 'Description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
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
                      task.description = descriptionController.text.trim();
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