// lib/widgets/linguabot/metric_gauge.dart
import 'package:flutter/material.dart';

class MetricGauge extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  const MetricGauge({super.key, required this.label, required this.value, required this.color});

  @override
  State<MetricGauge> createState() => _MetricGaugeState();
}

class _MetricGaugeState extends State<MetricGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _animation.value,
                    strokeWidth: 5,
                    color: widget.color,
                    backgroundColor: widget.color.withAlpha(51),
                  ),
                  Center(child: Text("${(_animation.value * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      },
    );
  }
}

