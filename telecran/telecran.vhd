library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50: in std_logic;

        -- HDMI
        io_hdmi_i2c_scl       : inout std_logic;
        io_hdmi_i2c_sda       : inout std_logic;
        o_hdmi_tx_clk        : out std_logic;
        o_hdmi_tx_d          : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de         : out std_logic;
        o_hdmi_tx_hs         : out std_logic;
        i_hdmi_tx_int        : in std_logic;
        o_hdmi_tx_vs         : out std_logic;

        -- KEYs
        i_rst_n : in std_logic;
		  
		-- LEDs
		o_leds : out std_logic_vector(9 downto 0);
		o_de10_leds : out std_logic_vector(7 downto 0);

		-- Coder
		i_left_ch_a : in std_logic;
		i_left_ch_b : in std_logic;
		i_left_pb : in std_logic;
		i_right_ch_a : in std_logic;
		i_right_ch_b : in std_logic;
		i_right_pb : in std_logic
    );
end entity telecran;

architecture rtl of telecran is
	component I2C_HDMI_Config 
		port (
			iCLK : in std_logic;
			iRST_N : in std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			HDMI_TX_INT  : in std_logic
		);
	 end component;
	 
	component pll 
		port (
			refclk : in std_logic;
			rst : in std_logic;
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;

    component encoder
        port (
            i_clk       : in std_logic;
            i_rst_n     : in std_logic;
            i_a         : in std_logic;
            i_b         : in std_logic;
            o_increment : out std_logic;
            o_decrement : out std_logic
        );
    end component;

        component hdmi_controler

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

        end component;

                    component dpram
                        generic
                        (
                            mem_size    : natural := 720 * 480;
                            data_width  : natural := 1
                        );
                       port 
                       (   
                            i_clk_a        : in std_logic;
                            i_clk_b        : in std_logic;
                
                            i_data_a    : in std_logic_vector(data_width-1 downto 0);
                            i_data_b    : in std_logic_vector(data_width-1 downto 0);
                            i_addr_a    : in natural range 0 to mem_size-1;
                            i_addr_b    : in natural range 0 to mem_size-1;
                            i_we_a      : in std_logic := '1';
                            i_we_b      : in std_logic := '1';
                            o_q_a       : out std_logic_vector(data_width-1 downto 0);
                            o_q_b       : out std_logic_vector(data_width-1 downto 0)
                       );
                    end component;
                
                    constant h_res : natural := 720;
                    constant v_res : natural := 480;
                
                	signal s_clk_27 : std_logic;
                	signal s_rst_n : std_logic;
                
                    -- Signaux HDMI Controler
                    signal s_hdmi_hs : std_logic;
                    signal s_hdmi_vs : std_logic;
                    signal s_hdmi_de : std_logic;
                    signal s_pixel_en : std_logic;
                    signal s_pixel_address : natural;
                    signal s_hdmi_x_counter : natural;
                    signal s_hdmi_y_counter : natural;
                
    -- Signaux RAM
    signal s_ram_addr_a : natural range 0 to 720*480-1;
    signal s_ram_data_a : std_logic_vector(0 downto 0); -- 1 bit
    signal s_ram_we_a   : std_logic;
    signal s_ram_q_b    : std_logic_vector(0 downto 0); -- 1 bit
    signal s_ram_data_a_in : std_logic_vector(0 downto 0); -- New signal for data mux

    -- Signaux Erase
    signal s_erase_active : std_logic := '0';
    signal s_erase_addr   : natural range 0 to 720*480-1 := 0;

    -- Signaux pour les encodeurs
    signal s_inc_x, s_dec_x : std_logic;
    signal s_inc_y, s_dec_y : std_logic;
    
    -- Compteurs de position
    signal s_x_counter : unsigned(9 downto 0) := (others => '0');
    signal s_y_counter : unsigned(9 downto 0) := (others => '0');

begin
    -- Affichage du compteur X sur les LEDs pour le test
	o_leds <= std_logic_vector(s_x_counter);
	o_de10_leds <= (others => '0');



	-- Frequency for HDMI is 27MHz generated by this PLL
	pll0 : component pll 
		port map (
			refclk => i_clk_50,
			rst => not(i_rst_n),
			outclk_0 => s_clk_27,
			locked => s_rst_n
		);

	-- Configures the ADV7513 for 480p
	I2C_HDMI_Config0 : component I2C_HDMI_Config 
		port map (
			iCLK => i_clk_50,
			iRST_N => i_rst_n,
			I2C_SCLK => io_hdmi_i2c_scl,
			I2C_SDAT => io_hdmi_i2c_sda,
			HDMI_TX_INT => i_hdmi_tx_int
	 );

        inst_hdmi_controler : component hdmi_controler
            port map (
                i_clk => s_clk_27,
                i_rst_n => s_rst_n,
                o_hdmi_hs => s_hdmi_hs,
                o_hdmi_vs => s_hdmi_vs,
                o_hdmi_de => s_hdmi_de,
                o_pixel_en => s_pixel_en,
                o_pixel_address => s_pixel_address,
                o_x_counter => s_hdmi_x_counter,
                o_y_counter => s_hdmi_y_counter
            );
    
        -- Erase Process
        process(s_clk_27, s_rst_n)
        begin
            if s_rst_n = '0' then
                s_erase_active <= '0';
                s_erase_addr <= 0;
            elsif rising_edge(s_clk_27) then
                if s_erase_active = '1' then
                    if s_erase_addr = 720*480-1 then
                        s_erase_active <= '0';
                        s_erase_addr <= 0;
                    else
                        s_erase_addr <= s_erase_addr + 1;
                    end if;
                elsif i_left_pb = '0' then -- Button Pressed (Active Low)
                    s_erase_active <= '1';
                    s_erase_addr <= 0;
                end if;
            end if;
        end process;
    
            s_ram_we_a <= '1' when s_erase_active = '1' else 
                          '1' when (to_integer(s_x_counter) < 720 and to_integer(s_y_counter) < 480) else
                          '0';
            
            s_ram_addr_a <= s_erase_addr when s_erase_active = '1' else
                            to_integer(s_y_counter) * 720 + to_integer(s_x_counter) when (to_integer(s_x_counter) < 720 and to_integer(s_y_counter) < 480) else
                            0;
                s_ram_data_a_in <= "0" when s_erase_active = '1' else "1";
    
        inst_dpram : component dpram
            port map (
                i_clk_a     => s_clk_27,
                i_clk_b     => s_clk_27,
                i_data_a    => s_ram_data_a_in,
                i_data_b    => "0",
                i_addr_a    => s_ram_addr_a,
                i_addr_b    => s_pixel_address, -- Read address from HDMI controller
                i_we_a      => s_ram_we_a,
                i_we_b      => '0',
                o_q_a       => open,
                o_q_b       => s_ram_q_b
            );
    o_hdmi_tx_de <= s_hdmi_de;
    o_hdmi_tx_hs <= s_hdmi_hs;
    o_hdmi_tx_vs <= s_hdmi_vs;
    
    o_hdmi_tx_clk <= s_clk_27;

    -- HDMI Output: Display RAM content (1 bit -> 24 bit)
    o_hdmi_tx_d <= (others => '0') when s_pixel_en = '0' else
                   x"FFFFFF"       when s_ram_q_b(0) = '1' else
                   x"000000";




    -- Instanciation de l'encodeur Gauche (Axe X)
    inst_encoder_left : component encoder
        port map (
            i_clk       => s_clk_27,
            i_rst_n     => s_rst_n,
            i_a         => i_left_ch_a,
            i_b         => i_left_ch_b,
            o_increment => s_inc_x,
            o_decrement => s_dec_x
        );

    -- Instanciation de l'encodeur Droit (Axe Y)
    inst_encoder_right : component encoder
        port map (
            i_clk       => s_clk_27,
            i_rst_n     => s_rst_n,
            i_a         => i_right_ch_a,
            i_b         => i_right_ch_b,
            o_increment => s_inc_y,
            o_decrement => s_dec_y
        );

    -- Gestion des compteurs de position
    process(s_clk_27, s_rst_n)
    begin
        if (s_rst_n = '0') then
            s_x_counter <= (others => '0');
            s_y_counter <= (others => '0');
        elsif (rising_edge(s_clk_27)) then
            -- Gestion X
            if (s_inc_x = '1') then
                s_x_counter <= s_x_counter + 1;
            elsif (s_dec_x = '1') then
                s_x_counter <= s_x_counter - 1;
            end if;

            -- Gestion Y
            if (s_inc_y = '1') then
                s_y_counter <= s_y_counter + 1;
            elsif (s_dec_y = '1') then
                s_y_counter <= s_y_counter - 1;
            end if;
        end if;
    end process;

end architecture rtl;
