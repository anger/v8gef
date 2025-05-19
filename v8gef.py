import gdb
import os


v8gef_dir = os.path.dirname(__file__)

gef_print(Color.colorify(f"[V8gef] Loading from: {v8gef_dir}", "blue"))

@register_command
class V8GefCommand(GenericCommand):
    """V8 debugging extension for GEF."""
    _cmdline_ = "v8gef"
    _syntax_  = f"{_cmdline_} (config|version|help)"
    _aliases_ = []
    
    def __init__(self):
        super().__init__(prefix=True)
        self.add_setting("active_version", "0.0.0", "Active V8 version profile for V8gef offsets (e.g., '12.5.212').")
        self.add_setting("offset_profile_dir", "", "Directory for V8 offset profiles")
        self.add_setting("main_cage_base", "0x0", "V8 main pointer compression heap cage base address (hex)")
        return
        
    def do_invoke(self, argv):
        self.usage()
        return

@register_command
class V8GefConfigCommand(GenericCommand):
    """V8gef config command."""
    _cmdline_ = "v8gef config"
    _syntax_  = f"{_cmdline_} [setting_name] [setting_value]"
    
    def __init__(self):
        super().__init__(complete=gdb.COMPLETE_NONE)
        return
        
    def do_invoke(self, argv):
        argc = len(argv)
        
        if argc == 0:
            # Print all v8gef settings
            gdb.execute("gef config v8gef", from_tty=False)
            return

        if argc == 1:
            # Print specific setting
            setting_name = argv[0]
            gdb.execute(f"gef config v8gef.{setting_name}", from_tty=False)
            return
            
        if argc == 2:
            # Set specific setting
            setting_name, setting_value = argv
            gdb.execute(f"gef config v8gef.{setting_name} {setting_value}", from_tty=False)
            gef_print(f"[V8gef] Set {setting_name} = {setting_value}")
            return
            
        # Invalid number of arguments
        err(f"Invalid arguments: {self._syntax_}")
        return

V8GefCommand()
V8GefConfigCommand()