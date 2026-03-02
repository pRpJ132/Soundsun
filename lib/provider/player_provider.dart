import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

class PlayerProvider extends ChangeNotifier {
  final _client = SoundcloudClient();
  final _player = AudioPlayer();
  TrackSearchResult? _currentTrack;
  final List<TrackSearchResult> _tracks = [];
  
  SoundcloudClient get client => _client;
  AudioPlayer get player => _player;
  TrackSearchResult? get currentTrack => _currentTrack;
  List<TrackSearchResult> get tracks => _tracks;

  PlayerProvider() {
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed && _player.playing) {
        if (_currentTrack == null) return;
        final indexTrack = _tracks.indexWhere((tr) => tr.id == _currentTrack!.id);
        if (indexTrack == -1) return;

        final nextIndexTrack = indexTrack + 1;

        _currentTrack = _tracks[nextIndexTrack];
        final streams = await _client.tracks.getStreams(_currentTrack!.id);

        final mp3 = streams.firstWhere(
          (s) => s.container == 'mpeg',
          orElse: () => throw Exception('Нет MP3 потока'),
        );

        await setUrlPlayer(mp3.url);
        await playPlayer();
        notifyListeners();
      }
    });
  }

  set currentTrack(TrackSearchResult ct) {
    _currentTrack = ct;
    notifyListeners();
  }

  Future<void> playPlayer() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> seekPlayer(Duration dr) async {
    await _player.seek(dr);
    notifyListeners();
  }

  Future<void> setLoopModePlayer(LoopMode mode) async {
    player.setLoopMode(mode);
    notifyListeners();
  }

  Future<void> stopPlayer() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> pausePlayer() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> setUrlPlayer(String url) async {
    await player.setUrl(url);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}