interface Instruction {
    shared formal String present();
}

object clear satisfies Instruction {
    shared actual String present() => "clear";
}

object ret satisfies Instruction {
    shared actual String present() => "ret";
}

class Goto(Integer lit) satisfies Instruction {
    shared actual String present() => "goto ``hex(lit)``";
}

class Call(Integer lit) satisfies Instruction {
    shared actual String present() => "call ``hex(lit)``";
}

class JumpEqualsLiteral(Integer reg, Integer lit) satisfies Instruction {
    shared actual String present() => "jump if V[``hex(reg)``] == ``hex(lit)``";
}

class JumpNotEqualsLiteral(Integer reg, Integer lit) satisfies Instruction {
    shared actual String present() => "jump if V[``hex(reg)``] != ``hex(lit)``";
}

class JumpEqualsRegister(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "jump if V[``hex(reg0)``] == V[``hex(reg1)``]";
}

class AssignLiteral(Integer reg, Integer lit) satisfies Instruction {
    shared actual String present() => "V[``hex(reg)``] = ``hex(lit)``";
}

class AddLiteral(Integer reg, Integer lit) satisfies Instruction {
    shared actual String present() => "V[``hex(reg)``] += ``hex(lit)``";
}

class AssignRegister(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] = V[``hex(reg1)``]";
}

class Or(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] |= V[``hex(reg1)``]";
}

class And(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] &= V[``hex(reg1)``]";
}

class Xor(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] ^= V[``hex(reg1)``]";
}

class Add(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] += V[``hex(reg1)``]";
}

class Subtract(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] -= V[``hex(reg1)``]";
}

class RightShift(Integer reg) satisfies Instruction {
    shared actual String present() => "V[``hex(reg)``] >>= 1";
}

class ReverseSubtract(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "V[``hex(reg0)``] = V[``hex(reg1)``] - V[``hex(reg0)``]";
}

class LeftShift(Integer reg) satisfies Instruction {
    shared actual String present() => "V[``hex(reg)``] <<= 1";
}

class JumpNotEqualsRegister(Integer reg0, Integer reg1) satisfies Instruction {
    shared actual String present() => "jump if V[``hex(reg0)``] != V[``hex(reg1)``]";
}

class MoveAddress(Integer lit) satisfies Instruction {
    shared actual String present() => "I = ``hex(lit)``";
}

class GotoOffset(Integer lit) satisfies Instruction {
    shared actual String present() => "PC = V[0] + ``hex(lit)``";
}

class Rand(Integer reg, Integer lit) satisfies Instruction {
    shared actual String present() => "V[``hex(reg)``] = rand() & ``hex(lit)``";
}

//class Draw(Integer reg0 Integer reg1, Integer h)

// TODO: the rest
