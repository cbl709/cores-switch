//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_defines.v                                              ////
////                                                              ////
////                                                              ////

// Uncomment this if you want your UART to have
// 16xBaudrate output port.
// If defined, the enable signal will be used to drive baudrate_o signal
// It's frequency is 16xbaudrate
//---------------------------------------------

// Line Control register bits
`define UART_LC_BITS	1:0	// bits in character
`define UART_LC_SB	    2	// stop bits
`define UART_LC_PE	    3	// parity enable
`define UART_LC_EP	    4	// even parity
`define UART_LC_SP	    5	// stick parity
`define UART_LC_BC	    6	// Break control
`define UART_LC_DL	    7	// Divisor Latch access bit
//----------------------------

// FIFO parameter defines

`define UART_FIFO_WIDTH	    8
`define UART_FIFO_DEPTH	    16
`define UART_FIFO_POINTER_W	4
`define UART_FIFO_COUNTER_W	5
// receiver fifo has width 11 because it has break, parity and framing error bits
`define UART_FIFO_REC_WIDTH  11


`define OSC               14746    // 14746 khz
`define RESET_PERIOD      10        // 10ms
`define BAUD              38400
`define DETECTION_TIME    500      //500ms，心跳检测判断时间
`define GAP_T             4        //帧之间传输间隔时间不小于4字节时间长度









