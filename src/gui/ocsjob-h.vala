/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QVector>
// #include <QList>
// #include <QPair>
// #include <QUrl>

const int OCS_SUCCESS_STATUS_CODE 100
// Apparantly the v2.php URLs can return that
const int OCS_SUCCESS_STATUS_CODE_V2 200
// not modified when using  ETag
const int OCS_NOT_MODIFIED_STATUS_CODE_V2 304


namespace Occ {

/**
@brief The OcsShareJob class
@ingroup gui

Base class for jobs that talk to the OCS endpoints on th
All the communication logic is handled in this class.

All OCS jobs (e.g. sharing) should extend this class.
*/
class OcsJob : AbstractNetworkJob {

protected:
    OcsJob (AccountPtr account);

    /**
     * Set the verb for the job
     *
     * @param verb currently supported PUT POST DELETE
     */
    void setVerb (QByteArray &verb);

    /**
     * Add a new parameter to the request.
     * Depending on the verb this is GET or POST parameter
     *
     * @param name The name of the parameter
     * @param value The value of the parameter
     */
    void addParam (QString &name, QString &value);

    /**
     * Set the post parameters
     *
     * @param postParams list of pairs to add (urlEncoded) to the body of the
     * request
     */
    void setPostParams (QList<QPair<QString, QString>> &postParams);

    /**
     * List of expected statuscodes for this request
     * A warning will be printed to the debug log if a different status code is
     * encountered
     *
     * @param code Accepted status code
     */
    void addPassStatusCode (int code);

    /**
     * The base path for an OcsJob is always the same. But it could be the case that
     * certain operations need to append something to the URL.
     *
     * This function appends the common id. so <PATH>/<ID>
     */
    void appendPath (QString &id);

public:
    /**
     * Parse the response and return the status code and the message of the
     * reply (metadata)
     *
     * @param json The reply from OCS
     * @param message The message that is set in the metadata
     * @return The statuscode of the OCS response
     */
    static int getJsonReturnCode (QJsonDocument &json, QString &message);

    /**
     * @brief Adds header to the request e.g. "If-None-Match"
     * @param headerName a string with the header name
     * @param value a string with the value
     */
    void addRawHeader (QByteArray &headerName, QByteArray &value);

protected slots:

    /**
     * Start the OCS request
     */
    void start () override;

signals:

    /**
     * Result of the OCS request
     *
     * @param reply the reply
     */
    void jobFinished (QJsonDocument reply, int statusCode);

    /**
     * The status code was not one of the expected (passing)
     * status code for this command
     *
     * @param statusCode The actual status code
     * @param message The message provided by the server
     */
    void ocsError (int statusCode, QString &message);

    /**
     * @brief etagResponseHeaderReceived - signal to report the ETag response header value
     * from ocs api v2
     * @param value - the ETag response header value
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void etagResponseHeaderReceived (QByteArray &value, int statusCode);

private slots:
    bool finished () override;

private:
    QByteArray _verb;
    QList<QPair<QString, QString>> _params;
    QVector<int> _passStatusCodes;
    QNetworkRequest _request;
};
}
