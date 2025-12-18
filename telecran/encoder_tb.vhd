library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_tb is
end entity encoder_tb;

architecture tb of encoder_tb is

    -- Déclaration du composant à tester
    component encoder is
        port (
            i_clk       : in std_logic;
            i_rst_n     : in std_logic;
            i_a         : in std_logic; -- Canal A de l'encodeur
            i_b         : in std_logic; -- Canal B de l'encodeur
            o_increment : out std_logic; -- Pulse actif haut pour incrémenter
            o_decrement : out std_logic  -- Pulse actif haut pour décrémenter
        );
    end component;

    -- Signaux pour le testbench
    signal tb_clk       : std_logic := '0';
    signal tb_rst_n     : std_logic := '0';
    signal tb_a         : std_logic := '0';
    signal tb_b         : std_logic := '0';
    signal tb_increment : std_logic;
    signal tb_decrement : std_logic;

    -- Constantes d'horloge
    constant CLK_PERIOD : time := 10 ns; -- 27 MHz approx (1/27MHz = 37.03ns, prenons 10ns pour une simulation plus rapide, l'important est le nombre de cycles)
    constant DEBOUNCE_TIME : time := 2 ms; -- Doit être supérieur à 1ms de la logique (27000 cycles)

begin

    -- Instanciation du DUT (Device Under Test)
    dut : encoder
        port map (
            i_clk       => tb_clk,
            i_rst_n     => tb_rst_n,
            i_a         => tb_a,
            i_b         => tb_b,
            o_increment => tb_increment,
            o_decrement => tb_decrement
        );

    -- Génération du signal d'horloge
    clk_process : process
    begin
        loop
            tb_clk <= '0';
            wait for CLK_PERIOD / 2;
            tb_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clk_process;

    -- Génération du signal de reset
    reset_process : process
    begin
        tb_rst_n <= '0';
        wait for CLK_PERIOD * 5; -- Reset actif pendant quelques cycles
        tb_rst_n <= '1';
        wait; -- Maintient le reset inactif par la suite
    end process reset_process;

    -- Génération des stimulus pour l'encodeur
    stimulus_process : process
    begin
        -- Attendre la fin du reset
        wait until tb_rst_n = '1';
        wait for CLK_PERIOD * 10;

        -- Test d'incrémentation (rotation droite)
        -- Séquence typique A: 00 -> 10 -> 11 -> 01 -> 00
        -- B est en retard sur A de 90 degrés
        report "Starting increment test...";
        tb_a <= '0'; tb_b <= '0'; wait for DEBOUNCE_TIME;
        tb_a <= '1'; tb_b <= '0'; wait for DEBOUNCE_TIME; -- (10)
        tb_a <= '1'; tb_b <= '1'; wait for DEBOUNCE_TIME; -- (11)
        tb_a <= '0'; tb_b <= '1'; wait for DEBOUNCE_TIME; -- (01)
        tb_a <= '0'; tb_b <= '0'; wait for DEBOUNCE_TIME; -- (00) -> devrait générer un pulse incrément
        report "Increment test complete.";
		  
		  wait for DEBOUNCE_TIME * 2; -- Pause

        -- Test de décrémentation (rotation gauche)
        -- Séquence typique A: 00 -> 01 -> 11 -> 10 -> 00
        -- B est en avance sur A de 90 degrés
        report "Starting decrement test...";
        tb_a <= '0'; tb_b <= '0'; wait for DEBOUNCE_TIME;
        tb_a <= '0'; tb_b <= '1'; wait for DEBOUNCE_TIME; -- (01)
        tb_a <= '1'; tb_b <= '1'; wait for DEBOUNCE_TIME; -- (11)
        tb_a <= '1'; tb_b <= '0'; wait for DEBOUNCE_TIME; -- (10)
        tb_a <= '0'; tb_b <= '0'; wait for DEBOUNCE_TIME; -- (00) -> devrait générer un pulse décrément
        report "Decrement test complete.";

        wait; -- Fin de la simulation
    end process stimulus_process;

end architecture tb;