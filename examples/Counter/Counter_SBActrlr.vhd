-- /SBA: Controller ------------------------------------------------------------
--
-- /SBA: Program Details -------------------------------------------------------
--
-- Project Name: Counter
-- Title: SBA Seven segments 4 digits up counter demo
-- Version: 0.1.1
-- Date: 2015/06/12
-- Author: Miguel A. Risco-Castillo
-- Description: This a demo of the implementation of a simple up counter in the 
-- 4 digits 7 segments display of the Nexys2 board.
-- 
-- /SBA: End -------------------------------------------------------------------
--
-- SBA Master System Controller v1.51
-- Based on Master Controller for SBA v1.1 Guidelines
--
-- (c) 2008-2015 Miguel A. Risco Castillo
-- email: mrisco@accesus.com
-- sba web page: http://sba.accesus.com
--
-- Notes:
--
-- v1.51 20150509
-- * Address always will be of type integer, then the functions to support
--   read and write of unsigned address were removed.
-- * Rename some signal to follow SBA1.1 design guides:
--   signals in uppercase, ending with lowercase i for internal signals.
-- * Remove the range limitations of integer variables (the synthesis
--   optimization phase will truncate integers according to the necessary bits.
-- * Added Signatures '-- SBA:' for Easy editing in SBA System Creator

-- v1.50 20141211
-- change some more variables to signals
-- remove cal variable
-- make compatible with pre SBA v1.1
-- Add SBAjump function (jump to some step)
--
-- v1.47 20110331
-- Move step, ret and address variables to signals to improve
-- performance and area. Restore ACK_I functionality
--
-- v1.46 20101015
-- Implement SBAwait for freeze Bus values;
-- Restore STB_O functionality
--
-- v1.45 20101015
--
-- 1.0.1 20100730
--
-- v0.6.5 20080603
-- Initial release.
--
--------------------------------------------------------------------------------
-- Copyright:
--
-- This code, modifications, derivate work or based upon, can not be used or
-- distributed without the complete credits on this header.
--
-- This version is released under the GNU/GLP license
-- http://www.gnu.org/licenses/gpl.html
-- if you use this component for your research please include the appropriate
-- credit of Author.
--
-- The code may not be included into ip collections and similar compilations
-- which are sold. If you want to distribute this code for money then contact me
-- first and ask for my permission.
--
-- These copyright notices in the source code may not be removed or modified.
-- If you modify and/or distribute the code to any third party then you must not
-- veil the original author. It must always be clearly identifiable.
--
-- Although it is not required it would be a nice move to recognize my work by
-- adding a citation to the application's and/or research.
--
-- FOR COMMERCIAL PURPOSES REQUEST THE APPROPRIATE LICENSE FROM THE AUTHOR.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Counter_SBAconfig.all;
use work.SBApackage.all;

entity Counter_SBAcontroller  is
port(
   RST_I : in std_logic;                     -- active high reset
   CLK_I : in std_logic;                     -- main clock
   DAT_I : in std_logic_vector;              -- Data input Bus
   DAT_O : out std_logic_vector;             -- Data output Bus
   ADR_O : out std_logic_vector;             -- Address output Bus
   STB_O : out std_logic;                    -- Strobe enabler
   WE_O  : out std_logic;                    -- Write / Read
   ACK_I : in  std_logic;                    -- Strobe Acknoledge
   INT_I : in  std_logic                     -- Interrupt request
);
end Counter_SBAcontroller;

architecture Counter_SBAcontroller_Arch of Counter_SBAcontroller is

  subtype STP_type is integer range 0 to 63;
  subtype ADR_type is integer range 0 to (2**ADR_O'length-1);

  signal D_Oi : unsigned(DAT_O'range);       -- Internal Data Out signal (unsigned)
  signal A_Oi : ADR_type;                    -- Internal Address signal (integer)
  signal S_Oi : std_logic;                   -- strobe (Address valid)   
  signal W_Oi : std_logic;                   -- Write enable ('0' read enable)
  signal STPi : STP_type;                    -- STeP counter
  signal NSTPi: STP_type;                    -- Step counter + 1 (Next STep)

begin

  Main : process (CLK_I, RST_I)

-- General variables
  variable jmp  : STP_type;                  -- Jump step register
  variable ret  : STP_type;                  -- Return step for subroutines register
  variable dati : unsigned(DAT_I'range);     -- Input Internal Data Bus

-- /SBA: Procedures ------------------------------------------------------------

  -- Prepare bus for reading from DAT_I in the next step
  procedure SBAread(addr:in integer) is
  begin
    if (debug=1) then
      Report "SBAread: Address=" &  integer'image(addr);
    end if;

    A_Oi <= addr;
    S_Oi <= '1';
    W_Oi <= '0';
  end;

  -- Write values to bus
  procedure SBAwrite(addr:in integer; data: in unsigned) is
  begin
    if (debug=1) then
      Report "SBAwrite: Address=" &  integer'image(addr) & " Data=" &  integer'image(to_integer(data));
    end if;

    A_Oi <= addr;
    S_Oi <= '1';
    W_Oi  <= '1';
    D_Oi<= resize(data,D_Oi'length);
  end;

  -- Do not make any modification to bus in that step
  procedure SBAwait is
  begin
    S_Oi<='1'; 
  end;

  -- Jump to arbitrary step
  procedure SBAjump(stp:in integer) is
  begin
	 jmp:=stp;
  end;

  -- Jump to rutine and storage return step in ret variable
  procedure SBAcall(stp:in integer) is
  begin
	 jmp:=stp;
	 ret:=NSTPi;
  end;

  -- Copy the return step to jump variable
  procedure SBAret is
  begin
    jmp:=ret;
  end;
  
-- /SBA: User Registers and Constants ------------------------------------------


-- /SBA: End -------------------------------------------------------------------


-- /SBA: Label constants -------------------------------------------------------


-- /SBA: End -------------------------------------------------------------------

begin

  if rising_edge(CLK_I) then
  
    if (debug=1) then
      Report "Step: " &  integer'image(STPi);
    end if;
	 
	 jmp := 0;				      -- Default jmp value	
    S_Oi<='0';                -- Default S_Oi value  
    dati:= unsigned(DAT_I);   -- Get value from data bus
	 
	  
    if (RST_I='1') then
      ret := 0;               -- Default ret value  
      STPi<= 1;               -- First step is 1 (cal and jmp valid only if >0)
      A_Oi<= 0;               -- Default Address Value
      W_Oi<='1';              -- Default W_Oi value on reset

    elsif (ACK_I='1') or (S_Oi='0') then
      case STPi is

-- /SBA: User Program ----------------------------------------------------------
                
        When 001=> SBAjump(Init);
                
-------------------------------- RUTINES ---------------------------------------
                

------------------------------ MAIN PROGRAM ------------------------------------
                
-- /L:Init
        When 002=> SBAWait;

        When 003=> SBAjump(Init);
                
-- /SBA: End -------------------------------------------------------------------

        When others=> jmp:=1; 
      end case;
      if jmp/=0 then STPi<=jmp; else STPi<=NSTPi; end if;
    end if;
  end if;
end process;

NSTPi <= STPi + 1;      -- Step plus one (Next STeP)
STB_O <= S_Oi;
WE_O  <= W_Oi;
ADR_O <= std_logic_vector(to_unsigned(A_Oi,ADR_O'length));
DAT_O <= std_logic_vector(D_Oi);

end Counter_SBAController_Arch;

