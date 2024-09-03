import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _bluetoothEnabled = false;
  bool _qrScanningEnabled = false;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _checkCameraPermission();
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
      body: ListView(
        children: [
          _buildSectionTitle('NOTIFICACIONES'),
          _buildSwitchTile(
            'Habilitar Notificaciones',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSectionTitle('BLUETOOTH'),
          _buildBluetoothTile(
            'Bluetooth para Beacons',
            _bluetoothEnabled,
          ),
          _buildSectionTitle('ESCANEO DE CÓDIGO QR'),
          _buildPermissionTile(
            'Escaneo de Código QR',
            _qrScanningEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      subtitle: value ? Text('Habilitado') : null,
    );
  }

  Widget _buildPermissionTile(String title, bool value) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        value ? Icons.check : Icons.close,
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
        color: value ? Colors.green : Colors.red,
      ),
      subtitle: Text(value ? 'Activado' : 'Desactivado'),
      onTap: _openBluetoothSettings,
    );
  }
}
