-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the SurfAxiStreamProtocolChecker module
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
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

entity SurfAxiStreamProtocolCheckerTb is end SurfAxiStreamProtocolCheckerTb;

architecture testbed of SurfAxiStreamProtocolCheckerTb is

   constant AXIS_CONFIG_INIT_C : AxiStreamConfigType := ssiAxiStreamConfig(
      dataBytes => 8,                   -- 64-bit (8 bytes)
      tKeepMode => TKEEP_COMP_C,
      tUserMode => TUSER_FIRST_LAST_C,
      tDestBits => 4,
      tUserBits => 4,
      tIdBits   => 4);

   component AxiStreamProtocolChecker
      port (
         aclk           : in  std_logic;
         aresetn        : in  std_logic;
         pc_axis_tvalid : in  std_logic;
         pc_axis_tready : in  std_logic;
         pc_axis_tdata  : in  std_logic_vector(8*AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0);
         pc_axis_tkeep  : in  std_logic_vector(AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0);
         pc_axis_tlast  : in  std_logic;
         pc_axis_tid    : in  std_logic_vector(AXIS_CONFIG_INIT_C.TID_BITS_C-1 downto 0);
         pc_axis_tdest  : in  std_logic_vector(AXIS_CONFIG_INIT_C.TDEST_BITS_C-1 downto 0);
         pc_axis_tuser  : in  std_logic_vector(AXIS_CONFIG_INIT_C.TUSER_BITS_C-1 downto 0);
         pc_asserted    : out std_logic;
         pc_status      : out std_logic_vector(31 downto 0)
         );
   end component;

   constant CLK_PERIOD_G : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_G/4;

   constant PACKET_LENGTH_C : slv(31 downto 0) := toSlv(256, 32);
   constant NUMBER_PACKET_C : slv(31 downto 0) := toSlv(1024, 32);

   constant NUM_AXIS_C : natural := 4;

   signal txMasters : AxiStreamMasterArray(NUM_AXIS_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txSlaves  : AxiStreamSlaveArray(NUM_AXIS_C-1 downto 0);

   signal muxMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal muxSlave  : AxiStreamSlaveType;

   signal rxMasters : AxiStreamMasterArray(NUM_AXIS_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal rxSlaves  : AxiStreamSlaveArray(NUM_AXIS_C-1 downto 0);

   signal pc_status   : Slv32Array(2*NUM_AXIS_C downto 0) := (others => (others => '0'));
   signal pc_asserted : slv(2*NUM_AXIS_C downto 0)        := (others => '0');

   signal clk  : sl := '0';
   signal rst  : sl := '1';
   signal rstL : sl := '0';

   signal passed : slv(NUM_AXIS_C-1 downto 0) := (others => '0');
   signal failed : sl                         := '0';

   signal updated       : slv(NUM_AXIS_C-1 downto 0)        := (others => '0');
   signal errorDet      : slv(NUM_AXIS_C-1 downto 0)        := (others => '0');
   signal cnt           : Slv32Array(NUM_AXIS_C-1 downto 0) := (others => (others => '0'));
   signal packetLengths : Slv32Array(NUM_AXIS_C-1 downto 0) := (others => (others => '0'));

begin

   --------------------
   -- Clocks and Resets
   --------------------
   U_axisClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_G,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => clk,
         rst  => rst,
         rstL => rstL);

   ----------------
   -- AXI Stream TX
   ----------------
   GEN_TX :
   for i in (NUM_AXIS_C-1) downto 0 generate

      U_SsiPrbsTx : entity surf.SsiPrbsTx
         generic map (
            -- General Configurations
            TPD_G                      => TPD_G,
            AXI_EN_G                   => '0',
            -- AXI Stream Configurations
            MASTER_AXI_STREAM_CONFIG_G => AXIS_CONFIG_INIT_C)
         port map (
            -- Master Port (mAxisClk)
            mAxisClk     => clk,
            mAxisRst     => rst,
            mAxisMaster  => txMasters(i),
            mAxisSlave   => txSlaves(i),
            -- Trigger Signal (locClk domain)
            locClk       => clk,
            locRst       => rst,
            trig         => rstL,
            packetLength => PACKET_LENGTH_C,
            forceEofe    => '0',
            busy         => open,
            tDest        => toSlv(i, 8),
            tId          => toSlv(i, 8));

      U_Checker : AxiStreamProtocolChecker
         port map (
            aclk           => clk,
            aresetn        => rstL,
            pc_axis_tvalid => txMasters(i).tvalid,
            pc_axis_tready => txSlaves(i).tready,
            pc_axis_tdata  => txMasters(i).tdata(8*AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
            pc_axis_tkeep  => txMasters(i).tkeep(AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
            pc_axis_tlast  => txMasters(i).tlast,
            pc_axis_tid    => txMasters(i).tid(AXIS_CONFIG_INIT_C.TID_BITS_C-1 downto 0),
            pc_axis_tdest  => txMasters(i).tdest(AXIS_CONFIG_INIT_C.TDEST_BITS_C-1 downto 0),
            pc_axis_tuser  => txMasters(i).tuser(AXIS_CONFIG_INIT_C.TUSER_BITS_C-1 downto 0),
            pc_asserted    => pc_asserted(i),
            pc_status      => pc_status(i));

   end generate GEN_TX;

   -----------------
   -- AXI Stream MUX
   -----------------
   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_AXIS_C,
         MODE_G               => "INDEXED",
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => true,
         ILEAVE_REARB_G       => 32,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => clk,
         axisRst      => rst,
         -- Slaves
         sAxisMasters => txMasters,
         sAxisSlaves  => txSlaves,
         -- Master
         mAxisMaster  => muxMaster,
         mAxisSlave   => muxSlave);

   U_Checker : AxiStreamProtocolChecker
      port map (
         aclk           => clk,
         aresetn        => rstL,
         pc_axis_tvalid => muxMaster.tvalid,
         pc_axis_tready => muxSlave.tready,
         pc_axis_tdata  => muxMaster.tdata(8*AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
         pc_axis_tkeep  => muxMaster.tkeep(AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
         pc_axis_tlast  => muxMaster.tlast,
         pc_axis_tid    => muxMaster.tid(AXIS_CONFIG_INIT_C.TID_BITS_C-1 downto 0),
         pc_axis_tdest  => muxMaster.tdest(AXIS_CONFIG_INIT_C.TDEST_BITS_C-1 downto 0),
         pc_axis_tuser  => muxMaster.tuser(AXIS_CONFIG_INIT_C.TUSER_BITS_C-1 downto 0),
         pc_asserted    => pc_asserted(2*NUM_AXIS_C),
         pc_status      => pc_status(2*NUM_AXIS_C));

   -------------------
   -- AXI Stream DEMUX
   -------------------
   U_DeMux : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => NUM_AXIS_C,
         MODE_G        => "INDEXED",
         PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk      => clk,
         axisRst      => rst,
         -- Slave
         sAxisMaster  => muxMaster,
         sAxisSlave   => muxSlave,
         -- Masters
         mAxisMasters => rxMasters,
         mAxisSlaves  => rxSlaves);

   ----------------
   -- AXI Stream RX
   ----------------
   GEN_RX :
   for i in (NUM_AXIS_C-1) downto 0 generate

      U_SsiPrbsRx : entity surf.SsiPrbsRx
         generic map (
            -- General Configurations
            TPD_G                     => TPD_G,
            -- FIFO Configurations
            GEN_SYNC_FIFO_G           => true,
            -- AXI Stream Configurations
            SLAVE_AXI_STREAM_CONFIG_G => AXIS_CONFIG_INIT_C)
         port map (
            -- Streaming RX Data Interface (sAxisClk domain)
            sAxisClk       => clk,
            sAxisRst       => rst,
            sAxisMaster    => rxMasters(i),
            sAxisSlave     => rxSlaves(i),
            -- Optional: AXI-Lite Register Interface (axiClk domain)
            axiClk         => clk,
            axiRst         => rst,
            axiReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
            axiWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
            -- Error Detection Signals (sAxisClk domain)
            updatedResults => updated(i),
            errorDet       => errorDet(i),
            packetLength   => packetLengths(i));

      U_Checker : AxiStreamProtocolChecker
         port map (
            aclk           => clk,
            aresetn        => rstL,
            pc_axis_tvalid => rxMasters(i).tvalid,
            pc_axis_tready => rxSlaves(i).tready,
            pc_axis_tdata  => rxMasters(i).tdata(8*AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
            pc_axis_tkeep  => rxMasters(i).tkeep(AXIS_CONFIG_INIT_C.TDATA_BYTES_C-1 downto 0),
            pc_axis_tlast  => rxMasters(i).tlast,
            pc_axis_tid    => rxMasters(i).tid(AXIS_CONFIG_INIT_C.TID_BITS_C-1 downto 0),
            pc_axis_tdest  => rxMasters(i).tdest(AXIS_CONFIG_INIT_C.TDEST_BITS_C-1 downto 0),
            pc_axis_tuser  => rxMasters(i).tuser(AXIS_CONFIG_INIT_C.TUSER_BITS_C-1 downto 0),
            pc_asserted    => pc_asserted(i+NUM_AXIS_C),
            pc_status      => pc_status(i+NUM_AXIS_C));

   end generate GEN_RX;

   --------------------------------
   -- Monitor for pass/fail Results
   --------------------------------
   process(clk)
      variable i : natural;
   begin
      if rising_edge(clk) then
         if rst = '1' then
            failed <= '0'             after TPD_G;
            passed <= (others => '0') after TPD_G;
         else
            -- Check for protocol violation
            if pc_asserted /= 0 then
               failed <= '1' after TPD_G;
            end if;
            -- Check each RX channel
            for i in NUM_AXIS_C-1 downto 0 loop
               if updated(i) = '1' then
                  -- Check for missed packet error
                  if errorDet(i) = '1' then
                     failed <= '1' after TPD_G;
                  end if;
                  -- Check for packet size mismatch
                  if packetLengths(i) /= PACKET_LENGTH_C then
                     failed <= '1' after TPD_G;
                  end if;
                  -- Check the counter
                  if cnt(i) = NUMBER_PACKET_C then
                     passed(i) <= '1' after TPD_G;
                  else
                     -- Increment the counter
                     cnt(i) <= cnt(i) + 1 after TPD_G;
                  end if;
               end if;
            end loop;
         end if;
      end if;
   end process;

   process(failed, passed)
   begin
      if failed = '1' then
         assert false
            report "Simulation Failed!" severity failure;
      end if;
      if uAnd(passed) = '1' then
         assert false
            report "Simulation Passed!" severity failure;
      end if;
   end process;

end testbed;
