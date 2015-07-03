def do_telnet(host, username, commands):
    import telnetlib
    # connect to ftp
    tn = telnetlib.Telnet(host)
    tn.set_debuglevel(2)
     
    # login
    ret = tn.read_until('login: ', 5)

    if ret.find('login: ') > -1:
        tn.write(username + '\n')
        tn.read_until('# ')
        tn.write('cd /\n')
        tn.read_until('# ')
    
    tn.write('ls\n')
    
    for cmd in commands:
        tn.read_until('# ')
        tn.write('%s\n' % cmd)
        
    # exit
    tn.read_until('# ')
    tn.close() # tn.write('exit\n')

if __name__=='__main__':
    Host = '192.168.42.1'
    Username = 'root'
    Commands = ['cd /tmp/fuse_d','ls']
    do_telnet(Host, Username, Commands)
