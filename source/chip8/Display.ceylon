import java.awt { Color, Dimension, Graphics }
import java.awt.event { ActionEvent, KeyAdapter, KeyEvent }
import java.io { JFile = File }
import java.lang { IntArray }
import java.util { Random }
import javax.swing { JFileChooser, JFrame, JMenu, JMenuBar, JMenuItem, JPanel }
import ceylon.collection { HashMap, MutableMap }
import ceylon.file { File, current, parsePath }

class Display() {
    variable Machine? machine = null;
    variable Integer scale = 16;
    Color bgColor = Color.\iBLACK;
    Color fgColor = Color.\iGREEN;
    MutableMap<Integer, Integer> keymap = HashMap<Integer, Integer>();
    keymap.put(KeyEvent.\iVK_0, #0);
    keymap.put(KeyEvent.\iVK_1, #1);
    keymap.put(KeyEvent.\iVK_2, #2);
    keymap.put(KeyEvent.\iVK_3, #3);
    keymap.put(KeyEvent.\iVK_4, #4);
    keymap.put(KeyEvent.\iVK_5, #5);
    keymap.put(KeyEvent.\iVK_6, #6);
    keymap.put(KeyEvent.\iVK_7, #7);
    keymap.put(KeyEvent.\iVK_8, #8);
    keymap.put(KeyEvent.\iVK_9, #9);
    keymap.put(KeyEvent.\iVK_A, #a);
    keymap.put(KeyEvent.\iVK_B, #b);
    keymap.put(KeyEvent.\iVK_C, #c);
    keymap.put(KeyEvent.\iVK_D, #d);
    keymap.put(KeyEvent.\iVK_E, #e);
    keymap.put(KeyEvent.\iVK_F, #f);

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
    value panel = object extends JPanel() {
        shared actual void paint(Graphics g) {
            g.color = bgColor;
            g.fillRect(0, 0, screenWidth * scale, screenHeight * scale);

            if (exists m = machine) {
                g.color = fgColor;
                for (x in 0:screenWidth) {
                    for (y in 0:screenHeight) {
                        if (m.getPixel(x, y)) {
                            g.fillRect(x * scale, y * scale, scale, scale);
                        }
                    }
                }
            }
        }
    };
    panel.setSize(screenWidth * scale, screenHeight * scale);
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    frame.resizable = false;

    void resize() {
        frame.setMinimumSize(Dimension(screenWidth * scale, screenHeight * scale));
        frame.pack();
    }

    resize();

    shared void setVisible(Boolean visible) {
        frame.setVisible(visible);
    }

    loadMenuItem.addActionListener((ActionEvent e) {
        value chooser = JFileChooser();
        chooser.currentDirectory = JFile(current.absolutePath.string);
        if (chooser.showOpenDialog(frame) == JFileChooser.approveOption) {
            value path = chooser.selectedFile.toPath().string;
            value resource = parsePath(path).resource;

            if (is File resource) {
                try (reader = resource.Reader()) {
                    value bytes = reader.readBytes(resource.size);
                    value data = IntArray(bytes.size);
                    variable Integer i = 0;
                    for (b in bytes) {
                        data[i++] = b.unsigned;
                    }
                    value m = Machine(data, ActualPeripherals());
                    machine = m;
                }
            }
        }
    });

    renderMenuItem.addActionListener((ActionEvent e) {
        panel.repaint();
    });

    frame.addKeyListener(object extends KeyAdapter() {
        shared actual void keyPressed(KeyEvent e) {
            value m = machine;
            if (exists m) {
                if (exists k = keymap.get(e.keyCode)) {
                    m.setKeyPressed(k, true);
                }
            }
            else if (e.keyCode == KeyEvent.\iVK_EQUALS && e.controlDown) {
                scale += 1;
                resize();
            }
            else if (e.keyCode == KeyEvent.\iVK_MINUS && e.controlDown) {
                scale -= 1;
                resize();
            }
        }

        shared actual void keyReleased(KeyEvent e) {
            value m = machine;
            if (exists m) {
                if (exists k = keymap.get(e.keyCode)) {
                    m.setKeyPressed(k, false);
                }
            }
        }
    });
}

class ActualPeripherals() satisfies Peripherals {
    Random r = Random();
    shared actual void beep() => print("beep!");
    shared actual Integer waitForKeyPressed() => 0;
    shared actual Integer rand() => r.nextInt(#100);
}
