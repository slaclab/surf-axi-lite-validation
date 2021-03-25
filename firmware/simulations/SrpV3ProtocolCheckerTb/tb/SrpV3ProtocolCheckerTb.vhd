-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation testbed for SrpV3AxiLite
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

entity SrpV3ProtocolCheckerTb is

end entity SrpV3ProtocolCheckerTb;

architecture tb of SrpV3ProtocolCheckerTb is

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

   constant GET_BUILD_INFO_C : BuildInfoRetType := toBuildInfo(BUILD_INFO_C);
   constant MOD_BUILD_INFO_C : BuildInfoRetType := (
      buildString => GET_BUILD_INFO_C.buildString,
      fwVersion   => x"1234_5678",      -- force FW version
      gitHash     => x"1111_2222_3333_4444_5555_6666_7777_8888_9999_AAAA");  -- Force githash
   constant SIM_BUILD_INFO_C : slv(2239 downto 0) := toSlv(MOD_BUILD_INFO_C);

   constant CLK_PERIOD_C : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_C/4;

   constant AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(AXI_STREAM_MAX_TKEEP_WIDTH_C);

   constant NUM_AXIL_BUSES_C : positive := 1;

   type StateType is (
      WRITE_REQ_S,
      WRITE_RESP_S,
      READ_REQ_S,
      READ_RESP_S,
      DONE_S);

   type RegType is record
      done        : sl;
      tid         : slv(31 downto 0);
      sAxisMaster : AxiStreamMasterType;
      mAxisSlave  : AxiStreamSlaveType;
      state       : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      done        => '0',
      tid         => toSlv(1, 32),
      sAxisMaster => AXI_STREAM_MASTER_INIT_C,
      mAxisSlave  => AXI_STREAM_SLAVE_INIT_C,
      state       => WRITE_REQ_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk  : sl := '0';
   signal rst  : sl := '1';
   signal rstL : sl := '0';

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;

   signal sAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal sAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal mAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal mAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   signal pc_status   : Slv160Array(NUM_AXIL_BUSES_C-1 downto 0) := (others => (others => '0'));
   signal pc_asserted : slv(NUM_AXIL_BUSES_C-1 downto 0)         := (others => '0');

begin

   ---------------------------
   -- Generate clock and reset
   ---------------------------
   U_ClkRst : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk,
         rst  => rst,
         rstL => rstL);

   ----------------------
   -- Module Being Tested
   ----------------------
   U_SRPv3 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => AXIS_CONFIG_C)
      port map (
         -- AXIS Slave Interface (sAxisClk domain)
         sAxisClk         => clk,
         sAxisRst         => rst,
         sAxisMaster      => sAxisMaster,
         sAxisSlave       => sAxisSlave,
         -- AXIS Master Interface (mAxisClk domain)
         mAxisClk         => clk,
         mAxisRst         => rst,
         mAxisMaster      => mAxisMaster,
         mAxisSlave       => mAxisSlave,
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => clk,
         axilRst          => rst,
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave);

   ------------------------------------
   -- Master AXI-Lite Protocol Checking
   ------------------------------------
   U_MasterChecker : AxiLiteProtocolChecker
      port map (
         pc_status      => pc_status(0),
         pc_asserted    => pc_asserted(0),
         -- system_resetn  => axilRstL,
         aclk           => clk,
         aresetn        => rstL,
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

   U_BRAM : AxiLiteBramIpCore
      port map (
         rsta_busy     => open,
         rstb_busy     => open,
         s_aclk        => clk,
         s_aresetn     => rstL,
         s_axi_awaddr  => axilWriteMaster.awaddr,
         s_axi_awvalid => axilWriteMaster.awvalid,
         s_axi_wdata   => axilWriteMaster.wdata,
         s_axi_wstrb   => axilWriteMaster.wstrb,
         s_axi_wvalid  => axilWriteMaster.wvalid,
         s_axi_bready  => axilWriteMaster.bready,
         s_axi_awready => axilWriteSlave.awready,
         s_axi_wready  => axilWriteSlave.wready,
         s_axi_bresp   => axilWriteSlave.bresp,
         s_axi_bvalid  => axilWriteSlave.bvalid,
         s_axi_araddr  => axilReadMaster.araddr,
         s_axi_arvalid => axilReadMaster.arvalid,
         s_axi_rready  => axilReadMaster.rready,
         s_axi_arready => axilReadSlave.arready,
         s_axi_rdata   => axilReadSlave.rdata,
         s_axi_rresp   => axilReadSlave.rresp,
         s_axi_rvalid  => axilReadSlave.rvalid);

   comb : process (mAxisMaster, r, rst, sAxisSlave) is
      variable v          : RegType;
      variable cntPattern : slv(63 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- AXI stream Flow control
      v.mAxisSlave.tReady := '0';
      if (sAxisSlave.tReady = '1') then
         v.sAxisMaster.tValid := '0';
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when WRITE_REQ_S =>
            -- Check if ready to move data
            if (v.sAxisMaster.tValid = '0') then

               -- Send 1 word frame
               v.sAxisMaster.tValid := '1';
               v.sAxisMaster.tLast  := '1';
               v.sAxisMaster.tKeep  := resize(x"FFFFFF", AXI_STREAM_MAX_TKEEP_WIDTH_C);
               ssiSetUserSof(AXIS_CONFIG_C, v.sAxisMaster, '1');

               -- Format the frame
               v.sAxisMaster.tData((0*32)+31 downto (0*32)) := x"0000_0103";
               v.sAxisMaster.tData((1*32)+31 downto (1*32)) := r.tid;
               v.sAxisMaster.tData((2*32)+31 downto (2*32)) := x"0000_0004";  -- Addr[31:0] = ScratchPad address
               v.sAxisMaster.tData((3*32)+31 downto (3*32)) := x"0000_0000";  -- Addr[63:32] = zeros
               v.sAxisMaster.tData((4*32)+31 downto (4*32)) := x"0000_0003";  -- 0x3 = 4 byte transaction
               v.sAxisMaster.tData((5*32)+31 downto (5*32)) := x"BABE_CAFE";

               -- Next State
               v.state := WRITE_RESP_S;

            end if;
         ----------------------------------------------------------------------
         when WRITE_RESP_S =>
            -- Check for response
            if (mAxisMaster.tValid = '1') then

               -- Accept the data
               v.mAxisSlave.tReady := '1';

               -- Increment the counter
               v.tid := r.tid + 1;

               -- Next State
               v.state := READ_REQ_S;

            end if;
         ----------------------------------------------------------------------
         when READ_REQ_S =>
            -- Check if ready to move data
            if (v.sAxisMaster.tValid = '0') then

               -- Send 1 word frame
               v.sAxisMaster.tValid := '1';
               v.sAxisMaster.tLast  := '1';
               v.sAxisMaster.tKeep  := resize(x"FFFFF", AXI_STREAM_MAX_TKEEP_WIDTH_C);
               ssiSetUserSof(AXIS_CONFIG_C, v.sAxisMaster, '1');

               -- Format the frame
               v.sAxisMaster.tData((0*32)+31 downto (0*32)) := x"0000_0003";
               v.sAxisMaster.tData((1*32)+31 downto (1*32)) := r.tid;
               v.sAxisMaster.tData((2*32)+31 downto (2*32)) := x"0000_0004";  -- Addr[31:0] = ScratchPad address
               v.sAxisMaster.tData((3*32)+31 downto (3*32)) := x"0000_0000";  -- Addr[63:32] = zeros
               v.sAxisMaster.tData((4*32)+31 downto (4*32)) := x"0000_0003";  -- 0x3 = 4 byte transaction
               v.sAxisMaster.tData((5*32)+31 downto (5*32)) := x"0000_0000";  -- clear out for debugging

               -- Next State
               v.state := READ_RESP_S;

            end if;
         ----------------------------------------------------------------------
         when READ_RESP_S =>
            -- Check for response
            if (mAxisMaster.tValid = '1') then

               -- Accept the data
               v.mAxisSlave.tReady := '1';

               -- Increment the counter
               v.tid := r.tid + 1;

               -- Next State
               v.state := DONE_S;

            end if;
         ----------------------------------------------------------------------
         when DONE_S =>
            v.done := '1';
      ----------------------------------------------------------------------
      end case;

      -- Outputs
      mAxisSlave  <= v.mAxisSlave;
      sAxisMaster <= r.sAxisMaster;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Monitor for pass/fail Results
   --------------------------------
   test : process is
   begin

      -----------------------------------------------
      -- Wait for the AxiLiteMasterTester to complete
      -----------------------------------------------
      wait until r.done = '1';

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

end architecture tb;
