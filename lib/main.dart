import 'package:bate_ponto/home.dart';
import 'package:bate_ponto/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: const Color.fromARGB(255, 23, 26, 170),
);

final theme = ThemeData().copyWith(
  brightness: Brightness.light,
  colorScheme: colorScheme,
);

final darkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 23, 26, 170),
);

final darkTheme = ThemeData(brightness: Brightness.dark).copyWith(
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
);

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const InitialApp());
}

class InitialApp extends StatelessWidget {
  const InitialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          if (snapshot.data == null) {
            return const AuthScreen();
          }
          return const HomePage();
        },
      ),
      // home: user == null ? const AuthScreen() : HomePage(user),
    );
  }
}
