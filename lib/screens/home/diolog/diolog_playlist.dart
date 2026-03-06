import 'package:flutter/material.dart';
import 'package:soundsun/provider/player_provider.dart';

final TextEditingController controller = TextEditingController();

void createShowDialog(BuildContext context, PlayerProvider provider) {
  showDialog(
    context: context,
    builder: (context) {
      final selectedPlaylists = <String>{};

      provider.playlistUser.forEach((name, tracks) {
        if (provider.currentTrack != null &&
            tracks.any((t) => t.id == provider.currentTrack!.id)) {
          selectedPlaylists.add(name);
        }
      });

      return StatefulBuilder(
        builder: (context, setState) {
          final hasPlaylists = provider.playlistUser.isNotEmpty;

          return AlertDialog(
            title: const Text("Добавить в плейлист"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPlaylists) ...[
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: provider.playlistUser.length,
                        itemBuilder: (context, i) {
                          final name = provider.playlistUser.keys.elementAt(i);
                          final isSelected = selectedPlaylists.contains(name);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(15),
                              color: const Color.fromARGB(133, 56, 55, 59),
                            ),
                            child: ListTile(
                              title: Text(name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    const Icon(Icons.check, color: Colors.green),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        provider.removePlaylist(name);
                                        selectedPlaylists.remove(name);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedPlaylists.remove(name);
                                    provider.removeTrackFromPlaylist(name, provider.currentTrack!.id);
                                  } else {
                                    selectedPlaylists.add(name);
                                    provider.addTrackToPlaylist(name);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Название нового плейлиста",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.clear();
                  Navigator.pop(context);
                },
                child: const Text("Отмена"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.createPlaylist(controller.text);
                    controller.clear();
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Сохранить"),
              ),
            ],
          );
        },
      );
    },
  );
}