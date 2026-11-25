library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.ofdm_pkg.all;

entity tb_ofdm_tx is
end entity;

architecture sim of tb_ofdm_tx is
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal bit_in    : std_logic := '0';
  signal bit_v     : std_logic := '0';
  signal sym_i, sym_q : signed(DW-1 downto 0);
  signal sym_v     : std_logic;
  signal ifft_i_par, ifft_q_par : complex_array;
  signal ifft_v    : std_logic;
  signal done      : boolean := false;

  constant CLK_PER : time := 10 ns;

  file f_out  : text open write_mode is "ofdm_out.txt";
  file f_ifft : text open write_mode is "ofdm_ifft.txt";
begin
  clk <= not clk after CLK_PER/2 when not done else '0';

  dut : entity work.ofdm_tx_top
    port map (
      clk        => clk,
      rst        => rst,
      bit_in     => bit_in,
      bit_v      => bit_v,
      sym_i      => sym_i,
      sym_q      => sym_q,
      sym_v      => sym_v,
      ifft_i_par => ifft_i_par,
      ifft_q_par => ifft_q_par,
      ifft_v     => ifft_v
    );

    stim : process
    -- 128 bits = 32 hex characters (1B4E repeated 8 times)
    constant PATTERN : std_logic_vector(127 downto 0) := 
      x"1B4E1B4E1B4E1B4E1B4E1B4E1B4E1B4E";
    variable L : line;
    variable cnt : integer := 0;
  begin
    rst <= '1';
    wait for 50 ns;
    rst <= '0';
    wait for 20 ns;

    for i in PATTERN'range loop
      bit_in <= PATTERN(i);
      bit_v  <= '1';
      wait for CLK_PER;
    end loop;
    bit_v <= '0';

    wait until ifft_v = '1' for 500 * CLK_PER;
    wait for CLK_PER;

    for k in 0 to N_FFT-1 loop
      write(L, to_integer(ifft_i_par(k)));
      write(L, ' ');
      write(L, to_integer(ifft_q_par(k)));
      writeline(f_ifft, L);
    end loop;
    file_close(f_ifft);

    while cnt < SYM_LEN loop
      wait until rising_edge(clk);
      if sym_v = '1' then
        write(L, to_integer(sym_i));
        write(L, ' ');
        write(L, to_integer(sym_q));
        writeline(f_out, L);
        cnt := cnt + 1;
      end if;
    end loop;
    file_close(f_out);

    report "Simulation complete. Files: ofdm_ifft.txt (64), ofdm_out.txt (80)" severity note;
    done <= true;
    wait;
  end process;
end architecture;