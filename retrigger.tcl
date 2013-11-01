#!/usr/bin/tclsh
package require Tcl 8.5
package require http
package require tls
package require json

proc process_token { token } {
    upvar #0 $token state
    set result [json::json2dict $state(body)]
    http::cleanup $token
    return $result
}

proc get { url } {
    return [process_token [http::geturl $url]]
}

proc authenticated_get { url token } {
    return [process_token [http::geturl $url -headers [get_auth_headers $token] ] ]
}

proc post { url data } {
    return [process_token [http::geturl $url -query [generate_query_params $data] ] ]
}

proc authenticated_post { url data token } {
    return [process_token [http::geturl $url -query [generate_query_params $data] -headers [get_auth_headers $token] ] ]
}

proc generate_query_params { items } {
    return [http::formatQuery {*}$items]
}

proc get_github_token { } {
    set fp [open "token.txt" r]
    set filedata [read $fp]
    close $fp
    return $filedata
}

proc get_repo_list {} {
    set fp [open "repos.txt" r]
    set filedata [read $fp]
    close $fp
    return [split $filedata]
}

proc get_auth_headers { token } {
    return [list Authorization "token $token"]
}

proc get_travis_token {} {
    set result [post https://api.travis-ci.org/auth/github "github_token [get_github_token]"]
    return [dict get $result access_token]
}

proc get_last_master_build { repo } {
    set result [get https://api.travis-ci.org/repos/$repo/branches/master]
    return [dict get $result branch id]
}

proc restart_build { build_id token } {
    set result [authenticated_post https://api.travis-ci.org/requests "build_id $build_id" $token]
    return [dict get $result result]
}

http::register https 443 ::tls::socket
set token [get_travis_token]
foreach repo [get_repo_list] {
    if {$repo != {}} {
        set build_id [get_last_master_build $repo]
        if {[restart_build $build_id $token] == true} {
            puts "Successfully restarted $repo"
        } else {
            puts "$repo failed to restart"
        }
    }
}
