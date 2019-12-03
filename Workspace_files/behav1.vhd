LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--------------------------------------------------------------------------------------
-- ENTITY DECLARATION
--------------------------------------------------------------------------------------

ENTITY am29f400b_interface IS
    
    PORT (
		-- BACKEND TO NOR FLASH
		back_A			 : OUT 	  std_logic_vector(17 downto 0) := (others => 'U');
		back_DQ		     : INOUT  std_logic_vector(15 downto 0) := (others => 'U');
		back_CE          : OUT    std_logic := 'U';
		back_OE          : OUT    std_logic := 'U';
		back_WE          : OUT    std_logic := 'U';
		back_RESET       : OUT    std_logic := 'U';
		back_BYTE        : OUT    std_logic := 'U';
		back_RY          : IN     std_logic := 'U';  --back_RY/BY#
		
		-- FRONTEND
		-- HostChoice		 : IN     std_logic_vector(3 downto 0) := (others => '0'); Предлагаю работать с данным сигналом. Правила работы я описал ниже
		clk        	  	 : IN     std_logic;
		front_Byte 	     : IN     std_logic;
		nRst       	     : IN     std_logic := 'U';
		front_nCE        : IN     std_logic := 'U';
		front_nWE        : IN     std_logic := 'U';
		front_nReady     : OUT    std_logic := 'U';
		front_S_Addr     : IN     std_logic_vector(17 downto 0) := (others => 'U');
		front_S_DIn      : IN     std_logic_vector(15 downto 0) := (others => 'U');
		front_S_DOut     : OUT    std_logic_vector(15 downto 0) := (others => 'U')
    );

END am29f400b_interface;


------------------------------------------------------------------------------------
-- Изменил везде сигналы, добавил суффиксы front_ и back_ во всех трёх файлах (tester, tb, behav)
-- Везде скорректировал форматирование
-- Добавил порт nHostChoice. Активный уровень — 1.
-- Возможные ситуации:
-- 		Если host ничего не делает, то host обязан либо послать на frontend HostChoice = "0000", либо ничего не посылать (по умолчанию тоже "000") 
--		Если host хочет обычную операцию чтения (Read), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "001"
-- 		Если host хочет операцию чтения Manufacturer ID (read + Manufacturer_ID), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "010"
--	    Если host хочет операцию записи (write), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "100"
--	    Если host хочет операцию стирания всей флешки (erase), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "011"
--		... Есть задел для ещё 3 операций (101, 110, 111). Этими операциями могут быть, например Erase блока памяти, ещё какое-нибудь чтение или что-нибудь ещё
-- Если что-то падает (CE и в таком духе) - штатно завершаем ситуацию и выдаём, пусть и в пустоту, результат. Проблемы хоста. 
-- Если хост не соблюдает эти правила - проблемы хоста
-- Если есть проблемы - это проблемы хоста

--------------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
--------------------------------------------------------------------------------------

ARCHITECTURE am29f400b_behavioral of am29f400b_interface IS

	-- FRONTEND
	SIGNAL  front_S_DOut1		:    std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL  front_nReady1		:    std_logic := 'U';
	
	-- BACKEND
	SIGNAL back_A1	        	:    std_logic_vector(17 downto 0) := (others => 'U');
	SIGNAL back_DQ1	        	:    std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL back_CE1           	:    std_logic := 'U';
	SIGNAL back_OE1           	:    std_logic := 'U';
	SIGNAL back_WE1           	:    std_logic := 'U';
	SIGNAL back_RESET1        	:    std_logic := 'U';
	SIGNAL back_BYTE1         	:    std_logic := 'U';
	SIGNAL t_RC_counter		    :    std_logic_vector(3 downto 0);
	SIGNAL t_RC_enable		    :    std_logic := '0';  -- counting is not allowed
	SIGNAL t_RH_counter		    :    std_logic_vector(2 downto 0);
	SIGNAL t_RH_enable		    :    std_logic := '0';  -- counting is not allowed  
	SIGNAL t_WC_counter		    :    std_logic_vector(3 downto 0);
	SIGNAL t_WC_enable		    :    std_logic := '0';  -- counting is not allowed  
	SIGNAL t_AH_counter		    :    std_logic_vector(2 downto 0);
	SIGNAL t_AH_enable		    :    std_logic := '0';  -- counting is not allowed
	SIGNAL write_cycle_number	:    std_logic_vector(1 downto 0) := (others => '0');
  
-----------------------------------------------------------------------------
TYPE STATE_TYPE IS (
	idle,     -- waiting state 
	read_s,   -- reading state
	write_w,  -- writing state
	reset_s,  -- reseting state
	erase     -- erasing state
 );
  -----------------------------------------------------------------------------
SIGNAL current_state : STATE_TYPE ;

BEGIN

	back_WE       <= back_WE1;
	back_OE       <= back_OE1;
	back_CE       <= back_CE1;
	back_A        <= back_A1;
	back_DQ       <= back_DQ1;
	back_RESET    <= back_RESET1;
	back_BYTE     <= back_BYTE1;
	front_S_DOut  <= front_S_DOut1;
	front_nReady  <= front_nReady1;

-----------------------------------------------------------------------------

state_flow: process (Clk, nRst)
begin  -- process state_flow
	if (nRst = '0') then                   
		current_state <= reset_s;
	elsif (rising_edge(clk)) then    
		case current_state is  
			when idle =>
				if (front_nCE = '0') and (front_nWE = '1') then   
					current_state <= read_s;
				elsif (front_nCE = '0') and (front_nWE = '0')   then
					current_state <= write_w;
				end if;
				
			when read_s =>	
				if (t_RC_counter = "0000") and (t_RC_enable = '0') and (front_nCE = '1') then
					current_state <= idle;
				elsif(t_RC_counter /= "0000") and (front_nCE /= '0') then
					current_state <= reset_s;
				end if;

			when write_w =>
				if (t_AH_enable = '0' and t_WC_enable = '0' and write_cycle_number = "11" and front_nCE = '1') then
					current_state <= idle;
				end if;
			   
			when reset_s =>
				if (t_RH_enable = '0' and t_RH_counter = "000") then
					current_state <= idle;
				end if;
				
			when erase =>
				if (front_nCE = '1') then
					current_state <= idle;
				end if;
		end case;
	end if;
end process state_flow;

-------------------------------------------------------------------------------
	
main_flow: process (Clk, nRst)
begin
	if (Clk'event and Clk = '1') then
		
		--back_BYTE1 => back_BYTE --
		if(current_state = write_w) then
			if( write_cycle_number = "00" AND t_WC_enable = '0') then
				back_BYTE1 <= front_Byte;
			end if;
		end if;

		--back_RESET1 => back_RESET1 --
		if (current_state = read_s) then
			if(t_RC_enable = '1') then
				if (t_RC_counter /= "0000") then
					back_RESET1 <= '1';
				end if; 
			end if;
		elsif (current_state = reset_s) then
			if (t_RH_enable = '0') then
				back_RESET1 <= '1';
			elsif(t_RH_enable = '1') then
				if (t_RH_counter /= "000") then
					back_RESET1 <= '0';
				end if; 
			end if;
		end if;

		--front_nReady1=>front_nReady --
		if (current_state = read_s) then
			if (t_RC_counter /= "0000") then
				front_nReady1 <= '0' ;
			elsif (t_RC_counter = "0000") then
				front_nReady1 <= '1' ;				
			end if;
		elsif (current_state = reset_s) then
			if(t_RH_enable = '1') then
				if (t_RH_counter /= "000") then
					front_nReady1 <= '0' ;
				end if;
			elsif(t_RH_enable = '0') then
				if (t_RH_counter = "000") then
					front_nReady1 <= '1' ;
				end if;
			end if;
		elsif (current_state = idle) then
			front_nReady1 <= '1' ;	
		elsif (current_state = write_w) then
			front_nReady1 <= back_RY ;
		end if;

		--front_S_DOut1=>front_S_DOut --
		if (current_state = read_s) then
			if(t_RC_enable = '1') then
				if (t_RC_counter /= "0000") then			
					front_S_DOut1 <= back_DQ1; 
				end if;
			end if;
		end if;
		
		--back_A1=>back_A--
		if (current_state = read_s) then
			if (t_RC_enable='0' and t_RC_counter /= "0000") then
				back_A1 <= front_S_Addr; --save adress in registr
			end if;
		elsif(current_state = write_w) then
			if(write_cycle_number = "00" and front_Byte = '1') then
				back_A1 <= "000000010101010101";
			elsif(write_cycle_number = "00" and front_Byte = '0') then
				back_A1 <= "000000101010101010";
			elsif (back_BYTE1 = '1') then  --word 
				if(write_cycle_number = "01") then
					back_A1 <= "000000001010101010";
				elsif(write_cycle_number = "10") then
					back_A1 <= "000000010101010101";
				elsif(write_cycle_number = "11" and t_AH_enable = '0' and t_AH_counter = "101") then
					back_A1 <= front_S_Addr;
				end if;
			elsif(back_BYTE1 = '0') then  --byte
				if(write_cycle_number = "01") then
					back_A1 <= "000000010101010101";
				elsif(write_cycle_number = "10") then
					back_A1 <= "000000101010101010";
				elsif(write_cycle_number = "11" and t_AH_enable = '0' and t_AH_counter = "101") then
					back_A1 <= front_S_Addr;
				end if;
			end if;
		end if;
		
		--back_DQ1=>back_DQ--
		if (current_state = read_s) then
			if(t_RC_enable = '1') then
				if (t_RC_counter /= "0000") then
					back_DQ1 <= (others => 'Z');
				end if;
			end if;
		elsif(current_state = write_w) then
			if( write_cycle_number = "00") then
				back_DQ1 <= "0000000010101010";
			elsif(write_cycle_number = "01") then
				back_DQ1 <= "0000000001010101";
			elsif(write_cycle_number = "10") then
				back_DQ1 <= "0000000010100000";
			elsif(write_cycle_number = "11" and t_AH_enable = '0') then
				back_DQ1 <= front_S_DIn ;
			end if;
		end if;

		--back_OE1=>back_OE --
		if (current_state = read_s) then
			if(t_RC_enable = '1') then
				if (t_RC_counter /= "0000") then				
					back_OE1 <= '0';
				end if;
			end if;
		elsif (current_state = reset_s) then
			if(t_RH_enable = '1') then
				if (t_RH_counter /= "000") then
					back_OE1 <= '1';
				elsif (t_RH_counter = "000") then			
					back_OE1 <= '0';
				end if;
			end if;
		elsif (current_state = write_w) then
			back_OE1 <= '1';
		end if;
		
		--back_WE1=>back_WE --
		if (current_state = read_s) then
			if (t_RC_counter /= "0000") then
				back_WE1 <= '1';
			end if;
		elsif (current_state = write_w) then
			if(t_AH_enable /= '0') then		
				back_WE1 <= '0';		
			elsif(t_WC_enable /= '0') then
				back_WE1 <= '0';
			elsif(t_AH_enable = '0' and t_WC_enable = '0') then	
				back_WE1 <= '1';
			end if;
		end if;

		--back_CE1=>back_CE --
		if (current_state = read_s) then
			if (t_RC_counter /= "0000") then
				back_CE1 <= '0';
			end if;
		elsif (current_state = reset_s) then
			if (t_RH_enable = '1') then
				if (t_RH_counter /= "000") then
					back_CE1 <= '1';
				elsif (t_RH_counter = "000") then			
					back_CE1 <= '1';
				end if;
			end if;
		elsif (current_state = idle) then		
			back_CE1 <= '1';	
		elsif (current_state = write_w) then
			if(t_WC_enable = '0' and t_AH_enable = '0')then
				if(write_cycle_number = "00") then
					back_CE1 <= '1';
				elsif(write_cycle_number = "10") then
					back_CE1 <= '1';
				elsif(write_cycle_number = "01") then
					back_CE1 <= '1';
				elsif(write_cycle_number = "11") then
					back_CE1 <= '1';
				end if;
			elsif (t_WC_enable /= '0') then
				back_CE1 <= '0';
			elsif (t_AH_enable /= '0') then
				back_CE1 <= '0';
			end if;	
		end if;
		
		-- t_RC_counter --
		if (current_state = read_s) then
			if (t_RC_enable = '0') then
				t_RC_counter <= "1001";  --9 = 90ns	
			elsif(t_RC_enable = '1') then
				if (t_RC_counter /= "0000") then
					t_RC_counter <= t_RC_counter - '1';
				end if;
			end if;
		elsif (current_state = reset_s) then
			t_RC_counter <= "1001";  --9 = 90ns	
		end if;
		
		-- t_RH_enable --
		if (current_state = reset_s and t_RH_counter /= "000") then 
			t_RH_enable <= '1';
		elsif (current_state = reset_s and t_RH_counter = "000") then
			t_RH_enable <= '0';
		end if;
		
		-- t_RC_enable --
		if (current_state = read_s and t_RC_counter = "1001") then 
			t_RC_enable <= '1';
		elsif (current_state = reset_s) then
			t_RC_enable <= '0';  --not enable counting for counter in read_s state		
		--else
		elsif (current_state = read_s and t_RC_counter = "0000") then 
			t_RC_enable <= '0';
		end if;

		-- t_RH_counter --
		if (current_state = reset_s and t_RH_enable = '0') then 
			t_RH_counter <= "101";  --5 = 50ns
		elsif(current_state = reset_s and t_RH_enable = '1') then 
			if (t_RH_counter /= "000")then
				t_RH_counter <= t_RH_counter - '1';
			end if;
		end if;
		
		-- t_WC_counter --
		if (current_state = write_w and t_WC_enable = '0') then 
			t_WC_counter <= "1001"; --9 = 90ns
		elsif(current_state = write_w and t_WC_enable = '1') then 
			if (t_WC_counter /= "0000") then
				t_WC_counter <= t_WC_counter - '1';
			end if;
		end if;
		
		-- t_WC_enable --
		if (current_state = write_w and t_WC_counter /= "0000" and write_cycle_number = "00") then 
				t_WC_enable <= '1';
		elsif (current_state = write_w and t_WC_counter /= "0000" and write_cycle_number = "10") then 
			t_WC_enable <= '1';
		elsif (current_state = reset_s) then
			t_WC_enable <= '0';  --not enable counting for counter in read_s state		
		elsif (current_state = write_w and t_WC_counter = "0000") then 
			t_WC_enable <= '0';
		end if;
		
		-- t_AH_enable --
		if (current_state = write_w and t_AH_counter /= "000" and write_cycle_number = "01") then 
			t_AH_enable <= '1';
		elsif (current_state = write_w and t_AH_counter /= "000" and write_cycle_number = "11") then 
			t_AH_enable <= '1';
		elsif (current_state = write_w and t_AH_counter = "000" and write_cycle_number = "01") then
			t_AH_enable <= '0';
		elsif (current_state = write_w and t_AH_counter = "000" and write_cycle_number = "11") then
			t_AH_enable <= '0';
		elsif (current_state = reset_s) then
			t_AH_enable <= '0'; 
		end if;
		
		-- t_AH_counter --
		if (current_state = write_w and t_AH_enable = '0') then 
			t_AH_counter <= "101";  --5 = 50ns
		elsif(current_state = write_w and t_AH_enable = '1') then 
			if (t_AH_counter /= "000") then
				t_AH_counter <= t_AH_counter - '1';
			end if;
		end if;
		
		--write_cycle_number--
		if (current_state = write_w and t_WC_enable = '0' and t_AH_enable = '0') then 
			if (write_cycle_number = "11" and t_AH_counter = "000") then 
				write_cycle_number <= "00";  --0
			elsif ( t_AH_counter = "000" and write_cycle_number = "01" and t_AH_enable = '0') then 
				write_cycle_number <= "10";  --2
			elsif( t_WC_counter = "0000" and write_cycle_number = "00") then 
				write_cycle_number <= "01";  -- 1
			elsif( t_WC_counter = "0000" and write_cycle_number = "10") then 
				write_cycle_number <= "11";  -- 3
			end if;
		end if;

	end if;

end process main_flow;

END am29f400b_behavioral;
