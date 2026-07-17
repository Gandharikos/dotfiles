#include "qt_quick_app/app_model.hpp"

#include <QSignalSpy>
#include <QtTest>

class AppModelTest final : public QObject {
  Q_OBJECT

private slots:
  void hasUsefulDefaults();
  void updatesPropertiesAndEmitsSignals();
  void ignoresUnchangedValues();
  void normalizesNegativeCounts();
  void resetsProperties();
};

void AppModelTest::hasUsefulDefaults() {
  const qt_quick_app::AppModel model;

  QCOMPARE(model.title(), QStringLiteral("Qt Quick + C++23 + Nix"));
  QCOMPARE(model.count(), 0);
}

void AppModelTest::updatesPropertiesAndEmitsSignals() {
  qt_quick_app::AppModel model;
  QSignalSpy titleChanged{&model, &qt_quick_app::AppModel::titleChanged};
  QSignalSpy countChanged{&model, &qt_quick_app::AppModel::countChanged};

  model.setTitle(QStringLiteral("Slides"));
  model.setCount(3);

  QCOMPARE(model.title(), QStringLiteral("Slides"));
  QCOMPARE(model.count(), 3);
  QCOMPARE(titleChanged.count(), 1);
  QCOMPARE(countChanged.count(), 1);
}

void AppModelTest::ignoresUnchangedValues() {
  qt_quick_app::AppModel model;
  QSignalSpy titleChanged{&model, &qt_quick_app::AppModel::titleChanged};
  QSignalSpy countChanged{&model, &qt_quick_app::AppModel::countChanged};

  model.setTitle(model.title());
  model.setCount(model.count());

  QCOMPARE(titleChanged.count(), 0);
  QCOMPARE(countChanged.count(), 0);
}

void AppModelTest::normalizesNegativeCounts() {
  qt_quick_app::AppModel model;
  model.setCount(4);
  QSignalSpy countChanged{&model, &qt_quick_app::AppModel::countChanged};

  model.setCount(-1);

  QCOMPARE(model.count(), 0);
  QCOMPARE(countChanged.count(), 1);
}

void AppModelTest::resetsProperties() {
  qt_quick_app::AppModel model;
  model.setTitle(QStringLiteral("Changed"));
  model.setCount(2);

  model.reset();

  QCOMPARE(model.title(), QStringLiteral("Qt Quick + C++23 + Nix"));
  QCOMPARE(model.count(), 0);
}

QTEST_GUILESS_MAIN(AppModelTest)

#include "app_model_test.moc"
