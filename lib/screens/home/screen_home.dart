import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';
import 'package:soundsun/provider/player_provider.dart';
import 'package:soundsun/sharedPreferences/user.dart';

import 'widgets/mini_player.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentQuery = '';

  StreamIterator<Iterable<SearchResult>>? _searchIterator;

  bool hideMiniApp = false;

  Future<void> loadHistory() async {
    _searchHistory = (await UserPreferences.getHistoryUser())!;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) _searchHistory.removeLast();
  }

  Future<void> _performSearch(String query, SoundcloudClient client, List<TrackSearchResult> tracks) async {
    if (query.trim().isEmpty) return;

    _addToHistory(query);
    await UserPreferences.setHistoryUser(_searchHistory);

    tracks.clear();

    setState(() {
      _hasMore = true;
      _currentQuery = query;
      _isLoading = true;
    });

    _searchIterator?.cancel();

    final stream = client.search(
      query,
      searchFilter: SearchFilter.tracks,
      limit: 20,
    );

    _searchIterator = StreamIterator(stream);

    await _loadNextPage(tracks);
  }

  Future<void> _loadNextPage(List<TrackSearchResult> tracks) async {
    if (!_hasMore || _searchIterator == null) return;
    setState(() => _isLoading = true);

    try {
      if (await _searchIterator!.moveNext()) {
        final page = _searchIterator!.current;
        final newTracks = page
            .whereType<TrackSearchResult>()
            .toList();

        tracks.addAll(newTracks);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _playTrack(
    TrackSearchResult track,
    provider,
  ) async {
    try {
      await provider.stopPlayer();
      provider.currentTrack = track;

      final streams = await provider.client.tracks.getStreams(track.id);

      final mp3 = streams.firstWhere(
        (s) => s.container == 'mpeg',
        orElse: () => throw Exception('Нет MP3 потока'),
      );

      await provider.setUrlPlayer(mp3.url);
      await provider.playPlayer();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка воспроизведения: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchIterator?.cancel();
    super.dispose();
  }

  bool hideInputSearch = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(99, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: AnimatedOpacity(
            opacity: provider.openMiniApp ? 0 : 1,
            onEnd: () => setState(() {
              provider.openMiniApp ? hideInputSearch = true : hideInputSearch = false;
            }),
            duration: const Duration(milliseconds: 350),
            child: !hideInputSearch ? TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Найти трек...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color.fromARGB(94, 32, 32, 32),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) {
                _performSearch(v.trim(), provider.client, provider.tracks);
                FocusScope.of(context).unfocus();
              },
            ) : null,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_searchHistory.isNotEmpty)
                  AnimatedOpacity(
                    opacity: provider.openMiniApp ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(top: 12, bottom: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 8,
                          mainAxisSize: MainAxisSize.min,
                          children: _searchHistory.map((query) {
                            return ElevatedButton(
                              child: Text(query, style: const TextStyle(color: Colors.white70)),
                              onPressed: () {
                                _searchController.text = query;
                                _performSearch(query, provider.client, provider.tracks);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                
                Expanded(
                  child: AnimatedOpacity(
                    opacity: provider.openMiniApp ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    child: RefreshIndicator(
                      onRefresh: () => _performSearch(_currentQuery, provider.client, provider.tracks),
                      child: provider.tracks.isEmpty && !_isLoading
                        ? const Center(
                            child: Text(
                              'Поиск ничего не дал\nПопробуйте другое название',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: 16, 
                              right: 16,
                              bottom: provider.currentTrack != null
                                ? (provider.hideMiniApp ? 70 : 240)
                                : 0,
                            ),
                            controller: _scrollController,
                            itemCount: provider.tracks.length + (_isLoading || _hasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == provider.tracks.length) {
                                if (!_isLoading && _hasMore) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _loadNextPage(provider.tracks);
                                  });
                                }
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                                      
                              final track = provider.tracks[i];
                              final isPlaying = provider.currentTrack?.id == track.id;
                                      
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2)
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  color: !isPlaying ?
                                  const Color.fromARGB(103, 31, 31, 31) : 
                                  const Color.fromARGB(133, 56, 55, 59),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: track.artworkUrl != null
                                          ? Image.network(
                                              track.artworkUrl.toString(),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                    color: Colors.grey[800],
                                                    child: const Icon(
                                                      Icons.music_note_rounded,
                                                    )
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: Colors.grey[900],
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.music_note_rounded,
                                              )
                                          )
                                    )
                                  ),
                                  title: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    track.user.username,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: isPlaying
                                      ? const Icon(CupertinoIcons.speaker_2_fill, color: Color.fromARGB(255, 255, 255, 255))
                                      : null,
                                  onTap: () => {
                                    provider.openMiniApp = false,
                                    provider.hideMiniApp = false,
                                    _playTrack(track, provider)
                                  },
                                ),
                              );
                            },
                          ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedOpacity(
              opacity: provider.currentTrack != null ? 1 : 0,
              duration: const Duration(milliseconds: 650),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 550),
                curve: Curves.ease,
                transform: Matrix4.translationValues(
                  0,
                  provider.currentTrack != null
                      ? (provider.openMiniApp ? -80
                        :  provider.hideMiniApp ? 305 : 0)
                      : 100,
                  0,
                ),
                child: provider.currentTrack != null
                    ? MiniPlayer()
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
  }
}