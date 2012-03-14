#include <TimerOne.h>
#include <EL_Escudo.h>
#include <stdlib.h>

//The EL_Escudo library uses letters A-H to reference each EL string.
//Each EL string output has a corresponding label on the EL Escudo shield.

boolean debug = false;
int debugLastPiezoThreshold[] = {0};

int knockDetectionBlackout = 100; // ms to wait before checking for knocks again

// Assignments in this order: {Kick drum}
char*   inputNames[] = {"kick"};
#define NUM_INPUTS (sizeof(inputNames)/sizeof(char *))
int     piezoInputPin[]      = {0};
int     piezoThresholdPin[]  = {1};
long    lastKnockTimestamp[] = {0};
int     piezoValue[]         = {0}; // the analog value from the piezo
int     piezoThreshold[]     = {0}; // the threshold, above which we consider a knock to have happened
boolean knockReceived[1];
    
int brightness = 0;
float fractionalBrightness = 0;

int animationLength = 800;   // in milliseconds
unsigned long animationStart; // in milliseconds
unsigned long currentTime;    // in milliseconds

float animationPercentage;    // a fraction

int timerPeriod = 1000;       // in microseconds

void setup() {
  if(debug == true) Serial.begin(9600);  // Open the serial port for debugging
  
  // Asynchronously listen for knocks and animate down the brightness
  Timer1.initialize(timerPeriod);
  Timer1.attachInterrupt(checkForKnocks);
  
  // Enable all the wire outputs
  for(int j=A; j<=E; j++) {
    pinMode(j, OUTPUT);
  }
}

void checkForKnocks() {
  // Check for knocks on all inputs
  for(int i=0; i<NUM_INPUTS; i++) {
    updatePiezoThreshold(i);
    knockReceived[i] = checkForKnockOnSensor(i);
    
    if(knockReceived[i] == true) handleKnock(i);
    
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

void loop() {
  updateCurrentTime();
  if(animationStart) animateTargetBrightness();
  illuminateWire();
}

void updateCurrentTime() {
  // Update the clock
  currentTime = millis();
}
void animateTargetBrightness() {
  // Animate brightness
  animationPercentage = (float)(millis() - animationStart) / animationLength;
  if(animationPercentage < 0.0) {
    animationPercentage = 0.0;
  } else if(animationPercentage > 1.0) {
    animationPercentage = 1.0;
    animationStart = NULL;
    if(debug == true) {
      Serial.print("Animation out of range: ");
      Serial.println(animationPercentage);
    }
  }
  
  setBrightness(pulse_width - (pulse_width * transition(animationPercentage)));
}
void illuminateWire() {
  // Update the brightness of the EL wire 
  if(brightness > 0) {
    // Turn all of the wires on
    for(int j=A; j<=E; j++) {
      digitalWrite(j, HIGH);
    }
  }
  
  // Hold the wires on for a duration that corresponds to the duty cycle
  delay(brightness);

  if(brightness < pulse_width) {
    // Turn all of the wires off
    for(int j=A; j<=E; j++) {
      digitalWrite(j, LOW);
    }
  }
  
  // Hold the wires off for a duration that corresponds to the pulse width minus the duty cycle
  delay(pulse_width - brightness);
}

float transition(float p) { return pow(p, 2.25); }

void handleKnock(int index) {
  animationStart = currentTime;
}

void setBrightness(float value) {
  brightness = int(value);
  fractionalBrightness = value;
}

void updatePiezoThreshold(int index) { piezoThreshold[index] = analogRead(piezoThresholdPin[index]); }

boolean checkForKnockOnSensor(int index) {
  // Read the value from the piezo sensor
  piezoValue[index] = analogRead(piezoInputPin[index]);
  
  if(currentTime > (lastKnockTimestamp[index] + knockDetectionBlackout)) { // once you've detected a knock, wait a bit to test for the next one (to let the piezo settle)
    if(piezoValue[index] > piezoThreshold[index]) {
      lastKnockTimestamp[index] = currentTime;
      return true;
    }
  }
}
