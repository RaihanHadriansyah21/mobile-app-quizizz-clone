import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class UpdateService {
  static final _updater = ShorebirdUpdater();

  /// Programmatically check, download, and prompt to apply Shorebird updates
  static Future<void> checkAndApplyUpdate(BuildContext context) async {
    try {
      // 1. Verify if Shorebird is active and supported on this platform/build
      final isAvailable = _updater.isAvailable;
      debugPrint('Shorebird status: isAvailable = $isAvailable');
      if (!isAvailable) {
        return;
      }

      // 2. Check current patch info
      final currentPatch = await _updater.readCurrentPatch();
      if (currentPatch != null) {
        debugPrint('Current Shorebird patch version: ${currentPatch.number}');
      } else {
        debugPrint('No Shorebird patch currently active.');
      }

      // 3. Query Shorebird server for updates
      debugPrint('Checking for Shorebird updates...');
      final status = await _updater.checkForUpdate();
      debugPrint('Shorebird update status: $status');

      if (status == UpdateStatus.outdated) {
        debugPrint('A new update is available. Downloading patch...');
        
        // 4. Download the patch in the background
        await _updater.update();
        debugPrint('Shorebird patch downloaded successfully.');

        // 5. Prompt user to restart app to apply patch
        if (context.mounted) {
          _showUpdateDialog(context);
        }
      } else if (status == UpdateStatus.restartRequired) {
        debugPrint('Shorebird patch is downloaded. Restart required.');
        if (context.mounted) {
          _showUpdateDialog(context);
        }
      } else {
        debugPrint('Shorebird: Application is up-to-date.');
      }
    } catch (e) {
      debugPrint('Error inside UpdateService: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E), // Curated premium dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Row(
            children: [
              Icon(Icons.system_update_alt, color: Color(0xFF8A2BE2)),
              SizedBox(width: 12),
              Text(
                'Pembaruan Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Pembaruan aplikasi telah berhasil diunduh. Silakan ketuk OK untuk memulai ulang aplikasi dan menerapkan pembaruan.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                exit(0);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
