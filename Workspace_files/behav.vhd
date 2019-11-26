LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY am29f400b_interface IS
    
    PORT   (
	-- BACKEND TO NOR FLASH
     A		: OUT 	STD_LOGIC_VECTOR(17 downto 0):= (others => 'U');
     DQ		: INOUT	STD_LOGIC_VECTOR(15 downto 0):= (others => 'U');
     CE      : OUT    std_logic := 'U';
     OE      : OUT    std_logic := 'U';
     WE      : OUT    std_logic := 'U';
     RESET   : OUT    std_logic := 'U';
     BYTE    : OUT    std_logic := 'U';
     RY      : IN   std_logic := 'U' ; --RY/BY#
	
	-- FRONTEND
	 clk	   : IN std_logic;
	 nRst      : IN std_logic := 'U';
	 S_Addr	   : IN std_logic_vector(17 downto 0) := (others => 'U');
     S_DIn     : IN std_logic_vector(15 downto 0) := (others => 'U');
	 S_DOut	   : OUT std_logic_vector(15 downto 0) := (others => 'U');
     nCE       : IN std_logic := 'U';
     nWE       : IN std_logic := 'U';
     NReady	   : OUT    std_logic := 'U'
    );

END am29f400b_interface;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE am29f400b_behavioral of am29f400b_interface IS
	-- FRONTEND
	SIGNAL	S_DOut1	      : std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL	NReady1	      : std_logic := 'U';
	
	-- BACKEND
	SIGNAL	A1			  : 	STD_LOGIC_VECTOR(17 downto 0):= (others => 'U');
    SIGNAL  DQ1			  : 	STD_LOGIC_VECTOR(15 downto 0):= (others => 'U');
    SIGNAL  CE1           :    std_logic := 'U';
    SIGNAL  OE1           :    std_logic := 'U';
    SIGNAL  WE1           :     std_logic := 'U';
    SIGNAL  RESET1        :     std_logic := 'U';
    SIGNAL  BYTE1         :     std_logic := 'U';
    signal t_RC_counter	  : std_logic_vector(3 downto 0):= (others => 'U');
	-----------------------------------------------------------------------------
  TYPE STATE_TYPE IS (
  idle, --waiting state 
  read_s,
  write_s,
  erase
  
   );
  -----------------------------------------------------------------------------
SIGNAL current_state : STATE_TYPE ;
SIGNAL next_state       : STATE_TYPE;  --

BEGIN
		WE<= WE1;
		OE <= OE1;
		CE <= CE1;
		A  <= A1;
		DQ  <= DQ1;
		RESET  <= RESET1;
		BYTE  <= BYTE1;
		S_DOut  <= S_DOut1;
		NReady  <= NReady1;
-----------------------------------------------------------------------------
  state_flow: process (Clk, nRst)
 

begin  -- process state_flow
  current_state <= idle;
  if (nRst= '0') then                   
    current_state <= erase;
	--t_RC_counter <= "0000" ;
  elsif (rising_edge(clk)) then    
    case current_state is
      when idle =>
        if (nCE = '0') and (nWE = '1') then   
		  current_state <= read_s;
        elsif (nCE = '0') and (nWE = '0') then
          current_state <= write_s;
		 
        end if;
		
      when read_s =>
		if (t_RC_counter = "0000") then
          current_state <= idle;
        end if;
		
	  when write_s =>
       if (nCE = '1') then
          current_state <= idle;
        end if;
		
	  when erase =>
       if (nCE = '1') then
          current_state <= idle;
        end if;
    end case;
  end if;
end process state_flow;
-------------------------------------------------------------------------------
 main_flow: process (Clk, nRst)
----------- READ_COMMAND_SEQUENCES_ ------------
   
--| t_RC  = 45ns;  |--
--| t_ACC = 45ns;  |--
--| t_CE  = 45ns;  |--
--| t_OE  = 30ns;  |--
--| t_DF  = 15ns;  |--
--| t_OEH = 10ns;  |--
--| t_OH  = 0ns;   |--

-- X = Donâ€™t care
-- RA = Address of the memory location to be read.
-- RD = Data read from location RA during read operation
-- X = Donâ€™t care
-- PA = Address of the memory location to be programmed.
-- Addresses latch on the falling edge of the WE# or CE# pulse, whichever happens later.
-- PD = Data to be programmed at location PA. Data latches on the rising edge of WE# or CE# pulse, whichever happens first.
-- SA = Address of the sector to be verified (in autoselect mode) or erased. Address bits A17â€“A12 uniquely select any sector.

----- READ_ -------
 constant t_RC: STD_LOGIC_VECTOR(3 downto 0):= "1011";-- 11  -55ns;


begin
  if (nRst = '0') then
    t_RC_counter <= "1011";
  elsif (Clk'event and Clk = '1') then
    if (current_state = read_s  ) then   
      if (t_RC_counter /= "0000") then
        t_RC_counter <= t_RC_counter - '1';
        if (t_RC_counter = "0001") then
          CE1 <= '1';
          OE1 <= '1';
        end if;
      else
        t_RC_counter <= "1011";
        DQ1 <= (others=>'Z');
        WE1 <= '1';
        CE1 <= '0';
        OE1 <= '0';
        A1 <= S_Addr;
        S_DOut1 <= DQ1; 		
      end if; 
    end if;
  end if;
---- END OF READ_ -------
 
--äàëåå âñå ÷òî -- íàæàòü un-comment
----- READ_Manufacturer_ID -------
--- Word_mode (if BYTE1=...)
--- First Cycle
--A1 <= x"555";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"2AA";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"555";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X00";
--DQ1 <= x"01";
--
----- Byte_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"AAA";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"555";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"AAA";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X00";
--DQ1 <= x"01";
------- END OF _READ_Manufacturer_ID -------
--
--
------- READ_Device_ID_Top_Boot_Block -------
----- Word_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"555";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"2AA";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"555";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X01";
--DQ1 <= x"2223";
--
----- Byte_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"AAA";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"555";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"AAA";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X02";
--DQ1 <= x"23";
------- !END OF! READ_Device_ID_Top_Boot_Block -------
--
--
------- READ_Device_ID_Bottom_Boot_Block -------
----- Word_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"555";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"2AA";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"555";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X01";
--DQ1 <= x"22AB";
--
----- Byte_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"AAA";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"555";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"AAA";
--DQ1 <= x"90";
----- Fourth Cycle
--A1 <= x"X02";
--DQ1 <= x"AB";
------- !END OF! READ_Device_ID_Bottom_Boot_Block -------
--
------- READ_Sector_Protect_Verify -------
----- Word_mode (if BYTE1=...)
----- First Cycle
------????? (what is it "(SA)\nX02" ?)
------- !END OF! READ_Device_ID_Bottom_Boot_Block -------
--
--
------------- WRITE_COMMAND_SEQUENCES_ ------------
----- Word_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"555";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"2AA";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"555";
--DQ <= x"A0";
----- Fourth Cycle
--A1 <= PA;
--DQ1 <= PD;
--
----- Byte_mode (if BYTE1=...)
----- First Cycle
--A1 <= x"AAA";
--DQ1 <= x"AA";
----- Second Cycle
--A1 <= x"555";
--DQ1 <= x"55";
----- Third Cycle
--A1 <= x"AAA";
--DQ <= x"A0";
----- Fourth Cycle
--A1 <= PA;
--DQ1 <= PD;

end process main_flow;
 
		
	
		
END am29f400b_behavioral;

  














