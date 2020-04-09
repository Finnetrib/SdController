----------------------------------------------------------------------------------
-- Company:
-- Engineer:	Finnetrib@gmail.com
-- 
-- Create Date: 13.02.2019 13:56:17
-- Design Name: 
-- Module Name: SdHost - rtl
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
use IEEE.STD_lOGIC_UNSIGNED.ALL;

entity SdHost is
	generic	(	gTCQ		: time := 2 ns );
	port	(	-- Sd Host command
				iSdCommand	: in	std_logic_vector( 2 downto 0);
				iSdAddress	: in	std_logic_vector(31 downto 0);
				iSdStart	: in	std_logic;
				oSdStatus	: out	std_logic_vector( 1 downto 0);
				oSdInitFail	: out	std_logic;
				-- Write data to card
				iSdTxData	: in	std_logic_vector(31 downto 0);
				iSdTxValid	: in	std_logic;
				iSdTxLast	: in	std_logic;
				oSdTxReady	: out	std_logic;
				-- Read data from card
				oSdRxData	: out	std_logic_vector(31 downto 0);
				oSdRxValid	: out	std_logic;
				oSdRxLast	: out	std_logic;
				iSdRxReady	: in	std_logic;
				-- Spi
				oSdCS		: out	std_logic;
				oSdClk		: out	std_logic;
				oSdMosi		: out	std_logic;
				oSdMosiT	: out	std_logic;
				iSdMiso		: in	std_logic;
				-- system
				pclk		: in	std_logic;
				sclk		: in	std_logic;
				rst			: in	std_logic );
end SdHost;

architecture rtl of SdHost is

	-- Входные параметры
	signal	SdStart			: std_logic;
	signal	SdCommand		: std_logic_vector( 2 downto 0);
	signal	SdAdress		: std_logic_vector(31 downto 0);
	-- Управляющий автомат 
	type	TSM_SD_CONTROL	is (sIdle, sWaitCmd, sReadCmd, sWriteCmd, sEraseCmd, sWaitEnd, sFinish);
	signal	smSdControl		: TSM_SD_CONTROL;
	signal	WrDataReady		: std_logic;
	signal	WrDataCmd		: std_logic;
	signal	SdStartRead		: std_logic;
	signal	SdStartWrite	: std_logic;
	signal	SdStartErase	: std_logic;
	signal	SdCmdFinish		: std_logic_vector( 1 downto 0);
	signal	SdCmdFinishD	: std_logic_vector( 1 downto 0);
	signal	SdhcPresent		: std_logic;
	signal	SdCmdFail		: std_logic;
	-- Хранение пакетов с данными
	signal	TxFifoRst		: std_logic;
	signal	TxFifoDataW		: std_logic_vector(32 downto 0);
	signal	TxFifoWrite		: std_logic;
	signal	TxFifoDataR		: std_logic_vector(32 downto 0);
	signal	TxFifoRead		: std_logic;
	signal	TxFifoEmpty		: std_logic;
	signal	TxFifoFull		: std_logic;
	signal	RxFifoDataW		: std_logic_vector(32 downto 0);
	signal	RxFifoWrite		: std_logic;
	signal	RxFifoDataR		: std_logic_vector(32 downto 0);
	signal	RxFifoRead		: std_logic;
	signal	RxFifoEmpty		: std_logic;
	signal	RxFifoFull		: std_logic;	
	signal	SdInitComp		: std_logic;	
	
	-- Константы для выбора команды
	constant	cBIT_RD			: integer := 0;
	constant	cBIT_WR			: integer := 1;
	constant	cBIT_ER			: integer := 2;
	
	function bool_to_logic( iBool : boolean ) return std_logic is
	begin
		
		if iBool then
			return '1';
		end if;
		
		return '0';
		
	end bool_to_logic;
	
begin

	----------------------------------------------------------------------------
	-- Входные параметры
	----------------------------------------------------------------------------
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdStart <= '0' after gTCQ;
			else
				SdStart <= iSdStart after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdCommand <= (others => '0') after gTCQ;
			else
				if (iSdStart = '1' and smSdControl = sIdle) then
					SdCommand <= iSdCommand after gTCQ;
				elsif (smSdControl = sWriteCmd) then
					SdCommand(cBIT_WR) <= '0' after gTCQ;
				elsif (smSdControl = sEraseCmd) then
					SdCommand(cBIT_ER) <= '0' after gTCQ;
				elsif (smSdControl = sReadCmd) then
					SdCommand(cBIT_RD) <= '0' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	-- Для карт SDSC используется байтовый адрес, а для всех остальных используется
	-- адрес, выровненный на 512 байт. В инициализации, в случае SDSC, настраивается режим 
	-- работы блоками по 512 байт.
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdAdress <= (others => '0') after gTCQ;
			else
				if (iSdStart = '1' and smSdControl = sIdle) then
					if (SdhcPresent = '1') then
						SdAdress <= iSdAddress after gTCQ;
					else
						SdAdress <= iSdAddress(22 downto 0) & b"000000000" after gTCQ;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oSdStatus <= (others => '0') after gTCQ;
			else
				oSdStatus(0) <= bool_to_logic(smSdControl = sFinish) after gTCQ;
				oSdStatus(1) <= bool_to_logic(smSdControl = sFinish and SdCmdFail = '1') after gTCQ;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Управляющий автомат 
	----------------------------------------------------------------------------	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				smSdControl <= sIdle after gTCQ;
			else
				case (smSdControl) is
					when sIdle		=>	if (SdStart = '1' and SdInitComp = '1'	) then	smSdControl <= sWaitCmd		after gTCQ; end if;
					when sWaitCmd	=>	if (SdCommand(cBIT_RD) = '1'			) then	smSdControl <= sReadCmd		after gTCQ;
										elsif (SdCommand(cBIT_WR) = '1'			) then	smSdControl <= sWriteCmd	after gTCQ;
										elsif (SdCommand(cBIT_ER) = '1'			) then	smSdControl <= sEraseCmd	after gTCQ;
										else											smSdControl <= sFinish		after gTCQ; end if;
					when sReadCmd	=>	if (RxFifoEmpty = '1'					) then	smSdControl <= sWaitEnd		after gTCQ; end if; 
					when sWriteCmd	=>	if (WrDataReady = '0'					) then	smSdControl <= sWaitEnd		after gTCQ; end if;
					when sEraseCmd	=>													smSdControl <= sWaitEnd		after gTCQ; 
					when sWaitEnd	=>	if (SdCmdFinish(1) = '1'				) then	smSdControl <= sFinish		after gTCQ; 
										elsif (SdCmdFinish(0) = '1'				) then	smSdControl <= sWaitCmd		after gTCQ; end if;
					when sFinish	=>	if (SdStart = '0'						) then	smSdControl <= sIdle		after gTCQ; end if; 
					when others		=>													smSdControl <= sIdle		after gTCQ;
				end case;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				WrDataReady <= '0' after gTCQ;
			else
				if (iSdTxLast = '1' and iSdTxValid = '1' and TxFifoFull = '0') then
					WrDataReady <= '0' after gTCQ;
				elsif (TxFifoEmpty = '1' and smSdControl = sIdle and TxFifoFull = '0') then
					WrDataReady <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdControl = sWaitCmd) then
				WrDataCmd <= '0' after gTCQ;
			elsif (smSdControl = sWriteCmd) then
				WrDataCmd <= '1' after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdStartRead <= '0' after gTCQ;
			else
				SdStartRead <= bool_to_logic(smSdControl = sReadCmd and RxFifoEmpty = '1') after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdStartWrite <= '0' after gTCQ;
			else
				SdStartWrite <= bool_to_logic(smSdControl = sWriteCmd and WrDataReady = '0') after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				SdStartErase <= '0' after gTCQ;
			else
				SdStartErase <= bool_to_logic(smSdControl = sEraseCmd) after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			SdCmdFinishD <= SdCmdFinish after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (smSdControl = sIdle) then
				SdCmdFail <= '0' after gTCQ;
			elsif (smSdControl = sWaitEnd and SdCmdFinish(1) = '1') then
				SdCmdFail <= '1' after gTCQ;
			end if;
		end if;
	end process;
	
	-- Если при записи произошла ошибка, то FIFO с данными сбрасывается. В результате формируется
	-- готовность к приему новых данных. Однако, в этот момент FIFO может находится в сбросе, поэтому 
	-- данные не запишутся. Такое может произойти при уменьшении счетчика сброса в SdCommand 
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				TxFifoRst <= '1' after gTCQ;
			else
				TxFifoRst <= bool_to_logic(WrDataCmd = '1' and SdCmdFinish(1) = '1' and SdCmdFinishD(1) = '0') after gTCQ;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Хранение пакетов с данными
	----------------------------------------------------------------------------
	TxFifoDataW <= iSdTxLast & iSdTxData;
	TxFifoWrite <= WrDataReady and iSdTxValid;

	TxFifo : entity WORK.SyncFifoBram33x8192
	port map	(	clk			=> pclk,
					srst		=> TxFifoRst,
					din			=> TxFifoDataW,
					wr_en		=> TxFifoWrite,
					rd_en		=> TxFifoRead,
					dout		=> TxFifoDataR,
					full		=> open,
					empty		=> TxFifoEmpty,
					prog_full	=> TxFifoFull );
	
	oSdTxReady <= WrDataReady;
	
	RxFifo : entity WORK.SyncFifoBram33x8192
	port map	(	clk			=> pclk,
					srst		=> rst,
					din			=> RxFifoDataW,
					wr_en		=> RxFifoWrite,
					rd_en		=> RxFifoRead,
					dout		=> RxFifoDataR,
					full		=> open,
					empty		=> RxFifoEmpty,
					prog_full	=> RxFifoFull );
	
	oSdRxData	<= RxFifoDataR(31 downto 0);
	oSdRxValid	<= not RxFifoEmpty;
	oSdRxLast	<= RxFifoDataR(32);
	RxFifoRead	<= iSdRxReady;	

	SdCardCommand : entity WORK.SdCommand(rtl)
	generic map	(	gTCQ			=> gTCQ )
	port map	(	-- Command from host
					oSdInitComp		=> SdInitComp,
					oSdInitFail		=> oSdInitFail,
					iSdAddress		=> SdAdress,
					iSdStartErase	=> SdStartErase,
					iSdStartRead	=> SdStartRead,
					iSdStartWrite	=> SdStartWrite,
					oSdCmdFinish	=> SdCmdFinish,		
					oSdhcPresent	=> SdhcPresent,		
					-- Data
					oSdReadData		=> TxFifoRead,
					iSdDataR		=> TxFifoDataR(31 downto 0),
					oSdWriteData	=> RxFifoWrite,
					oSdDataW		=> RxFifoDataW,					
					-- Spi
					oSdCS			=> oSdCS,
					oSdClk			=> oSdClk,
					oSdMosi			=> oSdMosi,
					oSdMosiT		=> oSdMosiT,
					iSdMiso			=> iSdMiso,
					-- system
					pclk			=> pclk,
					sclk			=> sclk,
					rst				=> rst );

end rtl;