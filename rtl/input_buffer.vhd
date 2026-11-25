library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ofdm_pkg.all;

entity input_buffer is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    bit_in    : in  std_logic;
    bit_v     : in  std_logic;
    sym_i     : out complex_array;
    sym_q     : out complex_array;
    sym_ready : out std_logic
  );
end entity;

architecture rtl of input_buffer is
  signal ram_i : complex_array := (others => (others => '0'));
  signal ram_q : complex_array := (others => (others => '0'));
  signal idx   : integer range 0 to 2*N_FFT-1 := 0;   
  signal rdy   : std_logic := '0';
begin
  process(clk)
    variable b0, b1 : std_logic;
    variable sym_idx : integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        idx <= 0;
        rdy <= '0';
      elsif bit_v = '1' then
        if idx mod 2 = 0 then
          ram_q(idx/2) <= (DW-1 => bit_in, others => '0');
        else
       
          b0 := ram_q(idx/2)(DW-1); 
          b1 := bit_in;               
          if b0 = '0' then
            ram_i(idx/2) <= to_signed( 16384, DW);
          else
            ram_i(idx/2) <= to_signed(-16384, DW);
          end if;
          if b1 = '0' then
            ram_q(idx/2) <= to_signed( 16384, DW);
          else
            ram_q(idx/2) <= to_signed(-16384, DW);
          end if;
        end if;

        if idx = 2*N_FFT-1 then
          idx <= 0;
          rdy <= '1';        
        else
          idx <= idx + 1;
          rdy <= '0';
        end if;
      else
        rdy <= '0';
      end if;
    end if;
  end process;

  sym_i     <= ram_i;
  sym_q     <= ram_q;
  sym_ready <= rdy;
end architecture;