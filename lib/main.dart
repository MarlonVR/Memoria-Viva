import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/intro_page.dart';
import 'views/home_page.dart';
import 'views/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null, // Ícone padrão para notificações (pode ser null)
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Lembretes',
        channelDescription: 'Notificações de lembretes',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _checkIfNameExists() async {
    print('Verificando se o nome do usuário existe nos SharedPreferences...');

    // Adiciona o atraso de 3 segundos para mostrar a SplashScreen
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    bool hasName = prefs.containsKey('userName');

    print('O nome do usuário existe: $hasName');
    return hasName;
  }

  Future<String?> _getSavedName() async {
    print('Tentando carregar o nome do usuário dos SharedPreferences...');

    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');

    print('Nome carregado: $userName');
    return userName;
  }

  // Adicione este método para solicitar permissão de notificações
  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Solicita permissão ao usuário
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memória Viva',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 76, 175, 125)),
        useMaterial3: true,
        datePickerTheme: const DatePickerThemeData(
          dayStyle: TextStyle(fontSize: 20),
          headerHelpStyle: TextStyle(fontSize: 20),
          confirmButtonStyle: ButtonStyle(textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 20))),
          cancelButtonStyle: ButtonStyle(textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 20))),
        ),
        timePickerTheme: const TimePickerThemeData(
          dialTextStyle: TextStyle(fontSize: 20),
          confirmButtonStyle: ButtonStyle(textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 20))),
          cancelButtonStyle: ButtonStyle(textStyle: MaterialStatePropertyAll(TextStyle(fontSize: 20))),
        ),
      ),
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: FutureBuilder<bool>(
        future: _checkIfNameExists(),
        builder: (context, snapshot) {
          print('Estado do FutureBuilder (verificação de nome): ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Exibindo SplashScreen...');
            return const SplashScreenPage();
          } else if (snapshot.hasData && snapshot.data == true) {
            return FutureBuilder<String?>(
              future: _getSavedName(),
              builder: (context, nameSnapshot) {
                print('Estado do FutureBuilder (carregamento do nome): ${nameSnapshot.connectionState}');
                if (nameSnapshot.connectionState == ConnectionState.waiting) {
                  print('Exibindo SplashScreen enquanto carrega o nome...');
                  return const SplashScreenPage();
                } else if (nameSnapshot.hasData && nameSnapshot.data != null) {
                  print('Nome encontrado, indo para HomePage...');
                  return MyHomePage(title: 'Olá, ${nameSnapshot.data}');
                } else {
                  print('Nome não encontrado, indo para IntroPage...');
                  // Se algo der errado ou o nome não estiver presente, mostra a IntroPage
                  return const IntroPage();
                }
              },
            );
          } else {
            print('Nome não existe, indo para IntroPage...');
            return const IntroPage();
          }
        },
      ),
    );
  }
}
