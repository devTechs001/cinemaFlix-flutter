import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('newer patch/minor/major are updates', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('equal or older versions are not updates', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
    });

    test('compares numerically, not lexicographically', () {
      expect(UpdateService.isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.9.0', '1.10.0'), isFalse);
    });

    test('handles missing segments and build suffixes', () {
      expect(UpdateService.isNewerVersion('1.1', '1.0.5'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.1.0+2', '1.0.0+9'), isTrue);
    });
  });
}
