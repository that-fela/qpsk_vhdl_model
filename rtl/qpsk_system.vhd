library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity qpsk_system is
    port (
        clk             : in  std_logic;                     -- System clock
        reset           : in  std_logic;                     -- Active-high reset

        tx_symbol_valid : in  std_logic;                     -- TX symbol valid
        tx_symbol_bits  : in  std_logic_vector(1 downto 0); -- TX QPSK symbol bits

        sample_ce       : out std_logic;                     -- Sample-rate clock enable

        tx_i            : out q15_t;                         -- Transmitted I baseband signal
        tx_q            : out q15_t;                         -- Transmitted Q baseband signal
        tx_rf           : out rf_t;                          -- Transmitted RF signal

        rx_rf           : out rf_t;                          -- Received RF signal after channel
        rx_mixed_i      : out bb_t;                          -- Mixed-down I signal before filtering
        rx_mixed_q      : out bb_t;                          -- Mixed-down Q signal before filtering
        rx_i            : out bb_t;                          -- Recovered filtered I signal
        rx_q            : out bb_t;                          -- Recovered filtered Q signal

        rx_bits         : out std_logic_vector(1 downto 0); -- Received QPSK symbol bits
        rx_bits_valid   : out std_logic                     -- Received bits are valid
    );
end entity;

architecture rtl of qpsk_system is

    signal sample_div : integer range 0 to SAMPLE_DIVIDER - 1 := 0;
    signal sample_ce_i : std_logic;

    signal carrier_i : q15_t;
    signal carrier_q : q15_t;

begin

    -- 100 MHz -> 10 MHz sample enable.
    sample_ce_i <= '1' when sample_div = SAMPLE_DIVIDER - 1 else '0';
    sample_ce <= sample_ce_i;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                sample_div <= 0;
            elsif sample_div = SAMPLE_DIVIDER - 1 then
                sample_div <= 0;
            else
                sample_div <= sample_div + 1;
            end if;
        end if;
    end process;

    carrier_i_gen : entity work.cosine_generator
        generic map (
            PHASE_OFFSET => x"00000000"
        )
        port map (
            clk        => clk,
            reset      => reset,
            sample_ce  => sample_ce_i,
            cosine_out => carrier_i
        );

    carrier_q_gen : entity work.cosine_generator
        generic map (
            -- cos(wt + pi/2) = -sin(wt)
            PHASE_OFFSET => Q_CARRIER_PHASE
        )
        port map (
            clk        => clk,
            reset      => reset,
            sample_ce  => sample_ce_i,
            cosine_out => carrier_q
        );

    modulator : entity work.qpsk_modulator
        port map (
            clk          => clk,
            reset        => reset,
            sample_ce    => sample_ce_i,
            symbol_valid => tx_symbol_valid,
            symbol_bits  => tx_symbol_bits,
            carrier_i    => carrier_i,
            carrier_q    => carrier_q,
            i_out        => tx_i,
            q_out        => tx_q,
            rf_out       => tx_rf
        );

    channel : entity work.simulated_channel
        port map (
            clk       => clk,
            reset     => reset,
            sample_ce => sample_ce_i,
            tx_rf     => tx_rf,
            rx_rf     => rx_rf
        );

    demodulator : entity work.qpsk_demodulator
        generic map (
            -- FIR group delay = 31 samples.
            -- There is one registered-filter observation delay.
            SAMPLE_OFFSET => 83
        )
        port map (
            clk           => clk,
            reset         => reset,
            sample_ce     => sample_ce_i,
            received_rf   => rx_rf,
            i_carrier     => carrier_i,
            q_carrier     => carrier_q,
            mixed_i       => rx_mixed_i,
            mixed_q       => rx_mixed_q,
            baseband_i    => rx_i,
            baseband_q    => rx_q,
            received_bits => rx_bits,
            bits_valid    => rx_bits_valid
        );

end architecture;
