import 'package:dialer/pages/container_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dialer/providers/contact_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContactProvider(),
      child: Material(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dialer',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const ContainerPage(),
        ),
      ),
    );
  }
}
