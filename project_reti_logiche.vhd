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
    signal bit_mask : std_logic_vector(7 downto 0);
    signal x_p : std_logic_vector(7 downto 0);
    signal y_p : std_logic_vector(7 downto 0);
    type d_array is array (63 downto 0) of std_logic_vector(7 downto 0);
    signal distances : d_array;
    signal x_tmp : std_logic_vector(7 downto 0);
    signal y_tmp : std_logic_vector(7 downto 0);
    signal min_distance : unsigned;
    signal count : integer;
    signal bit_cons : std_logic;
begin 
    process(i_clk)
    begin
        x_p <= "00000000";
        y_p <= "00000000";
        o_done <= '0';
        o_en <= '1';
        o_we <= '0';
        o_address <= "0000000000010001";
        while x_p = "0000000" loop
            if rising_edge(i_clk) then
                x_p <= i_data;
            end if;
        end loop;
        o_address <= "0000000000010010"; 
        while y_p = "0000000" loop
            if rising_edge(i_clk) then
                y_p <= i_data;
            end if;
        end loop;
        count <= 8;
        for i in 0 to 16 loop
            o_address <= std_logic_vector(to_unsigned(i,16));
            if i > 0 then
                bit_cons <= bit_mask(count);
                if i mod 2 > 0 then
                    if bit_cons = '0' then
                        x_tmp <= "11111111";
                    else
                        x_tmp <= std_logic_vector(to_unsigned(0,8));
                        while x_tmp = "00000000" loop
                            if rising_edge(i_clk) then
                                x_tmp <= i_data;
                            end if;
                        end loop;
                    end if;
                else
                    if bit_cons = '0' then
                        y_tmp <= "11111111";
                    else
                        y_tmp <= std_logic_vector(to_unsigned(0,8));
                        while y_tmp = "00000000" loop
                            if rising_edge(i_clk) then
                                y_tmp <= i_data;
                            end if;
                        end loop;
                    end if;
                    -- CALCOLI LA DISTANZA -> CONFRONTI CON LA DISTANZA MINIMA -> SALVATAGGIO DELLA DISTANZA NELL'ARRAY
                    count <= count - 1;
                end if;
            else
                bit_mask <= i_data;
            end if;
        end loop;
        -- CONFRONTI OGNI ELEMENTO DELLE DISTANZE CON LA DISTANZA -> SALVI I '0' E '1' NELL'ARRAY DI USCITA (BYTE DI USCITA)
        -- SETTO I VALORI PER INTERROGARE NELLA SCRITTURA DELLA MEMORIA -> SETTO DONE A 1 -> ....
    end process;
end Behavioral;
