import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:soundsun/provider/player_provider.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Duration? totalDuration;
  bool isLooping = false;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PlayerProvider>();
    _durationSub = provider.player.durationStream.listen((d) {
      if (!mounted) return;
      setState(() {
        totalDuration = d ?? Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            backgroundColor: WidgetStateProperty.all(
            const Color.fromARGB(150, 26, 26, 36).withOpacity(0.85)
            )
          ),
          onPressed: () => provider.hideMiniApp = !provider.hideMiniApp,
          child: Icon(
            !provider.hideMiniApp ? 
            CupertinoIcons.arrow_down
            : CupertinoIcons.arrow_up,
            color: Colors.white,
          )
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1A1A28).withOpacity(0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.currentTrack!.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              StreamBuilder<Duration>(
                stream: provider.player.positionStream,
                builder: (context, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = totalDuration ?? Duration.zero;
                  final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
        
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          activeTrackColor: const Color.fromARGB(255, 60, 49, 109),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color.fromARGB(255, 75, 60, 138),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            final ms = (v * dur.inMilliseconds).round();
                            provider.seekPlayer(Duration(milliseconds: ms));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTime(pos), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            Text(_formatTime(dur), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 42,
                    icon: Icon(
                      provider.player.playing ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (provider.player.playing) {
                        provider.pausePlayer();
                        setState(() {});
                      } else {
                        provider.playPlayer();
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    iconSize: 32,
                    icon: Icon(
                      Icons.repeat,
                      color: isLooping ? const Color.fromARGB(255, 52, 127, 255) : const Color.fromARGB(136, 255, 255, 255),
                    ),
                    onPressed: () {
                      setState(() => isLooping = !isLooping);
                      provider.setLoopModePlayer(isLooping ? LoopMode.one : LoopMode.off);
                    },
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