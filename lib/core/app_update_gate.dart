import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  bool _checking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  List<int> _versionParts(String value) {
    return value
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  bool _isOlder(String current, String target) {
    final currentParts = _versionParts(current);
    final targetParts = _versionParts(target);
    final length = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < length; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final targetPart = i < targetParts.length ? targetParts[i] : 0;
      if (currentPart != targetPart) return currentPart < targetPart;
    }
    return false;
  }

  Future<void> _checkForUpdate() async {
    if (_checking || _dialogVisible || kIsWeb || !Platform.isAndroid) return;
    _checking = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final release = await Supabase.instance.client
          .from('app_releases')
          .select()
          .eq('platform', 'android')
          .maybeSingle();

      if (release == null || !mounted) return;

      final latestVersion = (release['latest_version'] ?? '').toString();
      final minimumVersion = (release['minimum_version'] ?? '').toString();
      final downloadUrl = (release['download_url'] ?? '').toString();
      final releaseNotes = (release['release_notes'] ?? '').toString();
      final forceUpdate = release['force_update'] == true;

      final belowMinimum =
          minimumVersion.isNotEmpty &&
          _isOlder(packageInfo.version, minimumVersion);
      final belowLatest =
          latestVersion.isNotEmpty &&
          _isOlder(packageInfo.version, latestVersion);
      final mustUpdate = belowMinimum || (forceUpdate && belowLatest);

      if (!belowLatest || downloadUrl.isEmpty || !mounted) return;

      _dialogVisible = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: !mustUpdate,
        builder: (dialogContext) {
          return PopScope(
            canPop: !mustUpdate,
            child: AlertDialog(
              icon: const Icon(Icons.system_update_alt),
              title: const Text('Actualización disponible'),
              content: Text(
                'Hay una nueva versión de CBVSA Inspecciones '
                '($latestVersion).\n\n'
                '${releaseNotes.isEmpty ? 'Actualiza para continuar usando la aplicación.' : releaseNotes}',
              ),
              actions: [
                if (!mustUpdate)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Más tarde'),
                  ),
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(downloadUrl);
                    if (uri == null ||
                        !await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No fue posible abrir la descarga oficial.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Actualizar aplicación'),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      debugPrint('No fue posible comprobar actualizaciones: $error');
    } finally {
      _checking = false;
      _dialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
