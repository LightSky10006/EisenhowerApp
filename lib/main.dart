import 'package:flutter/material.dart';

void main() {
  runApp(EisenhowerApp());
}

class Task {
  String title;
  int quadrant; // 0:重要且緊急, 1:重要不緊急, 2:不重要但緊急, 3:不重要不緊急
  int importance; // -5~+5
  int urgency; // -5~+5
  Task(this.title, this.quadrant, {this.importance = 0, this.urgency = 0});
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

  // 主題色定義集中管理
  static const cyberpunkPrimary = Color(0xFFFFF000); // 螢光黃
  static const cyberpunkSecondary = Color(0xFF00FFF7); // 螢光藍
  static const cyberpunkSurface = Color(0xFF2D1B3C); // 紫
  static const cyberpunkBackground = Color(0xFF1A1832); // 深藍紫

  void _setThemeMode(AppThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _setLanguage(AppLanguage lang) {
    setState(() {
      _language = lang;
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
  }

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.cyberpunk:
        return ThemeMode.light;
    }
  }

  ThemeData get cyberpunkTheme => ThemeData(
        colorScheme: ColorScheme(
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
    // 直接用 ThemeData，避免 Theme.of(context) 受 Theme 包覆影響
    final theme = isCyberpunk ? cyberpunkTheme : (_themeMode == AppThemeMode.dark ? ThemeData.dark() : ThemeData.light());
    final lang = _language;
    // dock顏色
    final bottomBarBg = isCyberpunk ? cyberpunkSurface : theme.colorScheme.surface;
    final bottomBarSelected = isCyberpunk ? cyberpunkPrimary : theme.colorScheme.primary;
    final bottomBarUnselected = isCyberpunk ? cyberpunkSecondary : theme.unselectedWidgetColor;
    return MaterialApp(
      title: lang == AppLanguage.zh ? 'Eisenhower Matrix Todo' : 'Eisenhower Matrix Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: materialThemeMode,
      highContrastTheme: isCyberpunk ? cyberpunkTheme : null,
      home: Builder(
        builder: (context) {
          final effectiveTheme = isCyberpunk ? cyberpunkTheme : Theme.of(context);
          return Theme(
            data: effectiveTheme,
            child: Scaffold(
              backgroundColor: isCyberpunk ? cyberpunkBackground : null,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  EisenhowerListScreen(
                    tasks: tasks,
                    onAdd: _showAddTaskDialog,
                    onDelete: _deleteTask,
                    language: lang,
                  ),
                  QuadrantPlaneScreen(tasks: tasks, isCyberpunk: isCyberpunk, language: lang),
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, int quadrant) async {
    final TextEditingController dialogController = TextEditingController();
    // 根據象限設定權重範圍
    int minImportance = -5, maxImportance = 5, minUrgency = -5, maxUrgency = 5;
    int defaultImportance = 0, defaultUrgency = 0;
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
    int importance = defaultImportance;
    int urgency = defaultUrgency;
    final lang = _language;
    final quadrantTitle = lang == AppLanguage.zh
        ? EisenhowerListScreen.quadrantTitlesZh[quadrant]
        : EisenhowerListScreen.quadrantTitlesEn[quadrant];
    final addTitle = lang == AppLanguage.zh ? '新增到「$quadrantTitle」' : 'Add to "$quadrantTitle"';
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
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      tasks.add(Task(value.trim(), quadrant, importance: importance, urgency: urgency));
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('重要程度'),
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
                  Text(lang == AppLanguage.zh ? '$importance' : '$importance'),
                ],
              ),
              Row(
                children: [
                  const Text('緊急程度'),
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
                  Text(lang == AppLanguage.zh ? '$urgency' : '$urgency'),
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
              onPressed: () {
                if (dialogController.text.trim().isNotEmpty) {
                  setState(() {
                    tasks.add(Task(dialogController.text.trim(), quadrant, importance: importance, urgency: urgency));
                  });
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
  final Future<void> Function(BuildContext, int quadrant) onAdd;
  final void Function(Task) onDelete;
  final AppLanguage language;
  const EisenhowerListScreen({super.key, required this.tasks, required this.onAdd, required this.onDelete, required this.language});

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
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('${quadrantTasks[j].title} (${quadrantTasks[j].importance},${quadrantTasks[j].urgency})'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, size: 18),
                                        tooltip: language == AppLanguage.zh ? '刪除' : 'Delete',
                                        onPressed: () => onDelete(quadrantTasks[j]),
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

class QuadrantPlaneScreen extends StatelessWidget {
  final List<Task> tasks;
  final bool isCyberpunk;
  final AppLanguage language;
  const QuadrantPlaneScreen({super.key, required this.tasks, this.isCyberpunk = false, required this.language});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: QuadrantPainter(tasks, isDark: isDark, isCyberpunk: isCyberpunk, language: language),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;
  final bool isDark;
  final bool isCyberpunk;
  final AppLanguage language;
  QuadrantPainter(this.tasks, {this.isDark = false, this.isCyberpunk = false, required this.language});

  @override
  void paint(Canvas canvas, Size size) {
    final axisColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkPrimary
        : (isDark ? Colors.white : Colors.black);
    final labelColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkSecondary
        : (isDark ? Colors.white : Colors.black);
    final pointColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkSecondary
        : Colors.blue;
    final borderColor = isCyberpunk
        ? _EisenhowerAppState.cyberpunkPrimary.withOpacity(0.5)
        : (isDark ? Colors.white54 : Colors.grey);
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 2;
    // 畫中線
    canvas.drawLine(Offset(size.width/2, 0), Offset(size.width/2, size.height), paint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), paint);
    // 畫刻度與標籤
    textPainter(String text, Offset offset, {TextAlign align = TextAlign.left, Color? color}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 14, color: color ?? labelColor)),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout();
      tp.paint(canvas, offset);
    }
    // 橫軸標籤
    textPainter(language == AppLanguage.zh ? '不重要' : 'Not Important', Offset(8, size.height/2-24));
    textPainter(language == AppLanguage.zh ? '重要' : 'Important', Offset(size.width-72, size.height/2-24));
    // 縱軸標籤
    textPainter(language == AppLanguage.zh ? '緊急' : 'Urgent', Offset(size.width/2+8, 8));
    textPainter(language == AppLanguage.zh ? '不緊急' : 'Not Urgent', Offset(size.width/2+8, size.height-28));
    // 畫任務
    for (final t in tasks) {
      // importance, urgency -5~+5 => -6~+6 畫布
      final x = (t.importance + 6) / 12; // -6~+6 -> 0~1
      final y = 1 - ((t.urgency + 6) / 12); // -6~+6 -> 0~1 (上正下負)
      final px = x * size.width;
      final py = y * size.height;
      final tp = TextPainter(
        text: TextSpan(text: t.title, style: TextStyle(fontSize: 13, color: pointColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px-tp.width/2, py-tp.height/2-8));
      // 畫點
      canvas.drawCircle(Offset(px, py), 5, Paint()..color=pointColor);
    }
    // 畫邊界線
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);
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