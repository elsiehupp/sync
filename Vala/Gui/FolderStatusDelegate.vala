/***********************************************************
@author Klaas Freitag <freitag@kde.org>
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <theme.h>
//  #include <account.h>
//  #include <GLib.File_ico
//  #include <GLib.Painter>
//  #include <GLib.Application>
//  #include <GLib.MouseEvent>
//  #include <GLib.Styled_item_delegate>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderStatusDelegate class
@ingroup gui
***********************************************************/
public class FolderStatusDelegate : GLib.StyledItemDelegate {

    /***********************************************************
    ***********************************************************/
    public enum DataRole {
        FOLDER_ALIAS_ROLE = GLib.USER_ROLE + 100,
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
    private Gtk.IconInfo icon_more;


    /***********************************************************
    ***********************************************************/
    public FolderStatusDelegate () {
        base ();
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void paint (GLib.Painter painter, GLib.StyleOptionViewItem option, GLib.ModelIndex index) {
        if (index.data (DataRole.ItemType.ADD_BUTTON).to_bool ()) {
            ((GLib.StyleOptionViewItem) option).show_decoration_selected = false;
        }

        GLib.Styled_item_delegate.paint (painter, option, index);

        var text_align = GLib.Align_left;

        Cairo.FontFace alias_font = make_alias_font (option.font);
        Cairo.FontFace sub_font = option.font;
        Cairo.FontFace error_font = sub_font;
        Cairo.FontFace progress_font = sub_font;

        progress_font.point_size (sub_font.point_size () - 2);

        Cairo.FontOptions sub_font_metrics = new Cairo.FontOptions (sub_font);
        Cairo.FontOptions alias_font_metrics = new Cairo.FontOptions (alias_font);
        Cairo.FontOptions progress_font_metrics = new Cairo.FontOptions (progress_font);

        int alias_margin = alias_font_metrics.height () / 2;
        int margin = sub_font_metrics.height () / 4;

        if (index.data (DataRole.ItemType.ADD_BUTTON).to_bool ()) {
            GLib.StyleOptionButton opt = (GLib.StyleOption) option;
            if (opt.state & GLib.Style.State_Enabled && opt.state & GLib.Style.State_Mouse_over && index == this.pressed_index) {
                opt.state |= GLib.Style.State_Sunken;
            } else {
                opt.state |= GLib.Style.State_Raised;
            }
            opt.text = add_folder_text ();
            opt.rect = add_button_rect (option.rect, option.direction);
            painter.save ();
            painter.font (GLib.Application.font ("GLib.PushButton"));
            GLib.Application.this.style.draw_control (GLib.Style.CE_Push_button, opt, painter, option.widget);
            painter.restore ();
            return;
        }

        if (((FolderStatusModel) index.model ()).classify (index) != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return;
        }
        painter.save ();

        var status_icon = (Gtk.IconInfo)index.data (DataRole.FOLDER_STATUS_ICON_ROLE);
        var alias_text = (string)index.data (DataRole.HEADER_ROLE);
        var path_text = (string)index.data (DataRole.FOLDER_PATH_ROLE);
        var remote_path = (string)index.data (DataRole.FOLDER_SECOND_PATH_ROLE);
        var conflict_texts = (GLib.List<string>)index.data (DataRole.FOLDER_CONFLICT_MESSAGE);
        var error_texts = (GLib.List<string>)index.data (DataRole.FOLDER_ERROR_MESSAGE);
        var info_texts = (GLib.List<string>)index.data (DataRole.FOLDER_INFO_MESSAGE);

        var overall_percent = (int)index.data (DataRole.Sync_progress_overall_percent);
        var overall_string = (string)index.data (DataRole.Sync_progress_overall_string);
        var item_string = (string)index.data (DataRole.Sync_progress_item_string);
        var warning_count = (int)index.data (DataRole.Warning_count);
        var sync_ongoing = (bool)index.data (DataRole.Sync_running);
        var sync_enabled = (bool)index.data (DataRole.FolderAccountConnected);
        var sync_text = (string)index.data (DataRole.Folder_sync_text);

        var icon_rect = option.rect;
        var alias_rect = option.rect;

        icon_rect.left (option.rect.left () + alias_margin);
        icon_rect.top (icon_rect.top () + alias_margin); // (icon_rect.height ()-iconsize.height ())/2);

        // alias box
        alias_rect.top (alias_rect.top () + alias_margin);
        alias_rect.bottom (alias_rect.top () + alias_font_metrics.height ());
        alias_rect.right (alias_rect.right () - alias_margin);

        // remote directory box
        var remote_path_rect = alias_rect;
        remote_path_rect.top (alias_rect.bottom () + margin);
        remote_path_rect.bottom (remote_path_rect.top () + sub_font_metrics.height ());

        // local directory box
        var local_path_rect = remote_path_rect;
        local_path_rect.top (remote_path_rect.bottom () + margin);
        local_path_rect.bottom (local_path_rect.top () + sub_font_metrics.height ());

        icon_rect.bottom (local_path_rect.bottom ());
        icon_rect.width (icon_rect.height ());

        int next_to_icon = icon_rect.right () + alias_margin;
        alias_rect.left (next_to_icon);
        local_path_rect.left (next_to_icon);
        remote_path_rect.left (next_to_icon);

        int icon_size = icon_rect.width ();

        var options_button_visual_rect = options_button_rect (option.rect, option.direction);

        Gdk.Pixbuf pm = status_icon.pixmap (icon_size, icon_size, sync_enabled ? Gtk.IconInfo.Normal : Gtk.IconInfo.Disabled);
        painter.draw_pixmap (GLib.Style.visual_rect (option.direction, option.rect, icon_rect).left (),
            icon_rect.top (), pm);

        // only show the warning icon if the sync is running. Otherwise its
        // encoded in the status icon.
        if (warning_count > 0 && sync_ongoing) {
            GLib.Rect warn_rect;
            warn_rect.left (icon_rect.left ());
            warn_rect.top (icon_rect.bottom () - 17);
            warn_rect.width (16);
            warn_rect.height (16);

            Gtk.IconInfo warn_icon = new Gtk.IconInfo (":/client/theme/warning");
            Gdk.Pixbuf pm = warn_icon.pixmap (16, 16, sync_enabled ? Gtk.IconInfo.Normal : Gtk.IconInfo.Disabled);
            warn_rect = GLib.Style.visual_rect (option.direction, option.rect, warn_rect);
            painter.draw_pixmap (GLib.Point (warn_rect.left (), warn_rect.top ()), pm);
        }

        var palette = option.palette;

        if (GLib.Application.this.style.inherits ("GLib.Windows_vista_style")) {
            // Hack : Windows Vista's light blue is not contrasting enough for white

            // (code from GLib.Windows_vista_style.draw_control for CE_Item_view_item)
            palette.on_signal_color (Gtk.Palette.All, Gtk.Palette.HighlightedText, palette.color (Gtk.Palette.Active, Gtk.Palette.Text));
            palette.on_signal_color (Gtk.Palette.All, Gtk.Palette.Highlight, palette.base ().color ().darker (108));
        }

        Gtk.Palette.ColorGroup cg = option.state & GLib.Style.State_Enabled
            ? Gtk.Palette.Normal
            : Gtk.Palette.Disabled;
        if (cg == Gtk.Palette.Normal && ! (option.state & GLib.Style.State_Active)) {
            cg = Gtk.Palette.Inactive;
        }

        if (option.state & GLib.Style.State_Selected) {
            painter.pen (palette.color (cg, Gtk.Palette.HighlightedText));
        } else {
            painter.pen (palette.color (cg, Gtk.Palette.Text));
        }
        string elided_alias = alias_font_metrics.elided_text (alias_text, GLib.Elide_right, alias_rect.width ());
        painter.font (alias_font);
        painter.draw_text (GLib.Style.visual_rect (option.direction, option.rect, alias_rect), text_align, elided_alias);

        bool show_progess = !overall_string == "" || !item_string = "";
        if (!show_progess) {
            painter.font (sub_font);
            string elided_remote_path_text = sub_font_metrics.elided_text (
                sync_text,
                GLib.Elide_right, remote_path_rect.width ());
            painter.draw_text (GLib.Style.visual_rect (option.direction, option.rect, remote_path_rect),
                text_align, elided_remote_path_text);

            string elided_path_text = sub_font_metrics.elided_text (path_text, GLib.Elide_middle, local_path_rect.width ());
            painter.draw_text (GLib.Style.visual_rect (option.direction, option.rect, local_path_rect),
                text_align, elided_path_text);
        }

        int h = icon_rect.bottom () + margin;

        if (!conflict_texts == "")
            draw_text_box (conflict_texts, Gdk.RGBA (0xba, 0xba, 0x4d));
        if (!error_texts == "") {
            draw_text_box (error_texts, Gdk.RGBA (0xbb, 0x4d, 0x4d));
        }
        if (!info_texts == "") {
            draw_text_box (info_texts, Gdk.RGBA (0x4d, 0x4d, 0xba));
        }
        // Sync File Progress Bar: Show it if sync_file is not empty.
        if (show_progess) {
            int filename_text_height = sub_font_metrics.bounding_rect (_("File")).height ();
            int bar_height = 7; // same height as quota bar
            int overall_width = option.rect.right () - alias_margin - options_button_visual_rect.width () - next_to_icon;

            painter.save ();

            // Overall Progress Bar.
            GLib.Rect p_bRect;
            p_bRect.top (remote_path_rect.top ());
            p_bRect.left (next_to_icon);
            p_bRect.height (bar_height);
            p_bRect.width (overall_width - 2 * margin);

            GLib.Style_option_progress_bar p_bar_opt;

            p_bar_opt.state = option.state | GLib.Style.State_Horizontal;
            p_bar_opt.minimum = 0;
            p_bar_opt.maximum = 100;
            p_bar_opt.progress = overall_percent;
            p_bar_opt.orientation = GLib.Horizontal;
            p_bar_opt.rect = GLib.Style.visual_rect (option.direction, option.rect, p_bRect);
            GLib.Application.this.style.draw_control (GLib.Style.CE_Progress_bar, p_bar_opt, painter, option.widget);

            // Overall Progress Text
            GLib.Rect overall_progress_rect;
            overall_progress_rect.top (p_bRect.bottom () + margin);
            overall_progress_rect.height (filename_text_height);
            overall_progress_rect.left (p_bRect.left ());
            overall_progress_rect.width (p_bRect.width ());
            painter.font (progress_font);

            painter.draw_text (GLib.Style.visual_rect (option.direction, option.rect, overall_progress_rect),
                GLib.Align_left | GLib.Align_vCenter, overall_string);
            // painter.draw_rect (overall_progress_rect);

            painter.restore ();
        }

        painter.restore ();
        {
            GLib.Style_option_tool_button btn_opt;
            btn_opt.state = option.state;
            btn_opt.state &= ~ (GLib.Style.State_Selected | GLib.Style.State_Has_focus);
            btn_opt.state |= GLib.Style.State_Raised;
            btn_opt.arrow_type = GLib.No_arrow;
            btn_opt.sub_controls = GLib.Style.SC_Tool_button;
            btn_opt.rect = options_button_visual_rect;
            btn_opt.icon = this.icon_more;
            int e = GLib.Application.this.style.pixel_metric (GLib.Style.PM_Button_icon_size);
            btn_opt.icon_size = Gdk.Rectangle (e,e);
            GLib.Application.this.style.draw_complex_control (GLib.Style.CC_Tool_button, btn_opt, painter);
        }
    }



    /***********************************************************
    Paint an error overlay if there is an error string or
    conflict string
    ***********************************************************/
    private void draw_text_box (GLib.List<string> texts, Gdk.RGBA color) {
        GLib.Rect rect = local_path_rect;
        rect.left (icon_rect.left ());
        rect.top (h);
        rect.height (texts.length * sub_font_metrics.height () + 2 * margin);
        rect.right (option.rect.right () - margin);

        // save previous state to not mess up colours with the background (fixes issue : https://github.com/nextcloud/desktop/issues/1237)
        painter.save ();
        painter.brush (color);
        painter.pen (Gdk.RGBA (0xaa, 0xaa, 0xaa));
        painter.draw_rounded_rect (GLib.Style.visual_rect (option.direction, option.rect, rect),
            4, 4);
        painter.pen (GLib.white);
        painter.font (error_font);
        GLib.Rect text_rect = new GLib.Rect (
            rect.left () + margin,
            rect.top () + margin,
            rect.width () - 2 * margin,
            sub_font_metrics.height ()
        );

        foreach (string e_text in texts) {
            painter.draw_text (GLib.Style.visual_rect (option.direction, option.rect, text_rect), text_align,
                sub_font_metrics.elided_text (e_text, GLib.Elide_left, text_rect.width ()));
            text_rect.translate (0, text_rect.height ());
        }
        // restore previous state
        painter.restore ();

        h = rect.bottom () + margin;
    }


    /***********************************************************
    allocate each item size in listview.
    ***********************************************************/
    public Gdk.Rectangle size_hint (GLib.StyleOptionViewItem option, GLib.ModelIndex index) {
        Cairo.FontFace alias_font = make_alias_font (option.font);
        Cairo.FontFace font = option.font;

        Cairo.FontOptions font_options = new Cairo.FontOptions(font);
        Cairo.FontOptions alias_font_metrics = new alias_font_metrics (alias_font);

        var classif = ((FolderStatusModel) index.model ()).classify (index);
        if (classif == FolderStatusModel.ItemType.ADD_BUTTON) {
            int margins = alias_font_metrics.height (); // same as 2*alias_margin of paint
            Cairo.FontOptions font_options = new Cairo.FontOptions (GLib.Application.font ("GLib.PushButton"));
            GLib.StyleOptionButton opt = (GLib.StyleOption) option;
            opt.text = add_folder_text ();
            return GLib.Application.this.style.size_from_contents (
                GLib.Style.CT_Push_button, opt, font_options.size (GLib.Text_single_line, opt.text))
                    .expanded_to (GLib.Application.global_strut ())
                + Gdk.Rectangle (0, margins);
        }

        if (classif != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return GLib.Styled_item_delegate.size_hint (option, index);
        }

        // calc height
        int h = root_folder_height_without_errors (font_options, alias_font_metrics);
        // this already includes the bottom margin

        // add some space for the message boxes.
        int margin = font_options.height () / 4;
        foreach (var role in {FOLDER_CONFLICT_MESSAGE, FOLDER_ERROR_MESSAGE, FOLDER_INFO_MESSAGE}) {
            var msgs = (GLib.List<string>)index.data (DataRole.role);
            if (!msgs == "") {
                h += margin + 2 * margin + msgs.length * font_options.height ();
            }
        }

        return {0, h};
    }


    /***********************************************************
    ***********************************************************/
    public bool editor_event (Gdk.Event event, GLib.AbstractItemModel model,
        GLib.StyleOptionViewItem option, GLib.ModelIndex index) {
        switch (event.type ()) {
        case Gdk.Event.Mouse_button_press:
        case Gdk.Event.Mouse_move:
            var view = (GLib.AbstractItemView) option.widget;
            if (view) {
                var mouse_event = (GLib.MouseEvent) event;
                GLib.ModelIndex index;
                if (mouse_event.buttons ()) {
                    index = view.index_at (mouse_event.position ());
                }
                if (this.pressed_index != index) {
                    this.pressed_index = index;
                    view.viewport ().update ();
                }
            }
            break;
        case Gdk.Event.Mouse_button_release:
            this.pressed_index = GLib.ModelIndex ();
            break;
        default:
            break;
        }
        return GLib.Styled_item_delegate.editor_event (event, model, option, index);
    }


    /***********************************************************
    Return the position of the option button within the item
    ***********************************************************/
    public static GLib.Rect options_button_rect (GLib.Rect within, GLib.Layout_direction direction) {
        Cairo.FontFace font = new Cairo.FontFace ();
        Cairo.FontFace alias_font = make_alias_font (font);
        Cairo.FontOptions font_options = new Cairo.FontOptions (font);
        Cairo.FontOptions alias_font_metrics = new Cairo.FontOptions (alias_font);
        within.height (FolderStatusDelegate.root_folder_height_without_errors (font_options, alias_font_metrics));

        GLib.Style_option_tool_button opt;
        int e = GLib.Application.this.style.pixel_metric (GLib.Style.PM_Button_icon_size);
        opt.rect.size (Gdk.Rectangle (e,e));
        Gdk.Rectangle size = GLib.Application.this.style.size_from_contents (GLib.Style.CT_Tool_button, opt, opt.rect.size ()).expanded_to (GLib.Application.global_strut ());

        int margin = GLib.Application.this.style.pixel_metric (GLib.Style.PM_Default_layout_spacing);
        GLib.Rect rectangle = new GLib.Rect (
            GLib.Point (within.right () - size.width () - margin,
            within.top () + within.height () / 2 - size.height () / 2),
            size
        );
        return GLib.Style.visual_rect (direction, within, rectangle);
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Rect add_button_rect (GLib.Rect within, GLib.Layout_direction direction) {
        Cairo.FontOptions font_options = new Cairo.FontOptions (GLib.Application.font ("GLib.PushButton"));
        GLib.StyleOptionButton opt;
        opt.text = add_folder_text ();
        Gdk.Rectangle size = GLib.Application.this.style.size_from_contents (GLib.Style.CT_Push_button, opt, font_options.size (GLib.Text_single_line, opt.text)).expanded_to (GLib.Application.global_strut ());
        GLib.Rect rectangle = new GLib.Rect (
            GLib.Point (within.left (),
            within.top () + within.height () / 2 - size.height () / 2),
            size
        );
        return GLib.Style.visual_rect (direction, within, rectangle);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Rect errors_list_rect (GLib.Rect within) {
        Cairo.FontFace font = Cairo.FontFace ();
        Cairo.FontFace alias_font = make_alias_font (font);
        Cairo.FontOptions font_options = new Cairo.FontOptions (font);
        Cairo.FontOptions alias_font_metrics = new Cairo.FontOptions (alias_font);
        within.top (within.top () + FolderStatusDelegate.root_folder_height_without_errors (font_options, alias_font_metrics));
        return within;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.icon_more = LibSync.Theme.create_color_aware_icon (":/client/theme/more.svg");
    }


    /***********************************************************
    ***********************************************************/
    public static int root_folder_height_without_errors (Cairo.FontOptions font_options, Cairo.FontOptions alias_font_metrics) {
        int alias_margin = alias_font_metrics.height () / 2;
        int margin = font_options.height () / 4;

        int h = alias_margin; // margin to top
        h += alias_font_metrics.height (); // alias
        h += margin; // between alias and local path
        h += font_options.height (); // local path
        h += margin; // between local and remote path
        h += font_options.height (); // remote path
        h += margin; // bottom margin
        return h;
    }


    /***********************************************************
    ***********************************************************/
    private static Cairo.FontFace make_alias_font (Cairo.FontFace normal_font) {
        Cairo.FontFace alias_font = normal_font;
        alias_font.bold (true);
        alias_font.point_size (normal_font.point_size () + 2);
        return alias_font;
    }


    /***********************************************************
    ***********************************************************/
    private static string add_folder_text () {
        return _("Add FolderConnection Sync Connection");
    }

} // class FolderStatusDelegate

} // namespace Ui
} // namespace Occ
