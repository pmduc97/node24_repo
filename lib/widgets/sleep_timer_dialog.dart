import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _setTimer(BuildContext context, int minutes) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.setSleepTimer(minutes);
    Navigator.of(context).pop();
  }

  void _cancelTimer(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.cancelSleepTimer();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);

    return AlertDialog(
      backgroundColor: const Color(0xFF1F2430),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.timer, color: Color(0xFFE94057)),
          SizedBox(width: 10),
          Text(
            'Hẹn Giờ Tắt Nhạc',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playerService.isTimerActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Đang đếm ngược:',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playerService.remainingTimerSeconds ~/ 60}:${(playerService.remainingTimerSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Chọn thời gian tắt nhạc tự động:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Quick Presets Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [15, 30, 45, 60].map((mins) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3243),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _setTimer(context, mins),
                  child: Text('$mins Phút', style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Custom minutes input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập số phút...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2C3243),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94057),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final mins = int.tryParse(_customController.text);
                    if (mins != null && mins > 0) {
                      _setTimer(context, mins);
                    }
                  },
                  child: const Text('Đặt', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (playerService.isTimerActive)
          TextButton(
            onPressed: () => _cancelTimer(context),
            child: const Text('Tắt Hẹn Giờ', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
