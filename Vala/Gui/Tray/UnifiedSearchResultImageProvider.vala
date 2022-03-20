/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Image>
//  #include <QPainter>
//  #include <QSvgRenderer>
//  #include <QtCore>
//  #include <QQuickImageProvider>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The UnifiedSearchResultImageProvider
@ingroup gui
Allows to fetch Unified Search result icon from the server
or used a local resource
***********************************************************/
public class UnifiedSearchResultImageProvider : QQuickAsyncImageProvider {

    /***********************************************************
    ***********************************************************/
    public QQuickImageResponse request_image_response (string identifier, QSize requested_size) {
        return new AsyncImageResponse (identifier, requested_size);
    }

} // class UnifiedSearchResultImageProvider

} // namespace Ui
} // namespace Occ
