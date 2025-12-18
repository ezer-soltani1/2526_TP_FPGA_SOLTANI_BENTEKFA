library ieee;
use ieee.std_logic_1164.all;

entity encoder is
    port (
        i_clk       : in std_logic;
        i_rst_n     : in std_logic;
        i_a         : in std_logic; -- Canal A de l'encodeur
        i_b         : in std_logic; -- Canal B de l'encodeur
        o_increment : out std_logic; -- Pulse actif haut pour incrémenter
        o_decrement : out std_logic  -- Pulse actif haut pour décrémenter
    );
end entity encoder;

architecture rtl of encoder is
    -- Double synchronisation
    signal s_a_sync, s_b_sync : std_logic_vector(1 downto 0); 
    
    -- États précédents synchronisés (échantillonnés)
    signal s_a_prev, s_b_prev : std_logic := '0';
    
    signal r_cnt : natural range 0 to 27000 := 0;
    signal s_tick_1ms : std_logic := '0';

begin

    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            s_a_sync <= (others => '0');
            s_b_sync <= (others => '0');
            s_a_prev <= '0';
            s_b_prev <= '0';
            o_increment <= '0';
            o_decrement <= '0';
            r_cnt <= 0;
        elsif (rising_edge(i_clk)) then
		  
            s_a_sync <= s_a_sync(0) & i_a;
            s_b_sync <= s_b_sync(0) & i_b;
            
            -- 2. Gestion du Timer 1ms
            if r_cnt < 27000 then
                r_cnt <= r_cnt + 1;
                s_tick_1ms <= '0';
            else
                r_cnt <= 0;
                s_tick_1ms <= '1'; -- Pulse actif pendant 1 cycle tous les 1ms
            end if;

            o_increment <= '0';
            o_decrement <= '0';

            if (s_tick_1ms = '1') then
				
                -- Incrémentation
                if ( (s_a_sync(1) = '1' and s_a_prev = '0' and s_b_sync(1) = '0') or 
                     (s_a_sync(1) = '0' and s_a_prev = '1' and s_b_sync(1) = '1') ) then 
                    o_increment <= '1';
                
                -- Décrémentation
                elsif ( (s_b_sync(1) = '1' and s_b_prev = '0' and s_a_sync(1) = '0') or 
                          (s_b_sync(1) = '0' and s_b_prev = '1' and s_a_sync(1) = '1') ) then 
                    o_decrement <= '1';
                end if;
					 
                s_a_prev <= s_a_sync(1);
                s_b_prev <= s_b_sync(1);
            end if;
            
        end if;
    end process;

end architecture rtl;