----------------------------------------------------------------------------------
-- Company:		Cryptosoft
-- Engineer:	Fin
-- 
-- Create Date: 14.02.2019 09:33:35
-- Design Name: 
-- Module Name: SDPackage - Behavioral
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

package SDPackage is

	--------------------------------------------------------
	-- ќпределени€ режимов работы
	--------------------------------------------------------
	-- –ежим работы - начальное формирование частоты
	constant	cMODE_DUMMY	: std_logic_vector( 2 downto 0) := b"000";	
	-- –ежим работы - передача данных
	constant	cMODE_TX	: std_logic_vector( 2 downto 0) := b"001";	
	-- –ежим работы - чтение данных
	constant	cMODE_RX	: std_logic_vector( 2 downto 0) := b"010";	
	-- –ежим работы - ожидание завершени€ команды
	constant	cMODE_BUSY	: std_logic_vector( 2 downto 0) := b"011";	
	-- –ежим работы - чтение ответа при записи данных
	constant	cMODE_RESP	: std_logic_vector( 2 downto 0) := b"100";	
	-- –ежим работы - ожидание токена при чтении данных
	constant	cMODE_TOKEN	: std_logic_vector( 2 downto 0) := b"101";	
	
	--------------------------------------------------------
	-- ќпределени€ дл€ формировани€ частоты
	--------------------------------------------------------
	-- ѕараметр, указывающий, что используетс€ частота дл€ инициализации
	constant	cLOW_MODE	: std_logic := '1';		
	-- ѕараметр, указывающий, что используетс€ частота дл€ работы
	constant	cFAST_MODE	: std_logic := '0';

	--------------------------------------------------------
	--  оманды дл€ SD карты
	--------------------------------------------------------
	constant	cCMD0			: std_logic_vector(55 downto 0) := x"FF400000000095";
	constant	cCMD8			: std_logic_vector(55 downto 0) := x"FF48000001aa87";
	constant	cACMD41_SDHC	: std_logic_vector(55 downto 0) := x"FF6940000000FF";
	constant	cACMD41_SDSC	: std_logic_vector(55 downto 0) := x"FF6900000000FF";
	constant	cCMD58			: std_logic_vector(55 downto 0) := x"FF7A00000000FF";
	constant	cCMD55			: std_logic_vector(55 downto 0) := x"FF7700000000FF";
	constant	cCMD16			: std_logic_vector(55 downto 0) := x"FF5000000200FF";
	constant	cCMD1			: std_logic_vector(55 downto 0) := x"FF4100000000FF";
	constant	cCMD12			: std_logic_vector( 7 downto 0) := x"4C";
	constant	cCMD17			: std_logic_vector( 7 downto 0) := x"51";
	constant	cCMD18			: std_logic_vector( 7 downto 0) := x"52";
	constant	cCMD24			: std_logic_vector( 7 downto 0) := x"58";
	constant	cCMD25			: std_logic_vector( 7 downto 0) := x"59";
	constant	cCMD32			: std_logic_vector( 7 downto 0) := x"60";
	constant	cCMD33			: std_logic_vector( 7 downto 0) := x"61";
	constant	cCMD38			: std_logic_vector( 7 downto 0) := x"66";
	
	--------------------------------------------------------
	-- –азмеры ответов на команды
	--------------------------------------------------------
	constant	cRESP1_SIZE		: integer := 1;
	constant	cRESP3_SIZE		: integer := 5;
	constant	cRESP7_SIZE		: integer := 5;
	
	-- “окен дл€ данных
--	constant	cDATA_TOKEN		: std_logic_vector( 7 downto 0) := x"FE";
	constant	cDATA_TOKEN		: std_logic_vector( 7 downto 0) := x"FC";
	constant	cSTOP_TOKEN		: std_logic_vector( 7 downto 0) := x"FD";


	
	constant	cBLOCK_SIZE			: integer := 512;

end SDPackage;

package body SDPackage is

end SDPackage;
