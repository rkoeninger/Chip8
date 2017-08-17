import java.util { Random }

class Cpu() {
    Array<Integer> regs = Array.ofSize(#10, 0);
    Array<Integer> mem = Array.ofSize(#1000, 0);
    Array<Integer> stack = Array.ofSize(#10, 0);
    variable Integer pc = #200;
    variable Integer addr = 0;
    variable Integer pointer = 0;
    variable Integer delay = 0;
    variable Integer sound = 0;
    Random rand = Random();
    shared ScreenBuffer screen = ScreenBuffer();
    shared InputController input = InputController();

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

    void sreg(Integer index, Integer x) {
        if (exists _ = regs[index]) {
            regs[index] = x;
            return;
        }
        throw Exception();
    }

    Integer lmem(Integer index) {
        if (exists x = mem[index]) {
            return x;
        }
        throw Exception();
    }

    void smem(Integer index, Integer x) {
        if (exists _ = mem[index]) {
            mem[index] = x;
            return;
        }
        throw Exception();
    }

    void push(Integer x) {
        if (exists _ = stack[pointer]) {
            stack[pointer] = x;
            pointer++;
            return;
        }
        throw Exception();
    }

    Integer pop() {
        if (exists x = stack[pointer - 1]) {
            pointer--;
            return x;
        }
        throw Exception();
    }

    void cycle() {
        value opcode = lmem(pc).leftLogicalShift(8).and(lmem(pc + 1));

        if (execute(opcode)) {
            pc += 2;
        }

        if (delay > 0) {
            delay--;
        }

        if (sound > 0) {
            if (sound == 1) {
                // TODO: beep!
                print("beep!");
            }

            sound--;
        }
    }

    Boolean execute(Integer opcode) {
        variable Boolean increment = true;
        value [n0, n1, n2, n3] = splitWordToNibbles(opcode);

        if (opcode == #00e0) {
            screen.clear();
        }
        else if (opcode == #00ee) {
            pc = pop();
        }
        else if (n0 == 0) {
            // call RCA 1802 program at address n1n2n3
            throw Exception("RCA 1802 programs not supported");
        }
        else if (n0 == 1) {
            pc = opcode.and(#0fff);
            increment = false;
        }
        else if (n0 == 2) {
            push(pc);
            pc = opcode.and(#0fff);
            increment = false;
        }
        else if (n0 == 3 && lreg(n1) == opcode.and(#00ff)) {
            pc += 2;
        }
        else if (n0 == 4 && lreg(n1) != opcode.and(#00ff)) {
            pc += 2;
        }
        else if (n0 == 5 && lreg(n1) == lreg(n2)) {
            pc += 2;
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
        else if (opcode.and(#f00f) == #9000 && lreg(n1) != lreg(n2)) {
            pc += 2;
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
            // TODO: implement sprite rendering
            // draws a sprite at (reg[n1], reg[n2]) with width of 8px, height of (n3)px
            // sprite is read from memory starting at addr
            // addr is left unchanged
            // reg[f] is set to 1 if any pixels are flipped from set to unset
            //           set to 0 if that doesn't happen
        }
        else if (opcode.and(#f0ff) == #e09e && input.isKeyPressed(n1)) {
            pc += 2;
        }
        else if (opcode.and(#f0ff) == #e0a1 && !input.isKeyPressed(n1)) {
            pc += 2;
        }
        else if (opcode.and(#f0ff) == #f007) {
            sreg(n1, delay);
        }
        else if (opcode.and(#f0ff) == #f00a) {
            sreg(n1, input.waitForKeyPressed());
        }
        else if (opcode.and(#f0ff) == #f015) {
            delay = lreg(n1);
        }
        else if (opcode.and(#f0ff) == #f018) {
            sound = lreg(n1);
        }
        else if (opcode.and(#f0ff) == #f01e) {
            addr += lreg(n1);
        }
        else if (opcode.and(#f0ff) == #f029) {
            // TODO: implement font lookup
            // TODO: add font table
            // sets addr to the location of the sprite for the
            // character in reg[n1]
            // characters 0-F are represented in a 4x5 font
        }
        else if (opcode.and(#f0ff) == #f033) {
            value x = lreg(n1);
            smem(addr, x / 100 % 10);
            smem(addr + 1, x / 10 % 10);
            smem(addr + 2, x % 10);
        }
        else if (opcode.and(#f0ff) == #f055) {
            for (i in 0..n1) {
                smem(addr + i, lreg(i));
            }
        }
        else if (opcode.and(#f0ff) == #f065) {
            for (i in 0..n1) {
                sreg(i, lmem(addr + i));
            }
        }
        else {
            throw Exception("Invalid opcode");
        }

        return increment;
    }
}
