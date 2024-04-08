# TCP-Gecko-ASM-Code-Handler

This PowerPC assembly code is meant to be assembled, processed and then included as a C header file in [TCP Gecko](https://github.com/BullyWiiPlaza/tcpgecko) (src/tcpgecko/code_handler.h).

# Requirements
To process the *codehandler.s* file, you need devkitPPC and [Binary2CCode](https://github.com/BullyWiiPlaza/Binary2CCode).

# Process
1. Run `powerpc-eabi-as` with the following configuration:
```cmd
powerpc-eabi-as -mregnames -mgekko codehandler.s -o codehandler.o
```
2. Then run `powerpc-eabi-objcopy` to get a binary file Binary2CCode can read.
```cmd
powerpc-eabi-objcopy -O binary codehandler.o codehandler.bin
```
3. Finally, run `Binary2CCode`.
```cmd
Binary2CCode.jar -b codeHandler -h code_handler.h -l 4 -i codehandler.bin
```
4. Place the generated header file in TCP Gecko. (src/tcpgecko/code_handler.h)
<br><br>
## Special Thanks:
- CosmoCortney for the original code handler.
- ShyGuy for writting the original Insert ASM cafe code types.
