library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PONG is
    Port (
        clk        : in  STD_LOGIC;
        H          : out STD_LOGIC;
        V          : out STD_LOGIC;
        DAC_CLK    : out STD_LOGIC;
        Rout       : out STD_LOGIC_VECTOR(7 downto 0);
        Gout       : out STD_LOGIC_VECTOR(7 downto 0);
        Bout       : out STD_LOGIC_VECTOR(7 downto 0);
        SW0        : in  STD_LOGIC;
        SW1        : in  STD_LOGIC;
        SW2        : in  STD_LOGIC;
        SW3        : in  STD_LOGIC

    );
end PONG;

architecture Behavioral of PONG is
    -- BASIC SIGNALS
    signal dclk : std_logic;
    signal hsync, vsync, delay : Integer := 0;
    signal h_pos : integer range 0 to 640;
    signal v_pos : integer range 0 to 480;

    signal ballX : Integer := 315;
    signal ballY : Integer := 230;
signal ballSize: Integer :=15;

--ball direection
signal bDX : Integer := 1;
signal bDY : integer := 1;

signal w0: Integer :=0;

    -- SIZINGS
    signal paddlewidth : Integer := 12;
signal paddleheight : Integer := 90;
    constant nettop : Integer := 125;
    constant netbottom : Integer := 485 - nettop;

signal innerArenaTop : Integer :=37;
signal innerArenaBottom : Integer :=446;
signal innerArenaLeft : Integer := 26;
signal innerArenaRight : Integer := 604;

--posiiton vars
signal leftPaddlePosY : Integer := 37;
signal rightPaddlePosY : Integer := 37;

signal leftPaddlePosX : Integer := 40;
signal rightPaddlePosX : Integer := 600;

BEGIN
    -- 25Mhz into dclk from 50Mhz
    PROCESS (clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (dclk = '1') THEN
                dclk <= '0';
            ELSE
                dclk <= '1';
            END IF;
        END IF;
    END PROCESS;
    DAC_CLK <= dclk;

    PROCESS (dclk)
    BEGIN
        -- syncing process, reset at new frame
        IF (rising_edge(dclk)) THEN
            IF (hsync = 800) THEN
                vsync <= vsync + 1;
                hsync <= 0;
            ELSE
                hsync <= hsync + 1;
            END IF;
            IF (vsync = 524) THEN
                vsync <= 0;
            END IF;
            -- V Sync Pulse 64, set to 0 for 96 cycles of sync pulse
            IF (hsync >= 656 AND hsync <= 751) THEN
                H <= '0';
            ELSE
                H <= '1';
            END IF;
            -- H Sync Pulse, set to 0 for 2 cycles of sync pulse
            IF (vsync >= 490 AND vsync <= 491) THEN
                V <= '0';
            ELSE
                V <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- Static
    PROCESS (dclk, hsync, vsync)
    BEGIN
        IF (rising_edge(dclk)) THEN
            h_pos <= hsync;
            v_pos <= vsync;
            -- BACKGROUND COLOURING
            -- White top/bottom border
            IF (h_pos >= 25 AND h_pos <= 615 AND ((v_pos >= 25 AND v_pos <= 36) OR (v_pos >= 448 AND v_pos <= 459))) THEN
                ROUT <= X"FF";
                GOUT <= X"FF";
                BOUT <= X"FF";
            -- White sides border
            ELSIF (((h_pos >= 25 AND h_pos <= 36) OR (h_pos >= 604 AND h_pos <= 615)) AND ((v_pos >= 36 AND v_pos <= nettop) OR (v_pos >= netbottom AND v_pos <= 448))) THEN
                ROUT <= X"FF";
                GOUT <= X"FF";
                BOUT <= X"FF";
            -- Middle black lines
            ELSIF ((h_pos > 316 AND h_pos < 320) AND v_pos >= 37 AND v_pos < 448) AND (((v_pos - 35) mod 64) > 32) THEN
                ROUT <= X"00";
                GOUT <= X"00";
                BOUT <= X"00";
            -- All else green
            ELSIF (h_pos > 0 AND h_pos < 640 AND v_pos > 0 AND v_pos < 480) THEN
                ROUT <= X"34";
                GOUT <= X"FF";
                BOUT <= X"54";
            ELSE
    --don’t draw outside active area
                ROUT <= (OTHERS => '0');
                GOUT <= (OTHERS => '0');
                BOUT <= (OTHERS => '0');
            END IF;

            -- PADDLE LOGIC--
--left
IF ((h_pos > leftPaddlePosX AND h_pos < leftPaddlePosX + paddlewidth) AND (v_pos > leftPaddlePosY AND v_pos < leftPaddlePosY + paddleheight) ) THEN
ROUT <= X"00";
                GOUT <= X"00";
                BOUT <= X"FF";
END IF;
--right
IF ((h_pos < rightPaddlePosX AND h_pos > rightPaddlePosX - paddlewidth) AND (v_pos > rightPaddlePosY AND v_pos < rightPaddlePosY + paddleheight) ) THEN

ROUT <= X"FF";
                GOUT <= X"00";
                BOUT <= X"00";
--rightPaddlePosY <= rightPaddlePosY - 1;

END IF;

--right move down
IF (SW2 = '1' and h_pos >= 10 and h_pos <= 10 and v_pos >= 10 and v_pos <= 11 and rightPaddlePosY < 446 - paddleheight and SW3 = '1') THEN

rightPaddlePosY <= rightPaddlePosY + 1;
END IF;

--right move up
IF (SW2 = '0' and h_pos >= 10 and h_pos <= 10 and v_pos >= 10 and v_pos <= 11 and rightPaddlePosY > 37 and SW3 = '1') THEN

rightPaddlePosY <= rightPaddlePosY - 1;
END IF;
--left move down
IF (SW0 = '1' and h_pos >= 10 and h_pos <= 10 and v_pos >= 10 and v_pos <= 11 and leftPaddlePosY < 446 - paddleheight and SW1 = '1') THEN

leftPaddlePosY <= leftPaddlePosY + 1;
END IF;
--left up
IF (SW0 = '0' and h_pos >= 10 and h_pos <= 10 and v_pos >= 10 and v_pos <= 11 and leftPaddlePosY > 37 and SW1 = '1') THEN

leftPaddlePosY <= leftPaddlePosY - 1;
END IF;


--BALL LOGIC
IF (h_pos > ballX and h_pos< ballX + ballSize and v_pos > ballY and v_pos < ballY + ballSize) THEN

--check if goal
IF ((ballX < innerArenaLeft + ballSize - 6) OR (ballX > innerArenaRight - ballSize + 6)) THEN

ROUT <= X"FF";
                GOUT <= X"00";
                BOUT <= X"00";

IF ((ballX > 610) OR (ballX < 14)) THEN

ballX <= 312;
ballY <= 232;

END IF;

ELSE

ROUT <= X"FF";
                GOUT <= X"00";
                BOUT <= X"FF";

END IF;

END IF;

IF (h_pos >= 10 and h_pos <= 10 and v_pos >= 10 and v_pos <= 10) THEN

--which X way
IF bDX > 0 THEN
ballX <= ballX + 1;
ELSE
ballX <= ballX - 1;
END IF;

--which y way
IF bDY > 0 THEN
ballY <= ballY + 1;
ELSE
ballY <= ballY - 1;
END IF;

-----------------------------
--Switch vars, Y
IF (ballY < innerArenaTop) THEN

bDY <= 1;

END IF;

IF (ballY > innerArenaBottom - ballSize) THEN

bDY <= 0;

END IF;
-------------------------------
-- for X--walls

-- AND ((ballY < nettop) AND (ballY > netbottom))
IF (ballX > innerArenaRight - ballSize AND (((ballY < nettop) OR (ballY > netbottom - 10)))) THEN

bDX <= 0;

END IF;

IF (ballX < innerArenaLeft + ballSize AND (((ballY < nettop) OR (ballY > netbottom)))) THEN

bDX <= 1;

END IF;

--left paddle hit
IF(ballX < leftPaddlePosX + paddlewidth AND (ballY > leftPaddlePosY AND ballY < leftPaddlePosY + paddleheight)) THEN

bDX <= 1;

END IF;

--right paddle hit
IF(ballX > rightPaddlePosX - 2*paddlewidth  AND (ballY > rightPaddlePosY AND ballY < rightPaddlePosY + paddleheight )) THEN

bDX <= 0;

END IF;

END IF;


        END IF;
    END PROCESS;

end Behavioral;
