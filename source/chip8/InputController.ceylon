// TODO: implement
class InputController() {
    Array<Boolean> state = Array.ofSize(#1, false);

    shared Boolean isKeyPressed(Integer x) {
        if (exists s = state[x]) {
            return s;
        }
        throw Exception();
    }

    shared Integer waitForKeyPressed() => 0;
}
