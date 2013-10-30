#!/usr/bin/tclsh
package require http
package require tls
package require json

proc get { url } {
    set token [http::geturl $url]
    upvar #0 $token state
    return [json::json2dict $state(body)]
}

http::register https 443 ::tls::socket
puts [get https://api.travis-ci.org/config]
