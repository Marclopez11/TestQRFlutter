import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';
import '../widgets/header.dart';

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
  String _lastScannedLink = '';
  String _lastNotifiedLink = '';
  bool _isCheckingPermission = true;
  String _currentLanguage = 'ca';
  String _selectedLanguage = 'CA';
  late StreamSubscription<String> _languageSubscription;
  late ValueNotifier<String> _languageNotifier;
  final _openLinkButtonKey = GlobalKey();
  final _placeQRCodeTextKey = GlobalKey();
  final _scanQRCodeTextKey = GlobalKey();

  String _openLinkText = '';
  String _placeQRCodeText = '';
  String _scanQRCodeText = '';

  Timer? _languageTimer;
  final ApiService _apiService = ApiService();
  bool _isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
    _loadInitialLanguage();
    _startLanguageTimer();
    _updateTexts();
  }

  Future<void> _loadInitialLanguage() async {
    setState(() {
      _isLoadingLanguage = true;
    });

    try {
      final language = await _apiService.getCurrentLanguage();
      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _selectedLanguage = language.toUpperCase();
          _isLoadingLanguage = false;
        });
      }
    } catch (e) {
      print('Error loading initial language: $e');
      if (mounted) {
        setState(() {
          _isLoadingLanguage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    _languageTimer?.cancel();
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
      _isCheckingPermission = false;
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
      if (scanData.code != null && scanData.code != _lastScannedLink) {
        setState(() {
          scannedLink = scanData.code!;
          _lastScannedLink = scannedLink;
          _showButton = true;
        });
        if (scannedLink != _lastNotifiedLink) {
          _showNewQRScannedNotification();
          _lastNotifiedLink = scannedLink;
        }
      }
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

  void _showNewQRScannedNotification() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.qr_code, color: Colors.white),
            SizedBox(width: 16),
            Text(
              _getTranslatedText('new_qr_detected'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  void _onQRError(QRViewController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getTranslatedText('invalid_qr_or_link'))),
    );
  }

  String _getTranslatedText(String key) {
    final translations = {
      'es': {
        'wait_camera_initialization': 'Espera a que se inicialice la cámara',
        'place_qr_code_within_frame': 'Coloca el código QR dentro del marco',
        'open_link': 'ABRIR ENLACE',
        'scan_qr_code': 'Escanea un código QR',
        'camera_permission_required': 'Permiso de cámara requerido',
        'camera_permission_description':
            'Para escanear códigos QR, necesitas permitir el acceso a la cámara en los ajustes de la aplicación.',
        'enable_camera': 'Activar cámara',
        'permission_denied': 'Permiso denegado',
        'permission_denied_description':
            'Sin acceso a la cámara no podrás escanear códigos QR. Por favor, activa el permiso en los ajustes de la aplicación.',
        'cancel': 'Cancelar',
        'open_settings': 'Abrir ajustes',
        'invalid_qr_or_link': 'QR inválido o enlace no válido',
        'new_qr_detected': '¡Nuevo QR detectado!',
      },
      'en': {
        'wait_camera_initialization': 'Wait for the camera to initialize',
        'place_qr_code_within_frame': 'Place the QR code within the frame',
        'open_link': 'OPEN LINK',
        'scan_qr_code': 'Scan a QR code',
        'camera_permission_required': 'Camera permission required',
        'camera_permission_description':
            'To scan QR codes, you need to allow camera access in the app settings.',
        'enable_camera': 'Enable camera',
        'permission_denied': 'Permission denied',
        'permission_denied_description':
            'Without camera access, you will not be able to scan QR codes. Please enable the permission in the app settings.',
        'cancel': 'Cancel',
        'open_settings': 'Open settings',
        'invalid_qr_or_link': 'Invalid QR or link',
        'new_qr_detected': 'New QR detected!',
      },
      'ca': {
        'wait_camera_initialization': 'Espera que s\'inicialitzi la càmera',
        'place_qr_code_within_frame': 'Col·loca el codi QR dins del marc',
        'open_link': 'OBRIR ENLLAÇ',
        'scan_qr_code': 'Escaneja un codi QR',
        'camera_permission_required': 'Es requereix permís de càmera',
        'camera_permission_description':
            'Per escanejar codis QR, has de permetre l\'accés a la càmera a la configuració de l\'aplicació.',
        'enable_camera': 'Activa la càmera',
        'permission_denied': 'Permís denegat',
        'permission_denied_description':
            'Sense accés a la càmera no podràs escanejar codis QR. Si us plau, activa el permís a la configuració de l\'aplicació.',
        'cancel': 'Cancel·lar',
        'open_settings': 'Obrir configuració',
        'invalid_qr_or_link': 'QR o enllaç no vàlid',
        'new_qr_detected': 'S\'ha detectat un nou QR!',
      },
      'de': {
        'wait_camera_initialization':
            'Warten Sie, bis die Kamera initialisiert ist',
        'place_qr_code_within_frame':
            'Platzieren Sie den QR-Code innerhalb des Rahmens',
        'open_link': 'LINK ÖFFNEN',
        'scan_qr_code': 'QR-Code scannen',
        'camera_permission_required': 'Kameraerlaubnis erforderlich',
        'camera_permission_description':
            'Um QR-Codes zu scannen, müssen Sie den Kamerazugriff in den App-Einstellungen zulassen.',
        'enable_camera': 'Kamera aktivieren',
        'permission_denied': 'Erlaubnis verweigert',
        'permission_denied_description':
            'Ohne Kamerazugriff können Sie keine QR-Codes scannen. Bitte aktivieren Sie die Berechtigung in den App-Einstellungen.',
        'cancel': 'Abbrechen',
        'open_settings': 'Einstellungen öffnen',
        'invalid_qr_or_link': 'Ungültiger QR-Code oder Link',
        'new_qr_detected': 'Neuer QR-Code erkannt!',
      },
      'fr': {
        'wait_camera_initialization': 'Attendez que la caméra s\'initialise',
        'place_qr_code_within_frame': 'Placez le code QR dans le cadre',
        'open_link': 'OUVRIR LE LIEN',
        'scan_qr_code': 'Scanner un code QR',
        'camera_permission_required': 'Permission de caméra requise',
        'camera_permission_description':
            'Pour scanner des codes QR, vous devez autoriser l\'accès à la caméra dans les paramètres de l\'application.',
        'enable_camera': 'Activer la caméra',
        'permission_denied': 'Permission refusée',
        'permission_denied_description':
            'Sans accès à la caméra, vous ne pourrez pas scanner de codes QR. Veuillez activer l\'autorisation dans les paramètres de l\'application.',
        'cancel': 'Annuler',
        'open_settings': 'Ouvrir les paramètres',
        'invalid_qr_or_link': 'QR ou lien invalide',
        'new_qr_detected': 'Nouveau QR détecté !',
      },
    };

    return translations[_currentLanguage]?[key] ?? key;
  }

  void _subscribeToLanguageChanges() {
    _languageSubscription = ApiService().languageStream.listen((language) {
      //print('Language changed: $language');
      setState(() {
        _currentLanguage = language;
        _selectedLanguage = language.toUpperCase();
      });
      _refreshTexts();
    });
  }

  void _updateTexts() {
    print('Updating texts for language: $_currentLanguage');
    _openLinkText = _getTranslatedText('open_link');
    _placeQRCodeText = _getTranslatedText('place_qr_code_within_frame');
    _scanQRCodeText = _getTranslatedText('scan_qr_code');
    //print('Updated texts:');
    //print('  _openLinkText: $_openLinkText');
    //print('  _placeQRCodeText: $_placeQRCodeText');
    //print('  _scanQRCodeText: $_scanQRCodeText');
  }

  void _refreshTexts() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _updateTexts();
        });

        if (_cameraPermissionGranted && _isQRInitialized) {
          _reloadPage();
        }
      }
    });
  }

  void _reloadPage() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => CameraPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    });
  }

  void _startLanguageTimer() {
    _languageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkLanguage();
    });
  }

  Future<void> _checkLanguage() async {
    final apiService = ApiService();
    final language = await apiService.getCurrentLanguage();
    if (language != _currentLanguage) {
      setState(() {
        _currentLanguage = language;
        _selectedLanguage = language.toUpperCase();
      });
      _updateTexts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isQRInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(_getTranslatedText('wait_camera_initialization'))),
          );
          return false;
        }
        return true;
      },
      child: AppScaffold(
        body: Column(
          children: [
            // Header específico para CameraPage
            Container(
              height: 60,
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo_felanitx.png',
                    height: 40,
                  ),
                  if (!_isLoadingLanguage)
                    DropdownButton<String>(
                      value: _currentLanguage.toUpperCase(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _handleLanguageChange(newValue.toLowerCase());
                        }
                      },
                      items: <String>['ES', 'EN', 'CA', 'DE', 'FR']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      underline: Container(),
                      icon: Icon(Icons.arrow_drop_down),
                    ),
                  if (_isLoadingLanguage) SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _isCheckingPermission
                  ? _buildLoadingIndicator()
                  : _cameraPermissionGranted
                      ? _buildQRScanner()
                      : _buildPermissionRequest(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Stack(
      children: <Widget>[
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
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) {
              return Text(
                _placeQRCodeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: _showButton
                ? ElevatedButton(
                    onPressed: _launchURL,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      elevation: 5,
                    ),
                    child: Builder(
                      builder: (context) {
                        return Text(
                          _openLinkText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          return Text(
                            _scanQRCodeText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _getTranslatedText('camera_permission_required'),
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getTranslatedText('camera_permission_description'),
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
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    _getTranslatedText('enable_camera'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
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
        _lastNotifiedLink = ''; // Reset the last notified link
      });
    } else {
      throw 'Could not launch $scannedLink';
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_getTranslatedText('permission_denied')),
        content: Text(_getTranslatedText('permission_denied_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(_getTranslatedText('open_settings')),
          ),
        ],
      ),
    );
  }

  bool isQRInitialized() {
    return _isQRInitialized;
  }

  // Añadir el método para manejar el cambio de idioma
  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      final apiService = ApiService();
      await apiService.setLanguage(language);

      setState(() {
        _currentLanguage = language;
      });

      _updateTexts();
    }
  }
}
