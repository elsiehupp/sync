# project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'AccountApp.vala',
    'AccountManager.vala',
    'AccountSettings.vala',
    'AccountState.vala',
    'AddCertificateDialog.vala',
    'Application.vala',
    'AuthenticationDialog.vala',

    'CloudProviders/CloudProviderManager.vala',
    'CloudProviders/CloudProviderWrapper.vala',

    'ConflictDialog.vala',
    'ConflictSolver.vala',
    'ConnectionValidator.vala',
    'Credentials/CredentialsFactory.vala',
    'Credentials/Flow2Auth.vala',
    'Credentials/HttpCredentialsGui.vala',
    'Credentials/OAuth.vala',
    'Credentials/WebFlowCredentialsDialog.vala',
    'Credentials/WebFlowCredentials.vala',
    'ElidedLabel.vala',
    'EmojiCategoriesModel.vala',
    'FileActivityListModel.vala',
    'FolderConnection.vala',
    'FolderCreationDialog.vala',
    'FolderManager.vala',
    'FolderStatusDelegate.vala',
    'FolderStatusModel.vala',
    'FolderStatusView.vala',
    'FolderWatcherPrivate.vala',
    'FolderWatcher.vala',

    'FolderWizard/FolderWizard.vala',
    'FolderWizard/FolderWizardLocalPath.vala',
    'FolderWizard/FolderWizardRemotePath.vala',
    'FolderWizard/FolderWizardSelectiveSync.vala',
    'FolderWizard/FormatWarningsWizardPage.vala',

    'GeneralSettings.vala',
    'HeaderBanner.vala',
    'IconUtils.vala',
    'IgnoreListEditor.vala',
    'IgnoreListTableWidget.vala',
    'InvalidFilenameDialog.vala',
    'LegalNotice.vala',
    'LogBrowser.vala',
    'Main.vala',
    'NavigationPaneHelper.vala',
    'NetworkSettings.vala',
    'NotificationConfirmJob.vala',
    'OcsJob.vala',
    'OcsNavigationAppsJob.vala',
    'OcsShareeJob.vala',
    'OcsShareJob.vala',
    'OpenExternal.vala',
    'OpenFileManager.vala',
    'OwncloudGui.vala',
    'OwncloudSetupWizard.vala',
    'ProfilePageMenu.vala',
    'ProxyAuthDialog.vala',
    'ProxyAuthHandler.vala',
    'RemoteWipe.vala',
    'SelectiveSyncDialog.vala',
    'SettingsDialog.vala',
    'ShareDialog.vala',
    'Sharee.vala',
    'ShareeModel.vala',
    'ShareLinkWidget.vala',

    'ShareManager/LinkShare.vala',
    'ShareManager/Share.vala',
    'ShareManager/ShareManager.vala',
    'ShareManager/UserGroupShare.vala',

    'SharePermission.vala',

    'ShareUserGroupWidget/AvatarEventFilter.vala',
    'ShareUserGroupWidget/ShareUserGroupWidget.vala',
    'ShareUserGroupWidget/ShareUserLine.vala',

    'SocketApi/SocketApi.vala',
    'SocketApi/SocketUploadJob.vala',
    'SslButton.vala',
    'SslErrorDialog.vala',
    'SyncRunFileLog.vala',
    'Systray.vala',
    'ThumbnailJob.vala',
    'ToolTipUpdater.vala',

    'Tray/ActivityLink.vala',
    'Tray/ActivityListModel.vala',
    'Tray/AsyncImageResponse.vala',
    'Tray/NotificationCache.vala',
    'Tray/ServerNotificationHandler.vala',
    'Tray/SvgImageProvider.vala',
    'Tray/SyncStatusSummary.vala',
    'Tray/UnifiedSearchResultImageProvider.vala',
    'Tray/UnifiedSearchResultsListModel.vala',
    'Tray/UnifiedSearchResult.vala',

    'Tray/UserModel/ImageProvider.vala',
    'Tray/UserModel/User.vala',
    'Tray/UserModel/UserAppsModel.vala',
    'Tray/UserModel/UserModel.vala',

    'Updater/AbstractUpdater.vala',

    'Updater/OCUpdater/NSISUpdater.vala',
    'Updater/OCUpdater/OCUpdater.vala',
    'Updater/OCUpdater/PassiveUpdateNotifier.vala',
    'Updater/OCUpdater/UpdaterScheduler.vala',

    'Updater/UpdateInfo.vala',

    'UserInfo.vala',
    'UserStatusSelectorModel.vala',

    'Wizard/AbstractCredentialsWizardPage.vala',
    'Wizard/Flow2AuthCredsPage.vala',
    'Wizard/Flow2AuthWidget.vala',
    'Wizard/LinkLabel.vala',
    'Wizard/OwncloudAdvancedSetupPage.vala',
    'Wizard/OwncloudConnectionMethodDialog.vala',
    'Wizard/OwncloudHttpCredsPage.vala',
    'Wizard/OwncloudOAuthCredsPage.vala',
    'Wizard/OwncloudSetupPage.vala',
    'Wizard/OwncloudWizardCommon.vala',
    'Wizard/OwncloudWizard.vala',
    'Wizard/PostfixLineEdit.vala',
    'Wizard/SlideShow.vala',
    'Wizard/WebViewPage.vala',

    'Wizard/WebView/ExternalWebEnginePage.vala',
    'Wizard/WebView/WebEnginePage.vala',
    'Wizard/WebView/WebView.vala',
    'Wizard/WebView/WebViewPageUrlRequestInterceptor.vala',
    'Wizard/WebView/WebViewPageUrlSchemeHandler.vala',

    'Wizard/WelcomePage.vala'
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # libjson-glib-dev
    dependency('json-glib-1.0'),
    # libsecret-1-dev
    dependency('libsecret-1'),
    dependency('libsoup-2.4'),
]

libraries = [
    # subproject('3rdParty').get_variable ('3rd_party'),
    # subproject('Cmd').get_variable ('cmd'),
    subproject('Common').get_variable ('common'),
    # 'CrashReporter',
    subproject('CSync').get_variable ('csync'),
    # 'Gui',
    subproject('LibSync').get_variable ('lib_sync'),
    # 'ShellIntegration',
    # 'Testing',
    subproject('Gpseq').get_variable ('gpseq_lib')
]

gui = executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false,
    link_with: libraries
)