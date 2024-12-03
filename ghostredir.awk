#!/usr/bin/gawk -bE   

#
# Check for and resolve ghost redirects
#
# A ghost redirect is a redirect (301/302) that once existed and was later deleted by the website.
#   However that redirect still exists in the Wabyack Machine and thus the destination URL
#   can be determined by scouring the Wayback Machine for this old redirect information.
#
# Example: http://www.ew.com/ew/article/0,,286000,00.html is 404
#  But there is a redirect in the Wayback Machine:
#    https://web.archive.org/web/20150619213058/https://www.ew.com/ew/article/0,,286000,00.html
#  That leads to the destination URL:
#    http://www.ew.com/article/1998/12/04/twelve-songs-christmas

# The MIT License (MIT)
#
# Copyright (c) 2025 by User:GreenC (at en.wikipedia.org)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


BEGIN {

  delete G  # Global vars

  G["retry"] = 15      # Retry times for wget and curl (each)
  G["wait"] = 3        # Seconds wait between retries

  Optind = Opterr = 1 
  while ((G["C"] = getopt(ARGC, ARGV, "du:r:w:")) != -1) { 
      G["opts"]++
      if(G["C"] == "u")                 #  -u <url>    (required) URL to check
        G["url"] = Optarg
      if(G["C"] == "r")                 #  -r <#>      (optional) Number of retries
        G["retry"] = 1
      if(G["C"] == "w")                 #  -w <#>      (optional) Seconds wait between retries
        G["wait"] = 1
      if(G["C"] == "d")                 #  -d          (optional) Enable debugging
        G["debug"] = 1
  }

  if(empty(G["url"]) || G["opts"] == 0) {
    help()
    exit
  }

  srd = searchredir()
  if(!empty(srd)) {
    grd = getredir(srd)
    if(!empty(grd)) {
      if(G["debug"])
        debug("Final result: " grd)
      else
        print grd
    }
  }

}

#
# Get the redir target URL from the Wayback redir page
#
function getredir(srd,  command,ci,f,i,a,t,j) {

  command = "curl -ILs " shquote(srd)

  debug(command)

  for(ci = 0; ci <= int(G["retry"]); ci++) {

    if(ci == G["retry"]) { 
      debug("getredir max retries reached")
      exit
    }

    f = sys2var(command)

    debug("getredir attempt " ci)

    if(length(f) > 5) 
      break

    sleep(G["wait"], "unix") 
  }

  for(i=0; i <= splitn(f, a, i); i++) { 
    if(a[i] ~ /^[ ]*[Ll]ocation:/) {
      sub("^[ ]*[Ll]ocation:[ ]*(https?://web[.]archive[.]org)?/web/[0-9]{14}(id_)?/", "", a[i])
      if(a[i] !~ "/web/[0-9]{14}")
        t[++j] = a[i]
    } 
  }

  if(!empty(t[j])) 
    return t[j]
  else 
    debug("getredir none found")

}

#
# Search the WaybackMachine for a redirect page. The most recent one.
#
function searchredir(  command,ci,f,i,a,b,t,j,result) {

  command = "wget -q -O- " shquote("https://web.archive.org/cdx/search/cdx?url=" G["url"] "&MatchType=prefix")

  debug(command)

  for(ci = 0; ci <= int(G["retry"]); ci++) {

    if(ci == G["retry"]) { 
      debug("searchredir max retries reached")
      exit
    }

    f = sys2var(command)

    debug("searchredir attempt " ci)

    if(length(f) > 5) 
      break

    sleep(G["wait"], "unix") 
  }

  for(i=0; i <= splitn(f, a, i); i++) { 
    if(a[i] ~ / 30[12]/) {
      split(a[i], b, " ")
      t[++j] = b[2] 
    } 
  }

  if(t[j] ~ /[0-9]{14}/) {
    result = "https://web.archive.org/web/" t[j] "/" G["url"]
    debug("searchredir result: " result)
    return result
  }

  debug("searchredir result: none found")

}

#
# Help
#
function help() {

  print ""
  print "ghostredir"
  print ""
  print "  -u <url>      (required) URL to process"
  print "  -r <#>        (optional) Number of retries for wget and curl (default: " G["retry"] ")"
  print "  -w <#>        (optional) Seconds wait between retries (default: " G["wait"] ")"
  print "  -d            (optional) Enable debugging"
  print ""
  print "  Example:"
  print "    ./ghostredir -u 'http://www.ew.com/ew/article/0,,286000,00.html'"
  print ""

}


# ----- Functions from library.awk in BotWikiAwk https://github.com/greencardamom/BotWikiAwk ----------------

#
# stdErr() - print s to /dev/stderr
# 
#  . if flag = "n" no newline
#  
function stdErr(s, flag) { 
    if (flag == "n")
        printf("%s",s) > "/dev/stderr"
    else           
        printf("%s\n",s) > "/dev/stderr"
    close("/dev/stderr")
}

#
# shquote() - make string safe for shell
#
#  . an alternate is shell_quote.awk in /usr/local/share/awk which uses '"' instead of \'
#
#  Example:
#     print shquote("Hello' There")    produces 'Hello'\'' There'
#     echo 'Hello'\'' There'           produces Hello' There
#   
function shquote(str,  safe) {
    safe = str
    gsub(/'/, "'\\''", safe)
    gsub(/’/, "'\\’'", safe)
    return "'" safe "'"
}

# 
# sleep() - sleep seconds
#
#   . Caution: systime() method eats CPU and has up-to 1 second error of margin (averge half-second)
#   . optional "unix" will spawn unix sleep
#   . Use unix sleep for applications with long or many sleeps, needing precision, or sub-second sleep
#  
function sleep(seconds,opt,   t) {

    if (opt == "unix")
        sys2var("sleep " seconds)
    else {
      t = systime()           
      while (systime() < t + seconds) {}
    }

}

#
# sys2var() - run a system command and store result in a variable
#
#  . supports pipes inside command string
#  . stderr is sent to null
#  . if command fails (errno) return null
#
#  Example:        
#     googlepage = sys2var("wget -q -O- http://google.com")
#
function sys2var(command        ,fish, scale, ship) {

    # command = command " 2>/dev/null"
    while ( (command | getline fish) > 0 ) {
        if ( ++scale == 1 )
            ship = fish
        else
            ship = ship "\n" fish
    }
    close(command)
    system("")
    return ship
}

#                  
# empty() - return 0 if string is 0-length
#
function empty(s) { 
    if (length(s) == 0)
        return 1
    return 0       
}             


#
# readfile() - same as @include "readfile"
#
#   . leaves an extra trailing \n just like with the @include readfile
#
#   Credit: https://www.gnu.org/software/gawk/manual/html_node/Readfile-Function.html by Denis Shirokov
#    
function readfile(file,     tmp, save_rs) {
    save_rs = RS     
    RS = "^$"            
    getline tmp < file
    close(file)
    RS = save_rs
    return tmp      
}

#
# exists2() - check for file existence
#
#   . return 1 if exists, 0 otherwise.
#   . no dependencies
#                       
function exists2(file    ,line, msg) {
    if ((getline line < file) == -1 ) {
        msg = (ERRNO ~ /Permission denied/ || ERRNO ~ /a directory/) ? 1 : 0
        close(file)
        return msg
    }
    else {
        close(file)
        return 1
    }
}

#
# checkexists() - check file or directory exists.
#
#   . action = "exit" or "check" (default: check)
#   . return 1 if exists, or exit if action = exit
#   . requirement: @load "filefuncs"
#
function checkexists(file, program, action) {
    if ( ! exists2(file) ) {
        if ( action == "exit" ) {
            stdErr(program ": Unable to find/open " file)
            print program ": Unable to find/open " file
            system("")      
            exit    
        }                 
        else             
            return 0
    }    
    else             
        return 1         
}          

#
# splitn() - split input 'fp' along \n
#
#  Designed to replace typical code sequence
#      fp = readfile("test.txt")
#      c = split(fp, a, "\n")
#      for(i = 1; i <= c; i++) {
#        if(length(a[i]) > 0)
#          print "a[" i "] = " a[i]
#      }
#  With
#      for(i = 1; i <= splitn("test.txt", a, i); i++)
#        print "a[" i "] = " a[i]
#         
#   . If input is the name of a file, it will readfile() it; otherwise use literal text as given
#   . Automatically removes blank lines from input
#   . Allows for embedding in for-loops
#
#   Notes
#
#   . The 'counter' ('i' in the example) is assumed initialized to 1 in the for-loop. If
#     different, pass a start value in the fourth argument eg.
#             for(i = 5; i <= splitn("test.txt", a, i, 5); i++)
#   . If not in a for-loop the counter is not needed eg.
#             c = splitn("test.txt", a)
#   . 'fp' can be a filename, or a string of literal text. If 'fp' does not contain a '\n'
#     it will search for a filename of that name; if none found it will treat as a
#     literal string. If it means to be a string, for safety add a '\n' to end. eg.
#             for(i = 5; i <= splitn(ReadDB(key) "\n", a, i); i++)
#    
#
function splitn(fp, arrSP, counter, start,    c,j,dSP,i,save_sorted) {

    if ( empty(start) )
        start = 1                
    if (counter > start)
        return length(arrSP)

    if ("sorted_in" in PROCINFO)       
        save_sorted = PROCINFO["sorted_in"]
    PROCINFO["sorted_in"] = "@ind_num_asc"

    if (fp !~ /\n/) {
        if (checkexists(fp))      # If the string doesn't contain a \n check if a filename exists
            fp = readfile(fp)     # with that name. If not assume it's a literal string. This is a bug
    }                             # in case a filename exists with the same name as the literal string.

    delete arrSP
    c = split(fp, dSP, "\n")
    for (j in dSP) {
        if (empty(dSP[j]))
            delete dSP[j]
    }
    i = 1
    for (j in dSP)  {
        arrSP[i] = dSP[j]
        i++
    }

    if (save_sorted)
        PROCINFO["sorted_in"] = save_sorted
    else
        PROCINFO["sorted_in"] = ""

    return length(dSP)
}

# 
# getopt() - command-line parser
# 
#   . define these globals before getopt() is called:
#        Optind = Opterr = 1
# 
#   Credit: GNU awk (/usr/local/share/awk/getopt.awk)
# 
function getopt(argc, argv, options,    thisopt, i) {

    if (length(options) == 0)    # no options given
        return -1

    if (argv[Optind] == "--") {  # all done
        Optind++
        _opti = 0
        return -1
    } else if (argv[Optind] !~ /^-[^:[:space:]]/) {
        _opti = 0
        return -1
    }              
    if (_opti == 0)
        _opti = 2
    thisopt = substr(argv[Optind], _opti, 1)
    Optopt = thisopt
    i = index(options, thisopt)
    if (i == 0) {
        if (Opterr)
            printf("%c -- invalid option\n", thisopt) > "/dev/stderr"
        if (_opti >= length(argv[Optind])) {
            Optind++
            _opti = 0
        } else
            _opti++
        return "?"
    }
    if (substr(options, i + 1, 1) == ":") {
        # get option argument
        if (length(substr(argv[Optind], _opti + 1)) > 0)
            Optarg = substr(argv[Optind], _opti + 1)
        else
            Optarg = argv[++Optind]
        _opti = 0
    } else
        Optarg = ""
    if (_opti == 0 || _opti >= length(argv[Optind])) {
        Optind++
        _opti = 0
    } else
        _opti++
    return thisopt
}

function debug(s) {
  if(G["debug"])
    stdErr(s)
}
