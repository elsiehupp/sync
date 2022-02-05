
namespace Occ {
namespace Ui {

class Image_provider : QQuick_image_provider {

    /***********************************************************
    ***********************************************************/
    public Image_provider ();

    /***********************************************************
    ***********************************************************/
    public QImage request_image (string identifier, QSize size, QSize requested_size) override;
}
