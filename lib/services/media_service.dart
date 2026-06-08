import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaService extends ChangeNotifier {
  bool _cameraGranted = false;
  bool _storageGranted = false;
  bool _microphoneGranted = false;
  bool _photosGranted = false;
  bool _isLoading = false;

  bool get cameraGranted => _cameraGranted;
  bool get storageGranted => _storageGranted;
  bool get microphoneGranted => _microphoneGranted;
  bool get photosGranted => _photosGranted;
  bool get isLoading => _isLoading;
  bool get allMediaGranted => _cameraGranted && _storageGranted && _microphoneGranted && _photosGranted;

  Future<Map<String, bool>> requestAllMedia() async {
    _isLoading = true;
    notifyListeners();

    final camera = await Permission.camera.request();
    final storage = await Permission.storage.request();
    final microphone = await Permission.microphone.request();
    final photos = await Permission.photos.request();

    _cameraGranted = camera.isGranted;
    _storageGranted = storage.isGranted;
    _microphoneGranted = microphone.isGranted;
    _photosGranted = photos.isGranted;

    _isLoading = false;
    notifyListeners();

    return {
      'camera': _cameraGranted,
      'storage': _storageGranted,
      'microphone': _microphoneGranted,
      'photos': _photosGranted,
    };
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    _cameraGranted = status.isGranted;
    notifyListeners();
    return _cameraGranted;
  }

  Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    _storageGranted = status.isGranted;
    notifyListeners();
    return _storageGranted;
  }

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    _microphoneGranted = status.isGranted;
    notifyListeners();
    return _microphoneGranted;
  }

  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    _photosGranted = status.isGranted;
    notifyListeners();
    return _photosGranted;
  }
}
