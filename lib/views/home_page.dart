import 'package:flutter/material.dart';
import 'package:memoriaviva/views/reminder_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/reminder_item.dart';
import '../components/search_filter.dart';
import '../models/Reminder.dart';
import 'create_reminder_page.dart';
import 'intro_page.dart';

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
        title: Text('Olá, $userName',style:TextStyle(fontSize: 22,fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
        actions: [
          IconButton(
            onPressed: _removeUserName,
            icon: const Icon(Icons.delete,size: 40,),
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
              SearchFilter(
                searchQuery: searchQuery,
                onSearchQueryChanged: _updateSearchQuery,
                selectedFilter: selectedFilter,
                onFilterSelected: _updateFilter,
              ),
              const SizedBox(height: 10),
            ],

            // Lista de Lembretes Filtrados
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
        child: const Icon(Icons.add,size: 40,),
      ),
      
    );
  }
}
