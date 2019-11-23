------------------------------------------------------------------------------
--  File name : am29f400b.vhd
-------------------------------------------------------------------------------
--  Copyright (C) 2003, 2004 Free Model Foundry; http://www.FreeModelFoundry.com
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License version 2 as
--  published by the Free Software Foundation.
--
--  MODIFICATION HISTORY :
--
--  version: | author:         | mod date: | changes made:
--    V1.0    J.Bogosavljevic   03 Dec 10   Initial release
--    V1.1    J.Bogosavljevic   04 Jan 19   memory preload modified
--    V1.2    J.Bogosavljevic   04 Apr 29  -elapsed_erase timer suspended as
--                                         soon as erase suspend command issued
--                                         - CTMOUT bug fix
--                                         - tpd_BYTENeg_Dq0 removed
--    V1.3    J.Bogosavljevic   04 Jun 23  - Unlock bypass mode removed
-------------------------------------------------------------------------------
--  PART DESCRIPTION:
--
--  Library:        AMD
--  Technology:     Flash Memory
--  Part:           am29f400b
--
--  Description:   4Mbit(512K x 8-Bit/256K x 16-Bit) Boot Sector Flash Memory
--                 Boot sector determined by TimingModel generic
--
-------------------------------------------------------------------------------
--  Known Bugs:
--
-------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.std_logic_1164.ALL;
    USE IEEE.VITAL_timing_2000.ALL;
    USE IEEE.VITAL_primitives.ALL;
    ---USE IEEE.prmtvs_p.all
    ---USE IEEE.timing_p.all
    USE STD.textio.ALL;

--library UNISIM;
--use unisim.vcomponents.all;

LIBRARY FMF;    USE FMF.gen_utils.all;
                USE FMF.conversions.all;

-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY am29f400b IS
    GENERIC (
        -- tipd delays: interconnect path delays
        tipd_A0             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A1             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A2             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A3             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A4             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A5             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A6             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A7             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A8             : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A9             : VitalDelayType01 := VitalZeroDelay01; --address
        tipd_A10            : VitalDelayType01 := VitalZeroDelay01; --lines
        tipd_A11            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A12            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A13            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A14            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A15            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A16            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_A17            : VitalDelayType01 := VitalZeroDelay01; --

        tipd_DQ0            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ1            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ2            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ3            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ4            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ5            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ6            : VitalDelayType01 := VitalZeroDelay01; -- data
        tipd_DQ7            : VitalDelayType01 := VitalZeroDelay01; -- lines
        tipd_DQ8            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ9            : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ10           : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ11           : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ12           : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ13           : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ14           : VitalDelayType01 := VitalZeroDelay01; --
        tipd_DQ15           : VitalDelayType01 := VitalZeroDelay01; -- DQ15/A-1

        tipd_CENeg          : VitalDelayType01 := VitalZeroDelay01;
        tipd_OENeg          : VitalDelayType01 := VitalZeroDelay01;
        tipd_WENeg          : VitalDelayType01 := VitalZeroDelay01;
        tipd_RESETNeg       : VitalDelayType01 := VitalZeroDelay01;
        tipd_BYTENeg        : VitalDelayType01 := VitalZeroDelay01;

        -- tpd delays
        tpd_RESETNeg_DQ0    : VitalDelayType01Z := UnitDelay01Z;
        --tACC checked (a->d0, d15->d0)
        tpd_A0_DQ0          : VitalDelayType01  := UnitDelay01;
        tpd_CENeg_DQ0       : VitalDelayType01Z := UnitDelay01Z;
        --(tCE,tCE,tDF,-,tDF,-)
        tpd_OENeg_DQ0       : VitalDelayType01Z := UnitDelay01Z;
        --(tOE,tOE,tDF,-,tDF,-)
        --tBUSY WE->ry, Ce->ry
        tpd_WENeg_RY        : VitalDelayType01  := UnitDelay01;
        tpd_BYTENeg_DQ15    : VitalDelayType01Z := UnitDelay01Z;
        --(tfhqa:-:-, tfhqa,-:-, -:-:tflqz, tfhqa:-:-:, -:-:tflqz, tfhqa:-:-:)

        --tsetup values
        tsetup_A0_CENeg     : VitalDelayType := UnitDelay;  --tAS = 0;
        -- edge \; CE, we, byte-we
        tsetup_DQ0_CENeg    : VitalDelayType := UnitDelay;  --tDS edge / WE CE
        tsetup_OENeg_WENeg  : VitalDelayType := UnitDelay;  --0,edge /
        tsetup_CENeg_WENeg  : VitalDelayType := UnitDelay;  --0 ns /
        --thold values

        thold_A0_CENeg      : VitalDelayType := UnitDelay;  --tAH != 0;
                                                   --edge \; We, CE, BYTE-WE
        thold_DQ0_CENeg     : VitalDelayType := UnitDelay;  --tDH = 0;
                                                   --edge /; WE Ce
        thold_OENeg_WENeg   : VitalDelayType := UnitDelay;  --10,toeh,edge /
        thold_CENeg_WENeg   : VitalDelayType := UnitDelay;  --0 ns tGHVL edge /
        thold_CENeg_RESETNeg: VitalDelayType := UnitDelay;  --tRH = 50 ns;
                                                            -- edge /; ce, oe we
        thold_BYTENeg_CENeg : VitalDelayType := UnitDelay; --telfh=tehfl= 5 ns

        --tpw values: pulse width
        tpw_RESETNeg_negedge: VitalDelayType := UnitDelay; --tRP
        tpw_WENeg_negedge   : VitalDelayType := UnitDelay; --tWP checkicg WE CE
        tpw_WENeg_posedge   : VitalDelayType := UnitDelay; --tWPH checkicg WE CE
        tpw_A0_negedge      : VitalDelayType := UnitDelay; --tWC tRC(90-70)

        -- tdevice values: values for internal delays
            --Program Operation
        --byte write
        tdevice_POB         : VitalDelayType    := 7 us;
        --word write
        tdevice_POW         : VitalDelayType    := 12 us;
            --Sector Erase Operation    tWHWH2
        tdevice_SEO         : VitalDelayType    := 1000 ms;
            --Timing Limit Exceeded
        tdevice_HANG        : VitalDelayType    := 400 ms;
            --program/erase suspend timeout
        tdevice_START_T1    : VitalDelayType    := 20 us;
            --sector erase command sequence timeout
        tdevice_CTMOUT      : VitalDelayType    := 50 us;
            --device ready after Hardware reset(during embeded algorithm)
        tdevice_READY       : VitalDelayType    := 20 us; --tReady max checked

        -- generic control parameters
        InstancePath        : STRING    := DefaultInstancePath;
        TimingChecksOn      : BOOLEAN   := DefaultTimingChecks;
        MsgOn               : BOOLEAN   := DefaultMsgOn;
        XOn                 : BOOLEAN   := DefaultXon;
        -- memory file to be loaded
        mem_file_name       : STRING    := "none";--"am29f400bt.mem";
        prot_file_name      : STRING    := "none";--"am29f400bt_prot.mem";

        UserPreload         : BOOLEAN   := FALSE;--TRUE;
        LongTimming         : BOOLEAN   := TRUE;

        -- For FMF SDF technology file usage
        TimingModel         : STRING    := DefaultTimingModel --"am29f400bt-70"
    );
    PORT (
        A17             : IN    std_ulogic := 'U'; --
        A16             : IN    std_ulogic := 'U'; --
        A15             : IN    std_ulogic := 'U'; --
        A14             : IN    std_ulogic := 'U'; --
        A13             : IN    std_ulogic := 'U'; --address
        A12             : IN    std_ulogic := 'U'; --lines
        A11             : IN    std_ulogic := 'U'; --
        A10             : IN    std_ulogic := 'U'; --
        A9              : IN    std_ulogic := 'U'; --
        A8              : IN    std_ulogic := 'U'; --
        A7              : IN    std_ulogic := 'U'; --
        A6              : IN    std_ulogic := 'U'; --
        A5              : IN    std_ulogic := 'U'; --
        A4              : IN    std_ulogic := 'U'; --
        A3              : IN    std_ulogic := 'U'; --
        A2              : IN    std_ulogic := 'U'; --
        A1              : IN    std_ulogic := 'U'; --
        A0              : IN    std_ulogic := 'U'; --

        DQ15            : INOUT std_ulogic := 'U'; -- DQ15/A-1
        DQ14            : INOUT std_ulogic := 'U'; --
        DQ13            : INOUT std_ulogic := 'U'; --
        DQ12            : INOUT std_ulogic := 'U'; --
        DQ11            : INOUT std_ulogic := 'U'; --
        DQ10            : INOUT std_ulogic := 'U'; --
        DQ9             : INOUT std_ulogic := 'U'; -- data
        DQ8             : INOUT std_ulogic := 'U'; -- lines
        DQ7             : INOUT std_ulogic := 'U'; --
        DQ6             : INOUT std_ulogic := 'U'; --
        DQ5             : INOUT std_ulogic := 'U'; --
        DQ4             : INOUT std_ulogic := 'U'; --
        DQ3             : INOUT std_ulogic := 'U'; --
        DQ2             : INOUT std_ulogic := 'U'; --
        DQ1             : INOUT std_ulogic := 'U'; --
        DQ0             : INOUT std_ulogic := 'U'; --

        CENeg           : IN    std_ulogic := 'U';
        OENeg           : IN    std_ulogic := 'U';
        WENeg           : IN    std_ulogic := 'U';
        RESETNeg        : IN    std_ulogic := 'U';
        BYTENeg         : IN    std_ulogic := 'U';
        RY              : OUT   std_ulogic := 'U'  --RY/BY#
    );
    ATTRIBUTE VITAL_LEVEL0 of am29f400b : ENTITY IS TRUE;
END am29f400b;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE vhdl_behavioral of am29f400b IS
    ATTRIBUTE VITAL_LEVEL0 of vhdl_behavioral : ARCHITECTURE IS TRUE;

    CONSTANT PartID        : STRING  := "am29f400b";
    CONSTANT MaxData       : NATURAL := 16#FF#; --255;
    CONSTANT SecSize       : NATURAL := 16#FFFF#; --65535
    CONSTANT MemSize       : NATURAL := 16#7FFFF#;
    CONSTANT SecNum        : NATURAL := 7;
    CONSTANT SubSecNum     : NATURAL := 3;
    CONSTANT HiAddrBit     : NATURAL := 17;

    -- interconnect path delay signals
    SIGNAL A17_ipd         : std_ulogic := 'U';
    SIGNAL A16_ipd         : std_ulogic := 'U';
    SIGNAL A15_ipd         : std_ulogic := 'U';
    SIGNAL A14_ipd         : std_ulogic := 'U';
    SIGNAL A13_ipd         : std_ulogic := 'U';
    SIGNAL A12_ipd         : std_ulogic := 'U';
    SIGNAL A11_ipd         : std_ulogic := 'U';
    SIGNAL A10_ipd         : std_ulogic := 'U';
    SIGNAL A9_ipd          : std_ulogic := 'U';
    SIGNAL A8_ipd          : std_ulogic := 'U';
    SIGNAL A7_ipd          : std_ulogic := 'U';
    SIGNAL A6_ipd          : std_ulogic := 'U';
    SIGNAL A5_ipd          : std_ulogic := 'U';
    SIGNAL A4_ipd          : std_ulogic := 'U';
    SIGNAL A3_ipd          : std_ulogic := 'U';
    SIGNAL A2_ipd          : std_ulogic := 'U';
    SIGNAL A1_ipd          : std_ulogic := 'U';
    SIGNAL A0_ipd          : std_ulogic := 'U';

    SIGNAL DQ15_ipd        : std_ulogic := 'U';
    SIGNAL DQ14_ipd        : std_ulogic := 'U';
    SIGNAL DQ13_ipd        : std_ulogic := 'U';
    SIGNAL DQ12_ipd        : std_ulogic := 'U';
    SIGNAL DQ11_ipd        : std_ulogic := 'U';
    SIGNAL DQ10_ipd        : std_ulogic := 'U';
    SIGNAL DQ9_ipd         : std_ulogic := 'U';
    SIGNAL DQ8_ipd         : std_ulogic := 'U';
    SIGNAL DQ7_ipd         : std_ulogic := 'U';
    SIGNAL DQ6_ipd         : std_ulogic := 'U';
    SIGNAL DQ5_ipd         : std_ulogic := 'U';
    SIGNAL DQ4_ipd         : std_ulogic := 'U';
    SIGNAL DQ3_ipd         : std_ulogic := 'U';
    SIGNAL DQ2_ipd         : std_ulogic := 'U';
    SIGNAL DQ1_ipd         : std_ulogic := 'U';
    SIGNAL DQ0_ipd         : std_ulogic := 'U';

    SIGNAL CENeg_ipd       : std_ulogic := 'U';
    SIGNAL OENeg_ipd       : std_ulogic := 'U';
    SIGNAL WENeg_ipd       : std_ulogic := 'U';
    SIGNAL RESETNeg_ipd    : std_ulogic := 'U';
    SIGNAL BYTENeg_ipd     : std_ulogic := 'U';

    ---  internal delays
    SIGNAL POB_in           : std_ulogic := '0';
    SIGNAL POB_out          : std_ulogic := '0';
    SIGNAL POW_in           : std_ulogic := '0';
    SIGNAL POW_out          : std_ulogic := '0';
    SIGNAL SEO_in           : std_ulogic := '0';
    SIGNAL SEO_out          : std_ulogic := '0';

    SIGNAL HANG_out        : std_ulogic := '0'; --Program/Erase Timing Limit
    SIGNAL HANG_in         : std_ulogic := '0';
    SIGNAL START_T1_out        : std_ulogic := '0'; --Start TimeOut; SUSPEND
    SIGNAL START_T1_in     : std_ulogic := '0';
    SIGNAL CTMOUT_out          : std_ulogic := '0'; --Sector Erase TimeOut
    SIGNAL CTMOUT_in       : std_ulogic := '0';
    SIGNAL READY_in        : std_ulogic := '0';
    SIGNAL READY_out           : std_ulogic := '0'; -- Device ready after reset
BEGIN

    ---------------------------------------------------------------------------
    -- Internal Delays
    ---------------------------------------------------------------------------
    -- Artificial VITAL primitives to incorporate internal delays
    POB    :VitalBuf(POB_out,  POB_in,    (tdevice_POB     ,UnitDelay));
    POW    :VitalBuf(POW_out,  POW_in,    (tdevice_POW     ,UnitDelay));
    SEO    :VitalBuf(SEO_out, SEO_in,     (tdevice_SEO     ,UnitDelay));
    HANG   :VitalBuf(HANG_out,HANG_in,    (tdevice_HANG    ,UnitDelay));
    START_T1  :VitalBuf(START_T1_out,START_T1_in,(tdevice_START_T1,UnitDelay));
    CTMOUT :VitalBuf(CTMOUT_out, CTMOUT_in, (tdevice_CTMOUT-5 ns, UnitDelay));
    READY  :VitalBuf(READY_out,   READY_in,   (tdevice_READY   ,UnitDelay));
    ---------------------------------------------------------------------------
    -- Wire Delays
    ---------------------------------------------------------------------------
    WireDelay : BLOCK
    BEGIN
        w_0  : VitalWireDelay (A17_ipd, A17, tipd_A17);
        w_1  : VitalWireDelay (A16_ipd, A16, tipd_A16);
        w_2  : VitalWireDelay (A15_ipd, A15, tipd_A15);
        w_3  : VitalWireDelay (A14_ipd, A14, tipd_A14);
        w_4  : VitalWireDelay (A13_ipd, A13, tipd_A13);
        w_5  : VitalWireDelay (A12_ipd, A12, tipd_A12);
        w_6  : VitalWireDelay (A11_ipd, A11, tipd_A11);
        w_7  : VitalWireDelay (A10_ipd, A10, tipd_A10);
        w_8  : VitalWireDelay (A9_ipd, A9, tipd_A9);
        w_9  : VitalWireDelay (A8_ipd, A8, tipd_A8);
        w_10 : VitalWireDelay (A7_ipd, A7, tipd_A7);
        w_11 : VitalWireDelay (A6_ipd, A6, tipd_A6);
        w_12 : VitalWireDelay (A5_ipd, A5, tipd_A5);
        w_13 : VitalWireDelay (A4_ipd, A4, tipd_A4);
        w_14 : VitalWireDelay (A3_ipd, A3, tipd_A3);
        w_15 : VitalWireDelay (A2_ipd, A2, tipd_A2);
        w_16 : VitalWireDelay (A1_ipd, A1, tipd_A1);
        w_17 : VitalWireDelay (A0_ipd, A0, tipd_A0);

        w_18 : VitalWireDelay (DQ15_ipd, DQ15, tipd_DQ15);
        w_19 : VitalWireDelay (DQ14_ipd, DQ14, tipd_DQ14);
        w_20 : VitalWireDelay (DQ13_ipd, DQ13, tipd_DQ13);
        w_21 : VitalWireDelay (DQ12_ipd, DQ12, tipd_DQ12);
        w_22 : VitalWireDelay (DQ11_ipd, DQ11, tipd_DQ11);
        w_23 : VitalWireDelay (DQ10_ipd, DQ10, tipd_DQ10);
        w_24 : VitalWireDelay (DQ9_ipd, DQ9, tipd_DQ9);
        w_25 : VitalWireDelay (DQ8_ipd, DQ8, tipd_DQ8);
        w_26 : VitalWireDelay (DQ7_ipd, DQ7, tipd_DQ7);
        w_27 : VitalWireDelay (DQ6_ipd, DQ6, tipd_DQ6);
        w_28 : VitalWireDelay (DQ5_ipd, DQ5, tipd_DQ5);
        w_29 : VitalWireDelay (DQ4_ipd, DQ4, tipd_DQ4);
        w_30 : VitalWireDelay (DQ3_ipd, DQ3, tipd_DQ3);
        w_31 : VitalWireDelay (DQ2_ipd, DQ2, tipd_DQ2);
        w_32 : VitalWireDelay (DQ1_ipd, DQ1, tipd_DQ1);
        w_33 : VitalWireDelay (DQ0_ipd, DQ0, tipd_DQ0);
        w_34 : VitalWireDelay (OENeg_ipd, OENeg, tipd_OENeg);
        w_35 : VitalWireDelay (WENeg_ipd, WENeg, tipd_WENeg);
        w_36 : VitalWireDelay (RESETNeg_ipd, RESETNeg, tipd_RESETNeg);
        w_37 : VitalWireDelay (CENeg_ipd, CENeg, tipd_CENeg);
        w_38 : VitalWireDelay (BYTENeg_ipd, BYTENeg, tipd_BYTENeg);

    END BLOCK;

    ---------------------------------------------------------------------------
    -- Main Behavior Block
    ---------------------------------------------------------------------------
    Behavior: BLOCK

        PORT (
            A              : IN    std_logic_vector(HiAddrBit downto 0) :=
                                               (OTHERS => 'U');
            DIn            : IN    std_logic_vector(15 downto 0) :=
                                               (OTHERS => 'U');
            DOut           : OUT   std_ulogic_vector(15 downto 0) :=
                                               (OTHERS => 'Z');
            CENeg          : IN    std_ulogic := 'U';
            OENeg          : IN    std_ulogic := 'U';
            WENeg          : IN    std_ulogic := 'U';
            RESETNeg       : IN    std_ulogic := 'U';
            BYTENeg        : IN    std_ulogic := 'U';
            RY             : OUT   std_ulogic := 'U'
        );
        PORT MAP (
            A(17)    => A17_ipd,
            A(16)    => A16_ipd,
            A(15)    => A15_ipd,
            A(14)    => A14_ipd,
            A(13)    => A13_ipd,
            A(12)    => A12_ipd,
            A(11)    => A11_ipd,
            A(10)    => A10_ipd,
            A(9)     => A9_ipd,
            A(8)     => A8_ipd,
            A(7)     => A7_ipd,
            A(6)     => A6_ipd,
            A(5)     => A5_ipd,
            A(4)     => A4_ipd,
            A(3)     => A3_ipd,
            A(2)     => A2_ipd,
            A(1)     => A1_ipd,
            A(0)     => A0_ipd,

            DIn(15)  => DQ15_ipd,
            DIn(14)  => DQ14_ipd,
            DIn(13)  => DQ13_ipd,
            DIn(12)  => DQ12_ipd,
            DIn(11)  => DQ11_ipd,
            DIn(10)  => DQ10_ipd,
            DIn(9)   => DQ9_ipd,
            DIn(8)   => DQ8_ipd,
            DIn(7)   => DQ7_ipd,
            DIn(6)   => DQ6_ipd,
            DIn(5)   => DQ5_ipd,
            DIn(4)   => DQ4_ipd,
            DIn(3)   => DQ3_ipd,
            DIn(2)   => DQ2_ipd,
            DIn(1)   => DQ1_ipd,
            DIn(0)   => DQ0_ipd,

            DOut(15) => DQ15,
            DOut(14) => DQ14,
            DOut(13) => DQ13,
            DOut(12) => DQ12,
            DOut(11) => DQ11,
            DOut(10) => DQ10,
            DOut(9)  => DQ9,
            DOut(8)  => DQ8,
            DOut(7)  => DQ7,
            DOut(6)  => DQ6,
            DOut(5)  => DQ5,
            DOut(4)  => DQ4,
            DOut(3)  => DQ3,
            DOut(2)  => DQ2,
            DOut(1)  => DQ1,
            DOut(0)  => DQ0,

            CENeg    => CENeg_ipd,
            OENeg    => OENeg_ipd,
            WENeg    => WENeg_ipd,
            RESETNeg => RESETNeg_ipd,
            BYTENeg  => BYTENeg_ipd,
            RY       => RY
        );

        -- State Machine : State_Type
        TYPE state_type IS (
                            RESET,
                            Z001,
                            PREL_SETBWB,
                            AS,
                            A0SEEN,
                            C8,
                            C8_Z001,
                            C8_PREL,
                            ERS,
                            SERS,
                            ESPS,
                            SERS_EXEC,
                            ESP,
                            ESP_Z001,
                            ESP_PREL,
                            ESP_A0SEEN,
                            ESP_AS,
                            PGMS
                            );

        --Array of Sub sector start-end address within sector
        TYPE SubSecSEAddr IS ARRAY (0 TO SubSecNum) OF
                     NATURAL;

        --Addresses of all Sectors devided to sub sectors
        TYPE SubSecAddr IS ARRAY (0 TO 1) OF
                     SubSecSEAddr;--SecType;

        --Flash Memory Array
        TYPE SecType  IS ARRAY (0 TO SecSize) OF
                         INTEGER RANGE -1 TO MaxData;

        TYPE MemArray IS ARRAY (0 TO SecNum) OF
                         SecType;

        -- states
        SIGNAL current_state    : state_type;  --
        SIGNAL next_state       : state_type;  --

        -- powerup
        SIGNAL PoweredUp        : std_logic := '0';

        --zero delay signals
        SIGNAL DOut_zd          : std_logic_vector(15 downto 0):=(OTHERS=>'Z');
        SIGNAL RY_zd            : std_logic := 'Z';

        --FSM control signals
        SIGNAL ESP_ACT          : std_logic := '0'; --Erase Suspend

        --Model should never hang!!!!!!!!!!!!!!!
        SIGNAL HANG             : std_logic := '0';

        SIGNAL PDONE            : std_logic := '1'; --Prog. Done
        SIGNAL PSTART           : std_logic := '0'; --Start Programming

        --Program location is in protected sector
        SIGNAL PERR             : std_logic := '0';

        SIGNAL EDONE            : std_logic := '1'; --Ers. Done
        SIGNAL ESTART           : std_logic := '0'; --Start Erase
        SIGNAL ESUSP            : std_logic := '0'; --Suspend Erase
        SIGNAL ERES             : std_logic := '0'; --Resume Erase
        --All sectors selected for erasure are protected
        SIGNAL EERR             : std_logic := '0';
        --Sectors selected for erasure
        SIGNAL ERS_QUEUE        : std_logic_vector(SecNum downto 0) :=
                                                   (OTHERS => '0');
        SIGNAL ERS_SUB_QUEUE    : std_logic_vector(SubSecNum downto 0) :=
                                                   (OTHERS => '0');

        --Command Register
        SIGNAL write            : std_logic := '0';
        SIGNAL read             : std_logic := '0';

        --Sector Address
        SIGNAL SecAddr          : NATURAL RANGE 0 TO SecNum := 0;
        SIGNAL SubSect          : NATURAL RANGE 0 TO SubSecNum := 0;

        SIGNAL SA               : NATURAL RANGE 0 TO SecNum := 0;
        SIGNAL SSA              : NATURAL RANGE 0 TO SubSecNum := 0;
        SIGNAL WBPage           : NATURAL;

        --Address within sector
        SIGNAL Address          : NATURAL RANGE 0 TO SecSize := 0;

        SIGNAL D_tmp0           : NATURAL RANGE 0 TO MaxData;
        SIGNAL D_tmp1           : NATURAL RANGE 0 TO MaxData;

        --A17:A11 Don't Care
        SIGNAL Addr             : NATURAL RANGE 0 TO 16#7FF# := 0;
        SIGNAL WPage            : NATURAL RANGE 0 TO 16#7FF# := 0;--
        --glitch protection
        SIGNAL gWE_n            : std_logic := '1';
        SIGNAL gCE_n            : std_logic := '1';
        SIGNAL gOE_n            : std_logic := '1';

        SIGNAL RST              : std_logic := '1';
        SIGNAL reseted          : std_logic := '0';

            -- Mem(SecAddr)(Address)....
        SHARED VARIABLE Mem         : MemArray := (OTHERS =>(OTHERS=> MaxData));

        SHARED VARIABLE Sec_Prot    : std_logic_vector(SecNum downto 0) :=
                                                   (OTHERS => '0');
        SHARED VARIABLE SubSec_Prot : std_logic_vector(SubSecNum downto 0) :=
                                                   (OTHERS => '0');
        --am29f400bt
        SHARED VARIABLE sssa        : SubSecAddr :=
                                   ((16#0000#, 16#4000#, 16#6000#, 16#8000#),
                                    ( 16#0000#, 16#8000#, 16#A000#, 16#C000#));

        SHARED VARIABLE ssea        : SubSecAddr:=
                                   ((16#3FFF#, 16#5FFF#, 16#7FFF#, 16#FFFF#),
                                    (16#7FFF#, 16#9FFF#, 16#BFFF#, 16#FFFF#));

        -- timing check violation
        SIGNAL Viol                : X01 := '0';

        --Address of variable size sector (bottom or top boot sector)
        SIGNAL VarSect             : INTEGER := -1;
        SIGNAL vs                  : INTEGER;--0 if VarSect = 0 else 1
        -- Address of the Protected Sector

    PROCEDURE MemRead (
                       SIGNAL SecAddr     : IN NATURAL RANGE 0 TO SecNum;
                       SIGNAL Address     : IN NATURAL RANGE 0 TO SecSize;
                       SIGNAL BYTENeg     : IN std_ulogic;
                       SIGNAL DOut_zd     : INOUT std_logic_vector(15 downto 0)
                       ) IS

    BEGIN
        IF Mem(SecAddr)(Address) = -1 THEN
            DOut_zd(7 downto 0) <= (OTHERS => 'X');
        ELSE
            DOut_zd(7 downto 0) <= to_slv(Mem(SecAddr)(Address),8);
        END IF;
        IF BYTENeg = '1' THEN
            IF Mem(SecAddr)(Address + 1) = -1 THEN
                DOut_zd(15 downto 8) <= (OTHERS => 'X');
            ELSE
                DOut_zd(15 downto 8) <=
                    to_slv(Mem(SecAddr)(Address + 1),8);
            END IF;
        END IF;
    END MemRead;

    PROCEDURE AsRead (
                       SIGNAL Address      : IN NATURAL RANGE 0 TO SecSize;
                       SIGNAL BYTENeg      : IN std_ulogic;
                       SIGNAL vs           : IN INTEGER;
                       SIGNAL SecAddr      : IN NATURAL RANGE 0 TO SecNum;
                       SIGNAL SubSect      : IN NATURAL RANGE 0 TO SubSecNum;
                       SIGNAL DOut_zd      : INOUT std_logic_vector(15 downto 0)
                       ) IS
    BEGIN
        IF BYTENeg = '1' THEN
            IF Address = 0 THEN
                DOut_zd(15 downto 8) <= to_slv(0,8);
            ELSE
                DOut_zd(15 downto 8) <= to_slv(16#22#,8);
            END IF;
        ELSE
            DOut_zd(15 downto 8) <= "ZZZZZZZZ";
        END IF;
            IF Addr = 0 THEN
                DOut_zd(7 downto 0) <= to_slv(1,8);
            ELSIF Addr = 1 THEN
                IF vs = 1 THEN
                    DOut_zd(7 downto 0) <= to_slv(16#23#,8);
                ELSE
                    DOut_zd(7 downto 0) <= to_slv(16#AB#,8);
                END IF;
            ELSIF Addr = 2 THEN
                DOut_zd(7 downto 1) <= to_slv(0,7);
                IF (SecAddr = VarSect) THEN
                    DOut_zd(0) <= SubSec_Prot(SubSect);
                ELSE
                    DOut_zd(0) <= Sec_Prot(SecAddr);
                END IF;
            END IF;
    END AsRead;
    PROCEDURE RestoreSectAddr (
                       VARIABLE A           : IN NATURAL RANGE 0 TO MemSize;
                       VARIABLE SecAddr     : INOUT NATURAL RANGE 0 TO SecNum;
                       VARIABLE A_tmp       : INOUT NATURAL RANGE 0 TO SecSize
                       ) IS
        VARIABLE SA_tmp      : NATURAL RANGE 0 TO SecNum;
    BEGIN

        FOR i IN 0 TO SecNum LOOP
            IF A >= i*(SecSize+1) AND A <= i*(SecSize+1) + SecSize THEN
                SecAddr := i;
                A_tmp := A - i*(SecSize + 1);
            END IF;
        END LOOP;

    END RestoreSectAddr;

    BEGIN

    ---------------------------------------------------------------------------
    --VarSect
    ---------------------------------------------------------------------------
    VarSect <= SecNum WHEN TimingModel(1 to 10)="am29f400bt" ELSE
             0;--WHEN TimingModel = "am29f400bB"

    vs <= 1 WHEN TimingModel(1 to 10)="am29f400bt" ELSE
              0;
   ----------------------------------------------------------------------------
    --Power Up time 100 ns;
    ---------------------------------------------------------------------------
    PoweredUp <= '1' AFTER 100 ns;

    RST <= RESETNeg AFTER 500 ns;

    ---------------------------------------------------------------------------
    -- VITAL Timing Checks Procedures
    ---------------------------------------------------------------------------
    VITALTimingCheck: PROCESS(A, Din, CENeg, OENeg, WENeg, RESETNeg)--, WPNeg)
         -- Timing Check Variables
        VARIABLE Tviol_A0_CENeg        : X01 := '0';
        VARIABLE TD_A0_CENeg           : VitalTimingDataType;

        VARIABLE Tviol_A0_WENeg        : X01 := '0';
        VARIABLE TD_A0_WENeg           : VitalTimingDataType;

        VARIABLE Tviol_BYTENeg_WENeg   : X01 := '0';
        VARIABLE TD_BYTENeg_WENeg      : VitalTimingDataType;

        VARIABLE Tviol_DQ0_CENeg       : X01 := '0';
        VARIABLE TD_DQ0_CENeg          : VitalTimingDataType;

        VARIABLE Tviol_DQ0_WENeg       : X01 := '0';
        VARIABLE TD_DQ0_WENeg          : VitalTimingDataType;

        VARIABLE Tviol_CENeg_RESETNeg  : X01 := '0';
        VARIABLE TD_CENeg_RESETNeg     : VitalTimingDataType;

        VARIABLE Tviol_OENeg_RESETNeg  : X01 := '0';
        VARIABLE TD_OENeg_RESETNeg     : VitalTimingDataType;

        VARIABLE Tviol_WENeg_RESETNeg  : X01 := '0';
        VARIABLE TD_WENeg_RESETNeg     : VitalTimingDataType;

        VARIABLE Tviol_CENeg_WENeg_F   : X01 := '0';
        VARIABLE TD_CENeg_WENeg_F      : VitalTimingDataType;

        VARIABLE Tviol_CENeg_WENeg_R   : X01 := '0';
        VARIABLE TD_CENeg_WENeg_R      : VitalTimingDataType;

        VARIABLE Tviol_OENeg_WENeg_F   : X01 := '0';
        VARIABLE TD_OENeg_WENeg_F      : VitalTimingDataType;

        VARIABLE Tviol_OENeg_WENeg_R   : X01 := '0';
        VARIABLE TD_OENeg_WENeg_R      : VitalTimingDataType;

        VARIABLE Tviol_WENeg_CENeg_F   : X01 := '0';
        VARIABLE TD_WENeg_CENeg_F      : VitalTimingDataType;

        VARIABLE Tviol_WENeg_CENeg_R   : X01 := '0';
        VARIABLE TD_WENeg_CENeg_R      : VitalTimingDataType;

        VARIABLE Tviol_CENeg_OENeg     : X01 := '0';
        VARIABLE TD_CENeg_OENeg        : VitalTimingDataType;

        VARIABLE Tviol_BYTENeg_CENeg   : X01 := '0';
        VARIABLE TD_BYTENeg_CENeg      : VitalTimingDataType;

        VARIABLE Pviol_RESETNeg   : X01 := '0';
        VARIABLE PD_RESETNeg      : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_CENeg      : X01 := '0';
        VARIABLE PD_CENeg         : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_WENeg      : X01 := '0';
        VARIABLE PD_WENeg         : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_A0         : X01 := '0';
        VARIABLE PD_A0            : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Violation        : X01 := '0';
    BEGIN

    ---------------------------------------------------------------------------
    -- Timing Check Section
    ---------------------------------------------------------------------------
    IF (TimingChecksOn) THEN
        -- Setup/Hold Check between A and CENeg
        VitalSetupHoldCheck (
            TestSignal      => A,
            TestSignalName  => "A",
            RefSignal       => CENeg,
            RefSignalName   => "CE#",
            SetupHigh       => tsetup_A0_CENeg,
            SetupLow        => tsetup_A0_CENeg,
            HoldHigh        => thold_A0_CENeg, --used
            HoldLow         => thold_A0_CENeg,
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_A0_CENeg,
            Violation       => Tviol_A0_CENeg
        );
        -- Setup/Hold Check between A and WENeg
        VitalSetupHoldCheck (
            TestSignal      => A,
            TestSignalName  => "A",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            SetupHigh       => tsetup_A0_CENeg,
            SetupLow        => tsetup_A0_CENeg,
            HoldHigh        => thold_A0_CENeg,--used
            HoldLow         => thold_A0_CENeg,
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_A0_WENeg,
            Violation       => Tviol_A0_WENeg
        );
        -- Setup/Hold Check between BYTENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => BYTENeg,
            TestSignalName  => "BYTENeg",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            SetupHigh       => tsetup_A0_CENeg,
            SetupLow        => tsetup_A0_CENeg,
            HoldHigh        => thold_A0_CENeg,--used
            HoldLow         => thold_A0_CENeg,
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_BYTENeg_WENeg,
            Violation       => Tviol_BYTENeg_WENeg
        );
        -- Setup/Hold Check between DQ and CENeg
        VitalSetupHoldCheck (
            TestSignal      => DQ0,
            TestSignalName  => "DQ",
            RefSignal       => CENeg,
            RefSignalName   => "CE#",
            SetupHigh       => tsetup_DQ0_CENeg,
            SetupLow        => tsetup_DQ0_CENeg,--used
            HoldHigh        => thold_DQ0_CENeg,
            HoldLow         => thold_DQ0_CENeg,
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_DQ0_CENeg,
            Violation       => Tviol_DQ0_CENeg
        );
        -- Setup/Hold Check between DQ and WENeg
        VitalSetupHoldCheck (
            TestSignal      => DQ0,
            TestSignalName  => "DQ",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            SetupHigh       => tsetup_DQ0_CENeg,
            SetupLow        => tsetup_DQ0_CENeg,
            HoldHigh        => thold_DQ0_CENeg,--used
            HoldLow         => thold_DQ0_CENeg,
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_DQ0_WENeg,
            Violation       => Tviol_DQ0_WENeg
        );
        -- Hold Check between CENeg and RESETNeg
        VitalSetupHoldCheck (
            TestSignal      => CENeg,
            TestSignalName  => "CE#",
            RefSignal       => RESETNeg,
            RefSignalName   => "RESET#",
            HoldHigh        => thold_CENeg_RESETNeg, --used
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_CENeg_RESETNeg,
            Violation       => Tviol_CENeg_RESETNeg
        );
        -- Hold Check between OENeg and RESETNeg
        VitalSetupHoldCheck (
            TestSignal      => OENeg,
            TestSignalName  => "OE#",
            RefSignal       => RESETNeg,
            RefSignalName   => "RESET#",
            HoldHigh        => thold_CENeg_RESETNeg,--used
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_OENeg_RESETNeg,
            Violation       => Tviol_OENeg_RESETNeg
        );
        -- Hold Check between WENeg and RESETNeg
        VitalSetupHoldCheck (
            TestSignal      => WENeg,
            TestSignalName  => "WE#",
            RefSignal       => RESETNeg,
            RefSignalName   => "RESET#",
            HoldHigh        => thold_CENeg_RESETNeg, --used
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_WENeg_RESETNeg,
            Violation       => Tviol_WENeg_RESETNeg
        );
    -- Setup/Hold Check between BYTENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => BYTENeg,
            TestSignalName  => "BYTE#",
            RefSignal       => CENeg,
            RefSignalName   => "CE#",
            HoldHigh        => thold_BYTENeg_CENeg,--5ns
            HoldLow         => thold_BYTENeg_CENeg, --used
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_BYTENeg_CENeg,
            Violation       => Tviol_BYTENeg_CENeg
        );

    -- Hold Check between OENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => OENeg,
            TestSignalName  => "OE#",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            HoldHigh        => thold_OENeg_WENeg,--toeh used
            CheckEnabled    => PDONE = '0' OR EDONE = '0',--toggle
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_OENeg_WENeg_R,
            Violation       => Tviol_OENeg_WENeg_R
        );

    -- Hold Check between OENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => OENeg,
            TestSignalName  => "OE#",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            SetupHigh       => tsetup_OENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_OENeg_WENeg_F,
            Violation       => Tviol_OENeg_WENeg_F
        );
        -- Hold Check between WENeg and OENeg
        VitalSetupHoldCheck (
            TestSignal      => CENeg,
            TestSignalName  => "CE#",
            RefSignal       => OENeg,
            RefSignalName   => "OE#",
            HoldHigh        => thold_CENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_CENeg_OENeg,
            Violation       => Tviol_CENeg_OENeg
        );
        -- Setup/Hold Check between CENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => WENeg,
            TestSignalName  => "WE#",
            RefSignal       => CENeg,
            RefSignalName   => "CE#",
            SetupLow        => tsetup_CENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_WENeg_CENeg_F,
            Violation       => Tviol_WENeg_CENeg_F
        );
        -- Setup/Hold Check between CENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => WENeg,
            TestSignalName  => "WE#",
            RefSignal       => CENeg,
            RefSignalName   => "CE#",
            HoldLow         => thold_CENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_WENeg_CENeg_R,
            Violation       => Tviol_WENeg_CENeg_R
        );
        -- Setup/Hold Check between CENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => CENeg,
            TestSignalName  => "CE#",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            SetupLow        => tsetup_CENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_CENeg_WENeg_F,
            Violation       => Tviol_CENeg_WENeg_F
        );
        -- Setup/Hold Check between CENeg and WENeg
        VitalSetupHoldCheck (
            TestSignal      => CENeg,
            TestSignalName  => "CE#",
            RefSignal       => WENeg,
            RefSignalName   => "WE#",
            HoldLow         => thold_CENeg_WENeg,--0
            CheckEnabled    => TRUE,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_CENeg_WENeg_R,
            Violation       => Tviol_CENeg_WENeg_R
        );

    -- PulseWidth Check for RESETNeg
        VitalPeriodPulseCheck (
            TestSignal        => RESETNeg,
            TestSignalName    => "RESET#",
            PulseWidthLow     => tpw_RESETNeg_negedge, --used
            CheckEnabled      => TRUE,
            HeaderMsg         => InstancePath & PartID,
            PeriodData        => PD_RESETNeg,
            Violation         => Pviol_RESETNeg
        );
        -- PulseWidth Check for WENeg
        VitalPeriodPulseCheck (
            TestSignal        => WENeg,
            TestSignalName    => "WE#",
            PulseWidthHigh    => tpw_WENeg_posedge,
            PulseWidthLow     => tpw_WENeg_negedge,--used
            CheckEnabled      => TRUE,
            HeaderMsg         => InstancePath & PartID,
            PeriodData        => PD_WENeg,
            Violation         => Pviol_WENeg
        );
        -- PulseWidth Check for CENeg
        VitalPeriodPulseCheck (
            TestSignal        => CENeg,
            TestSignalName    => "CE#",
            PulseWidthHigh    => tpw_WENeg_posedge,
            PulseWidthLow     => tpw_WENeg_negedge,--used
            CheckEnabled      => TRUE,
            HeaderMsg         => InstancePath & PartID,
            PeriodData        => PD_CENeg,
            Violation         => Pviol_CENeg
        );
        -- PulseWidth Check for A
        VitalPeriodPulseCheck (
            TestSignal        => A(0),
            TestSignalName    => "A",
            PulseWidthHigh    => tpw_A0_negedge, --used
            PulseWidthLow     => tpw_A0_negedge,
            CheckEnabled      => TRUE,
            HeaderMsg         => InstancePath & PartID,
            PeriodData        => PD_A0,
            Violation         => Pviol_A0
        );

        Violation := Tviol_A0_CENeg       OR
                     Tviol_A0_WENeg       OR
                     Tviol_BYTENeg_WENeg  OR
                     Tviol_DQ0_CENeg      OR
                     Tviol_DQ0_WENeg      OR
                     Tviol_CENeg_RESETNeg OR
                     Tviol_OENeg_RESETNeg OR
                     Tviol_WENeg_RESETNeg OR
                     Tviol_BYTENeg_CENeg  OR
                     Tviol_OENeg_WENeg_F  OR
                     Tviol_OENeg_WENeg_R  OR
                     Tviol_CENeg_OENeg    OR
                     Tviol_WENeg_CENeg_F  OR
                     Tviol_WENeg_CENeg_R  OR
                     Tviol_CENeg_WENeg_F  OR
                     Tviol_CENeg_WENeg_R  OR
                     Pviol_RESETNeg       OR
                     Pviol_WENeg          OR
                     Pviol_CENeg          OR
                     Pviol_A0             ;

        Viol <= Violation;

        ASSERT Violation = '0'
            REPORT InstancePath & partID & ": simulation may be" &
                    " inaccurate due to timing violations"
            SEVERITY WARNING;
    END IF;
END PROCESS VITALTimingCheck;

    ----------------------------------------------------------------------------
    -- sequential process for reset control and FSM state transition
    ----------------------------------------------------------------------------
    StateTransition : PROCESS(next_state, RESETNeg, RST, READY_out, PDone,
                              EDone, PoweredUp)
        VARIABLE R  : std_logic := '0'; --prog or erase in progress
        VARIABLE E  : std_logic := '0'; --reset timming error
    BEGIN
        IF PoweredUp='1' THEN
        --Hardware reset timing control
            IF falling_edge(RESETNeg) THEN
                E := '0';
                IF (PDONE='0' OR EDONE='0') THEN
                    --if program or erase in progress
                    READY_in <= '1';
                    R :='1';
                ELSE
                    READY_in <= '0';
                    R:='0';         --prog or erase not in progress
                END IF;
            ELSIF rising_edge(RESETNeg) AND RST='1' THEN
                --RESET# pulse < tRP
                READY_in <= '0';
                R := '0';
                E := '1';
            END IF;

            IF  RESETNeg='1' AND ( R='0' OR (R='1' AND READY_out='1')) THEN
                current_state <= next_state;
                READY_in <= '0';
                E := '0';
                R := '0';
                reseted <= '1';

            ELSIF (R='0' AND RESETNeg='0' AND RST='0')OR
                  (R='1' AND RESETNeg='0' AND RST='0' AND READY_out='0')OR
                  (R='1' AND RESETNeg='1' AND RST='0' AND READY_out='0')OR
                  (R='1' AND RESETNeg='1' AND RST='1' AND READY_out='0') THEN
                --no state transition while RESET# low

                current_state <= RESET; --reset start
                reseted       <= '0';
            END IF;

        ELSE
            current_state <= RESET;      -- reset
            reseted       <= '0';
            E := '0';
            R := '0';
        END IF;

END PROCESS StateTransition;

    ---------------------------------------------------------------------------
    --Glitch Protection: Inertial Delay does not propagate pulses <5ns
    ---------------------------------------------------------------------------
    gWE_n <= WENeg AFTER 5 ns;
    gCE_n <= CENeg AFTER 5 ns;
    gOE_n <= OENeg AFTER 5 ns;

    --latch address on rising edge and data on falling edge  of write
    write_dc: PROCESS (gWE_n, gCE_n, gOE_n, RESETNeg, reseted)
    BEGIN
        IF RESETNeg /= '0' AND reseted = '1' THEN
            IF (gWE_n = '0') AND (gCE_n = '0') AND (gOE_n = '1') THEN
                write <= '1';
            ELSIF (gWE_n = '1' OR gCE_n = '1') AND gOE_n = '1' THEN
                write <= '0';
            ELSE
                write <= 'X';
            END IF;
        END IF;

        IF ((gWE_n = '1') AND (gCE_n = '0') AND (gOE_n = '0') )THEN
            read <= '1';
        ELSE
            read <= '0';
        END IF;

    END PROCESS write_dc;

    ---------------------------------------------------------------------------
    --Process that reports warning when changes on signals WE#, CE#, OE# are
    --discarded
    ---------------------------------------------------------------------------
    PulseWatch : PROCESS (WENeg, CENeg, OENeg, gWE_n, gCE_n, gOE_n)
    BEGIN
        IF (gWE_n'EVENT AND (gWE_n /= WENeg)) OR
           (gCE_n'EVENT AND (gCE_n /= CENeg)) OR
           (gOE_n'EVENT AND (gOE_n /= OENeg)) THEN
            ASSERT false
                REPORT "Glitch detected on write control signals"
                SEVERITY warning;
        END IF;
    END PROCESS PulseWatch;

    ---------------------------------------------------------------------------
    --Latch address on falling edge of WE# or CE# what ever comes later
    --Latches data on rising edge of WE# or CE# what ever comes first
    -- also Write cycle decode
    ---------------------------------------------------------------------------
    BusCycleDecode : PROCESS(A, Din, write, WENeg, CENeg, OENeg, BYTENeg,
                             reseted)

        VARIABLE A_tmp  : NATURAL RANGE 0 TO 16#7FF#;
        VARIABLE SA_tmp : NATURAL RANGE 0 TO SecNum;
        VARIABLE A_tmp1 : NATURAL RANGE 0 TO SecSize;

        VARIABLE CE     : std_logic;
        VARIABLE i      : NATURAL;
    BEGIN
        IF reseted='1' THEN
            IF (falling_edge(WENeg) AND CENeg='0' AND OENeg = '1' ) OR
               (falling_edge(CENeg) AND          WENeg /= OENeg ) OR
               (falling_edge(OENeg) AND WENeg='1' AND CENeg = '0' ) OR
               ((A'EVENT OR (Din(15)'EVENT AND BYTENeg='0' AND
                 Din(15) /= Dout_zd(15)) OR BYTENeg'EVENT )
            AND WENeg = '1' AND CENeg = '0' AND OENeg = '0') THEN

                A_tmp :=  to_nat( A(10 downto 0) );
                SA_tmp:=  to_nat( A(HiAddrBit downto 15));

                IF (BYTENeg = '0') THEN
                    A_tmp1 := to_nat( A(14 downto 0) & Din(15) );
                ELSE
                    A_tmp1 := to_nat( A(14 downto 0) & '0' );
                END IF;

            ELSIF (rising_edge(WENeg) OR rising_edge(CENeg)) 
                AND write = '1' THEN
                D_tmp0 <= to_nat(Din(7 downto 0));
                IF BYTENeg = '1' THEN
                    D_tmp1 <= to_nat(Din(15 downto 8));
                END IF;
            END IF;

            IF rising_edge(write) OR
               falling_edge(OENeg) OR
               ((A'EVENT OR (Din(15)'EVENT AND BYTENeg = '0') OR
                 BYTENeg'EVENT) AND WENeg = '1' AND CENeg = '0' AND
                 OENeg = '0') THEN
                SecAddr <= SA_tmp;
                Address <= A_tmp1;
                WPage   <= A_tmp1 / 32;

                FOR i IN 0 TO SubSecNum LOOP
                     IF A_tmp1 >= sssa(vs)(i) AND A_tmp1 <= ssea(vs)(i) THEN
                          SubSect <= i;
                     END IF;
                END LOOP;

                CE := CENeg;
                Addr <= A_tmp;
            END IF;
        END IF;
END PROCESS BusCycleDecode;

    ---------------------------------------------------------------------------
    -- Timing control for the Program/ Write Buffer Program Operations
    -- start/ suspend/ resume
    ---------------------------------------------------------------------------
    ProgTime :PROCESS(PSTART, BYTENeg, ESP_ACT, reseted)

        VARIABLE duration : time;
        VARIABLE pob      : time;
        VARIABLE pow      : time;

    BEGIN
        IF LongTimming THEN
            pob  := tdevice_POB;
            pow  := tdevice_POW;
        ELSE
            pob  := tdevice_POB / 2;
            pow  := tdevice_POW / 2;
        END IF;

        IF rising_edge(reseted) THEN
            PDONE <= '1';  -- reset done, programing terminated
        ELSIF reseted = '1' THEN
            IF rising_edge(PSTART) AND PDONE='1' THEN
                IF ( (SA /= VarSect
                    AND Sec_Prot(SA) = '0'
                    AND (Ers_queue(SA) = '0' OR ESP_ACT = '0'))
                    OR (SA = VarSect
                    AND SubSec_Prot(SSA) = '0'
                    AND (Ers_Sub_queue(SSA) = '0' OR ESP_ACT = '0')))THEN

                    IF BYTENeg = '1' THEN
                        duration := pow;
                    ELSE
                        duration := pob;
                    END IF;
                    PDONE <= '0', '1' AFTER duration;
                ELSE
                    PERR <= '1', '0' AFTER 2 us;
                END IF;
            END IF;
        END IF;
END PROCESS ProgTime;

    ---------------------------------------------------------------------------
    -- Timing control for the Erase Operations
    ---------------------------------------------------------------------------
    ErsTime :PROCESS(ESTART, ESUSP, ERES, Ers_Queue, Ers_Sub_Queue, reseted)
        VARIABLE cnt      : NATURAL RANGE 0 TO SecNum+SubSecNum := 0;
        VARIABLE elapsed  : time;
        VARIABLE duration : time;
        VARIABLE start    : time;
        VARIABLE seo      : time;

    BEGIN
        IF LongTimming THEN
            seo  := tdevice_SEO;
        ELSE
            seo  := tdevice_SEO/1000;
        END IF;
        IF rising_edge(reseted) THEN
            EDONE <= '1';  -- reset done, ERASE terminated
        ELSIF reseted = '1' THEN
            IF rising_edge(ESTART) AND EDONE = '1' THEN
                cnt := 0;
                FOR i IN Ers_Queue'RANGE LOOP
                    IF i = VarSect THEN
                        FOR j IN 0 TO SubSecNum LOOP
                            IF Ers_Sub_Queue(j) = '1'
                              AND SubSec_Prot(j) /= '1' THEN
                                cnt := cnt + 1;
                            END IF;
                        END LOOP;
                    ELSIF Ers_Queue(i) = '1' AND Sec_Prot(i) /= '1' THEN
                        cnt := cnt +1;
                    END IF;
                END LOOP;
                IF cnt > 0 THEN
                    elapsed := 0 ns;
                    duration := cnt* seo;
                    EDONE <= '0', '1' AFTER duration;
                    start := NOW;
                ELSE
                    EERR <= '1', '0' AFTER 100 us;

                END IF;
            ELSIF rising_edge(ESUSP) AND EDONE = '0' THEN
                elapsed  := NOW - start;
                duration := duration - elapsed;
                EDONE <= '0';
            ELSIF rising_edge(ERES) AND EDONE = '0' THEN
                start := NOW;
                EDONE <= '0', '1' AFTER duration;
            END IF;
        END IF;
END PROCESS;

    ---------------------------------------------------------------------------
    -- Main Behavior Process
    -- combinational process for next state generation
    ---------------------------------------------------------------------------
    StateGen :PROCESS(write, Addr, D_tmp0, PDONE, EDONE, HANG, CTMOUT_out,
                       START_T1_out, reseted, READY_out, PERR, EERR)
        VARIABLE PATTERN_1         : boolean := FALSE;
        VARIABLE PATTERN_2         : boolean := FALSE;
        VARIABLE A_PAT_1           : boolean := FALSE;

        --DATA  High Byte
        VARIABLE DataHi           : NATURAL RANGE 0 TO MaxData := 0;
        --DATA Low Byte
        VARIABLE DataLo           : NATURAL RANGE 0 TO MaxData := 0;
    BEGIN
        -----------------------------------------------------------------------
        -- Functionality Section
        -----------------------------------------------------------------------
        IF falling_edge(write) THEN
            DataLo    := D_tmp0;
            PATTERN_1 := (Addr = 16#555#) AND (DataLo = 16#AA#) ;
            PATTERN_2 := (Addr = 16#2AA#) AND (DataLo = 16#55#) ;
            A_PAT_1   := (Addr = 16#555#);
        END IF;
        IF reseted /= '1' THEN
            next_state <= current_state;
        ELSE
        CASE current_state IS
            WHEN RESET          =>
                IF falling_edge(write) THEN
                    IF (PATTERN_1)THEN
                        next_state <= Z001;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN Z001           =>
                IF falling_edge(write) THEN
                    IF (PATTERN_2) THEN
                        next_state <= PREL_SETBWB;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN PREL_SETBWB    =>
                IF falling_edge(write) THEN
                    IF (A_PAT_1 AND (DataLo = 16#90#)) THEN
                        next_state <= AS;
                    ELSIF (A_PAT_1 AND (DataLo = 16#A0#)) THEN
                        next_state <= A0SEEN;
                    ELSIF (A_PAT_1 AND (DataLo = 16#80#)) THEN
                        next_state <= C8;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN AS             =>
                IF falling_edge(write) THEN
                    IF (DataLo = 16#F0#) THEN
                        next_state <= RESET;
                    ELSE
                        next_state <= AS;
                    END IF;
                END IF;

            WHEN A0SEEN         =>
                IF falling_edge(write) THEN
                    next_state <= PGMS;
                ELSE
                    next_state <= A0SEEN;
                END IF;

            WHEN C8             =>
                IF falling_edge(write) THEN
                    IF PATTERN_1 THEN
                        next_state <= C8_Z001;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN C8_Z001        =>
                IF falling_edge(write) THEN
                    IF PATTERN_2 THEN
                        next_state <= C8_PREL;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN C8_PREL        =>
                IF falling_edge(write) THEN
                    IF A_PAT_1 AND DataLo = 16#10# THEN
                        next_state <= ERS;
                    ELSIF DataLo = 16#30# THEN
                        next_state <= SERS;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN ERS            =>
                IF rising_edge(EDONE) OR falling_edge(EERR) THEN
                    next_state <= RESET;
                END IF;

            WHEN SERS           =>
                IF CTMOUT_out = '1' AND CTMOUT_out'EVENT THEN
                    next_state <= SERS_EXEC;
                ELSIF falling_edge(write) THEN
                    IF (DataLo = 16#B0#) THEN
                        next_state <= ESPS; -- ESP according to datasheet
                    ELSIF (DataLo = 16#30#) THEN
                        next_state <= SERS;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

            WHEN ESPS           =>
                IF (START_T1_out = '1') THEN
                    next_state <= ESP;
                END IF;

            WHEN SERS_EXEC      =>
                IF rising_edge(EDONE) OR falling_edge(EERR) THEN
                    next_state <= RESET;
                ELSIF EERR /= '1' THEN
                    IF falling_edge(write) THEN
                        IF DataLo = 16#B0# THEN
                            next_state <= ESPS;
                        END IF;
                    END IF;
                END IF;

            WHEN ESP            =>
                IF falling_edge(write) THEN
                    IF DataLo = 16#30# THEN
                        next_state <= SERS_EXEC;
                    ELSE
                        IF PATTERN_1 THEN
                            next_state <= ESP_Z001;
                        END IF;
                    END IF;
                END IF;

            WHEN ESP_Z001       =>
                IF falling_edge(write) THEN
                    IF PATTERN_2 THEN
                        next_state <= ESP_PREL;
                    ELSE
                        next_state <= ESP;
                    END IF;
                END IF;

            WHEN ESP_PREL       =>
                IF falling_edge(write) THEN
                    IF A_PAT_1 AND DataLo = 16#20# THEN
                        next_state <= ESP;
                    ELSIF A_PAT_1 AND DataLo = 16#A0# THEN
                        next_state <= ESP_A0SEEN;
                    ELSIF A_PAT_1 AND DataLo = 16#90# THEN
                        next_state <= ESP_AS;
                    ELSE
                        next_state <= ESP;
                    END IF;
                END IF;


            WHEN ESP_A0SEEN     =>
                IF falling_edge(write) THEN
                    next_state <= PGMS; --set ESP
                END IF;

            WHEN ESP_AS         =>
                IF falling_edge(write) THEN
                    IF DataLo = 16#F0# THEN
                        next_state <= ESP;
                    END IF;
                END IF;

            WHEN PGMS           =>
                IF rising_edge(PDONE) OR falling_edge(PERR) THEN
                    IF ESP_ACT = '1' THEN
                        next_state <= ESP;
                    ELSE
                        next_state <= RESET;
                    END IF;
                END IF;

        END CASE;
        END IF;
END PROCESS StateGen;

    ---------------------------------------------------------------------------
    --FSM Output generation and general funcionality
    ---------------------------------------------------------------------------
    Functional : PROCESS(write, read, Addr, D_tmp0, D_tmp1, Address, SecAddr,
                         PDONE, EDONE, HANG, START_T1_out, CTMOUT_out, RST,
                         reseted, READY_out, gOE_n, current_state, BYTENeg)

        --Program
        TYPE WDataType IS ARRAY ( 0 TO 1) OF--n
                          INTEGER RANGE -1 TO MaxData;
        TYPE WAddrType IS ARRAY ( 0 TO 1) OF
                          INTEGER RANGE -1 TO SecSize;--n

        VARIABLE WData       : WDataType:=(OTHERS=>0);--n
        VARIABLE WAddr       : WAddrType:=(OTHERS=>-1);--n

        VARIABLE BaseLoc     : NATURAL RANGE 0 TO SecSize := 0;
        VARIABLE cnt         : NATURAL RANGE 0 TO 31 := 0;

        VARIABLE PATTERN_1   : boolean := FALSE;
        VARIABLE PATTERN_2   : boolean := FALSE;
        VARIABLE A_PAT_1     : boolean := FALSE;

        VARIABLE oe          : boolean := FALSE;
        --Status reg.
        VARIABLE Status      : std_logic_vector(7 downto 0) := (OTHERS=>'0');

        VARIABLE old_bit     : std_logic_vector(7 downto 0);
        VARIABLE new_bit     : std_logic_vector(7 downto 0);
        VARIABLE old_int     : INTEGER RANGE -1 to MaxData;
        VARIABLE new_int     : INTEGER RANGE -1 to MaxData;
        VARIABLE wr_cnt      : NATURAL RANGE 0 TO 31;

        --DATA  High Byte
        VARIABLE DataHi      : NATURAL RANGE 0 TO MaxData := 0;
        --DATA Low Byte
        VARIABLE DataLo      : NATURAL RANGE 0 TO MaxData := 0;

        VARIABLE temp        : std_logic_vector(7 downto 0);
    BEGIN
        -----------------------------------------------------------------------
        -- Functionality Section
        -----------------------------------------------------------------------
        IF falling_edge(write) THEN
            DataLo    := D_tmp0;
            DataHi    := D_tmp1;
            PATTERN_1 := (Addr = 16#555#) AND (DataLo = 16#AA#) ;
            PATTERN_2 := (Addr = 16#2AA#) AND (DataLo = 16#55#) ;
            A_PAT_1   := (Addr = 16#555#);
        END IF;
        oe := rising_edge(read) OR
        (read = '1' AND (Address'EVENT OR SecAddr'EVENT OR BYTENEg'EVENT));

        IF reseted = '1' THEN
        CASE current_state IS
            WHEN RESET          =>
                ESP_ACT   <= '0';

                IF falling_edge(write) THEN
                    null;
                ELSIF oe THEN
                    MemRead(SecAddr, Address, BYTENeg, DOut_zd);
                END IF;
                --ready signal active
                RY_zd <= '1';

            WHEN Z001           =>
                null;

            WHEN PREL_SETBWB    =>
                null;

            WHEN AS             =>
                IF falling_edge(write) THEN
                    null;
                ELSIF oe THEN
                    AsRead(Address, BYTENeg, vs, SecAddr, SubSect, Dout_zd);
                END IF;

            WHEN A0SEEN         =>
                IF falling_edge(write) THEN
                    PSTART <= '1', '0' AFTER 1 ns;
                    IF Viol /= '0' THEN
                        WData(0) := -1;
                        WData(1) := -1;
                    ELSE
                        WData(0) := DataLo;
                        WData(1) := DataHi;
                    END IF;
                    WAddr(0) := Address;
                    WBPage <= WPage;
                    SA <= SecAddr;
                    SSA <= SubSect;
                    temp := to_slv(DataLo, 8);
                    Status(7) := NOT temp(7);

                    IF BYTENeg = '1' THEN
                        WAddr(1) := WAddr(0) + 1;
                    ELSE
                        WAddr(1) := -1;
                    END IF;
                END IF;

            WHEN C8             =>
                IF falling_edge(write) THEN
                    null;
                END IF;

            WHEN C8_Z001        =>
                IF falling_edge(write) THEN
                END IF;

            WHEN C8_PREL        =>
                IF falling_edge(write) THEN
                    IF A_PAT_1 AND DataLo = 16#10# THEN
                        --Start Chip Erase
                        ESTART <= '1', '0' AFTER 1 ns;
                        ESUSP  <= '0';
                        ERES   <= '0';
                        Ers_Queue <= (OTHERS => '1');
                        Ers_Sub_Queue <= (OTHERS => '1');
                        Status := "00001000";
                    ELSIF DataLo = 16#30# THEN
                        --put selected sector to sec. ers. queue
                        --start timeout
                        Ers_Queue <= (OTHERS => '0');
                        Ers_Sub_Queue <= (OTHERS => '0');
                        IF SecAddr = VarSect THEN
                             Ers_Sub_Queue(SubSect) <= '1';
                        ELSE
                             Ers_Queue(SecAddr) <= '1';
                        END IF;
                        CTMOUT_in <= '0', '1' AFTER 1 ns;
                    END IF;
                END IF;

            WHEN ERS            =>

                IF oe THEN
                    -----------------------------------------------------------
                    -- read status / embeded erase algorithm - Chip Erase
                    -----------------------------------------------------------
                    Status(7) := '0';
                    Status(6) := NOT Status(6); --toggle
                    Status(5) := '0';
                    Status(3) := '1';
                    Status(2) := NOT Status(2); --toggle

                    DOut_zd(7 downto 0) <= Status;

                END IF;
                IF EERR /= '1' THEN
                    FOR i IN 0 TO SecNum LOOP
                         IF i = VarSect THEN
                              FOR j IN 0 TO SubSecNum LOOP
                                   IF SubSec_Prot(j) /= '1' THEN
                                        Mem(i)(sssa(vs)(j) TO ssea(vs)(j)) :=
                                                (OTHERS => -1);
                                   END IF;
                              END LOOP;
                         ELSIF Sec_Prot(i) /= '1' THEN
                              Mem(i):= (OTHERS => -1);
                        END IF;
                    END LOOP;
                    IF EDONE = '1' THEN
                        FOR i IN 0 TO SecNum LOOP
                            IF i = VarSect THEN
                                  FOR j IN 0 TO SubSecNum LOOP
                                       IF SubSec_prot(j) /= '1' THEN
                                           Mem(i)(sssa(vs)(j) TO ssea(vs)(j)) :=
                                                (OTHERS => MaxData);
                                       END IF;
                                  END LOOP;
                            ELSIF Sec_Prot(i) /= '1' THEN
                                Mem(i):= (OTHERS => MaxData);
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
                -- busy signal active
                RY_zd <= '0';

            WHEN SERS           =>
                IF CTMOUT_out = '1' AND CTMOUT_out'EVENT THEN
                    CTMOUT_in <= '0';

                    START_T1_in <= '0';
                    ESTART <= '1', '0' AFTER 1 ns;
                    ESUSP  <= '0';
                    ERES   <= '0';
                    --next_state <= SERS_EXEC;
                    IF oe THEN
                        --read status
                    END IF;
                ELSIF falling_edge(write) THEN
                    IF (DataLo = 16#B0#) THEN
                        --next_state <= ESPS; -- ESP according to datasheet
                        --need to start erase process prior to suspend
                        ESTART <= '1', '0' AFTER 1 ns;
                        ESUSP  <= '0';
                        ERES   <= '0';
                        --suspend timeout (should be 0 according to datasheet)
                        START_T1_in <= '1';
                    ELSIF (DataLo = 16#30#) THEN
                        CTMOUT_in <= '0', '1' AFTER 1 ns;
                        IF SecAddr = VarSect THEN
                           Ers_Sub_Queue(SubSect) <= '1';
                        ELSE
                           Ers_Queue(SecAddr) <= '1';
                        END IF;
                    END IF;
                ELSIF oe THEN
                    -----------------------------------------------------------
                    --read status - sector erase timeout
                    -----------------------------------------------------------
                    Status(3) := '0';

                    DOut_zd(7 downto 0) <= Status;
                END IF;
                --ready signal active
                RY_zd <= '1';

            WHEN ESPS           =>
                ESUSP <= '1';
                IF (START_T1_out = '1') THEN
                    ESP_ACT <= '1';
                    START_T1_in <= '0';
                    --ESUSP <= '1', '0' AFTER 1 ns;
                ELSIF oe THEN
                    -----------------------------------------------------------
                    --read status / erase suspend timeout - stil erasing
                    -----------------------------------------------------------
                    Status(7) := '0';
                    Status(6) := NOT Status(6); --toggle
                    Status(5) := '0';
                    Status(3) := '1';
                    IF (SecAddr /= VarSect AND Ers_Queue(SecAddr) = '1')
                    OR (SecAddr = VarSect AND Ers_Sub_Queue(SubSect) = '1') THEN
                        Status(2) := NOT Status(2); --toggle
                    END IF;

                    DOut_zd(7 downto 0) <= Status;

                END IF;
                --busy signal active
                RY_zd <= '0';

            WHEN SERS_EXEC      =>
                IF oe THEN
                    -----------------------------------------------------------
                    --read status Erase Busy
                    -----------------------------------------------------------
                    Status(7) := '0';
                    Status(6) := NOT Status(6); --toggle
                    Status(5) := '0';
                    Status(3) := '1';
                    IF (SecAddr /= VarSect AND Ers_Queue(SecAddr) = '1')
                    OR (SecAddr = VarSect AND Ers_Sub_Queue(SubSect) = '1') THEN
                        Status(2) := NOT Status(2); --toggle
                    END IF;


                    DOut_zd(7 downto 0) <= Status;
                END IF;
                IF EERR /= '1' THEN
                    FOR i IN Ers_Queue'RANGE LOOP
                         IF i = VarSect THEN
                              FOR j IN 0 TO SubSecNum LOOP
                                   IF Ers_Sub_Queue(j) = '1' AND 
                                      SubSec_Prot(j) /= '1' THEN
                                        Mem(i)(sssa(vs)(j) TO ssea(vs)(j)) :=
                                                (OTHERS => -1);
                                   END IF;
                              END LOOP;
                         ELSIF Ers_Queue(i) = '1' AND Sec_Prot(i) /= '1' THEN
                              Mem(i) := (OTHERS => -1);
                         END IF;
                    END LOOP;
                    IF EDONE = '1' THEN
                        FOR i IN Ers_Queue'RANGE LOOP
                            IF i = VarSect THEN
                                FOR j IN 0 TO SubSecNum LOOP
                                    IF Ers_Sub_Queue(j) = '1' AND
                                       SubSec_Prot(j) /= '1' THEN
                                        Mem(i)(sssa(vs)(j) TO ssea(vs)(j)):=
                                                  (OTHERS => MaxData);
                                    END IF;
                                END LOOP;
                            ELSIF Ers_Queue(i) = '1' AND Sec_Prot(i) /= '1' THEN
                                Mem(i) := (OTHERS => MaxData);
                            END IF;
                        END LOOP;
                    ELSIF falling_edge(write) THEN
                        IF DataLo = 16#B0# THEN
                            START_T1_in <= '1';
                        END IF;
                    END IF;
                END IF;
                --busy signal active
                RY_zd <= '0';

            WHEN ESP            =>
                ESUSP <= '0';
                IF falling_edge(write) THEN
                    IF DataLo = 16#30# THEN
                        --resume erase
                        ERES <= '1', '0' AFTER 1 ns;
                    END IF;
                ELSIF oe THEN
                    -----------------------------------------------------------
                    --read
                    -----------------------------------------------------------
                    IF (SecAddr /= VarSect AND Ers_Queue(SecAddr) /= '1')
                        OR (SecAddr = VarSect AND Ers_Sub_Queue(SubSect) /= '1')
                      THEN
                        MemRead(SecAddr, Address, BYTENeg, DOut_zd);
                    ELSE
                        -------------------------------------------------------
                        --read status
                        -------------------------------------------------------
                        Status(7) := '1';
                        -- Status(6) No toggle
                        Status(5) := '0';
                        Status(2) := NOT Status(2); --toggle

                        DOut_zd(7 downto 0) <= Status;

                    END IF;
                END IF;
                --ready signal active
                RY_zd <= '1';

            WHEN ESP_Z001       =>
                null;

            WHEN ESP_PREL       =>
                null;

            WHEN ESP_A0SEEN     =>
                IF falling_edge(write) THEN
                    ESP_ACT <= '1';

                    PSTART <= '1', '0' AFTER 1 ns;
                    IF Viol /= '0' THEN
                        WData(0) := -1;
                        WData(1) := -1;
                    ELSE
                        WData(0) := DataLo;
                        WData(1) := DataHi;
                    END IF;
                    WAddr(0) := Address;
                    WBPage <= WPage;-- MOD 8;
                    SA <= SecAddr;
                    SSA <= SubSect;

                    temp := to_slv(DataLo, 8);
                    Status(7) := NOT temp(7);

                    IF BYTENeg = '1' THEN
                        WAddr(1) := WAddr(0) +1;
                    ELSE
                        WAddr(1) := -1;
                    END IF;
                END IF;

            WHEN ESP_AS         =>
                IF falling_edge(write) THEN
                    null;
                ELSIF oe THEN
                    AsRead(Address, BYTENeg, vs, SecAddr, SubSect, Dout_zd);
                END IF;

            WHEN PGMS           =>
                IF oe THEN
                    -----------------------------------------------------------
                    --read status
                    -----------------------------------------------------------
                    Status(6) := NOT Status(6); --toggle
                    Status(5) := '0';
                    --Status(2) no toggle
                    Status(1) := '0';
                    DOut_zd(7 downto 0) <= Status;
                END IF;

                IF PERR/='1' THEN

                        BaseLoc := WBPage * 32;
                        IF WAddr(1) < 0 THEN
                            wr_cnt :=  0;
                        ELSE
                            wr_cnt := 1;
                        END IF;

                    FOR i IN wr_cnt downto 0 LOOP
                        new_int:= WData(i);
                        IF WAddr(i) < 0 THEN
                            REPORT "Write Addres error"
                            SEVERITY warning;
                        ELSE
                            old_int:=Mem(SA)(WAddr(i));
                        END IF;
                        IF new_int>-1 THEN
                            new_bit:=to_slv(new_int,8);
                            IF old_int>-1 THEN
                                old_bit:=to_slv(old_int,8);
                                FOR j IN 0 TO 7 LOOP
                                    IF old_bit(j) = '0' THEN
                                        new_bit(j):='0';
                                    END IF;
                                END LOOP;
                                new_int:=to_nat(new_bit);
                            END IF;

                            WData(i):= new_int;
                        ELSE
                            WData(i):= -1;
                        END IF;
                    END LOOP;
                    FOR i IN wr_cnt downto 0 LOOP
                        IF WAddr(i) > -1 THEN
                            Mem(SA)(WAddr(i)) := -1;
                        END IF;
                    END LOOP;

                    IF HANG /= '1' AND PDONE = '1' AND (NOT PERR'EVENT) THEN
                        FOR i IN wr_cnt downto 0 LOOP
                            IF WAddr(i)> -1 THEN
                                    Mem(SA)(WAddr(i)) := WData(i);
                            END IF;
                            WData(i):= -1;
                        END LOOP;
                    END IF;
                END IF;
                --busy signal active
                RY_zd <= '0';

        END CASE;
        END IF;

        --Output Disable Control
        IF (gOE_n = '1') OR (RESETNeg = '0' AND RST = '0') THEN
            DOut_zd <= (OTHERS=>'Z');
        ELSE
            IF (BYTENeg = '0') THEN
                DOut_zd(15 downto 8) <= (OTHERS =>'Z');
            END IF;
        END IF;

    END PROCESS Functional;

    ---------------------------------------------------------------------------
    ---- File Read Section - Preload Control
    ---------------------------------------------------------------------------
    MemPreload : PROCESS

        -- text file input variables
        FILE mem_file          : text  is  mem_file_name;
        FILE prot_file         : text  is  prot_file_name;

        VARIABLE S_ind         : NATURAL := 0;-- RANGE 0 TO SecNum:= 0;
        VARIABLE SS_ind        : NATURAL RANGE 0 TO SubSecNum:= 0;
        VARIABLE ind           : NATURAL RANGE 0 TO MemSize:= 0;
        VARIABLE ind_sect      : NATURAL RANGE 0 TO SecNum:= 0;
        VARIABLE ind_addr      : NATURAL RANGE 0 TO SecSize:= 0;

        VARIABLE buf           : line;
        VARIABLE over          : BOOLEAN := false;

    BEGIN
        WAIT ON VarSect;
        IF (mem_file_name /= "none" AND UserPreload ) THEN
            ind   := 0;
            Mem := (OTHERS => (OTHERS => MaxData));

            WHILE (not ENDFILE (mem_file)) LOOP
                READLINE (mem_file, buf);
                IF buf(1) = '/' THEN --comment
                    NEXT;
                ELSIF buf(1) = '@' THEN --address
                    ind := h(buf(2 to 6));
                ELSE
                    IF ind <= MemSize THEN
                        RestoreSectAddr(ind, ind_sect, ind_addr);
                        Mem(ind_sect)(ind_addr) := h(buf(1 to 2));
                    END IF;
                    IF ind < MemSize THEN
                        ind := ind + 1;
                    END IF;

                END IF;
            END LOOP;

        END IF;

        IF (prot_file_name /= "none" AND UserPreload ) THEN
            ind   := 0;
            SS_ind := 0;
            Sec_Prot := (OTHERS => '0');
            SubSec_Prot := (OTHERS => '0');

            WHILE (not ENDFILE (prot_file) AND not over) LOOP
                READLINE (prot_file, buf);
                IF buf(1) = '/' THEN --comment
                    NEXT;
                ELSIF buf(1) = '@' THEN --address
                    ind := h(buf(2 to 3));
                ELSE
                    IF (buf(1) = '1') THEN
                        IF (ind >= VarSect) THEN
                            IF (ind <= VarSect + SubSecNum) THEN
                                SS_ind := ind - VarSect;
                                SubSec_Prot(SS_ind) := '1';
                                Sec_Prot(VarSect) := '0';
                            ELSE
                                Sec_Prot(ind - SubSecNum) := '1';
                            END IF;
                        ELSE
                            Sec_Prot(ind) := '1';
                        END IF;
                    END IF;
                    IF ind <= (SubSecNum + secNum) THEN
                        ind := ind + 1;
                    ELSE
                         over := true;
                    END IF;
                END IF;
            END LOOP;

        END IF;

    END PROCESS MemPreload;

        -----------------------------------------------------------------------
        -- Path Delay Section
        -----------------------------------------------------------------------
    RY_OUT: PROCESS(RY_zd)

        VARIABLE RY_GlitchData : VitalGlitchDataType;
        VARIABLE RY_DATA       : std_logic;
    BEGIN
        IF RY_zd = '0' THEN
            RY_DATA := '0';
        ELSE
            RY_DATA := 'Z';
        END IF;

        VitalPathDelay01(
            OutSignal     => RY,
            OutSignalName => "RY/BY#",
            OutTemp       => RY_DATA,
            Mode          => VitalTransport,
            GlitchData    => RY_GlitchData,
            Paths         => (
            0 => (InputChangeTime   => CENeg'LAST_EVENT,
                  PathDelay         => tpd_WENeg_RY,
                  PathCondition     => TRUE),
            1 => (InputChangeTime   => WENeg'LAST_EVENT,
                  PathDelay         => tpd_WENeg_RY,--used
                  PathCondition     => TRUE),
            2 => (InputChangeTime   => READY_out'LAST_EVENT,
                  PathDelay         => VitalZeroDelay01,
                  PathCondition     => EDONE = '1'),
            3 => (InputChangeTime   => EDONE'LAST_EVENT,
                  PathDelay         => VitalZeroDelay01,
                  PathCondition     => EDONE = '1'),
            4 => (InputChangeTime   => PDONE'LAST_EVENT,
                  PathDelay         => VitalZeroDelay01,
                  PathCondition     => PDONE = '1')
            )
        );
    END PROCESS RY_Out;

    ---------------------------------------------------------------------------
    -- Path Delay Section for DOut signal
    ---------------------------------------------------------------------------
    D_Out_PathDelay_Gen : FOR i IN 0 TO 7 GENERATE --Dout_zd'RANGE GENERATE
        PROCESS(DOut_zd(i))
        VARIABLE D0_GlitchData     : VitalGlitchDataType;

        BEGIN
            VitalPathDelay01Z(
                OutSignal           => DOut(i),
                OutSignalName       => "DOut",
                OutTemp             => DOut_zd(i),
                GlitchData          => D0_GlitchData,
                IgnoreDefaultDelay  => TRUE,
                Mode                => VitalTransport,
                RejectFastPath      => false,
                Paths               => (
                0 => (InputChangeTime => CENeg'LAST_EVENT,
                      PathDelay       => tpd_CENeg_DQ0,
                      PathCondition   => (Dout_zd(i) = 'Z'
                      OR (Dout_zd(i) /= 'Z' AND
                     (CENeg'LAST_EVENT - OENeg'LAST_EVENT <=
                                    tpd_CENeg_DQ0(trz1) - tpd_OENeg_DQ0(trz1))))
                      ),
                1 => (InputChangeTime => OENeg'LAST_EVENT,
                      PathDelay       => tpd_OENeg_DQ0,
                      PathCondition   => (Dout_zd(i) = 'Z'
                      OR
                      (Dout_zd(i) /= 'Z' AND
                      (CENeg'LAST_EVENT - OENeg'LAST_EVENT >
                                    tpd_CENeg_DQ0(trz1) - tpd_OENeg_DQ0(trz1))))
                      ),
                2 => (InputChangeTime => A'LAST_EVENT,
                      PathDelay       => VitalExtendToFillDelay(tpd_A0_DQ0),
                      PathCondition   => true),
                3 => (InputChangeTime => Din(15)'LAST_EVENT,
                      PathDelay       => VitalExtendToFillDelay(tpd_A0_DQ0),
                      PathCondition   => BYTENeg='0'),
                4 => (InputChangeTime => RESETNeg'LAST_EVENT,
                      PathDelay       => tpd_RESETNeg_DQ0,
                      PathCondition   => RESETNeg='0')

                )
            );
        END PROCESS;
   END GENERATE D_Out_PathDelay_Gen;

    ---------------------------------------------------------------------------
    -- Path Delay Section for DOut signal
    ---------------------------------------------------------------------------
    D_Out_15_7_PathDelay_Gen : FOR i IN 8  TO 15 GENERATE
        PROCESS(DOut_zd(i))
        VARIABLE D0_GlitchData     : VitalGlitchDataType;

        BEGIN
            VitalPathDelay01Z(
                OutSignal           => DOut(i),
                OutSignalName       => "DOut",
                OutTemp             => DOut_zd(i),
                GlitchData          => D0_GlitchData,
                IgnoreDefaultDelay  => TRUE,
                Mode                => VitalTransport,
                RejectFastPath      => false,
                Paths               => (
                0 => (InputChangeTime => CENeg'LAST_EVENT,
                      PathDelay       => tpd_CENeg_DQ0,
                      PathCondition   => (Dout_zd(i) = 'Z'
                      OR (Dout_zd(i) /= 'Z' AND
                     (CENeg'LAST_EVENT - OENeg'LAST_EVENT <=
                                    tpd_CENeg_DQ0(trz1) - tpd_OENeg_DQ0(trz1))))
                      ),
                1 => (InputChangeTime => OENeg'LAST_EVENT,
                      PathDelay       => tpd_OENeg_DQ0,
                      PathCondition   => (Dout_zd(i) = 'Z'
                      OR
                      (Dout_zd(i) /= 'Z' AND
                      (CENeg'LAST_EVENT - OENeg'LAST_EVENT >
                                    tpd_CENeg_DQ0(trz1) - tpd_OENeg_DQ0(trz1))))
                      ),
                2 => (InputChangeTime => A'LAST_EVENT,
                      PathDelay       => VitalExtendToFillDelay(tpd_A0_DQ0),
                      PathCondition   => true),
                3 => (InputChangeTime => Din(15)'LAST_EVENT,
                      PathDelay       => VitalExtendToFillDelay(tpd_A0_DQ0),
                      PathCondition   => BYTENeg='0'),
                4 => (InputChangeTime => BYTENeg'LAST_EVENT,
                      PathDelay       =>
                                    VitalExtendToFillDelay(tpd_BYTENeg_DQ15),
                      PathCondition   => BYTENeg = '1'),
                5 => (InputChangeTime => RESETNeg'LAST_EVENT,
                      PathDelay       => tpd_RESETNeg_DQ0,
                      PathCondition   => RESETNeg='0'),
                6 => (InputChangeTime => BYTENeg'LAST_EVENT,
                      PathDelay       =>
                                    VitalExtendToFillDelay(tpd_BYTENeg_DQ15),
                      PathCondition   => BYTENeg = '0')
                )
            );
        END PROCESS;
   END GENERATE D_Out_15_7_PathDelay_Gen;

    END BLOCK behavior;
END vhdl_behavioral;



