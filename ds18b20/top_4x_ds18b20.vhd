library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Dieses Modul ist der "Chef" (Top Level) und verbindet das FPGA mit den 4 Temperatursensoren.
entity top_4x_ds18b20 is
    Port (
        CLK100MHZ : in  STD_LOGIC;  -- 100 MHz Takt vom Nexys 4

        -- Die 4 Pins, an denen die Sensoren angeschlossen sind
        DQ_1 : inout STD_LOGIC;
        DQ_2 : inout STD_LOGIC;
        DQ_3 : inout STD_LOGIC;
        DQ_4 : inout STD_LOGIC
    );
end top_4x_ds18b20;

architecture Behavioral of top_4x_ds18b20 is

    -- Wir sagen dem Top-Modul, wie unser Sensor-Modul aussieht
    component ds18b20_simple is
        Generic (
            CONVERT_TIME_US : integer := 800000
        );
        Port (
            clk_100MHz : in  STD_LOGIC;
            dq         : inout STD_LOGIC;
            temp_data  : out STD_LOGIC_VECTOR(15 downto 0);
            valid      : out STD_LOGIC
        );
    end component;

    -- Damit die Testbench schneller durchläuft
    -- In echter Hardware ist das 800.000 (800ms)
    -- Da wir kein "Generic Map" in der Entity von top haben (wäre zu komplex für Anfänger)
    -- setzen wir hier einen bedingten Default oder wir nutzen das VHDL Feature, dass die Testbench tief in die Komponenten guckt.
    -- Um das Top-Modul für Simulationen beschleunigen zu können, ohne es für Anfänger unlesbar zu machen,
    -- greifen wir in der Testbench einfach direkt ein. Hier bleibt es bei 800000.

    -- Leitungen, um die Temperaturen der 4 Sensoren zu speichern
    signal temp_1 : STD_LOGIC_VECTOR(15 downto 0);
    signal temp_2 : STD_LOGIC_VECTOR(15 downto 0);
    signal temp_3 : STD_LOGIC_VECTOR(15 downto 0);
    signal temp_4 : STD_LOGIC_VECTOR(15 downto 0);

    -- Signale, die kurz 1 werden, wenn neue Daten da sind
    signal valid_1 : STD_LOGIC;
    signal valid_2 : STD_LOGIC;
    signal valid_3 : STD_LOGIC;
    signal valid_4 : STD_LOGIC;

    -- =========================================================================
    -- VIVADO ATTRIBUTE: Verhindern das Weg-Optimieren (Keep) und zwingen
    -- die Signale in den ILA-Analyzer (Mark_Debug).
    -- =========================================================================





begin

    -- Sensor 1 anschließen
    Sensor_1: ds18b20_simple
        -- Die Zeit (800ms) ist direkt im ds18b20_simple_Modul per default gesetzt
        Port map (
            clk_100MHz => CLK100MHZ,
            dq         => DQ_1,
            temp_data  => temp_1,
            valid      => valid_1
        );

    -- Sensor 2 anschließen
    Sensor_2: ds18b20_simple
        Port map (
            clk_100MHz => CLK100MHZ,
            dq         => DQ_2,
            temp_data  => temp_2,
            valid      => valid_2
        );

    -- Sensor 3 anschließen
    Sensor_3: ds18b20_simple
        Port map (
            clk_100MHz => CLK100MHZ,
            dq         => DQ_3,
            temp_data  => temp_3,
            valid      => valid_3
        );

    -- Sensor 4 anschließen
    Sensor_4: ds18b20_simple
        Port map (
            clk_100MHz => CLK100MHZ,
            dq         => DQ_4,
            temp_data  => temp_4,
            valid      => valid_4
        );

end Behavioral;
