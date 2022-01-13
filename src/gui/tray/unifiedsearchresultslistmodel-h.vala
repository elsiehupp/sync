/*
 * Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #pragma once

// #include <limits>

// #include <QtCore>

namespace OCC {
class AccountState;

/**
 * @brief The UnifiedSearchResultsListModel
 * @ingroup gui
 * Simple list model to provide the list view with data for the Unified Search results.
 */

class UnifiedSearchResultsListModel : public QAbstractListModel {

    Q_PROPERTY (bool isSearchInProgress READ isSearchInProgress NOTIFY isSearchInProgressChanged)
    Q_PROPERTY (QString currentFetchMoreInProgressProviderId READ currentFetchMoreInProgressProviderId NOTIFY
            currentFetchMoreInProgressProviderIdChanged)
    Q_PROPERTY (QString errorString READ errorString NOTIFY errorStringChanged)
    Q_PROPERTY (QString searchTerm READ searchTerm WRITE setSearchTerm NOTIFY searchTermChanged)

    struct UnifiedSearchProvider {
        QString _id;
        QString _name;
        int32 _cursor = -1; // current pagination value
        int32 _pageSize = -1; // how many max items per step of pagination
        bool _isPaginated = false;
        int32 _order = std.numeric_limits<int32>.max (); // sorting order (smaller number has bigger priority)
    };

public:
    enum DataRole {
        ProviderNameRole = Qt.UserRole + 1,
        ProviderIdRole,
        ImagePlaceholderRole,
        IconsRole,
        TitleRole,
        SublineRole,
        ResourceUrlRole,
        RoundedRole,
        TypeRole,
        TypeAsStringRole,
    };

    explicit UnifiedSearchResultsListModel (AccountState *accountState, QObject *parent = nullptr);

    QVariant data (QModelIndex &index, int role) const override;
    int rowCount (QModelIndex &parent = QModelIndex ()) const override;

    bool isSearchInProgress () const;

    QString currentFetchMoreInProgressProviderId () const;
    QString searchTerm () const;
    QString errorString () const;

    Q_INVOKABLE void resultClicked (QString &providerId, QUrl &resourceUrl) const;
    Q_INVOKABLE void fetchMoreTriggerClicked (QString &providerId);

    QHash<int, QByteArray> roleNames () const override;

private:
    void startSearch ();
    void startSearchForProvider (QString &providerId, int32 cursor = -1);

    void parseResultsForProvider (QJsonObject &data, QString &providerId, bool fetchedMore = false);

    // append initial search results to the list
    void appendResults (QVector<UnifiedSearchResult> results, UnifiedSearchProvider &provider);

    // append pagination results to existing results from the initial search
    void appendResultsToProvider (QVector<UnifiedSearchResult> &results, UnifiedSearchProvider &provider);

    void removeFetchMoreTrigger (QString &providerId);

    void disconnectAndClearSearchJobs ();

    void clearCurrentFetchMoreInProgressProviderId ();

signals:
    void currentFetchMoreInProgressProviderIdChanged ();
    void isSearchInProgressChanged ();
    void errorStringChanged ();
    void searchTermChanged ();

public slots:
    void setSearchTerm (QString &term);

private slots:
    void slotSearchTermEditingFinished ();
    void slotFetchProvidersFinished (QJsonDocument &json, int statusCode);
    void slotSearchForProviderFinished (QJsonDocument &json, int statusCode);

private:
    QMap<QString, UnifiedSearchProvider> _providers;
    QVector<UnifiedSearchResult> _results;

    QString _searchTerm;
    QString _errorString;

    QString _currentFetchMoreInProgressProviderId;

    QMap<QString, QMetaObject.Connection> _searchJobConnections;

    QTimer _unifiedSearchTextEditingFinishedTimer;

    AccountState *_accountState = nullptr;
};
}
