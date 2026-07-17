#include "qt_quick_app/app_model.hpp"

#include <algorithm>
#include <utility>

namespace qt_quick_app {

AppModel::AppModel(QObject* parent) : QObject{parent} {}

QString AppModel::title() const { return title_; }

void AppModel::setTitle(const QString& title) {
  if (title_ == title) {
    return;
  }

  title_ = title;
  emit titleChanged();
}

int AppModel::count() const noexcept { return count_; }

void AppModel::setCount(int count) {
  const int normalizedCount = std::max(0, count);
  if (count_ == normalizedCount) {
    return;
  }

  count_ = normalizedCount;
  emit countChanged();
}

void AppModel::reset() {
  setTitle(tr("Qt Quick + C++23 + Nix"));
  setCount(0);
}

} // namespace qt_quick_app
