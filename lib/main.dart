import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://voorrggmvqeywjrtcwbo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvb3JyZ2dtdnFleXdqcnRjd2JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4Mzc0MTIsImV4cCI6MjA4NDQxMzQxMn0.QTm1dF1aPe7ws-ZSyIcRBzthgEmTJacFHg1ElEkRYAY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginView(),
    );
  }
}
