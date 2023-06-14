/*
ver ::cl 20120520
Configuracion basica para modulo receptor  RR 10
Utiliza libreria VirtualWire.h
pin 01 5v
pin 02 Tierra
pin 03 antena externa
pin 07 tierra
pin 10 5v
pin 11 tierra
pin 12 5v
pin 14 Arduino pin digital 2
pin 15 5v
*/

#include <VirtualWire.h>

// Declaramos ORIGEN/DESTINO esperado
// Asumiendo que somos GRUPO 9, se espera que los primeros 2 bytes sean 0 y 9
byte ORIGEN[2] = {0, 9};
byte DESTINO[2] = {0, 9};
uint8_t CRC[2] = {0b00000000, 0b00000000}; // DEFAULT: 0

void setup() {
  Serial.begin(9600);
  
  vw_set_ptt_inverted(true);
  vw_setup(2000);
  vw_set_rx_pin(2);
  vw_rx_start();

  pinMode(13, OUTPUT);  // Configurar el pin 13 como salida para indicar la recepción de mensajes

}

// Función que imprime el mensaje
void imprimirMensaje(uint8_t buf[VW_MAX_MESSAGE_LEN], int secuencia) {

      // =========== MENSAJE ===========
      char mensaje[8];
      for (int i = 0; i < 8; i++) {
        mensaje[i] = buf[i + 8];
      }
      // =========== MENSAJE ===========
      // Imprimimos el mensaje
      Serial.print(secuencia);
      Serial.print(" Mensaje recibido: ");
      Serial.print(mensaje);

      Serial.println();

      digitalWrite(13, LOW);  // Apagar el LED o indicador
}

boolean calcularCRC(uint8_t message[VW_MAX_MESSAGE_LEN]) {
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
    CRC[1] += (Res[i] - '0') << (4-i);
  }

  // Verificamos el CRC calculado, con el de buf[4..5]
  // - Si son iguales, entonces el mensaje es correcto
  // - Si son diferentes, entonces el mensaje es incorrecto

  if (CRC[0] == message[4] && CRC[1] == message[5]) {
    Serial.println("CRC correcto");
    return true;
  } else {
    return false;
  }
}


void loop() {
  uint8_t buf[VW_MAX_MESSAGE_LEN];
  uint8_t buflen = VW_MAX_MESSAGE_LEN;

  if (vw_get_message(buf, &buflen)) {
    digitalWrite(13, HIGH);  // Encender el LED o indicador para indicar la recepción de mensajes

    // Solo aceptamos:
    // - Mensajes con ORIGEN/DESTINO: ENVIO: 00/00 LOCAL: 00/00
    // - Mensajes con ORIGEN/DESTINO: ENVIO: 09/09 LOCAL: 09/09
    
    if(((buf[0] == 0 && buf[1] == 0) && (buf[2] == 0 && buf[3] == 0)) || ((buf[0] == ORIGEN[0] && buf[1] == ORIGEN[1]) && (buf[2] == DESTINO[0] && buf[3] == DESTINO[1])) ){
      // =========== CRC ===========
      // CRC tiene 2 bytes [4..5]
      boolean crcCorrecto = calcularCRC(buf);
      // if (!crcCorrecto) {
      //   Serial.println("CRC incorrecto (mensaje descartado)");
      //   return;
      // }

      // =========== SECUENCIA ===========
      // =========== PAQUETES_RECIBIDOS =========
      // =========== MENSAJE ===========
      imprimirMensaje(buf, buf[6]);
    }
    else {
      Serial.println("Origen o Destino incorrecto");
    }
  }
}