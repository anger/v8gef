# v8gef

**v8gef** is a suite of GDB commands designed to assist V8 JavaScript engine security researchers and developers. It integrates with the [GEF (GDB Enhanced Features)](https://github.com/hugsy/gef) extension, and is primarily developed and tested against the [bata24/gef fork](https://github.com/bata24/gef).

## Features

`v8gef` provides helpful commands for inspecting V8 internals, including:

*   **V8 Value Interpretation (`v8_check_value` or `v8cv`):** Interprets a GDB value as a V8 Smi (Small Integer) or a tagged HeapObject pointer, providing insights into its type and properties based on active V8 version profiles.
*   **Compressed Pointer Decompression (`v8_decompress` or `v8dc`):** Decompresses V8's 32-bit compressed pointers (used in pointer compression) to their full 64-bit tagged HeapObject pointer, using a configurable heap cage base.
*   **Configuration Management (`v8gef config`):** Allows viewing and setting `v8gef`-specific configurations, such as:
    *   `active_version`: The active V8 version profile for offsets (e.g., "12.5.212").
    *   `offset_profile_dir`: Directory for V8 offset profiles.
    *   `main_cage_base`: The V8 main pointer compression heap cage base address (hexadecimal).
    * Much more planned.
* Much more is on the way

## Planned Features

The following are commands I would like to implement in the near future:

| Category                      | Command Name                     | Brief Description                                                                                                |
| :---------------------------- | :------------------------------- | :--------------------------------------------------------------------------------------------------------------- |
| **Heap Inspection**         | `v8_obj`                         | Inspect V8 HeapObjects with type-specific field breakdown and recursion.                     |
|                               | `v8_map_details`                 | Exhaustive dump of a V8 `Map` object's fields, descriptors, and transitions.                                   |
|                               | `v8_heap_census_lite`            | Simplified V8 heap scan to count object occurrences by Map pointer.                                              |
|                               | `v8_heap_object_diff`            | Intelligently compares two V8 HeapObjects, highlighting semantic differences based on V8 tagging.              |
|                               | `v8_context_ancestry`            | Walks and displays the V8 `Context` chain from a given starting point.                                         |
| **Sandbox Analysis**          | `v8_ept_read`                    | Inspects an External Pointer Table (EPT) entry, verifies tag, and resolves the external pointer.                 |
|                               | `v8_trusted_ptr_read`            | Similar to `v8_ept_read` but for V8's Trusted Pointer Table.                                                   |
|                               | `v8_sandbox_layout`              | Displays configured/determined base addresses for sandbox regions (cage, EPT, Trusted Space).                  |
|                               | `v8_addr_info`                   | Reports if an address falls within known V8 regions (heap, EPT, JIT, etc.).                                    |
| **JIT & Optimized Code**    | `v8_jit_code_info`               | Displays detailed information about a V8 `Code` object, especially JIT-compiled code.                            |
|                               | `v8_map_transitions_graph`       | Visualizes V8 Map transitions by parsing `d8 --trace-maps` output.                                             |
|                               | `v8_deopt_monitor`               | Analyzes V8 deoptimization events (live or from log), showing reasons and locations.                           |
|                               | `v8_sfi_from_jit`                | Attempts to find the `SharedFunctionInfo` (SFI) object from an address within JIT code.                        |
| **WebAssembly (Wasm)**      | `v8_wasm_module_info`            | Displays key metadata from a `WasmModuleObject` or `WasmInstanceObject`.                                       |
|                               | `v8_wasm_disas`                  | Locates and disassembles a specific Wasm function's machine code.                                                |
| **Garbage Collector (GC)**    | `v8_gc_phase_bp`                 | Sets breakpoints on key V8 C++ functions marking GC phase transitions.                                           |
| **Exploit Development Aids**  | `v8_write_field`                 | Writes a value to a V8 object field using symbolic names or raw offsets.                                         |
|                               | `v8_watch_field`                 | Sets a GDB watchpoint on a V8 object field using symbolic names or raw offsets.                                  |
|                               | `v8_toggle_field_tag`            | Modifies a V8 pointer/Smi tag in a field to test tag corruption.                                                 |
|                               | `v8_jit_spray_verify`            | Scans memory to verify presence, density, and alignment of sprayed JIT gadget bytes.                             |
| **Environment & Config**    | `v8_info`                        | Displays detected/configured V8 version, build features, and active `v8gef` parameters.                        |
|                               | `v8_offsets_load`                | Loads a V8 version-specific offset profile.                                                                      |
|                               | `v8_offsets_show`                | Displays the currently loaded and active offset profile.                                                         |
| **Fuzzing & Triage Aids**   | `v8_fuzzil_lifted_guess`         | Heuristically guesses FuzzIL operations from a JS statement.                                                     |
|                               | `v8_repro_fuzzilli_assist`       | Aids debugging Fuzzilli test cases in a REPRL-patched `d8` by setting strategic breakpoints.                   |

I'm always open for ideas, please feel free to reach out if you have any!

## Prerequisites

*   [GDB](https://www.gnu.org/software/gdb/)
*   [GEF (GDB Enhanced Features)](https://github.com/hugsy/gef) - The [bata24/gef fork](https://github.com/bata24/gef) is highly recommended as `v8gef` is developed and tested against it.

## Installation & Setup

1.  **Ensure GEF is installed and loaded.**
    If you don't have GEF, you can install the bata24/gef fork:
    ```bash
    wget -q https://raw.githubusercontent.com/bata24/gef/dev/install-uv.sh -O- | sudo sh
    ```

2.  **Clone the v8gef repository:**
    ```bash
    git clone https://github.com/anger/v8gef.git
    ```

3.  **Source v8gef in your GDB init file:**
    Add the following line to your `~/.gdbinit` file, *after* the line that sources GEF:
    ```bash
    # tools/v8 gdbinit
    source /path/to/v8gef/gdbinit

    # v8gef modules
    source /path/to/v8gef/v8gef.py
    source /path/to/v8gef/v8gef_config.py
    source /path/to/v8gef/v8gef_utils.py
    source /path/to/v8gef/v8gef_commands_core.py
    source /path/to/v8gef/v8gef_commands_heap.py
    ```

## Contributing

Contributions, issues, and feature requests are welcome! Please feel free to open an issue or submit a pull request.