import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';
import '../pages/home_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _bluetoothEnabled = false;
  bool _qrScanningEnabled = false;
  String _currentLanguage = 'ca';

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _checkCameraPermission();
    _loadCurrentLanguage();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {
          _bluetoothEnabled = state == BluetoothAdapterState.on;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadCurrentLanguage(); // Recargar el idioma cuando la página se muestra
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      _adapterState = await FlutterBluePlus.adapterState.first;
      setState(() {
        _bluetoothEnabled = _adapterState == BluetoothAdapterState.on;
      });
    } catch (e) {
      print('Error al obtener el estado del Bluetooth: $e');
      setState(() {
        _bluetoothEnabled = false;
      });
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _qrScanningEnabled = status.isGranted;
    });
  }

  void _toggleBluetooth() async {
    if (!_bluetoothEnabled) {
      _showBluetoothDisabledDialog();
    } else {
      // TODO: Implementar lógica para desconectar beacons si es necesario
      setState(() {
        _bluetoothEnabled = false;
      });
    }
  }

  void _showBluetoothDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Bluetooth desactivado'),
        content: const Text(
            'Para conectarse a los beacons, necesitas activar el Bluetooth en los ajustes del dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
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

  void _toggleQRScanning(bool value) async {
    if (value) {
      final status = await Permission.camera.request();
      if (status == PermissionStatus.granted) {
        // TODO: Abrir cámara para escaneo QR
      } else {
        setState(() {
          _qrScanningEnabled = false;
        });
        _showPermissionDeniedDialog();
      }
    } else {
      setState(() {
        _qrScanningEnabled = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de cámara requerido'),
        content: const Text(
            'Para escanear códigos QR, necesitas permitir el acceso a la cámara en los ajustes de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
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

  void _openBluetoothSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header específico para SettingsPage
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
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  _buildSectionTitle('NOTIFICACIONES'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: _buildSwitchTile(
                      'Habilitar Notificaciones',
                      _notificationsEnabled,
                      (value) => setState(() => _notificationsEnabled = value),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle('BLUETOOTH'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: _buildBluetoothTile(
                      'Bluetooth para Beacons',
                      _bluetoothEnabled,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle('ESCANEO DE CÓDIGO QR'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: _buildPermissionTile(
                      'Escaneo de Código QR',
                      _qrScanningEnabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildPermissionTile(String title, bool value) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value ? Colors.green : Colors.red,
      ),
      onTap: () {
        openAppSettings();
      },
    );
  }

  Widget _buildBluetoothTile(String title, bool value) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        value ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
        color: value ? Colors.blue : Colors.grey,
      ),
      onTap: _openBluetoothSettings,
    );
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final apiService = ApiService();
      final language = await apiService.getCurrentLanguage();
      if (mounted) {
        setState(() {
          _currentLanguage = language;
        });
      }
    } catch (e) {
      print('Error loading current language: $e');
    }
  }

  Future<void> _handleLanguageChange(String language) async {
    if (_currentLanguage != language) {
      final apiService = ApiService();
      await apiService.setLanguage(language);

      setState(() {
        _currentLanguage = language;
      });

      // Notificar a HomePage del cambio
      if (mounted) {
        final homePage = HomePage.of(context);
        homePage?.reloadData();
      }
    }
  }
}
