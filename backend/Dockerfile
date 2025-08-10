FROM mysql:8.0

ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=profile_db
ENV MYSQL_USER=appuser
ENV MYSQL_PASSWORD=apppassword

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD mysqladmin ping -u root -prootpassword || exit 1
