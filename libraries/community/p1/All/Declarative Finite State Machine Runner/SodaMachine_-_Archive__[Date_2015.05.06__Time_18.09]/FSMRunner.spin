{{

Finite State Machine Runner
by Chris Cantrell
Version 1.0

See the end of this file for terms of use.

The FSM runner runs in a dedicated COG. It reads a state machine declaration
from a DAT section and manages the state transitions in response to events
injected into the running machine.

The declaration syntax includes function calls for the machine to make as it
moves from state to state. The machine will also call a function to accept
any pending events to be injected into the current state.

Each state begins with a label in the DAT section. States target each other
by using the address-of operator. For instance "@S0".

Each state ends with the text "@@" marker. The state is a list of event strings
and the action to do if that event arives in the machine while in the state.
Event names begin and end with the text "##". You are free to use any event
names you like. But you must not use "#" or "@" in the names since the runner
is watching for those tokens to parse the declaration.

The optional "##!##" event is executed whenever the state is entered.

The optional "##T##" event is executed whenever the specified timeout occurs.
The timeout value must follow the "##T##".

All events except the "##!##" require the address of a target state.

Events may also include a list of function to call (in order) as the transition
to a new state is made. SPIN does not offer pointers-to-functions. Instead, a
constants-table and a dispatch routine is used to translate a function number
to a function call. You may list zero or more function parameters after the
function name. These can be pointers within the data section or other numeric
values. It is up to your called function to decide how to use the parameters.

You separate multiple function calls with "%%".

These "edge" or "transition" functions usually return the value 0. But they may
return the address of another state instead. This gives the called code the
ability to alter the destination.

The declaration uses WORD instead of BYTE since pointers-to-states are 16 bits.
The syntax to switch back and forth between WORD and BYTE in a DAT section is
clunky. The declaration syntax looks much simpler if everything is WORD, but
that does waste space in the final binary. The string "##!##", for instance, is
10 bytes instead of 5.

Relying on the "##", "@@", and "%%" markers is a bit dangerous. These markers
might appear naturally in the function call parameters. The markers are four
bytes (two words), which reduces the chance of collision.

The following example from "SodaMachine.spin" shows an example state declaration.
Have a look at "SodaMachine.spin" for a complete and simple working example.

S0
  ' This is an "enter state" function. It is called anytime the state is entered.
  ' The "0" here is an argument to the function. You can list as many as you like
  ' or none at all. If you want to call multiple functions use the "%%" separator
  ' as in state "S15" below.
  word "##!##", FN_showDeposit, 0

  ' This is an example of a timeout function. After 50*100ms (5 seconds) the
  ' timeout goes back to state S0 and you get a free nickel. Again, just an
  ' example. Uncomment the next line to see the timeout in action.
'  word "##T##", 50,   @S0, FN_refundNickel

  ' These are events. The name of the event and the target state is required.
  ' You can also call one or more "edge" functions on the way to the target
  ' state. These edge functions can return a new destination state thus
  ' override the specified destination.
  word "##NICKEL##",  @S5
  word "##DIME##",    @S10
  word "##QUARTER##", @S25

  ' This is the marker for the end of the state
  word "@@"

}}

var
  ' This parameter block is shared by the state-machine-runner and the "main" program
  ' that responds to function requests.
  
  long reqResp       ' ENGINE sets to 1 for call request. HANDLER clears when handled.
  long nextState     ' Targeted next state (function may change the target)
  long currentState  ' Current state making the function call
  long funcNum       ' Function number (0 for getEvent)
  long funcNumParams ' Number of parameters passed to function
  long funcParamsPtr ' Function parameters

PUB init(firstState,base)
  ' The number of counts to wait for 50ms
  MS_50 := (clkfreq / 1_000) * 50
  '
  ptr_strConst := @str_const
  ptr_strTimer := @str_timer
  reqResp := base
  nextState := firstState
  cognew(@runner,@reqResp)
  repeat while reqResp<>0


{{
  These are accessor functions for the shared parameter block above
}}

PUB isFunctionRequest
  return reqResp
  
PUB getFunctionNumber
  return funcNum

PUB getNextState
  return nextState

PUB getCurrentState
  return currentState
  
PUB getFuncNumParams
  return funcNumParams
  
PUB getFunctionParamPtr
  return funcParamsPtr

PUB getFunctionParameter(i)
  return word[funcParamsPtr+i*2]

PUB replyToFunctionRequest(val)  
  funcNum := val  
  reqResp := 0

DAT

runner

        ' Pointers to the things we need
        '
        mov       ptr_reqResp,par
        '        
        mov       ptr_nextState,par
        add       ptr_nextState,#4
        '
        mov       ptr_currentState, par
        add       ptr_currentState, #8
        '
        mov       ptr_funcNum,par
        add       ptr_funcNum,#12
        '
        mov       ptr_funcNumParams,par
        add       ptr_funcNumParams,#16
        '
        mov       ptr_funcParamsPtr,par
        add       ptr_funcParamsPtr,#20
        

        ' Get the ptr to the data block
        rdlong    ptr_object, ptr_reqResp

        ' Start with the first state
        rdlong    curState,ptr_nextState    

        ' Clear the interface params        
        mov       tmp,#0
        wrlong    tmp,ptr_funcNum
        wrlong    tmp,ptr_nextState
        wrlong    tmp,ptr_currentState
        wrlong    tmp,ptr_funcNumParams
        wrlong    tmp,ptr_funcParamsPtr        
        wrlong    tmp,ptr_reqResp
                                      
enterState

        wrword   curState,ptr_currentState ' Our current state
         
        ' Handle any enter-state functions
        mov      p, ptr_strConst     ' Find the ...
        call     #findString         ' ... "entry" information
  if_z  jmp      #checkForTimer      ' Move on if there is none
        call     #callFuncs          ' Call the chain of functions    

checkForTimer
        ' Setup any timer event
        mov      timerCount,#0       ' In case there is no timer
        mov      timerChain,#0       ' In case there is no timer
        mov      p, ptr_strTimer     ' Find the ...
        call     #findString         ' ... "timer" information
  if_z  jmp      #withinState        ' Move on if there is none
        rdword   timerCount, q       ' Get the timer count value
        shl      timerCount,#1       ' 50ms ticks
        add      q,#2                ' Remember the ...
        mov      timerChain,q        ' ... function chain (or 0 if none)

withinState
        cmp      timerChain,#0 wz    ' Is there a time-out event?
  if_z  jmp      #doIdle             ' No ... skip checking it
        cmp      timerCount,#0 wz    ' Has the time-out expired?
  if_nz jmp      #doIdle             ' No ... ship processing it 
  
        mov      q,timerChain        ' Use the timer function chain

moveToNext        
        rdword   curState,q          ' Get the target state
        add      curState,ptr_object ' Offset now since the compiler can't
        add      q,#2                ' Point to fns
        
        call     #callFuncs          ' Call the chain of functions        
        jmp      #enterState         ' Start this state

doIdle                          
        
        ' Delay 50ms (fundamental tick rate of the engine)
        mov      tmp,cnt             ' Current count ...
        add      tmp,MS_50           ' ... plus 50ms
        waitcnt  tmp,0               ' Wait 50ms

        ' Call the GetEvent function           
        mov      fnNum,#0            ' Call ...
        mov      parCount,#0         ' ... the ...
        mov      q, #0               ' ... idle ...
        call     #callFunc           ' ... function
        cmp      tmp3,#0 wz          ' Is there an event?                          
   if_z jmp      #bottom             ' No ... end of this pass

        mov      p,tmp3              ' Look for the ...
        call     #findString         ' ... event
  if_nz jmp      #moveToNext         ' We found it. Now process it.

bottom
        sub      timerCount,#1       ' In case the timer is running
        jmp      #withinState        ' Back to top of state loop

' There can be any number of parameters to a function. But a single function
' will always end with "@@" or "##" or "%%". If it ends with "%%" then the
' caller will continue on through the next function.
'
' This function returns one-past the last marker value. The marker value
' is returned in repVal.
'
findEndOfParams
        mov      endPtr,q            ' Starting at q
        mov      repVal,C_FFFFFFFF   ' Last character read (none)

fe1     mov      tmp2, repVal        ' Keep up with last read
        rdword   repVal,endPtr       ' Read next character
        add      endPtr,#2           ' Next in memory
        cmp      repVal, tmp2 wz     ' Current and last the same?
  if_nz jmp      #fe1                ' No ... keep looking
        cmp      repVal,#$40 wz      ' Two @ ?
  if_z  jmp      #fe2                ' Yes ... done
        cmp      repVal,#$23 wz      ' Two # ?
  if_z  jmp      #fe2                ' Yes ... done
        cmp      repVal,#$25 wz      ' Two % ?
  if_nz jmp      #fe1                ' No ... keep looking

fe2
findEndOfParams_ret
        ret                

callFuncs
        call     #findEndOfParams    ' Get the end of the parameters for this function

        ' To make a function call, there must at least one value ... the FN number
        mov      parCount,endPtr     ' Are we ...
        sub      parCount,q          ' ... at the end ...
        sub      parCount,#4 wz      ' ... of the list (only the end marker found)?
  if_z  jmp      #callFuncs_ret      ' Yes ... done
        sub      parCount,#2         ' Don't count the FN number in the params
        shr      parCount,#1         ' Count of words
    
        rdword   fnNum,q             ' Function number
        add      q,#2                ' Pointer to params

        call     #callFunc           ' Call this function

        cmp      tmp3,#0 wz          ' The function may ...
  if_nz mov      curState,tmp3       ' ... redirect us

        mov      q,endPtr            ' Jump to the end of the list
        cmp      repVal, #$25 wz     ' Are there more functions in the list?
  if_z  jmp      #callFuncs          ' Yes ... go do them all             

callFuncs_ret
        ret

callFunc
        wrword   fnNum,ptr_funcNum           ' Store the function number
        wrword   parCount,ptr_funcNumParams  ' Store number of parameters
        wrword   q,ptr_funcParamsPtr         ' Store the ptr to the params
        wrword   curState,ptr_nextState      ' Store the target state
        mov      tmp3,#1                     ' Trigger ...
        wrword   tmp3,ptr_reqResp            ' ... the handler 

wait1   rdword   tmp3,ptr_reqResp wz         ' Has the handler responded?        
  if_nz jmp      #wait1                      ' No ... keep waiting
        rdword   tmp3,ptr_funcNum            ' Get the return value
        
callFunc_ret
        ret
        

findString
        ' p = target string
        ' curState = beginning of state
        ' return q = location (or 0 if not found)
        ' requrn zero-flag based on return value

        mov      q,curState          ' Start of state         

noMatch        
        mov      pp,p                ' Start of target string
        mov      qq,q                ' Start of location in state
        add      q,#2                ' Next time start here
        mov      atFound,#0          ' No marker passed
        mov      tmp,C_FFFFFFFF      ' There was no last character from state

checking
        mov      lastStChr,tmp       ' Remember the last character (watching for ## in target)    
        rdword   tmp,pp              ' Get the next target-string character                          
        add      pp,#2               ' Bump pointer
        rdword   tmp2,qq             ' Get the next state character
        add      qq,#2               ' Bump the pointer

        ' Check for end of state
        ' 
        cmp      tmp2, #$40 wz       ' Is this an @ character?
  if_nz jmp      #inp2               ' No ... move on
        rdword   tmp3,qq             ' Peek ahead
        cmp      tmp3, #$40 wz       ' Is the next last character an @ character?
  if_nz jmp      #inp2               ' No ... move on
        ' Return 0 if at end 
        mov      q,#0 wz             ' Two @s in a row ... end of the state. Not found.
        jmp      #findString_ret     ' Out 

        ' Make sure the characters match
        '
inp2    cmp      tmp,tmp2 wz         ' Do these characters match?        
  if_ne jmp      #noMatch            ' No ... reset try to next char in state

        ' Check input for end of string
        '
        cmp      tmp,#$23 wz         ' Is this a hash?
  if_nz jmp      #checking           ' No ... not an end mark
        cmp      lastStChr,#$23 wz   ' Was last character a hash?
  if_nz jmp      #checking           ' No ... not an end mark
        add      atFound,#1          ' There are 2 ##... one at beginning and one at end
        cmp      atFound,#2 wz       ' Got both start and end marks?
  if_nz jmp      #checking           ' No. Keep checking.

        mov      q,qq wz             ' qq points one past found string ... where the data is
        
findString_ret
        ret                          ' Out

MS_50              long 0              ' Filled in constant for 50ms delay
C_FFFFFFFF         long $FF_FF_FF_FF   ' Constant for all FFs

curState           long 0              ' Pointer to the current state

timerChain         long 0              ' Cache the pointer for this stat's timer chain
timerCount         long 0              ' Current timer count (if any)

lastStChr          long 0              ' Used in finding strings
atFound            long 0              ' Used in finding end of state

p                  long 0              ' General purpose
q                  long 0              '
pp                 long 0              '
qq                 long 0              '
tmp                long 0              '
tmp2               long 0              '
tmp3               long 0              '

fnNum              long 0
repVal             long 0
endPtr             long 0
parCount           long 0

ptr_reqResp        long 0              ' Pointers ...
ptr_nextState      long 0              ' ...
ptr_currentState   long 0              '
ptr_funcNum        long 0              ' ... to ...
ptr_funcNumParams  long 0              ' ... parameters ...
ptr_funcParamsPtr  long 0              ' ...

ptr_status         long 0              ' ...

ptr_object         long 0              ' Base object pointer (to fix up pointers in state spec)
'
ptr_strConst       long 0              ' Pointer to "##!##" (fixed up and filled in)
ptr_strTimer       long 0              ' Pointer to "##T##" (fixed up and filled in)

DAT                           
str_const word "##!##"
str_timer word "##T##"

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