library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Dieser Block ist so einfach wie möglich geschrieben, um
-- das Auslesen eines DS18B20 Temperatursensors verständlich zu machen.
-- Einsteigerfreundliche Variablen und ausführliche Kommentare.
entity ds18b20_simple is
    Port (
        clk_100MHz : in  STD_LOGIC;           -- 100 MHz Systemtakt (Standard vom Nexys 4)
        dq         : inout STD_LOGIC;         -- 1-Wire Datenleitung zum Sensor (an einen Pin anschließen)
        temp_data  : out STD_LOGIC_VECTOR(15 downto 0); -- Ausgelesene Temperatur (16 Bit)
        valid      : out STD_LOGIC            -- Zeigt an, ob die Daten neu ausgelesen wurden (wird kurz 1)
    );
end ds18b20_simple;

architecture Behavioral of ds18b20_simple is

    -- Alle Schritte (Zustände) für die Kommunikation mit dem Sensor
    type state_type is (
        S_RESET_PULSE_1,    -- Sende erstes Reset-Signal
        S_PRESENCE_WAIT_1,  -- Warte auf Bestätigung vom Sensor
        S_SKIP_ROM_1,       -- Sende Befehl: "Überspringe ROM/Adresse"
        S_CONVERT_CMD,      -- Sende Befehl: "Miss die Temperatur"
        S_WAIT_CONV,        -- Warte, bis die Messung fertig ist (ca. 800ms)
        S_RESET_PULSE_2,    -- Sende zweites Reset-Signal
        S_PRESENCE_WAIT_2,  -- Warte auf Bestätigung
        S_SKIP_ROM_2,       -- Sende Befehl: "Überspringe ROM/Adresse"
        S_READ_CMD,         -- Sende Befehl: "Schicke mir die Daten"
        S_READ_DATA,        -- Lese die 16-Bit Temperatur ein
        S_DONE              -- Messung abgeschlossen, kurz warten
    );
    signal state : state_type := S_RESET_PULSE_1;

    -- Ein Zähler, um aus 100 MHz Takt einen 1 Mikrosekunden (1 us) Takt zu machen
    signal clk_div : integer range 0 to 99 := 0;
    signal tick_1us : std_logic := '0';

    -- Ein Timer, der in Mikrosekunden zählt (bis zu 800.000 us = 800 ms)
    signal timer_us : integer range 0 to 800000 := 0;

    -- Variablen für das Senden von Befehlen (jeweils 8 Bit = 1 Byte)
    signal data_to_send : std_logic_vector(7 downto 0) := (others => '0');
    signal bits_sent    : integer range 0 to 8 := 0;

    -- Variablen für das Empfangen der Temperatur (16 Bit = 2 Byte)
    signal temp_reg     : std_logic_vector(15 downto 0) := (others => '0');
    signal bits_read    : integer range 0 to 16 := 0;

    -- Hilfs-Zustände für das Senden/Empfangen von einzelnen Bits (1en und 0en)
    type io_state_type is (IDLE, START_SLOT, WAIT_SAMPLE);
    signal io_state : io_state_type := IDLE;

    -- Kontrolliert, ob wir die Leitung auf Masse (0) ziehen oder in Ruhe lassen ('Z')
    signal dq_out : std_logic := 'Z';

begin

    -- Die Inout-Leitung dq wird entweder auf '0' gezogen oder hochohmig ('Z') geschaltet.
    -- Wenn sie auf 'Z' ist, zieht der externe Widerstand die Leitung auf 1 (High).
    dq <= '0' when dq_out = '0' else 'Z';

    -- Erzeuge einen 1-Mikrosekunde-Tick aus dem 100 MHz Takt
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if clk_div = 99 then
                clk_div <= 0;
                tick_1us <= '1';
            else
                clk_div <= clk_div + 1;
                tick_1us <= '0';
            end if;
        end if;
    end process;

    -- Haupt-Logik für die Sensor-Kommunikation
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            -- Standardmäßig 'valid' auf 0 setzen
            valid <= '0';

            -- Wir arbeiten in Schritten von 1 Mikrosekunde
            if tick_1us = '1' then
                case state is

                    -- Schritt 1: Reset-Puls senden (ca. 500 us)
                    when S_RESET_PULSE_1 =>
                        dq_out <= '0'; -- Leitung auf 0 ziehen
                        if timer_us = 500 then
                            dq_out <= 'Z'; -- Leitung wieder freigeben
                            timer_us <= 0;
                            state <= S_PRESENCE_WAIT_1;
                        else
                            timer_us <= timer_us + 1;
                        end if;

                    -- Schritt 2: Auf Sensor warten (weitere 500 us)
                    when S_PRESENCE_WAIT_1 =>
                        if timer_us = 500 then
                            timer_us <= 0;
                            -- Vorbereiten für nächsten Schritt: SKIP ROM Befehl = 0xCC (Hexadezimal) = 11001100 (Binär)
                            data_to_send <= x"CC";
                            bits_sent <= 0;
                            state <= S_SKIP_ROM_1;
                        else
                            timer_us <= timer_us + 1;
                        end if;

                    -- Schritt 3: SKIP ROM Befehl (0xCC) Bit für Bit senden
                    when S_SKIP_ROM_1 =>
                        case io_state is
                            when IDLE =>
                                if bits_sent < 8 then
                                    io_state <= START_SLOT;
                                    timer_us <= 0;
                                else
                                    -- Alle 8 Bits gesendet -> weiter zum Convert Befehl (0x44)
                                    data_to_send <= x"44";
                                    bits_sent <= 0;
                                    state <= S_CONVERT_CMD;
                                end if;

                            when START_SLOT =>
                                dq_out <= '0'; -- Puls beginnen
                                timer_us <= timer_us + 1;
                                -- Ist das Bit eine '1', lassen wir nach 5 us los.
                                -- Ist das Bit eine '0', lassen wir erst nach 60 us los.
                                if (data_to_send(bits_sent) = '1' and timer_us = 5) or
                                   (data_to_send(bits_sent) = '0' and timer_us = 60) then
                                    dq_out <= 'Z';
                                    io_state <= WAIT_SAMPLE;
                                end if;

                            when WAIT_SAMPLE =>
                                timer_us <= timer_us + 1;
                                -- Jeder Bit-Zyklus dauert insgesamt 70 us
                                if timer_us = 70 then
                                    bits_sent <= bits_sent + 1;
                                    io_state <= IDLE;
                                end if;
                        end case;

                    -- Schritt 4: CONVERT Befehl (0x44) senden ("Miss die Temperatur!")
                    when S_CONVERT_CMD =>
                        case io_state is
                            when IDLE =>
                                if bits_sent < 8 then
                                    io_state <= START_SLOT;
                                    timer_us <= 0;
                                else
                                    -- Befehl gesendet, jetzt warten wir auf den Sensor
                                    state <= S_WAIT_CONV;
                                    timer_us <= 0;
                                end if;

                            when START_SLOT =>
                                dq_out <= '0';
                                timer_us <= timer_us + 1;
                                if (data_to_send(bits_sent) = '1' and timer_us = 5) or
                                   (data_to_send(bits_sent) = '0' and timer_us = 60) then
                                    dq_out <= 'Z';
                                    io_state <= WAIT_SAMPLE;
                                end if;

                            when WAIT_SAMPLE =>
                                timer_us <= timer_us + 1;
                                if timer_us = 70 then
                                    bits_sent <= bits_sent + 1;
                                    io_state <= IDLE;
                                end if;
                        end case;

                    -- Schritt 5: Warten bis der Sensor fertig ist (800 Millisekunden)
                    when S_WAIT_CONV =>
                        if timer_us = 800000 then -- 800.000 us = 800 ms
                            timer_us <= 0;
                            state <= S_RESET_PULSE_2;
                        else
                            timer_us <= timer_us + 1;
                        end if;

                    -- Schritt 6: Zweites Reset-Signal
                    when S_RESET_PULSE_2 =>
                        dq_out <= '0';
                        if timer_us = 500 then
                            dq_out <= 'Z';
                            timer_us <= 0;
                            state <= S_PRESENCE_WAIT_2;
                        else
                            timer_us <= timer_us + 1;
                        end if;

                    -- Schritt 7: Auf Sensor Antwort warten
                    when S_PRESENCE_WAIT_2 =>
                        if timer_us = 500 then
                            timer_us <= 0;
                            data_to_send <= x"CC"; -- SKIP ROM Befehl
                            bits_sent <= 0;
                            state <= S_SKIP_ROM_2;
                        else
                            timer_us <= timer_us + 1;
                        end if;

                    -- Schritt 8: Zweiter SKIP ROM Befehl
                    when S_SKIP_ROM_2 =>
                        case io_state is
                            when IDLE =>
                                if bits_sent < 8 then
                                    io_state <= START_SLOT;
                                    timer_us <= 0;
                                else
                                    data_to_send <= x"BE"; -- READ SCRATCHPAD Befehl (0xBE)
                                    bits_sent <= 0;
                                    state <= S_READ_CMD;
                                end if;

                            when START_SLOT =>
                                dq_out <= '0';
                                timer_us <= timer_us + 1;
                                if (data_to_send(bits_sent) = '1' and timer_us = 5) or
                                   (data_to_send(bits_sent) = '0' and timer_us = 60) then
                                    dq_out <= 'Z';
                                    io_state <= WAIT_SAMPLE;
                                end if;

                            when WAIT_SAMPLE =>
                                timer_us <= timer_us + 1;
                                if timer_us = 70 then
                                    bits_sent <= bits_sent + 1;
                                    io_state <= IDLE;
                                end if;
                        end case;

                    -- Schritt 9: READ Befehl (0xBE) senden ("Schick mir die Daten!")
                    when S_READ_CMD =>
                        case io_state is
                            when IDLE =>
                                if bits_sent < 8 then
                                    io_state <= START_SLOT;
                                    timer_us <= 0;
                                else
                                    bits_read <= 0;
                                    state <= S_READ_DATA;
                                end if;

                            when START_SLOT =>
                                dq_out <= '0';
                                timer_us <= timer_us + 1;
                                if (data_to_send(bits_sent) = '1' and timer_us = 5) or
                                   (data_to_send(bits_sent) = '0' and timer_us = 60) then
                                    dq_out <= 'Z';
                                    io_state <= WAIT_SAMPLE;
                                end if;

                            when WAIT_SAMPLE =>
                                timer_us <= timer_us + 1;
                                if timer_us = 70 then
                                    bits_sent <= bits_sent + 1;
                                    io_state <= IDLE;
                                end if;
                        end case;

                    -- Schritt 10: Die 16 Bits für die Temperatur empfangen
                    when S_READ_DATA =>
                        case io_state is
                            when IDLE =>
                                if bits_read < 16 then
                                    io_state <= START_SLOT;
                                    timer_us <= 0;
                                else
                                    -- Alle 16 Bit gelesen: ausgeben und "valid" auf 1 setzen
                                    temp_data <= temp_reg;
                                    valid <= '1';
                                    state <= S_DONE;
                                end if;

                            when START_SLOT =>
                                dq_out <= '0'; -- Lese-Puls starten
                                timer_us <= timer_us + 1;
                                if timer_us = 2 then
                                    dq_out <= 'Z'; -- Nach 2 us wieder loslassen, damit Sensor senden kann
                                    io_state <= WAIT_SAMPLE;
                                end if;

                            when WAIT_SAMPLE =>
                                timer_us <= timer_us + 1;
                                if timer_us = 12 then
                                    -- Nach ca. 12 us schauen wir, was der Sensor uns sagt
                                    temp_reg(bits_read) <= dq;
                                elsif timer_us = 70 then
                                    -- Zyklus zuende, weiter zum nächsten Bit
                                    bits_read <= bits_read + 1;
                                    io_state <= IDLE;
                                end if;
                        end case;

                    -- Schritt 11: Fertig, kurz pausieren und dann neue Messung starten
                    when S_DONE =>
                        timer_us <= timer_us + 1;
                        if timer_us = 1000 then -- 1 ms Pause
                            timer_us <= 0;
                            state <= S_RESET_PULSE_1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
