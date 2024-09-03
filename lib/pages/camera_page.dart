import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // Add this import
import 'package:flutter/cupertino.dart'; // Add this import

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedLink = '';
  bool _cameraPermissionGranted = false;
  bool _showButton = false;
  bool _isQRInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
    if (_cameraPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
    if (_cameraPermissionGranted) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    if (controller != null) {
      controller!.resumeCamera();
    } else {
      setState(() {}); // Trigger a rebuild to create QRView
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scannedLink = scanData.code!;
        _showButton = true;
      });
    }, onError: (error) => _onQRError(controller));

    // Usar Future.delayed para asegurarse de que el controlador esté completamente inicializado
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        controller.resumeCamera().then((_) {
          setState(() {
            _isQRInitialized = true;
          });
        });
      }
    });
  }

  void _onQRError(QRViewController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR inválido o enlace no válido')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isQRInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Espera a que se inicialice la cámara')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _cameraPermissionGranted
            ? _buildQRScanner()
            : _buildPermissionRequest(),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
              Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: Theme.of(context).primaryColor,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: _showButton
                ? ElevatedButton(
                    onPressed: _launchURL,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'PULSA AQUÍ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Text('Escanea un código QR'),
          ),
        )
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.camera,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Permiso de cámara requerido',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para escanear códigos QR, necesitas permitir el acceso a la cámara en los ajustes de la aplicación.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Activar cámara',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL() async {
    if (await canLaunch(scannedLink)) {
      await launch(scannedLink);
      setState(() {
        _showButton = false;
        scannedLink = '';
      });
    } else {
      throw 'Could not launch $scannedLink';
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso denegado'),
        content: const Text(
            'Sin acceso a la cámara no podrás escanear códigos QR. Por favor, activa el permiso en los ajustes de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  bool isQRInitialized() {
    return _isQRInitialized;
  }
}
