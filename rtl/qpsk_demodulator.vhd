library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity qpsk_demodulator is
    generic (
        SAMPLE_OFFSET : integer := 84
    );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        sample_ce      : in  std_logic;

        received_rf    : in  rf_t;

        i_carrier      : in  q15_t;
        q_carrier      : in  q15_t;

        mixed_i        : out bb_t;
        mixed_q        : out bb_t;

        baseband_i     : out bb_t;
        baseband_q     : out bb_t;

        received_bits  : out std_logic_vector(1 downto 0);
        bits_valid     : out std_logic
    );
end entity;

architecture rtl of qpsk_demodulator is

    signal mix_i_signal : bb_t := (others => '0');
    signal mix_q_signal : bb_t := (others => '0');

    signal filtered_i : bb_t := (others => '0');
    signal filtered_q : bb_t := (others => '0');

    signal symbol_count : integer range 0 to SAMPLES_PER_SYMBOL - 1 := 0;

begin

    mixed_i <= mix_i_signal;
    mixed_q <= mix_q_signal;

    -- RF * carrier.
    -- The carrier is Q1.15, RF is Q2.15.
    process(received_rf, i_carrier, q_carrier)
        variable pi : signed(33 downto 0);
        variable pq : signed(33 downto 0);
    begin
        pi := received_rf * i_carrier;
        pq := received_rf * q_carrier;

        mix_i_signal <= resize(shift_right(pi, 15), BB_WIDTH);
        mix_q_signal <= resize(shift_right(pq, 15), BB_WIDTH);
    end process;

    fir_i : entity work.low_pass_filter
        generic map (
            INPUT_WIDTH  => BB_WIDTH,
            OUTPUT_WIDTH => BB_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            sample_ce  => sample_ce,
            sample_in  => mix_i_signal,
            sample_out => filtered_i
        );

    fir_q : entity work.low_pass_filter
        generic map (
            INPUT_WIDTH  => BB_WIDTH,
            OUTPUT_WIDTH => BB_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            sample_ce  => sample_ce,
            sample_in  => mix_q_signal,
            sample_out => filtered_q
        );

    -- Mixer gives a factor of 1/2. Multiply by two to match the Python
    -- demodulator's 2.0 * Gain scaling.
    baseband_i <= shift_left(filtered_i, 1);
    baseband_q <= shift_left(filtered_q, 1);

    process(clk)
        variable i_decision : std_logic;
        variable q_decision : std_logic;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                symbol_count <= 0;
                received_bits <= (others => '0');
                bits_valid <= '0';

            elsif sample_ce = '1' then
                bits_valid <= '0';

                if symbol_count = SAMPLE_OFFSET then
                    if baseband_i(baseband_i'high) = '0' then
                        i_decision := '1';
                    else
                        i_decision := '0';
                    end if;

                    if baseband_q(baseband_q'high) = '0' then
                        q_decision := '1';
                    else
                        q_decision := '0';
                    end if;

                    received_bits <= i_decision & q_decision;
                    bits_valid <= '1';
                end if;

                if symbol_count = SAMPLES_PER_SYMBOL - 1 then
                    symbol_count <= 0;
                else
                    symbol_count <= symbol_count + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;
