import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';
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

  bool _isSaving = false;

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

    final url =
        'https://api.unsplash.com/photos/random?query=${Uri.encodeComponent(translatedQuery.text)}&client_id=$apiKey';

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
    if (_isSaving) return; // Impede múltiplos cliques

    setState(() {
      _isSaving = true; // Inicia o processo de salvamento
    });

    try {
      if (_eventNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, insira o nome do evento.')),
        );
        return;
      }

      if (adicionarImagem == true && _selectedImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Você selecionou "Sim" para adicionar uma foto. Por favor, adicione uma foto antes de continuar.',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Faz o download da imagem do Unsplash caso a opção de adicionarImagem esteja marcada como false
      if (adicionarImagem == false) {
        await _downloadImageFromUnsplash(_eventNameController.text);
      }

      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      Reminder reminder = Reminder(
        eventName: _eventNameController.text,
        date: selectedDate ?? DateTime.now(),
        repeat: repetir ?? false,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        alarmTime: selectedTime,
        imagePath: _selectedImagePath,
        notificationId: notificationId,
      );

      final prefs = await SharedPreferences.getInstance();
      List<String> reminderList = prefs.getStringList('reminders') ?? [];
      reminderList.add(reminder.toJson());
      await prefs.setStringList('reminders', reminderList);

      await _scheduleNotification(reminder);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lembrete adicionado com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Erro ao salvar o lembrete: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    if (reminder.repeat) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.notificationId!,
          channelKey: 'basic_channel',
          title: 'Alarme: ${reminder.eventName}',
          body: reminder.notes ?? 'Seu alarme está tocando',
          payload: {
            'reminder': reminder.toJson(),
          },
          displayOnForeground: true,
          displayOnBackground: true,
          fullScreenIntent: true,
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
          criticalAlert: true,
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        schedule: NotificationCalendar(
          hour: reminder.alarmTime?.hour ?? 0,
          minute: reminder.alarmTime?.minute ?? 0,
          second: 0,
          repeats: true,
          preciseAlarm: true,
        ),
      );
    } else {
      DateTime scheduledDateTime = DateTime(
        reminder.date.year,
        reminder.date.month,
        reminder.date.day,
        reminder.alarmTime?.hour ?? 0,
        reminder.alarmTime?.minute ?? 0,
      );

      if (scheduledDateTime.isBefore(DateTime.now())) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.notificationId!,
          channelKey: 'basic_channel',
          title: 'Alarme: ${reminder.eventName}',
          body: reminder.notes ?? 'Seu alarme está tocando',
          payload: {
            'reminder': reminder.toJson(),
          },
          displayOnForeground: true,
          displayOnBackground: true,
          fullScreenIntent: true,
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
          criticalAlert: true,
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDateTime,
          preciseAlarm: true,
          repeats: false,
        ),
      );
    }
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
        title: const Text('Criar Lembrete', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
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
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/logo_notext.png',
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nome do Evento (Lembrete)',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    Text(
                      'Data',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    Text(
                      'Alarme',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    Text(
                      'Repetir alarme todos os dias?',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    Text(
                      'Deseja tirar uma foto?',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
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
                      Text(
                        'Clique no ícone abaixo para tirar uma foto',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
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
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.height * 0.3,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.height * 0.3,
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
                        onPressed: _isSaving ? null : _saveReminder, // Desabilita o botão se estiver salvando
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.15,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: _isSaving
                              ? Colors.grey // Altera a cor do botão quando desabilitado
                              : const Color.fromARGB(255, 76, 175, 125),
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text('Adicionar Lembrete'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
