#include <WiServer.h>
#include <OneWire.h>
#include <DallasTemperature.h>


#define WIRELESS_MODE_INFRA 1
#define WIRELESS_MODE_ADHOC 2

#define RELAY_PIN 9
#define ONE_WIRE_BUS 8

unsigned char local_ip[] = {192,168,5,234};
unsigned char gateway_ip[] = {192,168,5,1};
unsigned char subnet_mask[] = {255,255,255,0};
const prog_char ssid[] PROGMEM = {"ssid"};
unsigned char security_type = 2;	// 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2
const prog_char security_passphrase[] PROGMEM = {"password"};
prog_uchar wep_keys[] PROGMEM = {};
unsigned char wireless_mode = WIRELESS_MODE_INFRA;
unsigned char ssid_len;
unsigned char security_passphrase_len;


OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress thermometer;



void setup() {
  //Serial.begin(57600);
  sensors.begin();
  if (!sensors.getAddress(thermometer, 0)) Serial.println("Unable to find address for Device 0");
  
  pinMode(RELAY_PIN, OUTPUT); 
  digitalWrite(RELAY_PIN, LOW);

  WiServer.init(sendMyPage);
  WiServer.enableVerboseMode(true);
  
  sensors.setHighAlarmTemp(thermometer, 14);
  sensors.setLowAlarmTemp(thermometer, 12);
  
  sensors.setAlarmHandler(&switchRelay);
}


boolean sendMyPage(char* URL) {
  String requestURL = URL;
  WiServer.print("<xml>");
  
  if(requestURL.startsWith("/set")) {
    int valPos = requestURL.indexOf("=")+1;
    String val = requestURL.substring(valPos);
    int sepPos = requestURL.indexOf(",");
    String lowAlarm = requestURL.substring(valPos,sepPos);
    String highAlarm = requestURL.substring(sepPos+1);
    
    char this_char[lowAlarm.length() + 1];
    lowAlarm.toCharArray(this_char, sizeof(this_char));
    int lowI = atoi(this_char); 
    
    this_char[highAlarm.length() + 1];
    highAlarm.toCharArray(this_char, sizeof(this_char));
    int highI = atoi(this_char); 
    
    sensors.setAlarmHandler(&switchRelay);
    sensors.setHighAlarmTemp(thermometer, highI);
    sensors.setLowAlarmTemp(thermometer, lowI);
    
    WiServer.print("<newLowAlarm>");
    WiServer.print(lowAlarm);
    WiServer.print("</newLowAlarm>");
    WiServer.print("<newHighAlarm>");
    WiServer.print(highAlarm);
    WiServer.print("</newHighAlarm>");
  } else {
    WiServer.print("<temp>");
    WiServer.print(sensors.getTempCByIndex(0));
    WiServer.print("</temp>");
    WiServer.print("<lowAlarm>");
    WiServer.print(sensors.getLowAlarmTemp(thermometer), DEC);
    WiServer.print("</lowAlarm>");
    WiServer.print("<highAlarm>");
    WiServer.print(sensors.getHighAlarmTemp(thermometer), DEC);
    WiServer.print("</highAlarm>"); 
  }
  
  WiServer.print("</xml>");
  return true;
}

long updateTime = 0;
long interval = 1000*60;

void loop(){
  
  WiServer.server_task();
  if (millis() >= updateTime) {
    sensors.requestTemperatures();
    sensors.processAlarms();
    updateTime = millis()+20000;
    //Serial.println("Ran Update:");
    //Serial.println(millis());
    //Serial.println(updateTime);
  } 
  
  delay(10);
}


void switchRelay(uint8_t* deviceAddress) {
  
  float temp = sensors.getTempC(deviceAddress);
  if ((char)temp <= sensors.getLowAlarmTemp(deviceAddress)) {
    //Serial.println("LOW ALARM");
    digitalWrite(RELAY_PIN, LOW);
  }
  // check high alarm
  if ((char)temp >= sensors.getHighAlarmTemp(deviceAddress)) {
    //Serial.println("HIGH ALARM");
    digitalWrite(RELAY_PIN, HIGH);
  }
  //Serial.println("Alarm Handler Finish");
} 

