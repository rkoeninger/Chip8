import java.awt { Color }
import java.awt.event { ActionEvent }
import java.util { Random }
import javax.swing { JFrame, JMenu, JMenuBar, JMenuItem, JPanel, UIManager }

class MainFrame {
    shared static Integer scale = 4;
    shared static void render(Machine machine, JPanel panel) {
        value g = panel.graphics;

        g.color = Color.\iBLACK;
        g.fillRect(0, 0, panel.width, panel.height);

        g.color = Color.\iGREEN;
        for (x in 0:width) {
            for (y in 0:height) {
                if (machine.getPixel(x, y)) {
                    g.fillRect(x * scale, y * scale, scale, scale);
                }
            }
        }
    }
    new create() {} // TODO: no better way to do this?
}

class ActualPeripherals() satisfies Peripherals {
    Random r = Random();
    shared actual void beep() => print("beep!");
    shared actual Integer waitForKeyPressed() => 0;
    shared actual Integer rand() => r.nextInt(#100);
}
