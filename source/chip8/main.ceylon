import java.awt.event {
    ActionEvent
}
import javax.swing {
    UIManager,
    JMenuItem,
    JPanel,
    JMenuBar,
    JFrame,
    JMenu
}

shared void main() {
    value machine = Machine(ActualPeripherals());

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
    panel.setSize(width * MainFrame.scale, height * MainFrame.scale);
    value frame = JFrame("CHIP-8");
    frame.jMenuBar = menuBar;
    frame.contentPane.add(panel);
    frame.defaultCloseOperation = JFrame.exitOnClose;
    // TODO: make frame stick to panel size
    // TODO: configurable pixel scaling (with hotkeys like Ctrl+, Ctrl-)
    //frame.resizable = false;
    //frame.pack();
    frame.setSize(64 * 4 + 100, 32 * 4 + 100);
    UIManager.setLookAndFeel(UIManager.systemLookAndFeelClassName);
    frame.setVisible(true);

    renderMenuItem.addActionListener((ActionEvent e) {
        MainFrame.render(machine, panel);
    });
    MainFrame.render(machine, panel);
}
