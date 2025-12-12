library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tuto_fpga is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
        o_led : out std_logic_vector(9 downto 0)
    );
end entity tuto_fpga;

architecture rtl of tuto_fpga is
    signal r_led : std_logic_vector(9 downto 0) := "0000000001";
	 signal r_led_enable : std_logic := '0';
	 
begin

process(i_clk, i_rst_n)
    variable counter : natural range 0 to 5000000 := 0;
begin
    if (i_rst_n = '0') then
        counter := 0;
        r_led_enable <= '0';
    elsif (rising_edge(i_clk)) then
        if (counter = 5000000) then
            counter := 0;
            r_led_enable <= '1';
        else
            counter := counter + 1;
            r_led_enable <= '0';
        end if;
    end if;
end process;

process(i_clk, i_rst_n)
	begin
        if (i_rst_n = '0') then
            r_led <= "0000000001";
        elsif (rising_edge(i_clk)) then
				if (r_led_enable = '1') then
            r_led <= r_led(8 downto 0) & r_led(9);
				end if;
			end if;
end process;
	 
    o_led <= r_led;
end architecture rtl;