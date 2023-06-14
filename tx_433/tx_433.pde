/*
ver ::cl 20120520
Configuracion basica para modulo transmisor RT 11
Utiliza libreria VirtualWire.h
pin 01 entrada desde Arduino pin digital 2
pin 02 Tierra
pin 07 tierra
pin 08 antena externa
pin 09 tierra
pin 10 5v
*/

#include <VirtualWire.h>

uint8_t message[16];  // Se declara un arreglo de 16 elementos para representar los 16 bytes del mensaje

// Declaramos ORIGEN/DESTINO esperado
// Asumiendo que somos GRUPO 9, se espera que los primeros 2 bytes sean 0 y 9
uint8_t ORIGEN[2] = {0b00000000, 0b00001001}; // 0
uint8_t DESTINO[2] = {0b00000000, 0b00001001}; // 9
uint8_t CRC[2] = {0b00000000, 0b00000000}; // DEFAULT: 0
uint8_t secuencia[2] = {0b00000000, 0b00000001}; // DEFAULT: 1, Corresponde a "i" veces hasta "TOTAL_PAQUETES"
uint8_t TOTAL_PAQUETES = 0b00000101; // DEFAULT: Se envia 5 veces
uint8_t MENSAJE[8] = {  // "G 09": 01000111 00100000 00110000 00111001
  0b01000111, // "G"
  0b00100000, // " "
  0b00110000, // "0"
  0b00111001, // "9"
  0b00000000, // ""
  0b00000000, // ""
  0b00000000, // ""
};

void setup() {
  vw_set_ptt_inverted(true);
  vw_set_tx_pin(2);
  vw_setup(2000);
  Serial.begin(9600);

  // Asignar los bytes del mensaj
  // ORIGEN
  message[0] = ORIGEN[0];
  message[1] = ORIGEN[1];
  // DESTINO
  message[2] = DESTINO[0];
  message[3] = DESTINO[1];
  // CRC
  message[4] = CRC[0];
  message[5] = CRC[1];
  // SECUENCIA
  message[6] = secuencia[0];
  message[7] = secuencia[1];
  // TOTAL DE PAQUETES
  message[8] = TOTAL_PAQUETES;
  // MENSAJE (8 bytes)
  for (int i = 0; i < 8; i++) {
    message[9 + i] = MENSAJE[i];
  }

  calcularCRC();

  // Asignación de los bits del CRC al mensaje
  Serial.println("Configurando envío");
}

void calcularCRC() {
  // Cálculo del CRC-5-USB
  // - Consideramos que CRC utiliza hasta 2 bytes
  // - Se hará CRC al mensaje message[9..16]
  // - Se asignará el resultado a CRC[0..1]
  // Inicializamos el CRC en 0
  uint16_t crc = 0;
  // - El primer for recorre los 8 bytes del mensaje
  for (int i = 9; i < 16; i++) {
    crc ^= message[i];
    // - El segundo for recorre los 8 bits de cada byte
    for (int j = 0; j < 8; j++) {
      if (crc & 0x80) {
        crc = (crc << 1) ^ 0x05;
      } else {
        crc <<= 1;
      }
    }
  }

  // Asignamos el resultado del CRC al mensaje
  // CRC[0] contiene los primeros 8 bits del CRC
  // CRC[1] contiene los últimos 8 bits del CRC
  CRC[0] = crc;
  CRC[1] = crc >> 8;
  message[4] = CRC[0];
  message[5] = CRC[1];

  // Mostramos CRC como binario
  // Serial.println("CRC: " + String(CRC[0], BIN) +" "+ String(CRC[1], BIN));
  // Serial.println("crc: " + String(crc, BIN));
}

// Creamos una función para SECUENCIA
void aumentaSecuencia() {
  // SECUENCIA

  secuencia[1] += 1;
  // Si el segundo byte de la secuencia es 0, incrementamos el primero
  // Esta condición ocurre al llegar al límite de 255
  if (secuencia[1] == 0) {
    secuencia[0] += 1;
  }
  message[6] = secuencia[0];
  message[7] = secuencia[1];

}

void loop() {

  
  // =========== TOTAL DE PAQUETES ===========
  // Enviar el mensaje <Total de paquetes> veces
  for (int i = 1; i < TOTAL_PAQUETES+1; i++) {
    // =========== CRC ===========
    calcularCRC();
    vw_send(message, 16);
    vw_wait_tx();
    Serial.println("Mensaje enviado, SEC: " + String(secuencia[0]) + String(secuencia[1]));
    delay(1000);
    // =========== SECUENCIA ===========
    aumentaSecuencia(); // secuencia++
  }

  // ======== RESET SECUENCIA =========
  secuencia[0] = 0b00000000;
  secuencia[1] = 0b00000001;
  message[6] = secuencia[0];
  message[7] = secuencia[1];
}