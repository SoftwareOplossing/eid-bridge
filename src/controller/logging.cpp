// SPDX-FileCopyrightText: Estonian Information System Authority
// SPDX-License-Identifier: MIT

#include "logging.hpp"

#include "utils/qt_comp.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMutex>
#include <QMutexLocker>
#include <QSettings>
#include <QStandardPaths>

#include <iostream>

namespace
{

bool openLogFile(QFile& logFile)
{
#ifdef Q_OS_WIN
    // A visible per-user location makes support logs accessible without registry edits.
    const auto documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    const auto logFilePath = documents.isEmpty()
                                 ? QString()
                                 : QDir(documents).filePath(QStringLiteral("LetsPeppol eID Bridge/Logs"));
#else
    const auto logFilePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
#endif
    if (logFilePath.isEmpty()) {
        std::cerr << "Unable to determine logfile location path" << std::endl;
        return false;
    }
    QDir logFileDir {logFilePath};
    if (!logFileDir.mkpath(logFileDir.absolutePath())) {
        std::cerr << "Unable to create logfile directory '"
                  << logFileDir.absolutePath().toStdString() << '\'' << std::endl;
        return false;
    }
#ifdef Q_OS_WIN
    const auto fileName = logFileDir.filePath(QStringLiteral("LetsPeppol-eID-Bridge.log"));
    // The native host starts for each browser request; keep at most one previous file.
    if (QFileInfo(fileName).size() >= 5 * 1024 * 1024) {
        const auto previous = fileName + QStringLiteral(".1");
        QFile::remove(previous);
        if (!QFile::rename(fileName, previous)) {
            std::cerr << "Unable to rotate log file" << std::endl;
        }
    }
    logFile.setFileName(fileName);
#else
    logFile.setFileName(logFileDir.filePath(QStringLiteral("%1.log").arg(qApp->applicationName())));
#endif
    if (!logFile.open(QIODevice::Append | QIODevice::Text)) {
        std::cerr << "Unable to open logfile '" << logFile.fileName().toStdString() << '\''
                  << std::endl;
        return false;
    }
    return true;
}

inline const char* toString(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg:
        return "DEBUG";
    case QtInfoMsg:
        return "INFO";
    case QtWarningMsg:
        return "WARNING";
    case QtCriticalMsg:
        return "ERROR";
    case QtFatalMsg:
        return "FATAL";
    }
    return "UNKNOWN";
}

inline QString removeAbsolutePathPrefix(const QString& filePath)
{
    const auto lastSrc = filePath.lastIndexOf(QStringLiteral("src"));
    return filePath.mid(lastSrc);
}

void messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& message)
{
    static QMutex mutex;
    QMutexLocker lock(&mutex);

    std::cerr << toString(type) << ": " << message.toStdString() << std::endl;

#ifndef Q_OS_WIN
    if (!QSettings().value(QStringLiteral("logging"), false).toBool()) {
        return;
    }
#endif

    static QFile logFile;
    static bool logFileIsOpen = openLogFile(logFile);

    if (logFileIsOpen) {
        logFile.write(QStringLiteral("%1 %2 %3:%4:%5 - %6\n")
                          .arg(QDateTime::currentDateTimeUtc().toString(
                              QStringLiteral("yyyy-MM-ddThh:mm:ss.zzzZ")))
                          .arg(toString(type))
                          .arg(removeAbsolutePathPrefix(context.file))
                          .arg(context.line)
                          .arg(context.function)
                          .arg(message)
                          .toUtf8());
        logFile.flush();
    }
}

} // namespace

void setupLogging()
{
    qInstallMessageHandler(messageHandler);
}
