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
`define UART_LC_BITS    1:0 // bits in character
`define UART_LC_SB      2   // stop bits
`define UART_LC_PE      3   // parity enable
`define UART_LC_EP      4   // even parity
`define UART_LC_SP      5   // stick parity
`define UART_LC_BC      6   // Break control
`define UART_LC_DL      7   // Divisor Latch access bit
//----------------------------

// FIFO parameter defines

`define UART_FIFO_WIDTH     8
`define UART_FIFO_DEPTH     1024
`define UART_FIFO_POINTER_W 10
`define UART_FIFO_COUNTER_W 11
// receiver fifo has width 11 because it has break, parity and framing error bits
`define UART_FIFO_REC_WIDTH  11


`define OSC               14746    // 14746 khz
`define RESET_PERIOD      10       // 10ms 重启信号持续时间
`define BAUD              38400
`define DETECTION_TIME    500      //500ms，心跳检测判断时间,状态连续持续DETECTION_TIME ms才能对心跳信号作出判断
`define GAP_T             4        //帧之间传输间隔时间不小于4字节时间长度，8N1格式。如果格式更改需要在command_new，core文件中相应更改MAX_IDLE_T









