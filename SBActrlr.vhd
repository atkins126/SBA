-- /SBA: Controller ------------------------------------------------------------
--
-- /SBA: Program Details -------------------------------------------------------
-- Project Name: %name%
-- Title: %title%
-- Version: %version%
-- Date: %date%
-- Author: %author%
-- Description: %description%
-- /SBA: End Program Details ---------------------------------------------------
--
-- SBA Master System Controller v1.52
-- Based on Master Controller for SBA v1.1 Guidelines
--
-- (c) 2008-2015 Miguel A. Risco Castillo
-- SBA web page: http://sba.accesus.com
--
--------------------------------------------------------------------------------
-- Copyright:
--
-- This code, modifications, derivate work or based upon, can not be used or
-- distributed without the complete credits on this header.
--
-- The copyright notices in the source code may not be removed or modified.
-- If you modify and/or distribute the code to any third party then you must not
-- veil the original author. It must always be clearly identifiable.
--
-- Although it is not required it would be a nice move to recognize my work by
-- adding a citation to the application's and/or research. If you use this
-- component for your research please include the appropriate credit of Author.
--
-- FOR COMMERCIAL PURPOSES REQUEST THE APPROPRIATE LICENSE FROM THE AUTHOR.
--
-- For non commercial purposes this version is released under the GNU/GLP license
-- http://www.gnu.org/licenses/gpl.html
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.%name%_SBAconfig.all;
use work.SBApackage.all;

entity %name%_SBAcontroller  is
port(
   RST_I : in std_logic;                     -- active high reset
   CLK_I : in std_logic;                     -- main clock
   DAT_I : in std_logic_vector;              -- Data input Bus
   DAT_O : out std_logic_vector;             -- Data output Bus
   ADR_O : out std_logic_vector;             -- Address output Bus
   STB_O : out std_logic;                    -- Strobe enabler
   WE_O  : out std_logic;                    -- Write / Read
   ACK_I : in  std_logic;                    -- Strobe Acknowledge
   INT_I : in  std_logic                     -- Interrupt request
);
end %name%_SBAcontroller;

architecture %name%_SBAcontroller_Arch of %name%_SBAcontroller is

  subtype STP_type is integer range 0 to 63;
  subtype ADR_type is integer range 0 to (2**ADR_O'length-1);

  signal D_Oi : unsigned(DAT_O'range);       -- Internal Data Out signal (unsigned)
  signal A_Oi : ADR_type;                    -- Internal Address signal (integer)
  signal S_Oi : std_logic;                   -- strobe (Address valid)   
  signal W_Oi : std_logic;                   -- Write enable ('0' read enable)
  signal STPi : STP_type;                    -- STeP counter
  signal NSTPi: STP_type;                    -- Step counter + 1 (Next STep)

-- /SBA: User Signals and Type definitions ---------------------------------

-- /SBA: End User Signals and Type definitions -----------------------------

begin

  Main : process (CLK_I, RST_I)

-- General variables
  variable jmp  : STP_type;                  -- Jump step register
  variable ret  : STP_type;                  -- Return step for subroutines register
  variable dati : unsigned(DAT_I'range);     -- Input Internal Data Bus
  alias    dato is D_Oi;                     -- Output Data Bus alias

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
    W_Oi <= '1';
    D_Oi <= resize(data,D_Oi'length);
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

-- /SBA: End Procedures --------------------------------------------------------

-- /SBA: User Procedures and Functions -----------------------------------------

-- /SBA: End User Procedures and Functions -------------------------------------
  
-- /SBA: User Registers and Constants ------------------------------------------

-- /SBA: End User Registers and Constants --------------------------------------

-- /SBA: Label constants -------------------------------------------------------
  constant Init: integer := 002;
-- /SBA: End Label constants ---------------------------------------------------

begin

  if rising_edge(CLK_I) then
  
    if (debug=1) then
      Report "Step: " &  integer'image(STPi);
    end if;
	 
	jmp := 0;			      -- Default jmp value
    S_Oi<='0';                -- Default S_Oi value

    dati:= unsigned(DAT_I);   -- Get and capture value from data bus
	 
	  
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
                
-- /SBA: End User Program ------------------------------------------------------

        When others=> jmp:=1; 
      end case;
      if jmp/=0 then STPi<=jmp; else STPi<=NSTPi; end if;
    end if;
  end if;
end process;

-- /SBA: User Statements -------------------------------------------------------

-- /SBA: End User Statements ---------------------------------------------------

NSTPi <= STPi + 1;      -- Step plus one (Next STeP)
STB_O <= S_Oi;
WE_O  <= W_Oi;
ADR_O <= std_logic_vector(to_unsigned(A_Oi,ADR_O'length));
DAT_O <= std_logic_vector(D_Oi);

end %name%_SBAController_Arch;

