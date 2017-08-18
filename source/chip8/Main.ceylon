import java.awt { Color }
import javax.swing { JFrame, JPanel }

class Main {
    static value scale = 4;
    shared static void render(ScreenBuffer screen, JPanel panel) {
        value g = panel.graphics;

        g.color = Color.white;
        g.fillRect(0, 0, panel.width, panel.height);

        g.color = Color.black;
        for (x in 0:screen.width) {
            for (y in 0:screen.height) {
                g.fillRect(x * scale, y * scale, scale, scale);
            }
        }
    }
    new create() {}
}

shared void main() {
    value processor = Machine();

    value panel = JPanel();
    //panel.width = processor.screen.width * scale;
    //panel.height = processor.screen.height * scale;

    value frame = JFrame("CHIP-8");
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    frame.pack();
    frame.setVisible(true);

    Main.render(processor.screen, panel);
}