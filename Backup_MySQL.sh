#!/bin/bash
#
# MySQL_Backup
#
# Copyright (C) 2015 Allan Moraes <allan@mysqlbox.com.br> <www.mysqlbox.com.br>
#
# Este programa e um software livre; voce pode redistribui-lo e / ou modifica-lo 
# sob os termos da GNU General Public License como publicado pela
# Free Software Foundation; tanto a versao 3 da Licenca, ou
# (A seu criterio) qualquer versao posterior.
#
# Este programa a distribuido para ajudar todos DBA,
# mas SEM QUALQUER GARANTIA; mesmo sem a garantia implicita de
# COMERCIALIZACAO ou ADEQUACAO A UM DETERMINADO FIM. veja a
# GNU General Public License para mais detalhes.
#
# Voce deve ter recebido uma copia da Licença Publica Geral GNU
# junto com este programa; se nao, escreva para a Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, EUA.

###Parametros do script###

BACKUP_NAME="backup-`hostname`-`date +%d_%m_%Y`"	#Nome que ficara o backup. Ex: backup-SERVER01-01_12_2015
BACKUP_PATH="/usr/local/bin/MySQL-Backup"		#Local do diretorio do script
BACKUP_TEMP="$BACKUP_PATH/tmp" 				#Local temporario dos backups
BACKUP_SHELL="$BACKUP_PATH/Backup_MySQL.sh"		#Shell do backup
PERMISSIONS=`stat -c %a $BACKUP_SHELL 2>&1`		#Pega as permissoes do shell
DROPBOX_PATH="/usr/local/bin/Dropbox-Uploader" 		#Local de instalacao do Dropbox-Uploader
DROPBOX_FILE="$DROPBOX_PATH/dropbox_uploader.sh"	#Local do Dropbox-Uploader.sh
LOG_FILE="/var/log/mysql-backup.log" 			#Local dos logs
IGNORED_DB="information_schema|performance_schema"      #Bancos ignorados pela rotina do backup separados por pipe (|)
USER="" 						#Usuario do backup
SECRET="" 						#Senha do usuario

###Nao editar abaixo###

#Verifica se o nome do backup nao e nulo
if [ -z $BACKUP_NAME ]; then
	echo -e "\n\tERRO: Variavel BACKUP_NAME contem valor nulo"
	echo  "`date` - ERRO: Variavel BACKUP_NAME contem valor nulo" >> $LOG_FILE
	#exit 1
fi

#Verifica se o local configurado esta correto
if [ ! -d $BACKUP_PATH ]; then
	echo -e "\n\tERRO: Variavel BACKUP_PATH esta incorreta, o local de instalacao nao existe"
	echo "`date` - ERRO: Variavel BACKUP_PATH esta incorreta, o local de instalacao nao existe" >> $LOG_FILE
	##exit 1
fi

#Verifica se o local temporario existe
if [ ! -d $BACKUP_TEMP ]; then
	echo -e "\n\tERRO: Variavel BACKUP_TEMP esta incorreta, o local de backup nao existe"
	echo "`date` - ERRO: Variavel BACKUP_TEMP esta incorreta, o local de backup nao existe" >> $LOG_FILE
	#exit 1
fi
if [ ! -f $BACKUP_SHELL ]; then
	echo -e "\n\tERRO: O shell MySQL_Backup.sh nao foi encontrado"
	echo "`date` - ERRO: O shell MySQL_Backup.sh nao foi encontrado" >> $LOG_FILE
	#exit 1
fi
#Verifica se a permissao do shell esta correta
if [ $PERMISSIONS != "700" ]; then
	echo -e "\n\tERRO: Permissao do arquivo $BACKUP_SHELL incorreta! Permissao deve ser 700"
	echo "`date` - ERRO: Permissao do arquivo $BACKUP_SHELL incorreta! Permissao deve ser 700" >> $LOG_FILE
	#exit 1
fi

#Verifica se o local do Dropbox-Uploader esta correto
if [ ! -f $DROPBOX_FILE ]; then
	echo -e "\n\tERRO: Variavel DROPBOX_FILE esta incorreta, o local informado do Dropbox-Uploader nao existe"
	echo "`date` - ERRO: Variavel DROPBOX_FILE esta incorreta, o local informado do Dropbox-Uploader nao existe" >> $LOG_FILE
	#exit 1
fi

#Verifica se o usuario nao e nulo
if [ -z $USER ]; then
	echo -e "\n\tERRO: Usuario nao configurado"
	echo "`date` - ERRO: Usuario nao configurado" >> $LOG_FILE
	#exit 1
fi

#Verifica se a senha nao e nula
if [ -z $SECRET ]; then
	echo -e "\n\tERRO: A senha do usuario $USER nao foi fornecida"
	echo "`date` - ERRO: A senha do usuario $USER nao foi fornecida" >> $LOG_FILE
	#exit 1
fi

#Funcao que consulta todos os bancos do seu servidor e faz o backup
function Get-Databases(){
	for DB in `mysql -u$USER -p$SECRET -e "SHOW DATABASES"|egrep -vi 'Database|'$IGNORED_DB`; do
		echo "`date`  -  Fazendo backup do banco $DB"
		mysqldump -u$USER -p$SECRET  $DB > $BACKUP_TEMP/$DB.sql
	done
}

#Funcao que compact dos backups
function Zip-Databases(){
	cd $BACKUP_TEMP
	tar -czf $BACKUP_NAME.tar.gz *.sql
}

#Funca que faz o upload do backup
function Upload-Databases(){
	$DROPBOX_FILE upload $BACKUP_TEMP/*.tar.gz $BACKUP_NAME.tar.gz >> $LOG_FILE 2>&1
	rm -rf $BACKUP_TEMP/*
}

#Chama as funcoes criadas acima
Get-Databases >> $LOG_FILE 2>&1
Zip-Databases
Upload-Databases
