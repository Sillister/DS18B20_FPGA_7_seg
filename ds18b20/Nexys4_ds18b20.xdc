## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

## Pmod Header JA (Hier schließt du die 4 Sensoren an)
## Jeder Sensor benötigt VCC (3.3V), GND und den Data-Pin.
## WICHTIG: Du musst an JEDEN Daten-Pin einen 4.7k Ohm Pull-Up Widerstand zwischen Data und 3.3V schalten!

# Sensor 1 an JA Pin 1
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { DQ_1 }];
# Sensor 2 an JA Pin 2
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { DQ_2 }];
# Sensor 3 an JA Pin 3
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { DQ_3 }];
# Sensor 4 an JA Pin 4
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { DQ_4 }];
