/*
 * harbour-molecules.cpp
 *
 * Sailfish OS port of "Molecules" by Miskatonic Studio
 * Original game (Godot 4.0): https://github.com/miskatonicstudio/molecules
 * License: The Unlicense (public domain)
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QScopedPointer>

int main(int argc, char *argv[])
{
    // SailfishApp::application() sets up the QGuiApplication with the
    // correct application name, organization and display abstraction.
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // Expose the package version to QML (used on the About page).
    view->rootContext()->setContextProperty(QStringLiteral("APP_VERSION"),
                                             QStringLiteral(APP_VERSION));

    view->setSource(SailfishApp::pathTo("qml/harbour-molecules.qml"));
    view->showFullScreen();

    return app->exec();
}
