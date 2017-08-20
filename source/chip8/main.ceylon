import javax.swing { UIManager }

shared void main() {
    UIManager.setLookAndFeel(UIManager.systemLookAndFeelClassName);
    Display().setVisible(true);
}
