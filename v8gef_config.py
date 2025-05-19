import gdb
import sys

# --- V8gef Core Configuration Settings ---
CONFIG_ACTIVE_V8_VERSION = "v8gef.active_version"
CONFIG_OFFSET_PROFILE_DIR = "v8gef.offset_profile_dir" # For later expansions
CONFIG_MAIN_CAGE_BASE_NAME = "v8gef.main_cage_base"

# --- V8 Offset Constants (Initially Hardcoded, later from profiles(todo)) ---
_V8_CONSTANTS_DB = {
    "default": { # Fallback if active_version not found
        "TARGET_V8_VERSION_NOTE": "Default - CONFIGURE FOR YOUR V8 VERSION!",
        "HEAP_OBJECT_TAG_MASK": 1,
        "HEAP_OBJECT_TAG": 1,
        "SMI_TAG_MASK": 1,
        "SMI_TAG": 0,
        "SMI_SHIFT_SIZE": 1,
    },
    "12.5.0": {
        "TARGET_V8_VERSION_NOTE": "Constants for V8 ~12.5.0",
        "HEAP_OBJECT_TAG_MASK": 1,
        "HEAP_OBJECT_TAG": 1,
        "SMI_TAG_MASK": 1,
        "SMI_TAG": 0,
        "SMI_SHIFT_SIZE": 1,
    }
}

def get_active_v8_constants():
    """Gets the constants for the currently active V8 version profile."""
    try:
        v8gef_cmd = gdb.execute("gef config v8gef.active_version", from_tty=False, to_string=True).strip()
        active_version_str = v8gef_cmd.split()[-1] if v8gef_cmd else "default"
    except gdb.error:
        active_version_str = "default"  # Fallback if setting cannot be retrieved
        
    constants = _V8_CONSTANTS_DB.get(active_version_str, _V8_CONSTANTS_DB["default"])
    return constants

def get_v8_constant(name):
    """Helper to get a specific constant for the active V8 version."""
    active_constants = get_active_v8_constants()
    if name not in active_constants:
        # Fallback to default if not in specific version, or error
        default_constants = _V8_CONSTANTS_DB["default"]
        if name not in default_constants:
            raise KeyError(f"V8gef constant '{name}' not found in active or default profile.")
        # gef_print(f"V8gef: Using default for constant '{name}'", color="yellow")
        return default_constants[name]
    return active_constants[name]
