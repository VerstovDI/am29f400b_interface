LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY am29f400b_interface IS
    
    PORT (
	-- BACKEND TO NOR FLASH
     A			: OUT 	 STD_LOGIC_VECTOR(17 downto 0):= (others => 'U');
     DQ			: INOUT	 STD_LOGIC_VECTOR(15 downto 0):= (others => 'U');
     CE         : OUT    std_logic := 'U';
     OE         : OUT    std_logic := 'U';
     WE         : OUT    std_logic := 'U';
     RESET      : OUT    std_logic := 'U';
     BYTE       : OUT    std_logic := 'U';
     RY         : IN     std_logic := 'U' ; --RY/BY#
	
	-- FRONTEND
     clk       : IN     std_logic;
     nRst      : IN     std_logic := 'U';
     S_Addr    : IN     std_logic_vector(17 downto 0) := (others => 'U');
     S_DIn     : IN     std_logic_vector(15 downto 0) := (others => 'U');
     S_DOut    : OUT    std_logic_vector(15 downto 0) := (others => 'U');
     nCE       : IN     std_logic := 'U';
     nWE       : IN     std_logic := 'U';
     NReady    : OUT    std_logic := 'U'
    );

END am29f400b_interface;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE am29f400b_behavioral of am29f400b_interface IS
	-- FRONTEND
  SIGNAL  S_DOut1	: std_logic_vector(15 downto 0) := (others => 'U');
  SIGNAL  NReady1	: std_logic := 'U';
  
  -- BACKEND
  SIGNAL  A1	        :    STD_LOGIC_VECTOR(17 downto 0):= (others => 'U');
  SIGNAL  DQ1	        :    STD_LOGIC_VECTOR(15 downto 0):= (others => 'U');
  SIGNAL  CE1           :    std_logic := 'U';
  SIGNAL  OE1           :    std_logic := 'U';
  SIGNAL  WE1           :    std_logic := 'U';
  SIGNAL  RESET1        :    std_logic := 'U';
  SIGNAL  BYTE1         :    std_logic := 'U';
  signal t_RC_counter	:    std_logic_vector(3 downto 0);
  signal t_RC_enable	:    std_logic := '0' ; --not allowed counting
  signal t_RH_counter	:    std_logic_vector(2 downto 0);
  signal t_RH_enable	:    std_logic := '0' ; --not allowed counting  
	-----------------------------------------------------------------------------
  TYPE STATE_TYPE IS (
  idle, --waiting state 
  read_s,
  write_s,
  reset_s,
  erase
   );
  -----------------------------------------------------------------------------
SIGNAL current_state : STATE_TYPE ;
SIGNAL next_state    : STATE_TYPE;  
BEGIN
		WE <= WE1;
		OE <= OE1;
		CE <= CE1;
		A  <= A1;
		DQ <= DQ1;
		RESET  <= RESET1;
		BYTE   <= BYTE1;
		S_DOut  <= S_DOut1;
		NReady  <= NReady1;
-----------------------------------------------------------------------------
state_flow: process (Clk, nRst)
begin  -- process state_flow
if (nRst= '0') then                   
    current_state <= reset_s;
elsif (rising_edge(clk)) then    
    case current_state is
      
    when idle =>
        if (nCE = '0') and (nWE = '1') then   
          current_state <= read_s;
        elsif (nCE = '0') and (nWE = '0') then
          current_state <= write_s;
        end if;
		
    when read_s =>	
		if (t_RC_counter = "0000") and (t_RC_enable = '0') then
			current_state <= idle;
		elsif(t_RC_counter /= "0000") and (nCE /= '0') then
			current_state <= reset_s;
		end if;
		
		
    when write_s =>
        if (nCE = '1') then
          current_state <= idle;
        end if;
	   
	when reset_s =>
        if (t_RH_enable = '0') then
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
begin
if (Clk'event and Clk = '1') then
    if (current_state = read_s  ) then
		if (t_RC_enable='0') then
		--	t_RC_enable <= '1';
			t_RC_counter <= "1001"; --9 = 90ns
			A1 <= S_Addr; --save adress in registr
		elsif(t_RC_enable='1') then
			if (t_RC_counter /= "0000") then
				t_RC_counter <= t_RC_counter - '1';
				DQ1 <= (others=>'Z');
				WE1 <= '1';
				CE1 <= '0';
				OE1 <= '0';
				S_DOut1 <= DQ1; 
				NReady1 <= RY ;
				RESET1  <= '1';
			elsif (t_RC_counter = "0000") then				
				--CE1 <= '1';
				--OE1 <= '1';
				--t_RC_enable <= '0';
			end if; 
		end if;
		
	elsif (current_state = reset_s ) then
		--t_RC_enable <= '0'; --not enable counting for counter in read_s state		
		if (t_RH_enable='0') then
			-- t_RH_enable <= '1';
			-- t_RH_counter <= "101"; --5 = 50ns
			RESET1  <= '0';
		elsif(t_RH_enable='1') then
			if (t_RH_counter /= "000") then
			--	t_RH_counter <= t_RH_counter - '1';
				CE1 <= '1';
				OE1 <= '1';
				NReady1 <= RY ;
				RESET1  <= '1';
			elsif (t_RH_counter = "000") then			
				CE1 <= '1';
				OE1 <= '0';
				--t_RH_enable <= '0';
				
			end if; 
		
		end if;

	
	elsif (current_state = idle ) then		
		CE1 <= '1';	
		--t_RH_enable <= '0';
		--t_RC_enable <= '0';
	end if;
	
	
	
	-- t_RH_counter --
	IF (current_state = reset_s and t_RH_enable='0') then 
		t_RH_counter <= "101"; --5 = 50ns
	elsif(current_state = reset_s and t_RH_enable='1') then 
		t_RH_counter <= t_RH_counter - '1';
	end if;
	
end if;
if (Clk'event and Clk = '0') then
	-- t_RH_enable --
	IF (current_state = reset_s  and t_RH_counter /= "000") then 
		t_RH_enable <= '1';
	else
		t_RH_enable <= '0';
	end if;
	
	-- t_RC_enable --
	IF (current_state = read_s  and t_RC_counter = "1001") then 
		t_RC_enable <= '1';
	elsif (current_state = reset_s ) then
		t_RC_enable <= '0'; --not enable counting for counter in read_s state		
	--else
	elsif (current_state = read_s  and t_RC_counter = "0000") then 
		t_RC_enable <= '0';
	end if;
end if;
end process main_flow;
END am29f400b_behavioral;












