import gdb

def interpret_v8_tagged_value(val_int, arch_ptr_size, v8_constants):
    """
    Interprets a raw integer value according to V8 tagging.
    Uses v8_constants dictionary for SMI_TAG_MASK, SMI_TAG, SMI_SHIFT_SIZE, etc.
    Returns a list of human-readable string lines describing the value.
    """
    output_lines = []
    
    SMI_TAG_MASK = v8_constants["SMI_TAG_MASK"]
    SMI_TAG = v8_constants["SMI_TAG"]
    SMI_SHIFT_SIZE = v8_constants["SMI_SHIFT_SIZE"]
    HEAP_OBJECT_TAG_MASK = v8_constants["HEAP_OBJECT_TAG_MASK"]
    HEAP_OBJECT_TAG = v8_constants["HEAP_OBJECT_TAG"]

    if (val_int & SMI_TAG_MASK) == SMI_TAG:
        raw_shifted_val = val_int >> SMI_SHIFT_SIZE
        
        num_smi_payload_bits = arch_ptr_size * 8 - SMI_SHIFT_SIZE
        sign_bit_mask_in_payload = 1 << (num_smi_payload_bits - 1)

        if raw_shifted_val & sign_bit_mask_in_payload:
            # Negative number
            smi_int_val_interpreted = raw_shifted_val - (1 << num_smi_payload_bits)
        else:
            # Positive number
            smi_int_val_interpreted = raw_shifted_val

        output_lines.append(f"  Type: {Color.colorify('Smi (Small Integer)', 'green')}")
        output_lines.append(f"  Interpreted Int Value: {Color.colorify(str(smi_int_val_interpreted), 'bold green')} (Raw shifted: {hex(raw_shifted_val)})")
    elif (val_int & HEAP_OBJECT_TAG_MASK) == HEAP_OBJECT_TAG:
        untagged_address = val_int & ~HEAP_OBJECT_TAG_MASK
        output_lines.append(f"  Type: {Color.colorify('Tagged HeapObject Pointer', 'cyan')}")
        output_lines.append(f"  Untagged Address: {Color.colorify(hex(untagged_address), 'bold cyan')}")
        try:
            ptr_type = gdb.lookup_type('unsigned long long')
            pointed_to_value = int(gdb.Value(untagged_address).cast(ptr_type.pointer()).dereference())
            output_lines.append(f"  Points to (first {arch_ptr_size} bytes): {Color.colorify(hex(pointed_to_value), 'purple')} (Potential Map Ptr)")
        except gdb.MemoryError:
            output_lines.append(f"  Points to: {Color.colorify('<unreadable memory>', 'red')}")
        except Exception as e:
            output_lines.append(f"  Points to: {Color.colorify(f'<error reading memory: {e}>', 'red')}")
    else:
        output_lines.append(f"  Type: {Color.colorify('Unknown V8 Value Format', 'yellow')}")
    
    return output_lines
