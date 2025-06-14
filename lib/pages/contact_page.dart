import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dialer/providers/contact_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:dialer/pages/contact_details_page.dart';
import 'dart:async';

class ContactBean {
  final Contact contact;
  String? tagIndex;
  String? namePinyin;
  bool isShowSuspension = false;

  ContactBean(this.contact) {
    // Handle empty or invalid names
    if (contact.displayName.isEmpty) {
      tagIndex = '#';
    } else {
      try {
        // Safely get the first character and ensure it's a valid UTF-16 character
        final firstChar = contact.displayName[0];
        final codeUnit = firstChar.codeUnitAt(0);
        if (codeUnit > 0xFFFF || !RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
          tagIndex = '#';
        } else {
          tagIndex = firstChar.toUpperCase();
        }
      } catch (e) {
        tagIndex = '#';
      }
    }
  }

  String getSuspensionTag() => tagIndex ?? '#';
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _alphabet = [
    '#',
    ...List.generate(26, (index) => String.fromCharCode(65 + index))
  ];
  String? _selectedLetter;
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final Map<String, Widget> _avatarCache = {};
  final Map<String, int> _indexMap = {};
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().initializeContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollTimer?.cancel();
    _avatarCache.clear();
    _indexMap.clear();
    _scrollController.dispose();
    super.dispose();
  }

  String _sanitizeText(String text) {
    try {
      // Remove any invalid UTF-16 characters
      return text
          .replaceAll(RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]'), '')
          .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    } catch (e) {
      return 'Unknown';
    }
  }

  void _updateIndexMap(List<ContactBean> contacts) {
    _indexMap.clear();
    for (int i = 0; i < contacts.length; i++) {
      final tag = contacts[i].getSuspensionTag();
      if (!_indexMap.containsKey(tag)) {
        _indexMap[tag] = i;
      }
    }
  }

  void _handleIndexBarScroll(String tag) {
    if (!mounted) return;

    setState(() {
      _selectedLetter = tag;
      _isScrolling = true;
    });

    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
      }
    });
  }

  Widget _buildContactAvatar(Contact contact, BuildContext context) {
    final cacheKey = '${contact.id}_${contact.photo != null}';
    if (_avatarCache.containsKey(cacheKey)) {
      return _avatarCache[cacheKey]!;
    }

    final avatar = contact.photo != null
        ? CircleAvatar(
            radius: 24,
            backgroundImage: MemoryImage(contact.photo!),
          )
        : CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              _sanitizeText(contact.displayName).isNotEmpty
                  ? _sanitizeText(contact.displayName)[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'nothing',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

    _avatarCache[cacheKey] = avatar;
    return avatar;
  }

  Widget _buildContactTile(ContactBean contactBean, BuildContext context) {
    final contact = contactBean.contact;
    final displayName = _sanitizeText(contact.displayName);
    String? phoneNumber;
    try {
      phoneNumber = contact.phones.isNotEmpty
          ? _sanitizeText(contact.phones.first.number)
          : null;
    } catch (e) {
      phoneNumber = null;
    }

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailsPage(contact: contact),
          ),
        );
      },
      title: Text(
        displayName,
        style: const TextStyle(fontFamily: 'nothing'),
      ),
      leading: Hero(
        tag: 'contact_${contact.id}',
        child: _buildContactAvatar(contact, context),
      ),
      subtitle: phoneNumber != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                phoneNumber,
                style: TextStyle(
                  fontFamily: 'nothing',
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.phone_outlined),
        onPressed: () {
          // TODO: Implement call functionality
        },
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, child) {
        if (contactProvider.isLoading) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (contactProvider.contacts.isEmpty) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No contacts found',
                    style: TextStyle(
                      fontFamily: 'nothing',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: contactProvider.refreshContacts,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(fontFamily: 'nothing'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final contactBeans = contactProvider.filteredContacts
            .map((contact) => ContactBean(contact))
            .toList();

        _updateIndexMap(contactBeans);

        return SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: contactProvider.filterContacts,
                  style: const TextStyle(fontFamily: 'nothing', fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(
                      fontFamily: 'nothing',
                      color: Theme.of(context).hintColor.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: contactProvider.refreshContacts,
                      child: ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thickness: MaterialStateProperty.all(6),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            itemCount: contactBeans.length,
                            itemBuilder: (context, index) {
                              final contactBean = contactBeans[index];
                              return _buildContactTile(contactBean, context);
                            },
                          ),
                        ),
                      ),
                    ),
                    if (_isScrolling)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedLetter ?? '',
                            style: const TextStyle(
                              fontFamily: 'nothing',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
