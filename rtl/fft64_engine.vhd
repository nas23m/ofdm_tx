library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ofdm_pkg.all;

entity fft64_engine is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    in_i       : in  complex_array;
    in_q       : in  complex_array;
    out_i      : out complex_array;
    out_q      : out complex_array;
    done       : out std_logic
  );
end entity;

architecture rtl of fft64_engine is
  type ram_t is array (0 to N_FFT-1) of signed(DW-1 downto 0);
  signal ram_i, ram_q : ram_t := (others => (others => '0'));

  type state_t is (IDLE, LOAD, BUTTERFLY, FINISH);
  signal state : state_t := IDLE;

  signal stage     : integer range 0 to LOG2_N-1 := 0;
  signal bf_idx    : integer range 0 to N_FFT/2-1 := 0;
  signal load_idx  : integer range 0 to N_FFT-1 := 0;

  signal a_i, a_q, b_i, b_q : signed(DW-1 downto 0);
  signal w_re, w_im         : signed(DW-1 downto 0);

  signal tw_addr  : unsigned(AW-2 downto 0);
  signal tw_addr_r : integer range 0 to N_FFT/2-1 := 0;
  signal phase    : std_logic := '0';

  function bitrev(x : integer) return integer is
    variable v : unsigned(LOG2_N-1 downto 0) := to_unsigned(x, LOG2_N);
    variable r : unsigned(LOG2_N-1 downto 0);
  begin
    for k in 0 to LOG2_N-1 loop
      r(k) := v(LOG2_N-1-k);
    end loop;
    return to_integer(r);
  end function;

  -- DIF radix-2: i0 = a, i1 = b, twiddle index tw
  procedure bf_addr(stage_i, bf_i : in integer;
                    i0, i1     : out integer;
                    tw         : out integer) is
    variable half : integer;
    variable grp  : integer;
    variable off  : integer;
  begin
    half := N_FFT / (2 ** (stage_i+1));
    grp  := bf_i / half;
    off  := bf_i mod half;
    i0 := grp * 2 * half + off;
    i1 := i0 + half;
    tw := off * (2 ** stage_i);
  end procedure;

begin
  u_rom : entity work.twiddle_rom
    port map (addr => tw_addr, re => w_re, im => w_im);

  tw_addr <= to_unsigned(tw_addr_r, AW-1);

  process(clk)
    variable i0, i1, tw : integer;
    variable s_i, s_q   : signed(DW downto 0);
    variable d_i, d_q   : signed(DW downto 0);
    variable pr, pim    : signed(DW+DW+1 downto 0);
    variable r_i, r_q   : signed(DW-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state  <= IDLE;
        done   <= '0';
        stage  <= 0;
        bf_idx <= 0;
        load_idx <= 0;
        phase  <= '0';
      else
        case state is
          when IDLE =>
            done <= '0';
            if start = '1' then
              state    <= LOAD;
              load_idx <= 0;
            end if;

          when LOAD =>
            ram_i(load_idx) <= in_i(load_idx);
            ram_q(load_idx) <= in_q(load_idx);
            if load_idx = N_FFT-1 then
              state    <= BUTTERFLY;
              stage    <= 0;
              bf_idx   <= 0;
              load_idx <= 0;
              phase    <= '0';
            else
              load_idx <= load_idx + 1;
            end if;

          when BUTTERFLY =>
            bf_addr(stage, bf_idx, i0, i1, tw);
            if phase = '0' then
              -- fetch operands and twiddle address
              tw_addr_r <= tw;
              a_i <= ram_i(i0);  a_q <= ram_q(i0);
              b_i <= ram_i(i1);  b_q <= ram_q(i1);
              phase <= '1';
            else
              -- IFFT: conj twiddle W = w_re - j*(-w_im) ; 1/2 scaling per stage
              s_i := resize(a_i, DW+1) + resize(b_i, DW+1);
              s_q := resize(a_q, DW+1) + resize(b_q, DW+1);
              d_i := resize(a_i, DW+1) - resize(b_i, DW+1);
              d_q := resize(a_q, DW+1) - resize(b_q, DW+1);

              ram_i(i0) <= resize(shift_right(s_i + 1, 1), DW);
              ram_q(i0) <= resize(shift_right(s_q + 1, 1), DW);

              pr  := resize(d_i * w_re, DW+DW+2) + resize(d_q * w_im, DW+DW+2);
              pim := resize(d_q * w_re, DW+DW+2) - resize(d_i * w_im, DW+DW+2);
              r_i := resize(shift_right(pr  + 32768, DW), DW);
              r_q := resize(shift_right(pim + 32768, DW), DW);
              ram_i(i1) <= r_i;
              ram_q(i1) <= r_q;
              phase <= '0';

              if bf_idx = N_FFT/2-1 then
                bf_idx <= 0;
                if stage = LOG2_N-1 then
                  state <= FINISH;
                else
                  stage <= stage + 1;
                end if;
              else
                bf_idx <= bf_idx + 1;
              end if;
            end if;

          when FINISH =>
            done <= '1';
            for k in 0 to N_FFT-1 loop      -- bit-reversed -> natural order
              out_i(k) <= ram_i(bitrev(k));
              out_q(k) <= ram_q(bitrev(k));
            end loop;
            state <= IDLE;
        end case;
      end if;
    end if;
  end process;
end architecture;