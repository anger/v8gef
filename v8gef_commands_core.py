import gdb
import argparse


# ---- V8gef Commands ----
@register_command
class V8CheckValueCommand(GenericCommand):
    """v8_check_value: Interprets a GDB value as a V8 smi or a tagged HeapObject pointer"""
    _cmdline_ = "v8_check_value"
    _category_ = "v8gef"
    _aliases_ = ["v8cv"]
    _example_ = f"{_cmdline_} 0xFFFFFFFFFFFFFFF0"

    parser = argparse.ArgumentParser(prog=_cmdline_)
    parser.add_argument("value", type=str, help="The value to interpret as a V8 object")
    _syntax_ = parser.format_help()

    def __init__(self):
        super().__init__(complete=gdb.COMPLETE_SYMBOL)
        return

    @property
    def _note_(self):
        active_constants = get_active_v8_constants()
        return f"Interprets V8 values. Active V8 profile: {active_constants.get('TARGET_V8_VERSION_NOTE', 'Default - CONFIGURE!')}"

    @parse_args
    def do_invoke(self, args):
        try:
            val_str = args.value
            gdb_val = gdb.parse_and_eval(val_str)
            if gdb_val.type.code == gdb.TYPE_CODE_PTR:
                val_int = int(gdb_val.cast(gdb.lookup_type("unsigned long long")))
            else:
                val_int = int(gdb_val)
        except Exception as e:
            gef_print(Color.colorify(f"Error evaluating expression '{val_str}': {e}", "red"))
            return
        
        output = [f"Input Value: {Color.colorify(hex(val_int), 'bold blue')} (Decimal: {val_int})"]
        active_constants = get_active_v8_constants() # Get current V8 constants
        output.extend(interpret_v8_tagged_value(val_int, current_arch.ptrsize, active_constants))
        gef_print("\n".join(output))
        return


V8CheckValueCommand()