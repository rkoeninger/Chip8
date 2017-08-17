import java.util { Random }

class Cpu() {
    Array<Integer> regs = Array.ofSize(16, 0);
    variable Integer addr = 0; // TODO: what is initial value of I?
    Array<Integer> mem = Array.ofSize(4k, 0);
    variable Integer pc = 0; // TODO: what is intial value of PC?
    // TODO: delay timer
    // TODO: sound timer
    Random rand = Random();

    [Integer, Integer, Integer, Integer] splitWordToNibbles(Integer word) {
        return [
            word.rightLogicalShift(12).and(#f),
            word.rightLogicalShift(8).and(#f),
            word.rightLogicalShift(4).and(#f),
            word.and(#f)
        ];
    }

    Integer lreg(Integer index) {
        if (exists x = regs[index]) {
            return x;
        }
        throw Exception();
    }

    Integer sreg(Integer index, Integer x) {
        if (exists _ = regs[index]) {
            regs[index] = x;
        }
        throw Exception();
    }

    Integer lmem(Integer index) {
        if (exists x = mem[index]) {
            return x;
        }
        throw Exception();
    }

    Integer smem(Integer index, Integer x) {
        if (exists _ = mem[index]) {
            mem[index] = x;
        }
        throw Exception();
    }

    void run(Integer opcode) {
        value [n0, n1, n2, n3] = splitWordToNibbles(opcode);

        if (opcode == #00e0) {
            // clear the screen
        }
        else if (opcode == #00ee) {
            // return from a subroutine
        }
        else if (n0 == 0) {
            // call RCA 1802 program at address n1n2n3
        }
        else if (n0 == 1) {
            // jump to address n1n2n3
        }
        else if (n0 == 2) {
            // call subroutine at n1n2n3
        }
        else if (n0 == 3) {
            // skip next instruction if registers[n1] == n2n3
        }
        else if (n0 == 4) {
            // skip next instruction if registers[n1] != n2n3
        }
        else if (n0 == 5 && lreg(n1) == lreg(n2)) {
            // skip next instruction if registers[n1] == registers[n2]
        }
        else if (n0 == 8) {
            if (n3 == 0) {
                sreg(n1, lreg(n2));
            }
            else if (n3 == 1) {
                sreg(n1, lreg(n1).or(lreg(n2)));
            }
            else if (n3 == 2) {
                sreg(n1, lreg(n1).and(lreg(n2)));
            }
            else if (n3 == 3) {
                sreg(n1, lreg(n1).xor(lreg(n2)));
            }
            else if (n3 == 4) {
                value total = lreg(n1) + lreg(n2);
                sreg(n1, total.and(#ff));
                sreg(#f, if (total > #ff) then 1 else 0);
            }
            else if (n3 == 5) {
                value total = lreg(n1) - lreg(n2);
                sreg(n1, total.and(#ff));
                sreg(#f, if (total < 0) then 1 else 0);
            }
            else if (n3 == 6) {
                value original = lreg(n1);
                sreg(n1, original.rightLogicalShift(1).and(#ff));
                sreg(#f, original.and(#1));
            }
            else if (n3 == 7) {
                value total =  lreg(n2) - lreg(n1);
                sreg(n1, total.and(#ff));
                sreg(#f, if (total < 0) then 1 else 0);
            }
            else if (n3 == #e) {
                value original = lreg(n1);
                sreg(n1, original.leftLogicalShift(1).and(#ff));
                sreg(#f, original.rightLogicalShift(7).and(#1));
            }
            else {
                throw Exception("Invalid opcode");
            }
        }
        else if (opcode.and(#f00f) == #9000) {
            // skips next instruction if reg[n1] != reg[n2]
        }
        else if (opcode.and(#f000) == #a) {
            addr = opcode.and(#0fff);
        }
        else if (opcode.and(#f000) == #b) {
            pc = lreg(0) + opcode.and(#0fff);
        }
        else if (opcode.and(#f000) == #c) {
            sreg(n1, rand.nextInt(#100).and(opcode.and(#00ff)));
        }
        else if (opcode.and(#f000) == #d) {
            // draws a sprite at (reg[n1], reg[n2]) with width of 8px, height of (n3)px
            // sprite is read from memory starting at addr
            // addr is left unchanged
            // reg[f] is set to 1 if any pixels are flipped from set to unset
            //           set to 0 if that doesn't happen
        }
        else if (opcode.and(#f0ff) == #e09e) {
            // skips next instruction if key stored in reg[n1] is pressed
        }
        else if (opcode.and(#f0ff) == #e0a1) {
            // skips next instruction if key stored in reg[n1] is not pressed
        }
        else if (opcode.and(#f0ff) == #f007) {
            // sets reg[n1] to the value of the delay timer
        }
        else if (opcode.and(#f0ff) == #f00a) {
            // waits for a key press and then stores it in reg[n1]
        }
        else if (opcode.and(#f0ff) == #f015) {
            // sets delay timer to reg[n1]
        }
        else if (opcode.and(#f0ff) == #f018) {
            // sets sound timer to reg[n1]
        }
        else if (opcode.and(#f0ff) == #f01e) {
            // increases addr by reg[n1]
        }
        else if (opcode.and(#f0ff) == #f029) {
            // sets addr to the location of the sprite for the
            // character in reg[n1]
            // characters 0-F are represented in a 4x5 font
        }
        else if (opcode.and(#f0ff) == #f033) {
            // stores the BCD representaion of reg[n1] at addr, addr+1, addr+2
            // unsigned value of reg[n1]:
            // hundreds place at addr
            // tens place at addr+1
            // ones place at addr
        }
        else if (opcode.and(#f0ff) == #f055) {
            // stores reg[0] thru reg[n1] (inclusive)
            // starting at addr
            for (i in 0..(opcode.rightLogicalShift(8).and(#f))) {
                smem(addr + i, lreg(i));
            }
        }
        else if (opcode.and(#f0ff) == #f065) {
            // fills reg[0] thru reg[n1] (inclusive)
            // starting at addr
            for (i in 0..n1) {
                sreg(i, lmem(addr + i));
            }
        }
        else {
            throw Exception("Invalid opcode");
        }
    }
}
