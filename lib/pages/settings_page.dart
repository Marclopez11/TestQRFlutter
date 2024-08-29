import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _bluetoothEnabled = false;
  bool _qrScanningEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('NOTIFICATIONS'),
          _buildSwitchTile(
            'Enable Notifications',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSectionTitle('BLUETOOTH'),
          _buildSwitchTile(
            'Enable Bluetooth for Beacons',
            _bluetoothEnabled,
            (value) => setState(() => _bluetoothEnabled = value),
          ),
          _buildSectionTitle('QR CODE SCANNING'),
          _buildSwitchTile(
            'Enable QR Code Scanning',
            _qrScanningEnabled,
            (value) => setState(() => _qrScanningEnabled = value),
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
    );
  }
}
