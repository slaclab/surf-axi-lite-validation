-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SurfAxiStreamProtocolChecker module
-------------------------------------------------------------------------------
-- This file is part of 'surf-axi-protcol-checking'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'surf-axi-protcol-checking', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

entity SurfAxiStreamProtocolCheckerTb is end SurfAxiStreamProtocolCheckerTb;

architecture testbed of SurfAxiStreamProtocolCheckerTb is

   COMPONENT AxiStreamProtocolChecker
     PORT (
       aclk : IN STD_LOGIC;
       aresetn : IN STD_LOGIC;
       pc_axis_tvalid : IN STD_LOGIC;
       pc_axis_tready : IN STD_LOGIC;
       pc_axis_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
       pc_axis_tstrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       pc_axis_tkeep : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       pc_axis_tlast : IN STD_LOGIC;
       pc_axis_tid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       pc_axis_tdest : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       pc_axis_tuser : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       pc_asserted : OUT STD_LOGIC;
       pc_status : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
   END COMPONENT;

   constant GET_BUILD_INFO_C : BuildInfoRetType := toBuildInfo(BUILD_INFO_C);
   constant MOD_BUILD_INFO_C : BuildInfoRetType := (
      buildString => GET_BUILD_INFO_C.buildString,
      fwVersion   => GET_BUILD_INFO_C.fwVersion,
      gitHash     => x"1111_2222_3333_4444_5555_6666_7777_8888_9999_AAAA");  -- Force githash
   constant SIM_BUILD_INFO_C : slv(2239 downto 0) := toSlv(MOD_BUILD_INFO_C);

   constant CLK_PERIOD_G : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_G/4;

   constant NUM_AXIL_MASTERS_C : natural := 1;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, x"0000_0000", 20, 16);

   signal axilClk  : sl := '0';
   signal axilRst  : sl := '0';
   signal axilRstL : sl := '1';

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;

   signal axilReadMaster : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave  : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_INIT_C;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   -- signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal axilReadMasters : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves  : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_INIT_C);
   -- signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal asserted : slv(NUM_AXIL_MASTERS_C downto 0) := (others => '0');

begin

   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_G,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axilClk,
         rst  => axilRst,
         rstL => axilRstL);









   GEN_VEC : for i in NUM_AXIS_C-1 downto 0 generate
      U_Checker : AxiStreamProtocolChecker
     PORT MAP (
       aclk => aclk,
       aresetn => axilRstL,
       pc_axis_tvalid => pc_axis_tvalid,
       pc_axis_tready => pc_axis_tready,
       pc_axis_tdata => pc_axis_tdata,
       pc_axis_tstrb => pc_axis_tstrb,
       pc_axis_tkeep => pc_axis_tkeep,
       pc_axis_tlast => pc_axis_tlast,
       pc_axis_tid => pc_axis_tid,
       pc_axis_tdest => pc_axis_tdest,
       pc_axis_tuser => pc_axis_tuser,
       pc_asserted => pc_asserted,
       pc_status => pc_status
     );
   end generate GEN_VEC;

   ---------------------------------
   -- AXI-Lite Register Transactions
   ---------------------------------
   test : process is
      variable debugData : slv(31 downto 0) := (others => '0');
   begin
      debugData := x"1111_1111";
      ------------------------------------------
      -- Wait for the AXI-Lite reset to complete
      ------------------------------------------
      wait until axilRst = '1';
      wait until axilRst = '0';

      -- Get the FW Version
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0000", debugData, true);

      -- Get the FW Version from wrong location
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"8000_0000", debugData, true);

      -- Get the FW Version again
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0000", debugData, true);

      -----------------------------
      -- Check if simulation passed
      -----------------------------
      if asserted = 0 then
         assert false
            report "Simulation Passed!" severity failure;
      else
         assert false
            report "Simulation Failed!" severity failure;
      end if;

   end process test;





end testbed;
