import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String updateCheckUrl = 'https://api.github.com/repos/amrahulsaini/jfapp/releases/latest';
  
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Fetch latest version from GitHub
      final response = await http.get(Uri.parse(updateCheckUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name']?.replaceAll('v', ''); // Remove 'v' prefix
        final downloadUrl = data['assets']?.firstWhere(
          (asset) => asset['name'].endsWith('.apk'),
          orElse: () => null,
        )?['browser_download_url'];
        
        if (latestVersion != null && _isNewerVersion(currentVersion, latestVersion)) {
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      print('Update check failed: $e');
    }
  }
  
  bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('-')[0].split('.').map(int.parse).toList();
      final latestParts = latest.split('-')[0].split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  void _showUpdateDialog(BuildContext context, String version, String? downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFF34C759)),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version $version is now available!'),
            SizedBox(height: 8),
            Text(
              'Update now to get the latest features and improvements.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (downloadUrl != null) {
                _launchUrl(downloadUrl);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF34C759),
            ),
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
