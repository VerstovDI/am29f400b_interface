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
		HostChoice		 : IN     std_logic_vector(2 downto 0) := (others => '0'); -- Правила работы описаны ниже
		clk        	  	 : IN     std_logic;
		front_Byte 	     : IN     std_logic;
		nRst       	     : IN     std_logic := 'U';
		front_nReady     : OUT    std_logic := 'U';
		front_S_Addr     : IN     std_logic_vector(17 downto 0) := (others => 'U');
		front_S_DIn      : IN     std_logic_vector(15 downto 0) := (others => 'U');
		front_recieve  	 : OUT	  std_logic := '0';
		front_S_DOut     : OUT    std_logic_vector(15 downto 0) := (others => 'U');
		front_CS 		 : IN	  std_logic ;--allowed read HostChoice if 0
		front_give_data  : OUT	  std_logic := '0'  -- if 1, host need give addr or/and data
    );

END am29f400b_interface;


------------------------------------------------------------------------------------
-- Изменил везде сигналы, добавил суффиксы front_ и back_ во всех трёх файлах (tester, tb, behav)
-- Везде скорректировал форматирование
-- Добавил порт nHostChoice. Активный уровень — 1.
-- Возможные ситуации:
-- 		Если host ничего не делает (idle), то host обязан либо послать на frontend HostChoice = "000", либо ничего не посылать (по умолчанию тоже "000") 
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
	SIGNAL  front_S_DOut_reg			:    std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL  front_nReady_reg			:    std_logic := 'U';
	SIGNAL  front_recieve_reg  	    : 	  std_logic := '0'; -- 1 when HostChoice change and interface recieve this signal
	-- BACKEND
	SIGNAL back_A_reg	        		:    std_logic_vector(17 downto 0) := (others => 'U');
	SIGNAL back_DQ_reg	        		:    std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL back_CE_reg           		:    std_logic := 'U';
	SIGNAL back_OE_reg           		:    std_logic := 'U';
	SIGNAL back_WE_reg           		:    std_logic := 'U';
	SIGNAL back_RESET_reg        		:    std_logic := 'U';
	SIGNAL back_BYTE_reg         		:    std_logic := 'U';
	SIGNAL t_BUF_counter		    :    std_logic_vector(1 downto 0);
	SIGNAL t_BUF_enable_reg		    	:    std_logic := '0';  -- counting is not allowed  
	SIGNAL t_RC_counter		    	:    std_logic_vector(3 downto 0);
	SIGNAL t_RC_enable_reg		    	:    std_logic := '0';  -- counting is not allowed
	SIGNAL t_RH_counter		    	:    std_logic_vector(2 downto 0);
	SIGNAL t_RH_enable_reg		    	:    std_logic := '0';  -- counting is not allowed  
	SIGNAL t_WC_counter		    	:    std_logic_vector(3 downto 0);
	SIGNAL t_WC_enable_reg		    	:    std_logic := '0';  -- counting is not allowed  
	SIGNAL t_AH_counter		    	:    std_logic_vector(2 downto 0);
	SIGNAL t_AH_enable_reg		    	:    std_logic := '0';  -- counting is not allowed
	SIGNAL t_ERASE_CHECK_counter 	:    std_logic_vector(1 downto 0);
	SIGNAL t_ERASE_CHECK_enable_reg	 	:    std_logic := '0';  -- counting is not allowed
	SIGNAL write_cycle_number		:    std_logic_vector(1 downto 0) := (others => '0');
	SIGNAL erase_cycle_number		:    std_logic_vector(2 downto 0) := (others => '0');
    SIGNAL HostChoice_reg		        :     std_logic_vector(2 downto 0) := (others => '0'); -- регистр
	SIGNAL front_give_data_reg   		:    std_logic := '0'; 
-----------------------------------------------------------------------------
TYPE STATE_TYPE IS (
	idle,     		-- waiting state 
	read_s,   		-- reading state
	write_s,  		-- writing state
	reset_s,  		-- reseting state
	erase_wait, 	-- waiting decision about erasing state
	erase,    		-- chip erasing state
	manufacter_id, 	--reading manufacter id state
	BUF			-- temporary state,reset all registers and etc. 
 );
  -----------------------------------------------------------------------------
SIGNAL current_state : STATE_TYPE ;

BEGIN

	back_WE       <= back_WE_reg;
	back_OE       <= back_OE_reg;
	back_CE       <= back_CE_reg;
	back_A        <= back_A_reg;
	back_DQ       <= back_DQ_reg;
	back_RESET    <= back_RESET_reg;
	back_BYTE     <= back_BYTE_reg;
	front_S_DOut  <= front_S_DOut_reg;
	front_nReady  <= front_nReady_reg;
	front_recieve <= front_recieve_reg;
	front_give_data  <= front_give_data_reg;
-----------------------------------------------------------------------------

state_flow: process (Clk, nRst)
begin  -- process state_flow
	if (nRst = '0') then                   
		current_state <= reset_s;
	elsif (rising_edge(clk) and front_CS ='0') then    
		case current_state is  
			when idle =>
				if HostChoice = "001" then    --(front_nCE = '0') and (front_nWE = '1') 
					current_state <= read_s;
				elsif HostChoice = "100"   then --(front_nCE = '0') and (front_nWE = '0') 
					current_state <= write_s;
				elsif HostChoice = "010"   then
					current_state <= manufacter_id;
				elsif HostChoice = "011"   then
					current_state <= erase_wait;
				end if;
				
			when read_s =>	
				if (t_RC_counter = "0000") and (t_RC_enable_reg = '0')  then 
					current_state <= BUF;
				end if;

			when write_s =>
				if (t_AH_enable_reg = '0' and t_WC_enable_reg = '0' and write_cycle_number = "11" and t_AH_counter="000")  then
					current_state <= BUF;
				end if;
				
			when manufacter_id =>
				if (t_RC_counter = "0000")   and (write_cycle_number = "11") then
					current_state <= BUF;
				end if;
			   
			when reset_s =>
				if (t_RH_enable_reg = '0' and t_RH_counter = "000") then
					current_state <= idle;
				end if;
				
			when erase_wait =>

				if (t_ERASE_CHECK_enable_reg ='0') and (t_ERASE_CHECK_counter="00") then 
					if HostChoice = "001" then    --(front_nCE = '0') and (front_nWE = '1') 
						current_state <= read_s;
					elsif HostChoice = "100"   then --(front_nCE = '0') and (front_nWE = '0') 
						current_state <= write_s;
					elsif HostChoice = "010"   then
						current_state <= manufacter_id;
					elsif HostChoice = "011"   then
						current_state <= erase;
					elsif HostChoice = "000"   then
						current_state <= idle;
					end if;
				end if;	
			when erase =>
				if (t_AH_counter ="000"  and t_AH_enable_reg ='1' and erase_cycle_number = "101") then
					current_state <= BUF;
				end if;
				
			when BUF =>
				if(t_BUF_counter="00" ) and ( t_BUF_enable_reg ='0') then 
					current_state <= idle;
				end if;
		end case;
	end if;
end process state_flow;

-------------------------------------------------------------------------------
	
main_flow: process (Clk, nRst)
begin
	if (nRst = '0') then 
		front_nReady_reg<='0';
		
		front_recieve_reg<='0';
		front_give_data_reg<='0';
		back_A_reg <=(others => 'U');
		back_DQ_reg <=(others => 'U');
		back_CE_reg<='1';
		back_OE_reg<='0';
		back_WE_reg<='1';
		t_RC_counter<="1001";
		t_RC_enable_reg<='0';
		t_WC_counter<="1001";
		t_WC_enable_reg<='0';
		t_AH_counter<="101";
		t_AH_enable_reg<='0';
		t_ERASE_CHECK_counter<="11";
		t_ERASE_CHECK_enable_reg<='0';
		t_BUF_counter<="11";
		t_BUF_enable_reg<='0';
		write_cycle_number<="00";
		erase_cycle_number<="000";
		front_S_DOut_reg<=(others => 'U');
		t_RH_counter <= "101";  --5 = 50ns and enable_reg_reg <=0
		
		back_RESET_reg <= '0';
		t_RH_enable_reg <= '1';	
		
	
	elsif (Clk'event and Clk = '1') then
-- 		Если host ничего не делает (idle), то host обязан либо послать на frontend HostChoice = "000", либо ничего не посылать (по умолчанию тоже "000") 
--		Если host хочет обычную операцию чтения (Read), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "001"
-- 		Если host хочет операцию чтения Manufacturer ID (read + Manufacturer_ID), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "010"
--	    Если host хочет операцию записи (write), то помимо верной конфигурации прочих сигналов он обязан послать HostChoice = "100"		
		back_RESET_reg <= '1';
		
		if(current_state = BUF) then 
			front_nReady_reg<='0';
			front_recieve_reg<='0';
			front_give_data_reg<='0';
			back_A_reg <=(others => 'U');
			back_DQ_reg <=(others => 'U');
			back_CE_reg<='1';
			back_OE_reg<='0';
			back_WE_reg<='1';
			t_RC_counter<="1001";
			t_RC_enable_reg<='0';
			t_WC_counter<="1001";
			t_WC_enable_reg<='0';
			t_AH_counter<="101";
			t_AH_enable_reg<='0';
			t_ERASE_CHECK_counter<="11";
			t_ERASE_CHECK_enable_reg<='0';
			write_cycle_number<="00";
			erase_cycle_number<="000";
			front_S_DOut_reg<=(others => 'U');
			t_RH_counter <= "101";  --5 = 50ns and enable_reg_reg <=0
		end if;
		
		--t_BUF_enable_reg--
		if (current_state = BUF and t_BUF_counter = "11") then 
			t_BUF_enable_reg <= '1';
		elsif (current_state = BUF and t_BUF_counter = "00") then 
			t_BUF_enable_reg <= '0';
		end if;
		
		-- t_BUF_counter --
		if (current_state = BUF) then
			if (t_BUF_enable_reg = '0') then
				t_BUF_counter <= "11";  --9 = 40ns	
			elsif(t_BUF_enable_reg = '1') then
				if (t_BUF_counter /= "00") then
					t_BUF_counter <= t_BUF_counter - '1';
				end if;
			end if;
		end if;
		
		
		--front_give_data_reg--
		if (current_state = write_s) and (t_WC_counter="0000")  and (write_cycle_number="10") then
			front_give_data_reg<='1';
		elsif( current_state = read_s and t_RC_counter="1001")	then
			front_give_data_reg<='1';
		else
			front_give_data_reg<='0';
		end if;
		
		--front_recieve_reg and HostChoice_reg--
		if (HostChoice_reg /= HostChoice) then 
			front_recieve_reg<='1';
			HostChoice_reg <= HostChoice;
		elsif (front_recieve_reg ='1'  and HostChoice_reg = HostChoice) then
			front_recieve_reg<='0';
		end if;
			
		
		--back_BYTE_reg => back_BYTE --
		if(current_state = write_s) then
			if( write_cycle_number = "00" AND t_WC_enable_reg = '0') then
				back_BYTE_reg <= front_Byte;
			end if;
		elsif (current_state = manufacter_id) then
			if( write_cycle_number = "00" AND t_WC_enable_reg = '0') then
				back_BYTE_reg <= front_Byte;
			end if;
		elsif (current_state = erase) then
			if( erase_cycle_number = "000" AND t_WC_enable_reg = '0') then
				back_BYTE_reg <= front_Byte;
			end if;
		elsif (current_state = read_s ) then
			if(  t_RC_counter= "1001") then
				back_BYTE_reg <= front_Byte;
			end if;
		elsif(current_state=reset_s) then
			back_BYTE_reg<=front_Byte;
		end if;

		--back_RESET_reg => back_RESET_reg --
		-- if (current_state = read_s) then
			-- if(t_RC_enable_reg = '1') then
				-- if (t_RC_counter /= "0000") then
					-- back_RESET_reg <= '1';
				-- end if; 
			-- end if;
		-- elsif (current_state = reset_s) then
			-- if (t_RH_enable_reg = '0') then
				-- back_RESET_reg <= '1';
			-- elsif(t_RH_enable_reg = '1') then
				-- if (t_RH_counter /= "000") then
					-- back_RESET_reg <= '0';
				-- end if; 
			-- end if;
		-- end if;

		--front_nReady_reg=>front_nReady --
		if (current_state = read_s) then
			if (t_RC_counter = "1001") then
				front_nReady_reg <= '0' ;
			elsif (t_RC_counter = "0100") then
				front_nReady_reg <= '1' ;	
			elsif (t_RC_counter = "0000") and (t_RC_enable_reg='0') then
				front_nReady_reg <= '0' ;	
			end if;
		elsif (current_state = reset_s) then
			if(t_RH_enable_reg = '1') then
				if (t_RH_counter /= "000") then
					front_nReady_reg <= '0' ;
				end if;
			elsif(t_RH_enable_reg = '0') then
				if (t_RH_counter = "000") then
					front_nReady_reg <= '1' ;
				end if;
			end if;
		elsif (current_state = idle) then
			front_nReady_reg <= '1' ;	
		elsif (current_state = write_s) then
			if(t_AH_counter="000" and write_cycle_number ="11") then 
				front_nReady_reg <= '1' ;
			else 
				front_nReady_reg <= '0' ;
			end if;
		elsif (current_state = erase) then
			if(t_AH_counter="000" and erase_cycle_number ="101" and t_AH_enable_reg ='1') then 
				front_nReady_reg <= '1' ;
			else 
				front_nReady_reg <= '0' ;
			end if;
		elsif (current_state = erase_wait) then
			front_nReady_reg <= '0' ;
		elsif (current_state = manufacter_id) then
			if( write_cycle_number ="11" ) then 	
				if (t_RC_counter = "1001") then
					front_nReady_reg <= '0' ;
				elsif (t_RC_counter = "0100") then
					front_nReady_reg <= '1' ;		
				elsif (t_RC_counter = "0000") then
					front_nReady_reg <= '0' ;	
				END IF;

			end if;
		end if;
		

		--front_S_DOut_reg=>front_S_DOut --
		if (current_state = read_s) then
			if(t_RC_enable_reg = '1') then
				if (t_RC_counter /= "0000") then			
					front_S_DOut_reg <= back_DQ_reg; 
				end if;
			end if;
		elsif(current_state = manufacter_id) then
			if(write_cycle_number = "11" and t_RC_enable_reg='1' and t_RC_counter /= "0000" ) then
				front_S_DOut_reg <= back_DQ_reg; 
			end if;
			
		end if;
		
		--back_A_reg=>back_A--
		if (current_state = read_s) then
			if (t_RC_enable_reg='0' and t_RC_counter /= "0000") then
				back_A_reg <= front_S_Addr; --save adress in registr
			end if;
		elsif(current_state = write_s) then
			if(write_cycle_number = "00" and front_Byte = '1') then
				back_A_reg <= "000000010101010101";
			elsif(write_cycle_number = "00" and front_Byte = '0') then
				back_A_reg <= "000000101010101010";
			elsif (back_BYTE_reg = '1') then  --word 
				if(write_cycle_number = "01") then
					back_A_reg <= "000000001010101010";
				elsif(write_cycle_number = "10") then
					back_A_reg <= "000000010101010101";
				elsif(write_cycle_number = "11" and t_AH_enable_reg = '0' and t_AH_counter = "101") then
					back_A_reg <= front_S_Addr;
				end if;
			elsif(back_BYTE_reg = '0') then  --byte
				if(write_cycle_number = "01") then
					back_A_reg <= "000000010101010101";
				elsif(write_cycle_number = "10") then
					back_A_reg <= "000000101010101010";
				elsif(write_cycle_number = "11" and t_AH_enable_reg = '0' and t_AH_counter = "101") then
					back_A_reg <= front_S_Addr;
				end if;
			end if;
		elsif(current_state = manufacter_id) then
			if(write_cycle_number = "00" and front_Byte = '1') then
				back_A_reg <= "000000010101010101";
			elsif(write_cycle_number = "00" and front_Byte = '0') then
				back_A_reg <= "000000101010101010";
			elsif (back_BYTE_reg = '1') then  --word 
				if(write_cycle_number = "01") then
					back_A_reg <= "000000001010101010";
				elsif(write_cycle_number = "10") then
					back_A_reg <= "000000010101010101";
				elsif(write_cycle_number = "11" and t_AH_enable_reg = '0' ) then
					if (t_RC_enable_reg='0' and t_RC_counter /= "0000") then
						back_A_reg <= "000000000000000000"; --save adress in registr
					end if;
				end if;
			elsif(back_BYTE_reg = '0') then  --byte
				if(write_cycle_number = "01") then
					back_A_reg <= "000000010101010101";
				elsif(write_cycle_number = "10") then
					back_A_reg <= "000000101010101010";
				elsif(write_cycle_number = "11" and t_AH_enable_reg = '0' ) then
					if (t_RC_enable_reg='0' and t_RC_counter /= "0000") then
						back_A_reg <= "000000000000000000"; --save adress in registr
					end if;
				end if;
			end if;
		elsif(current_state = erase) then
			if(erase_cycle_number = "000" and front_Byte = '1') then
				back_A_reg <= "000000010101010101";
			elsif(erase_cycle_number = "000" and front_Byte = '0') then
				back_A_reg <= "000000101010101010";
			elsif (back_BYTE_reg = '1') then  --word 
				if(erase_cycle_number = "001") then
					back_A_reg <= "000000001010101010";
				elsif(erase_cycle_number = "010") then
					back_A_reg <= "000000010101010101";
				elsif(erase_cycle_number = "011") then
					back_A_reg <= "000000010101010101";
				elsif(erase_cycle_number = "100") then
					back_A_reg <= "000000001010101010";
				elsif(erase_cycle_number = "101" and t_AH_enable_reg = '0' and t_AH_counter ="101") then
					back_A_reg <= "000000010101010101";
				elsif(erase_cycle_number = "101"  and t_AH_counter ="000") then
					back_A_reg <= (others => 'U');	
				end if;
			elsif(back_BYTE_reg = '0') then  --byte
				if(erase_cycle_number = "001") then
					back_A_reg <= "000000010101010101";
				elsif(erase_cycle_number = "010") then
					back_A_reg <= "000000101010101010";					
				elsif(erase_cycle_number = "011") then
					back_A_reg <= "000000101010101010";
				elsif(erase_cycle_number = "100") then
					back_A_reg <= "000000010101010101";					
				elsif(erase_cycle_number = "101" and t_AH_enable_reg = '0' and t_AH_counter ="101") then
					back_A_reg <= "000000101010101010";
				
				end if;
			
			end if;
			
		end if;
		
		--back_DQ_reg=>back_DQ--
		if (current_state = read_s) then
			if(t_RC_enable_reg = '1') then
				if (t_RC_counter /= "0000") then
					back_DQ_reg <= (others => 'Z');
				end if;
			end if;
		elsif(current_state = write_s) then
			if( write_cycle_number = "00") then
				back_DQ_reg <= "0000000010101010";
			elsif(write_cycle_number = "01") then
				back_DQ_reg <= "0000000001010101";
			elsif(write_cycle_number = "10") then
				back_DQ_reg <= "0000000010100000";
			elsif(write_cycle_number = "11" and t_AH_enable_reg = '0' and t_AH_counter ="101") then
				back_DQ_reg <= front_S_DIn ;
			end if;
		elsif(current_state = manufacter_id) then
			if( write_cycle_number = "00") then
				back_DQ_reg <= "0000000010101010";
			elsif(write_cycle_number = "01") then
				back_DQ_reg <= "0000000001010101";
			elsif(write_cycle_number = "10") then
				back_DQ_reg <= "0000000010010000";
			elsif(write_cycle_number = "11" and t_AH_enable_reg = '0') then
				back_DQ_reg <= (others => 'Z');
			end if;
		elsif(current_state = erase) then
			if( erase_cycle_number = "000") then
				back_DQ_reg <= "0000000010101010";
			elsif(erase_cycle_number = "001") then
				back_DQ_reg <= "0000000001010101";
			elsif(erase_cycle_number = "010") then
				back_DQ_reg <= "0000000010000000";
			elsif(erase_cycle_number = "011") then
				back_DQ_reg <= "0000000010101010";
			elsif(erase_cycle_number = "100") then
				back_DQ_reg <= "0000000001010101";
			elsif(erase_cycle_number = "101" and t_AH_enable_reg = '0' and t_AH_counter ="101") then
				back_DQ_reg <= "0000000000010000" ;
			end if;
		end if;

		--back_OE_reg=>back_OE --
		if (current_state = read_s) then
			if(t_RC_enable_reg = '1') then
				if (t_RC_counter /= "0000") then				
					back_OE_reg <= '0';
				end if;
			end if;
		elsif (current_state = write_s) then
			back_OE_reg <= '1';
		elsif (current_state = manufacter_id) then
			if ( write_cycle_number /="11") then
				back_OE_reg <= '1';
			elsif ( write_cycle_number ="11") then
				back_OE_reg <= '0';
			end if;
		elsif (current_state = erase) then
			back_OE_reg <= '1';
		end if;
		
		--back_WE_reg=>back_WE --
		if (current_state = read_s) then
			if (t_RC_counter /= "0000") then
				back_WE_reg <= '1';
			end if;				
		elsif (current_state = write_s) then
			if(t_AH_enable_reg /= '0') then		
				back_WE_reg <= '0';		
			elsif(t_WC_enable_reg /= '0') then
				back_WE_reg <= '0';
			elsif(t_AH_enable_reg = '0' and t_WC_enable_reg = '0') then	
				back_WE_reg <= '1';
			end if;
		elsif (current_state = manufacter_id) then
			if(t_AH_enable_reg /= '0') then		
				back_WE_reg <= '0';		
			elsif(t_WC_enable_reg /= '0') then
				back_WE_reg <= '0';
			elsif(t_AH_enable_reg = '0' and t_WC_enable_reg = '0') then	
				back_WE_reg <= '1';
			end if;
		elsif (current_state = erase) then
			if(t_AH_enable_reg /= '0') then		
				back_WE_reg <= '0';		
			elsif(t_WC_enable_reg /= '0') then
				back_WE_reg <= '0';
			elsif(t_AH_enable_reg = '0' and t_WC_enable_reg = '0') then	
				back_WE_reg <= '1';
			end if;
		end if;

		--back_CE_reg=>back_CE --
		if (current_state = read_s) then
			if (t_RC_counter /= "0000") then
				back_CE_reg <= '0';
			end if;
		elsif (current_state = idle) then		
			back_CE_reg <= '1';	
		elsif (current_state = write_s) then
			if(t_WC_enable_reg = '0' and t_AH_enable_reg = '0')then
				if(write_cycle_number = "00") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "10") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "01") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "11") then
					back_CE_reg <= '1';
				end if;
			elsif (t_WC_enable_reg /= '0') then
				back_CE_reg <= '0';
			elsif (t_AH_enable_reg /= '0') then
				back_CE_reg <= '0';
			end if;	
		elsif (current_state = manufacter_id) then
			if(t_WC_enable_reg = '0' and t_AH_enable_reg = '0')then
				if(write_cycle_number = "00") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "10") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "01") then
					back_CE_reg <= '1';
				elsif(write_cycle_number = "11") then
					if (t_RC_counter /= "0000") then
						back_CE_reg <= '0';
					end if;
				end if;
			elsif (t_WC_enable_reg /= '0') then
				back_CE_reg <= '0';
			elsif (t_AH_enable_reg /= '0') then
				back_CE_reg <= '0';
			end if;	
		elsif (current_state = erase) then
			if(t_WC_enable_reg = '0' and t_AH_enable_reg = '0')then
				if(erase_cycle_number = "000") then
					back_CE_reg <= '1';
				elsif(erase_cycle_number = "001") then
					back_CE_reg <= '1';
				elsif(erase_cycle_number = "010") then
					back_CE_reg <= '1';
				elsif(erase_cycle_number = "011") then
					back_CE_reg <= '1';
				elsif(erase_cycle_number = "100") then
					back_CE_reg <= '1';
				elsif(erase_cycle_number = "101") then
					back_CE_reg <= '1';
				end if;
			elsif (t_WC_enable_reg /= '0') then
				back_CE_reg <= '0';
			elsif (t_AH_enable_reg /= '0') then
				back_CE_reg <= '0';
			end if;	
		end if;
		
		-- t_RC_counter --
		if (current_state = read_s) then
			if (t_RC_enable_reg = '0') then
				t_RC_counter <= "1001";  --9 = 90ns	
			elsif(t_RC_enable_reg = '1') then
				if (t_RC_counter /= "0000") then
					t_RC_counter <= t_RC_counter - '1';
				end if;
			end if;
		elsif (current_state = manufacter_id) then
			if (t_RC_enable_reg = '0') then
				t_RC_counter <= "1001";  --9 = 90ns	
			elsif(t_RC_enable_reg = '1') then
				if (t_RC_counter /= "0000") then
					t_RC_counter <= t_RC_counter - '1';
				end if;
			end if;
		end if;
		
		-- t_RH_enable_reg --
			
		if (current_state = reset_s and t_RH_counter = "000") then
			t_RH_enable_reg <= '0';
		end if;
		
		-- t_RC_enable_reg --
		if (current_state = read_s and t_RC_counter = "1001") then 
			t_RC_enable_reg <= '1';
		elsif (current_state = read_s and t_RC_counter = "0000") then 
			t_RC_enable_reg <= '0';
		elsif (current_state = manufacter_id and t_RC_counter = "1001" and write_cycle_number ="11") then 
			t_RC_enable_reg <= '1';
		elsif (current_state = manufacter_id and t_RC_counter = "0000" and write_cycle_number ="11") then 
			t_RC_enable_reg <= '0';
		end if;

		--t_ERASE_CHECK_enable_reg --
		if (current_state = erase_wait and t_ERASE_CHECK_counter = "11") then 
			t_ERASE_CHECK_enable_reg <= '1';
		--else
		elsif (current_state = erase_wait and t_ERASE_CHECK_counter = "00") then 
			t_ERASE_CHECK_enable_reg <= '0';
		end if;
		
		-- t_ERASE_CHECK_counter --
		if (current_state = erase_wait) then
			if (t_ERASE_CHECK_enable_reg = '0') then
				t_ERASE_CHECK_counter <= "11";  --9 = 90ns	
			elsif(t_ERASE_CHECK_enable_reg = '1') then
				if (t_ERASE_CHECK_counter /= "00") then
					t_ERASE_CHECK_counter <= t_ERASE_CHECK_counter - '1';
				end if;
			end if;
		end if;
		
		-- t_RH_counter --
			
		if(current_state = reset_s and t_RH_enable_reg = '1') then 
			if (t_RH_counter /= "000")then
				t_RH_counter <= t_RH_counter - '1';
			end if;
		end if;
		
		-- t_WC_counter --
		if (current_state = write_s and t_WC_enable_reg = '0') then 
			t_WC_counter <= "1001"; --9 = 90ns
		elsif(current_state = write_s and t_WC_enable_reg = '1') then 
			if (t_WC_counter /= "0000") then
				t_WC_counter <= t_WC_counter - '1';
			end if;
		elsif (current_state = manufacter_id and t_WC_enable_reg = '0') then 
			t_WC_counter <= "1001"; --9 = 90ns
		elsif(current_state = manufacter_id and t_WC_enable_reg = '1') then 
			if (t_WC_counter /= "0000") then
				t_WC_counter <= t_WC_counter - '1';
			end if;
		elsif (current_state = erase and t_WC_enable_reg = '0') then 
			t_WC_counter <= "1001"; --9 = 90ns
		elsif(current_state = erase and t_WC_enable_reg = '1') then 
			if (t_WC_counter /= "0000") then
				t_WC_counter <= t_WC_counter - '1';
			end if;
		end if;
		
		-- t_WC_enable_reg --
		if (current_state = write_s and t_WC_counter /= "0000" and write_cycle_number = "00") then 
				t_WC_enable_reg <= '1';
		elsif (current_state = write_s and t_WC_counter /= "0000" and write_cycle_number = "10") then 
			t_WC_enable_reg <= '1';
		elsif (current_state = write_s and t_WC_counter = "0000") then 
			t_WC_enable_reg <= '0';	
		elsif (current_state = manufacter_id and t_WC_counter /= "0000" and write_cycle_number = "00") then 
			t_WC_enable_reg <= '1';
		elsif (current_state = manufacter_id and t_WC_counter /= "0000" and write_cycle_number = "10") then 
			t_WC_enable_reg <= '1';
		elsif (current_state = manufacter_id and t_WC_counter = "0000") then 
			t_WC_enable_reg <= '0';
		elsif  (current_state = erase and t_WC_counter /= "0000") then
			if ( erase_cycle_number = "000") then 
				t_WC_enable_reg <= '1';
			elsif (erase_cycle_number = "010") then 
				t_WC_enable_reg <= '1';
			elsif (erase_cycle_number = "100") then 
				t_WC_enable_reg <= '1';
			end if;
		elsif (current_state = erase and t_WC_counter = "0000") then 
			t_WC_enable_reg <= '0';
		end if;
		
		-- t_AH_enable_reg --
		if (current_state = write_s and t_AH_counter /= "000" and write_cycle_number = "01") then 
			t_AH_enable_reg <= '1';
		elsif (current_state = write_s and t_AH_counter /= "000" and write_cycle_number = "11") then 
			t_AH_enable_reg <= '1';
		elsif (current_state = write_s and t_AH_counter = "000" and write_cycle_number = "01") then
			t_AH_enable_reg <= '0';
		elsif (current_state = write_s and t_AH_counter = "000" and write_cycle_number = "11") then
			t_AH_enable_reg <= '0';
		elsif (current_state = manufacter_id and t_AH_counter /= "000" and write_cycle_number = "01") then 
			t_AH_enable_reg <= '1';
		elsif (current_state = manufacter_id and t_AH_counter = "000" and write_cycle_number = "01") then
			t_AH_enable_reg <= '0';
		elsif (current_state = erase and t_AH_counter /= "000") then
			if ( erase_cycle_number = "001") then 
				t_AH_enable_reg <= '1';			
			elsif (erase_cycle_number = "011") then 
				t_AH_enable_reg <= '1';
			elsif (erase_cycle_number = "101") then 
				t_AH_enable_reg <= '1';
			end if;
		elsif (current_state = erase and t_AH_counter = "000") then 
			if ( erase_cycle_number = "001") then
				t_AH_enable_reg <= '0';
			elsif (erase_cycle_number = "011") then
				t_AH_enable_reg <= '0';
			elsif (erase_cycle_number = "101") then
				t_AH_enable_reg <= '0';
			end if;
		end if;
		
		-- t_AH_counter --
		if (current_state = write_s and t_AH_enable_reg = '0') then 
			t_AH_counter <= "101";  --5 = 50ns
		elsif(current_state = write_s and t_AH_enable_reg = '1') then 
			if (t_AH_counter /= "000") then
				t_AH_counter <= t_AH_counter - '1';
			end if;
		elsif (current_state = manufacter_id and t_AH_enable_reg = '0' ) then 
			t_AH_counter <= "101";  --5 = 50ns
		elsif(current_state = manufacter_id and t_AH_enable_reg = '1') then 
			if (t_AH_counter /= "000") then
				t_AH_counter <= t_AH_counter - '1';
			end if;
		elsif (current_state = erase and t_AH_enable_reg = '0' ) then 
			t_AH_counter <= "101";  --5 = 50ns
		elsif(current_state = erase and t_AH_enable_reg = '1') then 
			if (t_AH_counter /= "000") then
				t_AH_counter <= t_AH_counter - '1';
			end if;
		end if;
		
		--write_cycle_number--
		if (current_state = write_s and t_WC_enable_reg = '0' and t_AH_enable_reg = '0') then 
			if (write_cycle_number = "11" and t_AH_counter = "000") then 
				write_cycle_number <= "00";  --0
			elsif ( t_AH_counter = "000" and write_cycle_number = "01" ) then 
				write_cycle_number <= "10";  --2
			elsif( t_WC_counter = "0000" and write_cycle_number = "00") then 
				write_cycle_number <= "01";  -- 1
			elsif( t_WC_counter = "0000" and write_cycle_number = "10") then 
				write_cycle_number <= "11";  -- 3
			end if;
		elsif (current_state = manufacter_id and t_WC_enable_reg = '0' and t_AH_enable_reg = '0') then 
			if (write_cycle_number = "11" and t_RC_counter = "0000") then 
				write_cycle_number <= "00";  --0
			elsif ( t_AH_counter = "000" and write_cycle_number = "01" ) then 
				write_cycle_number <= "10";  --2
			elsif( t_WC_counter = "0000" and write_cycle_number = "00") then 
				write_cycle_number <= "01";  -- 1
			elsif( t_WC_counter = "0000" and write_cycle_number = "10") then 
				write_cycle_number <= "11";  -- 3
			end if;
		end if;
		
		-- erase_cycle_number	--
		if (current_state = erase and t_WC_enable_reg = '0' ) then 
			if (erase_cycle_number = "101" and t_AH_counter = "000") then 
				erase_cycle_number <= "000";  --0
			elsif( t_WC_counter = "0000" and erase_cycle_number = "000") then 
				erase_cycle_number <= "001";  -- 1
			elsif ( t_AH_counter = "000" and erase_cycle_number = "001" ) then 
				erase_cycle_number <= "010";  --2			
			elsif( t_WC_counter = "0000" and erase_cycle_number = "010") then 
				erase_cycle_number <= "011";  -- 3
			elsif ( t_AH_counter = "000" and erase_cycle_number = "011" ) then 
				erase_cycle_number <= "100";  --4	
			elsif( t_WC_counter = "0000" and erase_cycle_number = "100") then 
				erase_cycle_number <= "101";  -- 5
			end if;
		elsif(current_state = erase_wait and t_ERASE_CHECK_enable_reg='1') then 
			erase_cycle_number <= "000";  --0
			
		end if;
	end if;

end process main_flow;

END am29f400b_behavioral;













