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
          .where((reminder) => reminder.eventName.toLowerCase().contains(searchQuery.toLowerCase()))
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

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    reminderList.removeWhere((reminderJson) {
      Reminder r = Reminder.fromJson(reminderJson);
      return r.eventName == reminder.eventName && r.date == reminder.date;
    });

    await prefs.setStringList('reminders', reminderList);

    _filterAndSortReminders();
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
            // Mostra a barra de pesquisa e os filtros apenas se houver lembretes
            if (reminders.isNotEmpty) ...[
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
            ],

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

// Widget personalizado para cada item de lembrete
class ReminderItem extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ReminderItem({
    Key? key,
    required this.reminder,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  _ReminderItemState createState() => _ReminderItemState();
}

class _ReminderItemState extends State<ReminderItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDelete() {
    _controller.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
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
                Positioned.fill(
                  child: widget.reminder.imagePath != null
                      ? (widget.reminder.imagePath!.startsWith('assets/')
                      ? Image.asset(
                    widget.reminder.imagePath!,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(widget.reminder.imagePath!),
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
                          widget.reminder.eventName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(widget.reminder.date)}',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alarme: ${widget.reminder.alarmTime != null ? widget.reminder.alarmTime!.format(context) : 'Sem alarme'}',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _handleDelete,
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
}
