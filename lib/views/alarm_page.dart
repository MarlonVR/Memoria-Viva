import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memoriaviva/models/Reminder.dart';
import 'package:memoriaviva/views/home_page.dart';
import 'dart:io';

class AlarmPage extends StatefulWidget {
  final Reminder reminder;

  const AlarmPage({Key? key, required this.reminder}) : super(key: key);

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    _audioPlayer = AudioPlayer();

    try {
      await _audioPlayer.setAsset('assets/sounds/alarm_sound.mp3');
      _audioPlayer.setLoopMode(LoopMode.one); // Colocar o som em loop
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Erro ao tocar o som do alarme: $e");
    }
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });

    // Navegar para a HomePage após parar o alarme
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Memória Viva')),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarme', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.reminder.eventName,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Exibir a imagem, se houver
                      if (widget.reminder.imagePath != null && widget.reminder.imagePath!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Image.file(
                            File(widget.reminder.imagePath!),
                            height: MediaQuery.of(context).size.height * 0.3,
                            fit: BoxFit.cover,
                          ),
                        ),

                      if (widget.reminder.notes != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                          child: Text(
                            widget.reminder.notes!,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: _stopAlarm,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.2,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                          textStyle: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Parar Alarme'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
