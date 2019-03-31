----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2019 19:18:41
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    port (
-- i_clk � il segnale di CLOCK in ingresso generato dal TestBench    
        i_clk : in std_logic;
-- i_start � il segnale di START generato dal Test Bench;        
        i_start : in std_logic;
-- i_rst � il segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale         
        i_rst : in std_logic;
-- i_data � il segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura        
        i_data : in std_logic_vector(7 downto 0);
-- o_address � il segnale (vettore) di uscita che manda l�indirizzo alla memoria        
        o_address : out std_logic_vector(15 downto 0);
-- o_done � il segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria        
        o_done : out std_logic;
-- o_en � il segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura)        
        o_en : out std_logic;
-- o_we � il segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria 
-- esso dev'essere 0.        
        o_we : out std_logic;
-- o_data � il segnale (vettore) di uscita dal componente verso la memoria        
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATO is ( RST, S0, S1, S2, S3, S4, S5, S6, S7, S8 );
    type D_ARRAY is array (8191 downto 0) of unsigned(9 downto 0);
    signal PS, NS, PRS, PRS_prev : STATO;
    signal Y_out : std_logic_vector (7 downto 0);
    signal Yp, Xp, Xp_prev : unsigned (9 downto 0);
    signal Yo, Xo, Yo_prev, Xo_prev : unsigned (9 downto 0);
    signal Ydiff, Xdiff : unsigned (9 downto 0);
    signal bitMask, bitMask_prev : std_logic_vector(7 downto 0) := (others => '0');
    signal distances : D_ARRAY := (others => to_unsigned(520,10));
    signal min_distance,min_distance_prev : unsigned := to_unsigned(520,10);
    signal dist_tmp : unsigned (9 downto 0);
    signal counter,counter_prev : integer := 1;
    signal counter2,counter2_prev : integer := 7;
begin
    delta_lambda : process( PS, PRS, i_start, i_data, bitMask, Yo, Xo, Yp, Xp, Ydiff, Xdiff, dist_tmp,
    min_distance, distances, Y_out, counter, counter2,
    counter_prev, counter2_prev, min_distance_prev, Xp_prev, Xo_prev, Yo_prev, bitMask_prev, PRS_prev )
        begin
        NS <= PS;
        PRS <= PRS_prev;
        counter <= counter_prev;
        bitMask <= bitMask_prev;
        counter2 <= counter2_prev;
        Xo <= Xo_prev;
        Yo <= Yo_prev;
        Xp <= Xp_prev;
        min_distance <= min_distance_prev;
        Yp <= (others => '0');
        Xdiff <= (others => '0');
        Ydiff <= (others => '0');
        dist_tmp <= (others => '0');
        o_data <= (others => '0');
        Y_out <= (others => '0');
        o_done <= '0';
        o_en <= '1';
        o_we <= '0';
        case PS is
            when RST =>
                o_address <= (others => '0');
                o_data <= (others => '0');
                NS <= S0;
                PRS <= S0;
                counter <= 1;
                counter2 <= 7;
            when S0 =>
                if(i_start = '1') then
                    o_address <= (4 => '1', 0 => '1', others => '0');
                    NS <= S8;
                    PRS <= S1;
                else
                    o_address <= (others => '0');
                    PRS <= S0;
                end if;
            when S1 =>
                o_address <= (4 => '1', 1 => '1', others => '0');
                Xo <= unsigned("00" & i_data);
                NS <= S8;
                PRS <= S2;
            when S2 =>
                o_address <= (others => '0');
                Yo <= unsigned("00" & i_data);
                NS <= S8;
                PRS <= S3;
            when S3 =>
                o_address <= std_logic_vector(to_unsigned(counter,16));
                bitMask <= i_data;
                NS <= S8;
                PRS <= S4;
            when S4 =>
                counter <= counter + 1;
                o_address <= std_logic_vector(to_unsigned(counter,16));
                Xp <= unsigned("00" & i_data);
                NS <= S8;
                PRS <= S5;
            when S5 =>
                counter <= counter + 1;
                counter2 <= counter2-1;
                o_address <= std_logic_vector(to_unsigned(counter,16));
                Yp <= unsigned("00" & i_data);
                dist_tmp <= to_unsigned(520,10);
                if bitMask(counter2) = '1' then
                    if Yo > Yp then
                        Ydiff <= Yo - Yp;
                    else 
                        Ydiff <= Yp - Yo;
                    end if;
                    if Xo > Xp then
                        Xdiff <= Xo - Xp;
                    else 
                        Xdiff <= Xp - Xo;
                    end if;
                    dist_tmp <= Xdiff + Ydiff;
                    if dist_tmp < min_distance then
                        min_distance <= dist_tmp;
                    end if;
                end if; 
                distances(8-counter/2) <= dist_tmp;
                if counter = 17 then
                    NS <= S6;
                    PRS <= S6;
                else
                    NS <= S8;
                    PRS <= S4;
                end if;
            when S6 =>
                o_we <= '1';
                counter <= 19;
                o_address <= (4 => '1', 1 => '1', 0 => '1', others => '0');
                for i in 0 to 7 loop
                    dist_tmp <= distances(i);
                    if dist_tmp = min_distance then
                       Y_out(i) <= '1';
                    else
                       Y_out(i) <= '0';
                    end if; 
                end loop;
                o_data <= Y_out;
                NS <= S8;
                PRS <= S7;
                -- Faccio i calcoli di uguaglianza, costruisco il mio vettore di uscita, passo alla scrittura in uscita e vado in S9, da S9 poi passer� a S7
            when S7 =>
                o_done <= '1'; 
                o_en <= '0';
                o_address <= (others => '0');
                PRS <= S7;
                if i_start = '0' then
                    o_done <= '0';
                    NS <= RST;
                else                     
                    NS <= S7;
                end if;
                -- Setto un done a 1, e aspetto che start torni a 0 per poter tornare a S0 nel prossimo ciclo di clock, altrimenti rimango in questo stato.               
            when S8 =>
                o_address <= std_logic_vector(to_unsigned(counter,16));
                NS <= PRS;
        end case;
    end process;
    state: process( i_clk )
        begin
        if i_clk'event and i_clk = '1'  then
            if i_rst = '1' then
                PS <= RST;
            else
                PS <= NS;
                counter_prev <= counter;
                counter2_prev <= counter2;
                Xp_prev <= Xp;
                Xo_prev <= Xo;
                Yo_prev <= Yo;
                bitMask_prev <= bitMask;
                PRS_prev <= PRS;
                min_distance_prev <= min_distance;
            end if;
        end if;
    end process;
end Behavioral;
