{{

  Stepper Motor Driver Demo Program
  Don Starkey  Don@StarkeyMail.com
  
  Uses a step & direction type motor driver.

  This is a general propose trapezoidal profile stepper motor driver.
   It accelerates the motor up to the command speed, moves a distance then decelerates to a stop at the commanded distance.
   Both the acceleration and deceleration portions of the profile take 250 steps each.
   This profile is based on an acceleration coefficient table located at the bottom of this program.
   
   If you want to move 1000 steps, 1000-(2*250)=500 steps will be at the commanded speed.
   

  Current version 1.0 11/14/2010

   I/O 16, Pin 21     - Step+ Pin
   I/O 17, Pin 22     - Direction+ Pin (Must be 1 Pin ABOVE Step Pin)
     
   I/O 20, Pin 25     - Home Switch, Active LOW  (When LOW, the home switch is closed, can't move in the negative direction when closed)                          

   I/O 28, Pin 37     - SCL I2C (not used by this program)
   I/O 39, Pin 38     - SDA I2C (not used by this program)
   I/O 30, Pin 39     - Serial  (not used by this program)
   I/O 31, Pin 40     - Serial  (not used by this program)

 Usage: Start(Step_Pin,Home_Switch_Pin,@Parameter_TableAddress,@StepTable) to initialize PASM cog.

         Move(Speed,Distance) where speed is maximum speed in steps per second, Distance in steps. (+/- value for forward/backwards).
         In Negative Direction, closing the home switch will stop movement and set the flag that an over travel condition has occurred.
         Enable(state) where state 0=disabled, release control of step & direction pins, 1=Enabled, drive step & direction pins.
         If Frequency is set to = 0 then motion stops immediately.
         Frequency can be changed on the fly.
}}
  

CON                  
  _CLKMODE      = XTAL1 + PLL16X                         
  _XINFREQ      = 5_000_000

  StepPin       = 16                                    ' Pin number for Step Pin, Direction Pin=Step Pin + 1                            
  HomeSwPin     = 20                                    ' Home Limit Switch, Active LOW = at home position or over traveled in negative direction


VAR

    ' Stepper motion profile parameters & Memory location bias
    long    Frequency       ' +0  Step Speed in Hz. for the traverse (maximum speed) portion of the trapezoidal move.
    long    Distance        ' +4  Step Distance in Steps  (positive values will move in the positive direction
                            '     negative values will move in the negative direction and will stop immediately if the home/limit input goes low)
    long    StepEnable      ' +8  Enable Stepper Routine
                            '      0=Disabled = no motion and releases control of the Step/Direction Outputs,
                            '        Make changes to Freq & Dist when disabled,
                            '      1=Enabled. Start moving stepper motor & Honor Home Switch = Over travel (negative direction only)

    long    StepFlags       ' +12 Stepper Flags (set by the PASM code to indicate what is going on)
                            '         Flag:Bit 0 = not used
                            '         Flag:Bit 1 = Over travel Condition Exists
                            '         Flag:Bit 2 = Not used
                            '         Flag:Bit 3 = Moving, 1=Moving, 0=Stopped
        
    Long     MotorAt        ' +16 Real-Time Motor Position (in step counts). Can be preset when StepEnable==0


OBJ
    Stepper     :"_StepDriver"
    LCD         :"LCD_16X2_8BIT"                        ' Load the LCD driver of your choice, not required.

    
PUB Start 


    Dira[0..31]~                ' Release all I/O pins 

    LCD.start                   ' Start the LCD Driver (not required)

    StepEnable:=0               ' Disable stepper routine when it gets loaded. Must be cleared to load values below.
    Frequency:=0                ' Clear frequency of steps in steps/second at maximum speed
    Distance:=0                 ' Clear distance to move (RELATIVE MOVES ONLY)
    StepFlags:=0                ' Clear flags
    MotorAt:=0                  ' Clear the absolute motor position to 0

    stepper.start(StepPin,HomeSwPin,@Frequency,@STable) ' Start the PASM cog. Pass it the STEP pin number, the HOME switch pin number (active LOW)
                                                        ' The address of the Motion variables and the address of the step table.
    '===============================================
    ' Lets do some demo moves using the PASM cog.

    ' You only need to:
    '   1. Set the enable flag to 0
    '   2. Set the frequency in steps/second (when moving at full speed)
    '   3. Set the distance to move as a positive or negative RELATIVE distance.
    '   4. Set the enable flag to 1 to start the move. It will be cleared to 0 when the move is finished.
    '   5. Monitor the moving bit( bit 3) of the flags to determine if the move has finished

    '===============================================


    if ina[HomeSwPin]==0        ' if the limit switch is closed then
      move(4000,200,1)          ' move 200 count RELATIVE in the positive direction to move away from home / limit switch
      waitcnt(clkfreq/4+cnt)


    move(1000,-10000,1)         ' 10000 count RELATIVE move until the limit switch is hit.
    waitcnt(clkfreq+cnt)
    MotorAt:=0                  ' set the absolute motor position to 0

    move(500,500,1)             ' move off limit switch at 500 steps/second. It won't reach full speed since accel/decel require 250 steps
    waitcnt(clkfreq+cnt)

    move(500,1000,1)            ' move RELATIVE 1000 steps at 100 steps/second. 250 Steps to ramp up, move at 100 steps/second for 500 steps, 250 steps to ramp down
    waitcnt(clkfreq+cnt)

    move(2000,2000,1)           ' move RELATIVE 2000 steps in positive direction at 2000 steps/second
    waitcnt(clkfreq+cnt)

    move(4000,3000,1)           ' move RELATIVE 3000 steps in positive direction at 4000 steps/second
    waitcnt(clkfreq+cnt)

    move(3000,-3000,1)          ' move RELATIVE 3000 steps in negative direction at 3000 steps/second
    waitcnt(clkfreq+cnt)

    move(4000,-2000,1)          ' move RELATIVE -2000 steps in negative direction at 4000 steps/second
    waitcnt(clkfreq+cnt)

    move(4000,-1000,1)          ' move RELATIVE -1000 steps in negative direction at 4000 steps/second
    waitcnt(clkfreq+cnt)
    
    move(5000,5432-MotorAt,1)   ' move to ABSOLUTE position 5432 at 5000 steps/second
    waitcnt(clkfreq+cnt)

    move(5000,100-MotorAt,1)    ' move to ABSOLUTE position 100 at 5000 steps/second
    waitcnt(clkfreq+cnt)
                 
    move(5000,3500-MotorAt,1)   ' move to ABSOLUTE position 3500 at 5000 steps/second
    waitcnt(clkfreq+cnt)
                 
    move(5000,0-MotorAt,1)      ' move to ABSOLUTE position 0 at 5000 steps/second
    waitcnt(clkfreq+cnt)        ' it might hit the limit switch and stop before reaching 0
                 
    move(1000,100-MotorAt,1)    ' move to ABSOLUTE position 10 at 1000 steps/second
    waitcnt(clkfreq+cnt)
                 
    move(5000,2000-MotorAt,1)   ' move to ABSOLUTE position 2000 at 5000 steps/second
    waitcnt(clkfreq+cnt)

    move(3000,100-MotorAt,1)    ' move to ABSOLUTE position 10 at 3000 steps/second
    waitcnt(clkfreq+cnt)

                                ' set 3'rd parameter to 0 to cause it to not wait for it to finish moving
    move(1000,8000,0)           ' move RELATIVE 8000 steps at 1000 steps/second, should take just over 8 seconds
    waitcnt(clkfreq * 9 + cnt)  ' wait 9 seconds to make sure we finished the move 

    move(1000,-8000,0)          ' move RELATIVE 8000 steps 1000 steps/second then change speeds after 2-seconds
                                ' set 3'rd parameter to 0 to cause it to not wait for it to finish moving
                                
    waitcnt(clkfreq *2 + cnt)   ' wait 2 seconds then change the frequency 
    frequency:=1100             ' change frequency on the fly
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1200              
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1300             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1400             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1500             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1400             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1300             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1200             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1100             
    waitcnt(clkfreq /2 + cnt)   ' wait 1/2 second then change frequency again 
    frequency:=1100             
    waitcnt(clkfreq + cnt)      ' wait 1 second to make sure we finished the move 

    move(5000,2000-MotorAt,1)   ' move to ABSOLUTE position 2000 at 5000 steps/second
    waitcnt(clkfreq+cnt)


    MoveChangeSpeed(3500,7000,8000)    ' Move RELATIVE 7000 steps at ever increasing speed
    waitcnt(clkfreq+cnt)
    
    MoveChangeSpeed(3500,-7000,8000)   ' Move RELATIVE -7000 steps at ever increasing speed
    waitcnt(clkfreq+cnt)
  
    
    ' Show demonstrate that the PASM routine has released control of the step & direction pins
    ' by driving step & direction pins from within SPIN

    '===============================================
    ' Lets do some demo moves using SPIN code
    '===============================================
    
    dira[StepPin]~~
    dira[StepPin+1]~~
    Outa[StepPin+1]~            ' set to negative direction

    repeat 1000                 ' Move 1000 steps in the negative direction
       outa[StepPin]~
       outa[StepPin]~~
       waitcnt(clkfreq/1000+cnt)

    waitcnt(clkfreq+cnt)
    
    outa[StepPin+1]~~            ' set to positive direction

    repeat 1000                  ' Move 1000 steps in the positive direction
       outa[StepPin]~
       outa[StepPin]~~
       waitcnt(clkfreq/900+cnt)

    '===============================================
    ' Done with the demo.
    '===============================================

    
PUB Move(_Speed,_Dist,Wait)

' Move _Distance steps Positive or Negative distances acceptable
' after acceleration is complete, move at _Speed steps/second.
' if Wait=1 then wait until movement is complete before returning
' if Wait=0 then return immediately after starting the move.

    if _dist
        StepEnable:=0

        ' Speed of stepper in steps/second
        Frequency := _speed

        ' Distance To Travel in Stepper steps
        Distance := _Dist
    
        StepEnable:=1
        repeat while (getflags & %1000)==0 ' wait until it start moving
    
        if wait ' wait for motion to complete before returning to calling code
            repeat while (stepflags & %1000) 'Monitor bit-3 of the flags to check for motion in progress
                lcd.move(1,1)                ' Display the current position on a LCD display (optional)
                lcd.fmtdec(MotorAt,8,0)
                waitcnt(clkfreq/20+cnt)       
                
          lcd.move(1,1)                      ' Show the final position once the move is done.
          lcd.fmtDEC(MotorAt,8,0)

PUB GetFlags
' Return Flags
'         Flag:Bit 0 =
'         Flag:Bit 1 = Over travel Condition Exists
'         Flag:Bit 2 = 
'         Flag:Bit 3 = Moving, 1=Moving, 0=Stopped

result:=StepFlags

pub MoveChangeSpeed(_Speed,_Dist,MaxSpeed)
' Move and change frequency while moving
' This routine is not necessary, just wanted to show that the speed can be changed while a move was in progress.
' Works the same as the MOVE() routine above but it increases the speed variable while waiting for the move to finish
' Set the MaxSpeed variable to limit how fast it can go (in steps/second)

    if _dist
        StepEnable:=0

        ' Speed of stepper in steps/second
        Frequency := _speed

        ' Distance To Travel in Stepper steps
        Distance := _Dist
    
        StepEnable:=1
        repeat while (getflags & %1000)==0 ' wait until it start moving

        repeat while (stepflags & %1000)
          frequency:=frequency+10 <# MaxSpeed' increase frequency while moving
          lcd.move(1,1)
          lcd.fmtdec(MotorAt,8,0)
                
        lcd.move(1,1)
        lcd.fmtDEC(MotorAt,8,0)


dat



Segments                long    250    ' How many segments in the Ramp table                             
STable                  long    2529822,1047887,804072,677864,597210,539919,496507,462137,434049,410534
                        long    390471,373090,357842,344324,332231,321330,311435,302402,294113,286469
                        long    279393,272816,266683,260946,255564,250502,245729,241219,236949,232897
                        long    229047,225382,221887,218549,215358,212303,209374,206564,203863,201266
                        long    198765,196356,194032,191788,189621,187526,185498,183535,181633,179789
                        long    178000,176263,174576,172937,171343,169792,168283,166813,165381,163985
                        long    162625,161297,160001,158736,157501,156294,155114,153961,152833,151730
                        long    150650,149592,148557,147543,146549,145576,144621,143685,142767,141866
                        long    140982,140115,139263,138426,137605,136798,136005,135225,134459,133706
                        long    132965,132236,131520,130814,130120,129437,128765,128103,127451,126809
                        long    126176,125553,124939,124334,123738,123150,122571,121999,121436,120880
                        long    120332,119791,119257,118731,118211,117698,117192,116692,116199,115712
                        long    115230,114755,114286,113822,113364,112912,112465,112023,111586,111154
                        long    110728,110306,109889,109476,109069,108665,108267,107872,107482,107096
                        long    106714,106337,105963,105593,105227,104865,104506,104151,103800,103452
                        long    103108,102767,102430,102095,101765,101437,101112,100791,100472,100157
                        long    99844,99535,99228,98924,98623,98324,98029,97736,97445,97157
                        long    96872,96589,96309,96031,95755,95482,95211,94943,94676,94412
                        long    94150,93891,93633,93378,93124,92873,92623,92376,92131,91887
                        long    91646,91406,91169,90933,90699,90466,90236,90007,89780,89555
                        long    89331,89109,88889,88670,88453,88238,88024,87811,87601,87391
                        long    87183,86977,86772,86569,86367,86166,85967,85769,85573,85377
                        long    85184,84991,84800,84610,84421,84234,84048,83863,83679,83497
                        long    83315,83135,82956,82778,82602,82426,82252,82078,81906,81735
                        long    81565,81396,81228,81061,80895,80730,80566,80403,80241,80080
                        long    80000 ' Traverse Speed (80_000_000/80_000 = 1000 steps/second)
                        
    


{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
