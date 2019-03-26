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
-- i_clk è il segnale di CLOCK in ingresso generato dal TestBench    
        i_clk : in std_logic;
-- i_start è il segnale di START generato dal Test Bench;        
        i_start : in std_logic;
-- i_rst è il segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale         
        i_rst : in std_logic;
-- i_data è il segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura        
        i_data : in std_logic_vector(7 downto 0);
-- o_address è il segnale (vettore) di uscita che manda l’indirizzo alla memoria        
        o_address : out std_logic_vector(15 downto 0);
-- o_done è il segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria        
        o_done : out std_logic;
-- o_en è il segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura)        
        o_en : out std_logic;
-- o_we è il segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria 
-- esso dev'essere 0.        
        o_we : out std_logic;
-- o_data è il segnale (vettore) di uscita dal componente verso la memoria        
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATO is ( RST, S0, S1, S2, S3, S4, S5, S6, S7, S8 );
    type D_ARRAY is array (63 downto 0) of std_logic_vector(7 downto 0);
    signal PS, NS, PRS : STATO;
    signal Y_out : std_logic_vector (7 downto 0);
    signal Yp, Xp : unsigned;
    signal Yo, Xo : unsigned;
    signal Ydiff, Xdiff : unsigned;
    signal bitMask : std_logic_vector(7 downto 0);
    signal distances : D_ARRAY;
    signal min_distance : unsigned := to_unsigned(255,8);
    signal dist_tmp : unsigned;
    signal counter : integer := 1;
    signal counter2 : integer := 7;
begin
    delta_lambda : process( PS, PRS )
        begin
        case PS is
            when RST =>
                o_address <= (others => '0');
                o_done <= '0';
                o_en <= '1';
                o_we <= '0';
                o_data <= (others => '0');
                NS <= S0;
            when S0 =>
                o_en <= '1';
                o_we <= '0';
                if(i_start = '1') then
                    o_address <= (4 => '1', 0 => '1', others => '0');
                    NS <= S8;
                    PRS <= S1;
                else
                    NS <= S0;
                end if;
            when S1 =>
                Xo <= unsigned(i_data);
                o_en <= '1';
                o_we <= '0';
                o_address <= (4 => '1', 1 => '1', others => '0');
                NS <= S8;
                PRS <= S2;
            when S2 =>
                Yo <= unsigned(i_data);
                o_en <= '1';
                o_we <= '0';
                o_address <= (others => '0');
                NS <= S8;
                PRS <= S3;
            when S3 =>
                bitMask <= i_data;
                o_en <= '1';
                o_we <= '0';
                o_address <= std_logic_vector(to_unsigned(counter,8));
                NS <= S8;
                PRS <= S4;
            when S4 =>
                Xp <= unsigned(i_data);
                counter <= counter + 1;
                o_en <= '1';
                o_we <= '0';
                o_address <= std_logic_vector(to_unsigned(counter,8));
                NS <= S8;
                PRS <= S5;
            when S5 =>
                Yp <= unsigned(i_data);
                counter <= counter + 1;
                o_en <= '1';
                o_we <= '0';
                if bitMask(counter2) = '0' then
                    distances(counter2) <= (others => '1');
                else
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
                    distances(counter2) <= std_logic_vector(dist_tmp);
                end if; 
                counter2 <= counter2 - 1;
                o_address <= std_logic_vector(to_unsigned(counter,8));
                if(counter = 17) then
                    NS <= S6;
                else
                    NS <= S8;
                end if;
            when S6 =>
                for i in 0 to 7 loop
                    dist_tmp <= unsigned(distances(i));
                    if dist_tmp = min_distance then
                       Y_out(i) <= '1';
                    else
                        Y_out(i) <= '0';
                    end if; 
                end loop;
                o_en <= '1';
                o_we <= '1';
                o_address <= (4 => '1', 1 => '1', 0 => '1', others => '0');
                o_data <= Y_out;
                NS <= S8;
                PRS <= S7;
                -- Faccio i calcoli di uguaglianza, costruisco il mio vettore di uscita, passo alla scrittura in uscita e vado in S9, da S9 poi passerò a S7
            when S7 => 
                -- Setto un done a 1, e aspetto che start torni a 0 per poter tornare a S0 nel prossimo ciclo di clock, altrimenti rimango in questo stato.               
            when S8 =>
                o_en <= '1';
                o_we <= '0';
                NS <= PRS;
        end case;
    end process;
    state: process( i_clk )
        begin
        if( i_clk'event and i_clk = '1' ) then
            if( i_rst = '1' ) then
                PS <= RST;
            else
                PS <= NS;
            end if;
        end if;
    end process;    
    output: process( i_clk )
        begin
        if( i_clk'event and i_clk = '1' ) then
            if( i_rst = '1' ) then
                o_data <= (others => '0');
            else
                o_data <= Y;
            end if;
        end if;
    end process; 
end Behavioral;
