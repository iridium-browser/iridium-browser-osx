#!/usr/bin/python

# Iridium browser OSX finding signing identity information script
# Copyright (C) 2015 struktur AG <opensource@struktur.de>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA


import subprocess
import sys

def get_part_with_type(output, type, part):
    """
    Returns list of "id" values in lines formatted as

    X) <id> "<type>: <name> (<teamid>)"
    """
    result = []
    for line in output:
        try:
            idx = line.index(type)
        except ValueError:
            continue

        if part == "id":
            # return <id>
            line = line[:idx-1].rstrip()
            start = line.rfind(' ')
            result.append(line[start+1:])
        elif part == "teamid":
            # return <teamid>
            assert line[-2:] == ')"', line
            start = line.rfind('(')
            result.append(line[start+1:-2])
        elif part == "name":
            # return <teamid>
            assert line[-2:] == ')"', line
            start = line.rfind(':')
            end = line.rfind('(')
            result.append(line[start+2:end-1])

    return result

def get_mas_app(output):
    return get_part_with_type(output, '3rd Party Mac Developer Application', 'id')

def get_mas_package(output):
    return get_part_with_type(output, '3rd Party Mac Developer Installer', 'id')

def get_mas_teamid(output):
    return get_part_with_type(output, '3rd Party Mac Developer Application', 'teamid')

def get_iad_teamid(output):
    return get_part_with_type(output, 'Developer ID Application', 'teamid')

def get_mas_name(output):
    return get_part_with_type(output, '3rd Party Mac Developer Application', 'name')

def get_iad(output):
    return get_part_with_type(output, 'Developer ID Application', 'id')

OPTIONS = {
    'mas_app': get_mas_app,
    'mas_package': get_mas_package,
    'mas_teamid': get_mas_teamid,
    'iad_teamid': get_iad_teamid,
    'iad': get_iad,
    'mas_company_name' : get_mas_name
}

def main():
    try:
        getter = OPTIONS[sys.argv[1]]
    except (KeyError, IndexError):
        print >> sys.stderr, 'USAGE: %s [%s]' % (
            sys.argv[0], ' | '.join(sorted(OPTIONS)))
        sys.exit(1)

    try:
        p = subprocess.Popen(['/usr/bin/security', 'find-identity', '-v'],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except EnvironmentError, e:
        print >> sys.stderr, 'Could not get identities: %s' % (e, )
        sys.exit(1)

    (stdoutdata, stderrdata) = p.communicate()
    if p.returncode != 0:
        print >> sys.stderr, 'Returned with code %d' % (p.returncode, )
        sys.exit(1)

    result = getter([x.strip() for x in stdoutdata.split('\n') if x.strip()])
    if not result:
        print >> sys.stderr, 'No matching identity found'
        sys.exit(1)

    print >> sys.stdout, result[0]

if __name__ == '__main__':
    main()
