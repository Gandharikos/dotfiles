#pragma once

#include <QMainWindow>

namespace qt_app {

class MainWindow final : public QMainWindow {
  Q_OBJECT

public:
  explicit MainWindow(QWidget* parent = nullptr);
};

} // namespace qt_app
