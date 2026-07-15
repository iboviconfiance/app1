import 'package:flutter_test/flutter_test.dart';
import 'package:klas_plus/config/constants.dart';

void main() {
  test('API base URL has default value', () {
    expect(AppConstants.apiBaseUrl, isNotEmpty);
    expect(AppConstants.apiBaseUrl, contains('/api'));
  });
}
