library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
    generic(
    h_res : positive := 720;
    v_res : positive := 480;
    h_sync : positive := 61;
    h_fp : positive := 58;
    h_bp : positive := 18;
    v_sync : positive := 5;
    v_fp : positive := 30;
    v_bp : positive := 9
    );
    port(
        i_clk : in std_logic;
        i_rst_n : in std_logic;

        o_hdmi_hs : out std_logic;
        o_hdmi_vs : out std_logic;
        o_hdmi_de : out std_logic;

        o_pixel_en : out std_logic;
        o_pixel_address : out natural;
        o_x_counter : out natural;
        o_y_counter : out natural
    );
end hdmi_controler;

architecture rtl of hdmi_controler is    
    -- Constantes Horizontales
    constant h_start : positive := h_sync + h_fp; -- Début des pixels actifs
    constant h_end   : positive := h_start + h_res; -- Fin des pixels actifs
    constant h_total : positive := h_end + h_bp; -- Fin de la ligne

    -- Constantes Verticales
    constant v_start : positive := v_sync + v_fp; -- Début des lignes actives
    constant v_end   : positive := v_start + v_res; -- Fin des lignes actives
    constant v_total : positive := v_end + v_bp; -- Fin de la trame

    -- Registres Horizontaux
    signal r_h_count  : natural range 0 to h_total;
    signal r_h_active : std_logic;

    -- Registres Verticaux
    signal r_v_count  : natural range 0 to v_total;
    signal r_v_active : std_logic;

begin
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_h_count <= 0;
            r_v_count <= 0;
            o_hdmi_hs <= '1'; 
            o_hdmi_vs <= '1';
            r_h_active <= '0';
            r_v_active <= '0';
            o_hdmi_de <= '0';
        elsif rising_edge(i_clk) then
            
            -- Gestion Horizontale
            if r_h_count = h_total - 1 then
                r_h_count <= 0;
                
                -- Gestion Verticale (synchronisée sur la fin de ligne)
                if r_v_count = v_total - 1 then
                    r_v_count <= 0;
                else
                    r_v_count <= r_v_count + 1;
                end if;

            else
                r_h_count <= r_h_count + 1;
            end if;

            -- Génération H_SYNC (Actif bas : 0 pendant h_sync, 1 sinon)
            if r_h_count < h_sync then
                o_hdmi_hs <= '0'; 
            else
                o_hdmi_hs <= '1';
            end if;

            -- Génération H_ACTIVE
            if r_h_count = h_start then
                r_h_active <= '1';
            elsif r_h_count = h_end then
                r_h_active <= '0';
            end if;

            -- Génération V_SYNC (Actif bas : 0 pendant v_sync, 1 sinon)
            if r_v_count < v_sync then
                o_hdmi_vs <= '0';
            else
                o_hdmi_vs <= '1';
            end if;

            -- Génération V_ACTIVE
            if r_v_count = v_start then
                r_v_active <= '1';
            elsif r_v_count = v_end then
                r_v_active <= '0';
            end if;
            
            -- Génération Data Enable
            o_hdmi_de <= r_h_active and r_v_active;

        end if;
    end process;

    -- Génération des sorties Pixel
    -- o_pixel_en est actif quand on est dans la zone active
    o_pixel_en <= r_h_active and r_v_active;

    -- Coordonnées X et Y (relatives à la zone active)
    -- Si on est actif, X = h_count - h_start, Y = v_count - v_start
    -- Sinon 0
    o_x_counter <= r_h_count - h_start when (r_h_active = '1') else 0;
    o_y_counter <= r_v_count - v_start when (r_v_active = '1') else 0;

    -- Adresse linéaire du pixel : Y * Largeur + X
    o_pixel_address <= (r_v_count - v_start) * h_res + (r_h_count - h_start) when (r_h_active = '1' and r_v_active = '1') else 0;

end architecture rtl;
