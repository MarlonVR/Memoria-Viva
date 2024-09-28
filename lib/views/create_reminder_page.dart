import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Reminder.dart';

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
  String? errorMessage;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> defaultImages = [
    'assets/images/teste.png',
    'assets/images/image2.png',
    'assets/images/image3.png',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Impede a seleção de datas anteriores
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        errorMessage = null; // Reseta a mensagem de erro ao selecionar uma data válida
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

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImagePath = pickedImage.path;
      });
    }
  }

  void _selectDefaultImage(String imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione a origem da imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, size: 40),
                title: const Text(
                  'Galeria',
                  style: TextStyle(fontSize: 24),
                ),
                onTap: () {
                  _pickImageFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.image, size: 40),
                title: const Text(
                  'Imagens Padrão',
                  style: TextStyle(fontSize: 24),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDefaultImageDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDefaultImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma imagem padrão'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: defaultImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    _selectDefaultImage(defaultImages[index]);
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    defaultImages[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReminder() async {
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome do evento.')),
      );
      return;
    }

    // Validação para garantir que a data não seja anterior ao dia atual
    if (selectedDate != null && selectedDate!.isBefore(DateTime.now())) {
      setState(() {
        errorMessage = 'A data do lembrete não pode ser anterior ao dia atual.';
      });
      return;
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
        title: const Text('Criar Lembrete'),
        backgroundColor: const Color(0xFF4CAF50),
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
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 30),

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
                  style: const TextStyle(fontSize: 18),
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
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),

                // Exibe a mensagem de erro, se houver
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red, // Mensagem de erro em vermelho
                        ),
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
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
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
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Deseja adicionar alguma imagem?',
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
                          style: TextStyle(fontSize: 18, color: Colors.black),
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
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                if (adicionarImagem == true) ...[
                  const Text(
                    'Clique no ícone abaixo para adicionar a imagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: _selectedImagePath != null
                          ? _selectedImagePath!.startsWith('assets/')
                          ? Image.asset(
                        _selectedImagePath!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
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
                          Icons.add_a_photo,
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
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
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
