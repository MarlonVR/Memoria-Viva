import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Olá, ${_nameController.text}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/logo.png',
                width: 250,
                height: 292,
              ),
              const SizedBox(height: 40),


              const Text(
                'Por favor, digite seu nome:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),


              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Digite seu nome',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),


              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    _saveName();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, insira um nome')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Começar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
