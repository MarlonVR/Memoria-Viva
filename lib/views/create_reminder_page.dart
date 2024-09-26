import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Import para seleção de imagens
import 'dart:io'; // Para manipulação de arquivos
import 'package:shared_preferences/shared_preferences.dart'; // Para salvar os dados
import '../models/Reminder.dart';

class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({super.key});

  @override
  _CreateReminderPageState createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  // Variável para armazenar a escolha do usuário (true para "Sim", false para "Não")
  bool? repetir = false;

  // Variáveis para armazenar a data e a hora selecionadas
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Variável para armazenar se o usuário deseja adicionar imagem
  bool? adicionarImagem = false;

  // Variável para armazenar o caminho da imagem selecionada
  String? _selectedImagePath;

  // Controladores para os campos de texto
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Lista de imagens padrão
  final List<String> defaultImages = [
    'assets/images/teste.png',
    'assets/images/image2.png',
    'assets/images/image3.png',
  ];

  // ScrollController para controlar o scroll da página
  final ScrollController _scrollController = ScrollController();

  // Função para mostrar o calendário de seleção de data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(), // Data inicial
      firstDate: DateTime(1900), // Data mínima
      lastDate: DateTime(2100), // Data máxima
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Função para mostrar o seletor de hora
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Função para selecionar imagem da galeria
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedImage =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImagePath = pickedImage.path;
      });
    }
  }

  // Função para selecionar uma imagem padrão
  void _selectDefaultImage(String imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
    });
  }

  // Função para mostrar o diálogo de seleção de imagem padrão
  void _showDefaultImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma imagem'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: defaultImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Número de colunas (imagens maiores)
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1, // Mantém as células quadradas
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

  // Função para mostrar o menu de seleção de imagem no centro da tela
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

  // Função para rolar a tela até o final
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  // Função para salvar o lembrete
  Future<void> _saveReminder() async {
    // Verifica se o nome do evento foi preenchido
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome do evento.')),
      );
      return;
    }

    // Cria um objeto Reminder com as informações fornecidas
    Reminder reminder = Reminder(
      eventName: _eventNameController.text,
      date: selectedDate ?? DateTime.now(),
      repeat: repetir ?? false,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      alarmTime: selectedTime,
      imagePath: _selectedImagePath,
    );

    // Obtém a instância do SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Recupera a lista de lembretes salvos (se houver)
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    // Adiciona o novo lembrete à lista
    reminderList.add(reminder.toJson());

    // Salva a lista atualizada no SharedPreferences
    await prefs.setStringList('reminders', reminderList);

    // Exibe uma mensagem de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lembrete adicionado com sucesso!')),
    );

    // Limpa os campos ou navega de volta para a tela anterior
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obter o Locale atual
    Locale myLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Lembrete'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        // Aplica o gradiente de fundo
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
          child: SingleChildScrollView(
            controller: _scrollController, // Adiciona o ScrollController
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Logo do app no topo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),

                // Nome do Evento
                const Text(
                  'Nome do Evento (Lembrete)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Digite o nome do evento',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),

                // Data do Evento (com calendário)
                const Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy', 'pt_BR')
                          .format(selectedDate!)
                          : 'Escolha a data do evento',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Repetir?
                const Text(
                  'Repetir?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Botão "Sim"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          repetir = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: repetir == true
                              ? Colors.green
                              : Colors.grey[300],
                          border: Border.all(
                            color:
                            repetir == true ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Sim',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Botão "Não"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          repetir = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: repetir == false
                              ? Colors.red
                              : Colors.grey[300],
                          border: Border.all(
                            color:
                            repetir == false ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Não',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Observações
                const Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Digite observações adicionais',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),

                // Alarme (com seletor de hora)
                const Text(
                  'Alarme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Digite a hora do alarme (ex: 08:00)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pergunta: Deseja adicionar alguma Imagem para o seu lembrete?
                const Text(
                  'Deseja adicionar alguma Imagem para o seu lembrete?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Botão "Sim"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          adicionarImagem = true;
                        });
                        // Rola a tela até o final após o setState
                        _scrollToEnd();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: adicionarImagem == true
                              ? Colors.green
                              : Colors.grey[300],
                          border: Border.all(
                            color: adicionarImagem == true
                                ? Colors.green
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Sim',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Botão "Não"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          adicionarImagem = false;
                          _selectedImagePath = null; // Limpa a imagem selecionada
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: adicionarImagem == false
                              ? Colors.red
                              : Colors.grey[300],
                          border: Border.all(
                            color: adicionarImagem == false
                                ? Colors.red
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Não',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Se o usuário deseja adicionar imagem, mostra a opção
                if (adicionarImagem == true) ...[
                  // Instrução clara
                  const Text(
                    'Clique no ícone abaixo para adicionar a imagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Imagem selecionada ou placeholder
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Opções para selecionar imagem
                        _showImageSourceDialog();
                      },
                      child: _selectedImagePath != null
                          ? (_selectedImagePath!.startsWith('assets/')
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
                      ))
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
                  const SizedBox(height: 20),
                ],

                // Botão de Adicionar
                Center(
                  child: ElevatedButton(
                    onPressed: _saveReminder, // Chama a função para salvar o lembrete
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 20,
                      ),
                      backgroundColor: Colors.green,
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
