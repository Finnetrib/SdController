----------------------------------------------------------------------------------
-- Company:
-- Engineer:	Finnetrib@gmail.com
-- 
-- Create Date: 01.03.2019 11:14:44
-- Design Name: 
-- Module Name: SdTop - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SdTop is
	port	(	DDR_cas_n			: inout STD_LOGIC;
				DDR_cke				: inout STD_LOGIC;
				DDR_ck_n			: inout STD_LOGIC;
				DDR_ck_p			: inout STD_LOGIC;
				DDR_cs_n			: inout STD_LOGIC;
				DDR_reset_n			: inout STD_LOGIC;
				DDR_odt				: inout STD_LOGIC;
				DDR_ras_n			: inout STD_LOGIC;
				DDR_we_n			: inout STD_LOGIC;
				DDR_ba				: inout STD_LOGIC_VECTOR ( 2 downto 0 );
				DDR_addr			: inout STD_LOGIC_VECTOR ( 14 downto 0 );
				DDR_dm				: inout STD_LOGIC_VECTOR ( 3 downto 0 );
				DDR_dq				: inout STD_LOGIC_VECTOR ( 31 downto 0 );
				DDR_dqs_n			: inout STD_LOGIC_VECTOR ( 3 downto 0 );
				DDR_dqs_p			: inout STD_LOGIC_VECTOR ( 3 downto 0 );
				FIXED_IO_mio		: inout STD_LOGIC_VECTOR ( 53 downto 0 );
				FIXED_IO_ddr_vrn	: inout STD_LOGIC;
				FIXED_IO_ddr_vrp	: inout STD_LOGIC;
				FIXED_IO_ps_srstb	: inout STD_LOGIC;
				FIXED_IO_ps_clk		: inout STD_LOGIC;
				FIXED_IO_ps_porb	: inout STD_LOGIC;
				-- SD
				oSDClk				: out	std_logic;
				oSDCs				: out	std_logic;
				oSDMosi				: out	std_logic;
				iSDMiso				: in	std_logic );
end SdTop;

architecture Behavioral of SdTop is

	signal	clk				: std_logic;
	signal	clk50			: std_logic;
	signal	rst_n			: std_logic_vector(0 downto 0);
	signal	rst				: std_logic;
	
	-- SD
	signal	SdCS_buf		: std_logic;
	signal	SdClk_buf		: std_logic;
	signal	SdMosi_buf		: std_logic;
	signal	SdMosiT_buf		: std_logic;
	signal	SdMis_buf		: std_logic;
	
	--
	signal	SdCommand		: std_logic_vector( 2 downto 0);
	signal	SdAddress		: std_logic_vector(31 downto 0);
	signal	SdStart			: std_logic;
	signal	SdStatus		: std_logic_vector( 1 downto 0);
	signal	SdInitFail		: std_logic;
	signal	SdTxData		: std_logic_vector(31 downto 0);
	signal	SdTxValid		: std_logic;
	signal	SdTxLast		: std_logic;
	signal	SdTxReady		: std_logic;
	signal	SdRxData		: std_logic_vector(31 downto 0);
	signal	SdRxValid		: std_logic;
	signal	SdRxLast		: std_logic;
	signal	SdRxReady		: std_logic;



begin

	----------------------------------------------------------------------------
	-- Процессорный модуль
	----------------------------------------------------------------------------
	PS : entity WORK.ProcessingSystem
	port map(	DDR_cas_n			=> DDR_cas_n,
				DDR_cke				=> DDR_cke,
				DDR_ck_n			=> DDR_ck_n,
				DDR_ck_p			=> DDR_ck_p,
				DDR_cs_n			=> DDR_cs_n,
				DDR_reset_n			=> DDR_reset_n,
				DDR_odt				=> DDR_odt,
				DDR_ras_n			=> DDR_ras_n,
				DDR_we_n			=> DDR_we_n,
				DDR_ba				=> DDR_ba,
				DDR_addr			=> DDR_addr,
				DDR_dm				=> DDR_dm,
				DDR_dq				=> DDR_dq,
				DDR_dqs_n			=> DDR_dqs_n,
				DDR_dqs_p			=> DDR_dqs_p,
				FIXED_IO_mio		=> FIXED_IO_mio,
				FIXED_IO_ddr_vrn	=> FIXED_IO_ddr_vrn,
				FIXED_IO_ddr_vrp	=> FIXED_IO_ddr_vrp,
				FIXED_IO_ps_srstb	=> FIXED_IO_ps_srstb,
				FIXED_IO_ps_clk		=> FIXED_IO_ps_clk,
				FIXED_IO_ps_porb	=> FIXED_IO_ps_porb,
				-- system
				oCLK				=> clk,
				oClk50				=> clk50,
				oRst_n				=> rst_n,
				iSdInitFail			=> SdInitFail,
				iSdRxData			=> SdRxData,
				iSdRxValid			=> SdRxValid,
				iSdTxReady			=> SdTxReady,
				iSdRxLast			=> SdRxLast,
				oSdTxValid			=> SdTxValid,
				oSdTxLast			=> SdTxLast,
				oSdStart			=> SdStart,
				oSdAddress			=> SdAddress,
				oSdTxData			=> SdTxData,
				oSdCommand			=> SdCommand,
				oSdRxReady			=> SdRxReady,
				iSdStatus			=> SdStatus );
	
	rst <= not rst_n(0);
	----------------------------------------------------------------------------
	-- SD контроллер
	----------------------------------------------------------------------------
	SD : entity WORK.SdHost(rtl)
	port map	(	-- Sd Host command
					iSdCommand	=> SdCommand,
					iSdAddress	=> SdAddress,
					iSdStart	=> SdStart,
					oSdStatus	=> SdStatus,
					oSdInitFail	=> SdInitFail,
					-- Write data to card
					iSdTxData	=> SdTxData,
					iSdTxValid	=> SdTxValid,
					iSdTxLast	=> SdTxLast,
					oSdTxReady	=> SdTxReady,
					-- Read data from card
					oSdRxData	=> SdRxData,
					oSdRxValid	=> SdRxValid,
					oSdRxLast	=> SdRxLast,
					iSdRxReady	=> SdRxReady,
					-- Spi
					oSdCS		=> SdCS_buf,
					oSdClk		=> SdClk_buf,
					oSdMosi		=> SdMosi_buf,
					oSdMosiT	=> SdMosiT_buf,
					iSdMiso		=> SdMis_buf,
					-- system
					pclk		=> clk,
					sclk		=> clk50,
					rst			=> rst );
	
	----------------------------------------------------------------------------
	-- Подключение карты
	----------------------------------------------------------------------------
	OBUF_oSDClk	: OBUF
	generic map	(	SLEW	=> "FAST")
	port map	(	O	=>	oSDClk,	I	=>	SdClk_buf );
		
	OBUF_oSDCs	: OBUF
	generic map	(	SLEW	=> "SLOW")
	port map	(	O	=>	oSDCs,	I	=>	SdCS_buf );

	OBUFT_oSDMosi : OBUFT
	generic map	(	SLEW	=> "SLOW")
	port map	(	O	=>	oSDMosi,	I	=>	SdMosi_buf,	T	=>	SdMosiT_buf );
	
	IBUF_iSDMiso	: IBUF
	port map	(	O	=>	SdMis_buf,	I	=>	iSDMiso );

end Behavioral;
