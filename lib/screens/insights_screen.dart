import 'dart:math';
import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Research Insights',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insights filters coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Research Impact Gauge
              _buildSectionTitle(theme, 'RESEARCH IMPACT'),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      CustomPaint(
                        size: const Size(160, 160),
                        painter: PercentileGaugePainter(
                          percentile: 84,
                          activeColor: theme.colorScheme.secondary,
                          trackColor: theme.colorScheme.outlineVariant
                              .withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your research impact has increased by 4 points since last month, placing you in the top tier of your field.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Publication Activity Bar Chart
              _buildSectionTitle(theme, 'PUBLICATION ACTIVITY'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 128,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBarColumn(
                            theme,
                            'JAN',
                            0.30,
                            Colors.blue.withOpacity(0.2),
                          ),
                          _buildBarColumn(
                            theme,
                            'FEB',
                            0.45,
                            Colors.blue.withOpacity(0.4),
                          ),
                          _buildBarColumn(
                            theme,
                            'MAR',
                            0.75,
                            Colors.blue.withOpacity(0.6),
                          ),
                          _buildBarColumn(theme, 'APR', 0.90, Colors.blue),
                          _buildBarColumn(
                            theme,
                            'MAY',
                            0.55,
                            Colors.blue.withOpacity(0.5),
                          ),
                          _buildBarColumn(
                            theme,
                            'JUN',
                            0.80,
                            Colors.blue.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Citation Growth Line Graph
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(theme, 'CITATION GROWTH'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '+15%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: CitationGrowthPainter(
                        lineColor: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cumulative Citations: 1,240',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Top Research Fields Progress Bars
              _buildSectionTitle(theme, 'TOP RESEARCH FIELDS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildFieldProgressRow(theme, 'AI Ethics', 0.45),
                    const SizedBox(height: 16),
                    _buildFieldProgressRow(theme, 'Neural Networks', 0.30),
                    const SizedBox(height: 16),
                    _buildFieldProgressRow(theme, 'Quantum ML', 0.25),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.outline,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildBarColumn(
    ThemeData theme,
    String label,
    double ratio,
    Color color,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 96 * ratio,
            margin: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldProgressRow(
    ThemeData theme,
    String field,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              field,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class PercentileGaugePainter extends CustomPainter {
  final int percentile;
  final Color activeColor;
  final Color trackColor;

  PercentileGaugePainter({
    required this.percentile,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    final sweepAngle = 2 * pi * (percentile / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    // Draw Score Text
    final textPainterScore = TextPainter(
      text: TextSpan(
        text: percentile.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterScore.layout();
    textPainterScore.paint(
      canvas,
      center -
          Offset(textPainterScore.width / 2, textPainterScore.height / 2 + 10),
    );

    // Draw Percentile Label
    final textPainterLabel = TextPainter(
      text: const TextSpan(
        text: 'PERCENTILE',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterLabel.layout();
    textPainterLabel.paint(
      canvas,
      center - Offset(textPainterLabel.width / 2, -15),
    );
  }

  @override
  bool shouldRepaint(covariant PercentileGaugePainter oldDelegate) {
    return oldDelegate.percentile != percentile;
  }
}

class CitationGrowthPainter extends CustomPainter {
  final Color lineColor;

  CitationGrowthPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.7,
      size.width * 0.4,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.35,
      size.width,
      size.height * 0.15,
    );

    canvas.drawPath(path, paint);

    // Draw Gradient fill below curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.15), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
