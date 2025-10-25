@echo off
chcp 65001 > nul
java -Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN -jar target/elasticproxy-server-1.5.3.jar