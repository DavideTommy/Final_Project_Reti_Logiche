----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Lichinchi & Lorenzi
-- 
-- Create Date: 28.03.2019 15:32:58
-- Design Name: 
-- Module Name: progetto_reti_logiche - Behavioral
-- Project Name: Final Project Reti Logiche
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
-- o_address è il segnale (vettore) di uscita che manda l'indirizzo alla memoria        
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
    type STATO is (RST,BEGINNER,RAM_WAIT,READ,SAVE,BEGIN_COMPUTE,COMPUTE,COMPARE,WRITE, FINAL);
    type D_ARRAY is array (7 downto 0) of unsigned(8 downto 0);
    signal distances, nextDistances : D_ARRAY;
    signal XorY, nextXorY : integer := 2;
    signal min_distance, nextMinDistance : unsigned(8 downto 0); --ho calcolato il quadrato
    signal currState, nextState, prevState, nextPrevState : STATO := BEGINNER;
    signal bitMask,nextBitMask: std_logic_vector(7 downto 0);
    signal Xp,nextXp,Yp,nextYp,Xc,nextXc,Yc,nextYc : signed(8 downto 0);
    signal maskPtr,nextMaskPtr : integer := 7;
    signal cntrPtr,nextCntrPtr : integer := 1;
    signal distance, nextDistance : unsigned(8 downto 0);
    signal outMask, nextOutMask : std_logic_vector(7 downto 0);                
begin
    delta_lambda : process(currState, nextState, i_start, i_clk, XorY,cntrPtr,i_data,bitMask,maskPtr,Xc,Xp,Yc,Yp,distance,
    min_distance,distances, outMask,prevState,nextMinDistance, nextOutMask,nextCntrPtr,nextMaskPtr,nextXp,nextYp,
    nextXc, nextYc, nextDistances, nextPrevState,nextBitMask,nextDistance,nextXorY)
    
        begin   
        nextState <= currState;
        
        XorY <= nextXorY;
        min_distance <= nextMinDistance;
        outMask <= nextOutMask;
        cntrPtr <= nextCntrPtr;
        maskPtr <= nextMaskPtr;
        Xp <= nextXp;
        Yp <= nextYp;
        Xc <= nextXc;
        Yc <= nextYc;
        distances <= nextDistances;
        prevState <= nextPrevState;
        bitMask <= nextBitMask;
        distance <= nextDistance;
        
        o_address <= std_logic_vector(to_unsigned(cntrPtr,16));   
        o_data <= "00000000";
        o_done <= '0';
        o_en <= '0';
        o_we <= '0';
        
        nextXorY <= XorY;
        nextMaskPtr <= maskPtr;
        nextCntrPtr <= cntrPtr;
        nextMinDistance <= min_distance;
        nextXp <= Xp;
        nextYp <= Yp;
        nextXc <= Xc;
        nextYc <= Yc;
        nextOutMask <= outMask;
        nextDistances <= distances;
        nextBitMask <= bitMask;
        nextDistance <= distance;
        
            case currState is                                
                when BEGINNER =>
                    nextPrevState <= BEGINNER;
                    if i_start = '1' then                    
                        nextState <= RST;
                    else 
                        nextState <= BEGINNER;
                    end if;
                    
                when RST =>
                    nextXorY <= 2;
                    nextMaskPtr <= 7;
                    nextCntrPtr <= 1;
                    nextDistances <= (others => to_unsigned(510,9));
					nextMinDistance <= to_unsigned(510,9);
					nextXp <= (others => '0');
					nextYp <= (others => '0');
					nextXc <= (others => '0');
					nextYc <= (others => '0');
					nextOutMask <= (others => '0');
                    o_address <= std_logic_vector(to_unsigned(cntrPtr,16)); 
                    nextState <= READ;
                    nextPrevState <= RST;  
                    
                when RAM_WAIT =>
                    o_en <= '1';
                    nextPrevState <= prevState;
                    if (prevState = RST or prevState = BEGIN_COMPUTE) then
                        nextState <= SAVE;
                        o_address <= std_logic_vector(to_unsigned(cntrPtr,16)); 
                    else
                        nextState <= FINAL;
                    end if;
                    
                when READ =>
                    o_en <= '1';          
                    if prevState = RST then 
                        if XorY = 0 then
                            nextCntrPtr <= 17;
                        elsif XorY = 1 then
                            nextCntrPtr <= 18;
                        elsif XorY = 2 then
                            nextCntrPtr <= 0; 
                        end if;
                    elsif prevState = BEGIN_COMPUTE then
                        nextCntrPtr <= cntrPtr; 
                    end if;
                    o_address <= std_logic_vector(to_unsigned(cntrPtr,16));
                    nextState <= RAM_WAIT;
                    nextPrevState <= prevState;
                
                when SAVE =>                   
                    if prevState = RST then 
                        if XorY = 0 then
                            nextXp <= signed('0' & i_data);
                            nextXorY <= 1;
                            nextState <= READ;
                            nextPrevState <= prevState; 
                        elsif XorY = 1 then
                            nextYp <= signed('0' & i_data);
                            nextXorY <= 0;
                            nextCntrPtr <= 1;
                            nextMaskPtr <= 7;
                            nextState <= BEGIN_COMPUTE;
                            nextPrevState <= BEGIN_COMPUTE;
                        else
                            nextBitMask <= i_data;
                            nextXorY <= 0;
                            nextState <= READ;
                            nextPrevState <= prevState; 
                        end if;              
                    elsif prevState = BEGIN_COMPUTE then
                        if XorY = 0 then
                            nextXc <= signed('0' & i_data);
                            nextXorY <= 1;
                            nextState <= READ;                          
                        else 
                            nextYc <= signed('0' & i_data);
                            nextXorY <= 0;
                            nextState <= COMPUTE;
                        end if;                
                        nextCntrPtr <= cntrPtr + 1;
                        nextPrevState <= prevState; 
                    end if;
                
                when BEGIN_COMPUTE => 
                    nextPrevState <= BEGIN_COMPUTE;
                    if cntrPtr = 17 then
                        nextState <= COMPARE;
                    else
                        if bitMask(maskPtr) = '1' then
                            nextXorY <= 0;
                            nextState <= READ;
                        else 
                            nextCntrPtr <= cntrPtr + 2;
                            nextDistances(maskPtr) <= to_unsigned(510,9);
                            nextMaskPtr <= maskPtr - 1;
                            nextState <= BEGIN_COMPUTE;
                        end if;
                    end if;
                                      
                when COMPUTE => 
                    nextPrevState <= prevState;                
                    nextDistance <= unsigned(abs(Xc - Xp)+abs(Yc - Yp));
                    if nextDistance < min_distance then
                        nextMinDistance <= nextDistance;              
                    end if; 
                    nextDistances(maskPtr) <= nextDistance;        
                    nextMaskPtr <= maskPtr - 1;
                    
                    if cntrPtr < 17 then
                        nextState <= BEGIN_COMPUTE;
                    else
                        nextState <= COMPARE;
                    end if;
                
                when COMPARE =>
                    nextPrevState <= prevState; 
                    for i in 0 to 7 loop
                        if distances(i) = min_distance then
                            outMask(i) <= '1';
                        else
                            outMask(i) <= '0';
                        end if;
                    end loop;
                    nextState <= WRITE;
                
                when WRITE =>
                    o_en <= '1';
                    o_we <= '1';
                    o_data <= outMask;
                    nextCntrPtr <= 19;
                    o_address <= std_logic_vector(to_unsigned(nextCntrPtr,16));
                    nextPrevState <= currState;
                    nextState <= RAM_WAIT;
                                    
                when FINAL =>
                    o_done <= '1';
                    if (i_start = '0') then
                        o_done <= '0';
                        nextState <= BEGINNER;
                    else
                        nextState <= currState;
                    end if;
                    nextPrevState <= prevState; 
            end case;                
    end process;
    state: process( i_clk )
        begin
        if( i_clk'event and i_clk = '1' ) then
            if( i_rst = '1' ) then
                currState <= BEGINNER;
            else
                currState <= nextState;                                  
            end if;
        end if;
    end process; 
end Behavioral;