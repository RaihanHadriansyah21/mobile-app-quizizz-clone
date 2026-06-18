import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../core/theme/app_theme.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin(String code) async {
    if (code.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser!.id;
    final mahasiswaProvider = Provider.of<MahasiswaProvider>(context, listen: false);

    String? error = await mahasiswaProvider.joinClassWithCode(
      code.trim(),
      studentId,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (error != null) {
        HapticFeedback.heavyImpact();
        AppTheme.showPremiumSnackBar(
          context,
          error,
          SnackBarType.error,
        );
      } else {
        HapticFeedback.mediumImpact();
        AppTheme.showPremiumSnackBar(
          context,
          "Berhasil bergabung ke kelas!",
          SnackBarType.success,
        );
        _codeController.clear();
      }
    }
  }

  void _startQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          onCodeScanned: (code) {
            Navigator.pop(context);
            _handleJoin(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gabung Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 80,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Gabung ke Kelas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Masukkan 6-digit kode kelas dari dosen Anda, atau scan QR Code yang ditampilkan oleh dosen Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                labelText: 'Kode Kelas',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _handleJoin(_codeController.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Gabung dengan Kode'),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.getBorderColor(context))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.getBorderColor(context))),
              ],
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _startQrScanner,
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.accent,
              ),
              label: const Text('Scan QR Code Kelas'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  final Function(String) onCodeScanned;
  const QrScannerPage({super.key, required this.onCodeScanned});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _completed = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR Code'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_completed) {
                  _completed = true;
                  widget.onCodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Text(
              'Arahkan kamera ke QR Code kelas yang ditampilkan dosen Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              color: AppTheme.getSurface(context).withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Simulator Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onCodeScanned("102948");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Simulate Scan (X-A)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
