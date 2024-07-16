Ghostredir
===========

Check for and resolve ghost redirects

A ghost redirect is a redirect (301/302) that once existed and was later deleted by the website. However that redirect still 
exists in the Wabyack Machine and thus the destination URL can be determined by searching the Wayback Machine for the old 
redirect information.

Example: http://www.ew.com/ew/article/0,,286000,00.html is 404

But there is a redirect in the Wayback Machine: https://web.archive.org/web/20150619213058/https://www.ew.com/ew/article/0,,286000,00.html

This leads to the destination URL: http://www.ew.com/article/1998/12/04/twelve-songs-christmas

Running
==========

	ghostredir

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
When solving for link rot, a link might appear to be 404 ("dead") when actually still on the live web, at a different URL. There may have once been a 301 ("redirect"), but this was deleted by the website ie. the redirect is link rotted. This tool will allow you to quickly find ghost redirects and better solve link rot.

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

* Set the first shebang line to the location of your awk 

* Test

	./ghostredir

Credits
==================
by User:GreenC (en.wikipedia.org)

MIT License Copyright 2024

