# Alpine Nginx

This build of Nginx on Alpine includes:

- [ModSecurity v3](https://github.com/SpiderLabs/ModSecurity) using the [ModSecurity v3 Nginx Connector](https://github.com/SpiderLabs/ModSecurity-nginx) and the [OWASP Core Rule Set](https://github.com/coreruleset/coreruleset)
- [GeoIP2](https://github.com/leev/ngx_http_geoip2_module) with the [dbip databases](https://db-ip.com/)
- a few additional general security features

You can customize this build by changing the files in the `conf` directory.

`conf/modsec` contains files that link to our owasp rules and contain general modsec settings

`conf/nginx` contains our nginx, http, and https config files. The default http and https server blocks are built with the expectation of using php. You will need to remove the php block and rules if you are using a different language.

`conf/owasp` contains our owasp core rule set config

This image also includes generic error and maintenance pages that you can use out of the box or customize to match the design of your site.
