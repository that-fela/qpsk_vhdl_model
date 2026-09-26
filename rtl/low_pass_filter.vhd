library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity low_pass_filter is
    generic (
        INPUT_WIDTH  : integer := 19;
        OUTPUT_WIDTH : integer := 19
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        sample_ce  : in  std_logic;
        sample_in  : in  signed(INPUT_WIDTH - 1 downto 0);
        sample_out : out signed(OUTPUT_WIDTH - 1 downto 0)
    );
end entity;

architecture rtl of low_pass_filter is

    constant COEFF_WIDTH : integer := 16;
    constant ACC_WIDTH   : integer := 48;

    type delay_array_t is array (0 to FIR_TAPS - 2) of
        signed(INPUT_WIDTH - 1 downto 0);

    signal delay_line : delay_array_t := (others => (others => '0'));
    signal output_reg : signed(OUTPUT_WIDTH - 1 downto 0) := (others => '0');

begin

    sample_out <= output_reg;

    process(clk)
        variable acc  : signed(ACC_WIDTH - 1 downto 0);
        variable prod : signed(INPUT_WIDTH + COEFF_WIDTH - 1 downto 0);
        variable x    : signed(INPUT_WIDTH - 1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                delay_line <= (others => (others => '0'));
                output_reg <= (others => '0');

            elsif sample_ce = '1' then

                acc := (others => '0');

                for k in 0 to FIR_TAPS - 1 loop
                    if k = 0 then
                        x := sample_in;
                    else
                        x := delay_line(k - 1);
                    end if;

                    prod := x * to_signed(FIR_COEFFS(k), COEFF_WIDTH);
                    acc := acc + resize(prod, ACC_WIDTH);
                end loop;

                -- Coefficients are Q1.15.
                output_reg <= resize(shift_right(acc, 15), OUTPUT_WIDTH);

                for k in FIR_TAPS - 2 downto 1 loop
                    delay_line(k) <= delay_line(k - 1);
                end loop;

                delay_line(0) <= sample_in;
            end if;
        end if;
    end process;

end architecture;
