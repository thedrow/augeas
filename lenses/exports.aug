(* Lens for Linux syntax of NFS exports(5) *)

(*
Module: Exports
    Parses /etc/exports

Author: David Lutterkort <lutter@redhat.com>

About: Description
    /etc/exports contains lines associating a directory with one or
    more hosts, and NFS options for each host.

About: Usage Example

    $ augtool
    augtool> ls /files/etc/exports/
    comment[1] = /etc/exports: the access control list for filesystems which may be exported
    comment[2] = to NFS clients.  See exports(5).
    comment[3] = sample /etc/exports file
    dir[1]/ = /
    dir[2]/ = /projects
    dir[3]/ = /usr
    dir[4]/ = /home/joe


    augtool> ls /files/etc/exports/dir[1]
    client[1]/ = master
    client[2]/ = trusty

    The corresponding line in the file is:

	/               master(rw) trusty(rw,no_root_squash)

    Digging further:

    augtool> ls /files/etc/exports/dir[1]/client[1]
    option = rw

    To add a new entry, you'd do something like this:

    augtool> set /files/etc/exports/dir[10000] /foo
    augtool> set /files/etc/exports/dir[last()]/client[1] weeble
    augtool> set /files/etc/exports/dir[last()]/client[1]/option[1] ro
    augtool> set /files/etc/exports/dir[last()]/client[1]/option[2] all_squash
    augtool> save
    Saved 1 file(s)

    Which creates the line:

    /foo weeble(ro,all_squash)

About: Limitations
    This lens cannot handle options without a host, as with the last
    example line in "man 5 exports":

	/pub            (ro,insecure,all_squash)

    In this case, though, you can just do:

	/pub            *(ro,insecure,all_squash)

    It also can't handle whitespace before the directory name.
*)

module Exports =
  autoload xfm

  let client_re = /[a-zA-Z0-9\-\.@\*\?\/]+/

  let eol = del /[ \t]*\n/ "\n"
  
  let option = [ label "option" . store /[^,)]+/ ]

  let client = [ label "client" . store client_re .
                    ( Util.del_str "(" . 
                        option .
                        ( Util.del_str "," . option ) * .
                      Util.del_str ")" )? ]

  let entry = [ label "dir" . store /\/[^ \t]*/ .
                Util.del_ws_spc .
                client . (Util.del_ws_spc . client)* . eol ]

  let lns = (Hosts.empty | Hosts.comment | entry)*

  let xfm = transform lns (incl "/etc/exports")
