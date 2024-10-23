import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/intro_page.dart';
import 'views/home_page.dart';
import 'views/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'models/Reminder.dart';
import 'views/alarm_page.dart';
import 'dart:async';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final StreamController<ReceivedAction> notificationActionStream = StreamController<ReceivedAction>.broadcast();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null, // Ícone padrão para notificações (pode ser null)
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Lembretes',
        channelDescription: 'Notificações de lembretes',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        soundSource: 'resource://raw/alarm_sound',
        criticalAlerts: true,
        playSound: true,
        enableVibration: true,
        defaultPrivacy: NotificationPrivacy.Public,
      ),
    ],
    debug: true,
  );

  // Obter a ação inicial da notificação (se houver)
  ReceivedAction? initialAction = await AwesomeNotifications()
      .getInitialNotificationAction(removeFromActionEvents: false);

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(MyApp(initialAction: initialAction));
}

// Método que adiciona as ações de notificação ao StreamController
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  notificationActionStream.add(receivedAction);
}

void _handleNotificationAction(ReceivedAction receivedAction) {
  print("Payload da notificação: ${receivedAction.payload}");
  String? reminderJson = receivedAction.payload?['reminder'];
  if (reminderJson != null) {
    try {
      Reminder reminder = Reminder.fromJson(reminderJson);
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AlarmPage(reminder: reminder),
        ),
            (route) => false,
      );

      if (receivedAction.id != null) {
        AwesomeNotifications().dismiss(receivedAction.id!);
      }
    } catch (e) {
      print("Erro ao decodificar a notificação: $e");
    }
  }
}

class MyApp extends StatefulWidget {
  final ReceivedAction? initialAction;

  const MyApp({Key? key, this.initialAction}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationAction(widget.initialAction!);
      });
    }

    // Escutar o StreamController para lidar com as ações de notificação
    notificationActionStream.stream.listen((ReceivedAction receivedAction) {
      _handleNotificationAction(receivedAction);
    });

    // Solicitar permissões necessárias
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Solicitar permissão ao usuário
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memória Viva',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 76, 175, 125)),
        useMaterial3: true,
        datePickerTheme: const DatePickerThemeData(
          dayStyle: TextStyle(fontSize: 20),
          headerHelpStyle: TextStyle(fontSize: 20),
          confirmButtonStyle: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 20))),
          cancelButtonStyle: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 20))),
        ),
        timePickerTheme: const TimePickerThemeData(
          dialTextStyle: TextStyle(fontSize: 20),
          confirmButtonStyle: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 20))),
          cancelButtonStyle: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 20))),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreenPage();
          } else if (snapshot.hasData && snapshot.data == true) {
            return FutureBuilder<String?>(
              future: _getSavedName(),
              builder: (context, nameSnapshot) {
                if (nameSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreenPage();
                } else if (nameSnapshot.hasData && nameSnapshot.data != null) {
                  return MyHomePage(title: 'Olá, ${nameSnapshot.data}');
                } else {
                  return const IntroPage();
                }
              },
            );
          } else {
            return const IntroPage();
          }
        },
      ),
    );
  }

  Future<bool> _checkIfNameExists() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasName = prefs.containsKey('userName');
    return hasName;
  }

  Future<String?> _getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');
    return userName;
  }
}
