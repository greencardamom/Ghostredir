Ghostredir
===========

Check for and resolve ghost redirects

A ghost redirect is a redirect (301/302) that once existed on the live web but is now deleted. The redirect still exists in the Wabyack 
Machine, and thus the destination URL can be determined by searching the Wayback Machine for old redirect information.

Example dead URL: http://www.ew.com/ew/article/0,,286000,00.html 

..for which there is a ghost redirect in the Wayback Machine: https://web.archive.org/web/20150619213058/https://www.ew.com/ew/article/0,,286000,00.html

..that leads to the destination URL: http://www.ew.com/article/1998/12/04/twelve-songs-christmas

Running
==========

	Ghostredir

	  -u <url>      (required) URL to process
	  -r <#>        (optional) Number of retries for wget and curl (default: 15)
	  -w <#>        (optional) Seconds wait between retries (default: 3)
	  -d            (optional) Enable debugging output

	  Example:
	    ./ghostredir -u 'http://www.ew.com/ew/article/0,,286000,00.html'
	  Produces:
	    http://www.ew.com/article/1998/12/04/twelve-songs-christmas

Why this?
=========
When solving for link rot, a link might appear to be dead when it is actually still on the live web, but at a different URL. There may have once been a 301 redirect, but this was deleted by the website ie. the redirect itself is link rot. This tool will allow you to quickly discover ghost redirects.

Note: The tool does not determine if the new URL is working. For example the new URL could be dead, and even itself have a ghost redirect. 

Dependencies
====
* GNU awk 4.1+
* wget
* curl

Setup 
=====

* Clone, download, or copy-paste the file ghostredir.awk

	cd ~
	git clone 'https://github.com/greencardamom/Ghostredir'

* Set the file executable

	chmod 750 ghostredir.awk

* Create a symlink (optional)

	ln -s ghostredir.awk ghostredir

* Edit the top shebang line to the location of your awk program

	#!/usr/bin/awk 

* Test

	./ghostredir

Credits
==================
by User:GreenC (en.wikipedia.org)

MIT License Copyright 2024

