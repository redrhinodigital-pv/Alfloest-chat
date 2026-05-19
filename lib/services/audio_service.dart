import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

/// Audio service for voice note recording and playback
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  /// Stream of current playback position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Get current playback position
  Duration? get position => _player.position;

  /// Get total duration of loaded audio
  Duration? get duration => _player.duration;

  // ─────────────────────────────────────────────
  // Recording
  // ─────────────────────────────────────────────

  /// Start recording a voice note (AAC format for lightweight storage)
  Future<String?> startRecording() async {
    try {
      if (kIsWeb) {
        debugPrint('Voice recording not supported on web');
        return null;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Record as AAC for compression
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000, // Low bitrate for lightweight files
          sampleRate: 22050, // Sufficient for voice
          numChannels: 1, // Mono for smaller files
        ),
        path: path,
      );

      _isRecording = true;
      _currentRecordingPath = path;
      return path;
    } catch (e) {
      debugPrint('Recording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;
      return path;
    } catch (e) {
      debugPrint('Stop recording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete temporary file
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }

      // Delete the temporary file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      debugPrint('Cancel recording error: $e');
    }
  }

  /// Get the amplitude of current recording (for waveform visualization)
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;
    } catch (e) {
      return -160.0; // Silence
    }
  }

  // ─────────────────────────────────────────────
  // Playback
  // ─────────────────────────────────────────────

  /// Play a voice note from URL
  Future<void> play(String url) async {
    try {
      await _player.setUrl(url);
      _isPlaying = true;
      await _player.play();
    } catch (e) {
      debugPrint('Playback error: $e');
      _isPlaying = false;
    }
  }

  /// Play from local file
  Future<void> playFile(String path) async {
    try {
      await _player.setFilePath(path);
      _isPlaying = true;
      await _player.play();
    } catch (e) {
      debugPrint('File playback error: $e');
      _isPlaying = false;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
    _isPlaying = true;
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Set playback speed (0.5x, 1x, 1.5x, 2x)
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  // ─────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────

  /// Delete a temporary audio file
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Delete file error: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
