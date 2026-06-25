library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_top_4x_ds18b20 is
end tb_top_4x_ds18b20;

architecture Behavioral of tb_top_4x_ds18b20 is
    component ds18b20_simple
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

    signal clk   : std_logic := '0';
    signal dq  : std_logic := 'H';
    signal temp_data : std_logic_vector(15 downto 0);
    signal valid : std_logic;

    constant clk_period : time := 10 ns;
    signal sim_done : boolean := false;

begin

    dq <= 'H';

    UUT: ds18b20_simple
        Generic map (
            CONVERT_TIME_US => 800
        )
        Port map (
            clk_100MHz => clk,
            dq         => dq,
            temp_data  => temp_data,
            valid      => valid
        );

    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    sensor_sim : process
        -- Temperatur: 123.4 °C
        -- DS18B20 Format: Die untersten 4 Bit sind Nachkommastellen (1/16 = 0.0625 °C Schritte).
        -- 123.375 °C = 123 + 6/16 -> 123 in Binär ist 01111011. Die Nachkommastelle 6/16 ist 0110.
        -- Gesamter 16-Bit Wert: 0000 0111 1011 0110 = 0x07B6
        variable my_temp : std_logic_vector(15 downto 0) := "0000011110110110";
    begin
        -- === SCHRITT 1: Reset 1 ===
        wait until dq = '0';
        wait until dq = 'H' or dq = '1';
        wait for 30 us;
        dq <= '0';
        wait for 120 us;
        dq <= 'Z';

        -- === SCHRITT 2: Skip ROM ===
        for i in 0 to 7 loop
            wait until dq = '0';
            wait until dq = 'H' or dq = '1';
        end loop;

        -- === SCHRITT 3: Convert T ===
        for i in 0 to 7 loop
            wait until dq = '0';
            wait until dq = 'H' or dq = '1';
        end loop;

        -- === SCHRITT 4: Reset 2 ===
        wait until dq = '0';
        wait until dq = 'H' or dq = '1';
        wait for 30 us;
        dq <= '0';
        wait for 120 us;
        dq <= 'Z';

        -- === SCHRITT 5: Skip ROM ===
        for i in 0 to 7 loop
            wait until dq = '0';
            wait until dq = 'H' or dq = '1';
        end loop;

        -- === SCHRITT 6: Read Scratchpad ===
        for i in 0 to 7 loop
            wait until dq = '0';
            wait until dq = 'H' or dq = '1';
        end loop;

        -- === SCHRITT 7: Temperatur senden (LSB FIRST) ===
        for i in 0 to 15 loop
            wait until dq = '0';
            wait for 2 us;
            if my_temp(i) = '0' then
                dq <= '0';
                wait for 20 us;
                dq <= 'Z';
                wait for 40 us;
            else
                dq <= 'Z';
                wait for 60 us;
            end if;
        end loop;

        wait until valid = '1';
        report "Simulation erfolgreich: Valid-Signal empfangen!";
        sim_done <= true;
        wait;
    end process;

    process
    begin
        wait for 20 ms;
        assert sim_done report "TIMEOUT ERR: Simulation hat 20ms ueberschritten!" severity failure;
        wait;
    end process;

end Behavioral;
