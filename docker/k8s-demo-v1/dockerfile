# Docker Tiny Web Demo Container Image.
FROM        progrium/busybox
MAINTAINER Amit Vashist <amitvashist7@gmail.com>

RUN opkg-install uhttpd
RUN printf '#!/bin/sh\nset -e\n\nchmod 755 /www\nexec /usr/sbin/uhttpd $*\n' > /usr/sbin/run_uhttpd && chmod 755 /usr/sbin/run_uhttpd

VOLUME ["/www"]
WORKDIR /www/
ADD index.html /www/index.html

EXPOSE 80

ENTRYPOINT ["/usr/sbin/run_uhttpd", "-f", "-p", "80", "-h", "/www"]
CMD
