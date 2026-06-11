# 4x DS18B20 Temperatursensoren an Nexys 4 (Artix-7)

Dieses Projekt steuert 4 DS18B20 Temperatursensoren über das Nexys 4 FPGA-Board an.
Der Code wurde speziell so geschrieben, dass er für Anfänger verständlich ist.

## Aufbau der Dateien

- `ds18b20_simple.vhd`: Das Modul für einen einzelnen Sensor. Es sendet die Befehle zum Auslesen der Temperatur und speichert das Ergebnis (16 Bit). Die Komplexität wurde bewusst reduziert.
- `top_4x_ds18b20.vhd`: Das "Top-Level"-Modul. Hier werden 4 der `ds18b20_simple` Module aufgerufen und jedem ein eigener Pin (`DQ_1` bis `DQ_4`) zugewiesen.
- `Nexys4_ds18b20.xdc`: Die Constraints-Datei. Hier wird festgelegt, welcher Pin auf dem FPGA-Board welchem Signal im Code entspricht. Wir nutzen hier den Pmod-Anschluss "JA".

## Wichtige Hinweise zum Anschluss (Hardware)

1. Der DS18B20 benötigt 3 Anschlüsse: **GND** (Masse), **VDD** (Stromversorgung, 3.3V vom Pmod) und **DQ** (Datenleitung).
2. **Pull-Up Widerstand:** Das 1-Wire Protokoll erfordert ZWINGEND einen Pull-Up Widerstand. Du musst zwischen der **DQ**-Leitung und der **3.3V**-Leitung jedes Sensors einen **4.7 kOhm Widerstand** einbauen. Ohne diesen Widerstand funktioniert die Kommunikation nicht!
3. Schließe die Sensoren an den Pmod-Port JA an.

## Wie der Code funktioniert

Der FPGA sendet kontinuierlich Befehle an die Sensoren:
1. **Reset & Presence:** Der FPGA prüft, ob der Sensor da ist.
2. **Skip ROM (0xCC):** Da jeder Sensor an einem *eigenen* Pin hängt, müssen wir keine Adressen prüfen. Wir überspringen das.
3. **Convert T (0x44):** Der FPGA sagt dem Sensor: "Miss jetzt die Temperatur". Das dauert ca. 750 ms.
4. **Read Scratchpad (0xBE):** Nach der Wartezeit liest der FPGA die 16-Bit Temperaturdaten aus.

## Nächste Schritte

Aktuell werden die Werte im FPGA-Chip gespeichert, aber noch nicht auf dem 7-Segment-Display angezeigt. Das ist der nächste logische Schritt, oder auch die Einbindung von Relais, die basierend auf den gemessenen Temperaturen geschaltet werden können.
