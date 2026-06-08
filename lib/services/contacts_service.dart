import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactInfo {
  final String name;
  final String? phone;
  final String? email;

  ContactInfo({required this.name, this.phone, this.email});
}

class ContactsService extends ChangeNotifier {
  List<ContactInfo> _contacts = [];
  bool _hasPermission = false;
  bool _isLoading = false;

  List<ContactInfo> get contacts => _contacts;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;

  Future<bool> requestPermission() async {
    _isLoading = true;
    notifyListeners();

    final status = await Permission.contacts.request();
    _hasPermission = status.isGranted;

    if (_hasPermission) {
      _contacts = _mockContacts();
    }

    _isLoading = false;
    notifyListeners();
    return _hasPermission;
  }

  List<ContactInfo> _mockContacts() {
    return [
      ContactInfo(name: 'Sarah Johnson', phone: '+1 (555) 123-4567', email: 'sarah@email.com'),
      ContactInfo(name: 'Mike Chen', phone: '+1 (555) 234-5678', email: 'mike@email.com'),
      ContactInfo(name: 'Emma Wilson', phone: '+1 (555) 345-6789', email: 'emma@email.com'),
      ContactInfo(name: 'James Brown', phone: '+1 (555) 456-7890', email: 'james@email.com'),
      ContactInfo(name: 'Lisa Garcia', phone: '+1 (555) 567-8901', email: 'lisa@email.com'),
      ContactInfo(name: 'Alex Turner', phone: '+1 (555) 678-9012', email: 'alex@email.com'),
      ContactInfo(name: 'Rachel Kim', phone: '+1 (555) 789-0123', email: 'rachel@email.com'),
      ContactInfo(name: 'David Miller', phone: '+1 (555) 890-1234', email: 'david@email.com'),
    ];
  }
}
