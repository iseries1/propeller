'******************************************************************************
' Test Program for the C Function Library in Spin
' Author: Dave Hein
' Copyright (c) 2010
' See end of file for terms of use.
'******************************************************************************
'******************************************************************************
' Revison History
' v1.0 - 4/2/2010 First official release
'******************************************************************************
{{
  This is a test program for the C function library written in spin.  This
  program tests out the various string, I/O and memory allocation functions
  that are in the library.
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ
  c : "clib"

PUB main | i, j, x, str, str1, arglist[10], port
' Initialize the C library and wait for a key press
  c.start
  c.getchar

' Allocate 100 bytes of memory and test strcpy, strcat and printf
  str := c.malloc(100)
  c.strcpy(str, string("This"))
  c.strcat(str, string(" is"))
  c.strcat(str, string(" a"))
  c.strcat(str, string(" test.\n"))
  c.printf0(str)

' Use gets and puts to read a string and print it out
  c.puts(string("Enter string: "))
  c.gets(str)
  c.puts(str)
  c.putchar(13)

' Read two numbers and print them out using scanf and printf
  c.puts(string("Enter a decimal number and a hex number: "))
  c.scanf2(string("%d %x"), @i, @j)
  c.printf2(string("%d %x\n"), i, j)

' Read a floating point number using gets and sscanf, and print it out with printf
  c.puts(string("Enter a floating point number: "))
  c.gets(str)
  c.sscanf1(str, string("%f"), @x)
  c.printf2(string("%f %e\n"), x, x)

' Print out floating point numbers from 2^-32 to 2^32
  c.printf0(string("Press any key to run the floating-point print test\n"))
  c.getchar 
  repeat i from -32 to 32
    x := 1.0
    x += i << 23 'Adjust the exponent
    c.printf3(string("2.0^(%3d) = %16.5f, %13.6e\n"), i, x, x)

' Test itoa by printing out $6789abcd in base 16, 8, 4 and 2
  c.printf0(string("Press any key to continue\n"))
  c.getchar 
  i := 16
  j := $6789abcd
  repeat while (i > 1)
    c.itoa(j, str, i)
    c.printf3(string("%s, base %d, len = %d\n"), str, i, strsize(str))
    i >>= 1

' Allocate 2000 bytes for str1, and test strcmp and strncmp
  str1 := c.malloc(2000)
  c.strcpy(str, string("+12345"))
  c.strcpy(str1, string("+1234"))
  repeat 3
    c.printf2(string("strlen(%s) = %d\n"), str1, STRSIZE(str1))
    c.printf3(string("strcmp(%s, %s) = %d\n"), str, str1, c.strcmp(str, str1))
    c.printf3(string("strncmp(%s, %s, 6) = %d\n"), str, str1, c.strncmp(str, str1, 6))
    c.strcat(str1, string("5"))

' Test isdigit function
  c.printf2(string("isdigit(%c) = %d\n"), BYTE[str][0], c.isdigit(BYTE[str][0]))
  c.printf2(string("isdigit(%c) = %d\n"), BYTE[str][1], c.isdigit(BYTE[str][1]))

' Test sprintf
  c.sprintf2(str, string("sprintf test %03d %.3d\n"), 34, 35)
  c.puts(str)

' Test vprintf
  repeat i from 0 to 9
    arglist[i] := i
  c.vprintf(string("%d %d %d %d %d %d %d %d %d %d\n"), @arglist)

' Test malloc and free
  c.printf0(string("Press any key to run the malloc test\n"))
  c.getchar 
  c.printf1(string("malloc(1000) = %04x\n"), arglist[0] := c.malloc(1000))
  c.printf1(string("malloc(2000) = %04x\n"), arglist[1] := c.malloc(2000))
  c.printf1(string("malloc(4000) = %04x\n"), arglist[2] := c.malloc(4000))
  c.printf1(string("malloc(8000) = %04x\n"), arglist[3] := c.malloc(8000))
  c.printf1(string("malloc(16000) = %04x\n"), arglist[4] := c.malloc(16000))
  c.printf1(string("free(%04x)\n"), arglist[3])
  c.free(arglist[3])
  c.printf1(string("free(%04x)\n"), arglist[2])
  c.free(arglist[2])
  c.printf1(string("malloc(16000) = %04x\n"), arglist[4] := c.malloc(16000))
  repeat i from 0 to 4
    c.free(arglist[i])

' Open a new serial port and test it
  c.printf0(string("Second Seial Port Test\n"))
  c.printf0(string("Press any key when ready\n"))
  c.getchar 
  port := c.openserial(16, 16, 0, 300, 128, 128)
  repeat i from 1 to 10
    c.vfprintf(port, string("Test line %d\n"), @i)
    c.fgets(str, 100, port)
    c.printf1(string("String received: %s\n"), str)

' Test multi-cog prints
  c.printf0(string("Press any key to start the multi-cog print test\n"))
  c.getchar
  waitflag := 1
  cognew(MultiCogPrintTest, @stack1)
  cognew(MultiCogPrintTest, @stack2)
  cognew(MultiCogPrintTest, @stack3)
  cognew(MultiCogPrintTest, @stack4)
  MultiCogPrintTest

  c.printf0(string("Test program completed\n"))

DAT
  waitflag long 0
  stack1   long 0[100]
  stack2   long 0[100]
  stack3   long 0[100]
  stack4   long 0[100]

' This routine waits for cog 0 to clear the waitflag, and all the cogs print at the same time
PUB MultiCogPrintTest | i
  repeat i from 1 to 4
    if (cogid == 0)
      waitflag := 0
    repeat while (waitflag)
    c.printf2(string("Print %d from cog %d\n"), i, cogid)
    waitflag := 1
    if (cogid == 0)
      waitcnt(clkfreq+cnt)
      c.putchar(13)

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