#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTimer>
#include <QtGlobal>
#include <cstddef>
#include <iostream>
#include <span>
#include <string_view>

namespace {

[[nodiscard]] bool hasArgument(std::span<char*> arguments, std::string_view expected) noexcept {
  for (const char* value : arguments.subspan(1)) {
    if (std::string_view{value} == expected) {
      return true;
    }
  }
  return false;
}

} // namespace

int main(int argc, char** argv) {
  const std::span arguments{argv, static_cast<std::size_t>(argc)};
  if (hasArgument(arguments, "--version") || hasArgument(arguments, "-v")) {
    std::cout << "qt-quick-app " << QT_QUICK_APP_VERSION << '\n';
    return 0;
  }

  QGuiApplication application{argc, argv};
  QGuiApplication::setApplicationName("qt-quick-app");
  QGuiApplication::setApplicationVersion(QT_QUICK_APP_VERSION);

  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &application,
      [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
  engine.loadFromModule("QtQuickTemplate", "Main");

  if (hasArgument(arguments, "--smoke-test")) {
    QTimer::singleShot(0, &application, &QCoreApplication::quit);
  }

  return QGuiApplication::exec();
}
