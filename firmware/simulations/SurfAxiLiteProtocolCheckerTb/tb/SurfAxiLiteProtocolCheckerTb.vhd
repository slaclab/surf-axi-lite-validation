-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SurfAxiLiteProtocolCheckerTb module
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
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

entity SurfAxiLiteProtocolCheckerTb is end SurfAxiLiteProtocolCheckerTb;

architecture testbed of SurfAxiLiteProtocolCheckerTb is

   component AxiLiteProtocolChecker
      port (
         pc_status      : out std_logic_vector(159 downto 0);
         pc_asserted    : out std_logic;
         aclk           : in  std_logic;
         aresetn        : in  std_logic;
         pc_axi_awaddr  : in  std_logic_vector(31 downto 0);
         pc_axi_awprot  : in  std_logic_vector(2 downto 0);
         pc_axi_awvalid : in  std_logic;
         pc_axi_awready : in  std_logic;
         pc_axi_wdata   : in  std_logic_vector(31 downto 0);
         pc_axi_wstrb   : in  std_logic_vector(3 downto 0);
         pc_axi_wvalid  : in  std_logic;
         pc_axi_wready  : in  std_logic;
         pc_axi_bresp   : in  std_logic_vector(1 downto 0);
         pc_axi_bvalid  : in  std_logic;
         pc_axi_bready  : in  std_logic;
         pc_axi_araddr  : in  std_logic_vector(31 downto 0);
         pc_axi_arprot  : in  std_logic_vector(2 downto 0);
         pc_axi_arvalid : in  std_logic;
         pc_axi_arready : in  std_logic;
         pc_axi_rdata   : in  std_logic_vector(31 downto 0);
         pc_axi_rresp   : in  std_logic_vector(1 downto 0);
         pc_axi_rvalid  : in  std_logic;
         pc_axi_rready  : in  std_logic
         );
   end component;

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

   signal asserted : slv(2 downto 0) := (others => '0');

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

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ----------------------------
   -- AXI-Lite Protocol Checker
   ----------------------------
   U_Checker : AxiLiteProtocolChecker
      port map (
         pc_status      => open,
         pc_asserted    => asserted(0),
         aclk           => axilClk,
         aresetn        => axilRstL,
         pc_axi_awaddr  => axilWriteMaster.awaddr,
         pc_axi_awprot  => axilWriteMaster.awprot,
         pc_axi_awvalid => axilWriteMaster.awvalid,
         pc_axi_wdata   => axilWriteMaster.wdata,
         pc_axi_wstrb   => axilWriteMaster.wstrb,
         pc_axi_wvalid  => axilWriteMaster.wvalid,
         pc_axi_bready  => axilWriteMaster.bready,
         pc_axi_awready => axilWriteSlave.awready,
         pc_axi_wready  => axilWriteSlave.wready,
         pc_axi_bresp   => axilWriteSlave.bresp,
         pc_axi_bvalid  => axilWriteSlave.bvalid,
         pc_axi_araddr  => axilReadMaster.araddr,
         pc_axi_arprot  => axilReadMaster.arprot,
         pc_axi_arvalid => axilReadMaster.arvalid,
         pc_axi_rready  => axilReadMaster.rready,
         pc_axi_arready => axilReadSlave.arready,
         pc_axi_rdata   => axilReadSlave.rdata,
         pc_axi_rresp   => axilReadSlave.rresp,
         pc_axi_rvalid  => axilReadSlave.rvalid);

   GEN_VEC : for i in NUM_AXIL_MASTERS_C-1 downto 0 generate
      U_Checker : AxiLiteProtocolChecker
         port map (
            pc_status      => open,
            pc_asserted    => asserted(i+1),
            aclk           => axilClk,
            aresetn        => axilRstL,
            pc_axi_awaddr  => axilWriteMasters(i).awaddr,
            pc_axi_awprot  => axilWriteMasters(i).awprot,
            pc_axi_awvalid => axilWriteMasters(i).awvalid,
            pc_axi_wdata   => axilWriteMasters(i).wdata,
            pc_axi_wstrb   => axilWriteMasters(i).wstrb,
            pc_axi_wvalid  => axilWriteMasters(i).wvalid,
            pc_axi_bready  => axilWriteMasters(i).bready,
            pc_axi_awready => axilWriteSlaves(i).awready,
            pc_axi_wready  => axilWriteSlaves(i).wready,
            pc_axi_bresp   => axilWriteSlaves(i).bresp,
            pc_axi_bvalid  => axilWriteSlaves(i).bvalid,
            pc_axi_araddr  => axilReadMasters(i).araddr,
            pc_axi_arprot  => axilReadMasters(i).arprot,
            pc_axi_arvalid => axilReadMasters(i).arvalid,
            pc_axi_rready  => axilReadMasters(i).rready,
            pc_axi_arready => axilReadSlaves(i).arready,
            pc_axi_rdata   => axilReadSlaves(i).rdata,
            pc_axi_rresp   => axilReadSlaves(i).rresp,
            pc_axi_rvalid  => axilReadSlaves(i).rvalid);
   end generate GEN_VEC;

   ---------------------
   -- AXI-Lite End Point
   ---------------------
   U_Version : entity surf.AxiVersion
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => SIM_BUILD_INFO_C)
      port map (
         -- AXI-Lite Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(0),
         axiReadSlave   => axilReadSlaves(0),
         axiWriteMaster => axilWriteMasters(0),
         axiWriteSlave  => axilWriteSlaves(0));

end testbed;
