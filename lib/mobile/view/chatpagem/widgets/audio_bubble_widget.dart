import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Bulle de lecture audio style vocal WhatsApp.
/// Affiche un bouton play/pause + barre de progression + durée.
class AudioBubbleWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int? durationHint;
  final Color primaryColor;

  const AudioBubbleWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.durationHint,
    this.primaryColor = const Color(0xFF1CBF3F),
  });

  @override
  State<AudioBubbleWidget> createState() => _AudioBubbleWidgetState();
}

class _AudioBubbleWidgetState extends State<AudioBubbleWidget> {
  late final AudioPlayer _player;
  bool _loading = false;
  bool _loaded = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.durationHint != null) {
      _duration = Duration(seconds: widget.durationHint!);
    }

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => _duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() => _position = Duration.zero);
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      setState(() {});
      return;
    }

    if (!_loaded) {
      setState(() => _loading = true);
      try {
        await _player.setUrl(widget.audioUrl);
        _loaded = true;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }

    await _player.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final fgColor = widget.isMe ? Colors.white : widget.primaryColor;
    final trackColor = widget.isMe ? Colors.white24 : Colors.green.shade100;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isMe ? Colors.white24 : Colors.green.shade50,
            ),
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Icon(
                    _player.playing ? Icons.pause : Icons.play_arrow,
                    color: fgColor,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_fmt(_position)} / ${_fmt(_duration)}',
              style: TextStyle(
                fontSize: 10,
                color: widget.isMe ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
