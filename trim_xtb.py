#!/usr/bin/env python

# Iridium browser OSX translations clean up script
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


import argparse
import xml.etree.ElementTree as ET
import os
import sys

bracket = "translationbundle"

def trimFile(fileName):

	if fileName is None or len(fileName) == 0:
		return

	tree = ET.parse(fileName)
	root = tree.getroot()

	print "Root tag: " + root.tag

	if root.tag == bracket:
		children = list(root)
		for child in children:
			root.remove(child)

	else:

		for child in root:
			print "child tag:" + child.tag
			print "root tag:" + root.tag


			if child.tag == bracket:
				children = list(child)
				for ch in children:
					child.remove(ch)

	tree.write(fileName)



def trimFile_quick(filePath):

	if filePath is None or len(filePath) == 0:
		return

	fileName = os.path.basename(filePath)
	fileName = os.path.splitext(fileName)[0]

	lang = fileName.split("_")[-1]

	overrideText = "<" + bracket + " lang=\"" + lang + "\"></"+ bracket + ">"
	print "At \n" + filePath + "\n Overriding: " + overrideText

	f = open(filePath, 'w')
	f.write(overrideText)
	f.close



def main(argv):
	parser = argparse.ArgumentParser(description="Cleans up .xtb files from all translations, leaving only header with languauge.")
	parser.add_argument('-d', type=str, default=None, action='append', help="Directory(will be walked recursively) in which all .xtb files will be processed")
	parser.add_argument('-i', type=str, default=None, action='append', help="Separate .xtb file to process")
	parser.add_argument('--slow', type=bool, default=False, help="Use slow xml parsing instead or pure file overwriting basing on language")
	args = parser.parse_args()

	if args.d is not None:
		for directory in args.d:
			if directory is not None and os.path.isdir(directory):
				for folder, subs, files in os.walk(directory):
					for fileName in files:
						if os.path.splitext(fileName)[1] == ".xtb":
							filePath = os.path.join(folder, fileName)
							print filePath
							#if args.slow:
							#	trimFile(filePath)
							#else:
							#	trimFile_quick(filePath)

	if args.i is not None:
		for filePath in args.i:
			if filePath is not None and os.path.isFile(filePath):
				if args.slow:
					trimFile(filePath)
				else:
					trimFile_quick(filePath)



if __name__ == "__main__":
    main(sys.argv[1:])
