LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_am29f400b_interface IS
end tb_am29f400b_interface;


ARCHITECTURE struct OF tb_am29f400b_interface IS

	
	-- FRONTEND
	SIGNAL  clk			:  std_logic;
	SIGNAL  nRst		:  std_logic := 'U';
	SIGNAL S_Addr		:  std_logic_vector(17 downto 0) := (others => 'U');
    SIGNAL S_DIn		:  std_logic_vector(15 downto 0) := (others => 'U');
	SIGNAL S_DOut		:  std_logic_vector(15 downto 0) := (others => 'U');
    SIGNAL  nCE			:  std_logic := 'U';
    SIGNAL nWE			:  std_logic := 'U';
    SIGNAL NReady		:  std_logic := 'U';
		
	SIGNAL  A 			:     STD_LOGIC_VECTOR(17 downto 0); --
	SIGNAL  DQ			:     STD_LOGIC_VECTOR(15 downto 0) ; -- DQ15/A-1
	SIGNAL  CE			:     std_logic ;
	SIGNAL  OE			:     std_logic ;
	SIGNAL  WE			:     std_logic ;
	SIGNAL  RESET		:     std_logic ;
	SIGNAL  BYTE		:     std_logic ;
	SIGNAL  RY			:     std_logic ;  --RY/BY#



   -- Component Declarations

  
   COMPONENT am29f400b_interface
   PORT (
     A	     : OUT 	STD_LOGIC_VECTOR(17 downto 0):= (others => 'U');
     DQ	     : INOUT	STD_LOGIC_VECTOR(15 downto 0):= (others => 'U');
     CE      : OUT    std_logic := 'U';
     OE      : OUT    std_logic := 'U';
     WE      : OUT    std_logic := 'U';
     RESET   : OUT    std_logic := 'U';
     BYTE    : OUT    std_logic := 'U';
     RY      : IN     std_logic := 'U';  --RY/BY#
	
	-- FRONTEND
     clk		: IN  std_logic;
     nRst		: IN  std_logic := 'U';
     S_Addr		: IN  std_logic_vector(17 downto 0) := (others => 'U');
     S_DIn      : IN  std_logic_vector(15 downto 0) := (others => 'U');
     S_DOut		: OUT std_logic_vector(15 downto 0) := (others => 'U');
     nCE        : IN  std_logic := 'U';
     nWE        : IN  std_logic := 'U';
     NReady     : OUT std_logic := 'U'
   );
   END COMPONENT;

   COMPONENT am29f400b_tester 
   PORT (
	clk	  	  : OUT std_logic;
	nRst      : OUT std_logic := 'U';
	S_Addr	  : OUT std_logic_vector(17 downto 0) := (others => 'U');
	S_DIn     : OUT std_logic_vector(15 downto 0) := (others => 'U');
	S_DOut	  : IN  std_logic_vector(15 downto 0) := (others => 'U');
	nCE       : OUT std_logic := 'U';
	nWE       : OUT std_logic := 'U';
	NReady	  : IN  std_logic := 'U'

   );
   END COMPONENT;
   

COMPONENT am29f400b ---model
   PORT (
		A17             : IN    std_ulogic ; --
        A16             : IN    std_ulogic ; --
        A15             : IN    std_ulogic ; --
        A14             : IN    std_ulogic ; --
        A13             : IN    std_ulogic ; --address
        A12             : IN    std_ulogic ; --lines
        A11             : IN    std_ulogic ; --
        A10             : IN    std_ulogic ; --
        A9              : IN    std_ulogic ; --
        A8              : IN    std_ulogic ; --
        A7              : IN    std_ulogic ; --
        A6              : IN    std_ulogic ; --
        A5              : IN    std_ulogic ; --
        A4              : IN    std_ulogic ; --
        A3              : IN    std_ulogic ; --
        A2              : IN    std_ulogic ; --
        A1              : IN    std_ulogic ; --
        A0              : IN    std_ulogic ; --

        DQ15            : INOUT std_ulogic ; -- DQ15/A-1
        DQ14            : INOUT std_ulogic ; --
        DQ13            : INOUT std_ulogic ; --
        DQ12            : INOUT std_ulogic ; --
        DQ11            : INOUT std_ulogic ; --
        DQ10            : INOUT std_ulogic ; --
        DQ9             : INOUT std_ulogic ; -- data
        DQ8             : INOUT std_ulogic ; -- lines
        DQ7             : INOUT std_ulogic ; --
        DQ6             : INOUT std_ulogic ; --
        DQ5             : INOUT std_ulogic ; --
        DQ4             : INOUT std_ulogic ; --
        DQ3             : INOUT std_ulogic ; --
        DQ2             : INOUT std_ulogic ; --
        DQ1             : INOUT std_ulogic ; --
        DQ0             : INOUT std_ulogic ; --

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
     A	    => A,
     DQ	    => DQ,
     CE     => CE,
     OE     => OE,
     WE     => WE,
     RESET  => RESET,
     BYTE   => BYTE,
     RY     => RY,
	-- FRONTEND
     clk     =>  clk ,
     nRst    =>  nRst,
     S_Addr  =>  S_Addr,
     S_DIn   =>  S_DIn,
     S_DOut  =>  S_DOut,
     nCE     =>  nCE,
     nWE     =>  nWE,
     NReady  =>  NReady
      );
      

      
   U_0 : am29f400b_tester
      PORT MAP (
        
    	clk      =>  clk,
	nRst     =>  nRst,
	S_Addr   =>  S_Addr,
	S_DIn    =>  S_DIn ,
	S_DOut   =>  S_DOut ,  
	nCE      =>  nCE ,
	nWE      =>  nWE ,
	NReady   =>  NReady    		  
      );

--	 U_2 : am29f400b --model
--      PORT MAP (
--     		
--	   A17 =>   A(17),
--	   A16 =>   A(16),
--	   A15 =>   A(15),
--	   A14 =>   A(14),
--	   A13 =>   A(13),
--	   A12 =>   A(12),
--	   A11 =>   A(11),
--	   A10 =>   A(10),
--	   A9 =>    A(9),
--	   A8 =>    A(8),
--	   A7 =>    A(7),
--	   A6 =>    A(6),
--	   A5 =>    A(5),
--	   A4 =>    A(4),
--	   A3 =>    A(3),
--	   A2 =>    A(2),
--	   A1 =>    A(1),
--	   A0 =>    A(0),
--
--	    DQ15 => DQ(15),
--	    DQ14 => DQ(14),
--	    DQ13 => DQ(13),
--	    DQ12 => DQ(12),
--	    DQ11 => DQ(11),
--	    DQ10 => DQ(10),
--	    DQ9 =>  DQ(9),
--	    DQ8 =>  DQ(8),
--	    DQ7 =>  DQ(7),
--	    DQ6 =>  DQ(6),
--	    DQ5 =>  DQ(5),
--	    DQ4 =>  DQ(4),
--	    DQ3 =>  DQ(3),
--	    DQ2 =>  DQ(2),
--	    DQ1 =>  DQ(1),
--	    DQ0 =>  DQ(0),
--
--	    CENeg    => CE,
--	    OENeg    => OE,
--	    WENeg    => WE,
--	    RESETNeg => RESET,
--	    BYTENeg  => BYTE,
--	    RY       => RY
--      );
	  
END struct;














