import 'dart:async';

import 'package:flutter_speed_test_plus/flutter_speed_test_plus.dart';

class PhoneSpeedTestResult {
  const PhoneSpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.sourceLabel,
  });

  final double downloadMbps;
  final double uploadMbps;
  final String sourceLabel;
}

class PhoneSpeedTestService {
  PhoneSpeedTestService({FlutterInternetSpeedTest? speedTest})
      : _speedTest = speedTest ?? FlutterInternetSpeedTest();

  final FlutterInternetSpeedTest _speedTest;

  Future<PhoneSpeedTestResult> runFastComCheck() {
    final completer = Completer<PhoneSpeedTestResult>();

    _speedTest.startTesting(
      useFastApi: true,
      onCompleted: (TestResult download, TestResult upload) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneSpeedTestResult(
              downloadMbps: _toMbps(download),
              uploadMbps: _toMbps(upload),
              sourceLabel: 'phone',
            ),
          );
        }
      },
      onError: (String errorMessage, String speedTestError) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('$errorMessage ($speedTestError)'),
          );
        }
      },
      onCancel: () {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Speed test cancelled'),
          );
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception('Phone speed test timed out'),
    );
  }

  double _toMbps(TestResult result) {
    switch (result.unit) {
      case SpeedUnit.kbps:
        return result.transferRate / 1000;
      case SpeedUnit.mbps:
        return result.transferRate;
    }
  }
}
