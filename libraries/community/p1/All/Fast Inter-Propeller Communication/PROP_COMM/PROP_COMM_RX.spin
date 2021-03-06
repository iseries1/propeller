''************************************************
''*  Fast Prop-Prop Comm RX v1.0                 *
''*  Receives information quickly between Props  *
''*  Author: Brandon Nimon                       *
''*  Created: 16 September, 2009                 * 
''***********************************************************************************
''* Requires pull-down on communication line.                                       *
''*  TX Prop──┳──RX Prop                                                          *
''*            10K                                                                 *
''*                                                                                *
''* The difference in clock speed between the two Propellers cannot exceed 0.2%.    *
''* Transfers information at 2 instructions per bit (8 cycles).                     *
''* Data transfers have been tested at 100MHz with 0 errors. That is 12.5Mbaud.     *
''*                                                                                 *
''* Inputs at about 8.66 million bits per second (@80MHz), including PASM overhead. *
''* This ends up being 270K longs every second (over 1MB/s).                        *
''*                                                                                 *
''* Transmission methodology puts one high start cycle, and after each long (while  *
''* the next long in the buffer is being retrieved) line will remain low as a stop  *
''* bit. After entire buffer is received, an acknowledge bit is sent back on the    *
''* same line.                                                                      *
''*                                                                                 *
''* To be sure that both Propellers are operating at the same clockspeed, it may be *
''* good practice to send a $5555_5555 value as the first long. This cog should     *
''* check to make sure that value came through.                                     *
''***********************************************************************************  

CON
                                     
  BUFFER_SIZE = 512                                    ' longs to send and recieve (always sends all longs), must equal or greater than TX cog
  
OBJ

VAR

  '' DO NOT REARRANGE LONGS 
  long done
  long buffer[BUFFER_SIZE] 
  byte cogon, cog          

PUB recieve (pin)
'' starts RX cog

  stop
  done := 0              
  rxmask := |< pin
  cogon := (cog := cognew(@rx_entry, @buffer))
  return @buffer

PUB stop
'' Stops cog if running
              
  IF (cogon~)
    cogstop(cog)    

PUB waitrx
'' waits for input and returns it, or if it is already there just returns it

  REPEAT UNTIL done                                     ' wait until "done"                                        
  done := 0                                             ' this is after the recieve so it can recieve another set of messages while controll cog is doing other things
                                                        ' be aware that information could be overwritten if this is not copied to a perminant location after recieved
  RETURN @buffer                                        ' return address of input so it can be copied to perminant location

PUB waitrx_wd (watchdogms) | waitstart, waitlen
'' waits for input and returns it, or if it is already there just returns it
'' this will also time out based on the watchdogms time (time in milliseconds to wait)

  waitlen := clkfreq / 1_000 * watchdogms
  waitstart := cnt
  REPEAT UNTIL (done OR cnt - waitstart => waitlen)     ' wait until "done"
  IF (done)                                        
    done := 0                                           ' this is after the recieve so it can recieve another set of messages while controll cog is doing other things
                                                        ' be aware that information could be overwritten if this is not copied to a perminant location after recieved
    RETURN @buffer                                      ' return address of input so it can be copied to perminant location
  ELSE
    RETURN false

    
DAT
                        ORG 0
rx_entry
                        MOV     doneAddr, PAR
                        SUB     doneAddr, #4
                        MOV     OUTA, rxmask            ' set high
                        
rx_bloop                MOV     rxptr, PAR              ' get output buffer address
                        MOV     rxbidx, rxbsize         ' set for BUFFER_SIZE longs

rx_loop                 MOV     rxval, #0               ' clear current long
                        
                        WAITPEQ rxmask, rxmask          ' wait for high pulse from TX
                        
:loop                                           
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                        TEST    rxmask, INA      WC     ' get INA mask
                        RCL     rxval, #1               ' set value
                                                
                        WRLONG  rxval, rxptr            ' write current long to buffer
                        ADD     rxptr, #4               ' move write pointer one long

                        DJNZ    rxbidx, #rx_loop        ' do next long until done with buffer

                        WRLONG  rxnegone, doneAddr      ' tell the controlling cog all longs have been recieved

                        MOV     DIRA, rxmask            ' set output (set high earlier) -- this if for a simple ACK
                        MOV     DIRA, #0                ' set input
                        
                        JMP     #rx_bloop  

rxnegone                LONG    -1
rxbsize                 LONG    BUFFER_SIZE                          
rxmask                  LONG    0                       ' set in SPIN

rxval                   RES
rxptr                   RES   
rxbidx                  RES
doneAddr                RES

                        FIT 496                        
  
 