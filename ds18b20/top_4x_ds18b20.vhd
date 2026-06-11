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
        DQ_4 : inout STD_LOGIC;

        -- LEDs, um zu sehen, ob Werte gelesen wurden (optionales Debugging)
        LED_VALID : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top_4x_ds18b20;

architecture Behavioral of top_4x_ds18b20 is

    -- Wir sagen dem Top-Modul, wie unser Sensor-Modul aussieht
    component ds18b20_simple is
        Port (
            clk_100MHz : in  STD_LOGIC;
            dq         : inout STD_LOGIC;
            temp_data  : out STD_LOGIC_VECTOR(15 downto 0);
            valid      : out STD_LOGIC
        );
    end component;

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

    -- Wir speichern den Zustand für die LEDs dauerhaft ab
    signal led_reg : STD_LOGIC_VECTOR(3 downto 0) := "0000";

begin

    -- Sensor 1 anschließen
    Sensor_1: ds18b20_simple
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

    -- Ein kleiner Prozess, der eine LED einschaltet, wenn ein Sensor einmal erfolgreich gelesen hat.
    -- Das ist sehr praktisch, um sofort zu sehen, ob die Verkabelung stimmt!
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            if valid_1 = '1' then led_reg(0) <= '1'; end if;
            if valid_2 = '1' then led_reg(1) <= '1'; end if;
            if valid_3 = '1' then led_reg(2) <= '1'; end if;
            if valid_4 = '1' then led_reg(3) <= '1'; end if;
        end if;
    end process;

    LED_VALID <= led_reg;

end Behavioral;
