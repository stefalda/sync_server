A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.

Under Linux install the sqlite3's libraries:
<pre>
sudo apt-get install sqlite3 libsqlite3-dev
</pre>


curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"clientId":"8a0f7491-10e4-11ed-a726-ef13cdc3a029","lastSync":1659542493559,"changes":[]}' \
  https://memento.babisoft.com/pull/MEMENTO
  

 curl --header "Content-Type: application/json" \
    --request POST \
    --data '{"clientId":"8a0f7491-10e4-11ed-a726-ef13cdc3a029","lastSync":1659542493559,"changes":[]}' \
    http://localhost:8076/pull/MEMENTO



pragma table_info('users');

cid , name, type, notnull, dflt_value, pk
0,id,integer,1,NULL,1
1,email,varchar(255),1,NULL,0
2,password,varchar(255),1,NULL,0

