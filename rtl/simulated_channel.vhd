library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity simulated_channel is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        sample_ce  : in  std_logic;

        tx_rf      : in  rf_t;
        rx_rf      : out rf_t
    );
end entity;

architecture rtl of simulated_channel is

    -- Q1.15 scale: value * 2^15 (32768).
    constant Q15_ONE : real := 2.0**15;

    constant CHANNEL_GAIN_REAL    : real := 0.1;
    constant NOISE_AMPLITUDE_REAL : real := 0.05;

    constant CHANNEL_GAIN_Q15    : q15_t := to_signed(integer(CHANNEL_GAIN_REAL    * Q15_ONE), 16);
    constant NOISE_AMPLITUDE_Q15 : q15_t := to_signed(integer(NOISE_AMPLITUDE_REAL * Q15_ONE), 16);

    signal lfsr : unsigned(15 downto 0) := x"ACE1";
begin

    -- Hardware-synthesizable pseudo-random noise source.
    process(clk)
        variable feedback : std_logic;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                lfsr <= x"ACE1";
            elsif sample_ce = '1' then
                feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
                lfsr <= lfsr(14 downto 0) & feedback;
            end if;
        end if;
    end process;

    process(tx_rf, lfsr)
        variable gain_product  : signed(33 downto 0);
        variable noise_product : signed(31 downto 0);
        variable signal_scaled : signed(18 downto 0);
        variable noise_scaled  : signed(18 downto 0);
        variable channel_sum   : signed(18 downto 0);
    begin
        gain_product := tx_rf * CHANNEL_GAIN_Q15;
        signal_scaled := resize(shift_right(gain_product, 15), 19);

        noise_product := signed(lfsr) * NOISE_AMPLITUDE_Q15;
        noise_scaled := resize(shift_right(noise_product, 15), 19);

        channel_sum := signal_scaled + noise_scaled;

        rx_rf <= resize(channel_sum, RF_WIDTH);
    end process;

end architecture;
