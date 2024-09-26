import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    setState(() {
      reminders = reminderList.map((reminderJson) {
        return Reminder.fromJson(reminderJson);
      }).toList();
    });
  }

  // Função criada só para testar
  Future<void> _removeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('reminders'); // Remove os lembretes salvos
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
    _loadReminders(); // Recarrega os lembretes quando retorna da CreateReminderPage
  }

  Future<void> _deleteReminder(Reminder reminder, int index) async {
    // Animação de evaporação
    setState(() {
      reminders[index] = reminder.copyWithOpacity(0.0); // Atualiza a opacidade
    });


    await Future.delayed(const Duration(milliseconds: 500)); // Espera a animação terminar

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    // Remove o lembrete da lista
    reminderList.removeWhere((reminderJson) {
      Reminder r = Reminder.fromJson(reminderJson);
      return r.eventName == reminder.eventName && r.date == reminder.date;
    });

    // Atualiza o SharedPreferences
    await prefs.setStringList('reminders', reminderList);

    // Remove o lembrete da lista local após a animação
    setState(() {
      reminders.removeAt(index);
    });
  }

  Widget _buildReminderItem(Reminder reminder, int index) {
    return AnimatedOpacity(
      opacity: reminder.opacity ?? 1.0, // Opacidade variável com base no estado
      duration: const Duration(milliseconds: 500),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Container(
          height: 220, // Altura ajustada para permitir mais espaço
          child: Stack(
            children: <Widget>[
              // Verifica se há imagem associada, caso contrário, exibe um estilo diferente
              Positioned.fill(
                child: reminder.imagePath != null
                    ? (reminder.imagePath!.startsWith('assets/')
                    ? Image.asset(
                  reminder.imagePath!,
                  fit: BoxFit.contain, // A imagem se ajustará ao card sem cortar
                )
                    : Image.file(
                  File(reminder.imagePath!),
                  fit: BoxFit.contain, // A imagem se ajustará ao card sem cortar
                ))
                    : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB2DFDB), // Cor suave para o fundo
                        Color(0xFFE0F7FA), // Cor suave para o fundo
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.event_note,
                      size: 80,
                      color: Colors.grey, // Ícone grande quando não houver imagem
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
                    color: Colors.black.withOpacity(0.4), // Fundo preto semi-transparente
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Nome do evento
                      Text(
                        reminder.eventName,
                        style: const TextStyle(
                          fontSize: 22, // Tamanho do texto maior
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Texto branco para contraste
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Data e alarme
                      Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(reminder.date)}',
                        style: const TextStyle(fontSize: 18, color: Colors.white), // Texto maior
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alarme: ${reminder.alarmTime != null ? reminder.alarmTime!.format(context) : 'Sem alarme'}',
                        style: const TextStyle(fontSize: 18, color: Colors.white), // Texto maior
                      ),
                    ],
                  ),
                ),
              ),

              // Texto "Excluir Lembrete" no canto superior direito
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteReminder(reminder, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8), // Fundo vermelho semi-transparente
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Excluir Lembrete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // Texto branco para contraste
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
            IconButton(
              onPressed: _removeUserName,
              icon: const Icon(Icons.delete),
              tooltip: 'Excluir nome de usuário',
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFADD8E6),
              Color(0xFFF5F5DC),
            ],
          ),
        ),
        child: reminders.isEmpty
            ? const Center(
          child: Text(
            'Nenhum lembrete adicionado.',
            style: TextStyle(fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _buildReminderItem(reminders[index], index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateReminder,
        tooltip: 'Criar Lembrete',
        child: const Icon(Icons.add),
      ),
    );
  }
}
