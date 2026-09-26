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
        -- Gain = 0.4 in Q1.15.
        gain_product := tx_rf * to_signed(13107, 16);
        signal_scaled := resize(shift_right(gain_product, 15), 19);

        -- Uniform pseudo-random noise with approximately +/-0.1 amplitude.
        noise_product := signed(lfsr) * to_signed(3277, 16);
        noise_scaled := resize(shift_right(noise_product, 15), 19);

        channel_sum := signal_scaled + noise_scaled;

        rx_rf <= resize(channel_sum, RF_WIDTH);
    end process;

end architecture;
