library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ==============================================================================
-- EXTRA DATEI NUR ZUM TESTEN!
-- Dieses Modul dient nur dazu, den Code live auf dem FPGA zu überprüfen.
-- Es schließt EINEN Sensor an (DQ_1) und gibt seine 16 Bit Temperatur direkt
-- auf die 16 LEDs des Nexys 4 Boards aus.
-- ==============================================================================
entity top_led_test_ds18b20 is
    Port (
        CLK100MHZ : in  STD_LOGIC;  -- 100 MHz Takt vom Nexys 4

        -- Pin für Sensor 1
        DQ_1 : inout STD_LOGIC;

        -- Die 16 LEDs des Nexys 4 Boards, um die Temperatur anzuzeigen
        LED  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end top_led_test_ds18b20;

architecture Behavioral of top_led_test_ds18b20 is

    -- Wir sagen dem Modul, wie unser Sensor-Code aussieht
    component ds18b20_simple is
        Port (
            clk_100MHz : in  STD_LOGIC;
            dq         : inout STD_LOGIC;
            temp_data  : out STD_LOGIC_VECTOR(15 downto 0);
            valid      : out STD_LOGIC
        );
    end component;

    signal temp_1 : STD_LOGIC_VECTOR(15 downto 0);
    signal valid_1 : STD_LOGIC;

begin

    -- Den einzelnen Sensor anschließen
    Sensor_1: ds18b20_simple
        Port map (
            clk_100MHz => CLK100MHZ,
            dq         => DQ_1,
            temp_data  => temp_1,
            valid      => valid_1
        );

    -- Wir geben die 16-Bit Temperatur direkt auf die LEDs aus.
    -- (Bits 15 bis 4: Vorkommastelle, Bits 3 bis 0: Nachkommastelle)
    LED <= temp_1;

end Behavioral;
