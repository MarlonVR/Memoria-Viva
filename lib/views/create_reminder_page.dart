import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/Reminder.dart';
import 'package:path_provider/path_provider.dart';


class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({super.key});

  @override
  _CreateReminderPageState createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  bool? repetir = false;
  bool? adicionarImagem = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? _selectedImagePath;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      
      
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _selectedImagePath = pickedImage.path;
      });
    }
  }

  Future<void> _downloadImageFromUnsplash(String query) async {
    final translator = GoogleTranslator();
    final translatedQuery = await translator.translate(query, from: 'pt', to: 'en');
    const String apiKey = 'A880dxidfBGU-9k1njcsW2qOAGaxSLGLFyiDowxwhTw';

    final url = 'https://api.unsplash.com/photos/random?query=${Uri.encodeComponent(translatedQuery.text)}&client_id=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final imageUrl = jsonDecode(response.body)['urls']['regular'];

        final imageResponse = await http.get(Uri.parse(imageUrl));

        if (imageResponse.statusCode == 200) {
          final documentDirectory = await getApplicationDocumentsDirectory();
          final filePath = '${documentDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          file.writeAsBytesSync(imageResponse.bodyBytes);
          setState(() {
            _selectedImagePath = file.path;
          });
        } else {
          throw Exception('Erro ao baixar a imagem da URL.');
        }
      } else {
        throw Exception('Erro ao obter imagem da API do Unsplash.');
      }
    } catch (e) {
      print('Erro ao baixar imagem: $e');
    }
  }

  Future<void> _saveReminder() async {
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome do evento.')),
      );
      return;
    }

    // Se o usuário não quiser tirar foto, baixa imagem do Unsplash
    if (adicionarImagem == false) {
      await _downloadImageFromUnsplash(_eventNameController.text);
    }

    Reminder reminder = Reminder(
      eventName: _eventNameController.text,
      date: selectedDate ?? DateTime.now(),
      repeat: repetir ?? false,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      alarmTime: selectedTime,
      imagePath: _selectedImagePath,
    );

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];
    reminderList.add(reminder.toJson());
    await prefs.setStringList('reminders', reminderList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lembrete adicionado com sucesso!')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Lembrete',style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Image.asset(
                    'assets/logo_notext.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Nome do Evento (Lembrete)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _eventNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy', 'pt_BR').format(selectedDate!)
                          : 'Escolha a data do evento',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Alarme',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Selecione a hora do alarme',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Opção de repetir o lembrete
                const Text(
                  'Repetir alarme todos os dias?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          repetir = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: repetir == true ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: repetir == true ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Sim',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          repetir = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: repetir == false ? Colors.red : Colors.grey[300],
                          border: Border.all(
                            color: repetir == false ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Não',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Deseja tirar uma foto?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          adicionarImagem = true;
                          _scrollToEnd();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: adicionarImagem == true ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: adicionarImagem == true ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Sim',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          adicionarImagem = false;
                          _selectedImagePath = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: adicionarImagem == false ? Colors.red : Colors.grey[300],
                          border: Border.all(
                            color: adicionarImagem == false ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Não',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                if (adicionarImagem == true) ...[
                  const Text(
                    'Clique no ícone abaixo para tirar uma foto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: _selectedImagePath != null
                          ? Image.file(
                        File(_selectedImagePath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.grey,
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                Center(
                  child: ElevatedButton(
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      textStyle: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: const Color.fromARGB(255, 76, 175, 125),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Adicionar Lembrete'),
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
