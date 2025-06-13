import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class EditContactPage extends StatefulWidget {
  final Contact contact;

  const EditContactPage({super.key, required this.contact});

  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<TextEditingController> _phoneControllers;
  late List<TextEditingController> _emailControllers;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  Uint8List? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.displayName);

    // Initialize phone controllers
    _phoneControllers = widget.contact.phones.map((phone) {
      return TextEditingController(text: phone.number);
    }).toList();
    if (_phoneControllers.isEmpty) {
      _phoneControllers.add(TextEditingController());
    }

    // Initialize email controllers
    _emailControllers = widget.contact.emails.map((email) {
      return TextEditingController(text: email.address);
    }).toList();
    if (_emailControllers.isEmpty) {
      _emailControllers.add(TextEditingController());
    }

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
    _selectedPhoto = widget.contact.photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
    }
  }

  void _addEmailField() {
    setState(() {
      _emailControllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    if (_emailControllers.length > 1) {
      setState(() {
        _emailControllers[index].dispose();
        _emailControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedPhoto = bytes;
      });
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _selectedPhoto = null;
    });
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

      // Update photo if changed
      if (_selectedPhoto != widget.contact.photo) {
        contact.photo = _selectedPhoto;
      }

      // Update phones
      contact.phones = _phoneControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .map((number) => Phone(number))
          .toList();

      // Update emails
      contact.emails = _emailControllers
          .map((controller) => controller.text.trim())
          .where((email) => email.isNotEmpty)
          .map((email) => Email(email))
          .toList();

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
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                        child: _selectedPhoto != null
                            ? ClipOval(
                                child: Image.memory(
                                  _selectedPhoto!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  widget.contact.displayName.isNotEmpty
                                      ? widget.contact.displayName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontFamily: 'nothing',
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_selectedPhoto != null)
                      Positioned(
                        right: 0,
                        bottom: 24,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _removePhoto,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                  ],
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
            // Phone numbers section
            ...List.generate(_phoneControllers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == _phoneControllers.length - 1 ? 16 : 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneControllers[index],
                        style: const TextStyle(fontFamily: 'nothing'),
                        decoration: InputDecoration(
                          labelText: 'Phone ${index + 1}',
                          labelStyle: const TextStyle(fontFamily: 'nothing'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    if (_phoneControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removePhoneField(index),
                      ),
                  ],
                ),
              );
            }),
            // Add phone button
            TextButton.icon(
              onPressed: _addPhoneField,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Phone Number',
                style: TextStyle(fontFamily: 'nothing'),
              ),
            ),
            const SizedBox(height: 16),
            // Email addresses section
            ...List.generate(_emailControllers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == _emailControllers.length - 1 ? 16 : 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailControllers[index],
                        style: const TextStyle(fontFamily: 'nothing'),
                        decoration: InputDecoration(
                          labelText: 'Email ${index + 1}',
                          labelStyle: const TextStyle(fontFamily: 'nothing'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    if (_emailControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeEmailField(index),
                      ),
                  ],
                ),
              );
            }),
            // Add email button
            TextButton.icon(
              onPressed: _addEmailField,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Email Address',
                style: TextStyle(fontFamily: 'nothing'),
              ),
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
