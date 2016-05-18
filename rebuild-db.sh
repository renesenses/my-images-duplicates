rm img.db
rm -R Images
sqlite3 img.db < cr-imgdb.sql
perl -w mk-imgdb-classes.pl