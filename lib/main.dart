import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/audio_player_service.dart';
import 'services/update_service.dart';
import 'widgets/playlist_view.dart';
import 'widgets/player_controls.dart';
import 'widgets/update_dialog.dart';

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

class MusicPlayerHomeScreen extends StatefulWidget {
  const MusicPlayerHomeScreen({super.key});

  @override
  State<MusicPlayerHomeScreen> createState() => _MusicPlayerHomeScreenState();
}

class _MusicPlayerHomeScreenState extends State<MusicPlayerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto check update silently 3 seconds after app launch
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkForUpdate(silent: true);
      }
    });
  }

  Future<void> _checkForUpdate({bool silent = false}) async {
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang kiểm tra bản cập nhật...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final updateInfo = await UpdateService.checkForUpdate();
    if (!mounted) return;

    if (updateInfo != null) {
      showDialog(
        context: context,
        builder: (ctx) => UpdateDialog(updateInfo: updateInfo),
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phiên bản v${UpdateService.currentVersion} đang là mới nhất!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vibe Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'v${UpdateService.currentVersion}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Check for update button
          IconButton(
            icon: const Icon(Icons.system_update_alt, color: Color(0xFFE94057)),
            tooltip: 'Kiểm tra cập nhật',
            onPressed: () => _checkForUpdate(silent: false),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white54),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Vibe Music Player',
                applicationVersion: 'v${UpdateService.currentVersion}',
                applicationIcon: const Icon(
                  Icons.music_note,
                  color: Color(0xFFE94057),
                  size: 36,
                ),
                children: [
                  const Text('Ứng dụng nghe nhạc Offline cho Android.\nNhẹ nhàng, mượt mà và tự động cập nhật.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94057),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Kiểm Tra Cập Nhật'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _checkForUpdate(silent: false);
                    },
                  ),
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
