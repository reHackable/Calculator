#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtPlugin>

#ifndef DESKTOP
Q_IMPORT_PLUGIN(QsgEpaperPlugin)
#endif

int main(int argc, char *argv[])
{
#ifndef DESKTOP
    qputenv("QMLSCENE_DEVICE", "epaper");
    qputenv("QT_QPA_PLATFORM", "epaper:enable_fonts");
    qputenv("QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS", "rotate=180");
#endif

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
