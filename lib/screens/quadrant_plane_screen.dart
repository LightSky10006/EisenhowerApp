import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/app_enums.dart';
import '../widgets/quadrant_painter.dart';

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
  Offset? _lastTapPosition;
  
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
                ? const Color(0xFF2D1B3C) // 紫色，與主背景一致
                : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA)),
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
