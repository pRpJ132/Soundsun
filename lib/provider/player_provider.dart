import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';
import 'package:soundsun/sharedPreferences/user.dart';

class PlayerProvider extends ChangeNotifier {
  final _client = SoundcloudClient();
  final _player = AudioPlayer();

  TrackSearchResult? _currentTrack;
  final List<TrackSearchResult> _tracks = [];
  bool _hideMiniApp = false;
  bool _openMiniApp = false;
  bool _isMusicPlaylist = false;
  String _currentMusicPlaylist = "";
  final Map<String, List<TrackSearchResult>> _playlistUser = {};
  
  SoundcloudClient get client => _client;
  AudioPlayer get player => _player;
  TrackSearchResult? get currentTrack => _currentTrack;
  List<TrackSearchResult> get tracks => _tracks;
  bool get hideMiniApp => _hideMiniApp;
  bool get openMiniApp => _openMiniApp;
  bool get isMusicPlaylist => _isMusicPlaylist;
  String get currentMusicPlaylist => _currentMusicPlaylist;
  Map<String, List<TrackSearchResult>> get playlistUser => _playlistUser;

  Future<void> loadPlaylists() async {
    final data = await UserPreferences.getPlaylists();

    if (data != null) {
      _playlistUser..clear..addAll(data);
    }

    notifyListeners();
  }

  PlayerProvider() {
    loadPlaylists();
    _player.setVolume(0.7);
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed && _player.playing) {
        if (_currentTrack == null) return;
        final indexTrack = _tracks.indexWhere((tr) => tr.id == _currentTrack!.id);
        if (indexTrack == -1) return;

        final nextIndexTrack = indexTrack + 1;
        if (nextIndexTrack < 0 || nextIndexTrack >= _tracks.length) return;

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

  Future<void> createPlaylist(String name) async {
    if (currentTrack == null) return;

    _playlistUser[name] = [currentTrack!];
    await UserPreferences.setPlaylists(_playlistUser);
    notifyListeners();
  }

  Future<void> removePlaylist(String playlistName) async {
    if (!_playlistUser.containsKey(playlistName)) return;

    _playlistUser.remove(playlistName);
    await UserPreferences.setPlaylists(_playlistUser);
    notifyListeners();
  }

  
  Future<void> addTrackToPlaylist(String playlistName) async {
    if (currentTrack == null) return;

    final playlist = _playlistUser[playlistName];
    if (playlist == null) return;

    final alreadyExists = playlist.any((track) => track.id == currentTrack!.id);

    if (!alreadyExists) {
      _playlistUser[playlistName]!.add(currentTrack!);
      await UserPreferences.setPlaylists(_playlistUser);
      if (_isMusicPlaylist && currentMusicPlaylist == playlistName) tracks.add(currentTrack!);
      notifyListeners();
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistName, int id) async {
    final playlist = _playlistUser[playlistName];
    if (playlist == null) return;

    _playlistUser[playlistName]!.removeWhere((track) => track.id == id);
    if (_isMusicPlaylist && currentMusicPlaylist == playlistName) tracks.removeWhere((track) => track.id == id);

    await UserPreferences.setPlaylists(_playlistUser);

    notifyListeners();
  }

  void setTracks(List<TrackSearchResult> newTracks) {
    // Important: copy items, do NOT keep external list reference.
    // Otherwise clearing `_tracks` would also clear the playlist list.
    if (identical(newTracks, _tracks)) return;
    _tracks
      ..clear()
      ..addAll(newTracks);
    notifyListeners();
  }

  set currentMusicPlaylist(String value) {
    _currentMusicPlaylist = value;
    notifyListeners();
  }

  set hideMiniApp(bool value) {
    _hideMiniApp = value;
    notifyListeners();
  }

  set openMiniApp(bool value) {
    _openMiniApp = value;
    notifyListeners();
  }

  set isMusicPlaylist(bool value) {
    _isMusicPlaylist = value;
    notifyListeners();
  }

  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0.0, 1.0));
    notifyListeners();
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
    _player.setLoopMode(mode);
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
    await _player.setUrl(url);
    notifyListeners();
  }

  Future<void> lastTrack() async {
    pausePlayer();
    final indexTrack = _tracks.indexWhere((tr) => tr.id == _currentTrack!.id);
    if (indexTrack == -1) return;

    final nextIndexTrack = indexTrack - 1;
    if (nextIndexTrack < 0 || nextIndexTrack >= _tracks.length) return;

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

  Future<void> nextTrack() async {
    pausePlayer();
    final indexTrack = _tracks.indexWhere((tr) => tr.id == _currentTrack!.id);
    if (indexTrack == -1) return;

    final nextIndexTrack = indexTrack + 1;
    if (nextIndexTrack < 0 || nextIndexTrack >= _tracks.length) return;

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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}