----------------------------------------------------------------------------------
-- Company:	
-- Engineer:	Finnetrib@gmail.com
-- 
-- Create Date: 06.02.2019 16:32:56
-- Design Name: 
-- Module Name: SDPhy - rtl
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

library UNISIM;
use UNISIM.VComponents.all;

entity SDPhy is
	generic	(	gTCQ		: time := 2 ns );
	port	(	-- Control bus
				iPhyTxData	: in	std_logic_vector( 9 downto 0);
				iPhyMode	: in	std_logic_vector( 4 downto 0);
				iPhyTxWrite	: in	std_logic;
				oPhyTxReady	: out	std_logic; 
				-- Out Data
				oPhyRxData	: out	std_logic_vector( 7 downto 0); 
				oPhyRxWrite	: out	std_logic;
				oPhyCmdEnd	: out	std_logic;
				-- Spi
				oSdCS		: out	std_logic;
				oSdClk		: out	std_logic;
				oSdMosi		: out	std_logic;
				oSdMosiT	: out	std_logic;
				iSdMiso		: in	std_logic;
				-- system
				sclk		: in	std_logic;
				pclk		: in	std_logic;
				rst			: in	std_logic ); 
end SDPhy;

architecture rtl of SDPhy is

	-- Входные данные, параметры и управление
	signal	TxFifoDataW		: std_logic_vector(14 downto 0);
	signal	TxFifoRead		: std_logic;
	signal	TxFifoDataR		: std_logic_vector(14 downto 0);
	signal	TxFifoEmpty		: std_logic;
	signal	TxFifoFull		: std_logic;
	signal	PhyMode			: std_logic_vector( 2 downto 0);
	signal	SpeedSelect		: std_logic;
	signal	ShortCommand	: std_logic;
	signal	cntrLowClk		: std_logic_vector( 6 downto 0);
	signal	cntrFastClk		: std_logic_vector( 0 downto 0);
	signal	SdClk			: std_logic;
	signal	SdClkD			: std_logic;
	signal	RisingSdClk		: std_logic;
	signal	FallingSdClk	: std_logic;
	signal	ReadTx			: std_logic;
	signal	ReadRx			: std_logic;
	signal	ReadDummy		: std_logic;
	signal	ReadBusy		: std_logic;
	signal	ReadResp		: std_logic;
	-- Управляющий автомат для режимов cMODE_DUMMY, cMODE_TX
	type	TSM_SD_PHY_TX	is (sIdle, sDummy, sTxBits);
	signal	smSdPhyTx		: TSM_SD_PHY_TX;
	signal	cntrDummy		: std_logic_vector( 7 downto 0);
	signal	cntrTxBits		: std_logic_vector( 2 downto 0);
	-- Управляющий автомат для режимов cMODE_RX, cMODE_BUSY, cMODE_RESP, cMODE_TOKEN
	type	TSM_SD_PHY_RX	is (sIdle,  sRxBits, sBusy, sResp, sToken, sWait);
	signal	smSdPhyRx		: TSM_SD_PHY_RX;
	signal	SdMiso			: std_logic;
	signal	StartRx			: std_logic;
	signal	cntrRxBits		: std_logic_vector( 2 downto 0);
	signal	cntrRxByte		: std_logic_vector( 9 downto 0);
	signal	cntrWait		: std_logic_vector( 1 downto 0);
	signal	cntrBusy		: std_logic_vector( 2 downto 0);
	signal	BusyCmd			: std_logic;
	signal	RespCmd			: std_logic;
	signal	cntrRxResp		: std_logic_vector( 2 downto 0);
	signal	ErShiftBits		: std_logic_vector( 7 downto 0);
	-- Обработка протокола SPI
	signal	TxShiftBits		: std_logic_vector( 7 downto 0);
	signal	RxShiftBits		: std_logic_vector( 7 downto 0);
	signal	RxShfitWrite	: std_logic;
	signal	SdClkEn			: std_logic;
	signal	CmdComplete		: std_logic;
	signal	CmdCompleteD	: std_logic;
	-- Выходные данные и статус
	signal	RxFifoDataW		: std_logic_vector(14 downto 0);
	signal	RxFifoWrite		: std_logic;
	signal	RxFifoRead		: std_logic;
	signal	RxFifoDataR		: std_logic_vector(14 downto 0);	
	signal	RxFifoEmpty		: std_logic;
	-- Константы
	-- Максимальное количество тактов для генерации частоты инициализации
	constant	cLOW_COUNT	: integer := 127;
	-- Максимальное количество тактов для генерации частоты работы
	constant	cFAST_COUNT	: integer := 1; 
	-- Номер бита, используемого для указания признака завершения обработки команд
	constant	cBIT_END	: integer := 8;	 
	
	function bool_to_logic( iBool : boolean ) return std_logic is
	begin
		
		if iBool then
			return '1';
		end if;
		
		return '0';
		
	end bool_to_logic;
	
begin

	----------------------------------------------------------------------------
	-- Входные данные, параметры и формирование частот
	----------------------------------------------------------------------------
	
	TxFifoDataW <= iPhyMode & iPhyTxData;

	TxFifo : entity WORK.AsyncFifoLut15x16
	port map	(	rst			=> rst,
					wr_clk		=> pclk,
					rd_clk		=> sclk,
					din			=> TxFifoDataW,
					wr_en		=> iPhyTxWrite,
					rd_en		=> TxFifoRead,
					dout		=> TxFifoDataR,
					full		=> open,
					empty		=> TxFifoEmpty,
					prog_full	=> TxFifoFull );
	
	oPhyTxReady		<= not TxFifoFull;
	PhyMode			<= TxFifoDataR(12 downto 10);
	SpeedSelect		<= TxFifoDataR(13);
	ShortCommand	<= TxFifoDataR(14);
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				cntrLowClk <= (others => '0') after gTCQ;
			elsif (SpeedSelect = '1') then
				cntrLowClk <= cntrLowClk + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				cntrFastClk <= (others => '0') after gTCQ;
			elsif (SpeedSelect = '0') then
				cntrFastClk <= cntrFastClk + 1 after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			SdClk <= bool_to_logic((SpeedSelect = cLOW_MODE and cntrLowClk(cntrLowClk'high) = '1') or
				(SpeedSelect = cFAST_MODE and cntrFastClk(cntrFastClk'high) = '1')) after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			SdClkD <= SdClk after gTCQ;
		end if;
	end process;

	RisingSdClk		<= bool_to_logic(SdClk = '1' and SdClkD = '0');
	FallingSdClk	<= bool_to_logic(SdClk = '0' and SdClkD = '1');
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			ReadTx <= bool_to_logic(smSdPhyTx = sTxBits and cntrTxBits = 5 and RisingSdClk = '1') after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			ReadRx <= bool_to_logic(smSdPhyRx = sRxBits and cntrRxBits = 5 and cntrRxByte = 0 and FallingSdClk = '1') after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			ReadDummy <= bool_to_logic(smSdPhyTx = sDummy and cntrDummy = 70 and RisingSdClk = '1') after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			ReadBusy <= bool_to_logic(smSdPhyRx = sBusy and BusyCmd = '0' and FallingSdClk = '1') after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			ReadResp <= bool_to_logic(smSdPhyRx = sResp and cntrRxResp = 5 and FallingSdClk = '1') after gTCQ;
		end if;
	end process;

	TxFifoRead <= ReadTx or ReadRx or ReadDummy or ReadBusy or ReadResp;
	
	----------------------------------------------------------------------------
	-- Управляющий автомат для режимов cMODE_DUMMY, cMODE_TX
	----------------------------------------------------------------------------
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				smSdPhyTx <= sIdle after gTCQ;
			else
				if (RisingSdClk = '1') then
					case (smSdPhyTx) is
						when sIdle		=>	if (TxFifoEmpty = '0'					) then
												if (PhyMode = cMODE_DUMMY			) then	smSdPhyTx <= sDummy	after gTCQ;
												elsif (PhyMode = cMODE_TX			) then	smSdPhyTx <= sTxBits	after gTCQ; end if;
											end if;
						when sDummy		=>	if (cntrDummy(cntrDummy'high) = '1'		) then	smSdPhyTx <= sIdle	after gTCQ; end if;
						when sTxBits	=>	if (cntrTxBits = 6						) then	smSdPhyTx <= sIdle	after gTCQ; end if;
						when others		=>													smSdPhyTx <= sIdle	after gTCQ;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (RisingSdClk = '1') then
				if (smSdPhyTx = sIdle) then
					cntrDummy <= (others => '0') after gTCQ;
				elsif (smSdPhyTx = sDummy) then
					cntrDummy <= cntrDummy + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				cntrTxBits <= (others => '0') after gTCQ;
			else
				if (RisingSdClk = '1') then
					if (smSdPhyTx = sIdle) then
						cntrTxBits <= (others => '0') after gTCQ;
					elsif (smSdPhyTx = sTxBits) then
						cntrTxBits <= cntrTxBits + 1 after gTCQ;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Управляющий автомат для режимов cMODE_RX, cMODE_BUSY, cMODE_RESP, cMODE_TOKEN
	----------------------------------------------------------------------------
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				smSdPhyRx <= sIdle after gTCQ;
			else
				if (FallingSdClk = '1') then
					case (smSdPhyRx) is
						when sIdle		=>	if (TxFifoEmpty = '0'														) then
												if (PhyMode = cMODE_RX													) then	smSdPhyRx <= sRxBits	after gTCQ;
												elsif (PhyMode = cMODE_BUSY												) then	smSdPhyRx <= sBusy		after gTCQ;
												elsif (PhyMode = cMODE_RESP												) then	smSdPhyRx <= sResp		after gTCQ;
												elsif (PhyMode = cMODE_TOKEN											) then	smSdPhyRx <= sToken	after gTCQ; end if;
											end if;
						when sRxBits	=>	if (cntrRxBits = 6 and cntrRxByte = 0										) then
												if (TxFifoEmpty = '0'													) then	smSdPhyRx <= sIdle		after gTCQ;
												else																			smSdPhyRx <= sWait		after gTCQ; end if;
											end if;
						when sWait		=>	if (cntrWait = 2															) then	smSdPhyRx <= sIdle		after gTCQ; end if;
						when sBusy		=>	if (cntrBusy = 7 and iSdMiso = '1'											) then	smSdPhyRx <= sIdle		after gTCQ; end if;
						when sResp		=>	if (cntrRxResp = 6															) then	smSdPhyRx <= sIdle		after gTCQ; end if;
						when sToken		=>	if (ErShiftBits(7 downto 5) = b"000" and RxShiftBits(7 downto 5) = b"000"	) then	smSdPhyRx <= sIdle		after gTCQ;	
											elsif (RxShiftBits(7 downto 1) = b"1111111" and iSdMiso = '0'				) then	smSdPhyRx <= sRxBits	after gTCQ; end if; 
						when others		=>																						smSdPhyRx <= sIdle		after gTCQ;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx = sIdle) then
					SdMiso <= '1' after gTCQ;
				elsif (smSdPhyRx = sRxBits) then
					SdMiso <= iSdMiso after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx = sIdle and cntrRxBits = 0) or smSdPhyRx = sWait then
					StartRx <= '0' after gTCQ;
				elsif (smSdPhyRx = sRxBits and SdMiso = '1' and iSdMiso = '0') then
					StartRx <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx = sIdle or smSdPhyRx = sWait) then
					cntrRxBits <= (others => '0') after gTCQ;
				elsif (smSdPhyRx = sRxBits and ((iSdMiso = '0' and SdMiso = '1') or StartRx = '1')) then
					cntrRxBits <= cntrRxBits + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;

	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if ((smSdPhyRx = sIdle and TxFifoEmpty = '0' and PhyMode = cMODE_RX) or smSdPhyRx = sToken) then
					cntrRxByte <= TxFifoDataR(9 downto 0) after gTCQ;
				elsif (smSdPhyRx = sRxBits and cntrRxBits = 6) then
					cntrRxByte <= cntrRxByte - 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx /= sWait) then
					cntrWait <= (others => '0') after gTCQ;
				else
					cntrWait <= cntrWait + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx /= sBusy) then
					cntrBusy <= (others => '0') after gTCQ;
				elsif (iSdMiso = '1') then
					cntrBusy <= cntrBusy + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				BusyCmd <= bool_to_logic(smSdPhyRx = sBusy) after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				RespCmd <= bool_to_logic(smSdPhyRx = sResp) after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx = sIdle) then
					cntrRxResp <= (others => '0') after gTCQ;
				elsif (smSdPhyRx = sResp and RespCmd = '1') then
					cntrRxResp <= cntrRxResp + 1 after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				if (smSdPhyRx = sIdle and TxFifoEmpty = '1') then
					ErShiftBits <= (others => '1') after gTCQ;
				elsif ((smSdPhyRx = sIdle and PhyMode = cMODE_TOKEN) or smSdPhyRx = sToken) then
					ErShiftBits <= ErShiftBits(6 downto 0) & iSdMiso after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Обработка протокола SPI
	----------------------------------------------------------------------------
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				TxShiftBits <= (others => '1') after gTCQ;
			else
				if (RisingSdClk = '1') then
					if (smSdPhyTx = sIdle and PhyMode = cMODE_TX) then
						TxShiftBits <= TxFifoDataR(7 downto 0) after gTCQ; 
					elsif (smSdPhyTx = sTxBits) then
						TxShiftBits <= TxShiftBits(6 downto 0) & '0' after gTCQ;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				oSdMosi <= '1' after gTCQ;
			else
				oSdMosi <= TxShiftBits(7) after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			oSdMosiT <= not bool_to_logic(smSdPhyTx = sTxBits or (smSdPhyTx = sIdle and cntrTxBits /= 0)) after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (FallingSdClk = '1') then
				RxShiftBits <= RxShiftBits(6 downto 0) & iSdMiso after gTCQ;
			end if;
		end if;
	end process;

	process (sclk) begin
		if (rising_edge(sclk)) then
			RxShfitWrite <= bool_to_logic(FallingSdClk = '1' and (cntrRxBits = 7 or cntrRxResp = 7 or 
										(smSdPhyRx = sToken and ((RxShiftBits(7 downto 1) = b"1111111" and iSdMiso = '0') or
										(ErShiftBits(7 downto 5) = b"000" and RxShiftBits(7 downto 5) = b"000"))))) after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				oSdCS <= '1' after gTCQ;
			else
				if (smSdPhyTx = sTxBits) then
					oSdCS <= '0' after gTCQ; 
				elsif (smSdPhyTx = sIdle and smSdPhyRx = sIdle and TxFifoEmpty = '1' and ShortCommand = '1' and cntrRxBits = 0 ) then
					oSdCS <= '1' after gTCQ;
				end if;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (rst = '1') then
				SdClkEn <= '0' after gTCQ;
			else
				if (smSdPhyTx = sTxBits or smSdPhyTx = sDummy) then
					SdClkEn <= '1' after gTCQ;
				elsif (smSdPhyTx = sIdle and smSdPhyRx = sIdle and TxFifoEmpty = '1' and cntrRxBits = 0) then
					SdClkEn <= '0' after gTCQ;
				end if;
			end if;
		end if;
	end process;

	process (sclk) begin
		if (rising_edge(sclk)) then
			if (SdClkEn = '1') then
				if (SpeedSelect = cLOW_MODE) then
					oSdClk <= not SdClk after gTCQ;
				else
					oSdClk <= SdClk after gTCQ;
				end if;
			else
				oSdClk <= '0' after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			CmdComplete <= bool_to_logic(smSdPhyTx = sIdle and smSdPhyRx = sIdle and TxFifoEmpty = '1' and cntrRxBits = 0) after gTCQ;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			CmdCompleteD <= CmdComplete after gTCQ;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Выходные данные и статус
	----------------------------------------------------------------------------	
	process (sclk) begin
		if (rising_edge(sclk)) then
			if (CmdComplete = '1' and CmdCompleteD = '0') then
				RxFifoDataW(cBIT_END) <= '1' after gTCQ;
				RxFifoDataW(14 downto 9) <= (others => '0') after gTCQ;
			else
				RxFifoDataW(RxShiftBits'range) <= RxShiftBits after gTCQ;
				RxFifoDataW(cBIT_END) <= '0' after gTCQ;
				RxFifoDataW(14 downto 9) <= (others => '0') after gTCQ;
			end if;
		end if;
	end process;
	
	process (sclk) begin
		if (rising_edge(sclk)) then
			RxFifoWrite <= bool_to_logic(RxShfitWrite = '1' or (CmdComplete = '1' and CmdCompleteD = '0')) after gTCQ;
		end if;
	end process;
	
	RxFifo : entity WORK.AsyncFifoLut15x16
	port map	(	rst			=> rst,
					wr_clk		=> sclk,
					rd_clk		=> pclk,
					din			=> RxFifoDataW,
					wr_en		=> RxFifoWrite,
					rd_en		=> RxFifoRead,
					dout		=> RxFifoDataR,
					full		=> open,
					empty		=> RxFifoEmpty,
					prog_full	=> open );
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			RxFifoRead <= bool_to_logic(RxFifoEmpty = '0') after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			oPhyRxData <= RxFifoDataR(oPhyRxData'range) after gTCQ;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oPhyRxWrite <= '0' after gTCQ;
			else
				oPhyRxWrite <= bool_to_logic(RxFifoRead = '1' and RxFifoEmpty = '0' and RxFifoDataR(cBIT_END) = '0') after gTCQ;
			end if;
		end if;
	end process;
	
	process (pclk) begin
		if (rising_edge(pclk)) then
			if (rst = '1') then
				oPhyCmdEnd <= '0' after gTCQ;
			else
				oPhyCmdEnd <= bool_to_logic(RxFifoDataR(cBIT_END) = '1' and RxFifoEmpty = '0') after gTCQ;
			end if;
		end if;
	end process;	
	
end rtl;