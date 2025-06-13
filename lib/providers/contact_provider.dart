import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  List<Contact> get contacts => _contacts;
  List<Contact> get filteredContacts => _filteredContacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;

  Future<void> initializeContacts() async {
    if (_contacts.isNotEmpty) return;

    final permission = await Permission.contacts.request();
    _hasPermission = permission.isGranted;
    notifyListeners();

    if (permission.isGranted) {
      try {
        final contactsList = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
          withAccounts: true,
        );
        _contacts = contactsList;
        _filteredContacts = contactsList;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        rethrow;
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshContacts() async {
    if (!_hasPermission) {
      final permission = await Permission.contacts.request();
      _hasPermission = permission.isGranted;
      if (!permission.isGranted) return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final contactsList = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
        withAccounts: true,
      );
      _contacts = contactsList;
      _filteredContacts = contactsList;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void filterContacts(String query) {
    _filteredContacts = _contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number.toLowerCase()
          : '';
      final searchLower = query.toLowerCase();
      return name.contains(searchLower) || phone.contains(searchLower);
    }).toList();
    notifyListeners();
  }

  Future<void> deleteContact(Contact contact) async {
    try {
      await contact.delete();
      _contacts.remove(contact);
      _filteredContacts.remove(contact);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
