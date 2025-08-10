FROM mysql:8.0
ENV MYSQL_ROOT_PASSWORD=password
ENV MYSQL_DATABASE=profile_db
ENV MYSQL_USER=user
ENV MYSQL_PASSWORD=password
COPY init.sql /docker-entrypoint-initdb.d/
EXPOSE 3306
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD mysqladmin ping -u root -ppassword || exit 1
