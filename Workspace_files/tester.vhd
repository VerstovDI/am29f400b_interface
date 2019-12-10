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
	HostChoice		 	: OUT std_logic_vector(2 downto 0) := (others => '0')
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
    wait for 340 ns;
    front_S_Addr <= "101111001010101010";
    wait for 20 ns;
    front_S_Addr <= (others => 'U');
    wait for 380 ns;
    front_S_Addr <= "100000001010100000";
    wait for 20 ns;
    front_S_Addr <= (others => 'U');
    wait for 60 ns;
    front_S_Addr <= "100000001111111000";
    wait for 110 ns;
	front_S_Addr <= (others => 'U');
    wait ;
end process;

byte_process :process
begin
    front_Byte <= '1';
    wait for 615 ns;
    front_Byte <= '0';
    wait for 420 ns;
	front_Byte <= '1';
    wait for 520 ns;
	front_Byte <= '0';
	wait for 1170 ns;
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
	HostChoice <= "100";
	wait for 790 ns;
	HostChoice <= "001";--read
	wait for 120 ns;
	hostChoice <= "010";
	wait for 430 ns;
	wait for 420 ns;
	hostChoice <= "011";
	wait for 1340 ns;
	hostChoice <= "000";
	wait;
end process;


D_in_proc: process
begin        
	-- hold reset state for 10 ns.
    nRst <= '0';
    wait for 10 ns;
    nRst <= '1';
    wait for 525 ns;
	front_S_DIn <= "1101101000010010";
	wait for 20 ns;
	front_S_DIn <=(others => 'U');
	wait for 380 ns;
	front_S_DIn <= "0000000000000011";
	wait for 20 ns;
	front_S_DIn <=(others => 'U');
    wait;
end process;

END flow;






