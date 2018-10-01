MySQL-Backup
==============

É fato que devemos ter backups íntegros das nossas aplicações e servidores. Um backup confiável pode ser a diferença entre você ter que trabalhar durante algumas horas ou alguns dias ou até mesmo a diferença entre o sucesso ou a falência de uma empresa. Nada é mais frustrante, desmotivante e caro do que ter que refazer todo um sistema por uma simples falha no seu backup. 

Artigo previamente publicado no meu blog: www.mysqlbox.com.br 

### Configurando o ambiente

Para que o nosso script consiga usar a API, precisamos instalar o curl. O curl é uma ferramenta de linha de comando open source que transfere dados para uma URL, suportando DICT, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet e TFTP. Suporta certificados SSL, HTTP POST, HTTP PUT, upload FTP, proxies, HTTP/2, cookies, autenticação de usuário e senha (Basic, Plain, Digest, CRAM- MD5, NTLM, Negotiate e Kerberos) , tunneling proxy e muito mais. 

Para instalá-lo, basta executar o comando: 

```yum install curl``` 

Você precisará do git para efetuar o download dos scripts. Para quem não conhece, o git é um sistema de controle de versão, gratuito e open source. Para você trabalhar com o GitHub ou BitBucket, você precisa ter o git instalado em sua máquina. Então vamos instalá-lo: 

```yum install git``` 

Com o curl e git instalados, precisamos configurar o nosso usuário de MySQL que fará os dumps dos nossos bancos via mysqldump. O mysqldump é um utilitário do MySQL que executa backups lógicos, produzindo um conjunto de instruções SQL que podem ser executadas para reproduzir as definições de objeto de banco de dados originais e os dados da tabela. Ele despeja um ou mais bancos de dados MySQL para backup. O comando mysqldump também pode gerar a saída em formato CSV, ou em formato XML. 

A configuração do MySQL é rápida e o usuário terá apenas permissão de leitura. Lembrando que por motivos óbvios de segurança, devemos liberar o acesso apenas para localhost ou para o IP do servidor que se conectará e fará os backups. 

```mysql> GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, RELOAD, SUPER, FILE ON *.* TO backup@localhost IDENTIFIED BY 'SUASENHA';``` 

Com o shell e o MySQL prontos para fazer o backup, vamos ao próximo passo, que é o Dropbox! 

### Dropbox

Eu tenho certeza que você usa, usou ou já ouviu falar do Dropbox. Além de ser uma excelente ferramenta de armazenamento, nós podemos compartilhar dados com outras pessoas. É possível trabalhar via Shell Script, Node.js, Python etc, sem falar no preço que é muito bom. A forma com que vamos trabalhar com o Dropbox aqui será um pouco diferente da que você está acostumado. 

Acesse a área de developers do Dropbox e clique em "My apps". Será solicitado o seu login, basta autenticar ou criar uma nova conta. Agora logado em seu painel, você deve ir em "Create app".

A minha configuração ficou com o Dropbox API que é a versão free, na segunda opção liberei o acesso apenas ao diretório que será criado para o nosso app (App Folder) e a terceira opção eu coloquei um nome para o meu app. Anote a sua App Key e App Secret. 

Agora vamos ao script.

### Os scripts

A API do Dropbox não é difícil de ser usada, a documentação é muito boa. É através da API que trabalharemos com o Dropbox para armazenar os nossos backups. Para nos comunicarmos com a API do Dropbox, iremos utilizar um shell criado pelo Andrea Fabrizi e que pode ser clonado do git do MySQL Box. Para baixar e instalar, siga os passos: 

```
cd /usr/local/bin
git clone https://github.com/mysqlbox/Dropbox-Uploader.git
cd Dropbox-Uploader
chmod +x dropbox_uploader.sh
./dropbox_uploader.sh
``` 

Executando o shell script, serão solicitadas algumas informações, preencha-as, acesse a URL com o token e aperte enter. 

```
./dropbox_uploader.sh
This is the first time you run this script.

1) Open the following URL in your Browser, and log in using your account: https://www.dropbox.com/developers/apps
2) Click on "Create App", then select "Dropbox API app"
3) Now go on with the configuration, choosing the app permissions and access restrictions to your DropBox folder
4) Enter the "App Name" that you prefer (e.g. MyUploader26630258426034)

Now, click on the "Create App" button.
When your new App is successfully created, please type the
App Key, App Secret and the Permission type shown in the confirmation page:

App key: SUAAPPKEY
App secret: SUAAPPSECRET

Permission type:
App folder [a]: If you choose that the app only needs access to files it creates
Full Dropbox [f]: If you choose that the app needs access to files already on Dropbox

Permission type [a/f]: a

> App key is SUAAPPKEY, App secret is SUAAPPSECRET and Access level is App Folder. Looks ok? [y/n]: y

> Token request... OK

Please open the following URL in your browser, and allow Dropbox Uploader
to access your DropBox folder:

--> https://www.dropbox.com/1/oauth/authorize?oauth_token=TOKEN

Press enter when done...

> Access Token request... OK

Setup completed! 

Com o Dropbox-Uploader configurado, vamos criar o script que fará o dump dos seus bancos de dados. Este script também está no repositório do GituHub. 

cd /usr/local/bin
git clone https://github.com/mysqlbox/MySQL-Backup.git
chmod 700 MySQL-Backup/Backup_MySQL.sh 
```

Dentro do arquivo Shell, você deve colocar o usuário e senha do seu usuário de backup. Lembrando que este usuário não pode ter privilégios de administrador ou de escrita, apenas leitura. 

```
USER="" #Usuario do backup
SECRET="" #Senha do usuario
```

### Agendamento e log

Após a configuração do script, basta adicionar uma rotina no cron. Para quem não conhece, o cron é um sistema de agendamento de tarefas do Linux. É nele que você configurará as rotinas do backup ou execução de algum script shell, perl, python, php etc. Sua utilização e sintaxe são bem simples, fáceis de decorar e usar. 

```crontab -e ```

Sintaxe do cron:

    * * * * * /usr/local/bin/MySQL-Backup/Backup_MySQL.sh
    | | | | | |
    | | | | | +----- Comando a ser executado
    | | | | +------- Dia da semana (0 - 7) (0 ou 8 é domingo)
    | | | +--------- Mês (1 - 12)
    | | +----------- Dia do mês (1 - 31)
    | +------------- Hora (0 - 23)
    +--------------- Minuto (0 - 59)

Com o comando crontab -e você abrirá o terminal de edição, basta apertar "insert" ou "i", inserir a rotina desejada, salvar o arquivo apertando "ESC" ":wq!" (igual ao vi ou vim) e reiniciar o serviço com o systemctl restart crond. 

```00 01 * * * /usr/local/bin/MySQL-Backup/Backup_MySQL.sh```

Fique atento aos logs do MySQL-Backup que estão armazenados em ```/var/log/mysql-backup.log```. 

Caso queira ter um controle destes logs, para que não ocupem espaço em disco sem necessidade, você pode utilizar o logrotate. O logrotate é uma ferramenta que faz o rotacionamento de logs no Linux. Com ele você consegue limitar o tamanho dos logs, manter logs por dias específicos, compactar e outras diversas opções. Para efetuar esta configuração, edite o arquivo ```/etc/logrotate.conf``` e adicione no final do arquivo: 
```
    /var/log/mysql-backup.log {
            daily                   #Cria um log por dia
            create 0600 root root   #Permissão do arquivo de log que ficará
            rotate 4                #Quantos logs serão mantidos
    }
```

Tutorial disponível em: https://www.mysqlbox.com.br/backup-mysql-api-dropbox/
