import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoriaviva/views/reminder_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Reminder.dart';
import 'create_reminder_page.dart';
import 'intro_page.dart';
import 'dart:io';

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

  Future<void> _removeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('reminders');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IntroPage()),
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
      });
      _filterAndSortReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder, int index) async {
    setState(() {
      reminders[index] = reminder.copyWithOpacity(0.0);
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    reminderList.removeWhere((reminderJson) {
      Reminder r = Reminder.fromJson(reminderJson);
      return r.eventName == reminder.eventName && r.date == reminder.date;
    });

    await prefs.setStringList('reminders', reminderList);

    setState(() {
      reminders.removeAt(index);
      _filterAndSortReminders();
    });
  }

  Widget _buildReminderItem(Reminder reminder, int index) {
    return GestureDetector(
      onTap: () => _navigateToReminderDetails(reminder, index),
      child: AnimatedOpacity(
        opacity: reminder.opacity ?? 1.0,
        duration: const Duration(milliseconds: 500),
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB2DFDB),
                  Color(0xFFE0F7FA),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                // Verifica se há imagem associada, caso contrário, exibe um gradiente
                Positioned.fill(
                  child: reminder.imagePath != null
                      ? (reminder.imagePath!.startsWith('assets/')
                      ? Image.asset(
                    reminder.imagePath!,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(reminder.imagePath!),
                    fit: BoxFit.cover,
                  ))
                      : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFB2DFDB),
                          Color(0xFFE0F7FA),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.event_note,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Informações sobre o lembrete
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          reminder.eventName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(reminder.date)}',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alarme: ${reminder.alarmTime != null ? reminder.alarmTime!.format(context) : 'Sem alarme'}',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // Texto "Excluir Lembrete"
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _deleteReminder(reminder, index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Excluir Lembrete',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $userName'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            onPressed: _removeUserName,
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir nome de usuário',
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
            // Barra de Pesquisa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                onChanged: _updateSearchQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  hintText: 'Digite o que você procura...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Botões de Filtro
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _updateFilter('Mais recentes'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selectedFilter == 'Mais recentes' ? Colors.green : Colors.grey[300],
                      border: Border.all(
                        color: selectedFilter == 'Mais recentes' ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Mais recentes',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _updateFilter('Mais distantes'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selectedFilter == 'Mais distantes' ? Colors.green : Colors.grey[300],
                      border: Border.all(
                        color: selectedFilter == 'Mais distantes' ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Mais distantes',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Lista de Lembretes Filtrados
            Expanded(
              child: filteredReminders.isEmpty
                  ? const Center(
                child: Text(
                  'Nenhum lembrete encontrado.',
                  style: TextStyle(fontSize: 18),
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
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }
}
