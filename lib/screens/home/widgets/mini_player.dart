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

class _MiniPlayerState extends State<MiniPlayer> 
  with TickerProviderStateMixin {
  Duration? totalDuration;
  bool isLooping = false;
  StreamSubscription<Duration?>? _durationSub;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

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

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeIn),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: false);

    _gradientAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _glowController.dispose();
    _gradientController.dispose();
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
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color.fromARGB(210, 22, 22, 22).withOpacity(0.85),
            overlayColor: const Color.fromARGB(210, 203, 203, 203).withOpacity(0.85),
          ),
          onPressed: () => provider.hideMiniApp = !provider.hideMiniApp,
          child: Icon(
            !provider.hideMiniApp ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: 8),

        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 67, 62, 95).withOpacity(_glowAnimation.value * 0.7),
                    blurRadius: 20 + _glowAnimation.value * 2,
                    spreadRadius: 2 + _glowAnimation.value * 0.2,
                  ),
                  BoxShadow(
                    color: const Color.fromARGB(180, 220, 220, 220).withOpacity(_glowAnimation.value * 0.4),
                    blurRadius: 35,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: const Color.fromARGB(210, 22, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _gradientAnimation,
                        builder: (context, _) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  Color.fromARGB(255, 193, 193, 193),
                                  Color.fromARGB(234, 255, 255, 255),
                                  Color.fromARGB(255, 193, 193, 193),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                                begin: Alignment(-1 + 2 * _gradientAnimation.value, 0),
                                end: Alignment(1 + 2 * _gradientAnimation.value, 0),
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, 0));
                            },
                            child: Text(
                              provider.currentTrack?.title ?? "—",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color.fromARGB(120, 140, 100, 255),
                                    blurRadius: 12,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                      ),
            
                      const SizedBox(height: 10),
            
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
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                  activeTrackColor: const Color.fromARGB(255, 191, 191, 191),
                                  inactiveTrackColor: Colors.white.withOpacity(0.12),
                                  thumbColor: Colors.white,
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTime(pos),
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                                    ),
                                    Text(
                                      _formatTime(dur),
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            
                      const SizedBox(height: 12),
            
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: provider.player.playing ? 1.0 + (_glowAnimation.value - 0.4) * 0.12 : 1.0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: IconButton(
                              iconSize: 48,
                              padding: const EdgeInsets.all(12),
                              icon: Icon(
                                provider.player.playing ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
                                color: provider.player.playing 
                                  ? const Color.fromARGB(174, 255, 255, 255)
                                  : Colors.white,
                              ),
                              onPressed: () async {
                                if (provider.player.playing) {
                                  await provider.pausePlayer();
                                } else {
                                  await provider.playPlayer();
                                }
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
            
                          const SizedBox(width: 32),
            
                          IconButton(
                            iconSize: 34,
                            icon: Icon(
                              Icons.repeat,
                              color: isLooping
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                            ),
                            onPressed: () {
                              setState(() => isLooping = !isLooping);
                              provider.setLoopModePlayer(isLooping ? LoopMode.one : LoopMode.off);
                            },
                          ),
            
                          const SizedBox(width: 24),
            
                          SizedBox(
                            width: 100,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                activeTrackColor: const Color.fromARGB(255, 191, 191, 191),
                                inactiveTrackColor: Colors.white.withOpacity(0.18),
                                thumbColor: Colors.white,
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                              ),
                              child: StreamBuilder<double>(
                                stream: provider.player.volumeStream,
                                initialData: 1.0,
                                builder: (context, snapshot) {
                                  final volume = snapshot.data ?? 1.0;
                                  return Slider(
                                    value: volume.clamp(0.0, 1.0),
                                    onChanged: (value) {
                                      provider.setVolume(value);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}