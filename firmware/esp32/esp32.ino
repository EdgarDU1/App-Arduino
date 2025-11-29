// Librerías esenciales para Wi-Fi y Servidor Web
#include <WiFi.h>
#include <WebServer.h>

// Librerías para el sensor DHT
// **Requiere instalar la "DHT sensor library" y "Adafruit Unified Sensor"**
#include "DHT.h" 

// --- CONFIGURACIÓN DE ACCESO INALÁMBRICO (AP) ---
const char* ssid = "ESp_32.l."; // Nombre de la red Wi-Fi
const char* password = "123456789"; // Contraseña de la red (mínimo 8 caracteres)

// Crea el objeto del servidor web en el puerto 80
WebServer server(80);

// --- CONFIGURACIÓN DE HARDWARE Y PINES ---
// 1. PIN DE SALIDA: Foco (LED)
const int LED_PIN = 2; // GPIO 2 (Etiqueta P2 en tu placa)

// 2. PIN DE SALIDA: Bomba de Agua (conectada a un relé)
const int BOMBA_PIN = 4; // GPIO 4 (Etiqueta P4 en tu placa)

// 3. PIN DE ENTRADA: Sensor de Humedad y Temperatura (ARP-360)
const int DHT_PIN = 15; // GPIO 15 (Etiqueta G15 en tu placa)
#define DHTTYPE DHT11 // Configuramos para DHT22/ARP-360

// Inicializa el sensor DHT
DHT dht(DHT_PIN, DHTTYPE);

// =======================
// Funciones de Manejo (Handlers) - Controladores para la App
// =======================

// Maneja la URL /LED_ON y /LED_OFF (Foco)
void handleLedOn() {
  digitalWrite(LED_PIN, HIGH); 
  Serial.println("-> Foco Encendido");
  server.send(200, "text/plain", "Foco Encendido OK");
}
void handleLedOff() {
  digitalWrite(LED_PIN, LOW); 
  Serial.println("-> Foco Apagado");
  server.send(200, "text/plain", "Foco Apagado OK");
}

// Maneja la URL /PUMP_ON y /PUMP_OFF (Bomba)
void handlePumpOn() {
  // *** LÓGICA INVERTIDA: LOW ENCIENDE LA BOMBA ***
  digitalWrite(BOMBA_PIN, LOW); 
  Serial.println("-> Bomba Encendida");
  server.send(200, "text/plain", "Bomba Encendida OK");
}
void handlePumpOff() {
  // *** LÓGICA INVERTIDA: HIGH APAGA LA BOMBA ***
  digitalWrite(BOMBA_PIN, HIGH); 
  Serial.println("-> Bomba Apagada");
  server.send(200, "text/plain", "Bomba Apagada OK");
}

// Maneja la URL /READ_TEMP (Humedad y Temperatura Real)
void handleReadDht() {
  // 1. Lectura de los valores del sensor
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // 2. Comprobación de errores de lectura
  if (isnan(h) || isnan(t)) {
    Serial.println("-> Error al leer el sensor DHT!");
    server.send(500, "text/plain", "ERROR: Lectura de sensor fallida.");
    return;
  }

  // 3. Formatea la respuesta
  String respuesta = "TEMP: " + String(t, 1) + " C | HUM: " + String(h, 1) + " %";
  Serial.println("-> Lectura DHT: " + respuesta);
  server.send(200, "text/plain", respuesta);
}

// Maneja la URL /status (Prueba de conexión)
void handleStatus() {
  server.send(200, "text/plain", "Servidor listo: Control, Foco y DHT.");
}

// Maneja cualquier URL no definida (error 404)
void handleNotFound() {
  server.send(404, "text/plain", "Error: Ruta no encontrada.");
}

// =======================
// SETUP - Configuración de inicialización
// =======================
void setup() {
  Serial.begin(115200);
  
  // 1. Configuración de Pines de Salida (Foco y Bomba)
  pinMode(LED_PIN, OUTPUT);
  pinMode(BOMBA_PIN, OUTPUT);
  
  // ** CAMBIO CLAVE EN SETUP: APAGAR LA BOMBA USANDO HIGH **
  // Si tu relé es Active-LOW, HIGH la apaga al inicio
  digitalWrite(LED_PIN, LOW); // Foco (LED) sigue siendo lógica normal
  digitalWrite(BOMBA_PIN, HIGH); // Bomba se apaga al inicio con HIGH
  
  // ** SOLUCIÓN RÁPIDA: Activa la resistencia pull-up interna para el sensor DHT (G15) **
  // Esto elimina la necesidad de la resistencia externa de 4.7k ohm.
  pinMode(DHT_PIN, INPUT_PULLUP); 

  // 2. Inicializa el Sensor DHT
  dht.begin();
  
  // 3. Configura el ESP32 como Punto de Acceso (AP)
  Serial.print("Iniciando AP...");
  WiFi.softAP(ssid, password);
  
  IPAddress apIP = WiFi.softAPIP();
  Serial.print("IP del AP: ");
  Serial.println(apIP);

  // 4. Define las Rutas del Servidor (Endpoints)
  server.on("/", handleStatus);         
  server.on("/status", handleStatus);   
  server.on("/LED_ON", handleLedOn);   
  server.on("/LED_OFF", handleLedOff);
  server.on("/PUMP_ON", handlePumpOn); 
  server.on("/PUMP_OFF", handlePumpOff); 
  server.on("/READ_TEMP", handleReadDht); // Ruta para obtener T y H

  server.onNotFound(handleNotFound); 

  // 5. Inicia el servidor HTTP
  server.begin();
  Serial.println("Servidor HTTP iniciado.");
}

// =======================
// LOOP - Ejecución continua
// =======================
void loop() {
  server.handleClient();
}
