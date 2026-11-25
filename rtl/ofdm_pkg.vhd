library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ofdm_pkg is
  constant N_FFT    : integer := 64;
  constant LOG2_N   : integer := 6;
  constant CP_LEN   : integer := 16;
  constant SYM_LEN  : integer := N_FFT + CP_LEN;    
  constant DW       : integer := 16;               
  constant AW       : integer := 6;                

  type complex_array is array (0 to N_FFT-1)
    of signed(DW-1 downto 0);
end package;