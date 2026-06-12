import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerspectiveCanvasControls extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onResetPerspective;
  final VoidCallback onToggleShadows;
  final bool shadowsEnabled;
  final double currentTiltX;
  final double currentTiltY;
  final ValueChanged<double> onTiltXChanged;
  final ValueChanged<double> onTiltYChanged;

  const PerspectiveCanvasControls({
    super.key,
    required this.onReset,
    required this.onResetPerspective,
    required this.onToggleShadows,
    required this.shadowsEnabled,
    required this.currentTiltX,
    required this.currentTiltY,
    required this.onTiltXChanged,
    required this.onTiltYChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditorTool(
            icon: Icons.restart_alt,
            label: 'Reset All',
            onTap: onReset,
          ),
          const Divider(color: Colors.white24, height: 16),
          _EditorTool(
            icon: shadowsEnabled ? Icons.lens_blur : Icons.panorama_fish_eye,
            label: 'Shadows',
            onTap: onToggleShadows,
            isActive: shadowsEnabled,
          ),
          const Divider(color: Colors.white24, height: 16),
          _EditorTool(
            icon: Icons.view_in_ar,
            label: 'Flat 3D',
            onTap: onResetPerspective,
          ),
          const SizedBox(height: 8),
          _TiltControl(
            label: 'Tilt X',
            value: currentTiltX,
            onChanged: onTiltXChanged,
          ),
          const SizedBox(height: 8),
          _TiltControl(
            label: 'Tilt Y',
            value: currentTiltY,
            onChanged: onTiltYChanged,
          ),
        ],
      ),
    );
  }
}

class _EditorTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _EditorTool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isActive ? Colors.amber : Colors.white, 
              size: 20
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.amber : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TiltControl extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _TiltControl({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            height: 60,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                  trackHeight: 2.0,
                ),
                child: Slider(
                  value: value,
                  min: -0.8,
                  max: 0.8,
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white24,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
