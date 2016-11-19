#!/usr/bin/env python

#
# Copyright (C) 2014-2016, Marco Elver <me AT marcoelver.com>
#
# This file is part of abs2pkgix.
#
# abs2pkgix is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# abs2pkgix is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with abs2pkgix.  If not, see <http://www.gnu.org/licenses/>.
#

import sys
import os
import time
import bottle
import gzip
import re

import abs2pkgix.rules as rules

ABS_PATH = "/var/abs"
REPOS = ["core", "extra", "community"]
SCRIPT_PATH = os.path.join(os.environ["ABS2PKGIX_ROOT"], "lib", "abs2pkgix")
PKG_FILE_LIST = os.path.join(os.environ["ABS2PKGIX_ROOT"], "package_file_list.gz")
MAX_FILE_LIST = 3

pkg_file_list = {}

def init_pkg_file_list():
    with gzip.open(PKG_FILE_LIST, "r") as f:
        prev_pkgname = None
        for line in (str(l.decode()).strip() for l in f):
            pkgname, path = line.split(maxsplit=1)
            if prev_pkgname == pkgname:
                if count >= MAX_FILE_LIST: continue
            else:
                count = 0

            if not os.path.isfile(path): continue
            count += 1
            prev_pkgname = pkgname

            if pkgname not in pkg_file_list:
                pkg_file_list[pkgname] = [path]
            else:
                pkg_file_list[pkgname].append(path)

def get_pkgpath(name):
    for repo in REPOS:
        pkgpath = os.path.join(ABS_PATH, repo, name)
        if os.path.exists(pkgpath): break

    if not os.path.exists(pkgpath):
        raise Exception("Package does not exist!")

    return pkgpath

def pkg_convert(pkg_name, line):
    # Rename clashing functions
    rename = ["prepare", "build", "check"]
    if "()" in line:
        if any(line.startswith(x) for x in rename): return "_" + line

    # Rename *sums
    idx = line.find("sums=(")
    if idx > 0:
        which_digest = line[:idx]
        return "_checksums_digest={}\n{}".format(which_digest,
                line.replace("{}sums=".format(which_digest), "_checksums="))

    # Ensure ./configure has --exec-prefix
    if line.strip().startswith("./configure"):
        if "exec-prefix" not in line:
            line = line.replace("./configure", "./configure --exec-prefix=/usr")

    # Convert paths to ${prefix} paths
    if rules.prefix_ize(pkg_name, line):
        prefix_ize = ["/usr", "/etc", "/var", "/run", "/opt"]
        for x in prefix_ize:
            if x in line and not line.strip().startswith(x):
                prepend = "${prefix}"

                # Check if single quoted; if it is, need to unquote to use
                # ${prefix} variable.
                single_quoted_all = re.findall(r"'([^']*)'", line)
                for single_quoted in single_quoted_all:
                    if x in single_quoted:
                        prepend = "'\"${prefix}\"'"

                line = line.replace(x, prepend + x)

    return line

@bottle.route('/pkgs/<name>')
def index(name):
    try:
        pkgpath = get_pkgpath(name)
    except Exception as e:
        #bottle.abort(404, e)

        # TODO: Workaround for packages that depend on virtual packages
        # (provides)
        return "version=0\nisinstalled() { return 0; }\n"

    with open(os.path.join(pkgpath, "PKGBUILD"), "r") as pkgbuild:
        pkgbuild_content = "".join(pkg_convert(name, line) for line in pkgbuild)

    isinstalled_list = " ".join("'{}'".format(path) for \
                                path in pkg_file_list.get(name, []))

    bottle.response.content_type = "text/plain; charset=UTF8"
    return "\n".join([
        "# abs2pkgix generated ({})".format(time.strftime("%a %b %d %H:%M:%S %Z %Y")),
        "",
        "source_pkg \".functions/pre_wrap.sh\" \"${repo}\"",
        "#==========[ PKGBUILD ]==========#",
        pkgbuild_content,
        "#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#",
        "",
        "_isinstalled_list=({})".format(isinstalled_list),
        "source_pkg \".functions/build.sh\" \"${repo}\"",
        "source_pkg \".functions/wrap.sh\" \"${repo}\"",
        ""
        ])

@bottle.route('/support/<name>/<filename>')
def index(name, filename):
    try:
        pkgpath = get_pkgpath(name)
    except Exception as e:
        bottle.abort(404, e)

    return bottle.static_file(filename, root=pkgpath)

@bottle.route('/pkgs/.functions/<filename>')
def index(filename):
    return bottle.static_file(filename, root=SCRIPT_PATH)

def main(argv):
    try:
        host, port = argv[1].split(":")
    except:
        host = 'localhost'
        port = 8080

    bottle.run(host=host, port=port)
    return 0

init_pkg_file_list()
if __name__ == "__main__":
    sys.exit(main(sys.argv))
