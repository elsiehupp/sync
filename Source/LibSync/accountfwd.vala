/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QSharedPointer>

namespace Occ {

using AccountPtr = QSharedPointer<Account>;
using AccountStatePtr = QExplicitlySharedDataPointer<AccountState>;

} // namespace Occ

#endif //SERVERFWD
