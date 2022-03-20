/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestPinState : AbstractTestSyncJournalDB {

    /***********************************************************
    ***********************************************************/
    private TestPinState () {
        this.database.internal_pin_states.wipe_for_path_and_below ("");
        var list = this.database.internal_pin_states.raw_list ();
        GLib.assert_true (list.size () == 0);

        // Make a thrice-nested setup
        make ("", PinState.PinState.ALWAYS_LOCAL);
        make ("local", PinState.PinState.ALWAYS_LOCAL);
        make ("online", Vfs.ItemAvailability.ONLINE_ONLY);
        make ("inherit", PinState.PinState.INHERITED);
        foreach (string base_string_1 in {"local/", "online/", "inherit/"}) {
            make (base_string_1 + "inherit", PinState.PinState.INHERITED);
            make (base_string_1 + "local", PinState.PinState.ALWAYS_LOCAL);
            make (base_string_1 + "online", Vfs.ItemAvailability.ONLINE_ONLY);

            foreach (var base_string_2 in { "local/", "online/", "inherit/" }) {
                make (base_string_1 + base_string_2 + "inherit", PinState.PinState.INHERITED);
                make (base_string_1 + base_string_2 + "local", PinState.PinState.ALWAYS_LOCAL);
                make (base_string_1 + base_string_2 + "online", Vfs.ItemAvailability.ONLINE_ONLY);
            }
        }

        list = this.database.internal_pin_states.raw_list ();
        GLib.assert_true (list.size () == 4 + 9 + 27);

        // Baseline direct checks (the fallback for unset root pinstate is PinState.ALWAYS_LOCAL)
        GLib.assert_true (get_pin_state ("") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("inherit/online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("inherit/nonexistant") == PinState.PinState.ALWAYS_LOCAL);

        // Inheriting checks, level 1
        GLib.assert_true (get_pin_state ("local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);

        // Inheriting checks, level 2
        GLib.assert_true (get_pin_state ("local/inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("local/online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/inherit/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);

        // Spot check the recursive variant
        GLib.assert_true (get_recursive ("") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("inherit") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("inherit/inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("inherit/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_recursive ("inherit/online/local") == PinState.PinState.ALWAYS_LOCAL);
        make ("local/local/local/local", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("local/local/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("local/local/local/local") == PinState.PinState.ALWAYS_LOCAL);

        // Check changing the root pin state
        make ("", Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);
        make ("", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("nonexistant") == PinState.PinState.ALWAYS_LOCAL);

        // Wiping
        GLib.assert_true (get_raw ("local/local") == PinState.PinState.ALWAYS_LOCAL);
        this.database.internal_pin_states.wipe_for_path_and_below ("local/local");
        GLib.assert_true (get_raw ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_raw ("local/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local/local/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local/local/online") == PinState.PinState.INHERITED);
        list = this.database.internal_pin_states.raw_list ();
        GLib.assert_true (list.size () == 4 + 9 + 27 - 4);

        // Wiping everything
        this.database.internal_pin_states.wipe_for_path_and_below ("");
        GLib.assert_true (get_raw ("") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("online") == PinState.PinState.INHERITED);
        list = this.database.internal_pin_states.raw_list ();
        GLib.assert_true (list.size () == 0);
    }


    private void make (string path, PinState state) {
        this.database.internal_pin_states.set_for_path (path, state);
        var pin_state = this.database.internal_pin_states.raw_for_path (path);
        GLib.assert_true (pin_state);
        GLib.assert_true (pin_state == state);
    }

} // class TestPinState

} // namespace Testing
} // namespace Occ
