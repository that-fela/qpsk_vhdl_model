library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qpsk_pkg.all;

entity cosine_generator is
    generic (
        PHASE_OFFSET : unsigned(31 downto 0) := (others => '0')
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        sample_ce   : in  std_logic;
        cosine_out  : out q15_t
    );
end entity;

architecture rtl of cosine_generator is
    signal phase_acc : unsigned(31 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                phase_acc <= (others => '0');
            elsif sample_ce = '1' then
                phase_acc <= phase_acc + CARRIER_PHASE_INC;
            end if;
        end if;
    end process;

    process(phase_acc)
        variable phase_with_offset : unsigned(31 downto 0);
        variable lut_address       : integer range 0 to 255;
    begin
        phase_with_offset := phase_acc + PHASE_OFFSET;
        lut_address := to_integer(phase_with_offset(31 downto 24));
        cosine_out <= to_signed(SINE_LUT((lut_address + 64) mod 256), 16);
    end process;

end architecture;
