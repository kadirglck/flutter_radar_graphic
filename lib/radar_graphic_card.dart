import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class RadarChartData {
  int nodes, segments;
  List<String> labels;

  RadarChartData(
    this.nodes,
    this.segments,
    this.labels,
  );
}

RadarChartData radarChartData = RadarChartData(
  5,
  4,
  ['Özellik 1', 'Özellik 2', 'Özellik 3', 'Özellik 4', 'Özellik 5'],
);

class RadarChartTransition extends AnimatedWidget {
  final AnimationController controller;
  final int nodes;
  final int segments;

  final List<String> labels;

  RadarChartTransition(
    this.controller,
    RadarChartData radarChartData,
  )   : nodes = radarChartData.nodes,
        segments = radarChartData.segments,
        labels = radarChartData.labels,
        super(listenable: controller);

  AnimationController get _animationController => listenable as AnimationController;
  final List<double> data = [1, 0.5, 0.5, 0.8, 0.75];

  final TweenSequence<double> poppingTweenSeq = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0.5).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.5, end: 1).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 100,
      ),
    ],
  );

  final Tween<double> easeOutTween = Tween(begin: 0, end: 1);

  Animation<double> _tweenSeqVal(start, end) {
    return poppingTweenSeq.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          start,
          end,
          curve: Curves.ease,
        ),
      ),
    );
  }

  Animation<double> _tweenVal(start, end) {
    return easeOutTween.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          start,
          end,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data.length != nodes) {
      throw ('Data length and number of nodes are not equal!');
    }

    int totalSegments = segments * nodes;
    double segPhaseProgress = 0.5 / totalSegments;
    double polyPhaseProgress = 4 / totalSegments;
    double segStartProg = 0.4;
    double polyStartProg = 0.8;

    List<double> segTweenVal = [];
    for (var j = 0; j < totalSegments; j++) {
      double startProgress = segStartProg + segPhaseProgress * j;
      double endProgress = segStartProg + segPhaseProgress * (j + 1);
      double tweenValueTemp = _tweenSeqVal(startProgress, endProgress).value;
      segTweenVal.add(tweenValueTemp);
    }

    double polyTweenVal = _tweenVal(polyStartProg, (polyStartProg + polyPhaseProgress)).value;

    return CustomPaint(
      painter: RadarChartPainter(segTweenVal, polyTweenVal, nodes, segments, data, labels),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> segAniProgress;
  final double polyAniProgress;
  final int nodes;
  final int segments;
  final List<double> data;
  final List<String> labels;

  RadarChartPainter(
    this.segAniProgress,
    this.polyAniProgress,
    this.nodes,
    this.segments,
    this.data,
    this.labels,
  );

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final angle = 360 / nodes;
    List<List<double>> points = [];
    for (int i = 0; i < nodes; i++) {
      final double lineLength = 100;
      if (i == 0) {
        points.add([0, -lineLength]);
      } else {
        final currentAngle = i * angle * pi / 180;
        final x = lineLength * sin(currentAngle); // x
        final y = -lineLength * cos(currentAngle); // y
        points.add([x, y]);
      }
    }

    int totalSegments = segments * nodes;
    int x = 0;
    int i = 0;
    for (var j = 0; j < totalSegments + 5; j++) {
      final segStyle = Paint()
        ..strokeWidth = 1
        ..color = Colors.black
        ..style = PaintingStyle.stroke;
      var segNo = (j / nodes).floor() / segments;
      Offset segPoint = Offset(points[i][0], points[i][1]) * segNo.toDouble();

      // canvas.drawCircle(segPoint, 2, segStyle);
      if (x < 10) {
        canvas.drawOval(Rect.fromCircle(center: Offset(0, 0), radius: (12.5 * x).toDouble()), segStyle);
      }
      x++;
      i++;
      if (i >= nodes) {
        i = 0;
      }
    }
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final pointMode = ui.PointMode.points;
    final polyStyle = Paint()
      ..strokeWidth = 2
      ..color = Color(0xfff34C691).withAlpha(200);
    List<Offset> dataOffsets = [];
    for (var i = 0; i < nodes; i++) {
      var temp = Offset(points[i][0], points[i][1]) * data[i] * polyAniProgress;
      dataOffsets.add(temp);
    }
    Path polyPath = Path();
    polyPath.addPolygon(dataOffsets, true);
    canvas.drawPoints(pointMode, dataOffsets, paint);
    canvas.drawPath(polyPath, polyStyle);

    double fontHeight = 12.0;
    TextStyle style = TextStyle(
      color: Colors.grey.withAlpha((255 * polyAniProgress).toInt()),
      fontSize: fontHeight,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontFamily: 'Open Sans',
    );

    for (var i = 0; i < nodes; i++) {
      final paraBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: style.fontSize,
        fontFamily: style.fontFamily,
        fontStyle: style.fontStyle,
        fontWeight: style.fontWeight,
        textAlign: TextAlign.center,
      ))
        ..pushStyle(style.getTextStyle());
      paraBuilder.addText(labels[i]);
      final ui.Paragraph labelPara = paraBuilder.build()..layout(ui.ParagraphConstraints(width: 50));
      var temp = Offset(points[i][0] - fontHeight, points[i][1] - fontHeight) * 1.3;
      canvas.drawParagraph(labelPara, temp);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
