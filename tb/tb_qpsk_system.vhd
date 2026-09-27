library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.qpsk_pkg.all;

entity tb_qpsk_system is
end entity;

architecture sim of tb_qpsk_system is

    constant CLK_PERIOD : time := 10 ns;

    constant TEST_BITS_LENGTH : integer := 14;
    constant TEST_BITS : std_logic_vector(TEST_BITS_LENGTH - 1 downto 0) :=
        "00101110110001";

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal tx_symbol_valid : std_logic := '0';
    signal tx_symbol_bits  : std_logic_vector(1 downto 0) := "00";

    signal sample_ce     : std_logic;
    signal tx_i          : q15_t;
    signal tx_q          : q15_t;
    signal tx_rf         : rf_t;
    signal rx_rf         : rf_t;
    signal rx_mixed_i    : bb_t;
    signal rx_mixed_q    : bb_t;
    signal rx_i          : bb_t;
    signal rx_q          : bb_t;
    signal rx_bits       : std_logic_vector(1 downto 0);
    signal rx_bits_valid : std_logic;

    signal tx_bits_debug : std_logic_vector(13 downto 0) := TEST_BITS;

    signal received_bits_all : std_logic_vector(13 downto 0) := (others => '0');
    signal received_count    : integer range 0 to 7 := 0;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.qpsk_system
        port map (
            clk             => clk,
            reset           => reset,
            tx_symbol_valid => tx_symbol_valid,
            tx_symbol_bits  => tx_symbol_bits,
            sample_ce       => sample_ce,
            tx_i             => tx_i,
            tx_q             => tx_q,
            tx_rf            => tx_rf,
            rx_rf           => rx_rf,
            rx_mixed_i      => rx_mixed_i,
            rx_mixed_q      => rx_mixed_q,
            rx_i            => rx_i,
            rx_q            => rx_q,
            rx_bits         => rx_bits,
            rx_bits_valid   => rx_bits_valid
        );

    stimulus : process
        variable pair : std_logic_vector(1 downto 0);
    begin
        reset <= '1';

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        reset <= '0';

        for symbol_index in 0 to (TEST_BITS_LENGTH / 2) - 1 loop

            pair := TEST_BITS(13 - symbol_index*2 downto
                              12 - symbol_index*2);

            wait until rising_edge(clk) and sample_ce = '1';

            tx_symbol_bits  <= pair;
            tx_symbol_valid <= '1';

            wait until rising_edge(clk) and sample_ce = '1';

            tx_symbol_valid <= '0';

            for n in 0 to SAMPLES_PER_SYMBOL - 3 loop
                wait until rising_edge(clk) and sample_ce = '1';
            end loop;
        end loop;
        wait;
    end process;

    capture : process(clk)
        variable next_count : integer;
        variable next_bits  : std_logic_vector(TEST_BITS_LENGTH - 1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                received_bits_all <= (others => '0');
                received_count <= 0;

            elsif rx_bits_valid = '1' then
                next_count := received_count;
                next_bits := received_bits_all;

                if next_count < 7 then
                    next_bits(13 - next_count*2 downto
                              12 - next_count*2) := rx_bits;

                    next_count := next_count + 1;

                    received_bits_all <= next_bits;
                    received_count <= next_count;
                end if;
            end if;
        end if;
    end process;

end architecture;
