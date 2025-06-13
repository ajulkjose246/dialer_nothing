import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:dialer/pages/contact_details_page.dart';
import 'package:dialer/providers/contact_provider.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

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
    super.dispose();
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
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
                child: RefreshIndicator(
                  onRefresh: contactProvider.refreshContacts,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: contactProvider.filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = contactProvider.filteredContacts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ContactDetailsPage(contact: contact),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Hero(
                              tag: 'contact_${contact.id}',
                              child: contact.photo != null
                                  ? CircleAvatar(
                                      radius: 24,
                                      backgroundImage: MemoryImage(
                                        contact.photo!,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        contact.displayName.isNotEmpty
                                            ? contact.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontFamily: 'nothing',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                            title: Text(
                              contact.displayName,
                              style: const TextStyle(
                                fontFamily: 'nothing',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: contact.phones.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      contact.phones.first.number,
                                      style: TextStyle(
                                        fontFamily: 'nothing',
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
