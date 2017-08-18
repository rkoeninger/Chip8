class ScreenBuffer() {
    shared Integer width = 64;
    shared Integer height = 32;
    shared Array<Boolean> buffer = Array.ofSize(width * height, false);

    shared void clear() {
        for (index in 0:buffer.size) {
            buffer[index] = false;
        }
    }

    /*
     * Flips pixel at (x, y).
     * Returns true if pixel was unset by this operation.
     */
    shared Boolean flipPixel(Integer x, Integer y) {
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
}
