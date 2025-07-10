import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  
  DatabaseService._internal();
  
  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database not supported on web');
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eisenhower_tasks.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            quadrant INTEGER NOT NULL,
            importance INTEGER NOT NULL,
            urgency INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        
        // 創建索引以提高查詢效能
        await db.execute('CREATE INDEX idx_tasks_quadrant ON tasks(quadrant)');
        await db.execute('CREATE INDEX idx_tasks_importance ON tasks(importance)');
        await db.execute('CREATE INDEX idx_tasks_urgency ON tasks(urgency)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN description TEXT');
        }
      },
    );
  }
  
  Future<List<Task>> getAllTasks() async {
    if (kIsWeb) return [];
    
    try {
      final db = await database;
      final results = await db.query(
        'tasks',
        orderBy: 'updated_at DESC',
      );
      
      return results.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }
  
  Future<int> insertTask(Task task) async {
    if (kIsWeb) return -1;
    
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final taskMap = task.toMap();
      taskMap['created_at'] = now;
      taskMap['updated_at'] = now;
      
      debugPrint('Inserting task: $taskMap');
      
      final result = await db.insert('tasks', taskMap);
      debugPrint('Insert result: $result');
      return result;
    } catch (e) {
      debugPrint('Error inserting task: $e');
      return -1;
    }
  }
  
  Future<int> updateTask(Task task) async {
    if (kIsWeb) return 0;
    
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final taskMap = task.toMap();
      taskMap['updated_at'] = now;
      
      return await db.update(
        'tasks',
        taskMap,
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
      return 0;
    }
  }
  
  Future<int> deleteTask(int taskId) async {
    if (kIsWeb) return 0;
    
    try {
      final db = await database;
      return await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return 0;
    }
  }
  
  Future<List<Task>> getTasksByQuadrant(int quadrant) async {
    if (kIsWeb) return [];
    
    try {
      final db = await database;
      final results = await db.query(
        'tasks',
        where: 'quadrant = ?',
        whereArgs: [quadrant],
        orderBy: 'updated_at DESC',
      );
      
      return results.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading tasks by quadrant: $e');
      return [];
    }
  }
  
  // 重設資料庫（強制重新創建）
  Future<void> resetDatabase() async {
    if (kIsWeb) return;
    
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'eisenhower_tasks.db');
      
      // 關閉現有資料庫連接
      await close();
      
      // 刪除資料庫檔案
      await deleteDatabase(path);
      
      // 重新初始化資料庫
      _database = await _initDatabase();
      
      debugPrint('Database reset successfully');
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
  
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
