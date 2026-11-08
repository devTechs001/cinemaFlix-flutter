import 'package:flutter/foundation.dart';

import 'movie_service.dart';

/// Catalogue import manager (real-time).
///
/// Kicks off [MovieService.load] at startup: the app renders instantly
/// from the bundled catalogue, then imports rows from the Supabase
/// `movies` table and keeps them live through Realtime subscriptions —
/// edits made in the Supabase dashboard show up without a restart.
/// Any failure leaves the bundled catalogue in place.
class MovieDbService {
  Future<void> initialize() async {
    try {
      await movieService.load();
    } catch (e) {
      debugPrint('MovieDbService: catalogue import failed (bundled fallback active): $e');
    }
  }
}

final MovieDbService movieDbService = MovieDbService();
