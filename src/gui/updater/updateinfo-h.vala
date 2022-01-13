// This file is generated by kxml_compiler from occinfo.xml.

// #include <QString>
// #include <QDomElement>
// #include <QXmlStreamWriter>

namespace OCC {

class UpdateInfo
{
public:
    void setVersion(const QString &v);
    QString version() const;
    void setVersionString(const QString &v);
    QString versionString() const;
    void setWeb(const QString &v);
    QString web() const;
    void setDownloadUrl(const QString &v);
    QString downloadUrl() const;
    /**
      Parse XML object from DOM element.
     */
    static UpdateInfo parseElement(const QDomElement &element, bool *ok);
    static UpdateInfo parseString(const QString &xml, bool *ok);

private:
    QString mVersion;
    QString mVersionString;
    QString mWeb;
    QString mDownloadUrl;
};

} // namespace OCC

#endif // UPDATEINFO_H
