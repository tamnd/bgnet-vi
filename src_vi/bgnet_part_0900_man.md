# Man Pages

[i[man pages]<]

Trong thế giới Unix, có một đống sách hướng dẫn. Chúng có những phần
nhỏ mô tả từng hàm riêng lẻ mà bạn có sẵn để dùng.

Dĩ nhiên, "manual" sẽ là từ quá dài để gõ. Ý tôi là, không ai trong
thế giới Unix, kể cả tôi, thích gõ nhiều đến thế. Thật ra tôi có thể
nói dài tràng giang đại hải về chuyện tôi thích ngắn gọn đến mức nào,
nhưng thay vào đó tôi sẽ ngắn gọn và không làm bạn chán với những bài
diễn văn lê thê về chuyện tôi cực kỳ kinh ngạc ưa chuộng sự ngắn gọn
đến cỡ nào trong hầu hết mọi hoàn cảnh ở tính tổng thể trọn vẹn của
chúng.

_[Tiếng vỗ tay]_

Cảm ơn. Ý tôi muốn nói là, các trang này được gọi là "man page" trong
thế giới Unix, và tôi đã đưa vào đây biến thể cắt gọn của riêng tôi để
bạn đọc thư giãn. Vấn đề là, nhiều trong số các hàm này tổng quát hơn
nhiều so với tôi tiết lộ, nhưng tôi chỉ sẽ trình bày các phần liên
quan đến Lập Trình Socket Internet.

Nhưng khoan! Đó chưa phải là tất cả những gì sai với man page của
tôi:

* Chúng không đầy đủ và chỉ trình bày phần căn bản từ hướng dẫn.
* Có rất nhiều man page khác ngoài đời thực hơn cái này.
* Chúng khác với những cái trên hệ thống của bạn.
* Các file header có thể khác cho một số hàm nhất định trên hệ thống
  của bạn.
* Tham số hàm có thể khác cho một số hàm nhất định trên hệ thống của
  bạn.

Nếu bạn muốn thông tin thật, kiểm tra man page Unix cục bộ của bạn
bằng cách gõ `man gì_đó`, trong đó "gì_đó" là thứ bạn cực kỳ quan tâm
tới, ví dụ "`accept`". (Tôi chắc Microsoft Visual Studio có thứ gì đó
tương tự trong phần help của họ. Nhưng "man" tốt hơn vì nó ngắn gọn
hơn "help" một byte. Unix lại thắng!)

Vậy, nếu chúng thiếu sót như thế, tại sao lại đưa chúng vào Hướng
Dẫn? Có vài lý do, nhưng lý do tốt nhất là (a) những phiên bản này
được nhắm cụ thể vào lập trình mạng và dễ tiêu hóa hơn bản thật, và
(b) những phiên bản này có ví dụ!

À! Và nói về ví dụ, tôi có xu hướng không đưa tất cả phần kiểm tra
lỗi vào vì nó thật sự làm tăng độ dài của code. Nhưng bạn tuyệt đối
nên kiểm tra lỗi gần như mỗi khi bạn gọi bất kỳ system call nào trừ
khi bạn hoàn toàn 100% chắc chắn nó sẽ không thất bại, và có lẽ bạn
vẫn nên làm vậy kể cả khi đó!

[i[man pages]>]

[[manbreak]]
## `accept()` {#acceptman}

[i[`accept()` function]i]

Nhận một kết nối đi tới trên socket đang lắng nghe

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int accept(int s, struct sockaddr *addr, socklen_t *addrlen);
```

### Description {.unnumbered .unlisted}

Khi bạn đã mất công lấy một socket `SOCK_STREAM` và cấu hình nó để
nhận kết nối đi tới với `listen()`, rồi bạn gọi `accept()` để thực
sự có được một socket descriptor mới dùng cho các giao tiếp tiếp
theo với client vừa kết nối.

Socket cũ mà bạn đang dùng để lắng nghe vẫn còn đó, và sẽ được dùng
cho các lời gọi `accept()` tiếp theo khi chúng đến.

| Tham số   | Mô tả                                                     |
|-----------|-----------------------------------------------------------|
| `s`       | Socket descriptor đang `listen()`.                        | 
| `addr`    | Cái này được điền địa chỉ của bên đang kết nối tới bạn.  |
| `addrlen` | Cái này được điền `sizeof()` của struct trả về trong tham số `addr`. Bạn có thể yên tâm bỏ qua nó nếu bạn giả sử mình nhận được một `struct sockaddr_in`, điều mà bạn biết vì đó là kiểu bạn đã truyền vào cho `addr`.|

`accept()` thường sẽ block, và bạn có thể dùng `select()` để dòm
socket descriptor đang lắng nghe trước để xem nó có "sẵn sàng đọc"
không. Nếu có, thì có một kết nối mới đang đợi được `accept()`! Yay!
Hoặc, bạn có thể đặt cờ [i[`O_NONBLOCK` macro]] `O_NONBLOCK` trên
socket đang lắng nghe bằng [i[`fcntl()` function]] `fcntl()`, và
khi đó nó sẽ không bao giờ block, thay vào đó nó chọn trả về `-1`
với `errno` được gán thành `EWOULDBLOCK`.

Socket descriptor do `accept()` trả về là một socket descriptor
thực thụ, đang mở và đang kết nối tới host remote. Bạn phải
`close()` nó khi dùng xong.

### Return Value {.unnumbered .unlisted}

`accept()` trả về socket descriptor vừa kết nối, hoặc `-1` nếu lỗi,
với `errno` được gán phù hợp.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
struct sockaddr_storage their_addr;
socklen_t addr_size;
struct addrinfo hints, *res;
int sockfd, new_fd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_STREAM;
hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

getaddrinfo(NULL, MYPORT, &hints, &res);

// make a socket, bind it, and listen on it:

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
bind(sockfd, res->ai_addr, res->ai_addrlen);
listen(sockfd, BACKLOG);

// now accept an incoming connection:

addr_size = sizeof their_addr;
new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &addr_size);

// ready to communicate on socket descriptor new_fd!
```

### See Also {.unnumbered .unlisted}

[`socket()`](#socketman), [`getaddrinfo()`](#getaddrinfoman),
[`listen()`](#listenman), [`struct sockaddr_in`](#structsockaddrman)


[[manbreak]]
## `bind()` {#bindman}

[i[`bind()` function]i]

Gắn socket với một địa chỉ IP và số port

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int bind(int sockfd, struct sockaddr *my_addr, socklen_t addrlen);
```

### Description {.unnumbered .unlisted}

Khi một máy remote muốn kết nối tới chương trình server của bạn, nó
cần hai mẩu thông tin: địa chỉ IP và số port. Lời gọi `bind()` cho
phép bạn làm đúng chuyện đó.

Đầu tiên, bạn gọi `getaddrinfo()` để nạp một `struct sockaddr` với
thông tin địa chỉ đích và port. Rồi bạn gọi `socket()` để có một
socket descriptor, rồi bạn truyền socket và địa chỉ vào `bind()`, và
địa chỉ IP cùng port được gắn vào socket một cách thần kỳ (dùng phép
thuật thật sự)!

Nếu bạn không biết địa chỉ IP của mình, hoặc bạn biết mình chỉ có
một địa chỉ IP trên máy, hoặc bạn không quan tâm địa chỉ IP nào của
máy được dùng, bạn có thể chỉ cần truyền cờ `AI_PASSIVE` vào tham số
`hints` của `getaddrinfo()`. Cái này làm gì? Nó điền phần địa chỉ IP
của `struct sockaddr` bằng một giá trị đặc biệt báo cho `bind()`
biết rằng nó nên tự động điền địa chỉ IP của host này.

Cái gì cái gì? Giá trị đặc biệt nào được nạp vào địa chỉ IP của
`struct sockaddr` để làm nó tự động điền địa chỉ bằng host hiện tại?
Tôi sẽ nói cho bạn biết, nhưng nhớ là chuyện này chỉ khi bạn đang
điền `struct sockaddr` bằng tay; nếu không, dùng kết quả từ
`getaddrinfo()`, như trên. Ở IPv4, trường `sin_addr.s_addr` của
struct `sockaddr_in` được gán thành `INADDR_ANY`. Ở IPv6, trường
`sin6_addr` của struct `sockaddr_in6` được gán từ biến toàn cục
`in6addr_any`. Hoặc, nếu bạn đang khai báo một `struct in6_addr`
mới, bạn có thể khởi tạo nó bằng `IN6ADDR_ANY_INIT`.

Cuối cùng, tham số `addrlen` nên được gán bằng `sizeof my_addr`.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// modern way of doing things with getaddrinfo()

struct addrinfo hints, *res;
int sockfd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_STREAM;
hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

getaddrinfo(NULL, "3490", &hints, &res);

// make a socket:
// (you should actually walk the "res" linked list and error-check!)

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// bind it to the port we passed in to getaddrinfo():

bind(sockfd, res->ai_addr, res->ai_addrlen);
```

```{.c .numberLines}
// example of packing a struct by hand, IPv4

struct sockaddr_in myaddr;
int s;

myaddr.sin_family = AF_INET;
myaddr.sin_port = htons(3490);

// you can specify an IP address:
inet_pton(AF_INET, "63.161.169.137", &(myaddr.sin_addr));

// or you can let it automatically select one:
myaddr.sin_addr.s_addr = INADDR_ANY;

s = socket(PF_INET, SOCK_STREAM, 0);
bind(s, (struct sockaddr*)&myaddr, sizeof myaddr);
```

### See Also {.unnumbered .unlisted}

[`getaddrinfo()`](#getaddrinfoman), [`socket()`](#socketman), [`struct
sockaddr_in`](#structsockaddrman), [`struct in_addr`](#structsockaddrman)


[[manbreak]]
## `connect()` {#connectman}

[i[`connect()` function]i]

Kết nối một socket tới server

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int connect(int sockfd, const struct sockaddr *serv_addr,
            socklen_t addrlen);
```

### Description {.unnumbered .unlisted}

Khi đã dựng được một socket descriptor bằng lời gọi `socket()`, bạn
có thể `connect()` socket đó tới một server remote bằng system call
tên gọi rất đúng bản chất là `connect()`. Tất cả những gì bạn cần
làm là truyền cho nó socket descriptor và địa chỉ của server bạn
muốn làm quen. (À, và độ dài của địa chỉ, thứ thường được truyền
cho các hàm kiểu này.)

Thông thường thông tin này đi kèm như kết quả của lời gọi
`getaddrinfo()`, nhưng bạn có thể tự điền `struct sockaddr` của
mình nếu muốn.

Nếu bạn chưa gọi `bind()` trên socket descriptor, nó sẽ tự động
được bind vào địa chỉ IP của bạn và một port local ngẫu nhiên.
Chuyện này thường ổn với bạn nếu bạn không phải server, vì bạn
không thực sự quan tâm port local của mình là gì; bạn chỉ quan tâm
port remote là gì để có thể đặt nó vào tham số `serv_addr`. Bạn
_có thể_ gọi `bind()` nếu bạn thực sự muốn socket client của mình
nằm trên một địa chỉ IP và port cụ thể, nhưng chuyện này khá hiếm.

Khi socket đã `connect()`, bạn tự do `send()` và `recv()` dữ liệu
trên nó tùy ý.

[i[`connect()`-->on datagram sockets]] Ghi chú đặc biệt: nếu bạn
`connect()` một socket UDP `SOCK_DGRAM` tới một host remote, bạn
có thể dùng `send()` và `recv()` cũng như `sendto()` và
`recvfrom()`. Nếu bạn muốn.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// connect to www.example.com port 80 (http)

struct addrinfo hints, *res;
int sockfd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_STREAM;

// we could put "80" instead on "http" on the next line:
getaddrinfo("www.example.com", "http", &hints, &res);

// make a socket:

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// connect it to the address and port we passed in to getaddrinfo():

connect(sockfd, res->ai_addr, res->ai_addrlen);
```

### See Also {.unnumbered .unlisted}

[`socket()`](#socketman), [`bind()`](#bindman)


[[manbreak]]
## `close()` {#closeman}

[i[`close()` function]i]

Đóng một socket descriptor

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <unistd.h>

int close(int s);
```

### Description {.unnumbered .unlisted}

Sau khi bạn đã dùng xong socket cho bất kỳ âm mưu điên rồ nào bạn
đã bày ra và bạn không muốn `send()` hay `recv()` hay, nói thẳng,
làm _bất cứ gì khác_ với socket này, bạn có thể `close()` nó, và
nó sẽ được giải phóng, không bao giờ dùng lại nữa.

Đầu bên kia có thể biết chuyện này xảy ra bằng một trong hai cách.
Một: nếu đầu bên kia gọi `recv()`, nó sẽ trả về `0`. Hai: nếu đầu
bên kia gọi `send()`, nó sẽ nhận signal [i[`SIGPIPE` macro]]
`SIGPIPE` và send() sẽ trả về `-1` và `errno` sẽ được gán thành
[i[`EPIPE` macro]] `EPIPE`.

[i[Windows]] **Người dùng Windows**: hàm bạn cần dùng tên là
[i[`closesocket()` function]i] `closesocket()`, không phải
`close()`. Nếu bạn thử dùng `close()` trên socket descriptor, có
thể Windows sẽ nổi giận... Và bạn sẽ không thích nó khi nó nổi
giận đâu.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
s = socket(PF_INET, SOCK_DGRAM, 0);
.
.
.
// a whole lotta stuff...*BRRRONNNN!*
.
.
.
close(s);  // not much to it, really.
```

### See Also {.unnumbered .unlisted}

[`socket()`](#socketman), [`shutdown()`](#shutdownman)


[[manbreak]]
## `getaddrinfo()`, `freeaddrinfo()`, `gai_strerror()` {#getaddrinfoman}

[i[`getaddrinfo()` function]i]
[i[`freeaddrinfo()` function]i]
[i[`gai_strerror()` function]i]

Lấy thông tin về một tên host và/hoặc service, rồi nạp một `struct
sockaddr` với kết quả.

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *nodename, const char *servname,
                const struct addrinfo *hints,
                struct addrinfo **res);

void freeaddrinfo(struct addrinfo *ai);

const char *gai_strerror(int ecode);

struct addrinfo {
  int     ai_flags;          // AI_PASSIVE, AI_CANONNAME, ...
  int     ai_family;         // AF_xxx
  int     ai_socktype;       // SOCK_xxx
  int     ai_protocol;       // 0 (auto) or IPPROTO_TCP, IPPROTO_UDP 

  socklen_t  ai_addrlen;     // length of ai_addr
  char   *ai_canonname;      // canonical name for nodename
  struct sockaddr  *ai_addr; // binary address
  struct addrinfo  *ai_next; // next structure in linked list
};
```

### Description {.unnumbered .unlisted}

`getaddrinfo()` là một hàm xuất sắc sẽ trả về thông tin về một tên
host cụ thể (như địa chỉ IP của nó) và nạp một `struct sockaddr`
cho bạn, lo hết các chi tiết lỉnh kỉnh (như IPv4 hay IPv6). Nó thay
thế các hàm cũ `gethostbyname()` và `getservbyname()`. Mô tả ở dưới
có một đống thông tin có thể hơi ngợp, nhưng cách dùng thực tế khá
đơn giản. Có thể đáng xem ví dụ trước.

Tên host mà bạn quan tâm đặt vào tham số `nodename`. Địa chỉ có
thể là một tên host, như "www.example.com", hoặc một địa chỉ IPv4
hay IPv6 (truyền vào dạng chuỗi). Tham số này cũng có thể là `NULL`
nếu bạn đang dùng cờ `AI_PASSIVE` (xem bên dưới).

Tham số `servname` về cơ bản là số port. Nó có thể là một số port
(truyền vào dạng chuỗi, như "80"), hoặc nó có thể là tên service,
như "http", "tftp", "smtp", "pop", vân vân. Tên service nổi tiếng
có thể tìm thấy trong [fl[IANA Port
List|https://www.iana.org/assignments/port-numbers]] hoặc trong
file `/etc/services` của bạn.

Cuối cùng, cho các tham số đầu vào, chúng ta có `hints`. Đây thật
sự là nơi bạn định nghĩa những gì hàm `getaddrinfo()` sẽ làm. Xóa
toàn bộ struct về không trước khi dùng bằng `memset()`. Hãy xem
qua các trường bạn cần cấu hình trước khi dùng.

`ai_flags` có thể được gán thành nhiều thứ, nhưng đây là vài cái
quan trọng. (Có thể chỉ định nhiều cờ bằng cách OR bitwise chúng
lại với toán tử `|`.) Kiểm tra man page của bạn để có danh sách cờ
đầy đủ.

`AI_CANONNAME` làm cho `ai_canonname` của kết quả được điền bằng
tên canonical (thật) của host. `AI_PASSIVE` làm cho địa chỉ IP của
kết quả được điền bằng `INADDR_ANY` (IPv4) hoặc `in6addr_any`
(IPv6); điều này khiến lời gọi `bind()` tiếp theo tự động điền địa
chỉ IP của `struct sockaddr` bằng địa chỉ của host hiện tại. Tuyệt
vời cho việc dựng server khi bạn không muốn hardcode địa chỉ.

Nếu bạn có dùng cờ `AI_PASSIVE`, thì bạn có thể truyền `NULL` vào
`nodename` (vì sau đó `bind()` sẽ điền nó cho bạn).

Tiếp tục với các tham số đầu vào, có lẽ bạn sẽ muốn gán `ai_family`
thành `AF_UNSPEC`, báo cho `getaddrinfo()` tìm cả địa chỉ IPv4 lẫn
IPv6. Bạn cũng có thể tự giới hạn mình ở một trong hai bằng
`AF_INET` hoặc `AF_INET6`.

Kế tiếp, trường `socktype` nên được gán thành `SOCK_STREAM` hoặc
`SOCK_DGRAM`, tùy vào loại socket bạn muốn.

Cuối cùng, cứ để `ai_protocol` ở `0` để tự động chọn kiểu protocol
của bạn.

Giờ, sau khi bạn đã có tất cả thứ đó, bạn có thể _cuối cùng_ gọi
`getaddrinfo()`!

Dĩ nhiên, đây là nơi vui bắt đầu. `res` giờ sẽ trỏ tới một linked
list của các `struct addrinfo`, và bạn có thể đi qua danh sách này
để lấy tất cả địa chỉ khớp với những gì bạn đã truyền vào qua
hints.

Giờ, có khả năng bạn sẽ có một vài địa chỉ không chạy được vì lý
do này hay lý do khác, nên cái man page Linux làm là lặp qua danh
sách gọi `socket()` và `connect()` (hoặc `bind()` nếu bạn đang
dựng server với cờ `AI_PASSIVE`) cho đến khi thành công.

Cuối cùng, khi bạn đã dùng xong linked list, bạn cần gọi
`freeaddrinfo()` để giải phóng bộ nhớ (nếu không nó sẽ bị rò rỉ,
và Một Số Người sẽ nổi giận).

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc khác không nếu lỗi. Nếu trả về
khác không, bạn có thể dùng hàm `gai_strerror()` để có phiên bản
in được của mã lỗi trong giá trị trả về.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// code for a client connecting to a server
// namely a stream socket to www.example.com on port 80 (http)
// either IPv4 or IPv6

int sockfd;  
struct addrinfo hints, *servinfo, *p;
int rv;

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC; // use AF_INET6 to force IPv6
hints.ai_socktype = SOCK_STREAM;

rv = getaddrinfo("www.example.com", "http", &hints, &servinfo);
if (rv != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
    exit(1);
}

// loop through all the results and connect to the first we can
for(p = servinfo; p != NULL; p = p->ai_next) {
    if ((sockfd = socket(p->ai_family, p->ai_socktype,
            p->ai_protocol)) == -1) {
        perror("socket");
        continue;
    }

    if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
        perror("connect");
        close(sockfd);
        continue;
    }

    break; // if we get here, we must have connected successfully
}

if (p == NULL) {
    // looped off the end of the list with no connection
    fprintf(stderr, "failed to connect\n");
    exit(2);
}

freeaddrinfo(servinfo); // all done with this structure
```

```{.c .numberLines}
// code for a server waiting for connections
// namely a stream socket on port 3490, on this host's IP
// either IPv4 or IPv6.

int sockfd;  
struct addrinfo hints, *servinfo, *p;
int rv;

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC; // use AF_INET6 to force IPv6
hints.ai_socktype = SOCK_STREAM;
hints.ai_flags = AI_PASSIVE; // use my IP address

if ((rv = getaddrinfo(NULL, "3490", &hints, &servinfo)) != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
    exit(1);
}

// loop through all the results and bind to the first we can
for(p = servinfo; p != NULL; p = p->ai_next) {
    if ((sockfd = socket(p->ai_family, p->ai_socktype,
            p->ai_protocol)) == -1) {
        perror("socket");
        continue;
    }

    if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
        close(sockfd);
        perror("bind");
        continue;
    }

    break; // if we get here, we must have connected successfully
}

if (p == NULL) {
    // looped off the end of the list with no successful bind
    fprintf(stderr, "failed to bind socket\n");
    exit(2);
}

freeaddrinfo(servinfo); // all done with this structure
```

### See Also {.unnumbered .unlisted}

[`gethostbyname()`](#gethostbynameman), [`getnameinfo()`](#getnameinfoman)


[[manbreak]]
## `gethostname()` {#gethostnameman}

[i[`gethostname()` function]i]

Trả về tên của hệ thống

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/unistd.h>

int gethostname(char *name, size_t len);
```

### Description {.unnumbered .unlisted}

Hệ thống của bạn có tên. Tất cả đều có. Cái này Unix hơn một chút
so với phần mạng chúng ta đã nói, nhưng nó vẫn có chỗ dùng.

Ví dụ, bạn có thể lấy tên host của mình, rồi gọi
[i[`gethostbyname()` function]] `gethostbyname()` để tìm ra địa chỉ
IP của mình.

Tham số `name` nên trỏ tới một buffer sẽ chứa tên host, và `len` là
kích thước của buffer đó tính theo byte. `gethostname()` sẽ không
ghi đè quá cuối buffer (nó có thể trả về lỗi, hoặc có thể chỉ ngưng
ghi), và nó sẽ thêm `NUL` kết thúc chuỗi nếu có chỗ trong buffer.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
char hostname[128];

gethostname(hostname, sizeof hostname);
printf("My hostname: %s\n", hostname);
```

### See Also {.unnumbered .unlisted}

[`gethostbyname()`](#gethostbynameman)


[[manbreak]]
## `gethostbyname()`, `gethostbyaddr()` {#gethostbynameman}

[i[`gethostbyname()` function]i]
[i[`gethostbyaddr()` function]i]

Lấy địa chỉ IP cho một hostname, hoặc ngược lại

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>
#include <netdb.h>

struct hostent *gethostbyname(const char *name); // DEPRECATED!
struct hostent *gethostbyaddr(const char *addr, int len, int type);
```

### Description {.unnumbered .unlisted}

_XIN LƯU Ý: hai hàm này đã được thay thế bởi `getaddrinfo()` và
`getnameinfo()`!_ Đặc biệt, `gethostbyname()` không chạy tốt với
IPv6.

Các hàm này ánh xạ qua lại giữa tên host và địa chỉ IP. Ví dụ, nếu
bạn có "www.example.com", bạn có thể dùng `gethostbyname()` để lấy
địa chỉ IP của nó và lưu vào một `struct in_addr`.

Ngược lại, nếu bạn có một `struct in_addr` hoặc một `struct
in6_addr`, bạn có thể dùng `gethostbyaddr()` để lấy hostname. Hàm
`gethostbyaddr()` _có_ tương thích IPv6, nhưng bạn nên dùng hàm mới
sáng bóng hơn là `getnameinfo()` thay thế.

(Nếu bạn có một chuỗi chứa địa chỉ IP ở dạng chấm-và-số mà bạn
muốn tra hostname, bạn sẽ dùng `getaddrinfo()` với cờ
`AI_CANONNAME` sẽ tốt hơn.)

`gethostbyname()` nhận một chuỗi như "www.yahoo.com", và trả về
một `struct hostent` chứa hàng đống thông tin, bao gồm địa chỉ IP.
(Thông tin khác là tên host chính thức, danh sách alias, kiểu địa
chỉ, độ dài của các địa chỉ, và danh sách địa chỉ, đó là struct đa
mục đích khá dễ dùng cho mục đích cụ thể của chúng ta một khi bạn
hiểu cách.)

`gethostbyaddr()` nhận một `struct in_addr` hoặc `struct in6_addr`
và đưa về cho bạn một tên host tương ứng (nếu có một), nên nó hơi
kiểu ngược lại của `gethostbyname()`. Về tham số, dù `addr` là
`char*`, thực chất bạn muốn truyền vào một con trỏ tới `struct
in_addr`. `len` nên là `sizeof(struct in_addr)`, và `type` nên là
`AF_INET`.

Vậy cái [i[`struct hostent` type]i] `struct hostent` được trả về
này là gì? Nó có một số trường chứa thông tin về host đang nói.

| Trường               | Mô tả                                              |
|----------------------|----------------------------------------------------|
| `char *h_name`       | Tên host canonical thật.                           |
| `char **h_aliases`   | Danh sách alias có thể truy cập bằng mảng, phần tử cuối là `NULL` |
| `int h_addrtype`     | Kiểu địa chỉ của kết quả, thật ra nên là `AF_INET` cho mục đích của chúng ta. |
| `int length`         | Độ dài của địa chỉ tính theo byte, là 4 cho địa chỉ IP (phiên bản 4). |
| `char **h_addr_list` | Danh sách địa chỉ IP cho host này. Mặc dù đây là `char**`, thật ra nó là mảng ngụy trang của các `struct in_addr*`. Phần tử cuối của mảng là `NULL`. |
| `h_addr`             | Một alias hay được định nghĩa cho `h_addr_list[0]`. Nếu bạn chỉ cần địa chỉ IP nào cũng được cho host này (đúng, host có thể có nhiều hơn một) chỉ cần dùng trường này. |

### Return Value {.unnumbered .unlisted}

Trả về một con trỏ tới `struct hostent` kết quả nếu thành công,
hoặc `NULL` nếu lỗi.

Thay vì `perror()` thông thường và mấy thứ bạn thường dùng để báo
lỗi, các hàm này có kết quả song song trong biến `h_errno`, có thể
in bằng các hàm [i[`herror()` function]i] `herror()` hoặc
[i[`hstrerror()` function]i] `hstrerror()`. Chúng hoạt động giống
các hàm `errno`, `perror()`, và `strerror()` cổ điển mà bạn đã
quen.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// THIS IS A DEPRECATED METHOD OF GETTING HOST NAMES
// use getaddrinfo() instead!

#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char *argv[])
{
    int i;
    struct hostent *he;
    struct in_addr **addr_list;

    if (argc != 2) {
        fprintf(stderr,"usage: ghbn hostname\n");
        return 1;
    }

    if ((he = gethostbyname(argv[1])) == NULL) {  // get host info
        herror("gethostbyname");
        return 2;
    }

    // print information about this host:
    printf("Official name is: %s\n", he->h_name);
    printf("    IP addresses: ");
    addr_list = (struct in_addr **)he->h_addr_list;
    for(i = 0; addr_list[i] != NULL; i++) {
        printf("%s ", inet_ntoa(*addr_list[i]));
    }
    printf("\n");

    return 0;
}
```

```{.c .numberLines}
// THIS HAS BEEN SUPERSEDED
// use getnameinfo() instead!

struct hostent *he;
struct in_addr ipv4addr;
struct in6_addr ipv6addr;

inet_pton(AF_INET, "192.0.2.34", &ipv4addr);
he = gethostbyaddr(&ipv4addr, sizeof ipv4addr, AF_INET);
printf("Host name: %s\n", he->h_name);

inet_pton(AF_INET6, "2001:db8:63b3:1::beef", &ipv6addr);
he = gethostbyaddr(&ipv6addr, sizeof ipv6addr, AF_INET6);
printf("Host name: %s\n", he->h_name);
```

### See Also {.unnumbered .unlisted}

[`getaddrinfo()`](#getaddrinfoman), [`getnameinfo()`](#getnameinfoman),
[`gethostname()`](#gethostnameman), [`errno`](#errnoman),
[`perror()`](#perrorman), [`strerror()`](#perrorman), [`struct
in_addr`](#structsockaddrman)


[[manbreak]]
## `getnameinfo()` {#getnameinfoman}

[i[`getnameinfo()` function]i]

Tra thông tin tên host và tên service cho một `struct sockaddr` đã
cho.

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>
#include <netdb.h>

int getnameinfo(const struct sockaddr *sa, socklen_t salen,
                char *host, size_t hostlen,
                char *serv, size_t servlen, int flags);
```

### Description {.unnumbered .unlisted}

Hàm này là ngược lại của `getaddrinfo()`, nghĩa là, hàm này nhận
một `struct sockaddr` đã được nạp và tra tên cùng tên service trên
đó. Nó thay thế các hàm cũ `gethostbyaddr()` và `getservbyport()`.

Bạn phải truyền vào một con trỏ tới `struct sockaddr` (thực chất
có thể là `struct sockaddr_in` hoặc `struct sockaddr_in6` đã được
cast) trong tham số `sa`, và độ dài của struct đó trong `salen`.

Tên host và tên service kết quả sẽ được ghi vào vùng được trỏ tới
bởi các tham số `host` và `serv`. Dĩ nhiên, bạn phải chỉ định độ
dài tối đa của các buffer này trong `hostlen` và `servlen`.

Cuối cùng, có vài cờ bạn có thể truyền, nhưng đây là vài cái hay.
`NI_NOFQDN` sẽ làm cho `host` chỉ chứa tên host, không phải tên
domain đầy đủ. `NI_NAMEREQD` sẽ làm hàm thất bại nếu không tìm
được tên qua DNS lookup (nếu bạn không chỉ định cờ này và không
tìm được tên, `getnameinfo()` sẽ đặt phiên bản chuỗi của địa chỉ
IP vào `host` thay thế).

Như mọi khi, kiểm tra man page cục bộ của bạn để có thông tin đầy
đủ.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc khác không nếu lỗi. Nếu giá trị
trả về khác không, nó có thể được truyền cho `gai_strerror()` để
có chuỗi dễ đọc. Xem `getaddrinfo` để biết thêm.

[[book-pagebreak]]

### Example {.unnumbered .unlisted}

```{.c .numberLines}
struct sockaddr_in6 sa; // could be IPv4 if you want
char host[1024];
char service[20];

// pretend sa is full of good information about the host and port...

getnameinfo(&sa, sizeof sa, host, sizeof host, service,
            sizeof service, 0);

printf("   host: %s\n", host);    // e.g. "www.example.com"
printf("service: %s\n", service); // e.g. "http"
```

### See Also {.unnumbered .unlisted}

[`getaddrinfo()`](#getaddrinfoman), [`gethostbyaddr()`](#gethostbynameman)


[[manbreak]]
## `getpeername()` {#getpeernameman}

[i[`getpeername()` function]i]

Trả về thông tin địa chỉ về đầu remote của kết nối

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>

int getpeername(int s, struct sockaddr *addr, socklen_t *len);
```

### Description {.unnumbered .unlisted}

Khi bạn đã `accept()` một kết nối remote, hoặc `connect()` tới một
server, bạn giờ có cái gọi là _peer_. Peer của bạn đơn giản là máy
tính bạn đang kết nối tới, được nhận diện bằng một địa chỉ IP và
một port. Vậy...

`getpeername()` đơn giản trả về một `struct sockaddr_in` được điền
thông tin về máy bạn đang kết nối tới.

Tại sao nó được gọi là "name"? Có nhiều loại socket khác nhau,
không chỉ Internet Socket như chúng ta đang dùng trong hướng dẫn
này, nên "name" là thuật ngữ tổng quát hay bao phủ mọi trường hợp.
Trong trường hợp của chúng ta, "name" của peer là địa chỉ IP và
port của nó.

Mặc dù hàm trả về kích thước của địa chỉ kết quả trong `len`, bạn
phải nạp sẵn `len` bằng kích thước của `addr`.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// assume s is a connected socket

socklen_t len;
struct sockaddr_storage addr;
char ipstr[INET6_ADDRSTRLEN];
int port;

len = sizeof addr;
getpeername(s, (struct sockaddr*)&addr, &len);

// deal with both IPv4 and IPv6:
if (addr.ss_family == AF_INET) {
    struct sockaddr_in *s = (struct sockaddr_in *)&addr;
    port = ntohs(s->sin_port);
    inet_ntop(AF_INET, &s->sin_addr, ipstr, sizeof ipstr);
} else { // AF_INET6
    struct sockaddr_in6 *s = (struct sockaddr_in6 *)&addr;
    port = ntohs(s->sin6_port);
    inet_ntop(AF_INET6, &s->sin6_addr, ipstr, sizeof ipstr);
}

printf("Peer IP address: %s\n", ipstr);
printf("Peer port      : %d\n", port);
```

### See Also {.unnumbered .unlisted}

[`gethostname()`](#gethostnameman), [`gethostbyname()`](#gethostbynameman),
[`gethostbyaddr()`](#gethostbynameman)


[[manbreak]]
## `errno` {#errnoman}

[i[`errno` variable]i]

Giữ mã lỗi cho system call vừa gọi

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <errno.h>

int errno;
```

### Description {.unnumbered .unlisted}

Đây là biến giữ thông tin lỗi cho nhiều system call. Nếu bạn còn
nhớ, những thứ như `socket()` và `listen()` trả về `-1` khi lỗi,
và chúng đặt giá trị cụ thể của `errno` để cho bạn biết lỗi nào đã
xảy ra.

File header `errno.h` liệt kê một đống tên ký hiệu hằng cho các
lỗi, như `EADDRINUSE`, `EPIPE`, `ECONNREFUSED`, vân vân. Man page
cục bộ của bạn sẽ cho bạn biết mã nào có thể được trả về như là
lỗi, và bạn có thể dùng chúng ở runtime để xử lý các lỗi khác nhau
theo cách khác nhau.

Hoặc, thường gặp hơn, bạn có thể gọi [i[`perror()` function]]
`perror()` hoặc [i[`strerror()` function]] `strerror()` để có
phiên bản dễ đọc của lỗi.

Một điều cần lưu ý, cho các fan đa luồng, là trên hầu hết hệ thống
`errno` được định nghĩa theo cách thread-safe. (Nghĩa là, nó không
thật sự là biến toàn cục, nhưng hành xử y như một biến toàn cục
trong môi trường đơn luồng.)

### Return Value {.unnumbered .unlisted}

Giá trị của biến là lỗi mới nhất đã xảy ra, có thể là mã cho
"thành công" nếu hành động vừa rồi thành công.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
s = socket(PF_INET, SOCK_STREAM, 0);
if (s == -1) {
    perror("socket"); // or use strerror()
}

tryagain:
if (select(n, &readfds, NULL, NULL) == -1) {
    // an error has occurred!!

    // if we were only interrupted, just restart the select() call:
    if (errno == EINTR) goto tryagain;  // AAAA! goto!!!

    // otherwise it's a more serious error:
    perror("select");
    exit(1);
}
```

### See Also {.unnumbered .unlisted}

[`perror()`](#perrorman), [`strerror()`](#perrorman)


[[manbreak]]
## `fcntl()` {#fcntlman}

[i[`fcntl()` function]i]

Điều khiển các socket descriptor

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/unistd.h>
#include <sys/fcntl.h>

int fcntl(int s, int cmd, long arg);
```

### Description {.unnumbered .unlisted}

Hàm này thường được dùng để làm file locking và các chuyện liên
quan đến file, nhưng nó cũng có vài chức năng liên quan đến socket
mà bạn có thể thấy hoặc dùng thỉnh thoảng.

Tham số `s` là socket descriptor bạn muốn thao tác, `cmd` nên được
gán thành [i[`F_SETFL` macro]i] `F_SETFL`, và `arg` có thể là một
trong các lệnh sau. (Như tôi đã nói, `fcntl()` còn nhiều hơn những
gì tôi đang tiết lộ ở đây, nhưng tôi đang cố giữ tập trung vào
socket.)

| `cmd`        | Mô tả                                                      |
|--------------|------------------------------------------------------------|
| [i[`O_NONBLOCK` macro]i]`O_NONBLOCK` | Đặt socket thành non-blocking. Xem phần về [blocking](#blocking) để biết chi tiết.|
| [i[`O_ASYNC` macro]i]`O_ASYNC`    | Đặt socket làm I/O bất đồng bộ. Khi có dữ liệu sẵn sàng để `recv()` trên socket, signal [i[`SIGIO` signal]] `SIGIO` sẽ được raise. Ít khi thấy, và vượt ra ngoài phạm vi hướng dẫn. Và tôi nghĩ nó chỉ có trên một số hệ thống.|

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

Các cách dùng khác nhau của system call `fcntl()` thật ra có giá
trị trả về khác nhau, nhưng tôi không bao phủ chúng ở đây vì chúng
không liên quan đến socket. Xem man page `fcntl()` cục bộ của bạn
để biết thêm.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int s = socket(PF_INET, SOCK_STREAM, 0);

fcntl(s, F_SETFL, O_NONBLOCK);  // set to non-blocking
fcntl(s, F_SETFL, O_ASYNC);     // set to asynchronous I/O
```

### See Also {.unnumbered .unlisted}

[Blocking](#blocking), [`send()`](#sendman)


[[manbreak]]
## `htons()`, `htonl()`, `ntohs()`, `ntohl()` {#htonsman}

[i[`htons()` function]i]
[i[`htonl()` function]i]
[i[`ntohs()` function]i]
[i[`ntohl()` function]i]

Chuyển các kiểu số nguyên nhiều byte từ host byte order sang network
byte order

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <netinet/in.h>

uint32_t htonl(uint32_t hostlong);
uint16_t htons(uint16_t hostshort);
uint32_t ntohl(uint32_t netlong);
uint16_t ntohs(uint16_t netshort);
```

### Description {.unnumbered .unlisted}

Chỉ để làm bạn thật sự không vui, các máy tính khác nhau dùng thứ
tự byte khác nhau nội bộ cho các số nguyên nhiều byte (tức là mọi
số nguyên lớn hơn một `char`). Hệ quả là nếu bạn `send()` một
`short int` hai byte từ máy Intel sang máy Mac (trước khi chúng
cũng biến thành Intel luôn), cái một máy tính nghĩ là số `1`, máy
kia sẽ nghĩ là số `256`, và ngược lại.

[i[Byte ordering]] Cách vượt qua vấn đề này là tất cả mọi người
gạt bỏ khác biệt và đồng ý rằng Motorola và IBM đúng, còn Intel
làm cách kỳ cục, và vì vậy tất cả chúng ta chuyển thứ tự byte của
mình thành "big-endian" trước khi gửi ra. Vì Intel là máy
"little-endian", đúng chính trị hơn là gọi thứ tự byte ưu tiên của
chúng ta là "Network Byte Order". Vậy các hàm này chuyển từ thứ tự
byte gốc sang network byte order và ngược lại.

(Chuyện này nghĩa là trên Intel các hàm này đảo tất cả byte, còn
trên PowerPC chúng không làm gì vì các byte đã ở Network Byte
Order rồi. Nhưng bạn vẫn luôn nên dùng chúng trong code, vì có ai
đó có thể muốn build nó trên máy Intel và vẫn muốn mọi thứ chạy
đúng.)

Lưu ý rằng các kiểu liên quan là số 32-bit (4 byte, có lẽ `int`)
và 16-bit (2 byte, rất có thể `short`).

Có các biến thể 64-bit trên nhiều hệ thống. Xem hàm
[flm[`htobe64()`|htobe64]] và họ hàng trong `<endian.h>` nếu bạn
có (có vẻ MacOS thì không có). Và GCC có [fl[byte swapping
built-ins|https://gcc.gnu.org/onlinedocs/gcc/Byte-Swapping-Builtins.html]]
thậm chí lên tới 128 bit. [flx[Hoặc bạn có thể tự cuộn tay|htonll.c]],
nhưng chỉ thực sự làm swap nếu bạn đang ở trên máy little-endian!

Dù sao, cách các hàm này hoạt động là trước tiên bạn quyết định
mình đang chuyển _từ_ host (byte order của máy bạn) hay từ network
byte order. Nếu "host", thì chữ đầu của hàm bạn sắp gọi là "h". Nếu
không thì là "n" cho "network". Phần giữa tên hàm luôn là "to" vì
bạn đang chuyển từ cái này "to" cái khác, và chữ áp chót cho biết
bạn đang chuyển _sang_ cái gì. Chữ cuối là kích thước dữ liệu, "s"
cho short, hoặc "l" cho long. Vậy:

| Hàm       | Mô tả                         |
|-----------|-------------------------------|
| `htons()` | `h`ost `to` `n`etwork `s`hort |
| `htonl()` | `h`ost `to` `n`etwork `l`ong  |
| `ntohs()` | `n`etwork `to` `h`ost `s`hort |
| `ntohl()` | `n`etwork `to` `h`ost `l`ong  |

### Return Value {.unnumbered .unlisted}

Mỗi hàm trả về giá trị đã được chuyển.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
uint32_t some_long = 10;
uint16_t some_short = 20;

uint32_t network_byte_order;

// convert and send
network_byte_order = htonl(some_long);
send(s, &network_byte_order, sizeof(uint32_t), 0);

some_short == ntohs(htons(some_short)); // this expression is true
```


[[manbreak]]
## `inet_ntoa()`, `inet_aton()`, `inet_addr` {#inet_ntoaman}

[i[`inet_ntoa()` function]i]
[i[`inet_aton()` function]i]
[i[`inet_addr()` function]i]

Chuyển địa chỉ IP từ chuỗi chấm-và-số sang `struct in_addr` và
ngược lại

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// ALL THESE ARE DEPRECATED!
// Use inet_pton() or inet_ntop() instead!

char *inet_ntoa(struct in_addr in);
int inet_aton(const char *cp, struct in_addr *inp);
in_addr_t inet_addr(const char *cp);
```

### Description {.unnumbered .unlisted}

_Các hàm này bị deprecated vì chúng không xử lý IPv6! Dùng
[`inet_ntop()`](#inet_ntopman) hoặc [`inet_pton()`](#inet_ntopman)
thay thế! Chúng được đưa vào đây vì bạn vẫn có thể gặp chúng
ngoài đời._

Tất cả các hàm này chuyển từ `struct in_addr` (một phần của
`struct sockaddr_in` của bạn, có khả năng cao) sang một chuỗi ở
định dạng chấm-và-số (ví dụ "192.168.5.10") và ngược lại. Nếu bạn
có một địa chỉ IP được truyền qua command line hay gì đó, đây là
cách dễ nhất để có `struct in_addr` để `connect()` tới, hoặc bất
cứ gì. Nếu bạn cần quyền năng hơn, thử vài hàm DNS như
`gethostbyname()` hoặc cố đảo chính _coup d'État_ ở nước bản địa
của bạn.

Hàm `inet_ntoa()` chuyển một địa chỉ mạng trong `struct in_addr`
sang chuỗi định dạng chấm-và-số. Chữ "n" trong "ntoa" là
"network", và "a" là "ASCII" vì lý do lịch sử (nên đó là "Network
To ASCII", hậu tố "toa" có một người bạn tương tự trong thư viện
C gọi là `atoi()` chuyển chuỗi ASCII sang số nguyên).

Hàm `inet_aton()` là ngược lại, chuyển từ chuỗi chấm-và-số sang
một `in_addr_t` (là kiểu của trường `s_addr` trong `struct
in_addr` của bạn).

Cuối cùng, hàm `inet_addr()` là hàm cũ hơn làm cơ bản cùng chuyện
với `inet_aton()`. Về mặt lý thuyết nó bị deprecated, nhưng bạn
sẽ thấy nó nhiều và cảnh sát sẽ không đến bắt bạn nếu bạn dùng nó.

### Return Value {.unnumbered .unlisted}

`inet_aton()` trả về khác không nếu địa chỉ hợp lệ, và trả về
không nếu địa chỉ không hợp lệ.

`inet_ntoa()` trả về chuỗi chấm-và-số trong một buffer tĩnh bị
ghi đè mỗi lần gọi hàm.

`inet_addr()` trả về địa chỉ dưới dạng `in_addr_t`, hoặc `-1` nếu
có lỗi. (Đây là cùng kết quả nếu bạn thử chuyển chuỗi
[i[`255.255.255.255`]] "`255.255.255.255`", là một địa chỉ IP hợp
lệ. Đây là lý do `inet_aton()` tốt hơn.)

### Example {.unnumbered .unlisted}

```{.c .numberLines}
struct sockaddr_in antelope;
char *some_addr;

inet_aton("10.0.0.1", &antelope.sin_addr); // store IP in antelope

some_addr = inet_ntoa(antelope.sin_addr); // return the IP
printf("%s\n", some_addr); // prints "10.0.0.1"

// and this call is the same as the inet_aton() call, above:
antelope.sin_addr.s_addr = inet_addr("10.0.0.1");
```

### See Also {.unnumbered .unlisted}

[`inet_ntop()`](#inet_ntopman), [`inet_pton()`](#inet_ntopman),
[`gethostbyname()`](#gethostbynameman), [`gethostbyaddr()`](#gethostbynameman)


[[manbreak]]
## `inet_ntop()`, `inet_pton()` {#inet_ntopman}

[i[`inet_ntop()` function]i]
[i[`inet_pton()` function]i]

Chuyển địa chỉ IP sang dạng người đọc được và ngược lại.

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <arpa/inet.h>

const char *inet_ntop(int af, const void *src,
                      char *dst, socklen_t size);

int inet_pton(int af, const char *src, void *dst);
```

### Description {.unnumbered .unlisted}

Các hàm này để xử lý địa chỉ IP dạng người đọc được và chuyển
chúng sang biểu diễn nhị phân để dùng với nhiều hàm và system
call. Chữ "n" là "network", và "p" là "presentation". Hoặc "text
presentation". Nhưng bạn có thể nghĩ nó là "printable". "ntop" là
"network to printable". Thấy chưa?

Đôi khi bạn không muốn nhìn vào một đống số nhị phân khi xem một
địa chỉ IP. Bạn muốn nó ở dạng in đẹp đẽ, như `192.0.2.180`, hay
`2001:db8:8714:3a90::12`. Trong trường hợp đó, `inet_ntop()` là
dành cho bạn.

`inet_ntop()` nhận họ địa chỉ trong tham số `af` (hoặc `AF_INET`
hoặc `AF_INET6`). Tham số `src` nên là con trỏ tới một `struct
in_addr` hoặc `struct in6_addr` chứa địa chỉ bạn muốn chuyển thành
chuỗi. Cuối cùng `dst` và `size` là con trỏ tới chuỗi đích và độ
dài tối đa của chuỗi đó.

Độ dài tối đa của chuỗi `dst` nên là bao nhiêu? Độ dài tối đa cho
địa chỉ IPv4 và IPv6 là bao nhiêu? Rất may có vài macro giúp bạn.
Các độ dài tối đa là: `INET_ADDRSTRLEN` và `INET6_ADDRSTRLEN`.

Lúc khác, bạn có thể có một chuỗi chứa địa chỉ IP ở dạng đọc được,
và bạn muốn pack nó vào một `struct sockaddr_in` hoặc một `struct
sockaddr_in6`. Trong trường hợp đó, hàm ngược lại `inet_pton()` là
cái bạn cần.

`inet_pton()` cũng nhận họ địa chỉ (hoặc `AF_INET` hoặc
`AF_INET6`) trong tham số `af`. Tham số `src` là con trỏ tới một
chuỗi chứa địa chỉ IP ở dạng in được. Cuối cùng tham số `dst` trỏ
tới nơi kết quả nên được lưu, có thể là `struct in_addr` hoặc
`struct in6_addr`.

Các hàm này không làm DNS lookup, bạn sẽ cần `getaddrinfo()` cho
cái đó.

### Return Value {.unnumbered .unlisted}

`inet_ntop()` trả về tham số `dst` nếu thành công, hoặc `NULL`
nếu thất bại (và `errno` được gán).

`inet_pton()` trả về `1` nếu thành công. Nó trả về `-1` nếu có
lỗi (`errno` được gán), hoặc `0` nếu đầu vào không phải địa chỉ
IP hợp lệ.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// IPv4 demo of inet_ntop() and inet_pton()

struct sockaddr_in sa;
char str[INET_ADDRSTRLEN];

// store this IP address in sa:
inet_pton(AF_INET, "192.0.2.33", &(sa.sin_addr));

// now get it back and print it
inet_ntop(AF_INET, &(sa.sin_addr), str, INET_ADDRSTRLEN);

printf("%s\n", str); // prints "192.0.2.33"
```

```{.c .numberLines}
// IPv6 demo of inet_ntop() and inet_pton()
// (basically the same except with a bunch of 6s thrown around)

struct sockaddr_in6 sa;
char str[INET6_ADDRSTRLEN];

// store this IP address in sa:
inet_pton(AF_INET6, "2001:db8:8714:3a90::12", &(sa.sin6_addr));

// now get it back and print it
inet_ntop(AF_INET6, &(sa.sin6_addr), str, INET6_ADDRSTRLEN);

printf("%s\n", str); // prints "2001:db8:8714:3a90::12"
```

```{.c .numberLines}
// Helper function you can use:

//Convert a struct sockaddr address to a string, IPv4 and IPv6:

char *get_ip_str(const struct sockaddr *sa, char *s, size_t maxlen)
{
    switch(sa->sa_family) {
        case AF_INET:
            inet_ntop(AF_INET,
                    &(((struct sockaddr_in *)sa)->sin_addr), s,
                    maxlen);
            break;

        case AF_INET6:
            inet_ntop(AF_INET6,
                    &(((struct sockaddr_in6 *)sa)->sin6_addr), s,
                    maxlen);
            break;

        default:
            strncpy(s, "Unknown AF", maxlen);
            return NULL;
    }

    return s;
}
```

### See Also {.unnumbered .unlisted}

[`getaddrinfo()`](#getaddrinfoman)



[[manbreak]]
## `listen()` {#listenman}

[i[`listen()` function]i]

Báo một socket lắng nghe kết nối đi tới

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>

int listen(int s, int backlog);
```

### Description {.unnumbered .unlisted}

Bạn có thể cầm socket descriptor của mình (tạo bằng system call
`socket()`) và bảo nó lắng nghe kết nối đi tới. Đây là điều phân
biệt server với client đấy các bạn.

Tham số `backlog` có thể nghĩa vài thứ khác nhau tùy hệ thống bạn
đang dùng, nhưng nói chung nó là có thể có bao nhiêu kết nối đang
chờ trước khi kernel bắt đầu từ chối các kết nối mới. Khi các kết
nối mới đến, bạn nên nhanh chóng `accept()` chúng để backlog không
đầy. Thử gán 10 hoặc gì đó, và nếu client của bạn bắt đầu bị
"Connection refused" dưới tải nặng, tăng lên.

Trước khi gọi `listen()`, server của bạn nên gọi `bind()` để gắn
mình vào một số port cụ thể. Số port đó (trên địa chỉ IP của
server) sẽ là cái mà client kết nối tới.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ được
gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
struct addrinfo hints, *res;
int sockfd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_STREAM;
hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

getaddrinfo(NULL, "3490", &hints, &res);

// make a socket:

sockfd = socket(res->ai_family, res->ai_socktype,
    res->ai_protocol);

// bind it to the port we passed in to getaddrinfo():

bind(sockfd, res->ai_addr, res->ai_addrlen);

listen(sockfd, 10); // set sockfd up to be a server socket

// then have an accept() loop down here somewhere
```

### See Also {.unnumbered .unlisted}

[`accept()`](#acceptman), [`bind()`](#bindman), [`socket()`](#socketman)


[[manbreak]]
## `perror()`, `strerror()` {#perrorman}

[i[`perror()` function]i]
[i[`strerror()` function]i]

In một lỗi dưới dạng chuỗi người đọc được

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <stdio.h>
#include <string.h>   // for strerror()

void perror(const char *s);
char *strerror(int errnum);
```

### Description {.unnumbered .unlisted}

Vì rất nhiều hàm trả về `-1` khi lỗi và đặt giá trị của biến
[i[`errno` variable]] `errno` thành một số nào đó, sẽ tuyệt nếu
bạn có thể dễ dàng in nó ra ở dạng có ý nghĩa với bạn.

Rất may, `perror()` làm điều đó. Nếu bạn muốn in thêm mô tả trước
lỗi, bạn có thể trỏ tham số `s` tới đó (hoặc để `s` là `NULL` và
sẽ không in gì thêm).

Nói gọn, hàm này nhận các giá trị `errno`, như `ECONNRESET`, và in
chúng đẹp đẽ, như "Connection reset by peer."

Hàm `strerror()` rất giống `perror()`, chỉ khác là nó trả về một
con trỏ tới chuỗi thông báo lỗi cho giá trị đã cho (bạn thường
truyền biến `errno`).

### Return Value {.unnumbered .unlisted}

`strerror()` trả về một con trỏ tới chuỗi thông báo lỗi.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int s;

s = socket(PF_INET, SOCK_STREAM, 0);

if (s == -1) { // some error has occurred
    // prints "socket error: " + the error message:
    perror("socket error");
}

// similarly:
if (listen(s, 10) == -1) {
    // this prints "an error: " + the error message from errno:
    printf("an error: %s\n", strerror(errno));
}
```

### See Also {.unnumbered .unlisted}

[`errno`](#errnoman)


[[manbreak]]
## `poll()` {#pollman}

[i[`poll()` function]i]

Kiểm tra sự kiện trên nhiều socket cùng lúc

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/poll.h>

int poll(struct pollfd *ufds, unsigned int nfds, int timeout);
```

### Description {.unnumbered .unlisted}

Hàm này rất giống `select()` ở chỗ cả hai đều theo dõi các tập
file descriptor để có sự kiện, như dữ liệu đi tới sẵn sàng để
`recv()`, socket sẵn sàng để `send()` dữ liệu tới, dữ liệu
out-of-band sẵn sàng để `recv()`, lỗi, vân vân.

Ý tưởng cơ bản là bạn truyền một mảng `nfds` cái `struct pollfd`
trong `ufds`, cùng với một timeout tính theo millisecond (1000
millisecond một giây). `timeout` có thể âm nếu bạn muốn chờ mãi.
Nếu không có sự kiện nào xảy ra trên bất kỳ socket descriptor nào
trước khi timeout, `poll()` sẽ trả về.

Mỗi phần tử trong mảng `struct pollfd` đại diện cho một socket
descriptor, và chứa các trường sau:

[i[`struct pollfd` type]i]

```{.c}
struct pollfd {
    int fd;         // the socket descriptor
    short events;   // bitmap of events we're interested in
    short revents;  // after return, bitmap of events that occurred
};
```

Trước khi gọi `poll()`, nạp `fd` bằng socket descriptor (nếu bạn
gán `fd` thành một số âm, `struct pollfd` này bị bỏ qua và trường
`revents` được gán thành không) rồi dựng trường `events` bằng cách
OR bitwise các macro sau:

| Macro     | Mô tả                                                      |
|-----------|------------------------------------------------------------|
| `POLLIN`  | Báo cho tôi khi có dữ liệu sẵn sàng để `recv()` trên socket này. |
| `POLLOUT` | Báo cho tôi khi tôi có thể `send()` dữ liệu tới socket này mà không bị block. |
| `POLLPRI` | Báo cho tôi khi có dữ liệu out-of-band sẵn sàng để `recv()` trên socket này. |

Khi `poll()` trả về, trường `revents` sẽ được dựng như một phép OR
bitwise của các trường trên, cho bạn biết descriptor nào thật sự
đã có sự kiện đó xảy ra. Thêm nữa, các trường khác này có thể xuất
hiện:

| Macro      | Mô tả                                                       |
|------------|-------------------------------------------------------------|
| `POLLERR`  | Đã có lỗi trên socket này.                                  |
| `POLLHUP`  | Đầu remote của kết nối đã cúp máy.                         |
| `POLLNVAL` | Có gì đó sai với socket descriptor `fd`, có thể nó chưa khởi tạo? |

### Return Value {.unnumbered .unlisted}

Trả về số phần tử trong mảng `ufds` đã có sự kiện xảy ra; số này
có thể là không nếu timeout đã xảy ra. Cũng trả về `-1` nếu lỗi
(và `errno` sẽ được gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int s1, s2;
int rv;
char buf1[256], buf2[256];
struct pollfd ufds[2];

s1 = socket(PF_INET, SOCK_STREAM, 0);
s2 = socket(PF_INET, SOCK_STREAM, 0);

// pretend we've connected both to a server at this point
//connect(s1, ...)...
//connect(s2, ...)...

// set up the array of file descriptors.
//
// in this example, we want to know when there's normal or
// out-of-band (OOB) data ready to be recv()'d...

ufds[0].fd = s1;
ufds[0].events = POLLIN | POLLPRI; // check for normal or OOB

ufds[1].fd = s2;
ufds[1].events = POLLIN; // check for just normal data

// wait for events on the sockets, 3.5 second timeout
rv = poll(ufds, 2, 3500);

if (rv == -1) {
    perror("poll"); // error occurred in poll()
} else if (rv == 0) {
    printf("Timeout occurred! No data after 3.5 seconds.\n");
} else {
    // check for events on s1:
    if (ufds[0].revents & POLLIN) {
        recv(s1, buf1, sizeof buf1, 0); // receive normal data
    }
    if (ufds[0].revents & POLLPRI) {
        recv(s1, buf1, sizeof buf1, MSG_OOB); // out-of-band data
    }

    // check for events on s2:
    if (ufds[1].revents & POLLIN) {
        recv(s1, buf2, sizeof buf2, 0);
    }
}
```

### See Also {.unnumbered .unlisted}

[`select()`](#selectman)


[[manbreak]]
## `recv()`, `recvfrom()` {#recvman}

[i[`recv()` function]i]
[i[`recvfrom()` function]i]

Nhận dữ liệu trên socket

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

ssize_t recv(int s, void *buf, size_t len, int flags);
ssize_t recvfrom(int s, void *buf, size_t len, int flags,
                 struct sockaddr *from, socklen_t *fromlen);
```

### Description {.unnumbered .unlisted}

Khi bạn đã có socket dựng lên và đang kết nối, bạn có thể đọc dữ
liệu đi tới từ đầu bên kia bằng `recv()` (cho socket TCP
[i[`SOCK_STREAM` macro]] `SOCK_STREAM`) và `recvfrom()` (cho
socket UDP [i[`SOCK_DGRAM` macro]] `SOCK_DGRAM`).

Cả hai hàm đều nhận socket descriptor `s`, một con trỏ tới buffer
`buf`, kích thước (tính theo byte) của buffer `len`, và một tập
`flags` điều khiển cách các hàm hoạt động.

Ngoài ra, `recvfrom()` nhận thêm một [i[`struct sockaddr` type]]
`struct sockaddr*`, `from` sẽ cho bạn biết dữ liệu đến từ đâu, và
sẽ điền `fromlen` bằng kích thước của `struct sockaddr`. (Bạn
cũng phải khởi tạo `fromlen` bằng kích thước của `from` hoặc
`struct sockaddr`.)

Vậy những cờ kỳ diệu nào bạn có thể truyền vào hàm này? Đây là
vài cái, nhưng bạn nên kiểm tra man page cục bộ của mình để biết
thêm và cái gì thật sự được hỗ trợ trên hệ thống của bạn. Bạn OR
bitwise chúng lại với nhau, hoặc chỉ gán `flags` thành `0` nếu
muốn nó là `recv()` vani bình thường.

| Macro         | Mô tả                                                    |
|---------------|----------------------------------------------------------|
| [i[Out-of-band data]][i[`MSG_OOB` macro]i]`MSG_OOB` | Nhận dữ liệu Out of Band. Đây là cách lấy dữ liệu đã được gửi cho bạn với cờ `MSG_OOB` trong `send()`. Ở đầu nhận, signal [i[`SIGURG` macro]i] `SIGURG` sẽ được raise báo cho bạn rằng có dữ liệu khẩn. Trong handler cho signal đó, bạn có thể gọi `recv()` với cờ `MSG_OOB` này. |
| [i[`MSG_PEEK` macro]i]`MSG_PEEK`                    | Nếu bạn muốn gọi `recv()` "chỉ để giả bộ", bạn có thể gọi với cờ này. Cái này sẽ cho bạn biết có gì đang đợi trong buffer khi bạn gọi `recv()` "thật" (tức là _không có_ cờ `MSG_PEEK`). Nó giống bản xem trước cho lời gọi `recv()` kế tiếp. | 
| [i[`MSG_WAITALL` macro]i]`MSG_WAITALL`              | Bảo `recv()` không trả về cho đến khi đã nhận được toàn bộ dữ liệu bạn chỉ định trong tham số `len`. Nó sẽ bỏ qua ý muốn của bạn trong hoàn cảnh cực đoan, ví dụ nếu một signal ngắt lời gọi hoặc nếu có lỗi xảy ra hoặc nếu đầu remote đóng kết nối, vân vân. Đừng giận nó. | 

Khi bạn gọi `recv()`, nó sẽ block cho đến khi có dữ liệu để đọc.
Nếu bạn không muốn block, đặt socket thành non-blocking hoặc
kiểm tra bằng `select()` hay `poll()` để xem có dữ liệu đi tới
không trước khi gọi `recv()` hoặc `recvfrom()`.

### Return Value {.unnumbered .unlisted}

Trả về số byte thật sự đã nhận (có thể ít hơn số bạn yêu cầu
trong tham số `len`), hoặc `-1` nếu lỗi (và `errno` sẽ được gán
phù hợp).

Nếu đầu remote đã đóng kết nối, `recv()` sẽ trả về `0`. Đây là
cách thường dùng để xác định đầu remote đã đóng kết nối chưa.
Bình thường là tốt, cưng!

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// stream sockets and recv()

struct addrinfo hints, *res;
int sockfd;
char buf[512];
int byte_count;

// get host info, make socket, and connect it
memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_STREAM;
getaddrinfo("www.example.com", "3490", &hints, &res);
sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
connect(sockfd, res->ai_addr, res->ai_addrlen);

// all right! now that we're connected, we can receive some data!
byte_count = recv(sockfd, buf, sizeof buf, 0);
printf("recv()'d %d bytes of data in buf\n", byte_count);
```

```{.c .numberLines}
// datagram sockets and recvfrom()

struct addrinfo hints, *res;
int sockfd;
int byte_count;
socklen_t fromlen;
struct sockaddr_storage addr;
char buf[512];
char ipstr[INET6_ADDRSTRLEN];

// get host info, make socket, bind it to port 4950
memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
hints.ai_socktype = SOCK_DGRAM;
hints.ai_flags = AI_PASSIVE;
getaddrinfo(NULL, "4950", &hints, &res);
sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
bind(sockfd, res->ai_addr, res->ai_addrlen);

// no need to accept(), just recvfrom():

fromlen = sizeof addr;
byte_count = recvfrom(sockfd, buf, sizeof buf, 0, &addr, &fromlen);

printf("recv()'d %d bytes of data in buf\n", byte_count);
printf("from IP address %s\n",
    inet_ntop(addr.ss_family,
        addr.ss_family == AF_INET?
            ((struct sockaddr_in *)&addr)->sin_addr:
            ((struct sockaddr_in6 *)&addr)->sin6_addr,
        ipstr, sizeof ipstr);
```

### See Also {.unnumbered .unlisted}

[`send()`](#sendman), [`sendto()`](#sendman), [`select()`](#selectman),
[`poll()`](#pollman), [Blocking](#blocking)


[[manbreak]]
## `select()` {#selectman}

[i[`select()` function]i]

Kiểm tra xem các socket descriptor có sẵn sàng đọc/ghi không

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/select.h>

int select(int n, fd_set *readfds, fd_set *writefds,
           fd_set *exceptfds, struct timeval *timeout);

FD_SET(int fd, fd_set *set);
FD_CLR(int fd, fd_set *set);
FD_ISSET(int fd, fd_set *set);
FD_ZERO(fd_set *set);
```

### Description {.unnumbered .unlisted}

Hàm `select()` cho bạn cách kiểm tra đồng thời nhiều socket xem
chúng có dữ liệu đang đợi được `recv()` không, hoặc bạn có thể
`send()` dữ liệu cho chúng mà không bị block không, hoặc có
exception nào xảy ra không.

Bạn điền tập socket descriptor của mình bằng các macro, như
`FD_SET()` ở trên. Khi đã có tập, bạn truyền nó vào hàm qua một
trong các tham số sau: `readfds` nếu bạn muốn biết khi nào bất kỳ
socket nào trong tập sẵn sàng để `recv()` dữ liệu, `writefds` nếu
bất kỳ socket nào sẵn sàng để `send()` dữ liệu, và/hoặc
`exceptfds` nếu bạn cần biết khi nào có exception (lỗi) xảy ra
trên bất kỳ socket nào. Bất kỳ hoặc tất cả tham số này có thể là
`NULL` nếu bạn không quan tâm đến loại sự kiện đó. Sau khi
`select()` trả về, giá trị trong các tập sẽ bị thay đổi để cho
biết cái nào sẵn sàng đọc hoặc ghi, và cái nào có exception.

Tham số đầu tiên, `n`, là socket descriptor có số cao nhất (đều
là `int`, nhớ chứ?) cộng một.

Cuối cùng, [i[`struct timeval` type]i] `struct timeval`,
`timeout`, ở cuối, cái này cho bạn bảo `select()` kiểm tra các
tập này bao lâu. Nó sẽ trả về sau khi timeout, hoặc khi có sự
kiện xảy ra, cái nào đến trước. `struct timeval` có hai trường:
`tv_sec` là số giây, cộng thêm `tv_usec`, số microsecond
(1.000.000 microsecond một giây).

Các macro trợ giúp làm như sau:

| Macro                            | Mô tả                                |
|----------------------------------|--------------------------------------|
| [i[`FD_SET()` macro]i]`FD_SET(int fd, fd_set *set);`     | Thêm `fd` vào `set`. |
| [i[`FD_CLR()` macro]i]`FD_CLR(int fd, fd_set *set);`     | Bỏ `fd` khỏi `set`.  |
| [i[`FD_ISSET()` macro]i]`FD_ISSET(int fd, fd_set *set);` | Trả về true nếu `fd` nằm trong `set`. |
| [i[`FD_ZERO()` macro]i]`FD_ZERO(fd_set *set);`           | Xóa toàn bộ phần tử khỏi `set`. |

Lưu ý cho người dùng Linux: `select()` của Linux có thể trả về
"sẵn-sàng-đọc" rồi thật ra không sẵn sàng đọc, khiến lời gọi
`read()` theo sau bị block. Bạn có thể khắc phục bug này bằng
cách bật cờ [i[`O_NONBLOCK` macro]] `O_NONBLOCK` trên socket
nhận để nó trả lỗi với `EWOULDBLOCK`, rồi bỏ qua lỗi này nếu nó
xảy ra. Xem [man page của `fcntl()`](#fcntlman) để biết thêm về
cách đặt socket thành non-blocking.

### Return Value {.unnumbered .unlisted}

Trả về số descriptor trong tập nếu thành công, `0` nếu đã đến
timeout, hoặc `-1` nếu lỗi (và `errno` sẽ được gán phù hợp).
Ngoài ra, các tập bị sửa để cho biết socket nào sẵn sàng.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int s1, s2, n;
fd_set readfds;
struct timeval tv;
char buf1[256], buf2[256];

// pretend we've connected both to a server at this point
//s1 = socket(...);
//s2 = socket(...);
//connect(s1, ...)...
//connect(s2, ...)...

// clear the set ahead of time
FD_ZERO(&readfds);

// add our descriptors to the set
FD_SET(s1, &readfds);
FD_SET(s2, &readfds);

// since we got s2 second, it's the "greater", so we use that for
// the n param in select()
n = s2 + 1;

// wait until either socket has data ready to be recv()d
// (timeout 10.5 secs)
tv.tv_sec = 10;
tv.tv_usec = 500000;
rv = select(n, &readfds, NULL, NULL, &tv);

if (rv == -1) {
    perror("select"); // error occurred in select()
} else if (rv == 0) {
    printf("Timeout occurred! No data after 10.5 seconds.\n");
} else {
    // one or both of the descriptors have data
    if (FD_ISSET(s1, &readfds)) {
        recv(s1, buf1, sizeof buf1, 0);
    }
    if (FD_ISSET(s2, &readfds)) {
        recv(s2, buf2, sizeof buf2, 0);
    }
}
```

### See Also {.unnumbered .unlisted}

[`poll()`](#pollman)


[[manbreak]]
## `setsockopt()`, `getsockopt()` {#setsockoptman}

[i[`setsockopt()` function]i]
[i[`getsockopt()` function]i]

Đặt các tùy chọn khác nhau cho một socket

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int getsockopt(int s, int level, int optname, void *optval,
               socklen_t *optlen);
int setsockopt(int s, int level, int optname, const void *optval,
               socklen_t optlen);
```

### Description {.unnumbered .unlisted}

Socket là thứ khá có thể cấu hình. Thật ra, chúng có thể cấu
hình đến mức tôi thậm chí sẽ không bao phủ hết ở đây. Có lẽ dù
sao cũng tùy hệ thống. Nhưng tôi sẽ nói về phần cơ bản.

Rõ ràng, các hàm này lấy và đặt các tùy chọn nhất định trên một
socket. Trên máy Linux, tất cả thông tin về socket nằm trong man
page cho socket ở phần 7. (Gõ: "`man 7 socket`" để có hết mấy
món ngon này.)

Về tham số, `s` là socket bạn đang nói đến, level nên được gán
thành [i[`SOL_SOCKET` macro]i] `SOL_SOCKET`. Rồi bạn đặt
`optname` thành tên bạn quan tâm. Lại nữa, xem man page của bạn
để có tất cả tùy chọn, nhưng đây là vài cái vui nhất:

| `optname`         | Mô tả                                                |
|-------------------|------------------------------------------------------|
| [i[`SO_BINDTODEVICE` macro]i]`SO_BINDTODEVICE` | Bind socket này vào tên thiết bị ký hiệu như `eth0` thay vì dùng `bind()` để bind nó vào địa chỉ IP. Gõ lệnh `ifconfig` trên Unix để xem tên thiết bị. |
| [i[`SO_REUSEADDR` macro]i]`SO_REUSEADDR      ` | Cho phép socket khác `bind()` vào port này, trừ khi đã có một socket đang lắng nghe tích cực bind vào port đó. Cái này giúp bạn vượt qua những thông báo lỗi "Address already in use" khi bạn thử khởi động lại server sau khi crash. |
| [i[`SO_BROADCAST` macro]i]`SO_BROADCAST`       | Cho phép socket UDP datagram (`SOCK_DGRAM`) gửi và nhận các gói tin được gửi đến và từ địa chỉ broadcast. Không làm gì, _KHÔNG LÀM GÌ!!_, với socket TCP stream! Hahaha! |

Về tham số `optval`, nó thường là con trỏ tới một `int` cho
biết giá trị đang nói. Cho boolean, không là false, khác không
là true. Và đó là sự thật tuyệt đối, trừ khi nó khác trên hệ
thống của bạn. Nếu không có tham số nào cần truyền, `optval` có
thể là `NULL`.

Tham số cuối cùng, `optlen`, nên được gán thành độ dài của
`optval`, có lẽ là `sizeof(int)`, nhưng thay đổi tùy tùy chọn.
Lưu ý rằng trong trường hợp `getsockopt()`, đây là con trỏ tới
một `socklen_t`, và nó chỉ định kích thước tối đa của đối tượng
sẽ được lưu trong `optval` (để ngăn buffer overflow). Và
`getsockopt()` sẽ sửa giá trị của `optlen` để phản ánh số byte
thật sự đã đặt.

**Cảnh báo**: trên một số hệ thống (đặc biệt là [i[SunOS]]
[i[Solaris]] Sun và [i[Windows]] Windows), tùy chọn có thể là
`char` thay vì `int`, và được gán, ví dụ, thành giá trị ký tự
`'1'` thay vì giá trị `int` `1`. Lại nữa, kiểm tra man page của
bạn để có thông tin thêm với "`man setsockopt`" và "`man 7
socket`"!

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ
được gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int optval;
int optlen;
char *optval2;

// set SO_REUSEADDR on a socket to true (1):
optval = 1;
setsockopt(s1, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof optval);

// bind a socket to a device name (might not work on all systems):
optval2 = "eth1"; // 4 bytes long, so 4, below:
setsockopt(s2, SOL_SOCKET, SO_BINDTODEVICE, optval2, 4);

// see if the SO_BROADCAST flag is set:
getsockopt(s3, SOL_SOCKET, SO_BROADCAST, &optval, &optlen);
if (optval != 0) {
    print("SO_BROADCAST enabled on s3!\n");
}
```

### See Also {.unnumbered .unlisted}

[`fcntl()`](#fcntlman)


[[manbreak]]
## `send()`, `sendto()` {#sendman}

[i[`send()` function]i]
[i[`sendto()` function]i]

Gửi dữ liệu ra qua socket

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

ssize_t send(int s, const void *buf, size_t len, int flags);
ssize_t sendto(int s, const void *buf, size_t len,
               int flags, const struct sockaddr *to,
               socklen_t tolen);
```

### Description {.unnumbered .unlisted}

Các hàm này gửi dữ liệu tới một socket. Nói chung, `send()`
được dùng cho socket TCP `SOCK_STREAM` đã kết nối, còn
`sendto()` được dùng cho socket datagram UDP `SOCK_DGRAM` không
kết nối. Với socket không kết nối, bạn phải chỉ định đích đến
của gói tin mỗi lần gửi, đó là lý do tham số cuối của
`sendto()` định nghĩa gói tin đang đi đâu.

Với cả `send()` và `sendto()`, tham số `s` là socket, `buf` là
con trỏ tới dữ liệu bạn muốn gửi, `len` là số byte muốn gửi, và
`flags` cho phép bạn chỉ định thêm thông tin về cách dữ liệu
được gửi. Gán `flags` thành không nếu bạn muốn nó là dữ liệu
"bình thường". Đây là vài cờ hay dùng, nhưng kiểm tra man page
`send()` cục bộ của bạn để biết thêm:

| Macro           | Mô tả                                                  |
|-----------------|--------------------------------------------------------|
| [i[`MSG_OOB` macro]i]`MSG_OOB`             | Gửi như dữ liệu [i[Out-of-band data]] "out of band". TCP hỗ trợ cái này, và đó là cách báo cho hệ thống nhận biết rằng dữ liệu này có độ ưu tiên cao hơn dữ liệu thường. Bên nhận sẽ nhận signal [i[`SIGURG` macro]i] `SIGURG` và có thể nhận dữ liệu này mà không cần nhận hết phần dữ liệu thường còn lại trong hàng đợi trước. |
| [i[`MSG_DONTROUTE` macro]i]`MSG_DONTROUTE` | Đừng gửi dữ liệu này qua router, chỉ giữ nó trong local. |
| [i[`MSG_DONTWAIT` macro]i]`MSG_DONTWAIT`   | Nếu `send()` sẽ block vì traffic đi ra đang bị tắc, làm nó trả về [i[`EAGAIN` macro]] `EAGAIN`. Cái này giống như "bật [i[Non-blocking sockets]] non-blocking chỉ cho lần send này". Xem phần về [blocking](#blocking) để biết chi tiết. |
| [i[`MSG_NOSIGNAL` macro]i]`MSG_NOSIGNAL`   | Nếu bạn `send()` đến host remote không còn đang `recv()`, bạn thường sẽ nhận signal [i[`SIGPIPE` macro]] `SIGPIPE`. Thêm cờ này ngăn signal đó bị raise. |

### Return Value {.unnumbered .unlisted}

Trả về số byte thật sự đã gửi, hoặc `-1` nếu lỗi (và `errno`
sẽ được gán phù hợp). Lưu ý rằng số byte thật sự đã gửi có thể
ít hơn số bạn yêu cầu gửi! Xem phần về [xử lý `send()` một
phần](#sendall) để có hàm trợ giúp vượt qua chuyện này.

Ngoài ra, nếu socket đã bị đóng bởi bất kỳ bên nào, process gọi
`send()` sẽ nhận signal `SIGPIPE`. (Trừ khi `send()` được gọi
với cờ `MSG_NOSIGNAL`.)

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int spatula_count = 3490;
char *secret_message = "The Cheese is in The Toaster";

int stream_socket, dgram_socket;
struct sockaddr_in dest;
int temp;

// first with TCP stream sockets:

// assume sockets are made and connected
//stream_socket = socket(...
//connect(stream_socket, ...

// convert to network byte order
temp = htonl(spatula_count);
// send data normally:
send(stream_socket, &temp, sizeof temp, 0);

// send secret message out of band:
send(stream_socket, secret_message, strlen(secret_message)+1,
        MSG_OOB);

// now with UDP datagram sockets:
//getaddrinfo(...
//dest = ... // assume "dest" holds the address of the destination
//dgram_socket = socket(...

// send secret message normally:
sendto(dgram_socket, secret_message, strlen(secret_message)+1, 0, 
       (struct sockaddr*)&dest, sizeof dest);
```

### See Also {.unnumbered .unlisted}

[`recv()`](#recvman), [`recvfrom()`](#recvman)


[[manbreak]]
## `shutdown()` {#shutdownman}

[i[`shutdown()` function]i]

Dừng các lần send và receive tiếp theo trên socket

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/socket.h>

int shutdown(int s, int how);
```

### Description {.unnumbered .unlisted}

Đó! Tôi chịu hết nổi rồi! Không cho `send()` thêm nữa trên
socket này, nhưng tôi vẫn muốn `recv()` dữ liệu trên đó! Hoặc
ngược lại! Làm sao tôi làm được chuyện này?

Khi bạn `close()` một socket descriptor, nó đóng cả hai phía
của socket cho đọc và ghi, và giải phóng socket descriptor. Nếu
bạn chỉ muốn đóng một phía hoặc phía kia, bạn có thể dùng lời
gọi `shutdown()` này.

Về tham số, `s` rõ ràng là socket bạn muốn thực hiện hành động
này, và hành động đó là gì có thể chỉ định qua tham số `how`.
`how` có thể là [i[`SHUT_RD` macro]i]`SHUT_RD` để cấm thêm các
`recv()`, [i[`SHUT_WR` macro]i]`SHUT_WR` để cấm thêm các
`send()`, hoặc [i[`SHUT_RDWR` macro]i]`SHUT_RDWR` để cấm cả hai.

Lưu ý rằng `shutdown()` không giải phóng socket descriptor, nên
bạn vẫn phải cuối cùng `close()` socket kể cả khi nó đã bị shut
down hoàn toàn.

Đây là system call ít khi dùng.

### Return Value {.unnumbered .unlisted}

Trả về không nếu thành công, hoặc `-1` nếu lỗi (và `errno` sẽ
được gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
int s = socket(PF_INET, SOCK_STREAM, 0);

// ...do some send()s and stuff in here...

// and now that we're done, don't allow any more sends()s:
shutdown(s, SHUT_WR);
```

### See Also {.unnumbered .unlisted}

[`close()`](#closeman)


[[manbreak]]
## `socket()` {#socketman}

[i[`socket()` function]i]

Cấp phát một socket descriptor

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int socket(int domain, int type, int protocol);
```

### Description {.unnumbered .unlisted}

Trả về một socket descriptor mới mà bạn có thể dùng để làm
chuyện gì đó socket-kiểu. Đây thường là lời gọi đầu tiên trong
quá trình đồ sộ viết một chương trình socket, và bạn có thể
dùng kết quả cho các lời gọi tiếp theo tới `listen()`, `bind()`,
`accept()`, hay nhiều hàm khác.

Trong cách dùng thông thường, bạn lấy giá trị cho các tham số
này từ lời gọi `getaddrinfo()`, như trong ví dụ bên dưới. Nhưng
bạn có thể tự điền bằng tay nếu thật sự muốn.

| Tham số    | Mô tả                                                      |
|------------|------------------------------------------------------------|
| `domain`   | `domain` mô tả loại socket bạn quan tâm. Tin tôi đi, cái này có thể là nhiều thứ, nhưng vì đây là hướng dẫn về socket, nó sẽ là [i[`PF_INET` macro]i] `PF_INET` cho IPv4, và `PF_INET6` cho IPv6. |
| `type`     | Tham số `type` cũng có thể là nhiều thứ, nhưng bạn sẽ có lẽ gán nó thành [i[`SOCK_STREAM` macro]i] `SOCK_STREAM` cho socket TCP đáng tin (`send()`, `recv()`) hoặc [i[`SOCK_DGRAM` macro]i] `SOCK_DGRAM` cho socket UDP nhanh không đáng tin (`sendto()`, `recvfrom()`). (Một kiểu socket thú vị khác là [i[`SOCK_RAW` macro]i] `SOCK_RAW` có thể dùng để dựng gói tin bằng tay. Khá ngầu.) | 
| `protocol` | Cuối cùng, tham số `protocol` cho biết protocol nào dùng với một kiểu socket nhất định. Như tôi đã nói, ví dụ, `SOCK_STREAM` dùng TCP. Rất may cho bạn, khi dùng `SOCK_STREAM` hoặc `SOCK_DGRAM`, bạn chỉ cần gán protocol thành 0, và nó sẽ tự động dùng protocol phù hợp. Nếu không, bạn có thể dùng [i[`getprotobyname()` function]] `getprotobyname()` để tra số protocol phù hợp. |

### Return Value {.unnumbered .unlisted}

Socket descriptor mới để dùng trong các lời gọi tiếp theo,
hoặc `-1` nếu lỗi (và `errno` sẽ được gán phù hợp).

### Example {.unnumbered .unlisted}

```{.c .numberLines}
struct addrinfo hints, *res;
int sockfd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;     // AF_INET, AF_INET6, or AF_UNSPEC
hints.ai_socktype = SOCK_STREAM; // SOCK_STREAM or SOCK_DGRAM

getaddrinfo("www.example.com", "3490", &hints, &res);

// make a socket using the information gleaned from getaddrinfo():
sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
```

### See Also {.unnumbered .unlisted}

[`accept()`](#acceptman), [`bind()`](#bindman),
[`getaddrinfo()`](#getaddrinfoman), [`listen()`](#listenman)


[[manbreak]]
## `struct sockaddr` và đồng bọn {#structsockaddrman}

[i[`struct sockaddr` type]i]
[i[`struct sockaddr_in` type]i]
[i[`struct in_addr` type]i]
[i[`struct sockaddr_in6` type]i]
[i[`struct in6_addr` type]i]
[i[`struct sockaddr_storage` type]i]

Các struct để xử lý địa chỉ internet

### Synopsis {.unnumbered .unlisted}

```{.c}
#include <netinet/in.h>

// All pointers to socket address structures are often cast to
// pointers to this type before use in various functions and system
// calls:

struct sockaddr {
    unsigned short    sa_family;    // address family, AF_xxx
    char              sa_data[14];  // 14 bytes of protocol address
};


// IPv4 AF_INET sockets:

struct sockaddr_in {
    short            sin_family;   // e.g. AF_INET, AF_INET6
    unsigned short   sin_port;     // e.g. htons(3490)
    struct in_addr   sin_addr;     // see struct in_addr, below
    char             sin_zero[8];  // zero this if you want to
};

struct in_addr {
    unsigned long s_addr;          // load with inet_pton()
};


// IPv6 AF_INET6 sockets:

struct sockaddr_in6 {
    u_int16_t       sin6_family;   // address family, AF_INET6
    u_int16_t       sin6_port;     // port number, network order
    u_int32_t       sin6_flowinfo; // IPv6 flow information
    struct in6_addr sin6_addr;     // IPv6 address
    u_int32_t       sin6_scope_id; // Scope ID
};

struct in6_addr {
    unsigned char   s6_addr[16];   // load with inet_pton()
};


// General socket address holding structure, big enough to hold
// either struct sockaddr_in or struct sockaddr_in6 data:

struct sockaddr_storage {
    sa_family_t  ss_family;     // address family

    // all this is padding, implementation specific, ignore it:
    char      __ss_pad1[_SS_PAD1SIZE];
    int64_t   __ss_align;
    char      __ss_pad2[_SS_PAD2SIZE];
};
```

### Description {.unnumbered .unlisted}

Đây là các struct cơ bản cho tất cả syscall và hàm xử lý địa
chỉ internet. Bạn sẽ thường dùng `getaddrinfo()` để điền các
struct này, rồi sẽ đọc chúng khi cần.

Trong bộ nhớ, `struct sockaddr_in` và `struct sockaddr_in6`
chia sẻ cùng phần đầu struct với `struct sockaddr`, và bạn có
thể tự do cast con trỏ của một kiểu sang kiểu kia mà không gây
hại gì, trừ khả năng tận thế vũ trụ.

Nói đùa thôi về chuyện tận thế vũ trụ... nếu vũ trụ thực sự tận
thế khi bạn cast một `struct sockaddr_in*` sang `struct
sockaddr*`, tôi hứa với bạn đó là trùng hợp thuần túy và bạn
thậm chí không nên lo về nó.

Vậy, với chuyện đó trong đầu, nhớ rằng mỗi khi một hàm nói rằng
nó nhận `struct sockaddr*` bạn có thể cast `struct
sockaddr_in*`, `struct sockaddr_in6*`, hoặc `struct
sockaddr_storage*` của mình sang kiểu đó một cách dễ dàng và an
toàn.

`struct sockaddr_in` là struct được dùng với địa chỉ IPv4 (ví
dụ "192.0.2.10"). Nó chứa họ địa chỉ (`AF_INET`), một port trong
`sin_port`, và địa chỉ IPv4 trong `sin_addr`.

Cũng có trường `sin_zero` trong `struct sockaddr_in` mà một số
người quả quyết phải được gán thành không. Người khác không quả
quyết gì về nó (tài liệu Linux thậm chí không nhắc đến nó),
và gán nó thành không có vẻ không thực sự cần thiết. Vậy, nếu
bạn thích, cứ gán nó thành không bằng `memset()`.

Giờ, cái `struct in_addr` đó là một con quái vật lạ trên các hệ
thống khác nhau. Đôi khi nó là một `union` điên rồ với đủ loại
`#define` và nhảm nhí khác. Nhưng cái bạn nên làm là chỉ dùng
trường `s_addr` trong struct này, vì nhiều hệ thống chỉ cài đặt
mỗi trường đó.

`struct sockaddr_in6` và `struct in6_addr` rất giống, chỉ là
chúng được dùng cho IPv6.

`struct sockaddr_storage` là struct bạn có thể truyền cho
`accept()` hoặc `recvfrom()` khi bạn đang cố viết code độc lập
với phiên bản IP và bạn không biết địa chỉ mới sẽ là IPv4 hay
IPv6. Struct `sockaddr_storage` đủ lớn để chứa cả hai kiểu,
khác với `struct sockaddr` gốc nhỏ.

### Example {.unnumbered .unlisted}

```{.c .numberLines}
// IPv4:

struct sockaddr_in ip4addr;
int s;

ip4addr.sin_family = AF_INET;
ip4addr.sin_port = htons(3490);
inet_pton(AF_INET, "10.0.0.1", &ip4addr.sin_addr);

s = socket(PF_INET, SOCK_STREAM, 0);
bind(s, (struct sockaddr*)&ip4addr, sizeof ip4addr);
```

```{.c .numberLines}
// IPv6:

struct sockaddr_in6 ip6addr;
int s;

ip6addr.sin6_family = AF_INET6;
ip6addr.sin6_port = htons(4950);
inet_pton(AF_INET6, "2001:db8:8714:3a90::12", &ip6addr.sin6_addr);

s = socket(PF_INET6, SOCK_STREAM, 0);
bind(s, (struct sockaddr*)&ip6addr, sizeof ip6addr);
```

### See Also {.unnumbered .unlisted}

[`accept()`](#acceptman), [`bind()`](#bindman), [`connect()`](#connectman),
[`inet_aton()`](#inet_ntoaman), [`inet_ntoa()`](#inet_ntoaman)
