#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

namespace qt_quick_app {

class AppModel : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged FINAL)
  Q_PROPERTY(int count READ count WRITE setCount NOTIFY countChanged FINAL)

public:
  explicit AppModel(QObject* parent = nullptr);

  [[nodiscard]] QString title() const;
  void setTitle(const QString& title);

  [[nodiscard]] int count() const noexcept;
  void setCount(int count);

  Q_INVOKABLE void reset();

signals:
  void titleChanged();
  void countChanged();

private:
  QString title_{tr("Qt Quick + C++23 + Nix")};
  int count_{0};
};

} // namespace qt_quick_app
