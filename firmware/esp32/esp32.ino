#include <WiFi.h>
#include <WebServer.h>
#include "DHT.h" 

const char* ssid = "ESp_32.l."; // Nombre de la red Wi-Fi
const char* password = "123456789"; // Contraseña de la red (mínimo 8 caracteres)

// Crea el objeto del servidor web en el puerto 80
WebServer server(80);

// CONFIGURACIÓN DE HARDWARE Y PINES 
const int LED_PIN = 2; 
const int BOMBA_PIN = 4;
const int DHT_PIN = 15; 
#define DHTTYPE DHT11 

// Inicializa el sensor DHT
DHT dht(DHT_PIN, DHTTYPE);

// Manejo del led(foco)
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

// Maneja Bomba de Agua
void handlePumpOn() {
  digitalWrite(BOMBA_PIN, LOW); 
  Serial.println("-> Bomba Encendida");
  server.send(200, "text/plain", "Bomba Encendida OK");
}
void handlePumpOff() {
  digitalWrite(BOMBA_PIN, HIGH); 
  Serial.println("-> Bomba Apagada");
  server.send(200, "text/plain", "Bomba Apagada OK");
}

// Manejo del DTH
void handleReadDht() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
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

// Prueba de conexion
void handleStatus() {
  server.send(200, "text/plain", "Servidor listo: Control, Foco y DHT.");
}

void handleNotFound() {
  server.send(404, "text/plain", "Error: Ruta no encontrada.");
}

void setup() {
  Serial.begin(115200);
  
  // Configuración de Pines de Salida (Foco y Bomba)
  pinMode(LED_PIN, OUTPUT);
  pinMode(BOMBA_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  digitalWrite(BOMBA_PIN, HIGH);
  
  // Ya que no usa resistencia el DTH
  pinMode(DHT_PIN, INPUT_PULLUP); 

  dht.begin();
  
  // Configura el ESP32 como Punto de Acceso (AP)
  Serial.print("Iniciando AP...");
  WiFi.softAP(ssid, password);
  
  IPAddress apIP = WiFi.softAPIP();
  Serial.print("IP del AP: ");
  Serial.println(apIP);

  // Define las Rutas del Servidor (Endpoints)
  server.on("/", handleStatus);         
  server.on("/status", handleStatus);   
  server.on("/LED_ON", handleLedOn);   
  server.on("/LED_OFF", handleLedOff);
  server.on("/PUMP_ON", handlePumpOn); 
  server.on("/PUMP_OFF", handlePumpOff); 
  server.on("/READ_TEMP", handleReadDht); // Ruta para obtener T y H

  server.onNotFound(handleNotFound); 

  server.begin();
  Serial.println("Servidor HTTP iniciado.");
}

void loop() {
  server.handleClient();
}
