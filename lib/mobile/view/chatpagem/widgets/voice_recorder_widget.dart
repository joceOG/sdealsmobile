import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum _RecorderUiState { idle, recording, preview }

/// Widget d'enregistrement vocal style WhatsApp.
/// Passe par 3 états : idle → recording → preview.
class VoiceRecorderWidget extends StatefulWidget {
  final void Function(File audioFile, int durationSeconds) onSend;

  const VoiceRecorderWidget({super.key, required this.onSend});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();

  _RecorderUiState _state = _RecorderUiState.idle;
  int _seconds = 0;
  Timer? _timer;
  String? _filePath;
  int _durationSec = 0;

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    if (!await _requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone refusée.')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );

    setState(() {
      _state = _RecorderUiState.recording;
      _filePath = path;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= 120) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _durationSec = _seconds;
    await _recorder.stop();
    setState(() => _state = _RecorderUiState.preview);
  }

  void _discard() {
    if (_filePath != null) {
      try {
        File(_filePath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _state = _RecorderUiState.idle;
      _filePath = null;
      _seconds = 0;
      _durationSec = 0;
    });
  }

  void _send() {
    if (_filePath == null) return;
    final file = File(_filePath!);
    widget.onSend(file, _durationSec);
    setState(() {
      _state = _RecorderUiState.idle;
      _filePath = null;
      _seconds = 0;
      _durationSec = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_state == _RecorderUiState.preview) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: Colors.green, size: 20),
          const SizedBox(width: 4),
          Text(
            '🎤 ${_fmt(_durationSec)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: _discard,
            tooltip: 'Supprimer',
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green, size: 22),
            onPressed: _send,
            tooltip: 'Envoyer',
          ),
        ],
      );
    }

    if (_state == _RecorderUiState.recording) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: _PulsingDot(),
          ),
          const SizedBox(width: 6),
          Text(
            _fmt(_seconds),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 20),
            ),
          ),
        ],
      );
    }

    // idle
    return GestureDetector(
      onTap: _startRecording,
      child: const Icon(Icons.mic_none, color: Colors.grey, size: 26),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
