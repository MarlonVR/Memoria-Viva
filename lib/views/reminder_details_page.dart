import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/Reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderDetailsPage extends StatefulWidget {
  final Reminder reminder;
  final int index;

  const ReminderDetailsPage({super.key, required this.reminder, required this.index});

  @override
  _ReminderDetailsPageState createState() => _ReminderDetailsPageState();
}

class _ReminderDetailsPageState extends State<ReminderDetailsPage> {
  late TextEditingController _eventNameController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedAlarmTime;
  String? _selectedImagePath;
  bool repetir = false;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(text: widget.reminder.eventName);
    _notesController = TextEditingController(text: widget.reminder.notes);
    _selectedDate = widget.reminder.date;
    _selectedAlarmTime = widget.reminder.alarmTime;
    _selectedImagePath = widget.reminder.imagePath;
    repetir = widget.reminder.repeat;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Impede a seleção de datas anteriores ao dia atual
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectAlarmTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedAlarmTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedAlarmTime) {
      setState(() {
        _selectedAlarmTime = pickedTime;
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

  Future<void> _saveReminder() async {
    final updatedReminder = Reminder(
      eventName: _eventNameController.text,
      date: _selectedDate ?? DateTime.now(),
      repeat: repetir,
      notes: _notesController.text,
      alarmTime: _selectedAlarmTime,
      imagePath: _selectedImagePath,
      notificationId: widget.reminder.notificationId, // Usar o mesmo ID de notificação
    );

    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    // Atualizar o lembrete na lista com base no índice
    reminderList[widget.index] = updatedReminder.toJson();
    await prefs.setStringList('reminders', reminderList);

    // Cancelar a notificação antiga associada ao lembrete usando o ID de notificação existente
    await AwesomeNotifications().cancel(updatedReminder.notificationId!);

    // Reagendar a notificação com os novos dados
    _scheduleNotification(updatedReminder);

    Navigator.pop(context, updatedReminder);
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    DateTime scheduledDateTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.alarmTime?.hour ?? 0,
      reminder.alarmTime?.minute ?? 0,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
    }

    // Criar uma nova notificação usando o mesmo ID de notificação para atualizar os dados
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
        repeats: reminder.repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Lembrete',style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3), // Gradiente com azul
              Color(0xFFF5F5DC),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exibe a imagem ou um ícone padrão
                Center(
                  child: GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(4, 6),
                          ),
                        ],
                        image: _selectedImagePath != null
                            ? DecorationImage(
                          image: _selectedImagePath!.startsWith('assets/')
                              ? AssetImage(_selectedImagePath!) as ImageProvider
                              : FileImage(File(_selectedImagePath!)),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _selectedImagePath == null
                          ? const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Nome do Evento
                const Text(
                  'Nome do Evento',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _eventNameController,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                ),
                const SizedBox(height: 30),

                // Data do Evento
                const Text(
                  'Data do Evento',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Selecione a data',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Alarme
                const Text(
                  'Hora do Alarme',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectAlarmTime(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
                      _selectedAlarmTime != null
                          ? _selectedAlarmTime!.format(context)
                          : 'Selecione a hora do alarme',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Repetir
                const Text(
                  'Repetir?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                          color: repetir ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: repetir ? Colors.green : Colors.grey,
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
                          repetir = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: repetir ? Colors.grey[300] : Colors.red,
                          border: Border.all(
                            color: repetir ? Colors.grey : Colors.red,
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

                // Observações
                const Text(
                  'Observações',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  ),
                ),
                const SizedBox(height: 40),


                Center(
                  child: ElevatedButton(
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: const Color.fromARGB(255, 76, 175, 125),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Salvar Alterações',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
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
