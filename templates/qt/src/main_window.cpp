#include "qt_app/main_window.hpp"

#include <QLabel>

namespace qt_app {

MainWindow::MainWindow(QWidget* parent) : QMainWindow{parent} {
  auto* label = new QLabel{tr("Qt 6 + C++20 + Nix"), this};
  label->setAlignment(Qt::AlignCenter);
  setCentralWidget(label);
  setWindowTitle(tr("Qt App"));
  resize(640, 480);
}

} // namespace qt_app
