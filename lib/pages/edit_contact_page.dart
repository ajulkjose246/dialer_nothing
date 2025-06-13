import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class EditContactPage extends StatefulWidget {
  final Contact contact;

  const EditContactPage({super.key, required this.contact});

  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.displayName);
    _phoneController = TextEditingController(
      text: widget.contact.phones.isNotEmpty
          ? widget.contact.phones.first.number
          : '',
    );
    _emailController = TextEditingController(
      text: widget.contact.emails.isNotEmpty
          ? widget.contact.emails.first.address
          : '',
    );
    _addressController = TextEditingController(
      text: widget.contact.addresses.isNotEmpty
          ? widget.contact.addresses.first.address
          : '',
    );
    _notesController = TextEditingController(
      text: widget.contact.notes?.isNotEmpty ?? false
          ? widget.contact.notes!.first.note
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final contact = widget.contact;
      final newName = _nameController.text.trim();

      print('Updating contact name from: ${contact.displayName} to: $newName');

      // Update the contact using the recommended pattern
      contact.name.first = newName;
      contact.name.last = ''; // Clear last name to avoid conflicts

      // Update phone if provided
      if (_phoneController.text.trim().isNotEmpty) {
        contact.phones = [Phone(_phoneController.text.trim())];
      }

      // Update email - clear if empty
      if (_emailController.text.trim().isNotEmpty) {
        contact.emails = [Email(_emailController.text.trim())];
      } else {
        contact.emails = []; // Clear emails if empty
      }

      // Update address - clear if empty
      if (_addressController.text.trim().isNotEmpty) {
        contact.addresses = [Address(_addressController.text.trim())];
      } else {
        contact.addresses = []; // Clear addresses if empty
      }

      // Update notes - clear if empty
      if (_notesController.text.trim().isNotEmpty) {
        contact.notes = [Note(_notesController.text.trim())];
      } else {
        contact.notes = []; // Clear notes if empty
      }

      print('Saving contact with name: ${contact.name.first}');

      // Save the contact
      await contact.update();
      print('Contact update completed');

      // Add a small delay to ensure the contact is saved
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to get the updated contact multiple times
      Contact? freshContact;
      for (int i = 0; i < 3; i++) {
        try {
          freshContact = await FlutterContacts.getContact(
            contact.id,
            withProperties: true,
            withPhoto: true,
            withAccounts: true,
          );
          if (freshContact != null) {
            print('Successfully got updated contact on attempt ${i + 1}');
            print('Fresh contact name: ${freshContact.name.first}');
            break;
          }
        } catch (e) {
          print('Failed to get contact on attempt ${i + 1}: $e');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (freshContact != null) {
        print('Updated contact name: ${freshContact.name.first}');
        if (mounted) {
          Navigator.pop(context, freshContact);
        }
      } else {
        print('Failed to get updated contact after multiple attempts');
        // Return the modified contact if we can't get the updated one
        if (mounted) {
          Navigator.pop(context, contact);
        }
      }
    } catch (e) {
      print('Error updating contact: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(fontFamily: 'nothing'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Contact',
          style: TextStyle(fontFamily: 'nothing'),
        ),
        actions: [
          TextButton(
            onPressed: _saveContact,
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'nothing',
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Hero(
              tag: 'contact_${widget.contact.id}',
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: widget.contact.photo != null
                      ? ClipOval(
                          child: Image.memory(
                            widget.contact.photo!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.contact.displayName.isNotEmpty
                                ? widget.contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontFamily: 'nothing',
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontFamily: 'nothing'),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(fontFamily: 'nothing'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(fontFamily: 'nothing'),
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: const TextStyle(fontFamily: 'nothing'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(fontFamily: 'nothing'),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(fontFamily: 'nothing'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              style: const TextStyle(fontFamily: 'nothing'),
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: const TextStyle(fontFamily: 'nothing'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(fontFamily: 'nothing'),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: const TextStyle(fontFamily: 'nothing'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
