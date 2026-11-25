# ---- Variables ----
set proj_name ofdm_tx_real
set proj_dir  "C:/Users/nassim/Desktop/ofdm_tx/vivado"
set root_dir  "C:/Users/nassim/Desktop/ofdm_tx"
set part      xck24-ubva530-2LV-c

# ---- Create project ----
create_project $proj_name $proj_dir -part $part -force

# ---- Add RTL ----
add_files -norecurse [glob "$root_dir/rtl/*.vhd"]
set_property file_type {VHDL 2008} [get_files *.vhd]
set_property top ofdm_tx_top [current_fileset]

# ---- Add simulation ----
add_files -fileset sim_1 -norecurse [glob "$root_dir/sim/*.vhd"]
set_property top tb_ofdm_tx [get_fileset sim_1]

# ---- Copy .mem files next to the sim run directory ----
set sim_dir "$proj_dir/$proj_name.sim/sim_1/behav/xsim"
file mkdir $sim_dir
file copy -force "$root_dir/mem/twiddle_re.mem" $sim_dir/
file copy -force "$root_dir/mem/twiddle_im.mem" $sim_dir/

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project ready at: $proj_dir"
puts "Open: $proj_dir/$proj_name.xpr"
puts "Then run: launch_simulation; run all"