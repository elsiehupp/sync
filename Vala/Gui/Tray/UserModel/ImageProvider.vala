
class Image_provider : QQuick_image_provider {

    /***********************************************************
    ***********************************************************/
    public Image_provider ();

    /***********************************************************
    ***********************************************************/
    public 
    public QImage request_image (string id, QSize size, QSize requested_size) override;
}
