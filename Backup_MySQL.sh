#!/bin/bash
#
# MySQL_Backup
#
# Copyright (C) 2015 Allan Moraes <allan@mysqlbox.ml> <www.mysqlbox.ml>
#
# Este e um software livre e gratuíto que atua com a licensa 
# GNU GENERAL PUBLIC LICENSE Version 3. O seu uso e permitido
# mas a sua venda e proibida.

BACKUP_PATH="/usr/local/bin/MySQL-Backup/tmp" #Local temporario dos backups
USER="" #Usuario do backup
SECRET"" #Senha do usuario
DROPBOX_PATH="/usr/local/bin/Dropbox-Uploader" #Local de instalacao do Dropbox-Uploader
LOG="/var/log/mysql-backup.log" #Local dos logs


#Funcao que consulta todos os bancos do seu servidor
function Get-Databases(){
	if [ -d $BACKUP_PATH ]; then
		echo "`date`  -  Path temporario OK" >> $LOG
	else 
		mkdir -p $BACKUP_PATH
	fi
	for DB in `mysql -u$USER -p$SECRET -e "SHOW DATABASES"|grep -v Database`; do
		echo "`date`  -  Fazendo backup do banco $DB" >> $LOG
		mysqldump -u$USER -p$SECRET $DB > $BACKUP_PATH/$DB.sql >> $LOG 2>&1
	done
}

#Funcao que compact dos backups
function Zip-Databases(){
	cd $BACKUP_PATH
	tar -czf backup-`hostname`-`date +%d_%m_%Y`.tar.gz *.sql
}

#Funca que faz o upload do backup
function Upload-Databases(){
	$DROPBOX_PATH/dropbox_uploader.sh upload $BACKUP_PATH/*.tar.gz >> $LOG 2>&1
	rm -rf $BACKUP_PATH/*
}

#Chama as funcoes criadas acima
Get-Databases
Zip-Databases
Upload-Databases
