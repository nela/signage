#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QMediaPlayer>
#include <QFileInfo>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Load QML file from command line arg or default to resource
    QUrl url;
    if (argc > 1 && QFileInfo::exists(argv[1])) {
        url = QUrl::fromLocalFile(argv[1]);
    } else {
        url = QUrl(QStringLiteral("qrc:/main.qml"));
    }

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
