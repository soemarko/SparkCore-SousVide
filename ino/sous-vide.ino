// this is very important comment!
#include "PID.h"
#include "PID_AutoTune_v0.h"

#include "OneWire.h"
#include "DS18B20.h"

// Input pin where DS18B20 is connected
int ds18b20Pin = D6;
int ledPin = D7;
// Output pin where relay is connected
int relayPin = D4;
int relayON = LOW; // sinking SSR (negative go to pin)
int relayOFF = HIGH;

char publishString[64];

// PID: variables
double pointTemperature, actualTemperature, pidOutput;
double kP = 900;
double kI = 2.5;
double kD = 1;

boolean isTargetReached = false;

// PID: Specify the links and initial tuning parameters
PID myPID(&actualTemperature, &pidOutput, &pointTemperature, kP, kI, kD, DIRECT);

// PID: Autotune
byte ATuneModeRemember=2;
boolean tuning = false;
PID_ATune aTune(&actualTemperature, &pidOutput);

// PWM variables
long windowSize = 10000;
long windowStartTime;
int onTime;

// counter to run serial output once every 4 loops of 250 ms
int tcLoopCount = 0;

// Timestamp of the last status events
unsigned long lastEventTimestamp;

// Temperature device on the D1 pin
DS18B20 ds18b20 = DS18B20(ds18b20Pin);

void setup() {
    Serial.begin(9600);

    // SparkCloud: functions
    Spark.function("setPoint", setPointTemperature);
    Spark.function("setTunings", setPIDTunings);
    Spark.function("autoTune", doAutoTune);

    pinMode(ledPin, OUTPUT);

    // Set relay pin mode to output
    pinMode(relayPin, OUTPUT);
    digitalWrite(relayPin, relayOFF);

    // Point temperature default
    pointTemperature = 75;

    //turn the PID on
    myPID.SetOutputLimits(0, windowSize);
    myPID.SetMode(AUTOMATIC);

    // Last event timestamp
    lastEventTimestamp = 0;
}

void loop() {
    if (millis() - lastEventTimestamp >= 250) {
        do250msLoop();
        lastEventTimestamp = millis();
    }

    if(tuning) {
        if (aTune.Runtime()) {
            doneAutoTune();
            digitalWrite(ledPin, LOW);
        }
    }
    else {
        myPID.Compute();
    }
}

void do250msLoop() {
    // Searching for the ds18b20 device
    if(actualTemperature == 0 && !ds18b20.search()) {
        // Log to the serial
        Serial.println(F("No more addresses."));
        Spark.publish("sousInfo", "0.0|0.0|0|0.0|0.0|0.0|0");
        // Turn off the relay during the scan
        digitalWrite(relayPin, relayOFF);
        // Restart search
        ds18b20.resetsearch();
        return;
    }

    actualTemperature = ds18b20.getTemperature();
    doPWM();

    if(tcLoopCount > 3) { // 1000ms loop
        tcLoopCount = 0;
        doOutput();
    }
    tcLoopCount += 1;
}

void doPWM() {
    long now = millis();

    int Power = map(pidOutput, 0, windowSize, 0, 100);

    onTime = windowSize * Power / 100; //recalc the millisecs on to get this power level, user may have changed

    if (now - windowStartTime > windowSize) windowStartTime = now;

    if (now - windowStartTime < onTime) {
        digitalWrite(relayPin, relayON);
    }
    else {
        digitalWrite(relayPin, relayOFF);
    }
}

void doOutput() {
    sprintf(publishString, "%.1f|%.1f|%d|%.2f|%.2f|%.2f|%d", actualTemperature, pointTemperature, map(pidOutput, 0, windowSize, 0, 100), kP, kI, kD, tuning);

    // Log to the serial
    Serial.println(publishString);

    // SparkCore: publish
    Spark.publish("sousInfo", publishString);

    if (!isTargetReached && pointTemperature <= actualTemperature) {
        Spark.publish("sousTargetReached", "Target Temperature Reached");
        isTargetReached = true;
    }
}

int doAutoTune(String command) {
    if (command.length() == 0) command = "1,15,20";

    int noise = strSplit(command, ',', 0).toInt();
    int step = strSplit(command, ',', 1).toInt();
    int lookback = strSplit(command, ',', 2).toInt();

    // REmember the mode we were in
    ATuneModeRemember = myPID.GetMode();

    // set up the auto-tune parameters
    aTune.SetNoiseBand(noise);
    aTune.SetOutputStep(step);
    aTune.SetLookbackSec(lookback);
    tuning = true;

    digitalWrite(ledPin, HIGH);

    return 1;
}

void doneAutoTune() {
    tuning = false;

    // Extract the auto-tune calculated parameters
    kP = aTune.GetKp();
    kI = aTune.GetKi();
    kD = aTune.GetKd();

    // Re-tune the PID and revert to normal control mode
    myPID.SetTunings(kP,kI,kD);
    myPID.SetMode(ATuneModeRemember);
}


// set point temperature
int setPointTemperature(String command) {
  // Convert to double
  pointTemperature = command.toFloat();

  isTargetReached = false;

  return 1;
}

int setPIDTunings(String command) {
  kP = strSplit(command, ',', 0).toFloat();
  kI = strSplit(command, ',', 1).toFloat();
  kD = strSplit(command, ',', 2).toFloat();

  myPID.SetTunings(kP,kI,kD);

  return 1;
}

String strSplit(String data, char delim, int index) {
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length()-1;

  for(int i=0; i<=maxIndex && found<=index; i++) {
    if(data.charAt(i)==delim || i==maxIndex) {
        found++;
        strIndex[0] = strIndex[1]+1;
        strIndex[1] = (i == maxIndex) ? i+1 : i;
    }
  }

  return found>index ? data.substring(strIndex[0], strIndex[1]) : "0";
}
