-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SurfAxiLiteProtocolChecker module
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

   component AxiLiteCrossbarIpCore
      port (
         aclk          : in  std_logic;
         aresetn       : in  std_logic;
         s_axi_awaddr  : in  std_logic_vector(63 downto 0);
         s_axi_awprot  : in  std_logic_vector(5 downto 0);
         s_axi_awvalid : in  std_logic_vector(1 downto 0);
         s_axi_awready : out std_logic_vector(1 downto 0);
         s_axi_wdata   : in  std_logic_vector(63 downto 0);
         s_axi_wstrb   : in  std_logic_vector(7 downto 0);
         s_axi_wvalid  : in  std_logic_vector(1 downto 0);
         s_axi_wready  : out std_logic_vector(1 downto 0);
         s_axi_bresp   : out std_logic_vector(3 downto 0);
         s_axi_bvalid  : out std_logic_vector(1 downto 0);
         s_axi_bready  : in  std_logic_vector(1 downto 0);
         s_axi_araddr  : in  std_logic_vector(63 downto 0);
         s_axi_arprot  : in  std_logic_vector(5 downto 0);
         s_axi_arvalid : in  std_logic_vector(1 downto 0);
         s_axi_arready : out std_logic_vector(1 downto 0);
         s_axi_rdata   : out std_logic_vector(63 downto 0);
         s_axi_rresp   : out std_logic_vector(3 downto 0);
         s_axi_rvalid  : out std_logic_vector(1 downto 0);
         s_axi_rready  : in  std_logic_vector(1 downto 0);
         m_axi_awaddr  : out std_logic_vector(31 downto 0);
         m_axi_awprot  : out std_logic_vector(2 downto 0);
         m_axi_awvalid : out std_logic_vector(0 downto 0);
         m_axi_awready : in  std_logic_vector(0 downto 0);
         m_axi_wdata   : out std_logic_vector(31 downto 0);
         m_axi_wstrb   : out std_logic_vector(3 downto 0);
         m_axi_wvalid  : out std_logic_vector(0 downto 0);
         m_axi_wready  : in  std_logic_vector(0 downto 0);
         m_axi_bresp   : in  std_logic_vector(1 downto 0);
         m_axi_bvalid  : in  std_logic_vector(0 downto 0);
         m_axi_bready  : out std_logic_vector(0 downto 0);
         m_axi_araddr  : out std_logic_vector(31 downto 0);
         m_axi_arprot  : out std_logic_vector(2 downto 0);
         m_axi_arvalid : out std_logic_vector(0 downto 0);
         m_axi_arready : in  std_logic_vector(0 downto 0);
         m_axi_rdata   : in  std_logic_vector(31 downto 0);
         m_axi_rresp   : in  std_logic_vector(1 downto 0);
         m_axi_rvalid  : in  std_logic_vector(0 downto 0);
         m_axi_rready  : out std_logic_vector(0 downto 0)
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

   constant GET_BUILD_INFO_C : BuildInfoRetType := toBuildInfo(BUILD_INFO_C);
   constant MOD_BUILD_INFO_C : BuildInfoRetType := (
      buildString => GET_BUILD_INFO_C.buildString,
      fwVersion   => GET_BUILD_INFO_C.fwVersion,
      gitHash     => x"1111_2222_3333_4444_5555_6666_7777_8888_9999_AAAA");  -- Force githash
   constant SIM_BUILD_INFO_C : slv(2239 downto 0) := toSlv(MOD_BUILD_INFO_C);

   constant CLK_PERIOD_C : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_C/4;

   constant USE_XBAR_IP_CORE_C : boolean := false;

   constant USE_BRAM_IP_CORE_C : boolean := true;

   constant NUM_AXIL_MASTERS_C : natural := 1;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, x"0000_0000", 20, 16);

   signal mAxilWriteMasters : AxiLiteWriteMasterArray(1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   signal mAxilReadMasters  : AxiLiteReadMasterArray(1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0)   := (others => AXI_LITE_READ_SLAVE_INIT_C);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal axilReadMasters : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves  : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_INIT_C);

   signal pc_status   : Slv160Array(NUM_AXIL_MASTERS_C+1 downto 0) := (others => (others => '0'));
   signal pc_asserted : slv(NUM_AXIL_MASTERS_C+1 downto 0)         := (others => '0');
   signal bramBusy    : slv(1 downto 0)         := (others => '0');

   signal axilClk : sl := '0';
   signal axilRst : sl := '1';
   signal axilRstL : sl := '0';

   signal done : sl := '0';
   
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

   ------------------------------------------------------------------------------------------------
   -- AXI-Lite Register Transactions via axiLiteBusSimRead/axiLiteBusSimWrite simulation procedures
   ------------------------------------------------------------------------------------------------
   test : process is
      variable debugData : slv(31 downto 0) := (others => '0');
   begin
      debugData := x"1111_1111";
      -----------------------------------------------
      -- Wait for the AxiLiteMasterTester to complete
      -----------------------------------------------
      wait until done = '1';

      -- -- Access mapped region
      -- axiLiteBusSimRead (axilClk, mAxilReadMasters(0), mAxilReadSlaves(0), x"0000_0000", debugData, true);
      -- axiLiteBusSimRead (axilClk, mAxilReadMasters(0), mAxilReadSlaves(0), x"0000_0004", debugData, true);
      -- axiLiteBusSimRead (axilClk, mAxilReadMasters(0), mAxilReadSlaves(0), x"0000_0000", debugData, true);
      -- axiLiteBusSimRead (axilClk, mAxilReadMasters(0), mAxilReadSlaves(0), x"0000_0004", debugData, true);

      -- -- Access unmapped region
      -- axiLiteBusSimRead (axilClk, mAxilReadMasters(0), mAxilReadSlaves(0), x"8000_0000", debugData, true);

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

   -------------------------------------------------------------------
   -- AXI-Lite Register Transactions via surf.AxiLiteMaster RTL module
   -------------------------------------------------------------------
   U_AxiLiteMasterTester : entity work.AxiLiteMasterTester
      generic map (
         TPD_G => TPD_G)
      port map (
         enable           => axilRstL,
         done             => done,
         -- AXI-Lite Register Interface (sysClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => mAxilReadMasters(1),
         mAxilReadSlave   => mAxilReadSlaves(1),
         mAxilWriteMaster => mAxilWriteMasters(1),
         mAxilWriteSlave  => mAxilWriteSlaves(1));

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   XBAR_RTL : if (USE_XBAR_IP_CORE_C = false) generate
      U_XBAR : entity surf.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
            -- DEC_ERROR_RESP_G   => AXI_RESP_OK_C,
            NUM_SLAVE_SLOTS_G  => 2,
            NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
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
   end generate;

   XBAR_IP_CORE : if (USE_XBAR_IP_CORE_C = true) generate
      U_XBAR : AxiLiteCrossbarIpCore
         port map (
            aclk                       => axilClk,
            aresetn                    => axilRstL,
            -- SLAVE
            s_axi_awaddr(31 downto 0)  => mAxilWriteMasters(0).awaddr,
            s_axi_awaddr(63 downto 32) => mAxilWriteMasters(1).awaddr,
            s_axi_awprot(2 downto 0)   => mAxilWriteMasters(0).awprot,
            s_axi_awprot(5 downto 3)   => mAxilWriteMasters(1).awprot,
            s_axi_awvalid(0)           => mAxilWriteMasters(0).awvalid,
            s_axi_awvalid(1)           => mAxilWriteMasters(1).awvalid,
            s_axi_wdata(31 downto 0)   => mAxilWriteMasters(0).wdata,
            s_axi_wdata(63 downto 32)  => mAxilWriteMasters(1).wdata,
            s_axi_wstrb(3 downto 0)    => mAxilWriteMasters(0).wstrb,
            s_axi_wstrb(7 downto 4)    => mAxilWriteMasters(1).wstrb,
            s_axi_wvalid(0)            => mAxilWriteMasters(0).wvalid,
            s_axi_wvalid(1)            => mAxilWriteMasters(1).wvalid,
            s_axi_bready(0)            => mAxilWriteMasters(0).bready,
            s_axi_bready(1)            => mAxilWriteMasters(1).bready,
            s_axi_awready(0)           => mAxilWriteSlaves(0).awready,
            s_axi_awready(1)           => mAxilWriteSlaves(1).awready,
            s_axi_wready(0)            => mAxilWriteSlaves(0).wready,
            s_axi_wready(1)            => mAxilWriteSlaves(1).wready,
            s_axi_bresp(1 downto 0)    => mAxilWriteSlaves(0).bresp,
            s_axi_bresp(3 downto 2)    => mAxilWriteSlaves(1).bresp,
            s_axi_bvalid(0)            => mAxilWriteSlaves(0).bvalid,
            s_axi_bvalid(1)            => mAxilWriteSlaves(1).bvalid,
            s_axi_araddr(31 downto 0)  => mAxilReadMasters(0).araddr,
            s_axi_araddr(63 downto 32) => mAxilReadMasters(1).araddr,
            s_axi_arprot(2 downto 0)   => mAxilReadMasters(0).arprot,
            s_axi_arprot(5 downto 3)   => mAxilReadMasters(1).arprot,
            s_axi_arvalid(0)           => mAxilReadMasters(0).arvalid,
            s_axi_arvalid(1)           => mAxilReadMasters(1).arvalid,
            s_axi_rready(0)            => mAxilReadMasters(0).rready,
            s_axi_rready(1)            => mAxilReadMasters(1).rready,
            s_axi_arready(0)           => mAxilReadSlaves(0).arready,
            s_axi_arready(1)           => mAxilReadSlaves(1).arready,
            s_axi_rdata(31 downto 0)   => mAxilReadSlaves(0).rdata,
            s_axi_rdata(63 downto 32)  => mAxilReadSlaves(1).rdata,
            s_axi_rresp(1 downto 0)    => mAxilReadSlaves(0).rresp,
            s_axi_rresp(3 downto 2)    => mAxilReadSlaves(1).rresp,
            s_axi_rvalid(0)            => mAxilReadSlaves(0).rvalid,
            s_axi_rvalid(1)            => mAxilReadSlaves(1).rvalid,
            -- SLAVE
            m_axi_awaddr(31 downto 0)  => axilWriteMasters(0).awaddr,
            m_axi_awprot(2 downto 0)   => axilWriteMasters(0).awprot,
            m_axi_awvalid(0)           => axilWriteMasters(0).awvalid,
            m_axi_wdata(31 downto 0)   => axilWriteMasters(0).wdata,
            m_axi_wstrb(3 downto 0)    => axilWriteMasters(0).wstrb,
            m_axi_wvalid(0)            => axilWriteMasters(0).wvalid,
            m_axi_bready(0)            => axilWriteMasters(0).bready,
            m_axi_awready(0)           => axilWriteSlaves(0).awready,
            m_axi_wready(0)            => axilWriteSlaves(0).wready,
            m_axi_bresp(1 downto 0)    => axilWriteSlaves(0).bresp,
            m_axi_bvalid(0)            => axilWriteSlaves(0).bvalid,
            m_axi_araddr(31 downto 0)  => axilReadMasters(0).araddr,
            m_axi_arprot(2 downto 0)   => axilReadMasters(0).arprot,
            m_axi_arvalid(0)           => axilReadMasters(0).arvalid,
            m_axi_rready(0)            => axilReadMasters(0).rready,
            m_axi_arready(0)           => axilReadSlaves(0).arready,
            m_axi_rdata(31 downto 0)   => axilReadSlaves(0).rdata,
            m_axi_rresp(1 downto 0)    => axilReadSlaves(0).rresp,
            m_axi_rvalid(0)            => axilReadSlaves(0).rvalid);
   end generate;

   ----------------------------
   -- AXI-Lite Protocol Checker
   ----------------------------
   GEN_SRC : for i in 1 downto 0 generate
      U_Checker : AxiLiteProtocolChecker
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
   end generate GEN_SRC;

   GEN_DST : for i in NUM_AXIL_MASTERS_C-1 downto 0 generate
      U_Checker : AxiLiteProtocolChecker
         port map (
            pc_status      => pc_status(i+2),
            pc_asserted    => pc_asserted(i+2),
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
   end generate GEN_DST;

   ---------------------
   -- AXI-Lite End Point
   ---------------------
   RTL_END_POINT : if (USE_BRAM_IP_CORE_C = false) generate
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
   end generate;

   IP_END_POINT : if (USE_BRAM_IP_CORE_C = true) generate
      U_BRAM : AxiLiteBramIpCore
         port map (
            rsta_busy     => bramBusy(0),
            rstb_busy     => bramBusy(1),
            s_aclk        => axilClk,
            s_aresetn     => axilRstL,
            s_axi_awaddr  => axilWriteMasters(0).awaddr,
            s_axi_awvalid => axilWriteMasters(0).awvalid,
            s_axi_wdata   => axilWriteMasters(0).wdata,
            s_axi_wstrb   => axilWriteMasters(0).wstrb,
            s_axi_wvalid  => axilWriteMasters(0).wvalid,
            s_axi_bready  => axilWriteMasters(0).bready,
            s_axi_awready => axilWriteSlaves(0).awready,
            s_axi_wready  => axilWriteSlaves(0).wready,
            s_axi_bresp   => axilWriteSlaves(0).bresp,
            s_axi_bvalid  => axilWriteSlaves(0).bvalid,
            s_axi_araddr  => axilReadMasters(0).araddr,
            s_axi_arvalid => axilReadMasters(0).arvalid,
            s_axi_rready  => axilReadMasters(0).rready,
            s_axi_arready => axilReadSlaves(0).arready,
            s_axi_rdata   => axilReadSlaves(0).rdata,
            s_axi_rresp   => axilReadSlaves(0).rresp,
            s_axi_rvalid  => axilReadSlaves(0).rvalid);
   end generate;

end testbed;
