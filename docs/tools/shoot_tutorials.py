#!/usr/bin/env python3
"""Screenshots of the tutorial programs: docs/img/shots/tut-<name>.png
Some shots need the program in a later state: the code in INJECT runs just before the window is shown (in a temporary copy)."""
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
TUT = os.path.join(os.path.dirname(DOCS), "samples", "UsingDotNet", "tutorials")
OUT = os.path.join(DOCS, "img", "shots")

# (program, shot name, marker line (the injected code goes before it), injected code, delay ms, kind)
SHOTS = [
    ("ch10_window.ring", "g01a", None, "", 2500, "forms"),
    ("ch10_controls.ring", "g01b", None, "", 2500, "forms"),
    ("ch10_counter.ring", "g01c", None, "", 2500, "forms"),
    ("ch10_counter.ring", "g01c-clicked", "\tuiTest(", "\tnClicks = 3\n\toLabel.Text = 'Clicked 3 times'\n", 2500, "forms"),
    ("ch10_plain.ring", "g01d", None, "", 2500, "forms"),
    ("ch10_registration.ring", "g02", None, "", 2500, "forms"),
    ("ch10_registration.ring", "g02-filled", "\tuiTest(", "\toName.Text = 'Ann'\n\toCountry.SelectedIndex = 1\n\toNewsletter.Checked = True\n\tregister()\n\toName.Text = 'Bob'\n\toCountry.SelectedIndex = 0\n\tregister()\n\toName.Text = 'Cy'\n", 2500, "forms"),
    ("ch10_editor.ring", "g03", None, "", 2500, "forms"),
    ("ch10_editor.ring", "g03-text", "\tuiTest(", "\toEditor.Text = 'Hello from the tiny editor' + windowsnl() + 'Second line of text'\n\toEditor.SelectionStart = 0\n\toEditor.SelectionLength = 0\n\toEditor.ScrollToCaret()\n", 2500, "forms"),
    ("ch10_bounce.ring", "g04", None, "", 2200, "forms"),
    ("ch11_wpf.ring", "g05", None, "", 3500, "wpf"),
    ("ch11_wpf.ring", "g05-greeted", "\twpfTest(", "\toGreet.Text = 'Hello, Ring!'\n\toSlider.Value = 100\n", 3500, "wpf"),
    ("ch10_layout.ring", "g23", None, "", 3000, "forms"),
    ("ch10_layout.ring", "g23-orders", "\tuiTest(", "\toTabs.SelectedIndex = 1\n\toList.SelectedIndex = 2\n", 3000, "forms"),
    ("ch12_todo.ring", "g24", "\toForm.setFormClosingEvent", "\toTasks.Items.Clear()\n\toNew.Text = 'Buy milk'\n\taddTask()\n\toNew.Text = 'Write the tutorial'\n\taddTask()\n\toNew.Text = 'Walk the dog'\n\taddTask()\n\toTasks.SetItemChecked(0,True)\n\toTasks.SetItemChecked(2,True)\n\trefreshStatus()\n", 2500, "forms"),
    ("ch10_timers.ring", "g34", "\tuiTest(", "\ttoggleWatch()\n\toBar.Value = 60\n\toInfo.Text = 'Working... 60%'\n", 2500, "forms"),
    ("ch12_tictactoe.ring", "g35", "\tuiTest(", "\tplay(1)\n\tplay(4)\n\tplay(2)\n\tplay(5)\n", 2500, "forms"),
    ("ch12_tictactoe.ring", "g35-won", "\tuiTest(", "\tplay(1)\n\tplay(4)\n\tplay(2)\n\tplay(5)\n\tplay(3)\n", 2500, "forms"),
    ("ch10_chart.ring", "g36", None, "", 2500, "forms"),
    ("ch12_runner.ring", "g37", "\tuiTest(", "\trunCommand()\n", 2500, "forms"),
    ("ch11_wpf_layout.ring", "g38", None, "", 3500, "wpf"),
    ("ch11_wpf_layout.ring", "g38-typed", "\twpfTest(", "\tpressKey(4)\n\tpressKey(2)\n\tpressKey(7)\n", 3500, "wpf"),
    ("ch10_dialog.ring", "g40-main", None, "", 2500, "forms"),
    ("ch10_dialog.ring", "g40-dialog", "\tuiTest(", "\taskProfile('Ann',31)\n", 2500, "forms"),
    ("ch10_menus.ring", "g41", None, "", 2500, "forms"),
    ("ch10_browser.ring", "g42", "\tuiTest(", "\toTree.SelectedNode = oRootNode.Nodes.Item(2).Nodes.Item(0)\n", 2500, "forms"),
    ("ch12_addressbook.ring", "g48", "\treload()\n\tuiTest(", "\toDb.insert('Contacts',[['Name','Ann Taylor'],['Phone','555-0101'],['City','Cairo']])\n\toDb.insert('Contacts',[['Name','Bob Stone'],['Phone','555-0102'],['City','Oslo']])\n\toDb.insert('Contacts',[['Name','Cy Young'],['Phone','555-0103'],['City','Cairo']])\n\toDb.insert('Contacts',[['Name','Dee Park'],['Phone','555-0104'],['City','Tokyo']])\n", 2500, "forms"),
    ("ch12_sorting.ring", "g61", "\tuiTest(", "\toAlgorithm.SelectedIndex = 0\n\tstartSorting()\n\toTimer.Stop()\n\tfor nI = 1 to 260\n\t\tshowStep()\n\tnext\n", 2500, "forms"),
    ("ch12_maze.ring", "g62", "\tuiTest(", "\tsolve()\n", 2500, "forms"),
    ("ch12_filters.ring", "g63", "\tuiTest(", "\tapplyFilter('Sepia')\n", 2500, "forms"),
    ("ch12_chat.ring", "g64", "\toTimer.Start()", "\taInputs[1].Text = 'Hello Bob, are you there?'\n\tsendFrom(1)\n\twaitForText('are you there')\n\taInputs[2].Text = 'Yes, I am here!'\n\tsendFrom(2)\n\twaitForText('I am here')\n\taInputs[1].Text = 'Great, the chat works.'\n\tsendFrom(1)\n\twaitForText('chat works')\n\taInputs[2].Text = 'Type a message'\n", 2500, "forms"),
    ("ch11_wpf_animation.ring", "g70", None, "", 1300, "wpf"),
    ("ch12_filters.ring", "g63-edges", "\tuiTest(", "\tapplyFilter('Edges')\n", 2500, "forms"),
    ("ch10_clipboard.ring", "g127", "\tuiTest(", "\toStatus.Text = 'Copied a table of 4 rows'\n", 2500, "forms"),
    ("ch10_inputs.ring", "g128", None, "", 2500, "forms"),
    ("ch11_wpf_binding.ring", "g131", "\twpfTest(", "\twpfFind(oWindow,'amount').Value = 75\n\twpfFind(oWindow,'colors').SelectedIndex = 1\n", 1300, "wpf"),
    ("ch10_richtext.ring", "g133", "\tuiTest(", "\tselectWord('bold')\n\ttoggleBold()\n\tselectWord('red')\n\tmakeRed()\n\toFind.Text = 'ring'\n\tfindAll()\n", 2500, "forms"),
    ("ch10_listview.ring", "g134", None, "", 2500, "forms"),
    ("ch10_paint.ring", "g139", "\tuiTest(", "\tmouseDown(40,60)\n\tfor n = 1 to 20\n\t\tmouseMove(40 + n * 8,60 + floor(40 * sin(n / 3)))\n\tnext\n\tmouseUp()\n\tsetColor('Red')\n\tnPenSize = 12\n\tmouseDown(120,200)\n\tmouseUp()\n\tsetColor('Blue')\n\tnPenSize = 4\n\tmouseDown(250,220)\n\tmouseMove(330,150)\n\tmouseMove(400,230)\n\tmouseUp()\n", 2500, "forms"),
    ("ch11_wpf_menu.ring", "g140", "\twpfTest(", "\twpfFind(oWindow,'more').IsExpanded = True\n\twpfFind(oWindow,'speed').SelectedIndex = 1\n", 1300, "wpf"),
    ("ch10_grid.ring", "g142", None, "", 2500, "forms"),
    ("ch12_quiz.ring", "g143", "\tuiTest(", "\tplay(1)\n\tplay(0)\n\taAnswers[3].Checked = True\n", 2500, "forms"),
    ("ch10_keyboard.ring", "g146", "\tuiTest(", "\toName.Text = 'ann'\n\toAge.Text = '12'\n\taccept()\n", 2500, "forms"),
    ("ch11_wpf_lists.ring", "g148", "\twpfTest(", "\tfor cItem in ['tea','coffee','milk','honey','lemon']\n\t\twpfFind(oWindow,'input').Text = cItem\n\t\taddItem()\n\tnext\n\tlistBox().SelectedIndex = 1\n", 1300, "wpf"),
    ("ch13_inspector.ring", "g151", None, "", 2500, "forms"),
]


def main():
    import sys
    only = sys.argv[1:]
    for prog, name, marker, code, delay, kind in SHOTS:
        if only and name not in only:
            continue
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
