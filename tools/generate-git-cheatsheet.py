#!/usr/bin/env python3
"""Generate an A4-landscape PDF cheat sheet of git aliases from this repo's configs.

Sources:
  - lib/common.sh              the bash+zsh subset (wins in both shells)
  - ~/.oh-my-zsh/plugins/git/  the full oh-my-zsh git plugin (zsh only)

Most oh-my-zsh aliases are simple `alias name='git ...'` lines and are parsed
automatically. A handful are defined as shell functions, or behind
`is-at-least` version checks, and are listed in MANUAL_ALIASES below instead
so the sheet stays accurate without a shell interpreter.

Usage: tools/generate-git-cheatsheet.py [output.pdf]
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ZSH_PLUGIN = Path.home() / ".oh-my-zsh/plugins/git/git.plugin.zsh"
COMMON_SH = REPO / "lib/common.sh"

ALIAS_RE = re.compile(r"^alias\s+([^\s=]+)=(['\"])(.*)\2\s*$")

# Aliases the regex above cannot parse correctly: shell functions, aliases
# pointing at functions, or values behind `is-at-least` version checks.
# (category, command shown on the sheet)
MANUAL_ALIASES = {
    "ggpnp":   ("sync", "ggl && ggp  (pull then push [branch])"),
    "ggpur":   ("sync", "= ggu"),
    "ggu":     ("sync", "git pull --rebase origin [branch]"),
    "ggl":     ("sync", "git pull origin [branch]"),
    "ggp":     ("sync", "git push origin [branch]"),
    "ggf":     ("sync", "git push --force origin [branch]"),
    "ggfl":    ("sync", "git push --force-with-lease origin [branch]"),
    "gccd":    ("clone", "git clone --recurse-submodules <url> && cd into it"),
    "gdv":     ("diff", "git diff | view (read-only pager)"),
    "gdnolock": ("diff", 'git diff ":(exclude)*.lock" ":(exclude)package-lock.json"'),
    "gbda":    ("branch", "delete local branches merged into main/develop"),
    "gbds":    ("branch", "delete local branches squash-merged into main/develop"),
    "gunwipall": ("workflow", "undo all consecutive --wip-- commits"),
    "grename": ("branch", "rename current branch, locally and on origin"),
    "gtl":     ("tag", 'git tag --sort=-v:refname -n --list "<pattern>*"'),
    "gbgd":    ("branch", "delete local branches whose upstream is gone"),
    "gbgD":    ("branch", "force-delete local branches whose upstream is gone"),
    "gfa":     ("fetch", "git fetch --all --tags --prune --jobs=10"),
    "gpf":     ("push", "git push --force-with-lease --force-if-includes"),
    "gpsupf":  ("push", "git push -u origin $(current branch) --force-with-lease --force-if-includes"),
    "gsta":    ("stash", "git stash push"),
}

# Helper functions used internally by other aliases; not user-facing commands.
SKIP = {"git_current_branch", "git_main_branch", "git_develop_branch", "work_in_progress"}

# `git checkout` aliases that `git switch` (the modern, unambiguous
# replacement for branch operations) already covers exactly.
SKIP |= {
    "gcb",  # git checkout -b            -> gswc (git switch --create)
    "gcd",  # git checkout $(develop)    -> gswd (git switch $(develop))
    "gcm",  # git checkout $(main)       -> gswm (git switch $(main))
}

# Subcommands that should share a section with another (rather than getting
# their own tiny header).
SUBCOMMAND_ALIAS = {"mergetool": "merge", "diff-tree": "diff", "rev-list": "workflow"}

CATEGORY_TITLES = {
    "add": "Add", "am": "Am", "apply": "Apply", "bisect": "Bisect",
    "blame": "Blame", "branch": "Branch", "checkout": "Checkout",
    "cherry-pick": "Cherry-pick", "clean": "Clean", "clone": "Clone",
    "commit": "Commit", "config": "Config", "describe": "Describe",
    "diff": "Diff", "fetch": "Fetch", "gui": "GUI", "help": "Help",
    "log": "Log", "ls-files": "Ls-files", "merge": "Merge", "pull": "Pull",
    "push": "Push", "rebase": "Rebase", "reflog": "Reflog", "remote": "Remote",
    "reset": "Reset", "restore": "Restore", "revert": "Revert", "rm": "Rm",
    "shortlog": "Shortlog", "show": "Show", "stash": "Stash", "status": "Status",
    "submodule": "Submodule", "svn": "Svn", "switch": "Switch", "tag": "Tag",
    "update-index": "Update-index", "worktree": "Worktree",
    "sync": "Sync shortcuts", "workflow": "Workflow / WIP",
}

CATEGORY_ORDER = [
    "add", "am", "apply", "bisect", "blame", "branch", "checkout",
    "cherry-pick", "clean", "clone", "commit", "config", "describe", "diff",
    "fetch", "gui", "help", "log", "ls-files", "merge", "pull", "push",
    "rebase", "reflog", "remote", "reset", "restore", "revert", "rm",
    "shortlog", "show", "stash", "status", "submodule", "svn", "switch",
    "tag", "update-index", "worktree", "sync", "workflow",
]

# Aliases better grouped with the day-to-day sync/workflow shortcuts (or
# whose command is prefixed, e.g. `LANG=C git ...`, so the subcommand regex
# below can't find them) than under their literal git subcommand.
CATEGORY_OVERRIDE = {
    "gwip": "workflow", "gunwip": "workflow", "gpristine": "workflow",
    "gwipe": "workflow", "groh": "workflow", "ggsup": "sync",
    "ggpull": "sync", "ggpush": "sync", "gk": "gui", "gke": "gui",
    "g": "workflow", "grt": "workflow", "gbg": "branch", "glp": "log",
    "gstu": "stash",
}


def parse_simple_aliases(path):
    aliases = {}
    for line in path.read_text().splitlines():
        m = ALIAS_RE.match(line.strip())
        if m:
            name, _, value = m.groups()
            aliases[name] = value
    return aliases


def parse_common_sh_git_section(path):
    """lib/common.sh mixes git aliases with unrelated ones (navigation,
    Slurm, machine-specific paths, ...). Only take the `# --- git ---` block."""
    lines = path.read_text().splitlines()
    in_git_section = False
    section = []
    for line in lines:
        if re.match(r"^#\s*---\s*git\b", line):
            in_git_section = True
            continue
        if in_git_section and re.match(r"^#\s*---", line):
            break
        if in_git_section:
            section.append(line)
    aliases = {}
    for line in section:
        m = ALIAS_RE.match(line.strip())
        if m:
            name, _, value = m.groups()
            aliases[name] = value
    return aliases


def categorize(name, cmd):
    if name in CATEGORY_OVERRIDE:
        return CATEGORY_OVERRIDE[name]
    if name in MANUAL_ALIASES:
        return MANUAL_ALIASES[name][0]
    m = re.search(r"\bgit\s+(\S+)", cmd)
    if m:
        sub = m.group(1).lstrip("-")
        return SUBCOMMAND_ALIAS.get(sub, sub)
    return "misc"


def build_entries():
    zsh_aliases = {}
    if ZSH_PLUGIN.exists():
        zsh_aliases = parse_simple_aliases(ZSH_PLUGIN)
    else:
        print(f"warning: {ZSH_PLUGIN} not found, sheet will only cover lib/common.sh", file=sys.stderr)

    bash_aliases = parse_common_sh_git_section(COMMON_SH) if COMMON_SH.exists() else {}

    names = (set(zsh_aliases) | set(MANUAL_ALIASES) | set(bash_aliases)) - SKIP

    entries = []
    for name in names:
        if name in MANUAL_ALIASES:
            cmd = MANUAL_ALIASES[name][1]
        elif name in bash_aliases:
            cmd = bash_aliases[name]
        else:
            cmd = zsh_aliases[name]
        both = name in bash_aliases
        entries.append((name, cmd, categorize(name, cmd), both))

    by_category = {}
    for name, cmd, cat, both in entries:
        by_category.setdefault(cat, []).append((name, cmd, both))
    for cat in by_category:
        by_category[cat].sort(key=lambda e: e[0].lower())

    unknown = set(by_category) - set(CATEGORY_ORDER)
    if unknown:
        print(f"warning: uncategorized aliases will be dropped: {unknown}", file=sys.stderr)

    return by_category


LATEX_SPECIALS = {
    "\\": r"\textbackslash{}",
    "&": r"\&", "%": r"\%", "$": r"\$", "#": r"\#",
    "_": r"\_", "{": r"\{", "}": r"\}",
    "~": r"\textasciitilde{}", "^": r"\textasciicircum{}",
}


def esc(s):
    # Single pass over the original characters, so replacement text (e.g. the
    # braces in \textbackslash{}) is never re-escaped by a later lookup.
    out = "".join(LATEX_SPECIALS.get(c, c) for c in s)
    # Typewriter fonts here ligature "--" into an en-dash; break that so
    # flags like --all print literally.
    out = re.sub(r"-(?=-)", "-{}", out)
    # Long unbroken command substitutions ($(...), paths) have no spaces to
    # wrap on and would otherwise overflow the narrow column; add invisible
    # break points after common punctuation.
    return re.sub(r"([/_.,:=(){}$-])", r"\1\\hspace{0pt}", out)


PREAMBLE = r"""
\documentclass[8pt]{extarticle}
\usepackage[a4paper,landscape,margin=6mm]{geometry}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{multicol}
\usepackage{xcolor}
\usepackage{parskip}
\setlength{\columnsep}{3mm}
\setlength{\columnseprule}{0.2pt}
\definecolor{rule}{HTML}{CCCCCC}
\renewcommand{\columnseprulecolor}{\color{rule}}

\definecolor{accent}{HTML}{2A5DB0}
\definecolor{dim}{HTML}{555555}

\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}
\pagestyle{empty}

% Compact colored section header. \nointerlineskip + a following \nopagebreak
% via the immediately-appended first \aliasrow keeps it from separating.
\newcommand{\cathead}[1]{%
  \par\colorbox{accent}{\parbox{\dimexpr\columnwidth-4pt\relax}{%
    \rule{0pt}{7.5pt}\bfseries\fontsize{7.5}{8.5}\selectfont\color{white}\ #1}}\par\vspace{1.2pt}}

% \parbox makes each entry a single unbreakable box, so multicol's column
% balancing (which ignores interline nobreak penalties) can't split an
% alias name from its command onto different columns. Single line, with a
% hanging indent so a wrapped long command lines up under the command text
% instead of under the alias name.
\newcommand{\aliasrow}[3]{%
  \noindent\parbox[t]{\linewidth}{\raggedright\hangindent=1.1em\hangafter=1
    \fontsize{6.4}{7.6}\selectfont
    \texttt{\bfseries #1}%
    \ifnum#3=1 {\fontsize{4.5}{4.5}\selectfont\textcolor{accent}{\textsuperscript{B}}}\fi
    \ \texttt{\textcolor{dim}{#2}}}\par\vspace{0.6pt}}

\begin{document}
\begin{center}
{\large\bfseries Git Alias Cheat Sheet} \quad
{\scriptsize\textcolor{dim}{mjaehn/dotfiles --- generated from \texttt{lib/common.sh} and the oh-my-zsh \texttt{git} plugin}}
\quad {\scriptsize\textcolor{accent}{\textsuperscript{B}} = also available in bash}
\end{center}
\vspace{1pt}
\raggedcolumns
\begin{multicols}{6}
"""

POSTAMBLE = r"""
\end{multicols}
\end{document}
"""


def build_latex(by_category):
    parts = [PREAMBLE]
    for cat in CATEGORY_ORDER:
        rows = by_category.get(cat)
        if not rows:
            continue
        parts.append(f"\\cathead{{{esc(CATEGORY_TITLES[cat])}}}\n")
        for name, cmd, both in rows:
            parts.append(
                "\\aliasrow{%s}{%s}{%d}\n" % (esc(name), esc(cmd), 1 if both else 0)
            )
    parts.append(POSTAMBLE)
    return "".join(parts)


def compile_pdf(tex_source, output_pdf):
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        tex_file = tmp / "cheatsheet.tex"
        tex_file.write_text(tex_source)
        for _ in range(2):  # multicol needs two passes to balance columns
            result = subprocess.run(
                ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", tex_file.name],
                cwd=tmp, capture_output=True, text=True,
            )
            if result.returncode != 0:
                print(result.stdout[-4000:], file=sys.stderr)
                raise SystemExit("pdflatex failed")
        shutil.copy(tmp / "cheatsheet.pdf", output_pdf)


def main():
    output = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "git-cheatsheet.pdf"
    by_category = build_entries()
    tex_source = build_latex(by_category)
    compile_pdf(tex_source, output)
    total = sum(len(v) for v in by_category.values())
    print(f"wrote {output} ({total} aliases)")


if __name__ == "__main__":
    main()
