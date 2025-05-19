import gdb
import sys
import argparse

# Future heap commands will be implemented here

# --- V8 Heap Commands ---

@register_command
class V8DecompressCommand(GenericCommand):
    """v8_decompress: Decompresses a V8 compressed 32-bit pointer payload to a full 64-bit tagged HeapObject pointer"""
    _cmdline_ = "v8_decompress"
    _category_ = "v8gef"
    _aliases_ = ["v8dc"]
    _example_ = f"{_cmdline_} $rbx+0x10 [0x555553000000]"

    parser = argparse.ArgumentParser(prog=_cmdline_)
    parser.add_argument("address", type=str, help="Address where the 32-bit compressed pointer is stored")
    parser.add_argument("cage_base", type=str, nargs="?", help="(Optional) V8 heap cage base address. If not provided, uses v8gef.main_cage_base configuration")
    _syntax_ = parser.format_help()

    def __init__(self):
        super().__init__(complete=gdb.COMPLETE_LOCATION)
        return

    @property
    def _note_(self):
        return "Decompresses a V8 compressed 32-bit pointer payload stored at <address> to 64-bit tagged HeapObject pointer"

    @parse_args
    def do_invoke(self, args):
        # Parse field address argument
        try:
            field_addr_expr = args.address
            field_addr = int(gdb.parse_and_eval(field_addr_expr))
        except Exception as e:
            err(f"Error evaluating field address expression '{field_addr_expr}': {e}")
            return

        # Get cage base (from argument or config)
        try:
            if args.cage_base:
                cage_base = int(gdb.parse_and_eval(args.cage_base))
            else:
                # Get cage base from gef config
                cage_base_str = gdb.execute(f"gef config {CONFIG_MAIN_CAGE_BASE_NAME}", from_tty=False, to_string=True).strip()
                cage_base = int(cage_base_str.split()[-1], 16)
                
                if cage_base == 0:
                    err(f"Cage base is set to 0. Please configure it with: gef config {CONFIG_MAIN_CAGE_BASE_NAME} <hex_address>")
                    return
        except Exception as e:
            err(f"Error getting cage base: {e}")
            return

        # Read the 32-bit compressed payload from memory
        try:
            # Read 4 bytes (32 bits) from memory
            compressed_payload = int.from_bytes(gdb.selected_inferior().read_memory(field_addr, 4).tobytes(), byteorder="little")
        except Exception as e:
            err(f"Error reading memory at {hex(field_addr)}: {e}")
            return

        # Calculate decompressed tagged address
        decompressed_tagged_address = cage_base + compressed_payload

        # Print intermediate values
        gef_print(Color.colorify("[V8gef] Decompressing V8 Pointer:", "blue bold"))
        gef_print(f"Field Address            : {Color.colorify(hex(field_addr), 'bold')}")
        gef_print(f"  Raw Compressed Val (32b): {Color.colorify(hex(compressed_payload), 'bold')} (Decimal: {compressed_payload})")
        gef_print(f"V8 Heap Cage Base        : {Color.colorify(hex(cage_base), 'bold')}")
        gef_print(f"Decompressed Tagged Addr : {Color.colorify(hex(decompressed_tagged_address), 'bold')}")

        # Interpret the decompressed tagged address
        gef_print(Color.colorify(f"--- Interpreting Decompressed Address ({hex(decompressed_tagged_address)}): ---", "blue"))
        output = [f"  Input Value: {Color.colorify(hex(decompressed_tagged_address), 'bold blue')} (Decimal: {decompressed_tagged_address})"]
        active_constants = get_active_v8_constants()  # Get current V8 constants
        output.extend(interpret_v8_tagged_value(decompressed_tagged_address, current_arch.ptrsize, active_constants))
        gef_print("\n".join(output))
        return


V8DecompressCommand()

