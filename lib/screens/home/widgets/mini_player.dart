import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import 'package:soundsun/provider/player_provider.dart';
import 'package:soundsun/screens/home/diolog/diolog_playlist.dart';
import 'package:http/http.dart' as http;

class WaveformData {
  final List<double> samples;

  WaveformData({required this.samples});

  factory WaveformData.fromJson(Map<String, dynamic> json) {
    final raw = json['samples'] ?? [];
    final samples = List<double>.from(raw.map((e) => (e as num).toDouble()));
    return WaveformData(samples: samples);
  }
}

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

  WaveformData? waveformData;

  Future<void> loadWaveform(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = WaveformData.fromJson(jsonDecode(response.body));
        setState(() {
          waveformData = data;
        });
      } else {
        print("Ошибка загрузки waveform: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка загрузки waveform: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<PlayerProvider>();
    if (provider.currentTrack?.waveformUrl != null && waveformData == null) {
      loadWaveform(provider.currentTrack!.waveformUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        glassColor: Color.fromARGB(155, 0, 0, 0),
        ambientStrength: 2,
        thickness: 22,
        blur: 0,
      ),
      child: LiquidGlassBlendGroup(
        blend: 66.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 58),
            LiquidGlass.grouped(
              shape: LiquidRoundedSuperellipse(
                borderRadius: 60,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  overlayColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent
                ),
                onLongPress: () => provider.openMiniApp ? {
                    provider.openMiniApp = false,
                    provider.hideMiniApp = false,
                  }
                  : {
                    provider.openMiniApp = true,
                  },
                onPressed: () => provider.openMiniApp 
                ? {
                  provider.openMiniApp = false,
                  provider.hideMiniApp = false,
                }
                : provider.hideMiniApp = !provider.hideMiniApp,
                child: Icon(
                  provider.openMiniApp ? CupertinoIcons.minus
                  : !provider.hideMiniApp ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        
            const SizedBox(height: 8),
        
            Flexible(
              child: LiquidGlass.grouped(
                shape: LiquidRoundedSuperellipse(
                  borderRadius: 15,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  height: provider.openMiniApp 
                    ? double.infinity
                    : null,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _gradientAnimation,
                        builder: (context, _) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  Color.fromARGB(255, 210, 210, 210),
                                  Color.fromARGB(234, 255, 255, 255),
                                  Color.fromARGB(255, 210, 210, 210),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                                begin: Alignment(-1 + 2 * _gradientAnimation.value, 0),
                                end: Alignment(1 + 2 * _gradientAnimation.value, 0),
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, 0));
                            },
                            child: Text(
                              provider.currentTrack?.title ?? "—",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                                color: Colors.white,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 56 + _gradientAnimation.value * 2,
                                    spreadRadius: 56 + _gradientAnimation.value * 0.2,
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
                        builder: (context, snapshot) {
                          if (waveformData == null) return const SizedBox();

                          return SizedBox(
                            width: 360,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: provider.currentTrack!.artworkUrl != null
                                      ? Image.network(
                                          provider.currentTrack!.artworkUrl.toString(),
                                          fit: BoxFit.cover,
                                          width: 140,
                                          height: 140,
                                        )
                                      : Container(
                                          width: 140,
                                          height: 140,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.music_note_rounded),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                              
                      StreamBuilder<Duration>(
                        stream: provider.player.positionStream,
                        builder: (context, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final dur = totalDuration ?? Duration.zero;
                          final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
                              
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      bool isFavorite = false;
                                      if (provider.currentTrack == null) isFavorite = false;
                            
                                      for (final playlist in provider.playlistUser.values) {
                                        if (playlist.any((t) => t.id == provider.currentTrack!.id)) {
                                          isFavorite = true;
                                        }
                                      }
                            
                                      return ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          overlayColor: const Color.fromARGB(99, 158, 158, 158),
                                          elevation: 0,
                                        ),
                                        label: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_outline_sharp,
                                          size: 34,
                                          color: const Color.fromARGB(163, 255, 255, 255),
                                        ),
                                        onPressed: () => createShowDialog(context, provider),
                                      );
                                    }
                                  ),
                                  Spacer(),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      overlayColor: const Color.fromARGB(99, 158, 158, 158),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      setState(() => isLooping = !isLooping);
                                      provider.setLoopModePlayer(isLooping ? LoopMode.one : LoopMode.off);
                                    }, 
                                    label: Icon(
                                      Icons.repeat,
                                      color: isLooping
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.55),
                                      size: 34,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                  activeTrackColor: const Color.fromARGB(255, 191, 191, 191),
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
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
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.white.withValues(alpha: 0.75),
                                        shadows: [
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 40
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatTime(dur),
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.white.withValues(alpha: 0.75),
                                        shadows: [
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 40
                                          ),
                                        ],
                                      ),
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
                          IconButton(
                            iconSize: 28,
                            padding: const EdgeInsets.all(12),
                            icon: Icon(
                              CupertinoIcons.backward_end_fill,
                              color: Colors.white,
                            ),
                            onPressed: () => provider.lastTrack(),
                          ),
                            
                          StreamBuilder<bool>(
                            stream: provider.player.playingStream,
                            initialData: provider.player.playing,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                            
                              return IconButton(
                                iconSize: 48,
                                padding: const EdgeInsets.all(12),
                                icon: Icon(
                                  isPlaying
                                      ? CupertinoIcons.pause_solid
                                      : CupertinoIcons.play_arrow_solid,
                                  color: isPlaying
                                      ? const Color.fromARGB(174, 255, 255, 255)
                                      : Colors.white,
                                ),
                                onPressed: () async {
                                  isPlaying
                                      ? await provider.pausePlayer()
                                      : await provider.playPlayer();
                                },
                              );
                            },
                          ),
                            
                          Transform.rotate(
                            angle: 3.1415926535,
                            child: IconButton(
                              iconSize: 28,
                              padding: const EdgeInsets.all(12),
                              icon: const Icon(
                                CupertinoIcons.backward_end_fill,
                                color: Colors.white,
                              ),
                              onPressed: () => provider.nextTrack(),
                            ),
                          ),
                              
                          const SizedBox(width: 24),
                              
                          SizedBox(
                            width: 100,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                activeTrackColor: const Color.fromARGB(255, 191, 191, 191),
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
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
            ),
          ],
        ),
      ),
    );
  }
}