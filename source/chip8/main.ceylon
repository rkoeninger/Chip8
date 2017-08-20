import javax.swing { UIManager }

shared void main() {
    UIManager.setLookAndFeel(UIManager.systemLookAndFeelClassName);
    MainFrame().setVisible(true);
}
