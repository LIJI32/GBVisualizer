# GBVisualizer

A simple demo demonstrating the use of two undocumented Gameboy Color registers, nicknamed PCM12 (FF76) and PCM34 (FF77), which can be used to read the current PCM amplitude of the 4 APU channels. The demo uses these registers to visualize music in an oscilloscope-like manner.

GBVisualizer was designed to work on and tested on a Gameboy Color. PCM12 and PCM34 are not likely to exist on an original Gameboy, but I do not have one to verify. As of Feburary 2016, not a single publicly released emulator emulates these two registers, so it will not work on any emulator.

Music for this demo is adapted from [my disassembly of Super Bomberman](https://github.com/LIJI32/superbomberman/tree/master/dboot/songs).
