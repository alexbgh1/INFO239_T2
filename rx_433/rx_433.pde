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
      for (int i = 0; i < 7; i++) {
        mensaje[i] = (char)buf[i + 9];
      }
      mensaje[7] = '\0';

      // =========== MENSAJE ===========
      // Imprimimos el mensaje
      Serial.print(secuencia);
      Serial.print(" Mensaje recibido: ");
      Serial.print(mensaje);

      Serial.println();

      digitalWrite(13, LOW);  // Apagar el LED o indicador
}

// Función que imprime 'analítica' del mensaje
void imprimirPaquetes(byte paquetes_recibidos, byte total_paquetes) {

      Serial.print("Paquete duplicado ");
      Serial.print(paquetes_recibidos);
      Serial.print("/");
      Serial.print(total_paquetes);
      Serial.println();
}

void loop() {
  uint8_t buf[VW_MAX_MESSAGE_LEN];
  uint8_t buflen = VW_MAX_MESSAGE_LEN;

  if (vw_get_message(buf, &buflen)) {
    digitalWrite(13, HIGH);  // Encender el LED o indicador para indicar la recepción de mensajes

    // Verificamos ORIGEN [0..1]
    // Verificamos DESTINO [2..3]
    // En caso de ser '00' se considerará como un BROADCAST

    if (buf[0] == 0 && buf[1] == 0) {
      Serial.println("Recibiendo Broadcast");
    }
    else {
      // =========== ORIGEN ===========
      if (buf[0] != ORIGEN[0] || buf[1] != ORIGEN[1]) {
        Serial.println("Origen incorrecto");
        return;
      }

      // =========== DESTINO ===========
      if (buf[2] != DESTINO[0] || buf[3] != DESTINO[1]) {
        Serial.println("Destino incorrecto");
        return;
      }
      
      // =========== CRC ===========

      // =========== SECUENCIA ===========
      // Secuencia tiene 2 bytes
      // Imprimimos Secuencia [6..7] y 'Mensaje recibido'
      int secuencia = buf[6] * 256 + buf[7];

      // =========== TOTAL_PAQUETES =========
      // Se espera que Total de paquetes [8] sea la cantidad de paquetes que se enviarán
      byte total_paquetes = buf[8];

      // =========== PAQUETES_RECIBIDOS =========
      // imprimirPaquetes(paquetes_recibidos, total_paquetes);

      // =========== MENSAJE ===========
      imprimirMensaje(buf, secuencia);
    }

  }
}


// #include <VirtualWire.h>
// // Receptor

// void setup(){
//     Serial.begin(9600);
    
//     vw_set_ptt_inverted(true); 
//     vw_setup(2000);
//     vw_set_rx_pin(2);
//     vw_rx_start();
// }

// void loop(){
//   uint8_t buf[VW_MAX_MESSAGE_LEN];
//   uint8_t buflen = VW_MAX_MESSAGE_LEN;

//   if (vw_get_message(buf, &buflen)){
//       char m[5]="H";                                                                                                                                                                                                                                                                                                                                            
// 	int i;
//   digitalWrite(13, true);
// 	for (i = 0; i <=5; i++){
// 	    m[i] = (char)buf[i];
// 	}
//   Serial.print("Mensaje Recibido g40 = ");
//   Serial.println(m);
//   digitalWrite(13, false);
//   }
// }
