#simple-nuget-server

The Simple NuGet Server installed on CentOS 7.

### Pull image

```
docker pull openmedicus/simple-nuget-server
```

### Using config file on host

```
mkdir -p /www/simple-nuget-server/db
mkdir -p /www/simple-nuget-server/packagefiles

chown apache:apache /www/simple-nuget-server/db
chown apache:apache /www/simple-nuget-server/packagefiles
```

### SELinux

```
chcon -Rt svirt_sandbox_file_t /www/
```

```
semanage port -m -t http_port_t -p tcp 8080

```

```
chcon -R system_u:object_r:httpd_sys_content_t:s0 /www/simple-nuget-server/packagefiles
```


### Run

```
docker run --name=simple-nuget-server --privileged=true -p 8080:80 -v /www/simple-nuget-server/config.php:/var/www/inc/config.php:ro -v /www/simple-nuget-server/db:/var/www/db:rw -v /www/simple-nuget-server/packagefiles:/var/www/packagefiles:rw -d openmedicus/simple-nuget-server
```

### Systemd

/etc/systemd/system/docker-simple-nuget-server.service

```
[Unit]
Description=Simple NuGet Server Container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --name=simple-nuget-server --privileged=true -p 8080:80 -v /www/simple-nuget-server/config.php:/var/www/inc/config.php:ro -v /www/simple-nuget-server/db:/var/www/db:rw -v /www/simple-nuget-server/packagefiles:/var/www/packagefiles:rw openmedicus/simple-nuget-server
ExecStop=/usr/bin/docker stop -t 2 simple-nuget-server
ExecStopPost=/usr/bin/docker rm -f simple-nuget-server

[Install]
WantedBy=default.target
```

Now reload systemd, enable and start
```
# systemctl daemon-reload
# systemctl enable docker-simple-nuget-server
# systemctl start docker-simple-nuget-server
```

### Nginx

```
upstream nuget.example.local {
    server 172.17.0.1:8080;
}

#server {
#    listen 80;
#    server_name nuget.example.com;
#    return 301 https://$host$request_uri;
#}

server {
        listen 80;
        server_name nuget.example.com;
        access_log /var/log/nginx/nuget.example.com.log;
    root /www/simple-nuget-server;

        #ssl on;
        #ssl_certificate        /etc/pki/tls/certs/example.com.crt;
        #ssl_certificate_key    /etc/pki/tls/private/example.com.key;

    client_max_body_size 50M;

        rewrite ^/$ /index.php;
        rewrite ^/\$metadata$ /metadata.xml;
        rewrite ^/Search\(\)/\$count$ /count.php;
        rewrite ^/Search\(\)$ /search.php;
        rewrite ^/Packages\(\)$ /search.php;
        rewrite ^/Packages\(Id='([^']+)',Version='([^']+)'\)$ /findByID.php?id=$1&version=$2;
        rewrite ^/GetUpdates\(\)$ /updates.php;
        rewrite ^/FindPackagesById\(\)$ /findByID.php;
        # NuGet.exe sometimes uses two slashes (//download/blah)
        rewrite ^//?download/([^/]+)/([^/]+)$ /download.php?id=$1&version=$2;
        rewrite ^/([^/]+)/([^/]+)$ /delete.php?id=$1&version=$2;

        # NuGet.exe adds /api/v2/ to URL when the server is at the root
        rewrite ^/api/v2/package/$ /index.php;
        rewrite ^/api/v2/package/([^/]+)/([^/]+)$ /delete.php?id=$1&version=$2;

        location / {
        satisfy  any;
        allow 12.12.12.12/32;
        deny all;

        auth_basic "NuGet Server";
            auth_basic_user_file /www/simple-nuget-server/password;

        proxy_http_version 1.1;
                proxy_pass http://nuget.example.local;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_redirect    off;
        }

    # Used with Location
    location /packagefiles {
        auth_basic "NuGet Server";
                auth_basic_user_file /www/simaple-nuget-server/password;
    }
}

```
