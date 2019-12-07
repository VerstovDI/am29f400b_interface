LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY am29f400b_tester IS

   PORT( 
    clk	   				: OUT std_logic;
	nRst        		: OUT std_logic := 'U';
	front_S_Addr	    : OUT std_logic_vector(17 downto 0) := (others => 'U');
    front_S_DIn         : OUT std_logic_vector(15 downto 0) := (others => 'U');
	front_S_DOut	    : IN  std_logic_vector(15 downto 0) := (others => 'U');
    --front_nCE         	: OUT std_logic := 'U';
    --front_nWE         	: OUT std_logic := 'U';
    front_NReady	    : IN  std_logic := 'U';
	front_Byte  		: OUT std_logic := 'U';  --1 WORD
	HostChoice		 	: OUT     std_logic_vector(2 downto 0) := (others => '0')
   );

END am29f400b_tester ;


ARCHITECTURE flow OF am29f400b_tester   IS
BEGIN
   -- Clock process definitions
clock_process :process
begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
end process;

adr_process :process
begin
    front_S_Addr <= "101010001010101010";
    wait for 130 ns;
    front_S_Addr <= "001000101010101010";
    wait for 100 ns;
end process;

-- Stimulus process
stim_proc: process
begin        
	-- hold reset state for 10 ns.
	front_Byte <= '1';
    nRst <= '0';
    wait for 10 ns;
	--front_nCE <= '1';
	--front_nWE <= '0';
	HostChoice <= "000";
    nRst <= '1';
    wait for 10 ns;
	HostChoice <= "001";
	--front_nCE <= '0';
	--front_nWE <= '1';

    wait for 180 ns; 	
	--front_nCE <= '1';
	--front_nWE <= '0';
	--HostChoice <= "000";
	--wait for 10 ns;
	HostChoice <= "001";
	--front_nCE <= '0';
	--front_nWE <= '1';
    wait for 50 ns; 	
	--front_nCE <= '1';
	--front_nWE <= '0';
	HostChoice <= "000";
	wait for 10 ns;
	--front_nCE <= '0';
	--front_nWE <= '0';
	HostChoice <= "100";
	front_S_DIn <= "1101101000010010";
	wait for 820 ns;
	front_Byte <= '0';
	front_S_DIn <= "0000000010010000";
	wait for 845 ns;
	HostChoice <= "001";--read
    -- wait for 7000 ns;
    -- reset <= '1';
    -- wait for 10 ns;    
    -- reset <= '0';
	wait for 120 ns;
	front_Byte <= '1';
	hostChoice <= "010";
	wait for 430 ns;
	front_Byte <= '0';
	wait for 420 ns;
	front_Byte <= '1';
	hostChoice <= "011";
	wait for 740 ns;
	front_Byte <= '0';
	
	wait for 815 ns;
	front_Byte <= '1';
	hostChoice <= "000";
    wait;
end process;

END flow;


