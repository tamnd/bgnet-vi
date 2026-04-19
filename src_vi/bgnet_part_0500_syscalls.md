# System call hoặc không gì cả

Đây là phần chúng ta đi vào các system call (và vài hàm thư viện khác)
cho phép bạn chạm tới chức năng mạng của một máy Unix, hay bất kỳ máy
nào có sockets API (BSD, Windows, Linux, Mac, vân vân). Khi bạn gọi một
trong các hàm này, kernel nhảy vào làm hết công việc cho bạn, tự động
như có phép.

Chỗ nhiều người kẹt nhất quanh đây là thứ tự gọi các thứ này. Ở đoạn
đó, các trang `man` chả giúp được gì, chắc bạn cũng phát hiện ra rồi.
Để cứu cái hoàn cảnh kinh dị đó, tôi đã cố xếp các system call trong
các phần dưới đây theo _đúng_ (xấp xỉ) thứ tự bạn sẽ cần gọi chúng
trong chương trình.

Cộng thêm vài mẩu code mẫu rải rác, chút sữa và bánh quy (mà bạn sợ là
phải tự lo), cùng một ít gan và lòng can đảm, và bạn sẽ bắn dữ liệu đi
khắp Internet như Con Của Jon Postel!

_(Xin lưu ý để ngắn gọn, nhiều đoạn code dưới đây không có kiểm tra lỗi
cần thiết. Và chúng hay giả định rằng kết quả gọi `getaddrinfo()` thành
công và trả về một phần tử hợp lệ trong linked list. Cả hai tình huống
này đều được xử lý đàng hoàng trong các chương trình đứng độc lập, nên
cứ lấy mấy cái đó làm mẫu.)_


## `getaddrinfo()`: Chuẩn bị phóng!

[i[`getaddrinfo()` function]] Đây là một con ngựa thồ thực thụ với khá
nhiều tuỳ chọn, nhưng dùng thì thực ra đơn giản. Nó giúp chuẩn bị các
`struct` bạn sẽ cần về sau.

Một chút lịch sử: ngày xưa người ta dùng một hàm tên là
`gethostbyname()` để làm DNS lookup. Rồi bạn nạp thông tin đó bằng tay
vào một `struct sockaddr_in`, và dùng nó trong các lời gọi.

May thay, giờ không cần thế nữa. (Cũng không đáng mơ ước, nếu bạn muốn
viết code chạy được với cả IPv4 và IPv6!) Trong thời hiện đại, bạn có
hàm `getaddrinfo()` làm đủ thứ thiện lành giùm bạn, bao gồm DNS lookup
và tra tên dịch vụ, và còn điền luôn các `struct` bạn cần!

Xem thử cái coi!

```{.c}
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *node,   // e.g. "www.example.com" or IP
                const char *service,  // e.g. "http" or port number
                const struct addrinfo *hints,
                struct addrinfo **res);
```

Bạn đưa vào hàm này ba tham số đầu vào, và nó đưa lại cho bạn con trỏ
tới một linked list kết quả là `res`.

Tham số `node` là tên host cần kết nối, hoặc một địa chỉ IP.

Tiếp theo là tham số `service`, có thể là số port, kiểu "80", hoặc tên
một dịch vụ cụ thể (tìm trong [fl[Bảng Port Của
IANA|https://www.iana.org/assignments/port-numbers]] hoặc file
`/etc/services` trên máy Unix) kiểu "http" hay "ftp" hay "telnet" hay
"smtp" hay gì tuỳ ý.

Cuối cùng, tham số `hints` trỏ tới một `struct addrinfo` mà bạn đã điền
sẵn các thông tin liên quan.

Đây là một lời gọi ví dụ nếu bạn là server muốn lắng nghe trên địa chỉ
IP của host, port 3490. Lưu ý nó chưa thực sự lắng nghe hay cấu hình
mạng gì cả, chỉ chuẩn bị các struct để ta dùng sau:

```{.c .numberLines}
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // will point to the results

memset(&hints, 0, sizeof hints); // make sure the struct is empty
hints.ai_family = AF_UNSPEC;     // don't care IPv4 or IPv6
hints.ai_socktype = SOCK_STREAM; // TCP stream sockets
hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

if ((status = getaddrinfo(NULL, "3490", &hints, &servinfo)) != 0) {
    fprintf(stderr, "gai error: %s\n", gai_strerror(status));
    exit(1);
}

// servinfo now points to a linked list of 1 or more
// struct addrinfos

// ... do everything until you don't need servinfo anymore ....

freeaddrinfo(servinfo); // free the linked-list
```

Để ý tôi set `ai_family` là `AF_UNSPEC`, tức là tôi không quan tâm xài
IPv4 hay IPv6. Bạn có thể set `AF_INET` hoặc `AF_INET6` nếu muốn cụ
thể một trong hai.

Bạn cũng thấy cờ `AI_PASSIVE` ở đó; nó bảo `getaddrinfo()` tự gán địa
chỉ của local host vào các struct socket. Tiện vì bạn khỏi phải
hard-code. (Hoặc bạn đặt một địa chỉ cụ thể vào làm tham số đầu của
`getaddrinfo()` chỗ tôi đang để `NULL` ở trên.)

Rồi ta gọi. Nếu có lỗi (`getaddrinfo()` trả về khác không), ta có thể
in ra bằng hàm `gai_strerror()`, như bạn thấy. Còn nếu mọi thứ đâu vào
đấy, `servinfo` sẽ trỏ tới một linked list của các `struct addrinfo`,
mỗi cái chứa một `struct sockaddr` nào đó để ta dùng sau này. Đỉnh!

Cuối cùng, khi ta xong việc với linked list mà `getaddrinfo()` đã tốt
bụng cấp phát cho, ta có thể (và nên) giải phóng hết bằng một cú gọi
`freeaddrinfo()`.

Đây là ví dụ nếu bạn là client muốn kết nối tới một server cụ thể, ví
dụ "www.example.net" port 3490. Lại nữa, cái này chưa thực sự kết nối,
chỉ chuẩn bị các struct để dùng sau:

```{.c .numberLines}
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // will point to the results

memset(&hints, 0, sizeof hints); // make sure the struct is empty
hints.ai_family = AF_UNSPEC;     // don't care IPv4 or IPv6
hints.ai_socktype = SOCK_STREAM; // TCP stream sockets

// get ready to connect
status = getaddrinfo("www.example.net", "3490", &hints, &servinfo);

// servinfo now points to a linked list of 1 or more
// struct addrinfos

// etc.
```

Tôi cứ nói mãi rằng `servinfo` là linked list với đủ loại thông tin
địa chỉ. Viết nhanh một chương trình demo để khoe thông tin đó nào.
[flx[Chương trình ngắn này|showip.c]] sẽ in địa chỉ IP của host nào bạn
nhập trên dòng lệnh:

```{.c .numberLines}
/*
** showip.c
**
** show IP addresses for a host given on the command line
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

int main(int argc, char *argv[])
{
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];

    if (argc != 2) {
        fprintf(stderr,"usage: showip hostname\n");
        return 1;
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;  // Either IPv4 or IPv6
    hints.ai_socktype = SOCK_STREAM;

    if ((status = getaddrinfo(argv[1], NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 2;
    }

    printf("IP addresses for %s:\n\n", argv[1]);

    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;
        struct sockaddr_in *ipv4;
        struct sockaddr_in6 *ipv6;

        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
            ipver = "IPv6";
        }

        // convert the IP to a string and print it:
        inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
        printf("  %s: %s\n", ipver, ipstr);
    }

    freeaddrinfo(res); // free the linked list
    return 0;
}
```

Như bạn thấy, code gọi `getaddrinfo()` trên bất kỳ thứ gì bạn truyền
vào dòng lệnh, hàm đó điền linked list được `res` trỏ tới, rồi ta duyệt
list và in ra hoặc làm gì tuỳ thích.

(Có một đoạn hơi xấu xí chỗ ta phải đào vào các loại `struct sockaddr`
khác nhau tuỳ phiên bản IP. Xin lỗi về chuyện đó! Tôi cũng không chắc
có cách nào khéo hơn.)

Chạy thử nào! Ai chả thích screenshot:

```
$ showip www.example.net
IP addresses for www.example.net:

  IPv4: 192.0.2.88

$ showip ipv6.example.com
IP addresses for ipv6.example.com:

  IPv4: 192.0.2.101
  IPv6: 2001:db8:8c00:22::171
```

Giờ đã có cái đó trong tay, ta sẽ dùng kết quả từ `getaddrinfo()` để
truyền sang các hàm socket khác, và rồi, cuối cùng, dựng được kết nối
mạng! Đọc tiếp đi!


## `socket()`: Lấy File Descriptor! {#socket}

Chắc không trì hoãn được nữa, tôi phải nói về system call
[i[`socket()` function]] `socket()`. Đây là bản phân tích:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int socket(int domain, int type, int protocol); 
```

Nhưng các tham số này là gì? Chúng cho phép bạn nói rõ muốn loại socket
nào (IPv4 hay IPv6, stream hay datagram, TCP hay UDP).

Ngày xưa người ta hard-code các giá trị này, và bạn vẫn hoàn toàn có
thể làm thế. (`domain` là `PF_INET` hoặc `PF_INET6`, `type` là
`SOCK_STREAM` hoặc `SOCK_DGRAM`, còn `protocol` có thể set là `0` để
chọn protocol phù hợp cho `type` đó. Hoặc bạn có thể gọi
`getprotobyname()` để tra protocol bạn muốn, "tcp" hay "udp".)

(Cái `PF_INET` này là họ hàng gần của [i[`AF_INET` macro]] `AF_INET`,
cái mà bạn dùng khi khởi tạo trường `sin_family` trong `struct
sockaddr_in`. Thực ra chúng gần nhau đến mức có cùng giá trị, và nhiều
lập trình viên gọi `socket()` rồi truyền `AF_INET` làm tham số đầu thay
vì `PF_INET`. Giờ lấy sữa và bánh quy ra đi, vì đến giờ kể chuyện. Ngày
xửa ngày xưa, người ta tưởng rằng một address family (cái mà "AF"
trong "`AF_INET`" là viết tắt) có thể hỗ trợ nhiều protocol, được gọi
bởi protocol family của chúng (cái mà "PF" trong "`PF_INET`" là viết
tắt). Chuyện đó không xảy ra. Và họ sống hạnh phúc bên nhau mãi mãi,
Hết. Nên cách đúng nhất là dùng `AF_INET` trong `struct sockaddr_in` và
`PF_INET` trong cú gọi `socket()`.)

Thôi, đủ rồi. Cái bạn thực sự muốn làm là dùng các giá trị từ kết quả
gọi `getaddrinfo()`, nhét thẳng vào `socket()` như thế này:

```{.c .numberLines}
int s;
struct addrinfo hints, *res;

// do the lookup
// [pretend we already filled out the "hints" struct]
getaddrinfo("www.example.com", "http", &hints, &res);

// again, you should do error-checking on getaddrinfo(), and walk
// the "res" linked list looking for valid entries instead of just
// assuming the first one is good (like many of these examples do).
// See the section on client/server for real examples.

s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
```

`socket()` chỉ trả về cho bạn một _socket descriptor_ để dùng trong các
system call sau, hoặc `-1` khi lỗi. Biến toàn cục `errno` được set
thành giá trị của lỗi (xem trang man [`errno`](#errnoman) để biết thêm,
và một ghi chú nhanh về việc dùng `errno` trong chương trình đa luồng).

Ổn, ổn, ổn, mà cái socket này được tích sự gì? Câu trả lời là bản thân
nó chả được tích sự gì, bạn phải đọc tiếp và gọi thêm system call thì
nó mới có nghĩa.


## `bind()`: Tôi đang ở port nào? {#bind}

[i[`bind()` function]] Khi đã có một socket, có thể bạn sẽ phải gắn nó
với một [i[Port]] port trên máy local. (Thường làm vậy nếu bạn chuẩn
bị [i[`listen()` function]] `listen()` đợi kết nối tới trên một port
cụ thể, game mạng nhiều người chơi làm vậy khi bảo bạn "kết nối tới
192.168.5.10 port 3490".) Số port được kernel dùng để ghép gói tin tới
với socket descriptor của một tiến trình cụ thể. Nếu bạn chỉ định
[i[`connect()`] function] `connect()` (vì bạn là client, không phải
server), cái này có lẽ không cần. Cứ đọc đi, cho vui.

Đây là tóm tắt của system call `bind()`:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int bind(int sockfd, struct sockaddr *my_addr, int addrlen);
```

`sockfd` là socket file descriptor do `socket()` trả về. `my_addr` là
con trỏ tới một `struct sockaddr` chứa thông tin địa chỉ của bạn, cụ
thể là port và [i[IP address]] địa chỉ IP. `addrlen` là độ dài tính
theo byte của địa chỉ đó.

Phù. Hơi nhiều để nuốt trong một lần. Xem ví dụ bind socket vào host mà
chương trình đang chạy, port 3490:

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

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// bind it to the port we passed in to getaddrinfo():

bind(sockfd, res->ai_addr, res->ai_addrlen);
```

Bằng việc dùng cờ `AI_PASSIVE`, tôi đang bảo chương trình bind vào IP
của host đang chạy nó. Nếu bạn muốn bind vào một địa chỉ IP local cụ
thể, bỏ `AI_PASSIVE` đi và đặt địa chỉ IP vào tham số đầu của
`getaddrinfo()`.

`bind()` cũng trả về `-1` khi lỗi và set `errno` thành giá trị lỗi.

Rất nhiều code cũ đóng gói `struct sockaddr_in` bằng tay trước khi gọi
`bind()`. Rõ ràng cái đó chỉ cho IPv4, nhưng thật ra chả có gì ngăn bạn
làm điều tương tự với IPv6, chỉ là dùng `getaddrinfo()` thường dễ hơn.
Dẫu sao, code cũ trông kiểu này:

```{.c .numberLines}
// !!! THIS IS THE OLD WAY !!!

int sockfd;
struct sockaddr_in my_addr;

sockfd = socket(PF_INET, SOCK_STREAM, 0);

my_addr.sin_family = AF_INET;
my_addr.sin_port = htons(MYPORT);     // short, network byte order
my_addr.sin_addr.s_addr = inet_addr("10.12.110.57");
memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);

bind(sockfd, (struct sockaddr *)&my_addr, sizeof my_addr);
```

Trong code trên, bạn cũng có thể gán `INADDR_ANY` vào trường `s_addr`
nếu muốn bind vào IP local của mình (giống như cờ `AI_PASSIVE` phía
trên). Phiên bản IPv6 của `INADDR_ANY` là một biến toàn cục
`in6addr_any` được gán vào trường `sin6_addr` của `struct
sockaddr_in6`. (Cũng có macro `IN6ADDR_ANY_INIT` bạn có thể dùng trong
khởi tạo biến.)

Thêm một cái nữa phải để ý khi gọi `bind()`: đừng đi quá thấp với số
port. [i[Port]] Mọi port dưới 1024 đều ĐƯỢC DỰ TRỮ (trừ khi bạn là
superuser)! Bạn có thể dùng bất cứ port nào trên đó, lên tới 65535
(miễn là chúng chưa bị chương trình khác dùng).

Đôi khi bạn sẽ để ý, bạn chạy lại server và `bind()` fail, báo [i[Address
already in use]] "Address already in use." Nghĩa là sao? Ờ, một mẩu
socket từng kết nối vẫn lảng vảng trong kernel, và nó đang giữ port.
Bạn có thể chờ cho nó thoáng ra (khoảng một phút), hoặc thêm code vào
chương trình để cho phép tái dùng port, kiểu này:

[i[`setsockopt()` function]]
 [i[`SO_REUSEADDR` macro]]

```{.c .numberLines}
int yes=1;
//char yes='1'; // Solaris people use this

// lose the pesky "Address already in use" error message
setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
```

[i[`bind()` function]] Một ghi chú nhỏ cuối cùng về `bind()`: có lúc
bạn không nhất thiết phải gọi. Nếu bạn đang
[i[`connect()` function]] `connect()` tới một máy từ xa và không quan
tâm local port của mình là bao nhiêu (như trường hợp `telnet`, bạn chỉ
quan tâm remote port), bạn chỉ cần gọi `connect()`, nó sẽ kiểm tra xem
socket đã được bind chưa, và sẽ `bind()` vào một local port chưa dùng
nếu cần.


## `connect()`: Này, bạn kia! {#connect}

[i[`connect()` function]] Giả sử vài phút thôi là bạn là ứng dụng
telnet. Người dùng ra lệnh cho bạn (y như trong phim [i[TRON]] _TRON_)
lấy một socket file descriptor. Bạn tuân theo và gọi `socket()`. Tiếp,
người dùng bảo bạn kết nối tới "`10.12.110.57`" trên port "`23`" (port
telnet chuẩn). Ối! Làm gì giờ?

May cho bạn, hỡi chương trình, bạn đang đọc phần về `connect()`, tức là
làm sao kết nối tới một host từ xa. Nên đọc tiếp cho cuồng nhiệt! Không
có thời gian để mất!

Cú gọi `connect()` như sau:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int connect(int sockfd, struct sockaddr *serv_addr, int addrlen); 
```

`sockfd` là socket file descriptor thân thiện hàng xóm của ta, do cú
gọi `socket()` trả về, `serv_addr` là một `struct sockaddr` chứa port
đích và địa chỉ IP, và `addrlen` là độ dài tính theo byte của cấu trúc
địa chỉ server.

Mọi thông tin này có thể lấy được từ kết quả của `getaddrinfo()`, thế
mới đỉnh.

Bắt đầu có nghĩa hơn chưa? Từ đây tôi không nghe được bạn, nên đành hy
vọng là có. Xem ví dụ tạo kết nối socket tới "`www.example.com`", port
`3490`:

```{.c .numberLines}
struct addrinfo hints, *res;
int sockfd;

// first, load up address structs with getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;
hints.ai_socktype = SOCK_STREAM;

getaddrinfo("www.example.com", "3490", &hints, &res);

// make a socket:

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// connect!

connect(sockfd, res->ai_addr, res->ai_addrlen);
```

Lại nữa, chương trình kiểu cũ tự điền `struct sockaddr_in` của mình để
truyền cho `connect()`. Bạn có thể làm thế nếu muốn. Xem ghi chú tương
tự trong [phần `bind()`](#bind) ở trên.

Nhớ kiểm tra giá trị trả về từ `connect()`, nó trả `-1` khi lỗi và set
biến `errno`.

[i[`bind()` function-->implicit]]

Cũng để ý ta không gọi `bind()`. Cơ bản, ta không quan tâm local port
của mình; ta chỉ quan tâm đi đâu (remote port). Kernel sẽ chọn một
local port giùm ta, và site ta kết nối tới sẽ tự nhận được thông tin
đó. Khỏi lo.


## `listen()`: Ai đó gọi tôi đi mà? {#listen}

[i[`listen()` function]] Rồi, đổi không khí tí. Nếu bạn không muốn kết
nối tới một host từ xa thì sao. Ví dụ cho vui, bạn muốn chờ các kết nối
tới và xử lý chúng theo cách nào đó. Quá trình có hai bước: trước tiên
`listen()`, rồi [i[`accept()` function]] `accept()` (xem dưới).

Cú gọi `listen()` khá đơn giản, nhưng cần giải thích tí:

```{.c}
int listen(int sockfd, int backlog); 
```

`sockfd` là socket file descriptor quen thuộc từ system call `socket()`.
[i[`listen()` function-->backlog]] `backlog` là số kết nối cho phép
trong hàng đợi tới. Nghĩa là sao? Các kết nối tới sẽ chờ trong hàng đợi
này cho đến khi bạn `accept()` (xem dưới), và đây là giới hạn bao nhiêu
cái được phép xếp hàng. Đa số hệ thống âm thầm giới hạn con số này ở
khoảng 20; bạn có thể an toàn với `5` hay `10`.

Lại như thường lệ, `listen()` trả `-1` và set `errno` khi lỗi.

Ừ, chắc bạn đoán được, ta cần gọi `bind()` trước khi gọi `listen()` để
server chạy trên một port cụ thể. (Phải báo cho đám bạn biết kết nối
vào port nào chứ!) Nên nếu bạn chuẩn bị lắng nghe kết nối tới, dãy
system call bạn sẽ gọi là:

```{.c .numberLines}
getaddrinfo();
socket();
bind();
listen();
/* accept() goes here */ 
```

Tôi để đây thay cho code mẫu, vì nó cũng tự giải thích rồi. (Code trong
phần `accept()` dưới đây đầy đủ hơn.) Phần khó nhất của cả cái mớ này
là cú gọi `accept()`.


## `accept()`: "Cảm ơn đã gọi port 3490."

[i[`accept()` function]] Sẵn sàng chưa, cú gọi `accept()` hơi kỳ kỳ!
Chuyện xảy ra như vầy: ai đó xa tít tắp sẽ cố `connect()` tới máy bạn
trên một port bạn đang `listen()`. Kết nối của họ sẽ được xếp hàng chờ
được `accept()`. Bạn gọi `accept()` và bảo nó lấy kết nối đang chờ. Nó
sẽ trả về cho bạn _một socket file descriptor mới toanh_ để dùng cho
kết nối đơn lẻ này! Đúng vậy, tự nhiên bạn có _hai socket file
descriptor_ với giá một! Cái gốc vẫn tiếp tục lắng nghe các kết nối mới,
còn cái vừa tạo đã sẵn sàng để `send()` và `recv()`. Tới đích rồi!

Cú gọi như sau:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen); 
```

`sockfd` là socket descriptor đang `listen()`. Dễ thôi. `addr` thường
là con trỏ tới một `struct sockaddr_storage` cục bộ. Đây là nơi thông
tin về kết nối tới sẽ được đặt (và cùng với nó bạn xác định được host
nào đang gọi mình từ port nào). `addrlen` là một biến `int` cục bộ,
nên được set bằng `sizeof(struct sockaddr_storage)` trước khi địa chỉ
của nó được truyền cho `accept()`. `accept()` sẽ không nhét quá bấy
nhiêu byte vào `addr`. Nếu nó nhét ít hơn, nó sẽ đổi giá trị `addrlen`
cho khớp.

Đoán xem? `accept()` trả `-1` và set `errno` khi có lỗi. Cá là bạn đoán
ra rồi.

Như trước, đây là cả đống để nuốt một lần, nên có một mẩu code mẫu
dưới đây cho bạn ngẫm:

```{.c .numberLines}
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#define MYPORT "3490"  // the port users will be connecting to
#define BACKLOG 10     // how many pending connections queue holds

int main(void)
{
    struct sockaddr_storage their_addr;
    socklen_t addr_size;
    struct addrinfo hints, *res;
    int sockfd, new_fd;

    // !! don't forget your error checking for these calls !!

    // first, load up address structs with getaddrinfo():

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

    getaddrinfo(NULL, MYPORT, &hints, &res);

    // make a socket, bind it, and listen on it:

    sockfd = socket(res->ai_family, res->ai_socktype,
                                                 res->ai_protocol);
    bind(sockfd, res->ai_addr, res->ai_addrlen);
    listen(sockfd, BACKLOG);

    // now accept an incoming connection:

    addr_size = sizeof their_addr;
    new_fd = accept(sockfd, (struct sockaddr *)&their_addr,
                                                       &addr_size);

    // ready to communicate on socket descriptor new_fd!
    .
    .
    .
```

Lại nữa, để ý ta sẽ dùng socket descriptor `new_fd` cho mọi cú gọi
`send()` và `recv()`. Nếu bạn chỉ nhận đúng một kết nối duy nhất, bạn
có thể `close()` cái `sockfd` đang lắng nghe để chặn thêm kết nối tới
cùng port, nếu bạn muốn.


## `send()` và `recv()`: Nói với tôi đi, cưng! {#sendrecv}

Hai hàm này để giao tiếp qua stream socket hoặc datagram socket đã
connect. Nếu bạn muốn dùng datagram socket bình thường chưa connect,
bạn cần xem phần [`sendto()` và `recvfrom()`](#sendtorecv) bên dưới.

> [i[Blocking]] Đây là điều có thể (hoặc không) mới với bạn: mấy cú
> này là các cú gọi _blocking_. Tức là `recv()` sẽ _block_ cho tới khi
> có dữ liệu sẵn để nhận. "Mà 'block' là cái quái gì đã?!" Nghĩa là
> chương trình của bạn sẽ dừng ngay đó, trên cái system call đó, cho
> tới khi ai đó gửi bạn gì đó. (Thuật ngữ dân OS dùng cho "dừng" trong
> câu trên thực ra là _sleep_, nên tôi có thể dùng hai từ đó thay
> nhau.) `send()` cũng có thể block nếu thứ bạn đang gửi bị tắc ở đâu
> đó, nhưng hiếm hơn. Ta sẽ [quay lại khái niệm này sau](#blocking), và
> nói về cách tránh khi cần.

[i[`send()` function]] Đây là cú gọi `send()`:

```{.c}
int send(int sockfd, const void *msg, int len, int flags); 
```

`sockfd` là socket descriptor bạn muốn gửi dữ liệu tới (cho dù là cái
do `socket()` trả về hay cái lấy từ `accept()`). `msg` là con trỏ tới
dữ liệu bạn muốn gửi, và `len` là độ dài dữ liệu đó theo byte. Cứ set
`flags` bằng `0`. (Xem trang man `send()` để biết thêm về flags.)

Một đoạn code mẫu:

```{.c .numberLines}
char *msg = "Beej was here!";
int len, bytes_sent;
.
.
.
len = strlen(msg);
bytes_sent = send(sockfd, msg, len, 0);
.
.
. 
```

`send()` trả về số byte thực sự được gửi đi. _Con số này có thể ít hơn
số bạn bảo nó gửi!_ Đúng rồi, đôi khi bạn bảo nó gửi cả một đống dữ
liệu mà nó không kham nổi. Nó sẽ bắn đi được bao nhiêu dữ liệu thì bắn,
và tin rằng bạn sẽ gửi nốt phần còn lại sau. Nhớ nhé, nếu giá trị
`send()` trả về không khớp với `len`, bạn phải tự gửi nốt phần còn lại
của chuỗi. Tin vui: nếu gói tin nhỏ (dưới khoảng 1K), _thường_ nó sẽ
gửi hết được cả lần. Lại nữa, `-1` được trả về khi lỗi, và `errno`
được set thành mã lỗi.

[i[`recv()` function]] Cú gọi `recv()` giống ở nhiều điểm:

```{.c}
int recv(int sockfd, void *buf, int len, int flags);
```

`sockfd` là socket descriptor để đọc, `buf` là buffer để đọc thông tin
vào, `len` là độ dài tối đa của buffer, và `flags` lại có thể set bằng
`0`. (Xem trang man `recv()` để biết về flags.)

`recv()` trả về số byte thực sự được đọc vào buffer, hoặc `-1` khi lỗi
(với `errno` được set tương ứng).

Khoan! `recv()` có thể trả `0`. Chuyện này chỉ có một nghĩa duy nhất:
đầu bên kia đã đóng kết nối với bạn! Trả về `0` là cách `recv()` báo
cho bạn biết điều đó đã xảy ra.

Đấy, dễ mà, phải không? Giờ bạn đã có thể đưa dữ liệu qua lại trên
stream socket! Yay! Bạn đã là Lập Trình Viên Mạng Unix!


## `sendto()` và `recvfrom()`: Nói với tôi đi, kiểu DGRAM {#sendtorecv}

[i[`SOCK_DGRAM` macro]] "Tất cả nghe hay ho," tôi nghe bạn nói, "nhưng
với datagram socket chưa connect thì sao?" Không vấn đề, amigo. Có
ngay đây.

Vì datagram socket không gắn với một host từ xa, đoán xem mẩu thông tin
nào ta cần đưa vào trước khi gửi gói? Đúng rồi! Địa chỉ đích! Đây là
bức tranh:

```{.c}
int sendto(int sockfd, const void *msg, int len, unsigned int flags,
           const struct sockaddr *to, socklen_t tolen); 
```

Như bạn thấy, cú gọi này về cơ bản giống `send()` cộng thêm hai mẩu
thông tin. `to` là con trỏ tới một `struct sockaddr` (có lẽ là một
`struct sockaddr_in` hay `struct sockaddr_in6` hay `struct
sockaddr_storage` bạn ép kiểu vào phút chót) chứa [i[IP address]] địa
chỉ IP đích và [i[Port]] port. `tolen`, sâu bên trong là một `int`, có
thể chỉ cần set là `sizeof *to` hoặc `sizeof(struct sockaddr_storage)`.

Để có cấu trúc địa chỉ đích trong tay, bạn có thể lấy từ
`getaddrinfo()`, hoặc từ `recvfrom()` dưới đây, hoặc tự điền bằng
tay.

Y như `send()`, `sendto()` trả về số byte thực sự được gửi (lại nữa,
có thể ít hơn số byte bạn bảo nó gửi!), hoặc `-1` khi lỗi.

Y hệt là `recv()` và [i[`recvfrom()` function]] `recvfrom()`. Tóm tắt
của `recvfrom()` là:

```{.c}
int recvfrom(int sockfd, void *buf, int len, unsigned int flags,
             struct sockaddr *from, int *fromlen); 
```

Lại nữa, cái này giống `recv()` cộng thêm vài trường. `from` là con trỏ
tới một [i[`struct sockaddr` type]] `struct sockaddr_storage` cục bộ
sẽ được điền địa chỉ IP và port của máy nguồn. `fromlen` là con trỏ
tới một `int` cục bộ, nên được khởi tạo bằng `sizeof *from` hoặc
`sizeof(struct sockaddr_storage)`. Khi hàm trả về, `fromlen` sẽ chứa
độ dài của địa chỉ thực sự được lưu trong `from`.

`recvfrom()` trả về số byte đã nhận, hoặc `-1` khi lỗi (với `errno`
được set tương ứng).

Có một câu hỏi: tại sao ta dùng `struct sockaddr_storage` làm kiểu
socket? Sao không `struct sockaddr_in`? Vì, bạn thấy đó, ta không muốn
buộc mình vào IPv4 hay IPv6. Nên ta dùng `struct sockaddr_storage`
chung chung, đủ to cho cả hai.

(Rồi... câu hỏi nữa: sao `struct sockaddr` không đủ to cho mọi địa
chỉ? Ta còn ép kiểu cái `struct sockaddr_storage` chung chung về cái
`struct sockaddr` chung chung! Có vẻ dư thừa phải không? Câu trả lời
là, nó không đủ to, và tôi đoán đổi nó ở thời điểm này sẽ Rắc Rối. Nên
người ta làm cái mới.)

Nhớ nhé, nếu bạn [i[`connect()` function-->on datagram sockets]]
`connect()` một datagram socket, bạn có thể đơn giản dùng `send()` và
`recv()` cho mọi giao dịch. Bản thân socket vẫn là datagram socket và
gói tin vẫn dùng UDP, nhưng interface socket sẽ tự động thêm thông tin
đích và nguồn giùm bạn.


## `close()` và `shutdown()`: Biến khỏi mặt tôi đi!

Phù! Bạn đã `send()` và `recv()` dữ liệu cả ngày, và đã đủ rồi. Bạn sẵn
sàng đóng kết nối trên socket descriptor của mình. Dễ ợt. Bạn chỉ cần
dùng hàm [i[`close()` function]] `close()` file descriptor Unix thường
dùng:

```{.c}
close(sockfd); 
```

Cái này sẽ chặn mọi lần đọc và ghi tiếp tới socket. Ai đó cố đọc hay
ghi socket ở đầu từ xa sẽ nhận được lỗi.

Phòng khi bạn muốn kiểm soát chút nữa cách socket đóng, bạn có thể
dùng hàm [i[`shutdown()` function]] `shutdown()`. Nó cho phép bạn cắt
giao tiếp theo một hướng nhất định, hoặc cả hai (giống như `close()`).
Tóm tắt:

```{.c}
int shutdown(int sockfd, int how); 
```

`sockfd` là socket file descriptor bạn muốn shutdown, và `how` là một
trong các giá trị sau:

| `how` | Tác dụng                                                   |
|:-----:|------------------------------------------------------------|
|  `0`  | Không cho nhận thêm nữa                                    |
|  `1`  | Không cho gửi thêm nữa                                     |
|  `2`  | Không cho gửi lẫn nhận thêm nữa (giống `close()`)          |

`shutdown()` trả về `0` khi thành công, và `-1` khi lỗi (với `errno`
được set tương ứng).

Nếu bạn chịu khó dùng `shutdown()` trên datagram socket chưa connect,
nó chỉ làm socket không còn dùng được cho các cú gọi `send()` và
`recv()` tiếp theo (nhớ là bạn có thể dùng chúng nếu đã `connect()`
datagram socket của mình).

Lưu ý quan trọng, `shutdown()` không thực sự đóng file descriptor, nó
chỉ đổi khả năng dùng của nó. Để giải phóng một socket descriptor, bạn
cần dùng `close()`.

Không có gì cả.

(Trừ việc nhớ rằng nếu bạn dùng [i[Windows]] Windows và [i[Winsock]]
Winsock thì nên gọi [i[`closesocket()` function]] `closesocket()` thay
vì `close()`.)


## `getpeername()`: Bạn là ai?

[i[`getpeername()` function]] Hàm này dễ cực.

Dễ đến mức tôi suýt không cho nó nguyên một phần. Nhưng thôi cứ để
đây.

Hàm `getpeername()` sẽ cho bạn biết ai ở đầu bên kia của một stream
socket đã kết nối. Tóm tắt:

```{.c}
#include <sys/socket.h>

int getpeername(int sockfd, struct sockaddr *addr, int *addrlen); 
```

`sockfd` là descriptor của stream socket đã kết nối, `addr` là con trỏ
tới một `struct sockaddr` (hoặc `struct sockaddr_in`) sẽ giữ thông tin
về đầu kia của kết nối, và `addrlen` là con trỏ tới một `int`, nên
được khởi tạo bằng `sizeof *addr` hoặc `sizeof(struct sockaddr)`.

Hàm trả `-1` khi lỗi và set `errno` tương ứng.

Khi đã có địa chỉ của họ, bạn có thể dùng [i[`inet_ntop()` function]]
`inet_ntop()`, [i[`getnameinfo()` function]] `getnameinfo()`, hoặc
[i[`gethostbyaddr()` function]] `gethostbyaddr()` để in ra hoặc lấy
thêm thông tin. Không, bạn không thể lấy được tên login của họ. (Thôi
được, được. Nếu máy kia chạy một ident daemon, thì làm được. Tuy nhiên,
cái đó vượt quá phạm vi tài liệu này. Xem [flrfc[RFC 1413|1413]] để
biết thêm.)


## `gethostname()`: Tôi là ai?

[i[`gethostname()` function]] Còn dễ hơn cả `getpeername()` là hàm
`gethostname()`. Nó trả về tên của máy tính mà chương trình của bạn
đang chạy. Tên này có thể được dùng bởi [i[`getaddrinfo()` function]]
`getaddrinfo()` ở trên, để xác định [i[IP address]] địa chỉ IP của máy
local.

Còn gì vui hơn? Tôi nghĩ ra được vài thứ, nhưng chúng không liên quan
tới lập trình socket. Dẫu sao, đây là bản phân tích:

```{.c}
#include <unistd.h>

int gethostname(char *hostname, size_t size); 
```

Các tham số đơn giản: `hostname` là con trỏ tới một mảng char sẽ chứa
hostname sau khi hàm trả về, và `size` là độ dài theo byte của mảng
`hostname`.

Hàm trả về `0` khi thành công, và `-1` khi lỗi, set `errno` như thường
lệ.
