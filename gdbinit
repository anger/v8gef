# Copyright 2014 the V8 project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Print tagged object.
define job
call (void) _v8_internal_Print_Object((void*)($arg0))
end
document job
Print a v8 JavaScript object
Usage: job tagged_ptr
end
# Print content of V8 handles.
python
import gdb
import gdb.printing
import gdb.types
class PrintV8HandleCommand(gdb.Command):
  """Print content of a V8 object, accessed through a handle."""
  def __init__(self, command_name):
    self.command_name = command_name
    super(PrintV8HandleCommand, self).__init__(command_name, gdb.COMMAND_DATA)
  @staticmethod
  def print_direct(value, from_tty):
    CMD = "call (void) _v8_internal_Print_Object((v8::internal::Address*)({}))"
    gdb.execute(CMD.format(value.format_string()), from_tty)
    return True
  @staticmethod
  def print_indirect(value, from_tty):
    CMD = "call (void) _v8_internal_Print_Object(*(v8::internal::Address**)({}))"
    gdb.execute(CMD.format(value.format_string()), from_tty)
    return True
  def invoke(self, arg, from_tty):
    argv = gdb.string_to_argv(arg)
    if len(argv) != 1:
      raise gdb.GdbError("{} takes exactly one argument.".format(
          self.command_name))
    value = gdb.parse_and_eval(argv[0])
    if not self.print_handle(value, from_tty):
      raise gdb.GdbError("{} cannot print a value of type {}".format(
        self.command_name, value.type))
class PrintV8LocalCommand(PrintV8HandleCommand):
  """Print content of v8::(Maybe)?Local."""
  def __init__(self):
    super(PrintV8LocalCommand, self).__init__("print-v8-local")
  def print_handle(self, value, from_tty):
    if gdb.types.get_basic_type(value.type).code != gdb.TYPE_CODE_STRUCT:
      return False
    # After https://crrev.com/c/4335544, v8::MaybeLocal contains a local_.
    if gdb.types.has_field(value.type, "local_"):
      value = value["local_"]
    # After https://crrev.com/c/4335544, v8::Local contains a location_.
    if gdb.types.has_field(value.type, "location_"):
      return self.print_indirect(value["location_"], from_tty)
    # Before https://crrev.com/c/4335544, v8::Local contained a val_.
    if gdb.types.has_field(value.type, "val_"):
      return self.print_indirect(value["val_"], from_tty)
    # With v8_enable_direct_handle=true, v8::Local contains a ptr_.
    if gdb.types.has_field(value.type, "ptr_"):
      return self.print_direct(value["ptr_"], from_tty)
    # We don't know how to print this...
    return False
class PrintV8InternalHandleCommand(PrintV8HandleCommand):
  """Print content of v8::internal::(Maybe)?(Direct|Indirect)?Handle."""
  def __init__(self):
    super(PrintV8InternalHandleCommand, self).__init__("print-v8-internal-handle")
  def print_handle(self, value, from_tty):
    if gdb.types.get_basic_type(value.type).code != gdb.TYPE_CODE_STRUCT:
      return False
    # Indirect handles contain a location_.
    if gdb.types.has_field(value.type, "location_"):
      return self.print_indirect(value["location_"], from_tty)
    # With v8_enable_direct_handle=true, direct handles contain a obj_.
    if gdb.types.has_field(value.type, "obj_"):
      return self.print_direct(value["obj_"], from_tty)
    # Without v8_enable_direct_handle=true, direct handles contain a handle_.
    if gdb.types.has_field(value.type, "handle_"):
      return self.print_handle(value["handle_"], from_tty)
    # We don't know how to print this...
    return False
PrintV8LocalCommand()
PrintV8InternalHandleCommand()
end
python
class TryAliasCommand(gdb.Command):
  """Create an alias, but don't error if it already exists."""
  def __init__ (self):
    super (TryAliasCommand, self).__init__ ("try-alias", gdb.COMMAND_FILES)
  def invoke (self, arg, from_tty):
    try:
      gdb.execute('alias ' + arg)
    except:
      pass
TryAliasCommand()
end
try-alias jlh = print-v8-local
try-alias jl = print-v8-local
try-alias jh = print-v8-internal-handle
# Print Code objects containing given PC.
define jco
  if $argc == 0
    call (void) _v8_internal_Print_Code((void*)($pc))
  else
    call (void) _v8_internal_Print_Code((void*)($arg0))
  end
end
document jco
Print a v8 Code object from an internal code address
Usage: jco pc
end
# Print JSDispatchEntry object in the JSDispatchTable with the given dispatch handle
define jdh
  call (void) _v8_internal_Print_Dispatch_Handle((uint32_t)($arg0))
end
document jdh
Print JSDispatchEntry object in the JSDispatchTable with the given dispatch handle
Usage: jdh dispatch_handle
end
# Print Code objects assembly code surrounding given PC.
define jca
  if $argc == 0
    call (void) _v8_internal_Print_OnlyCode((void*)($pc), 30)
  else
    if $argc == 1
      call (void) _v8_internal_Print_OnlyCode((void*)($arg0), 30)
    else
      call (void) _v8_internal_Print_OnlyCode((void*)($arg0), (size_t)($arg1))
    end
  end
end
document jca
Print a v8 Code object assembly code from an internal code address
Usage: jca pc
end
# Print TransitionTree.
define jtt
call (void) _v8_internal_Print_TransitionTree((void*)($arg0), false)
end
document jtt
Print the complete transition tree starting at the given v8 map.
Usage: jtt tagged_ptr
end
# Print TransitionTree starting from the root map.
define jttr
call (void) _v8_internal_Print_TransitionTree((void*)($arg0), true)
end
document jttr
Print the complete transition tree starting at the root map of the given v8 map.
Usage: jttr tagged_ptr
end
# Print JavaScript stack trace.
define jst
call (void) _v8_internal_Print_StackTrace()
end
document jst
Print the current JavaScript stack trace
Usage: jst
end
# Print TurboFan graph node.
define pn
call _v8_internal_Node_Print((void*)($arg0))
end
document pn
Print a v8 TurboFan graph node
Usage: pn node_address
end
# Skip the JavaScript stack.
define jss
set $js_entry_sp=v8::internal::Isolate::Current()->thread_local_top()->js_entry_sp_
set $rbp=*(void**)$js_entry_sp
set $rsp=$js_entry_sp + 2*sizeof(void*)
set $pc=*(void**)($js_entry_sp+sizeof(void*))
end
document jss
Skip the jitted stack on x64 to where we entered JS last.
Usage: jss
end
# Print v8::FunctionCallbackInfo<T>& info.
define jfci
call _v8_internal_Print_FunctionCallbackInfo((void*)(&$arg0))
end
document jfci
Print v8::FunctionCallbackInfo<T>& info.
Usage: jfci info
end
# Print v8::PropertyCallbackInfo<T>& info.
define jpci
call _v8_internal_Print_PropertyCallbackInfo((void*)(&$arg0))
end
document jpci
Print v8::PropertyCallbackInfo<T>& info.
Usage: jpci info
end
# Print whether the object is marked, the mark-bit cell and index. The address
# of the cell is handy for reverse debugging to check when the object was
# marked/unmarked.
define jomb
call _v8_internal_Print_Object_MarkBit((void*)($arg0))
end
document jomb
Print whether the object is marked, the markbit cell and index.
Usage: jomb tagged_ptr
end
# Execute a simulator command.
python
import gdb
class SimCommand(gdb.Command):
  """Sim the current program."""
  def __init__ (self):
    super (SimCommand, self).__init__ ("sim", gdb.COMMAND_SUPPORT)
  def invoke (self, arg, from_tty):
    arg_bytes = arg.encode("utf-8") + b'\0'
    arg_c_string = gdb.Value(arg_bytes, gdb.lookup_type('char').array(len(arg_bytes) - 1))
    cmd_func = gdb.selected_frame().read_var("_v8_internal_Simulator_ExecDebugCommand")
    cmd_func(arg_c_string)
SimCommand()
end
# Print stack trace with assertion scopes.
define bta
python
import re
frame_re = re.compile("^#(\d+)\s*(?:0x[a-f\d]+ in )?(.+) \(.+ at (.+)")
assert_re = re.compile("^\s*(\S+) = .+<v8::internal::Per\w+AssertScope<v8::internal::(\S*), (false|true)>")
btl = gdb.execute("backtrace full", to_string = True).splitlines()
for l in btl:
  match = frame_re.match(l)
  if match:
    print("[%-2s] %-60s %-40s" % (match.group(1), match.group(2), match.group(3)))
  match = assert_re.match(l)
  if match:
    if match.group(3) == "false":
      prefix = "Disallow"
      color = "\033[91m"
    else:
      prefix = "Allow"
      color = "\033[92m"
    print("%s -> %s %s (%s)\033[0m" % (color, prefix, match.group(2), match.group(1)))
end
end
document bta
Print stack trace with assertion scopes
Usage: bta
end
# Search for a pointer inside all valid pages.
define space_find
  set $space = $arg0
  set $current_page = $space->first_page()
  while ($current_page != 0)
    printf "#   Searching in %p - %p\n", $current_page->area_start(), $current_page->area_end()-1
    find $current_page->area_start(), $current_page->area_end()-1, $arg1
    set $current_page = $current_page->next_page()
  end
end
define heap_find
  set $heap = v8::internal::Isolate::Current()->heap()
  printf "# Searching for %p in old_space  ===============================\n", $arg0
  space_find $heap->old_space() ($arg0)
  printf "# Searching for %p in map_space  ===============================\n", $arg0
  space_find $heap->map_space() $arg0
  printf "# Searching for %p in code_space ===============================\n", $arg0
  space_find $heap->code_space() $arg0
end
document heap_find
Find the location of a given address in V8 pages.
Usage: heap_find address
end
# The 'disassembly-flavor' command is only available on i386 and x84_64.
python
try:
  gdb.execute("set disassembly-flavor intel")
except gdb.error:
  pass
end
# Configuring ASLR may not be possible on some platforms, such running via the
# `rr` debugger.
python
try:
  gdb.execute("set disable-randomization off")
except gdb.error:
  pass
end
# Install a handler whenever the debugger stops due to a signal. It walks up the
# stack looking for V8_Dcheck / V8_Fatal / OS::DebugBreak frame and moves the
# frame to the one above it so it's immediately at the line of code that
# triggered the stop condition.
python
def v8_stop_handler(event):
  frame = gdb.selected_frame()
  select_frame = None
  message = None
  count = 0
  # Limit stack scanning since the frames we look for are near the top anyway,
  # and otherwise stack overflows can be very slow.
  while frame is not None and count < 10:
    count += 1
    # If we are in a frame created by gdb (e.g. for `(gdb) call foo()`), gdb
    # emits a dummy frame between its stack and the program's stack. Abort the
    # walk if we see this frame.
    if frame.type() == gdb.DUMMY_FRAME: break
    frame_name = frame.name()
    if frame_name is None:
      frame = frame.older()
      continue
    if frame_name == 'V8_Dcheck' or frame_name.endswith('::DefaultDcheckHandler'):
      try:
        frame_message = gdb.lookup_symbol('message', frame.block())[0]
        if frame_message:
          message = frame_message.value(frame).string()
      except:
        pass
      select_frame = frame.older()
    if any([
        frame_name.startswith('V8_Fatal'),
        frame_name == 'v8::base::OS::DebugBreak',
        frame_name == '__GI_abort',
        frame_name == '__GI_raise',
        frame_name == 'v8::base::OS::Abort',
        frame_name == 'v8::Utils::ApiCheck',
      ]):
      select_frame = frame.older()
    frame = frame.older()
  if select_frame is not None:
    select_frame.select()
    gdb.execute('frame')
    if message:
      print('==> DCHECK error: {}'.format(message))
gdb.events.stop.connect(v8_stop_handler)
end
# Code imported from chromium/src/tools/gdb/gdbinit
python
import os
import subprocess
import sys
compile_dirs = set()
src_dir = None
def get_current_debug_file_directories():
  dir = gdb.execute("show debug-file-directory", to_string=True)
  dir = dir[
      len('The directory where separate debug symbols are searched for is "'
         ):-len('".') - 1]
  return set(dir.split(":"))
def add_debug_file_directory(dir):
  # gdb has no function to add debug-file-directory, simulates that by using
  # `show debug-file-directory` and `set debug-file-directory <directories>`.
  current_dirs = get_current_debug_file_directories()
  current_dirs.add(dir)
  gdb.execute(
      "set debug-file-directory %s" % ":".join(current_dirs), to_string=True)
def load_libcxx_pretty_printers(src_dir):
  libcxx_pretty_printers = os.path.join(src_dir, 'third_party', 'libc++', 'src',
                                        'utils', 'gdb', 'libcxx')
  if not os.path.isdir(libcxx_pretty_printers):
    return
  sys.path.insert(1, libcxx_pretty_printers)
  from printers import register_libcxx_printer_loader
  register_libcxx_printer_loader()
def set_src_dir(compile_dir):
  global src_dir
  git = subprocess.Popen(
      ['git', '-C', compile_dir, 'rev-parse', '--show-toplevel'],
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE)
  src_dir, _ = git.communicate()
  if git.returncode:
    return
  if isinstance(src_dir, str):
    src_dir = src_dir.rstrip()
  else:
    src_dir = src_dir.decode('utf-8').rstrip()
  # If there's no LICENSE.v8 file in the repo root, we got the wrong git repo.
  # The most common way to have this happen is to be in a git checkout of
  # another project that vendors chromium in its own third_party directory. In
  # that case, try falling back to the current working directory.
  if not os.path.isfile(os.path.join(src_dir, 'LICENSE.v8')):
    src_dir = os.path.abspath(os.getcwd())
  load_libcxx_pretty_printers(src_dir)
def newobj_handler(event):
  global compile_dirs
  compile_dir = os.path.dirname(event.new_objfile.filename)
  if not compile_dir:
    return
  if compile_dir in compile_dirs:
    return
  compile_dirs.add(compile_dir)
  # Add source path
  gdb.execute("dir %s" % compile_dir)
  # Need to tell the location of .dwo files.
  # https://sourceware.org/gdb/onlinedocs/gdb/Separate-Debug-Files.html
  # https://crbug.com/603286#c35
  add_debug_file_directory(compile_dir)
  
  global src_dir
  if not src_dir:
    set_src_dir(compile_dir)
# Event hook for newly loaded objfiles.
# https://sourceware.org/gdb/onlinedocs/gdb/Events-In-Python.html
gdb.events.new_objfile.connect(newobj_handler)
gdb.execute("set environment V8_GDBINIT_SOURCED=1")
end
### CppGC helpers.
# Pretty printer for cppgc::Member.
python
import re
class CppGCMemberPrinter(object):
  """Print cppgc Member types."""
  def __init__(self, val, category, pointee_type):
    self.val = val
    self.category = category
    self.pointee_type = pointee_type
  def to_string(self):
    pointer = gdb.parse_and_eval(
        "_cppgc_internal_Uncompress_Member((void*){})".format(
            self.val.address))
    return "{}Member<{}> pointing to {}".format(
        '' if self.category is None else self.category, self.pointee_type,
        pointer)
  def display_hint(self):
    return "{}Member<{}>".format('' if self.category is None else self.category,
                                 self.pointee_type)
def cppgc_pretty_printers(val):
  typename = val.type.name or val.type.tag or str(val.type)
  regex = re.compile("^(cppgc|blink)::(Weak|Untraced)?Member<(.*)>$")
  match = regex.match(typename)
  if match is not None:
    return CppGCMemberPrinter(
        val, category=match.group(2), pointee_type=match.group(3))
  # The member type might have been obscured by typedefs and template
  # arguments. Fallback to using the underlying type.
  real_type = val.type.strip_typedefs()
  if (real_type.name is not None and
      real_type.name.startswith('cppgc::internal::BasicMember')):
    inner_type = real_type.template_argument(0)
    return CppGCMemberPrinter(
        val, category='Basic', pointee_type=inner_type.name)
  return None
gdb.pretty_printers.append(cppgc_pretty_printers)
class TaggedPrintCommand(gdb.Command):
    """
    The equivalent of the print command that deals with tagged objects
    Usage: tp <expression>
    Example: tp Isolate::Current()->context()->get(3)
    """
    def __init__(self):
        super(TaggedPrintCommand, self).__init__("tp", gdb.COMMAND_DATA, gdb.COMPLETE_EXPRESSION)
    def invoke(self, arg, from_tty):
        """Called when the 'tp' command is invoked."""
        try:
            # Split the expression by '->' to handle chained calls.
            parts = arg.split("->")
            if not parts:
                print("Error: No expression provided.")
                return
            if len(parts) == 1:
              gdb.execute(f"print {parts[0]}")
            else:
              current_val = gdb.parse_and_eval(parts[0])
              for part in parts[1:-1]:
                  current_val = self._evaluate_part(current_val, part, False)
                  if current_val is None:  # Early exit if an evaluation fails.
                      return
              self._evaluate_part(current_val, parts[-1], True)
        except gdb.error as e:
            print(f"Error: {e}")
    def _evaluate_part(self, current_val, part, last):
        """Evaluates a single part of the expression (method call or member access)."""
        storage = None
        target = f"(({current_val.type}){current_val})"
        type = current_val.type
        if type.tag and type.tag.startswith("v8::internal::Tagged<"):
          storage = gdb.parse_and_eval(f"malloc({type.sizeof})").cast(type.pointer())
          command = f"(({storage.type}){storage})->ptr_ = {current_val['ptr_']}"
          gdb.parse_and_eval(command)
          target = f"(({storage.type}){storage})->ToRawPtr()"
        # Check for a method call (ends with parentheses).
        command = f"{target}->{part}"
        result = None
        if last:
          gdb.execute(f"print {command}")
        else:
          result = gdb.parse_and_eval(command)
        if storage:
          gdb.parse_and_eval(f"free({storage})")
        return result
TaggedPrintCommand()
static_roots_cache = None
def GetStaticRoot(ptr):
  global static_roots_cache
  if static_roots_cache is None:
    static_roots_cache = {}
    try:
      for field in gdb.lookup_type("v8::internal::StaticReadOnlyRoot").fields():
        value = gdb.parse_and_eval("v8::internal::StaticReadOnlyRoot::"+field.name)
        if int(value) in static_roots_cache:
          static_roots_cache[int(value)] += "," + field.name
        else:
          static_roots_cache[int(value)] = field.name
    except Exception as e:
      print("Warning, couldn't find static roots: ", e)
  ptr = ptr & 0xFFFFFFFF
  return static_roots_cache.get(ptr, None)
def InterpretTaggedPointer(pointer):
  if (pointer & 0x1) == 0:
    return f"Smi: {pointer >> 1}"
  
  static_root = GetStaticRoot(pointer)
  if static_root is not None:
    return f"{static_root}"
  return None
def OptimizedOutToNone(val):
  if val is None:
    return None
  if val.is_optimized_out:
    return None
  return val
class TaggedPrinter(object):
  """Print Tagged<Foo> types."""
  def __init__(self, val, pointee_type):
    self.val = OptimizedOutToNone(val)
    self.pointee_type = pointee_type.lstrip('v8::internal::')
    self.ptr = self.val["ptr_"] if self.val is not None else None
  def to_string(self):
    if self.ptr is None:
      return f"Tagged<{self.pointee_type}>{{<optimized out>}}"
    pointer = int(self.ptr)
    fmt = f"Tagged<{self.pointee_type}>{{0x{pointer:02x}}}"
    if (label := InterpretTaggedPointer(pointer)) is not None:
      fmt += f" ({label})"          
    return fmt
def tagged_pretty_printers(val):
  # The member type might have been obscured by typedefs and template
  # arguments. Fallback to using the underlying type.
  real_type = val.type.strip_typedefs()
  typename = real_type.name or real_type.tag or str(real_type)
  regex = re.compile("^v8::internal::Tagged<(.*)>$")
  match = regex.match(typename)
  if match is not None:
    return TaggedPrinter(val, pointee_type=match.group(1))
  return None
gdb.pretty_printers.append(tagged_pretty_printers)
class HandlePrinter(object):
  """Print Handle<Foo> types."""
  def __init__(self, val, pointee_type):
    self.val = OptimizedOutToNone(val)
    self.pointee_type = pointee_type.lstrip('v8::internal::')
    self.location = OptimizedOutToNone(self.val["location_"] if self.val is not None else None)
    self.ptr = self.location.dereference() if self.location is not None else None
  def to_string(self):
    if self.location is None:
      return f"Handle<{self.pointee_type}>{{<optimized out>}}"
    location = int(self.location)
    fmt = f"Handle<{self.pointee_type}>{{0x{location:02x}}}: "
    if self.ptr is None:
      fmt += f"<optimized out>"
    else:
      pointer = None
      try:
        pointer = int(self.ptr)
      except Exception as e:
        fmt += f"[{e}]"
      else:
        fmt += f"0x{pointer:02x}"
        if (label := InterpretTaggedPointer(pointer)) is not None:
          fmt += f" ({label})"
          
    return fmt
def handle_pretty_printers(val):
  # The member type might have been obscured by typedefs and template
  # arguments. Fallback to using the underlying type.
  real_type = val.type.strip_typedefs()
  typename = real_type.name or real_type.tag or str(real_type)
  regex = re.compile("^v8::internal::(?:Indirect)?Handle<(.*)>$")
  match = regex.match(typename)
  if match is not None:
    return HandlePrinter(val, pointee_type=match.group(1))
  return None
gdb.pretty_printers.append(handle_pretty_printers)
class DirectHandlePrinter(object):
  """Print DirectHandle<Foo> types."""
  def __init__(self, val, pointee_type):
    self.val = val
    self.pointee_type = pointee_type.lstrip('v8::internal::')
    self.inner = None
    if gdb.types.has_field(self.val.type, "handle_"):
      self.inner = HandlePrinter(val['handle_'], pointee_type)
    elif gdb.types.has_field(self.val.type, "obj_"):
      self.inner = TaggedPrinter(val['obj_'], pointee_type)
    else:
      print("Warning: No recognised DirectHandle field")
  def to_string(self):
    if self.inner is not None:
      return self.inner.to_string()
def direct_handle_pretty_printers(val):
  # The member type might have been obscured by typedefs and template
  # arguments. Fallback to using the underlying type.
  real_type = val.type.strip_typedefs()
  typename = real_type.name or real_type.tag or str(real_type)
  regex = re.compile("^v8::internal::DirectHandle<(.*)>$")
  match = regex.match(typename)
  if match is not None:
    if gdb.types.has_field(real_type, "handle_"):
      handle = None
      if not val.is_optimized_out:
        handle = val['handle_']
      return HandlePrinter(handle, match.group(1))
    elif gdb.types.has_field(real_type, "obj_"):
      obj = None
      if not val.is_optimized_out:
        obj = val['obj_']
      return TaggedPrinter(obj, match.group(1))
  return None
gdb.pretty_printers.append(direct_handle_pretty_printers)
end

