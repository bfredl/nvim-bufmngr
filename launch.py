import neovim
import os, stat
from subprocess import call, Popen
import time

switcher_address = os.path.join(os.environ["XDG_RUNTIME_DIR"], "switcher.sock")

try:
    mode = os.stat(switcher_address).st_mode
    is_socket = stat.S_ISSOCK(mode)
except FileNotFoundError:
    is_socket = False

old_instance = is_socket

# TODO: when supported, embed nvim, start TUI from within, and then detach it
if not old_instance:
    os.environ["NVIM_LISTEN_ADDRESS"] = switcher_address
    Popen(["setsid", "pangoterm", "-e", "nvim"])

t0 = time.time()

while True:
    try:
        nvim = neovim.attach('socket', path=switcher_address)
    except FileNotFoundError:
        if old_instance or time.time() > t0 + 2.0:
            raise
        continue
    else:
        break

windowid = nvim.vars["bufmngr_windowid"]

if old_instance:
    call(['wmctrl', '-i', '-a', windowid])
else:
    nvim.vars["bufmngr_is_switcher"] = 1
    nvim.options["titlestring"] = "SWITCHER"
    call(['wmctrl', '-i', '-r', windowid, '-b', 'add,sticky'])

nvim.command("Unite -buffer-name=switcher -no-split bufmngr window/gui")
nvim.api.input("i")
