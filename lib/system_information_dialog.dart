import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phone_info/phone_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:share_plus/share_plus.dart';

// Add this import for your custom phone info plugin
import 'memo/base/memo_bitcoin_base.dart';
import 'memo/model/memo_model_creator.dart';

// System Information Dialog
class SystemInformationDialog extends ConsumerStatefulWidget {
  const SystemInformationDialog({super.key});

  @override
  ConsumerState<SystemInformationDialog> createState() => _SystemInformationDialogState();
}

class _SystemInformationDialogState extends ConsumerState<SystemInformationDialog> {
  final Map<String, int> _urlExpectedSizes = {
    'https://mahakka-apk.vercel.app/version.txt': 157, // TODO: Get actual size
    'https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74': 171, // TODO: Get actual size
    'https://memo.cash/topics/all': 437, // TODO: Get actual size
    MemoBitcoinBase.cauldronSwapTokenUrl: 1800, // TODO: Get actual size
    MemoBitcoinBase.cashonizeUrl: 902, // TODO: Get actual size
    MemoBitcoinBase.explorerUrl: 756, // TODO: Get actual size
  };

  final Map<String, String> _pingResults = {};
  final Map<String, String> _bandwidthResults = {};
  bool _isTesting = false;
  String _systemInfo = '';
  LocationData? _locationData;
  Map<String, dynamic>? _phoneInfo;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startTesting();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = Location();

      // Check current permission status
      PermissionStatus permissionStatus = await location.hasPermission();

      if (permissionStatus == PermissionStatus.denied || permissionStatus == PermissionStatus.deniedForever) {
        // Request permission if not granted
        permissionStatus = await location.requestPermission();

        if (permissionStatus != PermissionStatus.granted && permissionStatus != PermissionStatus.grantedLimited) {
          if (kDebugMode) {
            print('Location permission not granted: $permissionStatus');
          }
          return;
        }
      }

      // Only get location if permission is granted
      if (permissionStatus == PermissionStatus.granted || permissionStatus == PermissionStatus.grantedLimited) {
        _locationData = await location.getLocation();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location: $e');
      }
    }
  }

  void _startTesting() async {
    setState(() => _isTesting = true);
    await _testAllUrls();
    await _generateSystemInfo();
    setState(() => _isTesting = false);
  }

  Future<void> _testAllUrls() async {
    for (final url in _urlExpectedSizes.keys) {
      try {
        await _testUrl(url);
      } catch (e) {
        _pingResults[url] = 'Error: ${e.toString()}';
        _bandwidthResults[url] = 'Error';
      }
    }
  }

  Future<void> _testUrl(String url) async {
    final stopwatch = Stopwatch()..start();
    int downloadedBytes = 0;

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      // Count bytes during download
      await for (final chunk in response) {
        downloadedBytes += chunk.length;
      }

      stopwatch.stop();

      final ping = '${stopwatch.elapsedMilliseconds}ms';
      setState(() {
        _pingResults[url] = ping;
      });

      final bandwidth = await _measureBandwidthAccurate(url);

      if (kDebugMode) {
        print('URL: $url');
        print('  Ping: $ping');
        print('  Downloaded: $downloadedBytes bytes');
        print('  Expected: ${_urlExpectedSizes[url]} bytes');
        print('  Bandwidth: $bandwidth');
      }

      setState(() {
        _bandwidthResults[url] = bandwidth;
      });

      client.close();
    } catch (e) {
      if (kDebugMode) {
        print('URL test failed for $url: $e');
      }
      setState(() {
        _pingResults[url] = 'Unreachable';
        _bandwidthResults[url] = 'N/A';
      });
    }
  }

  Future<String> _measureBandwidthAccurate(String url) async {
    const numTests = 2; // Increased for better accuracy
    final results = <double>[];

    for (int i = 0; i < numTests; i++) {
      try {
        final bandwidth = await _singleBandwidthTest(url);
        if (bandwidth > 0) {
          results.add(bandwidth);
          if (kDebugMode) {
            print('Bandwidth test $i for $url: ${_formatBandwidth(bandwidth)}');
          }
        }
        // Longer delay between tests
        if (i < numTests - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Bandwidth test $i failed for $url: $e');
        }
        // Continue with next test
      }
    }

    if (results.isEmpty) return 'N/A';

    // Use median for more stable results (outlier resistant)
    results.sort();
    final medianBps = results[results.length ~/ 2];

    if (kDebugMode) {
      print('Final median bandwidth for $url: ${_formatBandwidth(medianBps)}');
    }

    return _formatBandwidth(medianBps);
  }

  Future<double> _singleBandwidthTest(String url) async {
    final stopwatch = Stopwatch()..start();
    int totalBytes = 0;

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));

      // Prevent caching for accurate measurement
      request.headers.add('Cache-Control', 'no-cache');
      request.headers.add('Pragma', 'no-cache');

      final response = await request.close();

      // Count all bytes received
      await for (final chunk in response) {
        totalBytes += chunk.length;
      }

      stopwatch.stop();
      final elapsedMillis = stopwatch.elapsedMilliseconds;

      // Use ACTUAL downloaded bytes for bandwidth calculation
      // This gives real throughput measurement
      return elapsedMillis > 0 ? totalBytes * 1024 * 1024 / elapsedMillis : 0;
    } finally {
      client.close();
    }
  }

  String _formatBandwidth(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return 'N/A';

    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    double value = bytesPerSecond;
    int unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    return '${value.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  Future<void> _generateSystemInfo() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('=== MAHAKKA SYSTEM REPORT ===');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln();

      appendUrlConnectivity(buffer);
      await appendAppInfo(buffer);
      appendABI(buffer);
      await appendDeviceInfo(buffer);
      await appendLocationInfo(buffer);
      appendBalanceInfo(buffer);
      appendTierInfo(buffer);
      await appendNetworkInfo(buffer);
      setState(() {
        _systemInfo = buffer.toString();
      });

      if (kDebugMode) {
        print(_systemInfo);
      }
    } catch (e) {
      setState(() {
        _systemInfo = 'Error generating system info: ${e.toString()}';
      });
    }
  }

  void appendUrlConnectivity(StringBuffer buffer) {
    buffer.writeln('=== URL CONNECTIVITY ===');
    for (final url in _urlExpectedSizes.keys) {
      buffer.writeln('URL: $url');
      buffer.writeln('  Ping: ${_pingResults[url] ?? "Testing..."}');
      buffer.writeln('  Bandwidth: ${_bandwidthResults[url] ?? "Testing..."}');
      buffer.writeln();
      setState(() {
        _systemInfo = buffer.toString();
      });
    }
  }

  Future<void> appendAppInfo(StringBuffer buffer) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      buffer.writeln('=== APP INFORMATION ===');
      buffer.writeln('App Name: ${packageInfo.appName}');
      buffer.writeln('Version: ${packageInfo.version}');
      buffer.writeln('Build: ${packageInfo.buildNumber}');
      buffer.writeln('Package: ${packageInfo.packageName}');
      buffer.writeln();
    } catch (e) {
      buffer.writeln('App Info: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  void appendABI(StringBuffer buffer) {
    try {
      final updateService = ref.read(updateServiceProvider);
      buffer.writeln('=== ABI INFORMATION ===');
      buffer.writeln('ABI: ${updateService.currentAbi}');
      buffer.writeln();
    } catch (e) {
      buffer.writeln('ABI Info: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  Future<void> appendDeviceInfo(StringBuffer buffer) async {
    try {
      _phoneInfo = await PhoneInfoPlugin.getPhoneInfo();
      buffer.writeln('=== DEVICE INFORMATION ===');
      buffer.writeln('Device: ${_phoneInfo?['deviceName'] ?? 'N/A'}');
      buffer.writeln('Manufacturer: ${_phoneInfo?['manufacturer'] ?? 'N/A'}');
      buffer.writeln('Model: ${_phoneInfo?['model'] ?? 'N/A'}');
      buffer.writeln('OS Version: ${_phoneInfo?['osVersion'] ?? 'N/A'}');
      buffer.writeln('Architecture: ${_phoneInfo?['architecture'] ?? 'N/A'}');
      buffer.writeln('Device ID: ${_phoneInfo?['deviceId'] ?? 'N/A'}');

      // Use battery_plus package for reliable battery info
      final battery = Battery();
      try {
        final batteryLevel = await battery.batteryLevel;
        final batteryStatus = await battery.batteryState;
        final isInSaveMode = await battery.isInBatterySaveMode;

        buffer.writeln('Battery Level: $batteryLevel%');
        buffer.writeln('Battery Status: ${_formatBatteryStatus(batteryStatus)}');
        buffer.writeln('Battery Save Mode: $isInSaveMode');
      } catch (e) {
        buffer.writeln('Battery Info: Error - ${e.toString()}');
      }

      buffer.writeln();
    } catch (e) {
      buffer.writeln('Device Info: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  String _formatBatteryStatus(BatteryState status) {
    switch (status) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.unknown:
      default:
        return 'Unknown';
    }
  }
  // Future<void> appendDeviceInfo(StringBuffer buffer) async {
  //   try {
  //     _phoneInfo = await PhoneInfoPlugin.getPhoneInfo();
  //     buffer.writeln('=== DEVICE INFORMATION ===');
  //     buffer.writeln('Device: ${_phoneInfo?['deviceName'] ?? 'N/A'}');
  //     buffer.writeln('Manufacturer: ${_phoneInfo?['manufacturer'] ?? 'N/A'}');
  //     buffer.writeln('Model: ${_phoneInfo?['model'] ?? 'N/A'}');
  //     buffer.writeln('OS Version: ${_phoneInfo?['osVersion'] ?? 'N/A'}');
  //     buffer.writeln('Architecture: ${_phoneInfo?['architecture'] ?? 'N/A'}');
  //     buffer.writeln('Device ID: ${_phoneInfo?['deviceId'] ?? 'N/A'}');
  //
  //     // Battery info
  //     final batteryInfo = await PhoneInfoPlugin.getBatteryInfo();
  //     buffer.writeln('Battery Level: ${batteryInfo['level'] ?? 'N/A'}%');
  //     buffer.writeln('Battery Status: ${batteryInfo['status'] ?? 'N/A'}');
  //     buffer.writeln();
  //   } catch (e) {
  //     buffer.writeln('Device Info: Error - ${e.toString()}');
  //     buffer.writeln();
  //   }
  // }

  Future<void> appendLocationInfo(StringBuffer buffer) async {
    try {
      // final location = Location();
      // var permission = location.hasPermission();
      if (_locationData != null) {
        // _locationData = await location.getLocation();
        buffer.writeln('=== LOCATION INFORMATION ===');
        buffer.writeln('Latitude: ${_locationData?.latitude ?? 'N/A'}');
        buffer.writeln('Longitude: ${_locationData?.longitude ?? 'N/A'}');
        buffer.writeln('Accuracy: ${_locationData?.accuracy ?? 'N/A'}m');
        buffer.writeln();
      } else {
        buffer.writeln('Location: Permission not granted');
        buffer.writeln();
      }
    } catch (e) {
      buffer.writeln('Location: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  void appendBalanceInfo(StringBuffer buffer) {
    try {
      final creator = ref.read(getCreatorProvider('current')).value;
      final token = _getBalanceText(true, creator);
      final memo = _getBalanceText(false, creator);
      buffer.writeln('=== BALANCE INFORMATION ===');
      buffer.writeln(memo);
      buffer.writeln(token);
      buffer.writeln();
    } catch (e) {
      buffer.writeln('Balance: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  Future<void> appendNetworkInfo(StringBuffer buffer) async {
    try {
      final connectivity = Connectivity();
      final connectivityResults = await connectivity.checkConnectivity();

      buffer.writeln('=== NETWORK INFORMATION ===');

      // Check if any connectivity exists (excluding 'none')
      final isConnected = connectivityResults.any((result) => result != ConnectivityResult.none);
      buffer.writeln('Is Connected: $isConnected');

      if (isConnected) {
        // Get all active connection types
        final activeTypes = connectivityResults.where((result) => result != ConnectivityResult.none).map((result) => result.name).join(', ');
        buffer.writeln('Active Connections: $activeTypes');
      } else {
        buffer.writeln('Connection Type: No connectivity');
      }
    } catch (e) {
      buffer.writeln('Network Info: Error - ${e.toString()}');
    }
  }

  // Future<void> appendNetworkInfo(StringBuffer buffer) async {
  //   try {
  //     final connectivity = Connectivity();
  //     final connectivityResults = await connectivity.checkConnectivity();
  //
  //     buffer.writeln('=== NETWORK INFORMATION ===');
  //
  //     // Handle multiple connectivity types (device can be connected to multiple networks)
  //     if (connectivityResults.isEmpty || connectivityResults.contains(ConnectivityResult.none)) {
  //       buffer.writeln('Connection Type: No connectivity');
  //       buffer.writeln('Is Connected: false');
  //     } else {
  //       // Get the primary connection type (excluding none)
  //       final activeConnections = connectivityResults.where((result) => result != ConnectivityResult.none).toList();
  //
  //       if (activeConnections.isNotEmpty) {
  //         // Format the connection types
  //         final connectionTypes = activeConnections.map((result) => _formatConnectivityResult(result)).join(', ');
  //         buffer.writeln('Connection Type: $connectionTypes');
  //         buffer.writeln('Is Connected: true');
  //
  //         // Show detailed info for each connection type
  //         for (final connection in activeConnections) {
  //           buffer.writeln('  - ${_formatConnectivityResult(connection)}');
  //         }
  //       } else {
  //         buffer.writeln('Connection Type: No connectivity');
  //         buffer.writeln('Is Connected: false');
  //       }
  //     }
  //   } catch (e) {
  //     buffer.writeln('Network Info: Error - ${e.toString()}');
  //   }
  // }
  //
  // String _formatConnectivityResult(ConnectivityResult result) {
  //   switch (result) {
  //     case ConnectivityResult.bluetooth:
  //       return 'Bluetooth';
  //     case ConnectivityResult.wifi:
  //       return 'WiFi';
  //     case ConnectivityResult.ethernet:
  //       return 'Ethernet';
  //     case ConnectivityResult.mobile:
  //       return 'Mobile Data';
  //     case ConnectivityResult.vpn:
  //       return 'VPN';
  //     case ConnectivityResult.other:
  //       return 'Other';
  //     case ConnectivityResult.none:
  //       return 'None';
  //   }
  // }

  // Future<void> appendNetworkInfo(StringBuffer buffer) async {
  //   try {
  //     // Check and request permission first
  //     final phoneStatus = await Permission.phone.status;
  //     if (!phoneStatus.isGranted) {
  //       final result = await Permission.phone.request();
  //       if (!result.isGranted) {
  //         buffer.writeln('=== NETWORK INFORMATION ===');
  //         buffer.writeln('Permission denied for network info');
  //         return;
  //       }
  //     }
  //
  //     final networkInfo = await PhoneInfoPlugin.getNetworkInfo();
  //     buffer.writeln('=== NETWORK INFORMATION ===');
  //     buffer.writeln('Connection Type: ${networkInfo['connectionType'] ?? 'N/A'}');
  //     buffer.writeln('Network Operator: ${networkInfo['networkOperator'] ?? 'N/A'}');
  //     buffer.writeln('Signal Strength: ${networkInfo['signalStrength'] ?? 'N/A'} dBm');
  //     buffer.writeln('Is Connected: ${await PhoneInfoPlugin.getIsConnected()}');
  //   } catch (e) {
  //     buffer.writeln('Network Info: Error - ${e.toString()}');
  //   }
  // }

  void appendTierInfo(StringBuffer buffer) {
    try {
      final tier = ref.read(currentTokenLimitEnumProvider);
      buffer.writeln('=== TIER INFORMATION ===');
      buffer.writeln('Current Tier: ${tier.name}');
      buffer.writeln();
    } catch (e) {
      buffer.writeln('Tier: Error - ${e.toString()}');
      buffer.writeln();
    }
  }

  String _getBalanceText(bool isCashtokenTab, MemoModelCreator? creator) {
    try {
      if (isCashtokenTab) {
        final bch = creator?.balanceBch ?? 0;
        final token = creator?.balanceToken ?? 0;
        return 'BCH: ${_formatBalance(bch)} sats\n${MemoBitcoinBase.tokenTicker}: ${_formatBalance(token)} units';
      } else {
        final balance = creator?.balanceMemo ?? 0;
        return 'MEMO: ${_formatBalance(balance)} sats';
      }
    } catch (e) {
      return 'Error retrieving balance: ${e.toString()}';
    }
  }

  String _formatBalance(int balance) {
    return balance.toString();
  }

  void _shareReport() {
    if (_systemInfo.isNotEmpty) {
      // Use the non-deprecated SharePlus method
      SharePlus.instance.share(ShareParams(text: _systemInfo, title: 'Mahakka System Report'));
      Sentry.captureMessage(_systemInfo, level: SentryLevel.info);
      Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage(_systemInfo),
          user: SentryUser(id: ref.read(userProvider)!.id),
        ),
      );
      print(_systemInfo);
    }
  }

  String getTranslation(String s) {
    return ref.watch(autoTranslationTextProvider(s)).value ?? s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    var s = getTranslation('System Report');
    var t = getTranslation('Testing connectivity...');
    var _connectivity = getTranslation('Connectivity');
    var r = getTranslation('Report Generated:');
    var speed = getTranslation('Speed');

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          children: [
            buildAnalysisHeader(colorScheme, s, textTheme),
            Expanded(
              child: _isTesting && _pingResults.isEmpty
                  ? buildLoadingWidget(colorScheme, t, textTheme)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // URL Status List
                          Text('URL $_connectivity:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          buildListPingBandwidthResults(textTheme, speed),
                          const SizedBox(height: 16),

                          // System Info Preview
                          if (_systemInfo.isNotEmpty) ...[
                            Text(r, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 2,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                                child: SingleChildScrollView(child: Text(_systemInfo, style: textTheme.bodySmall)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            buildAnalysisActions(context),
          ],
        ),
      ),
    );
  }

  Padding buildAnalysisActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            IconAction(text: 'Close', onTap: () => Navigator.of(context).pop(), type: IAB.cancel, icon: Icons.close),
            const SizedBox(width: 1),
            IconAction(
              text: 'Send',
              onTap: _shareReport,
              type: IAB.success,
              icon: Icons.send,
              disabled: _systemInfo.isEmpty,
              disabledMessage: 'Please wait for report generation',
            ),
          ],
        ),
      ),
    );
  }

  Container buildAnalysisHeader(ColorScheme colorScheme, String s, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Center(
        child: Text(s, style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
      ),
    );
  }

  Expanded buildListPingBandwidthResults(TextTheme textTheme, String speed) {
    return Expanded(
      flex: 3,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _urlExpectedSizes.length,
        itemBuilder: (context, index) {
          final url = _urlExpectedSizes.keys.toList()[index];
          return Card(margin: const EdgeInsets.symmetric(vertical: 3), child: buildListTilePingBandwithResult(url, textTheme, speed));
        },
      ),
    );
  }

  ListTile buildListTilePingBandwithResult(String url, TextTheme textTheme, String speed) {
    return ListTile(
      minTileHeight: 36,
      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      dense: true,
      title: Text(_getDisplayUrl(url), style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Ping: ${_pingResults[url] ?? "Testing..."}'), Text(' - $speed: ${_bandwidthResults[url] ?? "Testing..."}')],
        ),
      ),
      trailing: _getStatusIcon(_pingResults[url]),
    );
  }

  Center buildLoadingWidget(ColorScheme colorScheme, String t, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(colorScheme.primary)),
          const SizedBox(height: 16),
          Text(t, style: textTheme.bodyLarge),
        ],
      ),
    );
  }

  String _getDisplayUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.host}${uri.path}';
  }

  Widget _getStatusIcon(String? pingResult) {
    if (pingResult == null) {
      return Icon(Icons.hourglass_empty, color: Colors.orange);
    } else if (pingResult.contains('Unreachable') || pingResult.contains('Error')) {
      return Icon(Icons.error, color: Colors.red);
    } else {
      return Icon(Icons.check_circle, color: Colors.green);
    }
  }
}

// Show Dialog Method
void showSystemInformationDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const SystemInformationDialog(), barrierDismissible: true);
}
