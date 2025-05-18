FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "Asia/Shanghai"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password


LABEL org.opencontainers.image.source="https://github.com/wswv/cups-docker"
LABEL org.opencontainers.image.description="CUPS Printer Server"
LABEL org.opencontainers.image.author="John Z, qiangzhang09@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/wswv/cups-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses=GNU


# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install -qqy \
    apt-utils \
    usbutils \
    cups \
    cups-filters \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    avahi-daemon \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and group
RUN groupadd -g 1000 cupsuser && \
    useradd -u 1000 -g cupsuser -m -s /bin/bash cupsuser && \
    usermod -aG lp cupsuser


# copy pdd file
COPY drivers/Lenovo_LJ2400L.ppd /usr/share/cups/model/
RUN chmod 644 /usr/share/cups/model/Lenovo_LJ2400L.pdd && \
    chown -R cupuser:cupsuser /usr/share/cups/model/ && \
    chown -R cupsuser:cupsuser /etc/cups

# Let non-root user to bind lower port
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/cupsd



EXPOSE 631
EXPOSE 5353/udp

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# back up cups configs in case used does not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

# Copy and check the script of usb privilege
COPY check-usb-permissions.sh /check-usb-permissions.sh
RUN chmod +x check-usb-permissions.sh && \
    chown cupsuser:cupsuser /check-usb-permissions.sh

# Switch to non-root user  
USER cupsuser  

CMD ["/check-usb-permissions.sh"]
