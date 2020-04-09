----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.02.2019 10:17:06
-- Design Name: 
-- Module Name: tb_SdHost - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tb_SdHost is
end tb_SdHost;

architecture Behavioral of tb_SdHost is

	-- input
	signal	SdCommand		: std_logic_vector( 2 downto 0) := (others => '0');
	signal	SdAddress		: std_logic_vector(31 downto 0) := (others => '0');
	signal	SdStart			: std_logic := '0';
	signal	SdTxData		: std_logic_vector(31 downto 0) := (others => '0');
	signal	SdTxValid		: std_logic := '0';
	signal	SdTxLast		: std_logic := '0';
	signal	SdRxReady		: std_logic := '0';
	signal	SdMiso			: std_logic := '1';
	signal	pclk			: std_logic := '0';
	signal	sclk			: std_logic := '0';
	signal	rst				: std_logic := '0';
	
	-- output
	signal	SdStatus		: std_logic_vector( 1 downto 0);
	signal	SdTxReady		: std_logic;
	signal	SdRxData		: std_logic_vector(31 downto 0);
	signal	SdRxValid		: std_logic;
	signal	SdRxLast		: std_logic;
	signal	SdCS			: std_logic;
	signal	SdClk			: std_logic;
	signal	SdClkT			: std_logic;
	signal	SdMosi			: std_logic;
	signal	SdMosiT			: std_logic;
--	signal	oSDClk			: std_logic;
--	signal	oSDMosi			: std_logic;
	
	-- time
	constant	pclk_period	: time :=  4 ns;
	constant	sclk_period	: time := 20 ns;
	constant	cTCQ		: time :=  1 ns; 


begin

--	OBUFT_oSDClk : OBUFT
--	generic map	(	SLEW	=> "FAST")
--	port map	(	O	=>	oSDClk,	I	=>	SdClk,	T	=>	SdClkT );
	
--	OBUFT_oSDMosi : OBUFT
--	generic map	(	SLEW	=> "SLOW")
--	port map	(	O	=>	oSDMosi,	I	=>	SdMosi,	T	=>	SdMosiT );

	tb_ut : entity WORK.SdHost(rtl)
	generic map	(	gTCQ		=> cTCQ )
	port map	(	-- Sd Host command
					iSdCommand	=> SdCommand,
					iSdAddress	=> SdAddress,
					iSdStart	=> SdStart,
					oSdStatus	=> SdStatus,
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
					oSdCS		=> SdCS,
					oSdClk		=> SdClk,
--					oSdClkT		=> SdClkT,
					oSdMosi		=> SdMosi,
					oSdMosiT	=> SdMosiT,
					iSdMiso		=> SdMiso,
					-- system
					pclk		=> pclk,
					sclk		=> sclk,
					rst			=> rst );
	
	pclk_process : process begin
		pclk <= '1';
		wait for pclk_period / 2;
		pclk <= '0';
		wait for pclk_period / 2;
	end process;
	
	sclk_process : process begin
		sclk <= '1';
		wait for sclk_period / 2;
		sclk <= '0';
		wait for sclk_period / 2;
	end process;
	
--	data_process : process begin
--		wait until rising_edge(pclk) and SdTxReady = '1';
--		wait until rising_edge(pclk) and SdTxReady = '0';
--		wait until rising_edge(pclk) and SdTxReady = '1';
--		SdTxData <= x"0123aacc" after cTCQ;
--		SdTxValid <= '1' after cTCQ;
--		wait until rising_edge(pclk);
--		SdTxValid <= '0' after cTCQ;
		
--		wait;
--	end process;
	
	stim_process : process begin
		rst <= '1';
		wait for 150 ns;
		rst <= '0';
		wait for 150 ns;
		
		----------------------------------------------------
		-- Erase
		----------------------------------------------------
		wait until rising_edge(pclk);
		SdCommand <= b"100" after cTCQ;
		SdStart <= '1' after cTCQ;
		SdAddress <= x"00000011" after cTCQ;
		wait until rising_edge(pclk) and SdStatus(0) = '1';
		SdStart <= '0' after cTCQ;
		wait until rising_edge(pclk) and SdStatus(0) = '0';
		
		----------------------------------------------------
		-- Write
		----------------------------------------------------
		for i in 0 to 254 loop
			SdTxData <= conv_std_logic_vector(i + 28644343, SdTxData'high + 1) after cTCQ;
			SdTxValid <= '1' after cTCQ;
			wait for pclk_period;
		end loop;
		SdTxData <= x"dead_baef" after cTCQ;
		SdTxLast <= '1' after cTCQ;
		wait for pclk_period;
		SdTxLast <= '0' after cTCQ;
		SdTxValid <= '0' after cTCQ;
		
		wait for pclk_period * 10;
		SdCommand <= b"010" after cTCQ;
		SdStart <= '1' after cTCQ;
		SdAddress <= x"12345eac" after cTCQ;
		

		
		wait until rising_edge(pclk) and SdStatus(0) = '1';
		SdStart <= '0' after cTCQ;
		wait until rising_edge(pclk) and SdStatus(0) = '0';
		
		----------------------------------------------------
		-- Read
		----------------------------------------------------
		SdCommand <= b"001" after cTCQ;
		SdStart <= '1' after cTCQ;
		SdAddress <= x"ae058123" after cTCQ;
		wait until rising_edge(pclk) and SdStatus(0) = '1';
		SdStart <= '0' after cTCQ;
		wait until rising_edge(pclk) and SdStatus(0) = '0';
		
		wait;
	end process;
	
	rx_process : process begin
			-- First command
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			
--			-- Cmd 0 retry
--			wait until rising_edge(SdClk) and SdCs = '1';
--			wait until rising_edge(SdClk) and SdCs = '0';
--			wait until rising_edge(SdClk) and SdMosiT = '1';
--			wait until falling_edge(SdClk);
--			wait until falling_edge(SdClk);
--			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until SdCs = '1';

			
			-- R7 (response for Cmd8)
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			 -- 39
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 38
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 37
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 36
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 35
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 34
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 33
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 32
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 31
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 30
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 29
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 28
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 27
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 26
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 25
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 24
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 23
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 22
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 21
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 20
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 19
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 18
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 17
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 16
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 15
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 14
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 13
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 12
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 11
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 10
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 9
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 8
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 7
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 6
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 5
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 4
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 3
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 2
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 1
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until SdCs = '1';
			
			-- R0 (response for CMD55)
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until SdCs = '1';
			
			-- R0 (response for Acmd41Hc)
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until SdCs = '1';
			
			-- R3 (response cmd58)
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			 -- 39
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 38
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 37
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 36
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 35
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 34
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 33
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 32
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 31
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 30
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			-- 29
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 28
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 27
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 26
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 25
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 24
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 23
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 22
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 21
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 20
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 19
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 18
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 17
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 16
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 15
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 14
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 13
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 12
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 11
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 10
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 9
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 8
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 7
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 6
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 5
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 4
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 3
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 2
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 1
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			-- 0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until SdCs = '1';
			
			
			-- Response for cmd32
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0 
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until rising_edge(SdClk) and SdCs = '1';
			
			-- Response Cmd33
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until rising_edge(SdClk) and SdCs = '1';
	
			-- Response CMD38
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until rising_edge(SdClk) and SdCs = '1'; -- end Erase
			
			--- Response CMD24
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk);
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			
			-- Data write 0
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 680 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			--wait until rising_edge(SdClk) and SdCs = '1';	-- end write	
			
			-- Data write 1
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 2
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 3
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 4
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 5
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 6
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	
			
			-- Data write 7
			wait until falling_edge(SdClk) and SdMosiT = '0';
			wait until falling_edge(SdClk) and SdMosiT = '1';
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- bit resp
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;			-- busy		
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;	

--			-- Data write 8
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 9
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 10
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 11
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 12
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 13
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 14
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	

--			-- Data write 15
--			wait until falling_edge(SdClk) and SdMosiT = '0';
--			wait until falling_edge(SdClk) and SdMosiT = '1';
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- bit resp
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;			-- busy		
--			wait for 500 ns;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;	



			-- CMD12 response
--			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '0';
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait for 500 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			
					

			--- Response CMD17
			wait until rising_edge(SdClk) and SdCs = '0';
			wait until rising_edge(SdClk) and SdMosiT = '0';
			wait until rising_edge(SdClk);
			wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;		 -- error token bit 0
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '0' after cTCQ;
--			wait until falling_edge(SdClk);
--			SdMiso <= '1' after cTCQ;
--			wait until falling_edge(SdClk);	-- error token bit 7
			
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		
			
			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte																	
				
				
			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- next packet
			wait for 180 us;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- Data token
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;		-- end token
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 0 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 1 byte
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 2 byte
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;				
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;	
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;			-- end 3 byte		

			-- resp cmd12
			--wait for 180 us;
			--wait until rising_edge(SdClk) and SdCs = '0';
			--wait until rising_edge(SdClk);
			wait until rising_edge(SdClk) and SdMosiT = '0';
			--wait until rising_edge(SdClk) and SdMosiT = '1';
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			-- R0
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			wait until falling_edge(SdClk);
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);									
			wait until falling_edge(SdClk);	
			wait until falling_edge(SdClk);	
			wait until falling_edge(SdClk);	
			
			wait until falling_edge(SdClk);	
			SdMiso <= '1' after cTCQ;	
			wait until falling_edge(SdClk);	
			SdMiso <= '0' after cTCQ;						
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			
			SdMiso <= '1' after cTCQ;	
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			wait until falling_edge(SdClk);
			
			SdMiso <= '0' after cTCQ;
			wait until falling_edge(SdClk);
			wait for 540 ns;
			wait until falling_edge(SdClk);
			SdMiso <= '1' after cTCQ;
			
								
			wait;
		end process;



end Behavioral;
