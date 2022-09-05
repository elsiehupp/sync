/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestPinState : AbstractTestSyncJournalDB {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestPinState () {
    //      this.database.internal_pin_states.wipe_for_path_and_below ("");
    //      var list = this.database.internal_pin_states.raw_list ();
    //      GLib.assert_true (list.size () == 0);

    //      // Make a thrice-nested setup
    //      make ("", PinState.ALWAYS_LOCAL);
    //      make ("local", PinState.ALWAYS_LOCAL);
    //      make ("online", Common.ItemAvailability.ONLINE_ONLY);
    //      make ("inherit", PinState.INHERITED);
    //      foreach (string base_string_1 in {"local/", "online/", "inherit/"}) {
    //          make (base_string_1 + "inherit", PinState.INHERITED);
    //          make (base_string_1 + "local", PinState.ALWAYS_LOCAL);
    //          make (base_string_1 + "online", Common.ItemAvailability.ONLINE_ONLY);

    //          foreach (var base_string_2 in { "local/", "online/", "inherit/" }) {
    //              make (base_string_1 + base_string_2 + "inherit", PinState.INHERITED);
    //              make (base_string_1 + base_string_2 + "local", PinState.ALWAYS_LOCAL);
    //              make (base_string_1 + base_string_2 + "online", Common.ItemAvailability.ONLINE_ONLY);
    //          }
    //      }

    //      list = this.database.internal_pin_states.raw_list ();
    //      GLib.assert_true (list.size () == 4 + 9 + 27);

    //      // Baseline direct checks (the fallback for unset root pinstate is PinState.ALWAYS_LOCAL)
    //      GLib.assert_true (get_pin_state ("") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("nonexistant") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online/local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local/online") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("inherit/local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("inherit/online") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("inherit/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("inherit/nonexistant") == PinState.ALWAYS_LOCAL);

    //      // Inheriting checks, level 1
    //      GLib.assert_true (get_pin_state ("local/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local/nonexistant") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online/inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("online/nonexistant") == Common.ItemAvailability.ONLINE_ONLY);

    //      // Inheriting checks, level 2
    //      GLib.assert_true (get_pin_state ("local/inherit/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local/local/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local/local/nonexistant") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local/online/inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("local/online/nonexistant") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("online/inherit/inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("online/local/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online/local/nonexistant") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online/online/inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("online/online/nonexistant") == Common.ItemAvailability.ONLINE_ONLY);

    //      // Spot check the recursive variant
    //      GLib.assert_true (get_recursive ("") == PinState.INHERITED);
    //      GLib.assert_true (get_recursive ("local") == PinState.INHERITED);
    //      GLib.assert_true (get_recursive ("online") == PinState.INHERITED);
    //      GLib.assert_true (get_recursive ("inherit") == PinState.INHERITED);
    //      GLib.assert_true (get_recursive ("online/local") == PinState.INHERITED);
    //      GLib.assert_true (get_recursive ("online/local/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_recursive ("inherit/inherit/inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_recursive ("inherit/online/inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_recursive ("inherit/online/local") == PinState.ALWAYS_LOCAL);
    //      make ("local/local/local/local", PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_recursive ("local/local/local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_recursive ("local/local/local/local") == PinState.ALWAYS_LOCAL);

    //      // Check changing the root pin state
    //      make ("", Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("inherit") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("nonexistant") == Common.ItemAvailability.ONLINE_ONLY);
    //      make ("", PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("online") == Common.ItemAvailability.ONLINE_ONLY);
    //      GLib.assert_true (get_pin_state ("inherit") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_pin_state ("nonexistant") == PinState.ALWAYS_LOCAL);

    //      // Wiping
    //      GLib.assert_true (get_raw ("local/local") == PinState.ALWAYS_LOCAL);
    //      this.database.internal_pin_states.wipe_for_path_and_below ("local/local");
    //      GLib.assert_true (get_raw ("local") == PinState.ALWAYS_LOCAL);
    //      GLib.assert_true (get_raw ("local/local") == PinState.INHERITED);
    //      GLib.assert_true (get_raw ("local/local/local") == PinState.INHERITED);
    //      GLib.assert_true (get_raw ("local/local/online") == PinState.INHERITED);
    //      list = this.database.internal_pin_states.raw_list ();
    //      GLib.assert_true (list.size () == 4 + 9 + 27 - 4);

    //      // Wiping everything
    //      this.database.internal_pin_states.wipe_for_path_and_below ("");
    //      GLib.assert_true (get_raw ("") == PinState.INHERITED);
    //      GLib.assert_true (get_raw ("local") == PinState.INHERITED);
    //      GLib.assert_true (get_raw ("online") == PinState.INHERITED);
    //      list = this.database.internal_pin_states.raw_list ();
    //      GLib.assert_true (list.size () == 0);
    //  }


    //  private void make (string path, PinState state) {
    //      this.database.internal_pin_states.set_for_path (path, state);
    //      var pin_state = this.database.internal_pin_states.raw_for_path (path);
    //      GLib.assert_true (pin_state);
    //      GLib.assert_true (pin_state == state);
    //  }

} // class TestPinState

} // namespace Testing
} // namespace Occ
