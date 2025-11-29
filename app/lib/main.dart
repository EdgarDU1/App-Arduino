import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() => runApp(ArduinoControl());

class ArduinoControl extends StatelessWidget {
  const ArduinoControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control ESP32 Domótica',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ControlPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // IP por defecto de ESP32 
  String esp32IpAddress = '192.168.4.1'; 

  bool isConnected = false; 
  String responseText = "Introduce la IP y presiona 'Conexión'.";
  
  // Controlador para el campo de texto de la IP
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = esp32IpAddress;
  }

  Future<void> testConnection() async {
    setState(() {
      esp32IpAddress = _ipController.text.trim();
      responseText = "Conectando a $esp32IpAddress...";
      isConnected = false;
    });

    try {
      final url = Uri.parse('http://$esp32IpAddress/status');
      // Timeout bajo para detectar rápidamente si el ESP32 no está en la red
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
          responseText = "✅ Conexión exitosa a ESP32";
        });
      } else {
        setState(() {
          isConnected = false;
          responseText = "❌ Conexión no establecida. Código de estado ${response.statusCode}.";
        });
      }
    } on TimeoutException {
      setState(() {
        isConnected = false;
        responseText = "❌ Conexión no establecida. Error: Tiempo de espera agotado. Verifica la IP y la red Wi-Fi.";
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        responseText = "❌ Conexión no establecida. Error de red.";
      });
    }
  }

  // Enviar comandos HTTP GET al ESP32
  Future<void> sendCommand(String command, {String loadingMessage = ""}) async {
    if (!isConnected) {
      setState(() {
        responseText = "❌ Error: Conéctate primero.";
      });
      return; 
    }

    setState(() {
      responseText = loadingMessage.isNotEmpty ? loadingMessage : "Enviando comando '$command'...";
    });

    try {
      final url = Uri.parse('http://$esp32IpAddress/$command');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String friendlyMessage = _getFriendlyResponseMessage(command, response.body);
        setState(() {
          responseText = friendlyMessage;
        });
      } else {
        setState(() {
          responseText = "❌ Error: El ESP32 devolvió el código ${response.statusCode}.";
        });
      }
    } catch (e) {
      setState(() {
        responseText = "❌ Error de comunicación. Verifica el Wi-Fi.";
      });
    }
  }

  String _getFriendlyResponseMessage(String command, String espResponse) {
    if (command == "LED_ON") {
      return "💡 Foco Encendido con éxito.";
    } else if (command == "LED_OFF") {
      return "💡 Foco Apagado.";
    } else if (command == "PUMP_ON") {
      return "💧 Bomba de Agua activada.";
    } else if (command == "PUMP_OFF") {
      return "💧 Bomba de Agua desactivada.";
    } else if (command == "READ_TEMP") {
      return "🌡️ Lectura de Sensor: ${espResponse}";
    }
    
    return "✅ ESP32 respondió: $espResponse"; 
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ARDUINO CONTROL", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            // Configuración de IP y Conexión
            _buildConnectionSection(),
            
            const Divider(height: 40), 

            // Control de Foco
            _buildControlSection(
              title: "Control de Luz",
              color: Colors.amber[800]!,
              iconOn: Icons.lightbulb_outline,
              iconOff: Icons.lightbulb_outline, 
              commandOn: "LED_ON",
              commandOff: "LED_OFF",
              labelOn: "Encender Foco",
              labelOff: "Apagar Foco",
            ),

            const Divider(height: 30), 

            // Control de Bomba
            _buildControlSection(
              title: "Control de Bomba",
              color: Colors.blue[800]!,
              iconOn: Icons.water_drop_outlined,
              iconOff: Icons.water_drop, 
              commandOn: "PUMP_ON",
              commandOff: "PUMP_OFF",
              labelOn: "Encender Bomba",
              labelOff: "Apagar Bomba",
            ),

            const Divider(height: 30), 

            // Lectura de Sensor
            _buildSensorSection(),
            
            const SizedBox(height: 40),
            
            // Respuesta del ESP32
            _buildResponseSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      children: [
        TextField(
          controller: _ipController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Dirección IP del ESP32',
            hintText: '192.168.4.1 (por defecto en modo AP)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 19),
        ElevatedButton.icon(
          icon: Icon(isConnected ? Icons.check_circle : Icons.power_settings_new),
          label: Text(
            isConnected ? "Conectado" : "Conexión",
            style: const TextStyle(fontSize: 15), // Aumenta el tamaño del texto
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: isConnected ? Colors.teal : Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: testConnection, 
        ),
      ],
    );
  }

  Widget _buildControlSection({
    required String title,
    required Color color,
    required IconData iconOn,
    required IconData iconOff,
    required String commandOn,
    required String commandOff,
    required String labelOn,
    required String labelOff,
  }) {
    // Esta sección usa el color y los iconos para dar una estética limpia
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _CommandButton(
                label: labelOn,
                command: commandOn,
                onPressed: isConnected ? () => sendCommand(commandOn) : null,
                color: color,
                icon: iconOn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CommandButton(
                label: labelOff,
                command: commandOff,
                onPressed: isConnected ? () => sendCommand(commandOff) : null,
                color: Colors.grey.shade600,
                icon: iconOff,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Lectura de Temperatura y Humedad",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        _CommandButton(
          label: "Leer Humedad y Temperatura",
          command: "READ_TEMP", 
          onPressed: isConnected 
              ? () => sendCommand("READ_TEMP", loadingMessage: "Obteniendo datos del sensor...") 
              : null,
          color: Colors.green.shade600,
          icon: Icons.thermostat_outlined,
        ),
      ],
    );
  }

  Widget _buildResponseSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isConnected ? Colors.teal : Colors.grey, width: 2),
      ),
      child: Text(
        responseText,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo.shade900),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Widget auxiliar modificado para incluir iconos y estilo
class _CommandButton extends StatelessWidget {
  final String label;
  final String command;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  const _CommandButton({
    required this.label,
    required this.command,
    required this.onPressed,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_right_alt, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        backgroundColor: color.withOpacity(onPressed != null ? 1.0 : 0.4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),
    );
  }
}