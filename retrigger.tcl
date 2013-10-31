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

proc post { url data } {
    return [process_token [http::geturl $url -query [generate_query_params $data] ] ]
}

proc generate_query_params { items } {
    return http::formatQuery {*}$items
}

http::register https 443 ::tls::socket
set params {}
puts [post https://api.travis-ci.org/config $params]
