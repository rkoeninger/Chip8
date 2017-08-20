import java.awt { Color }
import java.awt.event { ActionEvent }
import java.util { Random }
import javax.swing { JFrame, JMenu, JMenuBar, JMenuItem, JPanel }

class Display() {
    Machine? machine = null;
    Integer scale = 4;
    Color background = Color.\iBLACK;
    Color foreground = Color.\iGREEN;

    // TODO: configurable key maps
    // TODO: per-rom key maps
    value loadMenuItem = JMenuItem("Load ROM...");
    value renderMenuItem = JMenuItem("Render Now");
    value fileMenu = JMenu("File");
    fileMenu.add(loadMenuItem);
    value displayMenu = JMenu("Display");
    displayMenu.add(renderMenuItem);
    value menuBar = JMenuBar();
    menuBar.add(fileMenu);
    menuBar.add(displayMenu);
    value panel = JPanel();
    panel.setSize(width * scale, height * scale);
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    // TODO: make frame stick to panel size
    // TODO: configurable pixel scaling (with hotkeys like Ctrl+, Ctrl-)
    //frame.resizable = false;
    //frame.pack();
    frame.setSize(width * scale + 100, height * scale + 100);

    shared void setVisible(Boolean visible) {
        frame.setVisible(visible);
    }

    void render() {
        value g = panel.graphics;

        g.color = background;
        g.fillRect(0, 0, panel.width, panel.height);

        if (exists machine) {
            g.color = foreground;
            for (x in 0:width) {
                for (y in 0:height) {
                    if (machine.getPixel(x, y)) {
                        g.fillRect(x * scale, y * scale, scale, scale);
                    }
                }
            }
        }
    }

    renderMenuItem.addActionListener((ActionEvent e) {
        render();
    });
}

class ActualPeripherals() satisfies Peripherals {
    Random r = Random();
    shared actual void beep() => print("beep!");
    shared actual Integer waitForKeyPressed() => 0;
    shared actual Integer rand() => r.nextInt(#100);
}
