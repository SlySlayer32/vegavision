import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/core/services/connectivity_service.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  group('ConnectivityService Tests', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    test('should initialize with disconnected state', () {
      expect(connectivityService.isConnected, false);
    });

    // Add more connectivity service tests here
  });
}
