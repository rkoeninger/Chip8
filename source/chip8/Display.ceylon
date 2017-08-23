import java.awt { Color, Dimension, Graphics }
import java.awt.event { ActionEvent, KeyAdapter, KeyEvent }
import java.io { JFile = File }
import java.lang { IntArray, Thread }
import java.util { Random }
import javax.swing { JColorChooser, JFileChooser, JFrame, JMenu, JMenuBar, JMenuItem, JPanel, SwingUtilities }
import ceylon.collection { HashMap, MutableMap }
import ceylon.file { File, current, parsePath }

class Display() {
    variable Machine? machine = null;
    variable Thread? thread = null;
    variable Integer scale = 16;
    variable Color fgColor = Color.\iWHITE;
    variable Color bgColor = Color.\iBLACK;
    MutableMap<Integer, Integer> keymap = HashMap<Integer, Integer>();
    keymap.put(KeyEvent.\iVK_X, #0);
    keymap.put(KeyEvent.\iVK_1, #1);
    keymap.put(KeyEvent.\iVK_2, #2);
    keymap.put(KeyEvent.\iVK_3, #3);
    keymap.put(KeyEvent.\iVK_Q, #4);
    keymap.put(KeyEvent.\iVK_W, #5);
    keymap.put(KeyEvent.\iVK_E, #6);
    keymap.put(KeyEvent.\iVK_A, #7);
    keymap.put(KeyEvent.\iVK_S, #8);
    keymap.put(KeyEvent.\iVK_D, #9);
    keymap.put(KeyEvent.\iVK_4, #a);
    keymap.put(KeyEvent.\iVK_R, #b);
    keymap.put(KeyEvent.\iVK_F, #c);
    keymap.put(KeyEvent.\iVK_V, #d);
    keymap.put(KeyEvent.\iVK_C, #e);
    keymap.put(KeyEvent.\iVK_Z, #f);

    // TODO: per-rom key maps
    value loadMenuItem = JMenuItem("Load ROM...");
    value renderMenuItem = JMenuItem("Render Now");
    value swapColorsMenuItem = JMenuItem("Swap Colors");
    value pickFgColorMenuItem = JMenuItem("Pick Foreground Color...");
    value pickBgColorMenuItem = JMenuItem("Pick Background Color...");
    value machineMenu = JMenu("Machine");
    value displayMenu = JMenu("Display");
    value menuBar = JMenuBar();
    machineMenu.add(loadMenuItem);
    displayMenu.add(renderMenuItem);
    displayMenu.add(swapColorsMenuItem);
    displayMenu.add(pickFgColorMenuItem);
    displayMenu.add(pickBgColorMenuItem);
    menuBar.add(machineMenu);
    menuBar.add(displayMenu);
    value panel = object extends JPanel() {
        shared actual void paint(Graphics g) {
            g.color = bgColor;
            g.fillRect(0, 0, screenWidth * scale, screenHeight * scale);
            g.color = fgColor;

            if (exists m = machine) {
                for (x in 0:screenWidth) {
                    for (y in 0:screenHeight) {
                        if (m.getPixel(x, y)) {
                            g.fillRect(x * scale, y * scale, scale, scale);
                        }
                    }
                }
            }
            else {
                g.font = Font(g.font.family, g.font.style, 24);
                value message = "Start by opening Machine > Load ROM...";
                value fontBounds = g.fontMetrics.getStringBounds(message, g);
                g.drawString(
                    message,
                    width / 2 - fontBounds.centerX.integer,
                    height / 2 - fontBounds.centerY.integer);
            }
        }
    };
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    frame.resizable = false;

    void resize() {
        panel.preferredSize = Dimension(screenWidth * scale, screenHeight * scale);
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
                    machine = Machine(data, ActualPeripherals());
                    thread = Thread(() {
                        while (true) {
                            value m = machine;
                            if (exists m) {
                                m.cycle();
                                SwingUtilities.invokeLater(() {
                                    panel.repaint();
                                });
                                Thread.sleep(16);
                            }
                            else {
                                break;
                            }
                        }
                    });
                    thread?.start();
                }
            }
        }
    });

    renderMenuItem.addActionListener((ActionEvent e) {
        panel.repaint();
    });

    swapColorsMenuItem.addActionListener((ActionEvent e) {
        value temp = bgColor;
        bgColor = fgColor;
        fgColor = temp;
    });

    pickFgColorMenuItem.addActionListener((ActionEvent e) {
        if (exists c = JColorChooser.showDialog(frame, "Foreground Color", fgColor)) {
            fgColor = c;
        }
    });

    pickBgColorMenuItem.addActionListener((ActionEvent e) {
        if (exists c = JColorChooser.showDialog(frame, "Background Color", bgColor)) {
            bgColor = c;
        }
    });

    frame.addKeyListener(object extends KeyAdapter() {
        shared actual void keyPressed(KeyEvent e) {
            if (exists k = keymap.get(e.keyCode)) {
                machine?.setKeyPressed(k, true);
            }
            else if (e.keyCode == KeyEvent.\iVK_EQUALS && e.controlDown) {
                scale += 1;
                resize();
            }
            else if (e.keyCode == KeyEvent.\iVK_MINUS && e.controlDown) {
                if (scale > 4) {
                    scale -= 1;
                    resize();
                }
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

// TODO: implement beep
// TODO: implement key input blocking
class ActualPeripherals() satisfies Peripherals {
    Random r = Random();
    shared actual void beep() => print("beep!");
    shared actual Integer waitForKeyPressed() => 0;
    shared actual Integer rand() => r.nextInt(#100);
}
