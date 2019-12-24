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
    front_NReady	    : IN  std_logic := 'U';
	front_Byte  		: OUT std_logic := 'U';  --1 WORD
	HostChoice		 	: OUT std_logic_vector(2 downto 0) := (others => '0');
	front_CS 			: OUT std_logic := '0'
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
wait for 85 ns;
    front_S_Addr <= "101010001010101010";
    wait for 110 ns;
    front_S_Addr <= (others => 'U');
    wait for 400 ns;
    front_S_Addr <= "101111001010101010";
    wait for 20 ns;
    front_S_Addr <= (others => 'U');
    wait for 1340 ns;
    front_S_Addr <= "100000001010100000";
    wait for 20 ns;
    front_S_Addr <= (others => 'U');
    wait for 490 ns;
    front_S_Addr <= "100000001111111000";
    wait for 20 ns;
	front_S_Addr <= (others => 'U');
    wait ;
end process;

byte_process :process
begin
    front_Byte <= '0';
    wait for 1890 ns;
    front_Byte <= '1';
	 wait ;
end process;

host_process :process
begin
    HostChoice <= "000";
    wait for 10 ns;
	HostChoice <= "001";
    wait for 195 ns;
    HostChoice <= "000";
	wait for 10 ns;
	HostChoice <= "100";--write
	wait for 390 ns;
	HostChoice <= "000";--read
	wait for 120 ns;
	hostChoice <= "010";
	wait for 430 ns;
	
	hostChoice <= "011";
	wait for 680 ns;
	hostChoice <= "000";
	wait for 40 ns;
	HostChoice <= "001";
    wait for 195 ns;
    HostChoice <= "000";
	wait for 10 ns;
	HostChoice <= "100";
	wait for 390 ns;
	HostChoice <= "000";--read
	wait for 120 ns;
	hostChoice <= "010";
	wait for 430 ns;
	
	hostChoice <= "011";
	wait for 680 ns;
	hostChoice <= "000";
	wait;
end process;

rst: process
begin
	nRst <= '0';
    wait for 10 ns;
    nRst <= '1';
	 wait for 1865 ns;
	 nRst <= '0';
    wait for 10 ns;
    nRst <= '1';
	wait;
end process;
D_in_proc: process
begin        
	-- hold reset state for 10 ns.
    
    wait for 595 ns;
	front_S_DIn <= "0000000000010010";
	wait for 20 ns;
	front_S_DIn <=(others => 'U');
	wait for 1850 ns;
	front_S_DIn <= "0000110110101110";
	wait for 20 ns;
	front_S_DIn <=(others => 'U');
    wait;
end process;

CS_proc: process
begin        

    front_CS <= '0';
    wait for 3500 ns;
    front_CS <= '1';
    wait for 20 ns;
	front_CS <= '0';
    wait;
end process;

END flow;










