FROM fulcrum/php7.4-composer1 AS builder

ENV BUILDDATE 202012181700

RUN STARTTIME=$(date "+%s")                                                                      && \
echo "################## [$(date)] Building Interim ##################"                          && \
echo "################## [$(date)] Install Drush ##################"                             && \
DRUSHCMDS=/usr/share/drush/commands                                                              && \
DRUSHDIR=/usr/local/drush                                                                        && \
mkdir -p $DRUSHCMDS $DRUSHDIR                                                                    && \
chown php.php $DRUSHCMDS $DRUSHDIR                                                               && \
su - php -c "cd $DRUSHDIR && php /usr/local/bin/composer require drush/drush:8.*"                && \
ln -s $DRUSHDIR/vendor/drush/drush/drush /usr/local/bin/drush                                    && \
su - php -c "/usr/local/bin/drush @none dl registry_rebuild-7.x"                                 && \
echo "################## [$(date)] Reset php user for fulcrum ##################"                && \
deluser php                                                                                      && \
adduser -h /var/www/html -s /bin/sh -D -H -u 1971 php                                            && \
echo "################## [$(date)] Clean up container/put on a diet ##################"          && \
rm -vrf $FILE /var/cache/apk/* /var/cache/distfiles/* /usr/local/bin/composer                       \
  $DRUSHDIR/composer.* $DRUSHCMDS/.composer $DRUSHDIR/.composer*                                 && \
find /usr/local -type f -exec strip -v {} \;                                                     && \
apk del binutils curl                                                                            && \
echo "################## [$(date)] Done ##################"                                      && \
echo "################## Elapsed: $(expr $(date "+%s") - $STARTTIME) seconds ##################"

FROM scratch
LABEL IF Fulcrum "fulcrum@ifsight.net"
COPY --from=builder / /

ENV COLUMNS 100
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php-fpm

HEALTHCHECK --interval=5s --timeout=60s --retries=3 CMD /healthcheck.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/sbin/php-fpm"]

CMD ["--nodaemonize"]

USER php
