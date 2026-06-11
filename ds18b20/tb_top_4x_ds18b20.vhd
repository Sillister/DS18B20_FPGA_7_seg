library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Eine einfache Testbench, um unser Top-Modul zu überprüfen.
-- Sie generiert einen 100MHz Takt und simuliert das Verhalten eines angebundenen Sensors.
entity tb_top_4x_ds18b20 is
end tb_top_4x_ds18b20;

architecture Behavioral of tb_top_4x_ds18b20 is

    -- Wir holen uns das Top-Modul
    component top_4x_ds18b20
        Port (
            CLK100MHZ : in  STD_LOGIC;
            DQ_1      : inout STD_LOGIC;
            DQ_2      : inout STD_LOGIC;
            DQ_3      : inout STD_LOGIC;
            DQ_4      : inout STD_LOGIC;
            LED_VALID : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    -- Signale für die Testbench
    signal clk   : std_logic := '0';
    signal dq_1  : std_logic := 'H'; -- 'H' simuliert den Pull-Up Widerstand
    signal dq_2  : std_logic := 'H';
    signal dq_3  : std_logic := 'H';
    signal dq_4  : std_logic := 'H';
    signal leds  : std_logic_vector(3 downto 0);

    -- Clock periode für 100 MHz (10 ns)
    constant clk_period : time := 10 ns;

begin

    -- Wir verbinden unser Top-Modul mit den Testbench-Signalen
    UUT: top_4x_ds18b20
        Port map (
            CLK100MHZ => clk,
            DQ_1      => dq_1,
            DQ_2      => dq_2,
            DQ_3      => dq_3,
            DQ_4      => dq_4,
            LED_VALID => leds
        );

    -- Erzeuge den 100MHz Takt
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Ein Prozess, der das Verhalten EINES Sensors an dq_1 simuliert
    -- Wir antworten hier auf das erste Reset-Signal des FPGAs
    sensor_sim : process
    begin
        -- Warte, bis der FPGA die Leitung zum ersten Mal auf '0' zieht (Reset Pulse)
        wait until dq_1 = '0';

        -- Der FPGA hält das Signal für 500 us. Wir warten, bis er wieder loslässt.
        wait until dq_1 = 'H' or dq_1 = 'Z' or dq_1 = '1';

        -- Nach dem Reset wartet der Sensor kurz (ca. 15-60 us) und antwortet dann
        -- mit einem "Presence Pulse" (er zieht die Leitung auf 0 für 60-240 us).
        wait for 30 us;

        -- Sende Presence Pulse (Bestätigung "Ich bin da!")
        dq_1 <= '0';
        wait for 120 us;

        -- Sensor gibt Leitung wieder frei
        dq_1 <= 'Z';

        -- Hier würde der Sensor nun auf die Befehle (Skip ROM, etc.) warten.
        -- Für einen einfachen Test der ersten Schritte belassen wir es dabei.
        wait;
    end process;

end Behavioral;
