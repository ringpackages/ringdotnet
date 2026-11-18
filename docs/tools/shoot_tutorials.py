#!/usr/bin/env python3
"""Screenshots of the tutorial programs: docs/img/shots/tut-<name>.png
Some shots need the program in a later state: the code in INJECT runs just before the window is shown (in a temporary copy)."""
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
TUT = os.path.join(DOCS, "tutorials")
OUT = os.path.join(DOCS, "img", "shots")

# (program, shot name, marker line (the injected code goes before it), injected code, delay ms, kind)
SHOTS = [
    ("g01a_window.ring", "g01a", None, "", 2500, "forms"),
    ("g01b_controls.ring", "g01b", None, "", 2500, "forms"),
    ("g01c_counter.ring", "g01c", None, "", 2500, "forms"),
    ("g01c_counter.ring", "g01c-clicked", "\tuiTest(", "\tnClicks = 3\n\toLabel.Text = 'Clicked 3 times'\n", 2500, "forms"),
    ("g01d_plain.ring", "g01d", None, "", 2500, "forms"),
    ("g02_registration.ring", "g02", None, "", 2500, "forms"),
    ("g02_registration.ring", "g02-filled", "\tuiTest(", "\toName.Text = 'Ann'\n\toCountry.SelectedIndex = 1\n\toNewsletter.Checked = True\n\tregister()\n\toName.Text = 'Bob'\n\toCountry.SelectedIndex = 0\n\tregister()\n\toName.Text = 'Cy'\n", 2500, "forms"),
    ("g03_editor.ring", "g03", None, "", 2500, "forms"),
    ("g03_editor.ring", "g03-text", "\tuiTest(", "\toEditor.Text = 'Hello from the tiny editor' + windowsnl() + 'Second line of text'\n\toEditor.SelectionStart = 0\n\toEditor.SelectionLength = 0\n\toEditor.ScrollToCaret()\n", 2500, "forms"),
    ("g04_bounce.ring", "g04", None, "", 2200, "forms"),
    ("g05_wpf.ring", "g05", None, "", 3500, "wpf"),
    ("g05_wpf.ring", "g05-greeted", "\twpfTest(", "\toGreet.Text = 'Hello, Ring!'\n\toSlider.Value = 100\n", 3500, "wpf"),
    ("g23_layout.ring", "g23", None, "", 3000, "forms"),
    ("g23_layout.ring", "g23-orders", "\tuiTest(", "\toTabs.SelectedIndex = 1\n\toList.SelectedIndex = 2\n", 3000, "forms"),
    ("g24_todo.ring", "g24", "\toForm.setFormClosingEvent", "\toTasks.Items.Clear()\n\toNew.Text = 'Buy milk'\n\taddTask()\n\toNew.Text = 'Write the tutorial'\n\taddTask()\n\toNew.Text = 'Walk the dog'\n\taddTask()\n\toTasks.SetItemChecked(0,True)\n\toTasks.SetItemChecked(2,True)\n\trefreshStatus()\n", 2500, "forms"),
    ("g34_timers.ring", "g34", "\tuiTest(", "\ttoggleWatch()\n\toBar.Value = 60\n\toInfo.Text = 'Working... 60%'\n", 2500, "forms"),
    ("g35_tictactoe.ring", "g35", "\tuiTest(", "\tplay(1)\n\tplay(4)\n\tplay(2)\n\tplay(5)\n", 2500, "forms"),
    ("g35_tictactoe.ring", "g35-won", "\tuiTest(", "\tplay(1)\n\tplay(4)\n\tplay(2)\n\tplay(5)\n\tplay(3)\n", 2500, "forms"),
    ("g36_chart.ring", "g36", None, "", 2500, "forms"),
    ("g37_runner.ring", "g37", "\tuiTest(", "\trunCommand()\n", 2500, "forms"),
    ("g38_wpf_layout.ring", "g38", None, "", 3500, "wpf"),
    ("g38_wpf_layout.ring", "g38-typed", "\twpfTest(", "\tpressKey(4)\n\tpressKey(2)\n\tpressKey(7)\n", 3500, "wpf"),
]


def main():
    for prog, name, marker, code, delay, kind in SHOTS:
        src = open(os.path.join(TUT, prog), encoding="utf-8").read()
        tmp = prog
        if marker:
            i = src.index(marker)
            src = src[:i] + code + src[i:]
            tmp = "_shot_" + prog
            with open(os.path.join(TUT, tmp), "w", encoding="utf-8", newline="\n") as f:
                f.write(src)
        out = os.path.join(OUT, "tut-%s.png" % name)
        r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", os.path.join(HERE, "shot.ps1"),
                            "-Dir", TUT, "-Script", tmp, "-Out", out, "-Delay", str(delay)], capture_output=True, text=True)
        print((r.stdout + r.stderr).strip().splitlines()[-1:] or "?")
        if marker:
            os.remove(os.path.join(TUT, tmp))


if __name__ == "__main__":
    main()
