--SELECT * FROM doarni.login;
--update doarni.login set update = 'yes'
--update doarni.login set update = 'no'
--select * from doarni.updates 
--GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA doarni to reader;
--update doarni.updates set url = 'https://www.dropbox.com/s/wc5kextstgfow4u/PATCHv1.0.1.zip?dl=1'
with s1 as(select * from pg_tables where schemaname='doarni') SELECT schemaname, tablename from s1