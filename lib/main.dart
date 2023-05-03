import 'package:authorization_app/providers/auth.dart';
import 'package:authorization_app/screens/auth_screen.dart';
import 'package:authorization_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:provider/provider.dart';
// import 'package:riverpod/riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: Auth()),],
      child: Consumer<Auth>(builder: (ctx, auth, _) =>
          MaterialApp(
              home: auth.isAuth ? const MainScreen() : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, authResult) =>
                  authResult.connectionState == ConnectionState.waiting ?  AuthScreen(): AuthScreen(),)

      ),),);

  }
}
