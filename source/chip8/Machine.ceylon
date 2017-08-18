import java.util { Random }

class Machine() {
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
    shared SoundCard speaker = SoundCard();
    shared InputController input = InputController();
    value glyphWidth = 5;

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

    shared void init() {
        // 0
        smem(0, #f0);
        smem(1, #90);
        smem(2, #90);
        smem(3, #90);
        smem(4, #f0);
        // 1
        smem(5, #20);
        smem(6, #60);
        smem(7, #20);
        smem(8, #20);
        smem(9, #70);
        // 2
        smem(10, #f0);
        smem(11, #10);
        smem(12, #f0);
        smem(13, #80);
        smem(14, #f0);
        // 3
        smem(15, #f0);
        smem(16, #10);
        smem(17, #f0);
        smem(18, #10);
        smem(19, #f0);
        // 4
        smem(20, #90);
        smem(21, #90);
        smem(22, #f0);
        smem(23, #10);
        smem(24, #10);
        // 5
        smem(25, #f0);
        smem(26, #80);
        smem(27, #f0);
        smem(28, #10);
        smem(29, #f0);
        // 6
        smem(30, #f0);
        smem(31, #80);
        smem(32, #f0);
        smem(33, #90);
        smem(34, #f0);
        // 7
        smem(35, #f0);
        smem(36, #10);
        smem(37, #20);
        smem(38, #40);
        smem(39, #40);
        // 8
        smem(40, #f0);
        smem(41, #90);
        smem(42, #f0);
        smem(43, #90);
        smem(44, #f0);
        // 9
        smem(45, #f0);
        smem(46, #90);
        smem(47, #f0);
        smem(48, #10);
        smem(49, #f0);
        // A
        smem(50, #f0);
        smem(51, #90);
        smem(52, #f0);
        smem(53, #90);
        smem(54, #90);
        // B
        smem(55, #e0);
        smem(56, #90);
        smem(57, #e0);
        smem(58, #90);
        smem(59, #e0);
        // C
        smem(60, #f0);
        smem(61, #80);
        smem(62, #80);
        smem(63, #80);
        smem(64, #f0);
        // D
        smem(65, #e0);
        smem(66, #90);
        smem(67, #90);
        smem(68, #90);
        smem(69, #e0);
        // E
        smem(70, #f0);
        smem(71, #80);
        smem(72, #f0);
        smem(73, #80);
        smem(74, #f0);
        // F
        smem(75, #f0);
        smem(76, #80);
        smem(77, #f0);
        smem(78, #80);
        smem(79, #80);
    }

    shared void load(Array<Integer> rom) {

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
                speaker.beep();
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
                        unset ||= screen.flipPixel(x + dx, y + dy);
                    }
                }
            }
            sreg(#f, if (unset) then 1 else 0);
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
