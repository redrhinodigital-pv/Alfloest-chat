import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';

/// Voice note widget for playback in chat bubbles
class VoiceNoteWidget extends StatefulWidget {
  final bool isSent;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onSpeedChange;
  final double speed;

  const VoiceNoteWidget({
    super.key,
    required this.isSent,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.onPlayPause,
    this.onSeek,
    this.onSpeedChange,
    this.speed = 1.0,
  });

  @override
  State<VoiceNoteWidget> createState() => _VoiceNoteWidgetState();
}

class _VoiceNoteWidgetState extends State<VoiceNoteWidget> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: widget.onPlayPause,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isSent ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.isSent ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Waveform / progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  trackHeight: 3,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: widget.isSent ? Colors.white : AppColors.primary,
                  inactiveTrackColor: widget.isSent ? Colors.white30 : AppColors.primary.withValues(alpha: 0.2),
                  thumbColor: widget.isSent ? Colors.white : AppColors.primary,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: widget.onSeek,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatDuration(widget.position),
                    style: AppTextStyles.chatTimestamp.copyWith(
                      color: widget.isSent ? Colors.white60 : AppColors.textHint,
                    ),
                  ),
                  if (widget.onSpeedChange != null)
                    GestureDetector(
                      onTap: widget.onSpeedChange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: widget.isSent ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${widget.speed}x',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: widget.isSent ? Colors.white70 : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
