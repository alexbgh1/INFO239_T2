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
uint8_t secuencia = 0b00000001; // DEFAULT: 1, Corresponde a "i" veces hasta "TOTAL_PAQUETES"
uint8_t TOTAL_PAQUETES = 0b00000101; // DEFAULT: Se envia 5 veces
uint8_t MENSAJE[8] = {  // "G 09": 01000111 00100000 00110000 00111001
  0b01000111, // "G"
  0b00100000, // " "
  0b00110000, // "0"
  0b00111001, // "9"  // "2" 00110010
  0b00000000, // ""
  0b00000000, // ""
  0b00000000, // ""
  0b01000111, // ""
  // 0b01100001, // "a"
  // 0b01100001, // "a"
  // 0b01100001, // "a"
  // 0b01100001, // "a"
};
//0100011100100000001100000011100100000000000000000000000001000111

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
  message[6] = secuencia;
  // TOTAL DE PAQUETES
  message[7] = TOTAL_PAQUETES;
  // MENSAJE (8 bytes)
  for (int i = 0; i < 8; i++) {
    message[i+8] = MENSAJE[i];
  }

  calcularCRC();

  // Asignación de los bits del CRC al mensaje
  Serial.println("Configurando envío");
}

void mostrarMSGbin() {
  // Mostramos el mensaje en binario
  Serial.println("Mensaje: ");
  for (int i = 0; i < 16; i++) {
    Serial.print(String(message[i], BIN) + " ");
  }
  Serial.println();
}

void calcularCRC() {
  // Cálculo del CRC-5-USB
  // - Consideramos que CRC utiliza hasta 2 bytes
  // - Se hará CRC al mensaje message[9..16]
  // - Se asignará el resultado a CRC[0..1]
  // Inicializamos el CRC en 0

  // Conseguimos todos los binarios del mensaje [8..15]
  uint8_t binarios[64];
  // Dejamos los bits ordenados de izquierda a derecha
  for (int i = 0; i < 8; i++) {
    for (int bit = 0; bit < 8; bit++) {
      binarios[i*8+bit] = (message[i+8] >> (7-bit)) & 0x01;
    }
  }

  // CODIGO EXTRAÍDO DESDE
  // https://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/index.php?Polynom=100101&Message=4720303900000047

  char Res[6];                                 // CRC Result
  char CRCIMP[5];
  int  i;
  char DoInvert;

  for (i=0; i<5; ++i)  CRCIMP[i] = 0;                    // Init before calculation

  for (i=0; i<64; ++i)
    {
    DoInvert = (binarios[i] == 1) ^ CRCIMP[4];         // XOR required?

    CRCIMP[4] = CRCIMP[3];
    CRCIMP[3] = CRCIMP[2];
    CRCIMP[2] = CRCIMP[1] ^ DoInvert;
    CRCIMP[1] = CRCIMP[0];
    CRCIMP[0] = DoInvert;
    }

  for (i=0; i<5; ++i)  Res[4-i] = CRCIMP[i] ? '1' : '0'; // Convert binary to ASCII
  Res[5] = 0;                                         // Set string terminator

  Serial.println(Res);

  // Asignamos el valor binario a CRC en message[5]
  // message[5] almacenará los 5 bits de CRC
  for (int i = 0; i < 5; i++) {
    message[4] += (Res[i] - '0') << (4-i);
  }
}

// Creamos una función para SECUENCIA
void aumentaSecuencia() {
  // SECUENCIA
  secuencia += 1;
  message[6] = secuencia;
}

void loop() {

  
  // =========== TOTAL DE PAQUETES ===========
  // Enviar el mensaje <Total de paquetes> veces
  for (int i = 1; i < message[7]+1; i++) {
    // =========== CRC ===========
    calcularCRC();
    vw_send(message, 16);
    vw_wait_tx();
    Serial.println("Mensaje enviado, SEC: " + String(secuencia));
    delay(1000);
    // =========== SECUENCIA ===========
    aumentaSecuencia(); // secuencia++
  }

  // ======== RESET SECUENCIA =========
  secuencia = 0b00000001;
  message[6] = secuencia;
}