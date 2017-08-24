import java.awt { Color, Dimension, Font, Graphics }
import java.awt.event { ActionEvent, KeyAdapter, KeyEvent }
import java.io { JFile = File }
import java.lang { IntArray, Thread }
import java.util { Random }
import java.util.concurrent { BlockingQueue, SynchronousQueue }
import javax.swing { JColorChooser, JFileChooser, JFrame, JMenu, JMenuBar, JMenuItem, JPanel, SwingUtilities }
import ceylon.collection { HashMap, MutableMap }
import ceylon.file { File, current, parsePath }

class Display() {
    variable Machine? machine = null;
    variable Thread? thread = null;
    Integer minScale = 8;
    variable Integer scale = 16;
    variable Color fgColor = Color.\iWHITE;
    variable Color bgColor = Color.\iBLACK;
    BlockingQueue<Integer> keyQueue = SynchronousQueue<Integer>();
    MutableMap<Integer, Integer> keyMap = HashMap<Integer, Integer>();
    keyMap.put(KeyEvent.\iVK_X, #0);
    keyMap.put(KeyEvent.\iVK_1, #1);
    keyMap.put(KeyEvent.\iVK_2, #2);
    keyMap.put(KeyEvent.\iVK_3, #3);
    keyMap.put(KeyEvent.\iVK_Q, #4);
    keyMap.put(KeyEvent.\iVK_W, #5);
    keyMap.put(KeyEvent.\iVK_E, #6);
    keyMap.put(KeyEvent.\iVK_A, #7);
    keyMap.put(KeyEvent.\iVK_S, #8);
    keyMap.put(KeyEvent.\iVK_D, #9);
    keyMap.put(KeyEvent.\iVK_4, #c);
    keyMap.put(KeyEvent.\iVK_R, #d);
    keyMap.put(KeyEvent.\iVK_F, #e);
    keyMap.put(KeyEvent.\iVK_V, #f);
    keyMap.put(KeyEvent.\iVK_C, #b);
    keyMap.put(KeyEvent.\iVK_Z, #a);

    void doPaint(JPanel panel, Graphics g) {
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
            g.font = Font(g.font.family, g.font.style, scale * 3 / 2);
            value message = "Start by opening Machine > Load ROM...";
            value fontBounds = g.fontMetrics.getStringBounds(message, g);
            g.drawString(
                message,
                panel.width / 2 - fontBounds.centerX.integer,
                panel.height / 2 - fontBounds.centerY.integer);
        }
    }

    void doResize(JFrame frame, JPanel panel) {
        panel.preferredSize = Dimension(screenWidth * scale, screenHeight * scale);
        frame.pack();
    }

    void doZoomIn(JFrame frame, JPanel panel) {
        scale += 1;
        doResize(frame, panel);
    }

    void doZoomOut(JFrame frame, JPanel panel) {
        if (scale > minScale) {
            scale -= 1;
            doResize(frame, panel);
        }
    }

    void doLoadRom(JFrame frame, JPanel panel) {
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

                    machine = Machine(data, object satisfies Peripherals {
                        Random r = Random();
                        shared actual void beep() => print("beep!"); // TODO: implement beep
                        shared actual Integer rand() => r.nextInt(#100);
                        shared actual Integer waitForKeyPressed() => keyQueue.take();
                    });
                    SwingUtilities.invokeLater(() {
                        panel.repaint();
                    });
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
    }

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
        shared actual void paint(Graphics g) => doPaint(this, g);
    };
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    frame.resizable = false;
    doResize(frame, panel);

    shared void setVisible(Boolean visible) {
        frame.setVisible(visible);
    }

    loadMenuItem.addActionListener((ActionEvent e) {
        doLoadRom(frame, panel);
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
            if (exists k = keyMap.get(e.keyCode)) {
                machine?.setKeyPressed(k, true);
                keyQueue.offer(k);
            }
            else if (e.keyCode == KeyEvent.\iVK_EQUALS && e.controlDown) {
                doZoomIn(frame, panel);
            }
            else if (e.keyCode == KeyEvent.\iVK_MINUS && e.controlDown) {
                doZoomOut(frame, panel);
            }
            else if (e.keyCode == KeyEvent.\iVK_O && e.controlDown) {
                doLoadRom(frame, panel);
            }
        }

        shared actual void keyReleased(KeyEvent e) {
            if (exists k = keyMap.get(e.keyCode)) {
                machine?.setKeyPressed(k, false);
            }
        }
    });
}
