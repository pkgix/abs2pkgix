#!/usr/bin/env python

#
# Copyright (C) 2014, Marco Elver <me AT marcoelver.com>
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

import os
import time
import bottle

ABS_PATH = "/var/abs"
REPOS = ["core", "extra", "community"]

WRAP_SCRIPT = os.path.join(os.environ["ABS2PKGIX_ROOT"], "lib", "abs2pkgix", "wrap.sh")
with open(WRAP_SCRIPT, "r") as wrap_script:
    WRAP_SCRIPT_CONTENT = wrap_script.read()

def get_pkgpath(name):
    for repo in REPOS:
        pkgpath = os.path.join(ABS_PATH, repo, name)
        if os.path.exists(pkgpath): break

    if not os.path.exists(pkgpath):
        raise Exception("Package does not exist!")

    return pkgpath

@bottle.route('/pkgs/<name>')
def index(name):
    try:
        pkgpath = get_pkgpath(name)
    except Exception as e:
        bottle.abort(404, e)

    with open(os.path.join(pkgpath, "PKGBUILD"), "r") as pkgbuild:
        pkgbuild_content = pkgbuild.read()

    return "\n".join([
        "# abs2pkgix generated ({})".format(time.strftime("%a %b %d %H:%M:%S %Z %Y")),
        "",
        "#====================[ PKGBUILD ]====================#",
        "",
        pkgbuild_content,
        "",
        "#====================[ wrap.sh ]====================#",
        "",
        WRAP_SCRIPT_CONTENT
        ])

@bottle.route('/support/<name>/<filename>')
def index(name, filename):
    try:
        pkgpath = get_pkgpath(name)
    except Exception as e:
        bottle.abort(404, e)

    return bottle.static_file(filename, root=pkgpath)

bottle.run(host='localhost', port=8080)
