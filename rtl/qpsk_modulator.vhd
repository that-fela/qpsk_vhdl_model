library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity qpsk_modulator is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        sample_ce    : in  std_logic;

        symbol_valid : in  std_logic;
        symbol_bits  : in  std_logic_vector(1 downto 0);

        carrier_i    : in  q15_t;
        carrier_q    : in  q15_t;

        i_out        : out q15_t;
        q_out        : out q15_t;
        rf_out       : out rf_t
    );
end entity;

architecture rtl of qpsk_modulator is
    signal i_symbol : q15_t := (others => '0');
    signal q_symbol : q15_t := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                i_symbol <= (others => '0');
                q_symbol <= (others => '0');

            elsif sample_ce = '1' and symbol_valid = '1' then
                case symbol_bits is
                    when "00" =>
                        i_symbol <= to_signed(-32768, 16);
                        q_symbol <= to_signed(-32768, 16);

                    when "01" =>
                        i_symbol <= to_signed(-32768, 16);
                        q_symbol <= to_signed( 32767, 16);

                    when "10" =>
                        i_symbol <= to_signed( 32767, 16);
                        q_symbol <= to_signed(-32768, 16);

                    when others =>
                        i_symbol <= to_signed( 32767, 16);
                        q_symbol <= to_signed( 32767, 16);
                end case;
            end if;
        end if;
    end process;

    i_out <= i_symbol;
    q_out <= q_symbol;

    process(i_symbol, q_symbol, carrier_i, carrier_q)
        variable pi    : signed(31 downto 0);
        variable pq    : signed(31 downto 0);
        variable total : signed(32 downto 0);
    begin
        pi := i_symbol * carrier_i;
        pq := q_symbol * carrier_q;

        total := resize(pi, 33) + resize(pq, 33);

        -- Q1.15 * Q1.15 -> Q2.30.
        -- Shift back by 15 bits.
        rf_out <= resize(shift_right(total, 15), RF_WIDTH);
    end process;

end architecture;
