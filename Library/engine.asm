ASSEMBLER_C64STUDIO = $01; 
ASSEMBLER_RETRODEVSTUDIO = $01; 
VIC.SPRITE_X_POS = $D000; 
VIC.SPRITE_Y_POS = $D001; 
VIC.SPRITE_X_EXTEND = $D010; 
VIC.CONTROL_1 = $D011; 
VIC.RASTER_POS = $D012; 
VIC.STROBE_X = $D013; 
VIC.STROBE_Y = $D014; 
VIC.SPRITE_ENABLE = $D015; 
VIC.CONTROL_2 = $D016; 
VIC.SPRITE_EXPAND_Y = $D017; 
VIC.MEMORY_CONTROL = $D018; 
VIC.IRQ_REQUEST = $D019; 
VIC.IRQ_MASK = $D01A; 
VIC.SPRITE_PRIORITY = $D01B; 
VIC.SPRITE_MULTICOLOR = $D01C; 
VIC.SPRITE_EXPAND_X = $D01D; 
VIC.SPRITE_COLLISION = $D01E; 
VIC.SPRITE_BG_COLLISION = $D01F; 
VIC.BORDER_COLOR = $D020; 
VIC.BACKGROUND_COLOR = $D021; 
VIC.CHARSET_MULTICOLOR_1 = $D022; 
VIC.CHARSET_MULTICOLOR_2 = $D023; 
VIC.BACKGROUND_COLOR_3 = $D024; 
VIC.SPRITE_MULTICOLOR_1 = $D025; 
VIC.SPRITE_MULTICOLOR_2 = $D026; 
VIC.SPRITE_COLOR = $D027; 
VIC.KEYBOARD_LINES = $D02F; 
VIC.CLOCK_SWITCH = $D030; 
CIA1.DATA_PORT_A = $DC00; 
CIA1.DATA_PORT_B = $DC01; 
CIA1.DATA_DIRECTION_REGISTER_A = $DC02; 
CIA1.DATA_DIRECTION_REGISTER_B = $DC03; 
CIA1.TIMER_A_LO_BYTE = $DC04; 
CIA1.TIMER_A_HI_BYTE = $DC05; 
CIA1.TIMER_B_LO_BYTE = $DC06; 
CIA1.TIMER_B_HI_BYTE = $DC07; 
CIA1.TIME_OF_DAY_CLOCK_10TH_SECONDS = $DC08; 
CIA1.TIME_OF_DAY_CLOCK_SECONDS = $DC09; 
CIA1.TIME_OF_DAY_CLOCK_MINUTES = $DC0A; 
CIA1.TIME_OF_DAY_CLOCK_HOURS_APM = $DC0B; 
CIA1.SERIAL_SYNC_IO = $DC0C; 
CIA1.IRQ_CONTROL = $DC0D; 
CIA1.CONTROL_REGISTER_A = $DC0E; 
CIA1.CONTROL_REGISTER_B = $DC0F; 
CIA2.DATA_PORT_A = $DD00; 
CIA2.DATA_PORT_B = $DD01; 
CIA2.DATA_DIRECTION_REGISTER_A = $DD02; 
CIA2.DATA_DIRECTION_REGISTER_B = $DD03; 
CIA2.TIMER_A_LO_BYTE = $DD04; 
CIA2.TIMER_A_HI_BYTE = $DD05; 
CIA2.TIMER_B_LO_BYTE = $DD06; 
CIA2.TIMER_B_HI_BYTE = $DD07; 
CIA2.TIME_OF_DAY_CLOCK_10TH_SECONDS = $DD08; 
CIA2.TIME_OF_DAY_CLOCK_SECONDS = $DD09; 
CIA2.TIME_OF_DAY_CLOCK_MINUTES = $DD0A; 
CIA2.TIME_OF_DAY_CLOCK_HOURS_APM = $DD0B; 
CIA2.SERIAL_SYNC_IO = $DD0C; 
CIA2.NMI_CONTROL = $DD0D; 
CIA2.CONTROL_REGISTER_A = $DD0E; 
CIA2.CONTROL_REGISTER_B = $DD0F; 
IRQ_RETURN_KERNAL = $EA81; 
IRQ_RETURN_KERNAL_KEYBOARD = $EA31; 
JOYSTICK_PORT_II = $DC00; 
JOYSTICK_PORT_I = $DC01; 
PROCESSOR_PORT = $01; 
KERNAL_IRQ_LO = $FFFE; 
KERNAL_IRQ_HI = $FFFF; 
SID.BASE = $D400; 
SID.FREQUENCY_LO_1 = $D400; 
SID.FREQUENCY_HI_1 = $D401; 
SID.PULSE_WIDTH_LO_1 = $D402; 
SID.PULSE_WIDTH_HI_1 = $D403; 
SID.CONTROL_WAVE_FORM_1 = $D404; 
SID.ATTACK_DECAY_1 = $D405; 
SID.SUSTAIN_RELEASE_1 = $D406; 
SID.FREQUENCY_LO_2 = $D407; 
SID.FREQUENCY_HI_2 = $D408; 
SID.PULSE_WIDTH_LO_2 = $D409; 
SID.PULSE_WIDTH_HI_2 = $D40A; 
SID.CONTROL_WAVE_FORM_2 = $D40B; 
SID.ATTACK_DECAY_2 = $D40C; 
SID.SUSTAIN_RELEASE_2 = $D40D; 
SID.FREQUENCY_LO_3 = $D40E; 
SID.FREQUENCY_HI_3 = $D40F; 
SID.PULSE_WIDTH_LO_3 = $D410; 
SID.PULSE_WIDTH_HI_3 = $D411; 
SID.CONTROL_WAVE_FORM_3 = $D412; 
SID.ATTACK_DECAY_3 = $D413; 
SID.SUSTAIN_RELEASE_3 = $D414; 
SID.FILTER_CUTOFF_LO = $D415; 
SID.FILTER_CUTOFF_HI = $D416; 
SID.FILTER_RESONANCE_VOICE_INPUT = $D417; 
SID.FILTER_MODE_VOLUME = $D418; 
SID.AD_CONVERTER_PADDLE_1 = $D419; 
SID.AD_CONVERTER_PADDLE_2 = $D41A; 
SID.OSCILLATOR_3_OUTPUT = $D41B; 
SID.ENV_GENERATOR_3_OUTPUT = $D41C; 
KERNAL.SCINIT = $FF81; 
KERNAL.IOINIT = $FF84; 
KERNAL.RAMTAS = $FF87; 
KERNAL.RESTOR = $FF8A; 
KERNAL.VECTOR = $FF8D; 
KERNAL.SETMSG = $FF90; 
KERNAL.LSTNSA = $FF93; 
KERNAL.TALKSA = $FF96; 
KERNAL.MEMBOT = $FF99; 
KERNAL.MEMTOP = $FF9C; 
KERNAL.SCNKEY = $FF9F; 
KERNAL.SETTMO = $FFA2; 
KERNAL.IECIN = $FFA5; 
KERNAL.IECOUT = $FFA8; 
KERNAL.UNTALK = $FFAB; 
KERNAL.UNLSTN = $FFAE; 
KERNAL.LISTEN = $FFB1; 
KERNAL.TALK = $FFB4; 
KERNAL.READST = $FFB7; 
KERNAL.SETLFS = $FFBA; 
KERNAL.SETNAM = $FFBD; 
KERNAL.OPEN = $FFC0; 
KERNAL.CLOSE = $FFC3; 
KERNAL.CHKIN = $FFC6; 
KERNAL.CHKOUT = $FFC9; 
KERNAL.CLRCHN = $FFCC; 
KERNAL.CHRIN = $FFCF; 
KERNAL.CHROUT = $FFD2; 
KERNAL.LOAD = $FFD5; 
KERNAL.SAVE = $FFD8; 
KERNAL.SETTIM = $FFDB; 
KERNAL.RDTIM = $FFDE; 
KERNAL.STOP = $FFE1; 
KERNAL.GETIN = $FFE4; 
KERNAL.CLALL = $FFE7; 
KERNAL.UDTIM = $FFEA; 
KERNAL.SCREEN = $FFED; 
KERNAL.PLOT = $FFF0; 
KERNAL.IOBASE = $FFF3; 
ENGINE.IRQ_WAIT_FLAGS = $02; 
ENGINE.GAME_MODE = $03; 
ENGINE.BUFFER_SWITCH = $04; 
ENGINE.CHAR_SWITCH = $05; 
ENGINE.BUFFER_POINTER_HI = $06; 
ENGINE.IRQ_WAIT_FLAGS.PENDING_OVERDRAW = $01; 
ENGINE.IRQ_WAIT_FLAGS.OVERDRAW_REACHED = $02; 
ENGINE.IRQ_WAIT_FLAGS.CLEARED = $03; 
ENGINE.GAME_MODE.MENU = $01; 
ENGINE.GAME_MODE.GAMEPLAY = $02; 
ENGINE.VIC_BUFFER_1 = $80; 
ENGINE.VIC_BUFFER_2 = $90; 
ENGINE.VIC_UI_CHAR = $01; 
ENGINE.VIC_GAME_CHAR = $0B; 
ENGINE.SAVE_FILE = $0200; 
ENGINE.SCRIPT_PRG = $0400; 
ENGINE.CORE_PRG = $2000; 
ENGINE.UI_CHAR = $4000; 
ENGINE.CORE_SPRITE = $4800; 
ENGINE.BUFFER_1 = $6000; 
ENGINE.BUFFER_2 = $6400; 
ENGINE.LEVEL_CHAR = $6800; 
ENGINE.LEVEL_SPRITE = $7000; 
ENGINE.LEVEL_QUIET_MUSIC = $8000; 
ENGINE.LEVEL_DYNAMIC_MUSIC = $8800; 
ENGINE.LEVEL_SFX = $9000; 
ENGINE.LEVEL_TILES = $9800; 
ENGINE.LEVEL_MAP = $AC00; 
ENGINE.COLOR_BACK_BUFFER = $BC00; 
ENGINE.ENTITY_MEMORY = $C000; 
ENGINE.START = $2000; unused
ENGINE.GAME_LOOP = $2056; 
ENGINE.GAME_LOOP.RUN_LEVEL_SCRIPT = $2062; 
ENGINE.GAME_LOOP.DRAW_MENU = $2068; 
ENGINE.GAME_LOOP.RUN_MAIN_SCRIPT = $206B; 
ENGINE.RENDER_LOOP = $2072; 
ENGINE.IRQ.MENU = $2089; 
ENGINE.IRQ.CHAIN = $2098; 
ENGINE.IRQ.GAMEPLAY = $209B; unused
ENGINE.SWAP_BUFFERS = $209C; 
ENGINE.GO_MENU_MODE = $20B0; 
ENGINE.SUBSCRIBE.LEVEL_LOOP = $20CE; unused
ENGINE.SUBSCRIBE.MAIN_LOOP = $20D5; unused
MENU.OPTIONS.LO = $10; 
MENU.OPTIONS.HI = $11; 
MENU.OPEN = $12; 
MENU.SELECTION = $14; 
MENU.CHOICE_POINTER.LO = $15; 
MENU.CHOICE_POINTER.HI = $16; 
MENU.CHOICE.X = $17; 
MENU.CHOICE.Y = $18; 
MENU.CHOICE_DIMENSIONS.X = $19; 
MENU.CHOICE_DIMENSIONS.Y = $1A; 
MENU.B = $1B; 
MENU.C = $1C; 
MENU.CURRENT_CHOICE = $1D; 
MENU.INPUT_ACTIVE = $1E; 
MENU.SELECTED = $1F; 
MENU.ELEMENT.END = $00; 
MENU.ELEMENT.TEXT = $01; 
MENU.ELEMENT.ICON = $02; 
MENU.ELEMENT.CHOICE = $03; 
MENU.ELEMENT.CHOICE.ON_SELECT = $04; 
MENU.ELEMENT.CHOICE.ON_CHOSEN = $05; 
MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN = $06; 
MENU.ELEMENT.BACKGROUND = $07; 
MENU.NEW = $20DC; unused
MENU.END = $20ED; 
MENU.SUBSCRIBE_INPUT = $20F8; unused
MENU.INTERPRET.EXIT = $2123; 
MENU.INTERPRET = $2124; 
MENU.INTERPRET.INSTRUCTION.LOOP = $2147; 
MENU.INTERPRET.INSTRUCTION.JUMP_TABLE = $2158; 
MENU.INTERPRET.INSTRUCTION.TEXT = $2170; 
MENU.INTERPRET.INSTRUCTION.TEXT.LOOP = $2182; 
MENU.INTERPRET.INSTRUCTION.TEXT.EXIT = $2198; 
MENU.INTERPRET.INSTRUCTION.ICON = $2199; 
MENU.INTERPRET.INSTRUCTION.CHOICE = $219A; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_SELECT = $21A7; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_SELECT.ABORT = $21B5; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN = $21BC; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN.ABORT = $21C6; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN = $21CD; 
MENU.INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN.ABORT = $21D7; 
MENU.INTERPRET.INSTRUCTION.BACKGROUND = $21DE; 
MENU.INTERPRET.NEXT_BYTE = $21E2; 
MENU.INTERPRET.NEXT_BYTE.EXIT = $21ED; 
MENU.INTERPRET.GO_POINTER = $21EE; 
MENU.INTERPRET.GO_POINTER.JUMP = $21FA; 
MENU.INTERPRET.ON_UP_PRESSED = $21FE; 
MENU.INTERPRET.ON_UP_PRESSED.EXIT = $2206; 
MENU.INTERPRET.ON_DOWN_PRESSED = $220A; 
MENU.INTERPRET.ON_DOWN_PRESSED.EXIT = $2218; 
MENU.INTERPRET.ON_LEFT_PRESSED = $221C; 
MENU.INTERPRET.ON_LEFT_PRESSED.EXIT = $2224; 
MENU.INTERPRET.ON_RIGHT_PRESSED = $2228; 
MENU.INTERPRET.ON_RIGHT_PRESSED.EXIT = $2236; unused
MENU.INTERPRET.ON_FIRE_PRESSED = $223A; 
MENU.INTERPRET.CHANGE_CHOSEN = $2241; 
MENU.INTERPRET.CHANGE_CHOSEN.LOOP = $2249; 
MENU.INTERPRET.CHANGE_CHOSEN.EXIT = $2253; unused
MENU.FINALIZE_SELECTION = $2256; 
INPUT.JOY.IN = $20; 
INPUT.JOY.OLD = $21; 
INPUT.KEY.IN = $26; 
INPUT.KEY.OLD = $27; 
INPUT.JOY.CHANGED.ON = $28; 
INPUT.JOY.CHANGED.OFF = $29; 
INPUT.JOY.RESET = $225D; 
INPUT.JOY.POLL = $229E; 
INPUT.JOY.TEST = $22AA; 
INPUT.JOY.TEST.RIGHT_LEFT_TEST = $22C6; 
INPUT.JOY.TEST.FIRE_TEST = $22D2; 
INPUT.JOY.TEST.UP_DOWN_TEST.RELEASE = $22D8; 
INPUT.JOY.TEST.RIGHT_LEFT_TEST.RELEASE = $22E4; 
INPUT.JOY.TEST.FIRE_TEST.RELEASE = $22F0; 
INPUT.JOY.TEST.EXIT = $22F6; 
INPUT.JOY.TEST.UP = $22F7; 
INPUT.JOY.TEST.DOWN = $22FD; 
INPUT.JOY.TEST.RIGHT = $2303; 
INPUT.JOY.TEST.LEFT = $2309; 
INPUT.JOY.TEST.FIRE = $230F; 
INPUT.JOY.TEST.UP.RELEASE = $2315; 
INPUT.JOY.TEST.DOWN.RELEASE = $231B; 
INPUT.JOY.TEST.RIGHT.RELEASE = $2321; 
INPUT.JOY.TEST.LEFT.RELEASE = $2327; 
INPUT.JOY.TEST.FIRE.RELEASE = $232D; 
INPUT.KEY.POLL = $2333; 
INPUT.JOY.SUBSCRIBE.UP = $2340; 
INPUT.JOY.SUBSCRIBE.DOWN = $2347; 
INPUT.JOY.SUBSCRIBE.RIGHT = $234E; 
INPUT.JOY.SUBSCRIBE.LEFT = $2355; 
INPUT.JOY.SUBSCRIBE.FIRE = $235C; 
INPUT.JOY.SUBSCRIBE.UP.RELEASE = $2363; unused
INPUT.JOY.SUBSCRIBE.DOWN.RELEASE = $236A; unused
INPUT.JOY.SUBSCRIBE.RIGHT.RELEASE = $2371; unused
INPUT.JOY.SUBSCRIBE.LEFT.RELEASE = $2378; unused
INPUT.JOY.SUBSCRIBE.FIRE.RELEASE = $237F; unused
INPUT.DO_NOTHING = $2386; 
LOGIC.B = $30; 
LOGIC.SWITCH = $2387; 
LOGIC.SWITCH.JUMP = $239C; 
GRAPHICS.PUT_CHAR = $23A0; 
GRAPHICS.PUT_CHAR.ADDRESS = $23A9; 
GRAPHICS.PUT_COLOR = $23AD; 
GRAPHICS.PUT_COLOR.ADDRESS = $23B6; 
GRAPHICS.SET_CHAR_MULTICOLORS = $23BA; unused
MEMORY.FILL_4_PAGES = $23C4; unused
MEMORY.FILL_PAGES.LOOP = $23D5; 
MEMORY.COPY_4_PAGES = $23E5; 
MEMORY.COPY_PAGES.LOOP = $2405; 
ENGINE.MENU_START = $2421; 
