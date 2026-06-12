import 'package:flutter/material.dart';

class MovablePanel extends StatefulWidget {
  final Widget child;
  final double? initialLeft;
  final double? initialTop;
  final double? initialRight;
  final double? initialBottom;

  const MovablePanel({
    super.key,
    required this.child,
    this.initialLeft,
    this.initialTop,
    this.initialRight,
    this.initialBottom,
  });

  @override
  State<MovablePanel> createState() => _MovablePanelState();
}

class _MovablePanelState extends State<MovablePanel> {
  double? _left;
  double? _top;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      
      if (widget.initialLeft != null) {
        _left = widget.initialLeft!;
      } else if (widget.initialRight != null) {
        // Assume default width of 60 for alignment if child width is unknown initially,
        // though typically right alignment relies on widget width. 
        // We will just offset from right edge.
        _left = size.width - widget.initialRight! - 60; // Approximate width
      } else {
        _left = 16.0;
      }

      if (widget.initialTop != null) {
        _top = widget.initialTop!;
      } else if (widget.initialBottom != null) {
        _top = size.height - widget.initialBottom! - 100; // Approximate height
      } else {
        _top = 16.0;
      }
      
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _left = (_left ?? 0) + details.delta.dx;
            _top = (_top ?? 0) + details.delta.dy;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
