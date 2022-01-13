/*
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

namespace Occ {

class OWNCLOUDSYNC_EXPORT DummyCredentials : AbstractCredentials {

public:
    QString _user;
    QString _password;
    QString authType () const override;
    QString user () const override;
    QString password () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    bool stillValid (QNetworkReply *reply) override;
    void fetchFromKeychain () override;
    void askFromUser () override;
    void persist () override;
    void invalidateToken () override {}
    void forgetSensitiveData () override{};
};

} // namespace Occ

#endif
