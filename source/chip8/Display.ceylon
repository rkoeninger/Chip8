import java.awt { BorderLayout, Color, Dimension, Graphics }
import java.awt.event { ActionEvent, KeyAdapter, KeyEvent }
import java.io { JFile = File }
import java.lang { IntArray, JString = String, Thread }
import java.util { Random }
import java.util.concurrent { BlockingQueue, SynchronousQueue }
import javax.swing {
    JColorChooser,
    JFileChooser,
    JFrame,
    JLabel,
    JMenu,
    JMenuBar,
    JMenuItem,
    JPanel,
    SwingUtilities
}
import javax.swing.border { EmptyBorder }
import ceylon.collection { HashMap, MutableMap }
import ceylon.file { File, current, parsePath }

class Display() {
    variable Machine? machine = null;
    Integer delayMs = 10;
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

    void doRepaintLater(JPanel panel) => SwingUtilities.invokeLater(() => panel.repaint());

    void doCycle(JPanel panel, JLabel label) {
        if (exists m = machine) {
            m.cycle();
            value builder = StringBuilder();
            builder.append(if (m.getKey(0)) then "0" else "_");

            for (i in 1..#f) {
                builder.append(" ");
                builder.append(if (m.getKey(i)) then hex(i).uppercased else "_");
            }

            label.text = builder.string;
            doRepaintLater(panel);
        }
    }

    void doLoadRom(JFrame frame, JPanel panel, JLabel label) {
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
                    value thread = Thread(() {
                        while (true) {
                            doCycle(panel, label);
                            Thread.sleep(delayMs);
                        }
                    });
                    thread.start();
                    doRepaintLater(panel);
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
    panel.border = EmptyBorder(10, 10, 10, 10);
    value label = JLabel("Start by opening Machine > Load ROM...");
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel, JString(BorderLayout.center));
    frame.contentPane.add(label, JString(BorderLayout.south));
    frame.defaultCloseOperation = JFrame.exitOnClose;
    frame.resizable = false;
    doResize(frame, panel);

    shared void setVisible(Boolean visible) => frame.setVisible(visible);

    loadMenuItem.addActionListener((ActionEvent e) => doLoadRom(frame, panel, label));

    renderMenuItem.addActionListener((ActionEvent e) => panel.repaint());

    swapColorsMenuItem.addActionListener((ActionEvent e) {
        value temp = bgColor;
        bgColor = fgColor;
        fgColor = temp;
    });

    pickFgColorMenuItem.addActionListener((ActionEvent e) {
        if (exists c = JColorChooser.showDialog(frame, "Foreground Color", fgColor)) {
            fgColor = c;
            doRepaintLater(panel);
        }
    });

    pickBgColorMenuItem.addActionListener((ActionEvent e) {
        if (exists c = JColorChooser.showDialog(frame, "Background Color", bgColor)) {
            bgColor = c;
            doRepaintLater(panel);
        }
    });

    frame.addKeyListener(object extends KeyAdapter() {
        shared actual void keyPressed(KeyEvent e) {
            if (exists k = keyMap.get(e.keyCode)) {
                machine?.setKeyPressed(k, true);
                keyQueue.offer(k);
            }
            else if (e.controlDown) {
                switch (e.keyCode)
                else case (KeyEvent.\iVK_O) { doLoadRom(frame, panel, label); }
                else case (KeyEvent.\iVK_EQUALS) { doZoomIn(frame, panel); }
                else case (KeyEvent.\iVK_MINUS) { doZoomOut(frame, panel); }
                else {}
            }
        }

        shared actual void keyReleased(KeyEvent e) {
            if (exists k = keyMap.get(e.keyCode)) {
                machine?.setKeyPressed(k, false);
            }
        }
    });
}
