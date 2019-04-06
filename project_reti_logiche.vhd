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
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;       
        o_en : out std_logic;
        o_we : out std_logic; 
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATO is (RST,S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10);
    type D_ARRAY is array (7 downto 0) of unsigned(8 downto 0);
    signal distances, nextDistances : D_ARRAY;
    signal min_distance, nextMinDistance : unsigned(8 downto 0); --ho calcolato il quadrato
    signal currState, nextState, prevState, nextPrevState : STATO;
    signal bitMask,nextBitMask: std_logic_vector(7 downto 0);
    signal Xp,nextXp,Yp,nextYp,Xc,nextXc,Yc,nextYc : signed(8 downto 0);
    signal maskPtr,nextMaskPtr : integer := 7;
    signal cntrPtr,nextCntrPtr : integer := 1;
    signal distance, nextDistance : unsigned(8 downto 0);
    signal outMask, nextOutMask : std_logic_vector(7 downto 0);                
begin
    delta_lambda : process(currState, nextState, i_start, i_clk,cntrPtr,i_data,bitMask,maskPtr,Xc,Xp,Yc,Yp,distance,
    min_distance,distances, outMask,prevState,nextMinDistance, nextOutMask,nextCntrPtr,nextMaskPtr,nextXp,nextYp,
    nextXc, nextYc, nextDistances, nextPrevState,nextBitMask,nextDistance)
    
        begin   
        nextState <= currState;
        
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
        nextPrevState <= prevState;
        
        o_address <= std_logic_vector(to_unsigned(cntrPtr,16));   
        o_data <= outMask;
        o_done <= '0';
        o_en <= '1';
        o_we <= '0';
        
        case currState is
            when RST =>
                o_en <= '0';
                nextMaskPtr <= 7;
                nextCntrPtr <= 1;
                nextDistances <= (others => to_unsigned(511,9));
                nextMinDistance <= to_unsigned(511,9);
                nextXp <= (others => '0');
                nextYp <= (others => '0');
                nextXc <= (others => '0');
                nextYc <= (others => '0');
                nextOutMask <= (others => '0');
                o_address <= std_logic_vector(to_unsigned(nextCntrPtr,16)); 
                nextState <= S1;
                nextPrevState <= RST;  
            when S0 =>
                if i_start = '1' then                    
                    nextState <= RST;
                else 
                    nextState <= S0;
                end if;
            when S1 =>
                nextCntrPtr <= 0;
                nextPrevState <= S2;
                nextState <= S9;
                o_address <= std_logic_vector(to_unsigned(0,16));
            when S2 =>
                nextBitMask <= i_data;
                nextCntrPtr <= 17;
                nextPrevState <= S3;
                nextState <= S9;
                o_address <= std_logic_vector(to_unsigned(17,16));
            when S3 =>
                nextXc <= signed('0' & i_data);
                nextCntrPtr <= 18;
                nextPrevState <= S4;
                nextState <= S9;
                o_address <= std_logic_vector(to_unsigned(18,16));
            when S4 =>
                nextYc <= signed('0' & i_data);
                nextCntrPtr <= 1;
                nextPrevState <= S5;
                nextState <= S9;
                o_address <= std_logic_vector(to_unsigned(1,16));
            when S5 =>
                nextXp <= signed('0' & i_data);
                nextCntrPtr <= cntrPtr + 1;
                nextPrevState <= S6;
                nextState <= S9;
                o_address <= std_logic_vector(to_unsigned(cntrPtr+1,16));
            when S6 =>
                nextYp <= signed('0' & i_data);
                nextDistance <= unsigned(abs(Xc - Xp)+abs(Yc - nextYp));
                if bitMask(7-maskPtr) = '1' then
                    if nextDistance < min_distance then
                        nextMinDistance <= nextDistance;              
                    end if;
                else
                    nextDistance <= to_unsigned(511,9); 
                end if;
                nextDistances(maskPtr) <= nextDistance;        
                nextMaskPtr <= maskPtr - 1;
                nextCntrPtr <= cntrPtr + 1;
                if cntrPtr = 16 then
                    o_en <= '0';
                    nextState <= S7; 
                else
                    nextPrevState <= S5;
                    nextState <= S9;
                end if;
                o_address <= std_logic_vector(to_unsigned(cntrPtr+1,16));
            when S7 =>
                --report integer'image(to_integer(min_distance));
                for i in 0 to 7 loop
                    if distances(7-i) = min_distance then
                        nextOutMask(i) <= '1';
                    else
                        nextOutMask(i) <= '0';
                    end if;
                    --report integer'image(i) & " - " & integer'image(to_integer(distances(i)));
                end loop;
                o_we <= '1';
                o_data <= nextOutMask;
                nextCntrPtr <= 19;
                o_address <= std_logic_vector(to_unsigned(19,16));
                nextPrevState <= S8;
                nextState <= S9;
            when S8 =>
                o_done <= '1';
                o_en <= '0';
                nextState <= S10;
            when S9 =>
                if cntrPtr = 19 then
                    o_we <= '1';
                end if;
                o_address <= std_logic_vector(to_unsigned(cntrPtr,16));
                nextState <= prevState;
            when S10 =>
                o_en <= '0';
                if i_start = '0' then
                    nextState <= S0;
                else
                    nextState <= S10;
                end if;
        end case;
    end process;
    state: process( i_clk )
        begin
        if( i_clk'event and i_clk = '1' ) then
            if( i_rst = '1' ) then
                currState <= S0;
            else
                currState <= nextState;
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
                prevState <= nextPrevState;                                  
            end if;
        end if;
    end process; 
end Behavioral;