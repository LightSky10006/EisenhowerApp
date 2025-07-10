import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/task.dart';
import '../models/app_enums.dart';

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;
  final bool isDark;
  final bool isCyberpunk;
  final AppLanguage language;
  final double scale;
  final Offset offset;
  
  // 主題色彩 - 與 main.dart 保持一致
  static const Color cyberpunkPrimary = Color(0xFFFFF000); // 螢光黃
  static const Color cyberpunkSecondary = Color(0xFF00FFF7); // 螢光藍
  static const Color cyberpunkBackground = Color(0xFF1A1832); // 深藍紫
  
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
        ? cyberpunkPrimary
        : (isDark ? Colors.white : Colors.black);
    final labelColor = isCyberpunk
        ? cyberpunkSecondary
        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85));
    final pointColor = isCyberpunk
        ? cyberpunkSecondary
        : Color(0xFF1976D2); // 深藍色，更專業
    final gridColor = isCyberpunk
        ? cyberpunkPrimary.withOpacity(0.15)
        : (isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.25));
    final minorGridColor = isCyberpunk
        ? cyberpunkPrimary.withOpacity(0.08)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.15));
    final quadrantLabelColor = isCyberpunk
        ? cyberpunkSecondary.withOpacity(0.4)
        : (isDark ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.4));
    final backgroundColor = isCyberpunk
        ? const Color(0xFF2D1B3C) // 紫色，與主背景一致
        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA));

    // 畫布設定 - 使用整個畫面
    final margin = 30.0;
    final plotWidth = size.width - 2 * margin;
    final plotHeight = size.height - 2 * margin;

    // 動態計算座標範圍 - 根據螢幕比例決定
    final baseRange = 10.0;
    final aspectRatio = plotWidth / plotHeight;
    
    // 座標範圍需要包含縮放和偏移
    final scaleReciprocalX = aspectRatio * baseRange / scale;
    final scaleReciprocalY = baseRange / scale;
    
    // 考慮偏移量
    final offsetX = -offset.dx * scaleReciprocalX * 2 / plotWidth;
    final offsetY = offset.dy * scaleReciprocalY * 2 / plotHeight;
    
    final minX = -scaleReciprocalX + offsetX;
    final maxX = scaleReciprocalX + offsetX;
    final minY = -scaleReciprocalY + offsetY;
    final maxY = scaleReciprocalY + offsetY;

    // 畫布背景
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, plotWidth, plotHeight),
      Paint()..color = backgroundColor,
    );

    // 繪製坐標軸和網格
    _drawGrid(canvas, size, margin, plotWidth, plotHeight, 
              minX, maxX, minY, maxY, gridColor, minorGridColor);
    _drawAxes(canvas, size, margin, plotWidth, plotHeight, 
              minX, maxX, minY, maxY, axisColor);
    _drawLabels(canvas, size, margin, plotWidth, plotHeight, 
                minX, maxX, minY, maxY, labelColor);

    // 繪製象限標籤
    _drawQuadrantLabels(canvas, size, margin, plotWidth, plotHeight, 
                        minX, maxX, minY, maxY, quadrantLabelColor);

    // 繪製任務點
    _drawTaskPoints(canvas, size, margin, plotWidth, plotHeight, 
                    minX, maxX, minY, maxY, pointColor, labelColor);
  }

  void _drawGrid(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight,
                 double minX, double maxX, double minY, double maxY, Color gridColor, Color minorGridColor) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint minorGridPaint = Paint()
      ..color = minorGridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 計算格線間距
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    
    final majorStepX = _calculateMajorStep(rangeX);
    final majorStepY = _calculateMajorStep(rangeY);
    
    final minorStepX = majorStepX / 5.0;
    final minorStepY = majorStepY / 5.0;

    // 垂直格線
    for (double x = (minX / minorStepX).ceil() * minorStepX; x <= maxX; x += minorStepX) {
      final screenX = margin + (x - minX) / rangeX * plotWidth;
      if (screenX >= margin && screenX <= margin + plotWidth) {
        final isMajor = ((x / majorStepX).round() * majorStepX - x).abs() < minorStepX * 0.1;
        canvas.drawLine(
          Offset(screenX, margin),
          Offset(screenX, margin + plotHeight),
          isMajor ? gridPaint : minorGridPaint,
        );
      }
    }

    // 水平格線
    for (double y = (minY / minorStepY).ceil() * minorStepY; y <= maxY; y += minorStepY) {
      final screenY = margin + plotHeight - (y - minY) / rangeY * plotHeight;
      if (screenY >= margin && screenY <= margin + plotHeight) {
        final isMajor = ((y / majorStepY).round() * majorStepY - y).abs() < minorStepY * 0.1;
        canvas.drawLine(
          Offset(margin, screenY),
          Offset(margin + plotWidth, screenY),
          isMajor ? gridPaint : minorGridPaint,
        );
      }
    }
  }

  void _drawAxes(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight,
                 double minX, double maxX, double minY, double maxY, Color axisColor) {
    final Paint axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;

    // X軸
    if (minY <= 0 && maxY >= 0) {
      final y0 = margin + plotHeight - (0 - minY) / rangeY * plotHeight;
      canvas.drawLine(
        Offset(margin, y0),
        Offset(margin + plotWidth, y0),
        axisPaint,
      );
    }

    // Y軸
    if (minX <= 0 && maxX >= 0) {
      final x0 = margin + (0 - minX) / rangeX * plotWidth;
      canvas.drawLine(
        Offset(x0, margin),
        Offset(x0, margin + plotHeight),
        axisPaint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight,
                   double minX, double maxX, double minY, double maxY, Color labelColor) {
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    
    final majorStepX = _calculateMajorStep(rangeX);
    final majorStepY = _calculateMajorStep(rangeY);

    final textStyle = TextStyle(
      color: isCyberpunk ? cyberpunkPrimary : labelColor, // cyberpunk 模式下座標軸數字用螢光黃
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );

    // X軸標籤
    for (double x = (minX / majorStepX).ceil() * majorStepX; x <= maxX; x += majorStepX) {
      if (x.abs() < majorStepX * 0.1) continue; // 跳過原點
      
      final screenX = margin + (x - minX) / rangeX * plotWidth;
      if (screenX >= margin && screenX <= margin + plotWidth) {
        final tp = TextPainter(
          text: TextSpan(text: x.round().toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        
        final y0 = margin + plotHeight - (0 - minY) / rangeY * plotHeight;
        final labelY = (minY <= 0 && maxY >= 0) ? y0 + 5 : margin + plotHeight + 5;
        
        tp.paint(canvas, Offset(screenX - tp.width / 2, labelY));
      }
    }

    // Y軸標籤
    for (double y = (minY / majorStepY).ceil() * majorStepY; y <= maxY; y += majorStepY) {
      if (y.abs() < majorStepY * 0.1) continue; // 跳過原點
      
      final screenY = margin + plotHeight - (y - minY) / rangeY * plotHeight;
      if (screenY >= margin && screenY <= margin + plotHeight) {
        final tp = TextPainter(
          text: TextSpan(text: y.round().toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        
        final x0 = margin + (0 - minX) / rangeX * plotWidth;
        final labelX = (minX <= 0 && maxX >= 0) ? x0 - tp.width - 5 : margin - tp.width - 5;
        
        tp.paint(canvas, Offset(labelX, screenY - tp.height / 2));
      }
    }
  }

  void _drawQuadrantLabels(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight,
                           double minX, double maxX, double minY, double maxY, Color quadrantLabelColor) {
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    
    final x0 = margin + (0 - minX) / rangeX * plotWidth;
    final y0 = margin + plotHeight - (0 - minY) / rangeY * plotHeight;

    final textStyle = TextStyle(
      color: quadrantLabelColor,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    final labels = language == AppLanguage.zh 
      ? ['重要且緊急', '重要不緊急', '不重要但緊急', '不重要不緊急']
      : ['Important & Urgent', 'Important & Not Urgent', 'Not Important & Urgent', 'Not Important & Not Urgent'];

    // 只有當原點在可見範圍內時才繪製象限標籤
    if (minX <= 0 && maxX >= 0 && minY <= 0 && maxY >= 0) {
      // 第一象限 (右上)
      if (x0 < margin + plotWidth && y0 > margin) {
        final tp = TextPainter(
          text: TextSpan(text: labels[0], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x0 + 10, y0 - tp.height - 10));
      }

      // 第二象限 (左上)
      if (x0 > margin && y0 > margin) {
        final tp = TextPainter(
          text: TextSpan(text: labels[1], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x0 - tp.width - 10, y0 - tp.height - 10));
      }

      // 第三象限 (左下)
      if (x0 > margin && y0 < margin + plotHeight) {
        final tp = TextPainter(
          text: TextSpan(text: labels[3], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x0 - tp.width - 10, y0 + 10));
      }

      // 第四象限 (右下)
      if (x0 < margin + plotWidth && y0 < margin + plotHeight) {
        final tp = TextPainter(
          text: TextSpan(text: labels[2], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x0 + 10, y0 + 10));
      }
    }
  }

  void _drawTaskPoints(Canvas canvas, Size size, double margin, double plotWidth, double plotHeight,
                       double minX, double maxX, double minY, double maxY, Color pointColor, Color labelColor) {
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final pointRadius = 6.0;
    final labelOffset = 12.0;
    final labelPadding = 4.0;

    for (Task task in tasks) {
      final x = margin + (task.importance - minX) / rangeX * plotWidth;
      final y = margin + plotHeight - (task.urgency - minY) / rangeY * plotHeight;

      // 只繪製在可見範圍內的點
      if (x >= margin - pointRadius && x <= margin + plotWidth + pointRadius &&
          y >= margin - pointRadius && y <= margin + plotHeight + pointRadius) {
        
        // 繪製點
        canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
        
        // 繪製白色邊框
        canvas.drawCircle(
          Offset(x, y), 
          pointRadius, 
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
        );

        // 繪製標籤
        final tp = TextPainter(
          text: TextSpan(
            text: task.title,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();

        // 標籤背景
        final labelRect = Rect.fromLTWH(
          x - tp.width/2 - labelPadding/2,
          y - tp.height - labelOffset,
          tp.width + labelPadding,
          tp.height + labelPadding,
        );
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
          Paint()
            ..color = isCyberpunk 
              ? cyberpunkBackground.withOpacity(0.85)
              : (isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.9))
            ..style = PaintingStyle.fill,
        );

        // 標籤文字
        tp.paint(canvas, Offset(x - tp.width/2, y - tp.height - labelOffset + labelPadding/2));
      }
    }
  }

  double _calculateMajorStep(double range) {
    final magnitude = math.pow(10, (math.log(range) / math.ln10).floor());
    final normalized = range / magnitude;
    
    if (normalized <= 1.0) return magnitude * 0.2;
    if (normalized <= 2.0) return magnitude * 0.5;
    if (normalized <= 5.0) return magnitude * 1.0;
    return magnitude * 2.0;
  }

  @override
  bool shouldRepaint(covariant QuadrantPainter oldDelegate) {
    return tasks != oldDelegate.tasks ||
           isDark != oldDelegate.isDark ||
           isCyberpunk != oldDelegate.isCyberpunk ||
           language != oldDelegate.language ||
           scale != oldDelegate.scale ||
           offset != oldDelegate.offset;
  }
}
