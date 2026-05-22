import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

/// A premium, self-contained stateful voice message player that displays
/// active waveform animations while playing.
class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final bool isSent;
  final int? durationSeconds;

  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.isSent,
    this.durationSeconds,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  Timer? _waveformTimer;
  final List<double> _waveHeights = List.generate(24, (index) => 3.0 + Random().nextDouble() * 15.0);

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.durationSeconds != null) {
        _duration = Duration(seconds: widget.durationSeconds!);
      }
      await _player.setUrl(widget.url);
      
      _durationSubscription?.cancel();
      _durationSubscription = _player.durationStream.listen((d) {
        if (d != null && mounted) {
          setState(() {
            _duration = d;
          });
        }
      });

      _positionSubscription?.cancel();
      _positionSubscription = _player.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
        }
      });

      _playerStateSubscription?.cancel();
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _player.seek(Duration.zero);
              _player.pause();
              _waveformTimer?.cancel();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading voice message: $e');
    }
  }

  @override
  void didUpdateWidget(covariant VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _reinitAudio();
    }
  }

  Future<void> _reinitAudio() async {
    try {
      _waveformTimer?.cancel();
      await _player.stop();
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
        if (widget.durationSeconds != null) {
          _duration = Duration(seconds: widget.durationSeconds!);
        } else {
          _duration = Duration.zero;
        }
      });
      await _player.setUrl(widget.url);
    } catch (e) {
      debugPrint('Error re-loading voice message: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    _waveformTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      _waveformTimer?.cancel();
    } else {
      await _player.play();
      _startWaveformAnimation();
    }
  }

  void _startWaveformAnimation() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isPlaying) {
        setState(() {
          for (int i = 0; i < _waveHeights.length; i++) {
            _waveHeights[i] = 3.0 + Random().nextDouble() * 18.0;
          }
        });
      }
    });
  }

  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _player.setSpeed(_playbackSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Play/Pause circular button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSent ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isSent ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform & Timestamps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Waveform Bars with tap-to-seek support
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (_duration.inMilliseconds > 0) {
                          final double clickX = details.localPosition.dx;
                          final double width = constraints.maxWidth;
                          final double relativeProgress = (clickX / width).clamp(0.0, 1.0);
                          final seekTarget = Duration(
                            milliseconds: (_duration.inMilliseconds * relativeProgress).round(),
                          );
                          _player.seek(seekTarget);
                        }
                      },
                      child: Container(
                        height: 24,
                        color: Colors.transparent, // Ensure whole container is clickable
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_waveHeights.length, (idx) {
                            final barProgress = idx / _waveHeights.length;
                            final isPassed = barProgress <= progress;
                            return Container(
                              width: 2.5,
                              height: _waveHeights[idx],
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? (widget.isSent ? Colors.white : AppColors.primary)
                                    : (widget.isSent ? Colors.white30 : AppColors.primary.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDuration(_position),
                      style: AppTextStyles.chatTimestamp.copyWith(
                        color: widget.isSent ? Colors.white60 : AppColors.textHint,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDuration(_duration),
                      style: AppTextStyles.chatTimestamp.copyWith(
                        color: widget.isSent ? Colors.white60 : AppColors.textHint,
                      ),
                    ),
                    GestureDetector(
                      onTap: _changeSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: widget.isSent ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: widget.isSent ? Colors.white70 : AppColors.primary,
                            fontSize: 9,
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
      ),
    );
  }
}
