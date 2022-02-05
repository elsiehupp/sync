/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <theme.h>
//  #include <account.h>
//  #include <QFile_ico
//  #include <QPainter>
//  #include <QApplication>
//  #include <QMouse_event>
//  #include <QStyled_item_delegate>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderStatusDelegate class
@ingroup gui
***********************************************************/
class FolderStatusDelegate : QStyledItemDelegate {

    /***********************************************************
    ***********************************************************/
    public enum DataRole {
        FOLDER_ALIAS_ROLE = Qt.USER_ROLE + 100,
        HEADER_ROLE,
        FOLDER_PATH_ROLE, // for a ItemType.SUBFOLDER it's the complete path
        FOLDER_SECOND_PATH_ROLE,
        FOLDER_CONFLICT_MESSAGE,
        FOLDER_ERROR_MESSAGE,
        FOLDER_INFO_MESSAGE,
        FOLDER_SYNC_PAUSED,
        FOLDER_STATUS_ICON_ROLE,
        FOLDER_ACCOUNT_CONNECTED,

        SYNC_PROGRESS_OVERALL_PERCENT,
        SYNC_PROGRESS_OVERALL_STRING,
        SYNC_PROGRESS_ITEM_STRING,
        WARNING_COUNT,
        SYNC_RUNNING,
        SYNC_DATE,

        ADD_BUTTON, // 1 = enabled; 2 = disabled
        FOLDER_SYNC_TEXT,
        DATA_ROLE_COUNT
    }

    /***********************************************************
    ***********************************************************/
    private QIcon icon_more;


    /***********************************************************
    ***********************************************************/
    public FolderStatusDelegate () {
        base ();
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void paint (QPainter painter, QStyleOptionViewItem option, QModelIndex index) {
        if (index.data (ItemType.ADD_BUTTON).to_bool ()) {
            const_cast<QStyleOptionViewItem &> (option).show_decoration_selected = false;
        }

        QStyled_item_delegate.paint (painter, option, index);

        var text_align = Qt.Align_left;

        QFont alias_font = make_alias_font (option.font);
        QFont sub_font = option.font;
        QFont error_font = sub_font;
        QFont progress_font = sub_font;

        progress_font.point_size (sub_font.point_size () - 2);

        QFontMetrics sub_fm (sub_font);
        QFontMetrics alias_fm (alias_font);
        QFontMetrics progress_fm (progress_font);

        int alias_margin = alias_fm.height () / 2;
        int margin = sub_fm.height () / 4;

        if (index.data (ItemType.ADD_BUTTON).to_bool ()) {
            QStyle_option_button opt;
            static_cast<QStyle_option &> (opt) = option;
            if (opt.state & QStyle.State_Enabled && opt.state & QStyle.State_Mouse_over && index == this.pressed_index) {
                opt.state |= QStyle.State_Sunken;
            } else {
                opt.state |= QStyle.State_Raised;
            }
            opt.text = add_folder_text ();
            opt.rect = add_button_rect (option.rect, option.direction);
            painter.save ();
            painter.font (Gtk.Application.font ("QPushButton"));
            QApplication.style ().draw_control (QStyle.CE_Push_button, opt, painter, option.widget);
            painter.restore ();
            return;
        }

        if (static_cast<const FolderStatusModel> (index.model ()).classify (index) != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return;
        }
        painter.save ();

        var status_icon = qvariant_cast<QIcon> (index.data (Folder_status_icon_role));
        var alias_text = qvariant_cast<string> (index.data (Header_role));
        var path_text = qvariant_cast<string> (index.data (FolderPathRole));
        var remote_path = qvariant_cast<string> (index.data (Folder_second_path_role));
        var conflict_texts = qvariant_cast<string[]> (index.data (Folder_conflict_msg));
        var error_texts = qvariant_cast<string[]> (index.data (Folder_error_msg));
        var info_texts = qvariant_cast<string[]> (index.data (Folder_info_msg));

        var overall_percent = qvariant_cast<int> (index.data (Sync_progress_overall_percent));
        var overall_string = qvariant_cast<string> (index.data (Sync_progress_overall_string));
        var item_string = qvariant_cast<string> (index.data (Sync_progress_item_string));
        var warning_count = qvariant_cast<int> (index.data (Warning_count));
        var sync_ongoing = qvariant_cast<bool> (index.data (Sync_running));
        var sync_enabled = qvariant_cast<bool> (index.data (FolderAccountConnected));
        var sync_text = qvariant_cast<string> (index.data (Folder_sync_text));

        var icon_rect = option.rect;
        var alias_rect = option.rect;

        icon_rect.left (option.rect.left () + alias_margin);
        icon_rect.top (icon_rect.top () + alias_margin); // (icon_rect.height ()-iconsize.height ())/2);

        // alias box
        alias_rect.top (alias_rect.top () + alias_margin);
        alias_rect.bottom (alias_rect.top () + alias_fm.height ());
        alias_rect.right (alias_rect.right () - alias_margin);

        // remote directory box
        var remote_path_rect = alias_rect;
        remote_path_rect.top (alias_rect.bottom () + margin);
        remote_path_rect.bottom (remote_path_rect.top () + sub_fm.height ());

        // local directory box
        var local_path_rect = remote_path_rect;
        local_path_rect.top (remote_path_rect.bottom () + margin);
        local_path_rect.bottom (local_path_rect.top () + sub_fm.height ());

        icon_rect.bottom (local_path_rect.bottom ());
        icon_rect.width (icon_rect.height ());

        int next_to_icon = icon_rect.right () + alias_margin;
        alias_rect.left (next_to_icon);
        local_path_rect.left (next_to_icon);
        remote_path_rect.left (next_to_icon);

        int icon_size = icon_rect.width ();

        var options_button_visual_rect = options_button_rect (option.rect, option.direction);

        QPixmap pm = status_icon.pixmap (icon_size, icon_size, sync_enabled ? QIcon.Normal : QIcon.Disabled);
        painter.draw_pixmap (QStyle.visual_rect (option.direction, option.rect, icon_rect).left (),
            icon_rect.top (), pm);

        // only show the warning icon if the sync is running. Otherwise its
        // encoded in the status icon.
        if (warning_count > 0 && sync_ongoing) {
            QRect warn_rect;
            warn_rect.left (icon_rect.left ());
            warn_rect.top (icon_rect.bottom () - 17);
            warn_rect.width (16);
            warn_rect.height (16);

            QIcon warn_icon (":/client/theme/warning");
            QPixmap pm = warn_icon.pixmap (16, 16, sync_enabled ? QIcon.Normal : QIcon.Disabled);
            warn_rect = QStyle.visual_rect (option.direction, option.rect, warn_rect);
            painter.draw_pixmap (QPoint (warn_rect.left (), warn_rect.top ()), pm);
        }

        var palette = option.palette;

        if (Gtk.Application.style ().inherits ("QWindows_vista_style")) {
            // Hack : Windows Vista's light blue is not contrasting enough for white

            // (code from QWindows_vista_style.draw_control for CE_Item_view_item)
            palette.on_color (QPalette.All, QPalette.Highlighted_text, palette.color (QPalette.Active, QPalette.Text));
            palette.on_color (QPalette.All, QPalette.Highlight, palette.base ().color ().darker (108));
        }

        QPalette.Color_group cg = option.state & QStyle.State_Enabled
            ? QPalette.Normal
            : QPalette.Disabled;
        if (cg == QPalette.Normal && ! (option.state & QStyle.State_Active))
            cg = QPalette.Inactive;

        if (option.state & QStyle.State_Selected) {
            painter.pen (palette.color (cg, QPalette.Highlighted_text));
        } else {
            painter.pen (palette.color (cg, QPalette.Text));
        }
        string elided_alias = alias_fm.elided_text (alias_text, Qt.Elide_right, alias_rect.width ());
        painter.font (alias_font);
        painter.draw_text (QStyle.visual_rect (option.direction, option.rect, alias_rect), text_align, elided_alias);

        const bool show_progess = !overall_string.is_empty () || !item_string.is_empty ();
        if (!show_progess) {
            painter.font (sub_font);
            string elided_remote_path_text = sub_fm.elided_text (
                sync_text,
                Qt.Elide_right, remote_path_rect.width ());
            painter.draw_text (QStyle.visual_rect (option.direction, option.rect, remote_path_rect),
                text_align, elided_remote_path_text);

            string elided_path_text = sub_fm.elided_text (path_text, Qt.Elide_middle, local_path_rect.width ());
            painter.draw_text (QStyle.visual_rect (option.direction, option.rect, local_path_rect),
                text_align, elided_path_text);
        }

        int h = icon_rect.bottom () + margin;

        // paint an error overlay if there is an error string or conflict string
        var draw_text_box = [&] (string[] texts, Gtk.Color color) {
            QRect rect = local_path_rect;
            rect.left (icon_rect.left ());
            rect.top (h);
            rect.height (texts.count () * sub_fm.height () + 2 * margin);
            rect.right (option.rect.right () - margin);

            // save previous state to not mess up colours with the background (fixes issue : https://github.com/nextcloud/desktop/issues/1237)
            painter.save ();
            painter.brush (color);
            painter.pen (Gtk.Color (0xaa, 0xaa, 0xaa));
            painter.draw_rounded_rect (QStyle.visual_rect (option.direction, option.rect, rect),
                4, 4);
            painter.pen (Qt.white);
            painter.font (error_font);
            QRect text_rect (rect.left () + margin,
                rect.top () + margin,
                rect.width () - 2 * margin,
                sub_fm.height ());

            foreach (string e_text, texts) {
                painter.draw_text (QStyle.visual_rect (option.direction, option.rect, text_rect), text_align,
                    sub_fm.elided_text (e_text, Qt.Elide_left, text_rect.width ()));
                text_rect.translate (0, text_rect.height ());
            }
            // restore previous state
            painter.restore ();

            h = rect.bottom () + margin;
        }

        if (!conflict_texts.is_empty ())
            draw_text_box (conflict_texts, Gtk.Color (0xba, 0xba, 0x4d));
        if (!error_texts.is_empty ())
            draw_text_box (error_texts, Gtk.Color (0xbb, 0x4d, 0x4d));
        if (!info_texts.is_empty ())
            draw_text_box (info_texts, Gtk.Color (0x4d, 0x4d, 0xba));

        // Sync File Progress Bar: Show it if sync_file is not empty.
        if (show_progess) {
            int filename_text_height = sub_fm.bounding_rect (_("File")).height ();
            int bar_height = 7; // same height as quota bar
            int overall_width = option.rect.right () - alias_margin - options_button_visual_rect.width () - next_to_icon;

            painter.save ();

            // Overall Progress Bar.
            QRect p_bRect;
            p_bRect.top (remote_path_rect.top ());
            p_bRect.left (next_to_icon);
            p_bRect.height (bar_height);
            p_bRect.width (overall_width - 2 * margin);

            QStyle_option_progress_bar p_bar_opt;

            p_bar_opt.state = option.state | QStyle.State_Horizontal;
            p_bar_opt.minimum = 0;
            p_bar_opt.maximum = 100;
            p_bar_opt.progress = overall_percent;
            p_bar_opt.orientation = Qt.Horizontal;
            p_bar_opt.rect = QStyle.visual_rect (option.direction, option.rect, p_bRect);
            QApplication.style ().draw_control (QStyle.CE_Progress_bar, p_bar_opt, painter, option.widget);

            // Overall Progress Text
            QRect overall_progress_rect;
            overall_progress_rect.top (p_bRect.bottom () + margin);
            overall_progress_rect.height (filename_text_height);
            overall_progress_rect.left (p_bRect.left ());
            overall_progress_rect.width (p_bRect.width ());
            painter.font (progress_font);

            painter.draw_text (QStyle.visual_rect (option.direction, option.rect, overall_progress_rect),
                Qt.Align_left | Qt.Align_vCenter, overall_string);
            // painter.draw_rect (overall_progress_rect);

            painter.restore ();
        }

        painter.restore ();
        {
            QStyle_option_tool_button btn_opt;
            btn_opt.state = option.state;
            btn_opt.state &= ~ (QStyle.State_Selected | QStyle.State_Has_focus);
            btn_opt.state |= QStyle.State_Raised;
            btn_opt.arrow_type = Qt.No_arrow;
            btn_opt.sub_controls = QStyle.SC_Tool_button;
            btn_opt.rect = options_button_visual_rect;
            btn_opt.icon = this.icon_more;
            int e = QApplication.style ().pixel_metric (QStyle.PM_Button_icon_size);
            btn_opt.icon_size = QSize (e,e);
            QApplication.style ().draw_complex_control (QStyle.CC_Tool_button, btn_opt, painter);
        }
    }


    /***********************************************************
    allocate each item size in listview.
    ***********************************************************/
    public QSize size_hint (QStyleOptionViewItem option, QModelIndex index) {
        QFont alias_font = make_alias_font (option.font);
        QFont font = option.font;

        QFontMetrics fm (font);
        QFontMetrics alias_fm (alias_font);

        var classif = static_cast<const FolderStatusModel> (index.model ()).classify (index);
        if (classif == FolderStatusModel.ItemType.ADD_BUTTON) {
            const int margins = alias_fm.height (); // same as 2*alias_margin of paint
            QFontMetrics fm (Gtk.Application.font ("QPushButton"));
            QStyle_option_button opt;
            static_cast<QStyle_option &> (opt) = option;
            opt.text = add_folder_text ();
            return QApplication.style ().size_from_contents (
                                            QStyle.CT_Push_button, opt, fm.size (Qt.Text_single_line, opt.text))
                    .expanded_to (QApplication.global_strut ())
                + QSize (0, margins);
        }

        if (classif != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return QStyled_item_delegate.size_hint (option, index);
        }

        // calc height
        int h = root_folder_height_without_errors (fm, alias_fm);
        // this already includes the bottom margin

        // add some space for the message boxes.
        int margin = fm.height () / 4;
        for (var role: {Folder_conflict_msg, Folder_error_msg, Folder_info_msg}) {
            var msgs = qvariant_cast<string[]> (index.data (role));
            if (!msgs.is_empty ()) {
                h += margin + 2 * margin + msgs.count () * fm.height ();
            }
        }

        return {0, h};
    }


    /***********************************************************
    ***********************************************************/
    public bool editor_event (QEvent event, QAbstractItemModel model,
        QStyleOptionViewItem option, QModelIndex index) {
        switch (event.type ()) {
        case QEvent.Mouse_button_press:
        case QEvent.Mouse_move:
            if (var view = qobject_cast<const QAbstractItemView> (option.widget)) {
                var me = static_cast<QMouse_event> (event);
                QModelIndex index;
                if (me.buttons ()) {
                    index = view.index_at (me.position ());
                }
                if (this.pressed_index != index) {
                    this.pressed_index = index;
                    view.viewport ().update ();
                }
            }
            break;
        case QEvent.Mouse_button_release:
            this.pressed_index = QModelIndex ();
            break;
        default:
            break;
        }
        return QStyled_item_delegate.editor_event (event, model, option, index);
    }


    /***********************************************************
    return the position of the option button within the item
    ***********************************************************/
    public static QRect options_button_rect (QRect within, Qt.Layout_direction direction) {
        QFont font = QFont ();
        QFont alias_font = make_alias_font (font);
        QFontMetrics fm (font);
        QFontMetrics alias_fm (alias_font);
        within.height (FolderStatusDelegate.root_folder_height_without_errors (fm, alias_fm));

        QStyle_option_tool_button opt;
        int e = QApplication.style ().pixel_metric (QStyle.PM_Button_icon_size);
        opt.rect.size (QSize (e,e));
        QSize size = QApplication.style ().size_from_contents (QStyle.CT_Tool_button, opt, opt.rect.size ()).expanded_to (QApplication.global_strut ());

        int margin = QApplication.style ().pixel_metric (QStyle.PM_Default_layout_spacing);
        QRect r (QPoint (within.right () - size.width () - margin,
                    within.top () + within.height () / 2 - size.height () / 2),
            size);
        return QStyle.visual_rect (direction, within, r);
    }


    /***********************************************************
    ***********************************************************/
    public static QRect add_button_rect (QRect within, Qt.Layout_direction direction) {
        QFontMetrics fm (Gtk.Application.font ("QPushButton"));
        QStyle_option_button opt;
        opt.text = add_folder_text ();
        QSize size = QApplication.style ().size_from_contents (QStyle.CT_Push_button, opt, fm.size (Qt.Text_single_line, opt.text)).expanded_to (QApplication.global_strut ());
        QRect r (QPoint (within.left (), within.top () + within.height () / 2 - size.height () / 2), size);
        return QStyle.visual_rect (direction, within, r);
    }


    /***********************************************************
    ***********************************************************/
    public QRect errors_list_rect (QRect within) {
        QFont font = QFont ();
        QFont alias_font = make_alias_font (font);
        QFontMetrics fm (font);
        QFontMetrics alias_fm (alias_font);
        within.top (within.top () + FolderStatusDelegate.root_folder_height_without_errors (fm, alias_fm));
        return within;
    }


    /***********************************************************
    ***********************************************************/
    public void on_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.icon_more = Theme.create_color_aware_icon (QLatin1String (":/client/theme/more.svg"));
    }


    /***********************************************************
    ***********************************************************/
    public static int root_folder_height_without_errors (QFontMetrics fm, QFontMetrics alias_fm) {
        const int alias_margin = alias_fm.height () / 2;
        const int margin = fm.height () / 4;

        int h = alias_margin; // margin to top
        h += alias_fm.height (); // alias
        h += margin; // between alias and local path
        h += fm.height (); // local path
        h += margin; // between local and remote path
        h += fm.height (); // remote path
        h += margin; // bottom margin
        return h;
    }


    /***********************************************************
    ***********************************************************/
    private static QFont make_alias_font (QFont normal_font) {
        QFont alias_font = normal_font;
        alias_font.bold (true);
        alias_font.point_size (normal_font.point_size () + 2);
        return alias_font;
    }


    /***********************************************************
    ***********************************************************/
    private static string add_folder_text ();
    string FolderStatusDelegate.add_folder_text () {
        return _("Add Folder Sync Connection");
    }
}













} // namespace Occ
