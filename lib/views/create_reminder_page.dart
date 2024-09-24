import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Função para mostrar o calendário de seleção de data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      // Removido o parâmetro 'locale'
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
      // Removido o parâmetro 'locale'
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
                const TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Digite o nome do evento',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(fontSize: 18),
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
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy', 'pt_BR').format(selectedDate!)
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: repetir == true ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: repetir == true ? Colors.green : Colors.grey,
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: repetir == false ? Colors.red : Colors.grey[300],
                          border: Border.all(
                            color: repetir == false ? Colors.red : Colors.grey,
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
                const TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Digite observações adicionais',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  style: TextStyle(fontSize: 18),
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
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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

                // Botão de Adicionar
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Adicionar lógica para salvar o lembrete
                      Navigator.pop(context); // Voltar para a tela anterior
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
