// Enviando dados via http com tasks no freertos
// Kaique Almeida
// 22/06/2022

//Bibliotecas para conexão na rede********************************

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiMulti.h>
#include <HTTPClient.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

//Bibliotecas para o sensor e o display lcd ********************************
#include <DHT.h>
#include <LiquidCrystal_I2C.h>
#define DHT_SENSOR_PIN 32 // ESP32 pin GIOP23 connected to DHT22 sensor
#define DHT_SENSOR_TYPE DHT22

// Instâncias de objetos e declaração de variáveis
LiquidCrystal_I2C lcd(0x27, 16, 2);  // I2C address 0x3F, 16 column and 2 rows
DHT dht_sensor(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);

WiFiMulti wifiMulti;
HTTPClient http;

char dado[1024];
String json;
int flag;

//Diretivas para armazenar informações de login

#define WIFISSID "Teste24"
#define PASSWORD "12345678"

//Funções*************************************************************

void setup()
{
  Serial.begin(9600);
  lcd.init(); 
  lcd.clear();
  lcd.backlight();
  
  for(uint8_t t = 3; t > 0; t--)
  {
    Serial.print("Inicializando em  ");
    Serial.println(t);
    delay(1000);
    }

  Serial.println("Equipe NODA_MCU");
  lcd.setCursor(0, 0);
  lcd.print("Equipe");
  lcd.setCursor(3, 1);
  lcd.print("NODA_MCU"); 

  delay(5000);

  Serial.println("Iniciando sensor . . .");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Iniciando");
  lcd.setCursor(3, 1);
  lcd.print("sensor . . . ");
  
  dht_sensor.begin(); 
  delay(3000);
  
  Serial.println("Iniciando conexão wifi . . .");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Iniciando");
  lcd.setCursor(0, 1);
  lcd.print("conexao wifi . . .");
  
  wifiMulti.addAP(WIFISSID,PASSWORD); // conecta a rede wifi
  delay(5000);
  
  if( (wifiMulti.run() == WL_CONNECTED) ){
    Serial.println("Wifi conectado");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wifi");
    lcd.setCursor(3, 1);
    lcd.print("conectado ! ");
    flag = 1;

    delay(2000);
    }
  
  else {

    Serial.println("Sem conexão Wifi");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Sem");
    lcd.setCursor(3, 1);
    lcd.print(" Wifi ! ");  
    flag = 0;
    delay (3000);    
    
    }  

    Serial.println("Iniciando Leituras . . .");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Iniciando");
    lcd.setCursor(3, 1);
    lcd.print("leituras . . . ");
    delay(5000);
    
  
  }

void loop(){

    
   float humi  = 0; 
   float tempC = 0; 

   float auxhumi  = 0; 
   float auxtempC = 0; 

   humi  = dht_sensor.readHumidity();    // read humidity
   tempC = dht_sensor.readTemperature(); // read temperature

  if (isnan(tempC) || isnan(humi)) {
    Serial.println("Sensor falhou . . .");
    lcd.setCursor(0, 0);
    lcd.print("Failed");
  } 
  else if (((tempC && humi <= 5)))
  
  {
    delay(3000);
    humi  = dht_sensor.readHumidity();    // read humidity
    tempC = dht_sensor.readTemperature();
    
    }
  
  else{
    Serial.print("Temp: ");
    Serial.print(tempC);
    Serial.println("ºC");

    Serial.print("Um: ");
    Serial.print(humi);
    Serial.println("%");

    lcd.clear(); 
    lcd.setCursor(0, 0);  // display position
    lcd.print("T:");
    lcd.print(tempC);     // display the temperature
    lcd.print("C");

    lcd.setCursor(0, 1);  // display position
    lcd.print("H:");
    lcd.print(humi);      // display the humidity
    lcd.print("%");

    if (flag == 1){

    lcd.setCursor(9, 1);  // display position
    lcd.print("online");   
      }
    else{
    lcd.setCursor(9, 1);  // display position
    lcd.print("offline");  
      }
    }
// Calcula média de leituras para o envio*******************************************************************8
   Serial.println("Coletando Leituras para envio da média . . .");
   for (int j = 0; j < 60; j++)
      {
      
      humi = dht_sensor.readHumidity();
      tempC = dht_sensor.readTemperature();

      if (((tempC && humi <= 5) && (auxhumi == 0)) || (isnan(tempC) || isnan(humi))) {

        delay(5000);
        Serial.println("Corrigindo falha ...");
        humi = dht_sensor.readHumidity();
        tempC = dht_sensor.readTemperature(); 
          
        }
      
      else if(((tempC && humi <= 5)) || (isnan(tempC) || isnan(humi))){
        Serial.println("Corrigindo falha ...");
        humi = auxhumi / (j-1);
        tempC = auxtempC / (j-1);
        
 
            }

      
      
      auxhumi += humi;
      auxtempC += tempC; 
      Serial.print(j);
      Serial.print(" ");
      Serial.print("H: ");
      Serial.print(humi);
      Serial.print(" % ");
      Serial.print("T: ");
      Serial.print(tempC);
      Serial.println(" ºC");
        
      
      delay(1000);
      }
  auxhumi /= 60;
  auxtempC /= 60;

  Serial.println("Enviando leituras: ");
  Serial.print("H: ");
  Serial.print(auxhumi);
  Serial.print(" % ");
  Serial.print("T: ");
  Serial.print(auxtempC);
  Serial.println(" ºC");

  



      
      Serial.print("Iniciando HTTP...\n");
      

       http.begin("http://192.168.0.149:8080/api/v1/U2EfQDC7VtgYsg5EZb1M/telemetry");
       //http.begin("http://iothmlsice.ipt.br:8080/api/v1/wSlpPJpVXmmRY7iduw8j/telemetry");
       http.addHeader("Content-Type","application/json"); 
       http.addHeader("Connection","close");

       

      sprintf(dado, "{\"T\":%.2f, \"Um\":%.2f}", tempC, humi);
      json = dado;
      int httpCode = http.POST(json);
      
      //int httpCode = http.POST( "{\"TempC\":" + temp + "}");


    if(httpCode == 200)
    {
      Serial.printf( "Dado enviado com sucesso: %d\n", httpCode );
      Serial.println("Retorno do servidor = 200");
 
    }
       else {

      Serial.println("Falha no envio !!!");
      http.end(); 
            }  
    
}   
  


// 1 coleta por segundo
