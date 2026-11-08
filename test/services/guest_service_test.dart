import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/services/guest_service.dart';

void main() {
  group('GuestService', () {
    late GuestService guestService;

    setUp(() {
      guestService = GuestService();
    });

    test('initial state is not guest', () {
      expect(guestService.isGuest, false);
    });

    test('guestId is empty by default', () {
      expect(guestService.guestId, '');
    });

    test('startGuestSession sets isGuest to true', () {
      guestService.startGuestSession();
      expect(guestService.isGuest, true);
    });

    test('startGuestSession creates a non-empty guestId', () {
      guestService.startGuestSession();
      expect(guestService.guestId.length, greaterThan(0));
    });

    test('startGuestSession sets restrictions', () {
      guestService.startGuestSession();
      expect(guestService.canReview, false);
      expect(guestService.canChat, false);
      expect(guestService.canDownload, false);
      expect(guestService.isHD, false);
      expect(guestService.canWatch, true);
      expect(guestService.canBrowse, true);
    });

    test('upgradeToFull clears guest state', () async {
      guestService.startGuestSession();
      await guestService.upgradeToFull();
      expect(guestService.isGuest, false);
      expect(guestService.guestId, '');
    });

    test('endGuestSession clears guest state', () {
      guestService.startGuestSession();
      guestService.endGuestSession();
      expect(guestService.isGuest, false);
    });

    test('incrementViews adds restriction after 5 views', () {
      guestService.startGuestSession();
      expect(guestService.canWatch, true);

      for (int i = 0; i < 5; i++) {
        guestService.incrementViews();
      }

      expect(guestService.canWatch, false);
    });
  });
}
