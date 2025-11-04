#!/bin/bash
certbot renew --nginx --noninteractive --post-hook "nginx -s reload"
