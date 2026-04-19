# Nền tảng client-server

[i[Client/Server]<]

Thế giới này là thế giới client-server, cưng ơi. Gần như mọi thứ trên
mạng đều xoay quanh các tiến trình client nói chuyện với các tiến
trình server và ngược lại. Ví dụ như `telnet`. Khi bạn kết nối tới một
host từ xa trên port 23 bằng telnet (client), một chương trình trên
host đó (tên `telnetd`, server) bật dậy. Nó xử lý kết nối telnet tới,
dựng cho bạn một prompt đăng nhập, vân vân.

![Tương tác client-server.](cs.pdf "[Client-Server Interaction Diagram]")

Việc trao đổi thông tin giữa client và server được tóm tắt trong sơ đồ
ở trên.

Lưu ý cặp client-server có thể nói `SOCK_STREAM`, `SOCK_DGRAM`, hoặc
bất cứ thứ gì khác (miễn là cùng nói một thứ). Vài cặp client-server
hay gặp: `telnet`/`telnetd`, `ftp`/`ftpd`, hay `Firefox`/`Apache`. Mỗi
lần bạn dùng `ftp`, có một chương trình từ xa tên `ftpd` đang phục vụ
bạn.

Thường thì, một máy sẽ chỉ có một server, và server đó xử lý nhiều
client bằng [i[`fork()` function]] `fork()`. Quy trình cơ bản là:
server chờ một kết nối, `accept()` nó, và `fork()` một tiến trình con
để xử lý. Đó là điều server mẫu của chúng ta làm trong phần kế tiếp.


## Server stream đơn giản

[i[Server-->stream]<]

Tất cả những gì server này làm là gửi chuỗi "`Hello, world!`" đi qua
một kết nối stream. Bạn chỉ cần chạy nó ở một cửa sổ, rồi telnet vào
từ cửa sổ khác bằng:

```
$ telnet remotehostname 3490
```

trong đó `remotehostname` là tên máy bạn đang chạy server.

[flx[Code server|server.c]]:

```{.c .numberLines}
/*
** server.c -- a stream socket server demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>

#define PORT "3490"  // the port users will be connecting to

#define BACKLOG 10   // how many pending connections queue will hold

void sigchld_handler(int s)
{
    (void)s; // quiet unused variable warning

    // waitpid() might overwrite errno, so we save and restore it:
    int saved_errno = errno;

    while(waitpid(-1, NULL, WNOHANG) > 0);

    errno = saved_errno;
}


// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(void)
{
    // listen on sock_fd, new connection on new_fd
    int sockfd, new_fd;
    struct addrinfo hints, *servinfo, *p;
    struct sockaddr_storage their_addr; // connector's address info
    socklen_t sin_size;
    struct sigaction sa;
    int yes=1;
    char s[INET6_ADDRSTRLEN];
    int rv;

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE; // use my IP

    if ((rv = getaddrinfo(NULL, PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and bind to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("server: socket");
            continue;
        }

        if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes,
                sizeof(int)) == -1) {
            perror("setsockopt");
            exit(1);
        }

        if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("server: bind");
            continue;
        }

        break;
    }

    freeaddrinfo(servinfo); // all done with this structure

    if (p == NULL)  {
        fprintf(stderr, "server: failed to bind\n");
        exit(1);
    }

    if (listen(sockfd, BACKLOG) == -1) {
        perror("listen");
        exit(1);
    }

    sa.sa_handler = sigchld_handler; // reap all dead processes
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        exit(1);
    }

    printf("server: waiting for connections...\n");

    while(1) {  // main accept() loop
        sin_size = sizeof their_addr;
        new_fd = accept(sockfd, (struct sockaddr *)&their_addr,
            &sin_size);
        if (new_fd == -1) {
            perror("accept");
            continue;
        }

        inet_ntop(their_addr.ss_family,
            get_in_addr((struct sockaddr *)&their_addr),
            s, sizeof s);
        printf("server: got connection from %s\n", s);

        if (!fork()) { // this is the child process
            close(sockfd); // child doesn't need the listener
            if (send(new_fd, "Hello, world!", 13, 0) == -1)
                perror("send");
            close(new_fd);
            exit(0);
        }
        close(new_fd);  // parent doesn't need this
    }

    return 0;
}
```

Nếu bạn tò mò, tôi để code trong một hàm `main()` to (theo tôi cảm
thấy) cho rõ mặt cú pháp. Bạn cứ tự nhiên tách ra thành các hàm nhỏ
hơn nếu thấy dễ chịu hơn.

(Cả cái chuyện [i[`sigaction()` function]] `sigaction()` này có thể mới
với bạn, không sao. Đoạn code ở đó chịu trách nhiệm dọn dẹp các
[i[Zombie process]] tiến trình zombie xuất hiện khi các tiến trình con
đã `fork()` thoát ra. Nếu bạn đẻ ra cả đống zombie mà không dọn, ông
quản trị hệ thống của bạn sẽ nhảy dựng lên.)

Bạn có thể lấy dữ liệu từ server này bằng client liệt kê ở phần tiếp
theo.

[i[Server-->stream]>]

## Client stream đơn giản

[i[Client-->stream]<]

Cậu này còn dễ hơn cả server. Tất cả những gì client này làm là kết
nối tới host bạn ghi ở dòng lệnh, port 3490. Nó nhận chuỗi server gửi
đi.

[flx[Source client|client.c]]:

```{.c .numberLines}
/*
** client.c -- a stream socket client demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <arpa/inet.h>

#define PORT "3490" // the port client will be connecting to 

#define MAXDATASIZE 100 // max number of bytes we can get at once 

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(int argc, char *argv[])
{
    int sockfd, numbytes;  
    char buf[MAXDATASIZE];
    struct addrinfo hints, *servinfo, *p;
    int rv;
    char s[INET6_ADDRSTRLEN];

    if (argc != 2) {
        fprintf(stderr,"usage: client hostname\n");
        exit(1);
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    if ((rv = getaddrinfo(argv[1], PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and connect to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("client: socket");
            continue;
        }

        inet_ntop(p->ai_family,
            get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
        printf("client: attempting connection to %s\n", s);

        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            perror("client: connect");
            close(sockfd);
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return 2;
    }

    inet_ntop(p->ai_family,
            get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
    printf("client: connected to %s\n", s);

    freeaddrinfo(servinfo); // all done with this structure

    if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1) {
        perror("recv");
        exit(1);
    }

    buf[numbytes] = '\0';

    printf("client: received '%s'\n",buf);

    close(sockfd);

    return 0;
}
```

Để ý nếu bạn không chạy server trước khi chạy client, `connect()` trả
về [i[Connection refused]] "Connection refused". Rất hữu ích.

[i[Client-->stream]>]

## Datagram socket {#datagram}

[i[Server-->datagram]<]

Ta đã đi qua cơ bản của UDP datagram socket ở phần thảo luận về
`sendto()` và `recvfrom()` phía trên, nên tôi chỉ giới thiệu vài chương
trình mẫu: `talker.c` và `listener.c`.

`listener` ngồi trên một máy chờ gói tin tới ở port 4950. `talker` gửi
một gói tới port đó, trên máy được chỉ định, chứa bất cứ thứ gì người
dùng gõ ở dòng lệnh.

Vì datagram socket không có kết nối và chỉ bắn gói tin ra không trung
với thái độ thờ ơ về chuyện có đến nơi không, ta sẽ bảo client và
server dùng cụ thể IPv6. Như vậy ta tránh được tình huống server lắng
nghe trên IPv6 còn client gửi bằng IPv4; dữ liệu đơn giản sẽ không
được nhận. (Ở thế giới TCP stream socket có kết nối, lệch kiểu này vẫn
có thể xảy ra, nhưng lỗi `connect()` cho một address family sẽ khiến
ta thử lại cái kia.)

Đây là [flx[source của `listener.c`|listener.c]]:

```{.c .numberLines}
/*
** listener.c -- a datagram sockets "server" demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define MYPORT "4950"    // the port users will be connecting to

#define MAXBUFLEN 100

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(void)
{
    int sockfd;
    struct addrinfo hints, *servinfo, *p;
    int rv;
    int numbytes;
    struct sockaddr_storage their_addr;
    char buf[MAXBUFLEN];
    socklen_t addr_len;
    char s[INET6_ADDRSTRLEN];

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET6; // or set to AF_INET to use IPv4
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags = AI_PASSIVE; // use my IP

    if ((rv = getaddrinfo(NULL, MYPORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and bind to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("listener: socket");
            continue;
        }

        if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("listener: bind");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "listener: failed to bind socket\n");
        return 2;
    }

    freeaddrinfo(servinfo);

    printf("listener: waiting to recvfrom...\n");

    addr_len = sizeof their_addr;
    if ((numbytes = recvfrom(sockfd, buf, MAXBUFLEN-1 , 0,
        (struct sockaddr *)&their_addr, &addr_len)) == -1) {
        perror("recvfrom");
        exit(1);
    }

    printf("listener: got packet from %s\n",
        inet_ntop(their_addr.ss_family,
            get_in_addr((struct sockaddr *)&their_addr),
            s, sizeof s));
    printf("listener: packet is %d bytes long\n", numbytes);
    buf[numbytes] = '\0';
    printf("listener: packet contains \"%s\"\n", buf);

    close(sockfd);

    return 0;
}
```

Để ý trong cú gọi `getaddrinfo()` cuối cùng ta dùng `SOCK_DGRAM`.
Cũng lưu ý không cần `listen()` hay `accept()`. Đây là một cái thú vị
của datagram socket chưa connect!

[i[Server-->datagram]>]

[i[Client-->datagram]<]

Tiếp theo là [flx[source của `talker.c`|talker.c]]:

```{.c .numberLines}
/*
** talker.c -- a datagram "client" demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define SERVERPORT "4950"   // the port users will be connecting to

int main(int argc, char *argv[])
{
    int sockfd;
    struct addrinfo hints, *servinfo, *p;
    int rv;
    int numbytes;

    if (argc != 3) {
        fprintf(stderr,"usage: talker hostname message\n");
        exit(1);
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET6; // set to AF_INET to use IPv4
    hints.ai_socktype = SOCK_DGRAM;

    rv = getaddrinfo(argv[1], SERVERPORT, &hints, &servinfo);
    if (rv != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and make a socket
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("talker: socket");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "talker: failed to create socket\n");
        return 2;
    }

    if ((numbytes = sendto(sockfd, argv[2], strlen(argv[2]), 0,
             p->ai_addr, p->ai_addrlen)) == -1) {
        perror("talker: sendto");
        exit(1);
    }

    freeaddrinfo(servinfo);

    printf("talker: sent %d bytes to %s\n", numbytes, argv[1]);
    close(sockfd);

    return 0;
}
```

Và bấy nhiêu thôi! Chạy `listener` trên một máy, rồi chạy `talker`
trên một máy khác. Xem chúng nói chuyện với nhau! Niềm vui lành mạnh
cho cả nhà!

Bạn còn chả cần chạy server lần này! Bạn có thể chạy `talker` một
mình, và nó vui vẻ bắn gói tin ra không trung, chúng biến mất nếu đầu
kia không có ai sẵn `recvfrom()` chờ. Nhớ nhé: dữ liệu gửi qua UDP
datagram socket không đảm bảo tới nơi!

[i[Client-->datagram]>]

Trừ một chi tiết nhỏ mà tôi đã nhắc nhiều lần ở trên:
[i[`connect()` function-->on datagram sockets]] datagram socket đã
connect. Tôi cần nói ở đây, vì ta đang ở phần datagram của tài liệu.
Giả sử `talker` gọi `connect()` và chỉ định địa chỉ của `listener`. Từ
lúc đó, `talker` chỉ có thể gửi tới và nhận từ địa chỉ được `connect()`
chỉ định. Vì lý do đó, bạn không cần dùng `sendto()` và `recvfrom()`,
cứ dùng `send()` và `recv()` cho xong.

[i[Client/Server]>]
