import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_reminder_page.dart';
import 'intro_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // Função criada só para testar
  Future<void> _removeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IntroPage()),
    );
  }

  void _incrementCounter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderPage()),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // Vai para a tela de criação de lembrete
        tooltip: 'Criar Lembrete',
        child: const Icon(Icons.add),
      ),
    );
  }
}
