#include <EL_Escudo.h>
//The EL_Escudo library uses letters A-H to reference each EL string.
//Each EL string output has a corresponding label on the EL Escudo shield.

boolean debug = true;
int debugLastPiezoThreshold[] = {0};

int knockDetectionBlackout = 50; // ms to wait before checking for knocks again

int powerButtonPin = 2;

// Assignments in this order: {Kick drum}
char*   inputNames[] = {"kick"};
#define NUM_INPUTS (sizeof(inputNames)/sizeof(char *))
int     piezoInputPin[]      = {0};
int     piezoThresholdPin[]  = {1};
long    lastKnockTimestamp[] = {0};
int     piezoValue[]         = {0}; // the analog value from the piezo
int     piezoThreshold[]     = {0}; // the threshold, above which we consider a knock to have happened
boolean knockReceived[1];

void setup() {
  if(debug == true) Serial.begin(9600);  // Open the serial port for debugging
}

void loop() {
  for(int i=0; i<NUM_INPUTS; i++) {
    updatePiezoThreshold(i);
    knockReceived[i] = checkForKnocks(i);
    
    if(knockReceived[i] == true) pulseLights();
    
    if(debug == true) {
      // Print the threshold value
      if(piezoThreshold[i] > (debugLastPiezoThreshold[i] + 10) || piezoThreshold[i] < (debugLastPiezoThreshold[i] - 10)) {
        Serial.print("Threshold: ");
        Serial.println(piezoThreshold[i]);
        debugLastPiezoThreshold[i] = piezoThreshold[i];
      }
      
      // Did we receive a kick drum knock?
      if(knockReceived[i] == true) {
        // Print the value to the serial port
        Serial.print("Kick Knock! Piezo value: ");
        Serial.println(piezoValue[0]);
      }
    }
  }
}

void pulseLights() {
  for(int j=A; j<=E; j++) {
    EL.on(j);
  }
  
  delay(100);
  
  for(int brightness=7; brightness>=0; brightness--) {
    for(int duration=0; duration<5; duration++){
      for(int j=A; j<=E; j++) {
        EL.on(j);
      }
      delay(brightness);
      for(int j=A; j<=E; j++) {
        EL.off(j);
      }
      delay(7-brightness);
    }
  }
}

void updatePiezoThreshold(int index) { piezoThreshold[index] = analogRead(piezoThresholdPin[index]); }

boolean checkForKnocks(int index) {
  // Read the value from the piezo sensor
  piezoValue[index] = analogRead(piezoInputPin[index]);
  
  if(millis() > (lastKnockTimestamp[index] + knockDetectionBlackout)) { // once you've detected a knock, wait a bit to test for the next one (to let the piezo settle)
    if(piezoValue[index] > piezoThreshold[index]) return true;
  }
}
