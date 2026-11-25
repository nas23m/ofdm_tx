library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.ofdm_pkg.all;

entity twiddle_rom is
  port (
    addr : in  unsigned(AW-2 downto 0);        
    re   : out signed(DW-1 downto 0);
    im   : out signed(DW-1 downto 0)
  );
end entity;

architecture rtl of twiddle_rom is
  type rom_t is array (0 to N_FFT/2-1) of signed(DW-1 downto 0);

  impure function load_rom(fname : string) return rom_t is
    variable r : rom_t;
    variable l : line;
    variable v : std_logic_vector(DW-1 downto 0);
    file f : text open read_mode is fname;
  begin
    for i in r'range loop
      readline(f, l);
      hread(l, v);
      r(i) := signed(v);
    end loop;
    return r;
  end function;

  constant RE_ROM : rom_t := load_rom("twiddle_re.mem");
  constant IM_ROM : rom_t := load_rom("twiddle_im.mem");
begin
  process(all)
  begin
    re <= RE_ROM(to_integer(addr));
    im <= IM_ROM(to_integer(addr));
  end process;
end architecture;