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
      firstDate: DateTime.now(),
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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.camera);

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
      notificationId: widget.reminder.notificationId,
    );

    // Atualizar a lista de lembretes no SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> reminderList = prefs.getStringList('reminders') ?? [];

    reminderList[widget.index] = updatedReminder.toJson();
    await prefs.setStringList('reminders', reminderList);

    await AwesomeNotifications().cancel(updatedReminder.notificationId!);
    _scheduleNotification(updatedReminder);
    Navigator.pop(context, updatedReminder);
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Lembrete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 76, 175, 125),
      ),
      body: Container(
        width: screenWidth,
        height: screenHeight,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exibe a imagem ou ícone
                Center(
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: screenWidth,
                      height: screenHeight * 0.3,
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
                          Icons.camera_alt,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Nome do Evento
                Text(
                  'Nome do Evento',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _eventNameController,
                  style: TextStyle(fontSize: screenWidth * 0.05),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.025,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Data do Evento
                Text(
                  'Data do Evento',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.01),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.025,
                      horizontal: screenWidth * 0.04,
                    ),
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
                      style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Alarme
                Text(
                  'Hora do Alarme',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.01),
                GestureDetector(
                  onTap: () => _selectAlarmTime(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.025,
                      horizontal: screenWidth * 0.04,
                    ),
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
                      style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Repetir
                Text(
                  'Repetir alarme todos os dias?',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.01),
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
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: repetir ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: repetir ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Sim',
                          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          repetir = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: repetir ? Colors.grey[300] : Colors.red,
                          border: Border.all(
                            color: repetir ? Colors.grey : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Não',
                          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Observações
                Text(
                  'Observações',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: TextStyle(fontSize: screenWidth * 0.05),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.025,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                Center(
                  child: ElevatedButton(
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15,
                        vertical: screenHeight * 0.03,
                      ),
                      textStyle: TextStyle(fontSize: screenWidth * 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: const Color.fromARGB(255, 76, 175, 125),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Salvar Alterações',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
