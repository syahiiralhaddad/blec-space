/*
 * BLEc Space — ESP32 BLE LED firmware
 *
 * Exposes one GATT service with one characteristic:
 *   - write "ON" / "OFF" (or "1" / "0") to switch the LED
 *   - read or subscribe (notify) to get the current LED state
 *
 * UUIDs must match lib/config/ble_config.dart in the Flutter app.
 *
 * Board : any ESP32 dev board (Arduino core for ESP32, v2.x or v3.x)
 * LED   : built-in LED on GPIO 2, or an external LED + 220Ω resistor on LED_PIN
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ---- Config ---------------------------------------------------------------
#define DEVICE_NAME  "BLEc-ESP32"   // shown in the app; give each board a unique name
#define LED_PIN      2

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define LED_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// ---------------------------------------------------------------------------

BLECharacteristic *ledCharacteristic = nullptr;
bool deviceConnected = false;
bool ledOn = false;

void publishLedState() {
  const char *state = ledOn ? "ON" : "OFF";
  ledCharacteristic->setValue(state);
  if (deviceConnected) {
    ledCharacteristic->notify();
  }
  Serial.printf("LED -> %s\n", state);
}

void setLed(bool on) {
  ledOn = on;
  digitalWrite(LED_PIN, on ? HIGH : LOW);
  publishLedState();
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    deviceConnected = true;
    Serial.println("Client connected");
  }

  void onDisconnect(BLEServer *server) override {
    deviceConnected = false;
    Serial.println("Client disconnected, advertising again");
    delay(200);
    BLEDevice::startAdvertising();  // let the app reconnect
  }
};

class LedCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    // .c_str() works for both std::string (core 2.x) and String (core 3.x)
    String value = String(characteristic->getValue().c_str());
    value.trim();
    value.toUpperCase();

    if (value == "ON" || value == "1") {
      setLed(true);
    } else if (value == "OFF" || value == "0") {
      setLed(false);
    } else {
      Serial.printf("Unknown command: %s\n", value.c_str());
    }
  }
};

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  BLEDevice::init(DEVICE_NAME);
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService *service = server->createService(SERVICE_UUID);
  ledCharacteristic = service->createCharacteristic(
      LED_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_WRITE |
      BLECharacteristic::PROPERTY_WRITE_NR |
      BLECharacteristic::PROPERTY_NOTIFY);
  ledCharacteristic->setCallbacks(new LedCallbacks());
#if !defined(CONFIG_NIMBLE_ENABLED)
  // Bluedroid stack (classic ESP32): add the CCCD so the app can subscribe.
  // NimBLE (e.g. ESP32-C6/H2) adds it automatically.
  ledCharacteristic->addDescriptor(new BLE2902());
#endif
  ledCharacteristic->setValue("OFF");
  service->start();

  // Advertising packet (max 31 bytes): flags + 128-bit service UUID,
  // so the app can filter by service. The name goes in the scan response.
  BLEAdvertising *advertising = BLEDevice::getAdvertising();

  BLEAdvertisementData advData;
  advData.setFlags(0x06);  // general discoverable, BR/EDR not supported
  advData.setCompleteServices(BLEUUID(SERVICE_UUID));
  advertising->setAdvertisementData(advData);

  BLEAdvertisementData scanResponse;
  scanResponse.setName(DEVICE_NAME);
  advertising->setScanResponseData(scanResponse);

  BLEDevice::startAdvertising();
  Serial.printf("%s ready, waiting for the app...\n", DEVICE_NAME);
}

void loop() {
  // Optional: BOOT button (GPIO 0) toggles the LED locally,
  // and the app updates instantly through the notification.
  static bool lastButton = HIGH;
  bool button = digitalRead(0);
  if (lastButton == HIGH && button == LOW) {
    setLed(!ledOn);
  }
  lastButton = button;
  delay(20);
}
