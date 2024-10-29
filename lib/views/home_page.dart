import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/Reminder.dart';
import 'create_reminder_page.dart';
import '../components/reminder_item.dart';
import '../components/search_filter.dart';
import 'reminder_details_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Reminder> reminders = [];
  List<Reminder> filteredReminders = [];
  String searchQuery = '';
  String selectedFilter = 'Mais recentes';
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadReminders();

    // Verificar otimização de bateria e exibir o pop-up apenas se houver restrições
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimizationStatus();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
    });
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    setState(() {
      reminders = reminderList.map((reminderJson) {
        return Reminder.fromJson(reminderJson);
      }).toList();
      _filterAndSortReminders();
    });
  }

  void _filterAndSortReminders() {
    setState(() {
      filteredReminders = reminders
          .where((reminder) =>
          reminder.eventName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();

      if (selectedFilter == 'Mais recentes') {
        filteredReminders.sort((a, b) => a.date.compareTo(b.date));
      } else {
        filteredReminders.sort((a, b) => b.date.compareTo(a.date));
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      _filterAndSortReminders();
    });
  }

  void _updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _filterAndSortReminders();
    });
  }

  Future<void> _changeUserName() async {
    TextEditingController nameController = TextEditingController(text: userName);

    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.04,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFFF5F5DC),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Alterar Nome de Usuário',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: nameController,
                  style: TextStyle(fontSize: screenWidth * 0.05),
                  decoration: InputDecoration(
                    labelText: 'Novo Nome',
                    labelStyle: TextStyle(fontSize: screenWidth * 0.045, color: Colors.grey[800]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('userName', nameController.text);
                        setState(() {
                          userName = nameController.text;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _navigateToCreateReminder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderPage()),
    );
    _loadReminders();
  }

  void _navigateToReminderDetails(Reminder reminder, int index) async {
    final updatedReminder = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailsPage(reminder: reminder, index: index),
      ),
    );

    if (updatedReminder != null) {
      setState(() {
        reminders[index] = updatedReminder;
        _filterAndSortReminders();
      });

      final prefs = await SharedPreferences.getInstance();
      List<String> reminderList = reminders.map((r) => r.toJson()).toList();
      await prefs.setStringList('reminders', reminderList);
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    setState(() {
      reminders.remove(reminder);
    });

    if (reminder.notificationId != null) {
      await AwesomeNotifications().cancel(reminder.notificationId!);
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    reminderList.removeWhere((reminderJson) {
      Reminder r = Reminder.fromJson(reminderJson);
      return r.eventName == reminder.eventName && r.date == reminder.date;
    });

    await prefs.setStringList('reminders', reminderList);
    _filterAndSortReminders();
  }

  // Verificar se o app está sob restrição de otimização de bateria
  Future<void> _checkBatteryOptimizationStatus() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt ?? 0;

      if (sdkInt >= 23) {
        bool isIgnoringBatteryOptimizations =
        await Permission.ignoreBatteryOptimizations.isGranted;

        // Se a otimização estiver ativa, mostrar o pop-up
        if (!isIgnoringBatteryOptimizations) {
          _showBatteryOptimizationDialog(context);
        }
      }
    }
  }

  // Mostrar pop-up para confirmação da ação
  Future<void> _showBatteryOptimizationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Otimização de Bateria'),
          content: const Text(
              'Para garantir que o aplicativo funcione corretamente, recomendamos desativar as otimizações de bateria. Deseja prosseguir para as configurações?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                Navigator.of(context).pop();
                _openBatteryOptimizationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Abrir configurações de otimização de bateria
  Future<void> _openBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:$packageName',
      );
      await intent.launch();
    }
  }

  Widget _buildReminderItem(Reminder reminder, int index) {
    return ReminderItem(
      key: ValueKey(reminder.eventName + reminder.date.toIso8601String()),
      reminder: reminder,
      onDelete: () => _deleteReminder(reminder),
      onTap: () => _navigateToReminderDetails(reminder, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $userName',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
        actions: [
          IconButton(
            onPressed: _changeUserName,
            icon: const Icon(Icons.edit, size: 30), // Ícone de lápis
            tooltip: 'Alterar nome de usuário',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFFF5F5DC),
            ],
          ),
        ),
        child: Column(
          children: [
            if (reminders.isNotEmpty) ...[
              SearchFilter(
                searchQuery: searchQuery,
                onSearchQueryChanged: _updateSearchQuery,
                selectedFilter: selectedFilter,
                onFilterSelected: _updateFilter,
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: filteredReminders.isEmpty
                  ? const Center(
                child: Text(
                  'Nenhum lembrete encontrado.',
                  style: TextStyle(fontSize: 22),
                ),
              )
                  : ListView.builder(
                itemCount: filteredReminders.length,
                itemBuilder: (context, index) {
                  return _buildReminderItem(filteredReminders[index], index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateReminder,
        tooltip: 'Criar Lembrete',
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
        child: const Icon(Icons.add, size: 40),
      ),
    );
  }
}
