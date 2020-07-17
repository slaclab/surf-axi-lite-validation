-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SurfAxiLiteProtocolChecker module
-------------------------------------------------------------------------------
-- This file is part of 'surf-axi-protocol-checking'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'surf-axi-protocol-checking', including this file,
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

entity SurfAxiLiteProtocolCheckerTb is end SurfAxiLiteProtocolCheckerTb;

architecture testbed of SurfAxiLiteProtocolCheckerTb is

   component AxiLiteProtocolChecker
      port (
         pc_status      : out std_logic_vector(159 downto 0);
         pc_asserted    : out std_logic;
         -- system_resetn  : in  std_logic;
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

   component AxiLiteBramIpCore
      port (
         rsta_busy     : out std_logic;
         rstb_busy     : out std_logic;
         s_aclk        : in  std_logic;
         s_aresetn     : in  std_logic;
         s_axi_awaddr  : in  std_logic_vector(31 downto 0);
         s_axi_awvalid : in  std_logic;
         s_axi_awready : out std_logic;
         s_axi_wdata   : in  std_logic_vector(31 downto 0);
         s_axi_wstrb   : in  std_logic_vector(3 downto 0);
         s_axi_wvalid  : in  std_logic;
         s_axi_wready  : out std_logic;
         s_axi_bresp   : out std_logic_vector(1 downto 0);
         s_axi_bvalid  : out std_logic;
         s_axi_bready  : in  std_logic;
         s_axi_araddr  : in  std_logic_vector(31 downto 0);
         s_axi_arvalid : in  std_logic;
         s_axi_arready : out std_logic;
         s_axi_rdata   : out std_logic_vector(31 downto 0);
         s_axi_rresp   : out std_logic_vector(1 downto 0);
         s_axi_rvalid  : out std_logic;
         s_axi_rready  : in  std_logic
         );
   end component;

   constant CLK_PERIOD_C : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_C/4;

   constant NUM_AXIL_BUSES_C : positive := 3;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_BUSES_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_BUSES_C, x"0000_0000", 20, 16);

   signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_BUSES_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_BUSES_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   signal mAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_BUSES_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_BUSES_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_INIT_C);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_BUSES_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_BUSES_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal axilReadMasters : AxiLiteReadMasterArray(NUM_AXIL_BUSES_C-1 downto 0) := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves  : AxiLiteReadSlaveArray(NUM_AXIL_BUSES_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_INIT_C);

   signal pc_status   : Slv160Array(2*NUM_AXIL_BUSES_C-1 downto 0) := (others => (others => '0'));
   signal pc_asserted : slv(2*NUM_AXIL_BUSES_C-1 downto 0)         := (others => '0');

   signal axilClk  : sl := '0';
   signal axilRst  : sl := '1';
   signal axilRstL : sl := '0';

   signal done   : slv(NUM_AXIL_BUSES_C-1 downto 0) := (others => '0');
   signal failed : slv(NUM_AXIL_BUSES_C-1 downto 0) := (others => '0');

begin

   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1 us)
      port map (
         clkP => axilClk,
         rst  => axilRst,
         rstL => axilRstL);

   -------------------------------------------------------------------
   -- AXI-Lite Register Transactions via surf.AxiLiteMaster RTL module
   -------------------------------------------------------------------
   RTL_MEM_TESTER : for i in NUM_AXIL_BUSES_C-1 downto 0 generate
      U_AxiLiteMasterTester : entity work.AxiLiteMasterTester
         generic map (
            TPD_G   => TPD_G,
            INDEX_G => i)
         port map (
            done             => done(i),
            failed           => failed(i),
            -- AXI-Lite Register Interface (sysClk domain)
            axilClk          => axilClk,
            axilRst          => axilRst,
            mAxilReadMaster  => mAxilReadMasters(i),
            mAxilReadSlave   => mAxilReadSlaves(i),
            mAxilWriteMaster => mAxilWriteMasters(i),
            mAxilWriteSlave  => mAxilWriteSlaves(i));
   end generate;

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         NUM_SLAVE_SLOTS_G  => NUM_AXIL_BUSES_C,
         NUM_MASTER_SLOTS_G => NUM_AXIL_BUSES_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         axiClk           => axilClk,
         axiClkRst        => axilRst,
         sAxiWriteMasters => mAxilWriteMasters,
         sAxiWriteSlaves  => mAxilWriteSlaves,
         sAxiReadMasters  => mAxilReadMasters,
         sAxiReadSlaves   => mAxilReadSlaves,
         mAxiWriteMasters => axilWriteMasters,
         mAxiWriteSlaves  => axilWriteSlaves,
         mAxiReadMasters  => axilReadMasters,
         mAxiReadSlaves   => axilReadSlaves);

   ----------------------------
   -- AXI-Lite Protocol Checker
   ----------------------------
   GEN_VEC : for i in NUM_AXIL_BUSES_C-1 downto 0 generate

      ------------------------------------
      -- Master AXI-Lite Protocol Checking
      ------------------------------------
      U_MasterChecker : AxiLiteProtocolChecker
         port map (
            pc_status      => pc_status(i),
            pc_asserted    => pc_asserted(i),
            -- system_resetn  => axilRstL,
            aclk           => axilClk,
            aresetn        => axilRstL,
            pc_axi_awaddr  => mAxilWriteMasters(i).awaddr,
            pc_axi_awprot  => mAxilWriteMasters(i).awprot,
            pc_axi_awvalid => mAxilWriteMasters(i).awvalid,
            pc_axi_wdata   => mAxilWriteMasters(i).wdata,
            pc_axi_wstrb   => mAxilWriteMasters(i).wstrb,
            pc_axi_wvalid  => mAxilWriteMasters(i).wvalid,
            pc_axi_bready  => mAxilWriteMasters(i).bready,
            pc_axi_awready => mAxilWriteSlaves(i).awready,
            pc_axi_wready  => mAxilWriteSlaves(i).wready,
            pc_axi_bresp   => mAxilWriteSlaves(i).bresp,
            pc_axi_bvalid  => mAxilWriteSlaves(i).bvalid,
            pc_axi_araddr  => mAxilReadMasters(i).araddr,
            pc_axi_arprot  => mAxilReadMasters(i).arprot,
            pc_axi_arvalid => mAxilReadMasters(i).arvalid,
            pc_axi_rready  => mAxilReadMasters(i).rready,
            pc_axi_arready => mAxilReadSlaves(i).arready,
            pc_axi_rdata   => mAxilReadSlaves(i).rdata,
            pc_axi_rresp   => mAxilReadSlaves(i).rresp,
            pc_axi_rvalid  => mAxilReadSlaves(i).rvalid);

      ------------------------------------
      -- Master AXI-Lite Protocol Checking
      ------------------------------------
      U_SlaveChecker : AxiLiteProtocolChecker
         port map (
            pc_status      => pc_status(i+NUM_AXIL_BUSES_C),
            pc_asserted    => pc_asserted(i+NUM_AXIL_BUSES_C),
            -- system_resetn  => axilRstL,
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

      ------------------------------
      -- IP Core AXI-Lite End Points
      ------------------------------
      IP_END_POINT : if (i = 0) generate
         U_BRAM : AxiLiteBramIpCore
            port map (
               rsta_busy     => open,
               rstb_busy     => open,
               s_aclk        => axilClk,
               s_aresetn     => axilRstL,
               s_axi_awaddr  => axilWriteMasters(i).awaddr,
               s_axi_awvalid => axilWriteMasters(i).awvalid,
               s_axi_wdata   => axilWriteMasters(i).wdata,
               s_axi_wstrb   => axilWriteMasters(i).wstrb,
               s_axi_wvalid  => axilWriteMasters(i).wvalid,
               s_axi_bready  => axilWriteMasters(i).bready,
               s_axi_awready => axilWriteSlaves(i).awready,
               s_axi_wready  => axilWriteSlaves(i).wready,
               s_axi_bresp   => axilWriteSlaves(i).bresp,
               s_axi_bvalid  => axilWriteSlaves(i).bvalid,
               s_axi_araddr  => axilReadMasters(i).araddr,
               s_axi_arvalid => axilReadMasters(i).arvalid,
               s_axi_rready  => axilReadMasters(i).rready,
               s_axi_arready => axilReadSlaves(i).arready,
               s_axi_rdata   => axilReadSlaves(i).rdata,
               s_axi_rresp   => axilReadSlaves(i).rresp,
               s_axi_rvalid  => axilReadSlaves(i).rvalid);
      end generate;

      ------------------------------------------------------------------
      -- RTL AXI-Lite End Points using axiSlaveDefault() helper function
      ------------------------------------------------------------------
      RTL_END_POINT_TYPE_0 : if (i = 1) generate
         U_AxiMemMap : entity work.AxiMemMapEndPoint
            generic map (
               TPD_G => TPD_G)
            port map (
               -- AXI-Lite Interface
               axiClk         => axilClk,
               axiRst         => axilRst,
               axiReadMaster  => axilReadMasters(i),
               axiReadSlave   => axilReadSlaves(i),
               axiWriteMaster => axilWriteMasters(i),
               axiWriteSlave  => axilWriteSlaves(i));
      end generate;

      ----------------------------------------------------------------------------------------------------
      -- RTL AXI-Lite End Points using axiSlaveReadResponse() and axiSlaveWriteResponse() helper functions
      ----------------------------------------------------------------------------------------------------
      RTL_END_POINT_TYPE_1 : if (i > 1) generate
         U_AxiDualPortRam : entity surf.AxiDualPortRam
            generic map (
               TPD_G        => TPD_G,
               ADDR_WIDTH_G => 8)
            port map (
               -- AXI-Lite Interface
               axiClk         => axilClk,
               axiRst         => axilRst,
               axiReadMaster  => axilReadMasters(i),
               axiReadSlave   => axilReadSlaves(i),
               axiWriteMaster => axilWriteMasters(i),
               axiWriteSlave  => axilWriteSlaves(i));
      end generate;

   end generate GEN_VEC;

   --------------------------------
   -- Monitor for pass/fail Results
   --------------------------------
   test : process is
   begin

      -----------------------------------------------
      -- Wait for the AxiLiteMasterTester to complete
      -----------------------------------------------
      wait until uAnd(done) = '1';

      ------------------------------------------------------
      -- Check if simulation failed during RTL memory tester
      ------------------------------------------------------
      if failed /= 0 then
         assert false
            report "Simulation Failed!" severity failure;
      end if;

      -----------------------------
      -- Check if simulation passed
      -----------------------------
      if pc_asserted = 0 then
         assert false
            report "Simulation Passed!" severity failure;
      else
         assert false
            report "Simulation Failed!" severity failure;
      end if;

   end process test;

end testbed;
