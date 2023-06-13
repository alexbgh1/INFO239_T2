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
uint8_t secuencia[2] = {0b00000000, 0b00000000}; // DEFAULT: 0
uint8_t TOTAL_PAQUETES = 0b00000100; // DEFAULT: 4
uint8_t MENSAJE[8] = { 
  0b01100001, // a
  0b01100010, // b
  0b01100011, // c
  0b01100100, // d
  0b01100101, // e
  0b01100110, // f
  0b01100111, // g
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

  // Cálculo del CRC-5-USB


  // Asignación de los bits del CRC al mensaje
  Serial.println("Configurando envío");
}

// Creamos una función para SECUENCIA
void aumentaSecuencia() {
  // SECUENCIA
  message[6] = secuencia[0];
  message[7] = secuencia[1];
  secuencia[1] += 1;
  // Si el segundo byte de la secuencia es 0, incrementamos el primero
  // Esta condición ocurre al llegar al límite de 255
  if (secuencia[1] == 0) {
    secuencia[0] += 1;
  }
}

void loop() {

  
  // =========== TOTAL DE PAQUETES ===========
  // Enviar el mensaje <Total de paquetes> veces
  for (int i = 0; i < TOTAL_PAQUETES; i++) {
    vw_send(message, 16);
    vw_wait_tx();
    delay(1000);
    Serial.println("Mensaje enviado");
  }

  // =========== SECUENCIA ===========
  aumentaSecuencia();
}

// #include <VirtualWire.h>
// const char *msg = "H";
// uint8_t mssg[16];

// void setup(){
//   vw_set_ptt_inverted(true);
//   vw_setup(2000);
//   vw_set_tx_pin(2);    
//   Serial.begin(9600);
//   Serial.println("configurando envio");
// }
// void loop(){
//   msg = "Labo 2";
//   vw_send((uint8_t *)msg, strlen(msg));
//   vw_wait_tx();
//   delay(1000);
//   Serial.println("mensaje enviado g40");
   
// }
