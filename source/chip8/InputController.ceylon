class InputController() {
    Array<Boolean> state = Array.ofSize(#1, false);

    shared Boolean isKeyPressed(Integer x) {
        if (exists s = state[x]) {
            return s;
        }
        throw Exception();
    }

    shared Integer waitForKeyPressed() => 0;

    shared void setKeyPressed(Integer x, Boolean pressed) {
        // TODO: set/clear value in state array
        // TODO: trip a switch that waitForKeyPressed() could be waiting on
    }
}
