import java.util { Random }

class Machine(Peripherals peripherals) {
    shared Integer width = 64;
    shared Integer height = 32;
    Array<Integer> regs = Array.ofSize(#10, 0);
    Array<Integer> mem = Array.ofSize(#1000, 0);
    Array<Integer> stack = Array.ofSize(#10, 0);
    shared Array<Boolean> buffer = Array.ofSize(width * height, false);
    Array<Boolean> keys = Array.ofSize(#1, false);
    variable Integer pc = #200;
    variable Integer addr = 0;
    variable Integer pointer = 0;
    variable Integer delay = 0;
    variable Integer sound = 0;
    Random rand = Random();

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

    Boolean isKeyPressed(Integer x) {
        if (exists s = keys[x]) {
            return s;
        }
        throw Exception();
    }

    shared void setKeyPressed(Integer x, Boolean pressed) {
        // TODO: set/clear value in state array
        // TODO: trip a switch that waitForKeyPressed() could be waiting on
    }

    void clear() {
        for (index in 0:buffer.size) {
            buffer[index] = false;
        }
    }

    /*
     * Flips pixel at (x, y).
     * Returns true if pixel was unset by this operation.
     */
    Boolean flipPixel(Integer x, Integer y) {
        value index = y * width + x;
        if (exists original = buffer[index]) {
            buffer[index] = !original;
            return original;
        }
        throw Exception();
    }

    shared Boolean getPixel(Integer x, Integer y) {
        value index = y * width + x;
        if (exists p = buffer[index]) {
            return p;
        }
        throw Exception();
    }

    shared void init() {
        variable Integer i = 0;

        for (b in glyphs) {
            smem(i, b.leftLogicalShift(4));
            i++;
        }
    }

    shared void load(Array<Integer> rom) {
        variable Integer i = #200;

        for (b in rom) {
            smem(i, b);
            i++;
        }
    }

    shared void cycle() {
        value opcode = lmem(pc).leftLogicalShift(8).and(lmem(pc + 1));

        if (execute(opcode)) {
            pc += 2;
        }

        if (delay > 0) {
            delay--;
        }

        if (sound > 0) {
            if (sound == 1) {
                peripherals.beep();
            }

            sound--;
        }
    }

    Boolean execute(Integer opcode) {
        variable Boolean increment = true;
        value n0 = opcode.rightLogicalShift(12).and(#f);
        value n1 = opcode.rightLogicalShift(8).and(#f);
        value n2 = opcode.rightLogicalShift(4).and(#f);
        value n3 = opcode.and(#f);

        if (opcode == #00e0) {
            clear();
        }
        else if (opcode == #00ee) {
            pc = pop();
        }
        else if (n0 == 0) {
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
                sreg(#f, original.rightLogicalShift(7).and(#01));
            }
            else {
                throw Exception("Invalid opcode");
            }
        }
        else if (opcode.and(#f00f) == #9000 && lreg(n1) != lreg(n2)) {
            pc += 2;
        }
        else if (n0 == #a) {
            addr = opcode.and(#0fff);
        }
        else if (n0 == #b) {
            pc = lreg(0) + opcode.and(#0fff);
        }
        else if (n0 == #c) {
            sreg(n1, rand.nextInt(#100).and(opcode.and(#00ff)));
        }
        else if (n0 == #d) {
            value x = lreg(n1);
            value y = lreg(n2);
            value h = lreg(n3);
            variable Boolean unset = false;
            for (dy in 0:h) {
                value line = lmem(addr + dy);

                for (dx in 0:8) {
                    if (line.leftLogicalShift(7 - dx).and(#01) != 0) {
                        unset ||= flipPixel(x + dx, y + dy);
                    }
                }
            }
            sreg(#f, if (unset) then 1 else 0);
        }
        else if (opcode.and(#f0ff) == #e09e && isKeyPressed(n1)) {
            pc += 2;
        }
        else if (opcode.and(#f0ff) == #e0a1 && !isKeyPressed(n1)) {
            pc += 2;
        }
        else if (opcode.and(#f0ff) == #f007) {
            sreg(n1, delay);
        }
        else if (opcode.and(#f0ff) == #f00a) {
            sreg(n1, peripherals.waitForKeyPressed());
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
            addr = lreg(n1) * glyphWidth;
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
