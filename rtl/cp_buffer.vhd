library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ofdm_pkg.all;

entity cp_buffer is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    in_i       : in  complex_array;
    in_q       : in  complex_array;
    out_i      : out signed(DW-1 downto 0);
    out_q      : out signed(DW-1 downto 0);
    out_v      : out std_logic;
    done       : out std_logic
  );
end entity;

architecture rtl of cp_buffer is
  type ram_t is array (0 to SYM_LEN-1) of signed(DW-1 downto 0);
  signal ram_i, ram_q : ram_t := (others => (others => '0'));
  signal wr_idx, rd_idx : integer range 0 to SYM_LEN-1 := 0;
  signal state : std_logic := '0';  -- 0 = write, 1 = read
  signal started : std_logic := '0';
begin
  process(clk)
    variable src : integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state   <= '0';
        wr_idx  <= 0;
        rd_idx  <= 0;
        out_v   <= '0';
        done    <= '0';
        started <= '0';
      else
        done <= '0';
        if start = '1' then
          state   <= '0';
          wr_idx  <= 0;
          rd_idx  <= 0;
          started <= '1';
        elsif started = '1' and state = '0' then
          ram_i(wr_idx) <= in_i(wr_idx);
          ram_q(wr_idx) <= in_q(wr_idx);
          if wr_idx = N_FFT-1 then
            for k in 0 to CP_LEN-1 loop
              ram_i(N_FFT + k) <= in_i(N_FFT - CP_LEN + k);
              ram_q(N_FFT + k) <= in_q(N_FFT - CP_LEN + k);
            end loop;
            state  <= '1';
            rd_idx <= 0;
          else
            wr_idx <= wr_idx + 1;
          end if;
        elsif state = '1' then
          if rd_idx < CP_LEN then
            src := N_FFT - CP_LEN + rd_idx;
          else
            src := rd_idx - CP_LEN;
          end if;
          out_i <= ram_i(src);
          out_q <= ram_q(src);
          out_v <= '1';

          if rd_idx = SYM_LEN-1 then
            state   <= '0';
            rd_idx  <= 0;
            done    <= '1';
            started <= '0';
          else
            rd_idx <= rd_idx + 1;
          end if;
        else
          out_v <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture;