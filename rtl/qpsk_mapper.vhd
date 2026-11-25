library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ofdm_pkg.all;

entity qpsk_mapper is
  port (
    bit    : in  std_logic;
    bit_v  : in  std_logic;
    i_out  : out signed(DW-1 downto 0);
    q_out  : out signed(DW-1 downto 0);
    dout_v : out std_logic
  );
end entity;

architecture rtl of qpsk_mapper is
begin
  process(all)
  begin
    if bit_v = '1' then

      if bit = '0' then
        i_out <= to_signed( 16384, DW);
        q_out <= to_signed( 16384, DW);
      else
        i_out <= to_signed(-16384, DW);
        q_out <= to_signed(-16384, DW);
      end if;
    else
      i_out <= (others => '0');
      q_out <= (others => '0');
    end if;
    dout_v <= bit_v;
  end process;
end architecture;