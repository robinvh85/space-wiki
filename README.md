# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Production with puma and nginx
## Nginx config

/etc/nginx/conf.d/space-wiki.conf
<code>
upstream app {
    # Path to Puma SOCK file, as defined previously
    server unix:///tmp/space_wiki.sock fail_timeout=0;
}

server {
    listen 80;
    server_name spacewiki;

    root /home/ec2-user/space-wiki/public;

    #try_files $uri/index.html $uri @app;
    try_files $uri @app;

    location @app {
        proxy_pass http://app;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
    }

    error_page 500 502 503 504 /500.html;
    client_max_body_size 4G;
    keepalive_timeout 10;
}
</code>

## Start puma
<code>
bundle exec puma -e production -d -b unix:///tmp/space_wiki.sock
</code>