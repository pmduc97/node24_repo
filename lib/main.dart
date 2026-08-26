import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/audio_player_service.dart';
import 'widgets/playlist_view.dart';
import 'widgets/player_controls.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferred portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF161925),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VibeMusicApp());
}

class VibeMusicApp extends StatelessWidget {
  const VibeMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AudioPlayerService>(
      create: (_) => AudioPlayerService(),
      child: MaterialApp(
        title: 'Vibe Music Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F111A),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE94057),
            secondary: Color(0xFFF27121),
            surface: Color(0xFF1E222D),
          ),
        ),
        home: const MusicPlayerHomeScreen(),
      ),
    );
  }
}

class MusicPlayerHomeScreen extends StatelessWidget {
  const MusicPlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94057), Color(0xFFF27121)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vibe Music',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white54),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Vibe Music Player',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.music_note,
                  color: Color(0xFFE94057),
                  size: 36,
                ),
                children: const [
                  Text('Ứng dụng nghe nhạc Offline cho Android.\nNhẹ nhàng, nhanh chóng và mượt mà.'),
                ],
              );
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(child: PlaylistView()),
            PlayerControls(),
          ],
        ),
      ),
    );
  }
}
