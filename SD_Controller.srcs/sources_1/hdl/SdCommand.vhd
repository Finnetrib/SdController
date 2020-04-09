----------------------------------------------------------------------------------
-- Company:
-- Engineer:	Finnetrib@gmail.com
-- 
-- Create Date: 11.02.2019 10:16:42
-- Design Name: 
-- Module Name: SdCommand - rtl
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

use WORK.SDPackage.all;

entity SdCommand is
	generic	(	gTCQ			: time := 2 ns );
	port	(	-- Command from host
				oSdInitComp		: out	std_logic;
				oSdInitFail		: out	std_logic;
				iSdAddress		: in	std_logic_vector(31 downto 0);
				iSdStartErase	: in	std_logic;
				iSdStartRead	: in	std_logic;
				iSdStartWrite	: in	std_logic;
				oSdCmdFinish	: out	std_logic_vector( 1 downto 0);
				oSdhcPresent	: out	std_logic;
				-- Data
				oSdReadData		: out	std_logic;
				iSdDataR		: in	std_logic_vector(31 downto 0);
				oSdWriteData	: out	std_logic;
				oSdDataW		: out	std_logic_vector(32 downto 0);
				-- Spi
				oSdCS			: out	std_logic;
				oSdClk			: out	std_logic;
				oSdMosi			: out	std_logic;
				oSdMosiT		: out	std_logic;
				iSdMiso			: in	std_logic;
				-- system
				pclk			: in	std_logic;
				sclk			: in	std_logic;
				rst				: in	std_logic );
end SdCommand;

architecture rtl of SdCommand is

	-- Инициализация
	type	TSM_SD_INIT		is (sWaitPwr, sDummy, sWaitDummy, sCmd0, sCmd8, sCmd55, sAcmd41Hc, sCmd58, sCmd16, sAcmd41Sc, sCmd1, sError, sComp, sResetPhy);	--! Управляющий автомат для инициализации
	signal	smSdInit		: TSM_SD_INIT;
	signal	cntrPwr			: std_logic_vector(18 downto 0);
	signal	cntrTimeOut		: std_logic_vector(16 downto 0);
	signal	Cmd55Direct		: std_logic;
	signal	cntrInitErr		: std_logic_vector( 3 downto 0);
	signal	InitCommand		: std_logic_vector(55 downto 0);
	signal	InitStart		: std_logic;
	-- Входные параметры
	signal	SdAddress		: std_logic_vector(31 downto 0);
	-- Стирание
	type	TSM_SD_ERASE	is (sIdle, sCmd32, sCmd33, sCmd38, sError, sFinish);
	signal	smSdErase		: TSM_SD_ERASE;
	signal	EraseCommand	: std_logic_vector(55 downto 0);
	signal	EraseStart		: std_logic;
	-- Чтение
	type	TSM_SD_READ		is (sIdle, sCmd18, sCheckResp, sWaitToken, sCheckToken, sRdPacket, sRdCrc, sWaitEndRd, sCmd12, sWaitCmd12, sError, sFinish);
	signal	smSdRead		: TSM_SD_READ;
	signal	ReadCommand		: std_logic_vector(55 downto 0);
	signal	ReadStart		: std_logic;
	signal	cntrRdByte		: std_logic_vector( 1 downto 0);
	signal	cntrRdDword		: std_logic_vector( 6 downto 0);
	signal	cntrRdBlock		: std_logic_vector( 5 downto 0);
	signal	cntrRdErr		: std_logic_vector( 3 downto 0);
	signal	SdDataW			: std_logic_vector(31 downto 0);
	signal	SdDataWLast		: std_logic;
	-- Запись
	type	TSM_SD_WRITE	is (sIdle, sCmd25, sWrToken, sWrPacket, sWrCrc, sWaitBusy, sCheck, sStop, sError, sFinish);	
	signal	smSdWrite		: TSM_SD_WRITE;
	signal	WriteCommand	: std_logic_vector(55 downto 0);
	signal	WriteStart		: std_logic;
	signal	PrepTxDataW		: std_logic_vector(31 downto 0);
	signal	PrepTxWrite		: std_logic;
	signal	PrepTxDataR		: std_logic_vector( 7 downto 0);
	signal	PrepTxRead		: std_logic;
	signal	PrepTxEmpty		: std_logic;
	signal	PrepTxFull		: std_logic;
	signal	cntrWrPackByte	: std_logic_vector( 1 downto 0);
	signal	cntrWrPackDw	: std_logic_vector( 6 downto 0);
	signal	cntrWrCrc		: std_logic_vector( 0 downto 0);
	signal	cntrWrBlock		: std_logic_vector( 5 downto 0);
	signal	cntrWrErr		: std_logic_vector( 3 downto 0);
	-- Формирование признаков для выполнения команды
	signal	StartCommand	: std_logic;
	signal	DummyCmd		: std_logic;
	signal	UseInitCmd		: std_logic;
	signal	UseEraseCmd		: std_logic;
	signal	UseWriteCmd		: std_logic;
	signal	UseReadCmd		: std_logic;
	signal	ByteWrCmd		: std_logic;
	signal	DataWrCmd		: std_logic;
	signal	CountShiftCmd	: std_logic_vector( 2 downto 0);
	signal	BusyCmd			: std_logic;
	signal	TokenRdCmd		: std_logic;
	type	TSM_SD_COMMAND	is (sIdle, sCheck, sDummy, sCommand, sRxData, sRxBusy, sTxData, sRxDataR, sWaitEnd, sFinish, sToken);
	signal	smSdCommand		: TSM_SD_COMMAND;
	signal	cntrShiftCmd	: std_logic_vector( 2 downto 0);
	signal	cntrToken		: std_logic_vector( 5 downto 0);
	signal	CmdComplete		: std_logic;
	signal	CmdCompleteD	: std_logic;
	signal	PerformCommand	: std_logic_vector(55 downto 0);
	signal	ResponseSize	: std_logic_vector( 9 downto 0);
	signal	PhyTxData		: std_logic_vector( 9 downto 0);
	signal	PhyMode			: std_logic_vector( 4 downto 0);
	signal	RxData			: std_logic;
	signal	PhyTxWrite		: std_logic;
	signal	PhyTxReady		: std_logic;
	signal	PhyRxData		: std_logic_vector( 7 downto 0);
	signal	PhyRxWrite		: std_logic;
	signal	PhyCmdEnd		: std_logic;
	signal	PhyReset		: std_logic;
	signal	Response		: std_logic_vector(39 downto 0);
	
	constant	cBLOCK_COUNT	: integer := 8;
	
	function bool_to_logic( iBool : boolean ) return std_logic is
	begin
		
		if iBool then
			return '1';
		end if;
		
		return '0';
		
	end bool_to_logic;

begin

	----------------------------------------------------------------------------
	-- Инициализация
	----------------------------------------------------------------------------
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				smSdInit <= sWaitPwr after gTCQ;
			else
				case (smSdInit) is
					when sWaitPwr	=>	if (cntrPwr(cntrPwr'high) = '1'									) then	smSdInit <= sDummy		after gTCQ; end if;
					when sDummy		=>	if (CmdComplete = '1'											) then	smSdInit <= sCmd0		after gTCQ; end if;
					when sCmd0		=>	if (cntrTimeOut(cntrTimeOut'high) = '1'							) then	smSdInit <= sResetPhy	after gTCQ; 
										elsif (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(2) = '1'										) then	smSdInit <= sError		after gTCQ;
											elsif (Response(7 downto 0) = x"01"							) then	smSdInit <= sCmd8		after gTCQ;
											else																smSdInit <= sCmd0		after gTCQ; end if;
										end if;
					when sCmd8		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(34) = '1' or Response(11 downto 0) = x"1AA"	) then	smSdInit <= sCmd55	after gTCQ;
											else																smSdInit <= sError	after gTCQ; end if;
										end if;
					when sCmd55		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(7 downto 0) /= x"01"							) then	smSdInit <= sCmd55		after gTCQ;
											elsif (Cmd55Direct = '1'									) then	smSdInit <= sAcmd41Sc	after gTCQ;
											else																smSdInit <= sAcmd41Hc	after gTCQ; end if;
										end if;
					when sAcmd41Hc	=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(2) = '1'										) then	smSdInit <= sError		after gTCQ;
											elsif (Response(7 downto 0) = x"00"							) then	smSdInit <= sCmd58		after gTCQ;
											else																smSdInit <= sCmd55		after gTCQ; end if;
										end if;
					when sCmd58		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(30) = '1'										) then	smSdInit <= sComp		after gTCQ;
											else																smSdInit <= sCmd16		after gTCQ; end if;
										end if;
					when sCmd16		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(7 downto 0) = x"00"							) then	smSdInit <= sComp		after gTCQ;
											else																smSdInit <= sError		after gTCQ; end if;
										end if;
					when sAcmd41Sc	=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(2) = '1'										) then	smSdInit <= sCmd1		after gTCQ;
											elsif (Response(7 downto 0) = x"00"							) then	smSdInit <= sCmd16		after gTCQ;
											else																smSdInit <= sCmd55	after gTCQ; end if;
										end if;
					when sCmd1		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then
											if (Response(2) = '1'										) then	smSdInit <= sError		after gTCQ;
											elsif (Response(7 downto 0) = x"00"							) then	smSdInit <= sCmd16		after gTCQ;
											else																smSdInit <= sCmd1		after gTCQ; end if;
										end if;
					when sResetPhy	=>	if (cntrInitErr(cntrInitErr'high) = '1'							) then	smSdInit <= sCmd0		after gTCQ; end if;
					when sError		=>																			smSdInit <= sError		after gTCQ;
					when sComp		=>																			smSdInit <= sComp		after gTCQ;
					when others		=>
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				cntrPwr <= (others => '0') after gTCQ;
			else
				if (smSdInit = sWaitPwr) then
					cntrPwr <= cntrPwr + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdInit /= sCmd0 or CmdComplete = '1') then
				cntrTimeOut <= (others => '0') after gTCQ;
			else
				cntrTimeOut <= cntrTimeOut + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdInit = sCmd8 and CmdComplete = '1' and CmdCompleteD = '0') then
				if (Response(34) = '1') then
					Cmd55Direct <= '1' after gTCQ;
				else
					Cmd55Direct <= '0' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdInit /= sResetPhy) then
				cntrInitErr <= (others => '0') after gTCQ;
			else
				cntrInitErr <= cntrInitErr + 1 after gTCQ;
			end if;
		end if;
	end process;

	process (pclk) begin
		if (rising_edge(pclk)) then
			case (smSdInit) is
				when sCmd0		=>	InitCommand	<= cCMD0		after gTCQ;
				when sCmd8		=>	InitCommand	<= cCMD8		after gTCQ;
				when sCmd55		=>	InitCommand	<= cCMD55		after gTCQ;
				when sAcmd41Hc	=>	InitCommand	<= cACMD41_SDHC	after gTCQ;
				when sAcmd41Sc	=>	InitCommand	<= cACMD41_SDSC	after gTCQ;
				when sCmd58		=>	InitCommand	<= cCMD58		after gTCQ;
				when sCmd16		=>	InitCommand	<= cCMD16		after gTCQ;
				when others		=>	InitCommand	<= cCMD1		after gTCQ;
			end case;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				InitStart <= '0' after gTCQ;
			else
				InitStart <= bool_to_logic((smSdInit = sDummy or smSdInit = sCmd0 or smSdInit = sCmd8 or smSdInit = sCmd55 or smSdInit = sAcmd41Hc or  
											smSdInit = sAcmd41Sc or smSdInit = sCmd58 or smSdInit = sCmd16 or smSdInit = sCmd1) and CmdComplete = '0') after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oSdInitComp <= '0' after gTCQ;
			else
				if (smSdInit = sComp) then
					oSdInitComp <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oSdInitFail <= '0' after gTCQ;
			else
				if (smSdInit = sError) then
					oSdInitFail <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Входные параметры
	----------------------------------------------------------------------------
	process (pclk) begin
		if (rising_edge(pclk)) then
			SdAddress <= iSdAddress after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			oSdCmdFinish(0) <= bool_to_logic(smSdErase = sFinish or smSdWrite = sFinish or smSdRead = sFinish) after gTCQ;
			oSdCmdFinish(1) <= bool_to_logic(smSdErase = sError or smSdWrite = sError or smSdRead = sError) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oSdhcPresent <= '0' after gTCQ;
			else
				if (smSdInit = sCmd58 and CmdComplete = '1' and CmdCompleteD = '0' and Response(30) = '1') then
					oSdhcPresent <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Стирание
	----------------------------------------------------------------------------
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				smSdErase <= sIdle after gTCQ;
			else
				case (smSdErase) is
					when sIdle		=>	if (iSdStartErase = '1'							) then	smSdErase <= sCmd32		after gTCQ; end if;
					when sCmd32		=>	if (CmdComplete = '1' and CmdCompleteD = '0'	) then
											if (Response(7 downto 0) = x"00"			) then	smSdErase <= sCmd33		after gTCQ;
											else												smSdErase <= sError		after gTCQ; end if;
										end if;
					when sCmd33		=>	if (CmdComplete = '1' and CmdCompleteD = '0'	) then	
											if (Response(7 downto 0) = x"00"			) then	smSdErase <= sCmd38		after gTCQ;
											else												smSdErase <= sError		after gTCQ; end if;
										end if;
					when sCmd38		=>	if (CmdComplete = '1' and CmdCompleteD = '0'	) then
											if (Response(7 downto 0) = x"00"			) then	smSdErase <= sFinish	after gTCQ;
											else												smSdErase <= sError		after gTCQ; end if;
										end if;
					when sFinish	=>															smSdErase <= sIdle		after gTCQ;
					when sError		=>															smSdErase <= sFinish	after gTCQ;
					when others		=>
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			case (smSdErase) is
				when sCmd32	=>	EraseCommand(47 downto 40) <= cCMD32	after gTCQ;
				when sCmd33	=>	EraseCommand(47 downto 40) <= cCMD33	after gTCQ;
				when others	=>	EraseCommand(47 downto 40) <= cCMD38	after gTCQ;
			end case;			
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			case (smSdErase) is
				when sCmd32	=>	EraseCommand(39 downto 8) <= SdAddress						after gTCQ;
				when sCmd33	=>	EraseCommand(39 downto 8) <= (SdAddress + cBLOCK_COUNT - 1)	after gTCQ;
				when others	=>	EraseCommand(39 downto 8) <= x"DEAF_BEEF"					after gTCQ;
			end case;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			EraseCommand( 7 downto  0) <= x"FF" after gTCQ;
			EraseCommand(55 downto 48) <= x"FF" after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			EraseStart <= bool_to_logic((smSdErase = sCmd32 or smSdErase = sCmd33 or smSdErase = sCmd38) and CmdComplete = '0') after gTCQ; 
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Чтение
	----------------------------------------------------------------------------
	-- При отправке sCmd12 карта прекращает чтение, даже в середине транзации. Нужно посмотреть
	-- на нескольких картах, как это будет выглядеть.  
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				smSdRead <= sIdle after gTCQ;
			else
				case (smSdRead) is
					when sIdle			=>	if (iSdStartRead = '1'											) then	smSdRead <= sCmd18		after gTCQ; end if;
					when sCmd18			=>	if (PhyRxWrite = '1'											) then	smSdRead <= sCheckResp	after gTCQ; end if;
					when sCheckResp		=>	if (Response(7 downto 0) = x"00"								) then	smSdRead <= sWaitToken	after gTCQ; 
											else																	smSdRead <= sError		after gTCQ; end if;
					when sWaitToken		=>	if (PhyRxWrite = '1'											) then	smSdRead <= sCheckToken	after gTCQ; end if;
					when sCheckToken	=>	if (Response(7 downto 5) = b"000"								) then	smSdRead <= sError		after gTCQ;
											else																	smSdRead <= sRdPacket	after gTCQ; end if;
 					when sRdPacket		=>	if (cntrRdDword = 127 and PhyRxWrite = '1' and cntrRdByte = 3	) then	smSdRead <= sRdCrc		after gTCQ; end if;
					when sRdCrc			=>	if (PhyRxWrite = '1' and cntrRdByte = 1							) then
												if (cntrRdBlock = cBLOCK_COUNT - 1							) then	smSdRead <= sWaitEndRd	after gTCQ;
												else																smSdRead <= sWaitToken	after gTCQ; end if;
											end if;
 					when sWaitEndRd		=>	if (CmdComplete = '1' and CmdCompleteD = '0'					) then	smSdRead <= sCmd12		after gTCQ; end if;
 					when sCmd12			=>	if (PhyRxWrite = '1'											) then	smSdRead <= sWaitCmd12	after gTCQ; end if;
 					when sWaitCmd12		=>	if (CmdComplete = '1'											) then	smSdRead <= sFinish		after gTCQ; end if;
 					when sError			=>	if (cntrRdErr(cntrRdErr'high) = '1'								) then	smSdRead <= sIdle		after gTCQ; end if;
 					when sFinish		=>																			smSdRead <= sIdle		after gTCQ;
 					when others			=>
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdRead = sCmd18) then
				ReadCommand(55 downto 40) <= x"FF" & cCMD18 after gTCQ;
			else
				ReadCommand(55 downto 40) <= x"FF" & cCMD12 after gTCQ;
			end if;
			ReadCommand(39 downto 0) <= SdAddress & x"FF" after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			ReadStart <= bool_to_logic((smSdRead = sCmd18 or smSdRead = sCmd12 ) and CmdComplete = '0') after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdRead /= sRdPacket and smSdRead /= sRdCrc) then
				cntrRdByte <= (others => '0') after gTCQ;
			elsif (PhyRxWrite = '1') then
				cntrRdByte <= cntrRdByte + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdRead /= sRdPacket) then
				cntrRdDword <= (others => '0') after gTCQ;
			elsif (PhyRxWrite = '1' and cntrRdByte = 3) then
				cntrRdDword <= cntrRdDword + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdRead = sIdle) then
				cntrRdBlock <= (others => '0') after gTCQ;
			elsif (smSdRead = sRdCrc and PhyRxWrite = '1' and cntrRdByte = 1) then
				cntrRdBlock <= cntrRdBlock + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdRead /= sError) then
				cntrRdErr <= (others => '0') after gTCQ;
			else
				cntrRdErr <= cntrRdErr + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdDataW <= (others => '0') after gTCQ;
			else
				if (PhyRxWrite = '1') then
					SdDataW <= PhyRxData & SdDataW(31 downto 8) after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			SdDataWLast <= bool_to_logic(smSdRead = sRdPacket and cntrRdDword = 127 and PhyRxWrite = '1' and 
											cntrRdByte = 3 and cntrRdBlock = cBLOCK_COUNT - 1) after gTCQ;
		end if;
	end process;
	
	oSdDataW(31 downto 0) <= SdDataW;
	oSdDataW(32) <= SdDataWLast;

	process (pclk) begin
		if (rising_edge(pclk)) then
			oSdWriteData <= bool_to_logic(smSdRead = sRdPacket and PhyRxWrite = '1' and cntrRdByte = 3) after gTCQ;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Запись
	----------------------------------------------------------------------------	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				smSdWrite <= sIdle after gTCQ;
			else
				case (smSdWrite) is
					when sIdle		=>	if (iSdStartWrite = '1'												) then	smSdWrite <= sCmd25		after gTCQ; end if;
					when sCmd25		=>	if (CmdComplete = '1'												) then
											if (Response(7 downto 0) = x"00"								) then	smSdWrite <= sWrToken	after gTCQ;
											else																	smSdWrite <= sError		after gTCQ; end if;
										end if;
					when sWrToken	=>	if (PrepTxFull = '0'												) then	smSdWrite <= sWrPacket	after gTCQ; end if;
					when sWrPacket	=>	if (PrepTxFull = '0' and cntrWrPackDw = 127 and cntrWrPackByte = 3	) then	smSdWrite <= sWrCrc		after gTCQ; end if;
					when sWrCrc		=>	if (PrepTxFull = '0' and cntrWrCrc = 1								) then	smSdWrite <= sWaitBusy	after gTCQ; end if;
					when sWaitBusy	=>	if (CmdComplete = '1'												) then
											if (Response(3 downto 0) = x"5"									) then	smSdWrite <= sCheck		after gTCQ;
											else																	smSdWrite <= sError		after gTCQ; end if;
										end if;
					when sCheck		=>	if (cntrWrBlock = cBLOCK_COUNT - 1									) then	smSdWrite <= sStop		after gTCQ;
										else																		smSdWrite <= sWrToken	after gTCQ; end if;
					when sStop		=>	if (CmdComplete = '1'												) then	smSdWrite <= sFinish	after gTCQ; end if;
					when sError		=>	if (cntrWrErr(cntrWrErr'high) = '1'									) then	smSdWrite <= sIdle		after gTCQ; end if;
					when sFinish	=>																				smSdWrite <= sIdle		after gTCQ;
					when others		=>
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite = sCmd25) then
				WriteCommand(55 downto 40) <= x"FF" & cCMD25 after gTCQ;
			else
				WriteCommand(55 downto 40) <= x"FF" & cSTOP_TOKEN after gTCQ;
			end if;
			WriteCommand(39 downto 0) <= SdAddress & x"FF" after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			WriteStart <= bool_to_logic((smSdWrite = sCmd25 or smSdWrite = sWrPacket or smSdWrite = sWrCrc or smSdWrite = sStop) and CmdComplete = '0') after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			oSdReadData <= bool_to_logic(smSdWrite = sWrPacket and PrepTxFull = '0' and cntrWrPackByte = 2) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (PrepTxFull = '0') then
				if (smSdWrite = sWrToken) then
					PrepTxDataW(7 downto 0) <= cDATA_TOKEN after gTCQ;
				elsif (smSdWrite = sWrCrc and cntrWrCrc = 0) then
					PrepTxDataW(15 downto 0) <= x"FFFF" after gTCQ;
				elsif (smSdWrite = sWrPacket and cntrWrPackByte = 0) then
					PrepTxDataW <= iSdDataR after gTCQ;
				else
					PrepTxDataW <= x"00" & PrepTxDataW(31 downto 8) after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				PrepTxWrite <= '0' after gTCQ;
			else
				PrepTxWrite <= bool_to_logic(PrepTxFull = '0' and (smSdWrite = sWrToken or smSdWrite = sWrCrc or smSdWrite = sWrPacket)) after gTCQ;
			end if;
		end if;
	end process;
	
	PrepTxFifo : entity WORK.SyncFifoLut8x16
	port map	(	clk			=> pclk,
					srst		=> rst,
					din			=> PrepTxDataW(7 downto 0),
					wr_en		=> PrepTxWrite,
					rd_en		=> PrepTxRead,
					dout		=> PrepTxDataR,
					full		=> open,
					empty		=> PrepTxEmpty,
					prog_full	=> PrepTxFull );
					
	PrepTxRead <= bool_to_logic(smSdCommand = sTxData and PhyTxReady = '1') after gTCQ;

	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite /= sWrPacket) then
				cntrWrPackByte <= (others => '0') after gTCQ;
			elsif (PrepTxFull = '0') then
				cntrWrPackByte <= cntrWrPackByte + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite /= sWrPacket) then
				cntrWrPackDw <= (others => '0') after gTCQ;
			elsif (PrepTxFull = '0' and cntrWrPackByte = 3) then
				cntrWrPackDw <= cntrWrPackDw + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite /= sWrCrc) then
				cntrWrCrc <= (others => '0') after gTCQ;
			elsif (PrepTxFull = '0') then
				cntrWrCrc <= cntrWrCrc + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite = sIdle) then
				cntrWrBlock <= (others => '0') after gTCQ;
			elsif (smSdWrite = sCheck) then
				cntrWrBlock <= cntrWrBlock + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite /= sError) then
				cntrWrErr <= (others => '0') after gTCQ;
			else
				cntrWrErr <= cntrWrErr + 1 after gTCQ;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Формирование признаков для выполнения команды
	----------------------------------------------------------------------------
	process (pclk) begin
		if (rising_edge(pclk)) then
			StartCommand <= InitStart or EraseStart or WriteStart or ReadStart;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			DummyCmd <= bool_to_logic(smSdInit = sDummy) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			UseInitCmd <= bool_to_logic(smSdInit = sDummy or smSdInit = sCmd0 or smSdInit = sCmd55 or smSdInit = sCmd8 or smSdInit = sAcmd41Hc or
										smSdInit = sCmd58 or smSdInit = sCmd16 or smSdInit = sAcmd41Sc or smSdInit = sCmd1 ) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			UseEraseCmd <= bool_to_logic(smSdErase = sCmd32 or smSdErase = sCmd33 or smSdErase = sCmd38) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			UseWriteCmd <= bool_to_logic(smSdWrite = sCmd25 or smSdWrite = sStop) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			UseReadCmd <= bool_to_logic(smSdRead = sCmd18 or smSdRead = sCmd12) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			ByteWrCmd <= UseInitCmd or UseEraseCmd or UseWriteCmd or UseReadCmd after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			DataWrCmd <= bool_to_logic(smSdWrite = sWrPacket or smSdWrite = sWrCrc) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdWrite = sStop) then
				CountShiftCmd <= conv_std_logic_vector(1, CountShiftCmd'high + 1) after gTCQ;
			else
				CountShiftCmd <= conv_std_logic_vector(6, CountShiftCmd'high + 1) after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			BusyCmd <= bool_to_logic(smSdWrite = sWaitBusy or smSdErase = sCmd38 or smSdRead = sCmd12 or smSdWrite = sStop) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			TokenRdCmd <= bool_to_logic(smSdRead = sCmd18) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (PhyReset = '1') then
				smSdCommand <= sIdle after gTCQ;
			else
				case (smSdCommand) is
					when sIdle		=>	if (StartCommand = '1'									) then	smSdCommand <= sCheck	after gTCQ; end if;
					when sCheck		=>	if (DummyCmd = '1'										) then	smSdCommand <= sDummy	after gTCQ;
										elsif (ByteWrCmd = '1'									) then	smSdCommand <= sCommand	after gTCQ; 
										elsif (DataWrCmd = '1'									) then	smSdCommand <= sTxData	after gTCQ; end if;
					when sDummy		=>	if (PhyTxReady = '1'									) then	smSdCommand <= sWaitEnd	after gTCQ; end if;
					when sCommand	=>	if (cntrShiftCmd = CountShiftCmd						) then	smSdCommand <= sRxData	after gTCQ; end if;
					when sRxData	=>	if (BusyCmd = '1'										) then	smSdCommand <= sRxBusy	after gTCQ;
										elsif (TokenRdCmd = '1'									) then	smSdCommand <= sToken	after gTCQ;
										elsif (PhyCmdEnd = '1'									) then	smSdCommand <= sFinish	after gTCQ; end if;
					when sRxBusy	=>	if (PhyTxReady = '1'									) then	smSdCommand <= sWaitEnd	after gTCQ; end if;
					when sTxData	=>	if (PrepTxEmpty = '1'									) then	smSdCommand <= sRxDataR	after gTCQ; end if;
					when sToken		=>	if (cntrToken = cBLOCK_COUNT - 1 and PhyTxReady = '1'	) then	smSdCommand <= sWaitEnd	after gTCQ; end if;
					when sRxDataR	=>	if (PhyTxReady = '1'									) then	smSdCommand <= sRxBusy	after gTCQ; end if;
					when sWaitEnd	=>	if (PhyCmdEnd = '1'										) then	smSdCommand <= sFinish	after gTCQ; end if;
					when sFinish	=>	if (StartCommand = '0'									) then	smSdCommand <= sIdle	after gTCQ; end if;
					when others		=>																	smSdCommand <= sIdle	after gTCQ;
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdCommand = sIdle) then
				cntrShiftCmd <= (others => '0') after gTCQ;
			elsif (smSdCommand = sCommand and PhyTxReady = '1') then
				cntrShiftCmd <= cntrShiftCmd + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdCommand = sIdle) then
				cntrToken <= (others => '0') after gTCQ;
			elsif (smSdCommand = sToken and PhyTxReady = '1') then
				cntrToken <= cntrToken + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			CmdComplete <= bool_to_logic(smSdCommand = sFinish) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			CmdCompleteD <= CmdComplete after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdCommand = sCommand and PhyTxReady = '1') then
				PerformCommand <= PerformCommand(47 downto 0) & x"00" after gTCQ;
			elsif (smSdInit /= sComp) then
				PerformCommand <= InitCommand after gTCQ;
			elsif (smSdErase /= sIdle) then
				PerformCommand <= EraseCommand after gTCQ;
			elsif (smSdRead /= sIdle) then
				PerformCommand <= ReadCommand after gTCQ;
			elsif (smSdWrite /= sIdle) then
				PerformCommand <= WriteCommand after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdInit = sCmd8) then
				ResponseSize <= conv_std_logic_vector(cRESP7_SIZE - 1, ResponseSize'high + 1) after gTCQ;
			elsif (smSdInit = sCmd58) then
				ResponseSize <= conv_std_logic_vector(cRESP3_SIZE - 1, ResponseSize'high + 1) after gTCQ;
			else
				ResponseSize <= conv_std_logic_vector(cRESP1_SIZE - 1, ResponseSize'high + 1) after gTCQ;
			end if;
		end if;
	end process; 
	
	-- При чтении размер передавамых данных складывается из размер блока 512 байт и размера CRC 2 байта.
	-- Вычитание единицы, т.к. осчет ведется до нуля
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdCommand = sCommand) then
				PhyTxData <= b"00" & PerformCommand(55 downto 48) after gTCQ;
			elsif (smSdCommand = sDummy) then
				PhyTxData <= (others => '0') after gTCQ;
			elsif (smSdCommand = sRxData) then
				PhyTxData <= ResponseSize after gTCQ;
			elsif (smSdCommand = sTxData) then
				PhyTxData <= b"00" & PrepTxDataR after gTCQ;
			elsif (smSdCommand = sToken) then
				PhyTxData <= conv_std_logic_vector(513, PhyTxData'high + 1) after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			case (smSdCommand) is
				when sDummy				=>	PhyMode(2 downto 0)	<= cMODE_DUMMY	after gTCQ;
				when sCommand | sTxData	=>	PhyMode(2 downto 0) <= cMODE_TX		after gTCQ;
				when sRxData			=>	PhyMode(2 downto 0) <= cMODE_RX		after gTCQ;
				when sRxBusy			=>	PhyMode(2 downto 0) <= cMODE_BUSY	after gTCQ; 
				when sRxDataR			=>	PhyMode(2 downto 0) <= cMODE_RESP	after gTCQ;
				when sToken				=>	PhyMode(2 downto 0) <= cMODE_TOKEN	after gTCQ;
				when others				=>	PhyMode(2 downto 0) <= (others => '0')	after gTCQ;
			end case;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdInit = sComp) then
				PhyMode(3) <= cFAST_MODE after gTCQ;
			else
				PhyMode(3) <= cLOW_MODE after gTCQ;
			end if;
		end if;
	end process;
	
	-- При выполнении команд чтения/записи сигнал CS должен быть перевден в состояние единицы
	-- только после завершения всей транзакции.
	process (pclk) begin
		if (rising_edge(pclk)) then
			PhyMode(4) <= bool_to_logic((smSdCommand = sRxData and UseWriteCmd = '0') or (smSdCommand = sRxBusy and smSdWrite /= sWaitBusy) or 
											(smSdCommand = sToken and UseReadCmd = '0')) after gTCQ;
		end if;
	end process;
		
	process (pclk) begin
		if (rising_edge(pclk)) then
			RxData <= bool_to_logic(smSdCommand = sRxData) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				PhyTxWrite <= '0' after gTCQ;
			else
				PhyTxWrite <= bool_to_logic(PhyTxReady = '1' and (smSdCommand = sDummy  or smSdCommand = sToken or smSdCommand = sCommand or 
											(smSdCommand = sTxData and PrepTxEmpty = '0') or (smSdCommand = sRxData and RxData = '0') or 
											smSdCommand = sRxBusy or smSdCommand = sRxDataR)) after gTCQ;
			end if;
		end if;
	end process;

	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				PhyReset <= '1' after gTCQ;
			else
				PhyReset <= bool_to_logic(smSdRead = sError or smSdWrite = sError or smSdInit = sResetPhy) after gTCQ;
			end if;
		end if;
	end process;
	
	SdCardPhy : entity WORK.SDPhy(rtl)
	generic map	(	gTCQ		=> gTCQ )
	port map	(	-- Control bus
					iPhyTxData	=> PhyTxData,
					iPhyMode	=> PhyMode,
					iPhyTxWrite	=> PhyTxWrite,
					oPhyTxReady	=> PhyTxReady,
					-- Out Data
					oPhyRxData	=> PhyRxData, 
					oPhyRxWrite	=> PhyRxWrite,
					oPhyCmdEnd	=> PhyCmdEnd,
					-- Spi
					oSdCS		=> oSdCS,
					oSdClk		=> oSdClk,
					oSdMosi		=> oSdMosi,
					oSdMosiT	=> oSdMosiT,
					iSdMiso		=> iSdMiso,
					-- system
					sclk		=> sclk,
					pclk		=> pclk,
					rst			=> PhyReset );
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdCommand = sIdle and StartCommand = '1') then
				Response <= (others => '0') after gTCQ;
			elsif ((smSdCommand = sRxData or smSdCommand = sWaitEnd or smSdCommand = sToken) and PhyRxWrite = '1') then
				Response <= Response(31 downto 0) & PhyRxData after gTCQ;
			end if;
		end if;
	end process;
	
end rtl;