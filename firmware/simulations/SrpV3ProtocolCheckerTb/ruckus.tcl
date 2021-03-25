# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for version 2020.1 of Vivado (or later)
if { [VersionCheck 2020.1] < 0 } {exit -1}

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules/surf

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb"
loadIpCore           -dir "$::DIR_PATH/ip"

# Set the top level synth_1 and sim_1
set_property top {AxiVersion} [get_filesets sources_1]
set_property top {SrpV3ProtocolCheckerTb} [get_filesets sim_1]
