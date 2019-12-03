LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_am29f400b_interface IS
end tb_am29f400b_interface;


ARCHITECTURE struct OF tb_am29f400b_interface IS

	-- FRONTEND
    SIGNAL  clk					:     std_logic;
    SIGNAL  nRst				:     std_logic := 'U';
    SIGNAL  front_S_Addr		:     std_logic_vector(17 downto 0) := (others => 'U');
    SIGNAL  front_S_DIn		    :     std_logic_vector(15 downto 0) := (others => 'U');
    SIGNAL  front_S_DOut		:     std_logic_vector(15 downto 0) := (others => 'U');
    SIGNAL  front_nCE			:     std_logic := 'U';
    SIGNAL  front_nWE			:     std_logic := 'U';
    SIGNAL  front_nReady		:     std_logic := 'U';
	SIGNAL  front_Byte			: 	  std_logic := 'U';
	
	-- BACKEND
    SIGNAL  back_A 		:     std_logic_vector(17 downto 0);  --
    SIGNAL  back_DQ		:     std_logic_vector(15 downto 0) ;  -- DQ15/back_A-1
    SIGNAL  back_CE		:     std_logic ;
    SIGNAL  back_OE		:     std_logic ;
    SIGNAL  back_WE		:     std_logic ;
    SIGNAL  back_RESET	:     std_logic ;
    SIGNAL  back_BYTE	:     std_logic ;
    SIGNAL  back_RY		:     std_logic ;  --RY/BY#

   -- Component Declarations

   COMPONENT am29f400b_interface
   PORT (
     back_A	    	: OUT 	 std_logic_vector(17 downto 0) := (others => 'U');
     back_DQ		: INOUT	 std_logic_vector(15 downto 0) := (others => 'U');
     back_CE      	: OUT    std_logic := 'U';
     back_OE      	: OUT    std_logic := 'U';
     back_WE      	: OUT    std_logic := 'U';
     back_RESET   	: OUT    std_logic := 'U';
     back_BYTE    	: OUT    std_logic := 'U';
     back_RY      	: IN     std_logic := 'U';  --RY/BY#
	
	-- FRONTEND
     clk		    : IN  	 std_logic;
     nRst			: IN  	 std_logic := 'U';
     front_S_Addr	: IN  	 std_logic_vector(17 downto 0) := (others => 'U');
     front_S_DIn    : IN  	 std_logic_vector(15 downto 0) := (others => 'U');
     front_S_DOut	: OUT 	 std_logic_vector(15 downto 0) := (others => 'U');
     front_nCE      : IN  	 std_logic := 'U';
     front_nWE      : IN  	 std_logic := 'U';
     front_nReady   : OUT 	 std_logic := 'U';
	 front_Byte     : IN  	 std_logic  := 'U'
   );
   END COMPONENT;

   COMPONENT am29f400b_tester 
   PORT (
	clk	  	   		: OUT std_logic;
	nRst       		: OUT std_logic := 'U';
	front_S_Addr	: OUT std_logic_vector(17 downto 0) := (others => 'U');
	front_S_DIn     : OUT std_logic_vector(15 downto 0) := (others => 'U');
	front_S_DOut	: IN  std_logic_vector(15 downto 0) := (others => 'U');
	front_nCE       : OUT std_logic := 'U';
	front_nWE       : OUT std_logic := 'U';
	front_nReady	: IN  std_logic := 'U';
	front_Byte 		: OUT std_logic := 'U'
   );
   END COMPONENT;
   

COMPONENT am29f400b ---model
   PORT (
		A17             : IN    std_ulogic ;  --
        A16             : IN    std_ulogic ;  --
        A15             : IN    std_ulogic ;  --
        A14             : IN    std_ulogic ;  --
        A13             : IN    std_ulogic ;  --address
        A12             : IN    std_ulogic ;  --lines
        A11             : IN    std_ulogic ;  --
        A10             : IN    std_ulogic ;  --
        A9              : IN    std_ulogic ;  --
        A8              : IN    std_ulogic ;  --
        A7              : IN    std_ulogic ;  --
        A6              : IN    std_ulogic ;  --
        A5              : IN    std_ulogic ;  --
        A4              : IN    std_ulogic ;  --
        A3              : IN    std_ulogic ;  --
        A2              : IN    std_ulogic ;  --
        A1              : IN    std_ulogic ;  --
        A0              : IN    std_ulogic ;  --
											  
        DQ15            : INOUT std_ulogic ;  -- DQ15/back_A-1
        DQ14            : INOUT std_ulogic ;  --
        DQ13            : INOUT std_ulogic ;  --
        DQ12            : INOUT std_ulogic ;  --
        DQ11            : INOUT std_ulogic ;  --
        DQ10            : INOUT std_ulogic ;  --
        DQ9             : INOUT std_ulogic ;  -- data
        DQ8             : INOUT std_ulogic ;  -- lines
        DQ7             : INOUT std_ulogic ;  --
        DQ6             : INOUT std_ulogic ;  --
        DQ5             : INOUT std_ulogic ;  --
        DQ4             : INOUT std_ulogic ;  --
        DQ3             : INOUT std_ulogic ;  --
        DQ2             : INOUT std_ulogic ;  --
        DQ1             : INOUT std_ulogic ;  --
        DQ0             : INOUT std_ulogic ;  --

        CENeg           : IN    std_ulogic ;
        OENeg           : IN    std_ulogic ;
        WENeg           : IN    std_ulogic ;
        RESETNeg        : IN    std_ulogic ;
        BYTENeg         : IN    std_ulogic ;
        RY              : OUT   std_ulogic   --RY/BY#

   );
   END COMPONENT;


BEGIN

   -- Instance port mappings.
   U_1 : am29f400b_interface 
      PORT MAP (
     back_A	     => back_A,
     back_DQ	 => back_DQ,
     back_CE     => back_CE,
     back_OE     => back_OE,
     back_WE     => back_WE,
     back_RESET  => back_RESET,
     back_BYTE   => back_BYTE,
     back_RY     => back_RY,
	 
	-- FRONTEND
     clk     =>  clk ,
     nRst    =>  nRst,
     front_S_Addr  =>  front_S_Addr,
     front_S_DIn   =>  front_S_DIn,
     front_S_DOut  =>  front_S_DOut,
     front_nCE     =>  front_nCE,
     front_nWE     =>  front_nWE,
     front_nReady  =>  front_nReady,
	 front_Byte    =>  front_Byte
      );

   U_0 : am29f400b_tester
      PORT MAP (    
    clk       	   =>  clk,
	nRst     	   =>  nRst,
	front_S_Addr   =>  front_S_Addr,
	front_S_DIn    =>  front_S_DIn ,
	front_S_DOut   =>  front_S_DOut ,  
	front_nCE      =>  front_nCE ,
	front_nWE      =>  front_nWE ,
	front_nReady   =>  front_nReady,
	front_Byte     =>  front_Byte
      );

--	 U_2 : am29f400b --model
--      PORT MAP (
--     		
--	   A17 =>   back_A(17),
--	   A16 =>   back_A(16),
--	   A15 =>   back_A(15),
--	   A14 =>   back_A(14),
--	   A13 =>   back_A(13),
--	   A12 =>   back_A(12),
--	   A11 =>   back_A(11),
--	   A10 =>   back_A(10),
--	   A9 =>    back_A(9),
--	   A8 =>    back_A(8),
--	   A7 =>    back_A(7),
--	   A6 =>    back_A(6),
--	   A5 =>    back_A(5),
--	   A4 =>    back_A(4),
--	   A3 =>    back_A(3),
--	   A2 =>    back_A(2),
--	   A1 =>    back_A(1),
--	   A0 =>    back_A(0),
--
--	    DQ15 => back_DQ(15),
--	    DQ14 => back_DQ(14),
--	    DQ13 => back_DQ(13),
--	    DQ12 => back_DQ(12),
--	    DQ11 => back_DQ(11),
--	    DQ10 => back_DQ(10),
--	    DQ9 =>  back_DQ(9),
--	    DQ8 =>  back_DQ(8),
--	    DQ7 =>  back_DQ(7),
--	    DQ6 =>  back_DQ(6),
--	    DQ5 =>  back_DQ(5),
--	    DQ4 =>  back_DQ(4),
--	    DQ3 =>  back_DQ(3),
--	    DQ2 =>  back_DQ(2),
--	    DQ1 =>  back_DQ(1),
--	    DQ0 =>  back_DQ(0),
--
--	    CENeg    => CE,
--	    OENeg    => OE,
--	    WENeg    => WE,
--	    RESETNeg => RESET,
--	    BYTENeg  => BYTE,
--	    RY       => RY
--      );
	  
END struct;

