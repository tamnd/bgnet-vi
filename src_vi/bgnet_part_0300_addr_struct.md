# Địa chỉ IP, `struct`, và xử lý dữ liệu

Đến đoạn mà chúng ta được ngồi nói chuyện code cho khác đi chút.

Nhưng trước tiên, nói thêm tí về phần không phải code nhé! Tuyệt vời! Tôi
muốn nói một chút về [i[IP address]] địa chỉ IP và port để chúng ta gọn
được phần đó. Rồi tới chuyện sockets API lưu trữ và thao tác với địa chỉ
IP cùng dữ liệu khác ra sao.


## Địa chỉ IP, phiên bản 4 và 6

Ngày xưa ơi là xưa, hồi Ben Kenobi còn được gọi là Obi Wan Kenobi, có
một hệ thống định tuyến mạng tuyệt vời tên là The Internet Protocol
Version 4, còn gọi là [i[IPv4]] IPv4. Địa chỉ của nó gồm bốn byte (hay
còn gọi là bốn "octet"), và thường được viết dưới dạng "chấm và số", kiểu
như: `192.0.2.111`.

Chắc bạn cũng thấy nó đâu đó rồi.

Thực tế là tính đến thời điểm viết bài này, gần như mọi site trên
Internet đều dùng IPv4.

Mọi người, kể cả Obi Wan, đều vui vẻ. Mọi thứ đều ổn, cho đến khi một
người hay dội nước lạnh tên Vint Cerf cảnh báo tất cả rằng chúng ta sắp
cạn địa chỉ IPv4!

(Ngoài việc cảnh báo mọi người về Ngày Tận Thế IPv4 Đang Tới Trong Khói
Lửa Đau Thương, [i[Vint Cerf]] [flw[Vint Cerf|Vint_Cerf]] còn nổi tiếng là
Cha Đẻ Của Internet. Nên thực sự tôi cũng không ở vị trí đủ tầm để nghi
ngờ phán đoán của ông.)

Cạn địa chỉ? Sao có thể thế được? Ý tôi là, có tới mấy tỷ địa chỉ IP
trong một địa chỉ IPv4 32-bit. Chả lẽ thực sự có mấy tỷ máy tính ngoài
kia?

Có.

Thêm nữa, lúc ban đầu, khi còn rất ít máy tính và ai cũng nghĩ một tỷ là
con số lớn không tưởng, một số tổ chức lớn đã được cấp hào phóng hàng
triệu địa chỉ IP để dùng riêng. (Như Xerox, MIT, Ford, HP, IBM, GE, AT&T,
và một công ty nhỏ bé gọi là Apple, chỉ kể vài cái.)

Thực ra, nếu không có mấy giải pháp chữa cháy, chúng ta đã cạn từ đời nào
rồi.

Nhưng giờ chúng ta đang ở cái thời mà ai cũng nói mỗi con người sẽ có
một địa chỉ IP, mỗi máy tính, mỗi cái máy tính bỏ túi, mỗi cái điện
thoại, mỗi cái đồng hồ đỗ xe, và (tại sao không) mỗi con chó con nữa.

Và thế là [i[IPv6]] IPv6 ra đời. Vì Vint Cerf chắc là bất tử (kể cả phần
xác có ra đi, lạy trời đừng, thì chắc ông cũng đã tồn tại dưới dạng một
chương trình [flw[ELIZA|ELIZA]] siêu thông minh nào đó lang thang trong
Internet2), không ai muốn nghe ông nói lại "tôi đã bảo rồi" nếu chúng ta
lại hết địa chỉ trong phiên bản tiếp theo của Internet Protocol.

Điều này gợi cho bạn cái gì?

Là chúng ta cần _rất nhiều_ địa chỉ hơn. Không phải gấp đôi, không phải
gấp một tỷ lần, không phải gấp nghìn nghìn tỷ lần, mà _nhiều gấp 79 TRIỆU
TỶ TỶ lần số địa chỉ khả dĩ!_ Xem đứa nào đòi cạn nữa nào!

Bạn sẽ hỏi, "Beej ơi, thật không? Tôi có mọi lý do để không tin mấy con
số khổng lồ." Ờ, khác biệt giữa 32 bit và 128 bit nghe cũng không ghê
gớm; chỉ thêm 96 bit thôi mà phải không? Nhưng nhớ là ta đang nói về lũy
thừa: 32 bit biểu diễn khoảng 4 tỷ số (2^32^), còn 128 bit biểu diễn
khoảng 340 nghìn tỷ nghìn tỷ nghìn tỷ số (thật đấy, 2^128^). Cỡ bằng một
triệu Internet IPv4 cho _mỗi ngôi sao trong Vũ Trụ_.

Quên luôn cái kiểu chấm và số của IPv4 đi; giờ chúng ta có biểu diễn
dạng hexa, mỗi cụm hai byte cách nhau bởi dấu hai chấm, kiểu như:

``` {.default}
2001:0db8:c9d2:aee5:73e3:934a:a5ae:9551
```

Chưa hết! Rất nhiều lần bạn sẽ gặp địa chỉ IP có nhiều số 0, và bạn có
thể nén chúng lại giữa hai dấu hai chấm. Bạn cũng có thể bỏ các số 0 đầu
của mỗi cặp byte. Ví dụ, từng cặp địa chỉ sau là tương đương:

``` {.default}
2001:0db8:c9d2:0012:0000:0000:0000:0051
2001:db8:c9d2:12::51

2001:0db8:ab00:0000:0000:0000:0000:0000
2001:db8:ab00::

0000:0000:0000:0000:0000:0000:0000:0001
::1
```

Địa chỉ `::1` là _địa chỉ loopback_. Nó luôn có nghĩa là "cái máy tôi
đang chạy ngay bây giờ". Trong IPv4, địa chỉ loopback là `127.0.0.1`.

Cuối cùng, có một chế độ tương thích IPv4 dành cho địa chỉ IPv6 mà bạn
có thể bắt gặp. Ví dụ muốn biểu diễn địa chỉ IPv4 `192.0.2.33` dưới dạng
địa chỉ IPv6, bạn viết thế này: "`::ffff:192.0.2.33`".

Đang vui ra trò đấy.

Thực ra vui đến mức mấy Người Sáng Tạo Ra IPv6 đã lơ là bỏ đi cả nghìn
tỷ nghìn tỷ địa chỉ để dành cho các mục đích dự trữ, nhưng nói thật,
chúng ta có quá trời địa chỉ, ai thèm đếm làm gì nữa? Vẫn còn dư đủ cho
mỗi người đàn ông, phụ nữ, trẻ em, chó con, và đồng hồ đỗ xe trên mỗi
hành tinh trong thiên hà. Và tin tôi đi, mỗi hành tinh trong thiên hà đều
có đồng hồ đỗ xe. Bạn biết điều đó là thật mà.


### Subnet

Vì lý do tổ chức, đôi khi sẽ tiện nếu ta tuyên bố rằng "phần đầu của địa
chỉ IP này tính đến bit đây là _phần network_ của địa chỉ IP, còn phần
còn lại là _phần host_".

Ví dụ, với IPv4, bạn có `192.0.2.12`, và ta có thể nói ba byte đầu là
network còn byte cuối là host. Hay nói cách khác, ta đang nói về host
`12` trên network `192.0.2.0` (để ý cách ta zero byte host).

Giờ đến phần thông tin lỗi thời hơn! Sẵn sàng chưa? Thời Thượng Cổ, có
các "class" subnet, trong đó một, hai, hoặc ba byte đầu của địa chỉ là
phần network. Nếu bạn may mắn có một byte cho network và ba byte cho
host, bạn có tới 24 bit host trên network của mình (khoảng 16 triệu). Đó
là network "Class A". Ngược lại là "Class C", với ba byte network và một
byte host (256 host, trừ đi vài cái bị dự trữ).

Nên như bạn thấy, có rất ít Class A, một đống Class C, và một ít Class B
ở giữa.

Phần network của địa chỉ IP được mô tả bằng thứ gọi là _netmask_, bạn
AND bit với địa chỉ IP để lấy ra số network. Netmask thường trông kiểu
như `255.255.255.0`. (Ví dụ với netmask đó, nếu IP của bạn là
`192.0.2.12`, thì network của bạn là `192.0.2.12` AND `255.255.255.0`
cho ra `192.0.2.0`.)

Tiếc là, hóa ra kiểu này không đủ tinh gọn cho nhu cầu cuối cùng của
Internet; chúng ta cạn network Class C khá nhanh, và Class A thì thôi
khỏi hỏi. Để khắc phục, Các Thế Lực Có Quyền Năng đã cho phép netmask
dùng số bit tuỳ ý, không chỉ 8, 16, hay 24. Vậy nên bạn có thể có netmask
kiểu `255.255.255.252`, nghĩa là 30 bit network và 2 bit host, cho phép
bốn host trên network. (Lưu ý netmask _LUÔN_ là một dãy bit 1 theo sau
là một dãy bit 0.)

Nhưng dùng chuỗi số dài ngoằng kiểu `255.192.0.0` làm netmask thì cũng
hơi bất tiện. Thứ nhất, người ta không có khái niệm trực quan đó là bao
nhiêu bit, thứ hai, nó không gọn tí nào. Nên Kiểu Mới ra đời, và nó đẹp
hơn nhiều. Bạn chỉ cần đặt một dấu gạch chéo sau địa chỉ IP, rồi theo sau
là số bit network ở dạng thập phân. Như thế này: `192.0.2.12/30`.

Hoặc với IPv6, kiểu thế này: `2001:db8::/32` hay
`2001:db8:5413:4028::9db9/64`.


### Số port

Nếu bạn còn nhớ, tôi đã giới thiệu [Mô hình Mạng Phân Lớp](#lowlevel)
trong đó Internet Layer (IP) được tách khỏi Host-to-Host Transport Layer
(TCP và UDP). Lướt lại đoạn đó trước khi qua đoạn tiếp theo nhé.

Hoá ra ngoài địa chỉ IP (tầng IP dùng), còn một địa chỉ nữa được TCP
(stream socket) dùng, và tiện thể cả UDP (datagram socket) cũng dùng. Đó
là _số port_. Nó là một số 16-bit, giống như địa chỉ cục bộ cho một kết
nối.

Hãy nghĩ địa chỉ IP như địa chỉ đường của một khách sạn, và số port như
số phòng. Cũng là một phép so sánh được; có khi lúc khác tôi sẽ nghĩ ra
một phép liên quan đến ngành công nghiệp ô tô.

Giả sử bạn muốn có một máy tính vừa xử lý mail đến VÀ dịch vụ web, làm
sao phân biệt hai dịch vụ trên một máy chỉ có một địa chỉ IP?

Ờ, các dịch vụ khác nhau trên Internet có các số port well-known khác
nhau. Bạn có thể xem hết trong [fl[Bảng Port Khổng Lồ Của
IANA|https://www.iana.org/assignments/port-numbers]] hoặc, nếu bạn dùng
Unix, trong file `/etc/services`. HTTP (web) là port 80, telnet là port
23, SMTP là port 25, game
[fl[DOOM|https://en.wikipedia.org/wiki/Doom_%281993_video_game%29]] dùng
port 666, vân vân. Port dưới 1024 thường được coi là đặc biệt, và thường
đòi hỏi quyền đặc biệt từ OS để dùng.

Và tạm vậy thôi!


## Byte Order

[i[Byte ordering]] Theo Lệnh Của Vương Quốc! Sẽ có hai thứ tự byte, từ
nay về sau được biết tới với tên gọi Chuối Lè và Hoành Tráng!

Tôi đùa thôi, nhưng thực sự một trong hai cái tốt hơn cái kia. `:-)`

Thật sự chả có cách nào nhẹ nhàng để nói, nên tôi cứ phun ra thẳng: máy
tính của bạn có thể đã đang lưu byte ngược chiều sau lưng bạn. Tôi biết!
Chả ai muốn phải nói ra.

Vấn đề là, mọi người trong thế giới Internet đã thống nhất chung rằng
nếu bạn muốn biểu diễn số hex hai byte, chẳng hạn `b34f`, bạn sẽ lưu nó
thành hai byte liên tiếp, `b3` rồi tới `4f`. Hợp lý, và như [fl[Wilford
Brimley|https://en.wikipedia.org/wiki/Wilford_Brimley]] sẽ nói với bạn,
đây là Cách Làm Đúng Đắn. Số này, với đầu lớn đứng trước, được gọi là
_Big-Endian_.

Khổ nỗi, _vài_ máy tính rải rác đây đó trên thế giới, cụ thể là những
máy chạy vi xử lý Intel hoặc tương thích Intel, lưu byte theo kiểu đảo
ngược, nên `b34f` sẽ được lưu trong bộ nhớ dưới dạng hai byte liên tiếp
`4f` rồi `b3`. Cách lưu này gọi là _Little-Endian_.

Nhưng khoan, tôi chưa xong chuyện thuật ngữ! Cái _Big-Endian_ tỉnh táo
hơn còn được gọi là _Network Byte Order_ vì đó là thứ tự mà dân mạng
chúng tôi khoái.

Máy của bạn lưu số theo _Host Byte Order_. Nếu là Intel 80x86, Host Byte
Order là Little-Endian. Nếu là Motorola 68k, Host Byte Order là
Big-Endian. Nếu là PowerPC, Host Byte Order là... ờ, tuỳ!

Nhiều lúc lúc xây gói tin hoặc điền struct dữ liệu, bạn sẽ cần chắc chắn
các số hai và bốn byte của mình ở dạng Network Byte Order. Nhưng làm sao
làm được điều đó nếu bạn không biết Host Byte Order gốc là gì?

Tin vui! Bạn cứ mặc định là Host Byte Order không đúng, rồi cứ đưa giá
trị qua một hàm để chuyển về Network Byte Order. Hàm sẽ làm phép màu
chuyển đổi nếu cần, và như vậy code của bạn khả chuyển giữa các máy với
endianness khác nhau.

Được rồi. Có hai kiểu số bạn có thể chuyển đổi: `short` (hai byte) và
`long` (bốn byte). Các hàm này cũng chạy được với biến thể `unsigned`.
Giả sử bạn muốn chuyển một `short` từ Host Byte Order sang Network Byte
Order. Bắt đầu bằng "h" cho "host", nối thêm "to", rồi "n" cho "network",
và "s" cho "short": h-to-n-s, hay `htons()` (đọc: "Host to Network
Short").

Đơn giản đến mức gần như quá đà...

Bạn có thể dùng mọi kết hợp của "n", "h", "s", và "l" mà bạn muốn, không
tính mấy cái ngớ ngẩn. Ví dụ, KHÔNG có hàm `stolh()` ("Short to Long
Host"), ít nhất là không có ở bữa tiệc này. Nhưng có:

[[book-pagebreak]]

| Hàm       | Mô tả                         |
|-----------|-------------------------------|
| [i[`htons()` function]]`htons()` | `h`ost `to` `n`etwork `s`hort |
| [i[`htonl()` function]]`htonl()` | `h`ost `to` `n`etwork `l`ong  |
| [i[`ntohs()` function]]`ntohs()` | `n`etwork `to` `h`ost `s`hort |
| [i[`ntohl()` function]]`ntohl()` | `n`etwork `to` `h`ost `l`ong  |

Nói chung, bạn sẽ muốn chuyển các số sang Network Byte Order trước khi
chúng ra đường dây, và chuyển về Host Byte Order khi chúng vào từ đường
dây.

Sockets API không có biến thể 64-bit chuẩn, nhưng tôi có nói về các lựa
chọn khác trong [trang tham khảo `htons()`](#htonsman). Còn nếu bạn muốn
làm việc với số thực dấu chấm động, xem phần
[Serialization](#serialization), ở tít phía dưới.

Cứ coi các số trong tài liệu này là ở dạng Host Byte Order trừ khi tôi
nói khác.


## `struct` {#structs}

Ờ, cuối cùng cũng tới. Tới lúc nói chuyện lập trình. Trong phần này, tôi
sẽ giới thiệu các kiểu dữ liệu được sockets interface dùng, vì một số
trong đó đúng là khó nhằn.

Đầu tiên là cái dễ: [i[Socket descriptor]] socket descriptor. Một socket
descriptor là kiểu sau:

```{.c}
int
```

Chỉ là `int` bình thường.

Từ đây đi bắt đầu lạ hơn, nên cứ đọc tiếp và kiên nhẫn với tôi tí.

Struct đầu tiên của tôi™, `struct addrinfo`. [i[`struct addrinfo` type]]
Struct này là phát minh tương đối gần đây, dùng để chuẩn bị các struct
địa chỉ socket cho các lần dùng sau. Nó cũng dùng trong tra tên máy và
tra tên dịch vụ. Chỗ đó sẽ dễ hiểu hơn khi chúng ta tới phần dùng thực
tế, nhưng tạm biết rằng đây là một trong những thứ đầu tiên bạn gọi khi
tạo kết nối.

```{.c}
struct addrinfo {
    int              ai_flags;     // AI_PASSIVE, AI_CANONNAME, etc.
    int              ai_family;    // AF_INET, AF_INET6, AF_UNSPEC
    int              ai_socktype;  // SOCK_STREAM, SOCK_DGRAM
    int              ai_protocol;  // use 0 for "any"
    size_t           ai_addrlen;   // size of ai_addr in bytes
    struct sockaddr *ai_addr;      // struct sockaddr_in or _in6
    char            *ai_canonname; // full canonical hostname

    struct addrinfo *ai_next;      // linked list, next node
};
```

Bạn sẽ điền struct này một chút, rồi gọi [i[`getaddrinfo()` function]]
`getaddrinfo()`. Nó sẽ trả về con trỏ tới một linked list mới của các
struct này đã được điền sẵn mọi thứ bạn cần.

Bạn có thể ép nó dùng IPv4 hoặc IPv6 bằng trường `ai_family`, hoặc để
`AF_UNSPEC` để dùng cái nào cũng được. Như vậy tiện vì code của bạn có
thể bất kể phiên bản IP.

Để ý rằng đây là linked list: `ai_next` trỏ tới phần tử kế tiếp, có thể
có nhiều kết quả để bạn chọn. Tôi sẽ dùng kết quả đầu tiên chạy được,
nhưng bạn có thể có nhu cầu kinh doanh khác; biết gì đâu mà nói, ông ơi!

Bạn sẽ thấy trường `ai_addr` trong `struct addrinfo` là con trỏ tới
[i[`struct sockaddr` type]] `struct sockaddr`. Đây là chỗ ta bắt đầu đi
vào chi tiết cặn kẽ bên trong một struct địa chỉ IP.

Bạn thường không cần ghi trực tiếp vào những struct này; đa số trường
hợp, một cuộc gọi tới `getaddrinfo()` để điền `struct addrinfo` giúp bạn
là đủ. Tuy nhiên, bạn _sẽ_ phải ngó vào bên trong các `struct` này để
lấy các giá trị ra, nên tôi giới thiệu chúng ở đây.

(Thêm nữa, mọi code viết trước khi `struct addrinfo` ra đời đều đóng gói
đống này bằng tay, nên bạn sẽ thấy nhiều code IPv4 ngoài đời làm đúng y
vậy. Kiểu, trong các phiên bản cũ của tài liệu này chẳng hạn.)

Một số `struct` là IPv4, một số là IPv6, và một số cả hai. Tôi sẽ ghi
chú cái nào là cái nào.

Dù sao thì, `struct sockaddr` giữ thông tin địa chỉ socket cho nhiều kiểu
socket.

```{.c}
struct sockaddr {
    unsigned short    sa_family;    // address family, AF_xxx
    char              sa_data[14];  // 14 bytes of protocol address
}; 
```

`sa_family` có thể là nhiều thứ, nhưng với mọi thứ ta làm trong tài liệu
này nó sẽ là [i[`AF_INET` macro]] `AF_INET` (IPv4) hoặc [i[`AF_INET6`
macro]] `AF_INET6` (IPv6). `sa_data` chứa địa chỉ đích và số port cho
socket. Cái này khá khó chịu vì bạn chẳng muốn tỉ mẩn đóng gói địa chỉ
vào `sa_data` bằng tay.

Để xử lý `struct sockaddr`, các lập trình viên tạo ra một cấu trúc song
song: [i[`struct sockaddr` type]] `struct sockaddr_in` ("in" cho
"Internet") dùng cho IPv4.

Và _đây là đoạn quan trọng_: một con trỏ tới `struct sockaddr_in` có thể
ép kiểu thành con trỏ tới `struct sockaddr` và ngược lại. Nên dù
`connect()` cần `struct sockaddr*`, bạn vẫn cứ dùng `struct sockaddr_in`
và ép kiểu ở phút cuối!

```{.c}
// (Chỉ IPv4, xem struct sockaddr_in6 cho IPv6)

struct sockaddr_in {
    short int          sin_family;  // Address family, AF_INET
    unsigned short int sin_port;    // Port number
    struct in_addr     sin_addr;    // Internet address
    unsigned char      sin_zero[8]; // Same size as struct sockaddr
};
```

Struct này giúp tham chiếu các thành phần của địa chỉ socket dễ dàng. Để
ý rằng `sin_zero` (được đưa vào để đệm struct cho đủ chiều dài của
`struct sockaddr`) nên được set toàn bộ về 0 bằng hàm `memset()`. Cũng
để ý rằng `sin_family` tương ứng với `sa_family` trong `struct sockaddr`
và nên được set là "`AF_INET`". Cuối cùng, `sin_port` phải ở [i[Byte
ordering]] _Network Byte Order_ (bằng cách dùng [i[`htons()` function]]
`htons()`!)

Đào sâu thêm! Bạn thấy trường `sin_addr` là một `struct in_addr`. Cái
gì đây? Ờ, không định kịch tính quá, nhưng đây là một trong những union
đáng sợ nhất mọi thời đại:

```{.c}
// (Chỉ IPv4, xem struct in6_addr cho IPv6)

// Địa chỉ Internet (là một struct vì lý do lịch sử)
struct in_addr {
    uint32_t s_addr; // đây là int 32-bit (4 byte)
};
```

Chà! Ờ, nó _từng_ là union, nhưng giờ có vẻ cái thời đó đã qua. May
phúc. Vậy nếu bạn khai báo `ina` là `struct sockaddr_in`, thì
`ina.sin_addr.s_addr` tham chiếu tới địa chỉ IP 4-byte (ở Network Byte
Order). Lưu ý rằng kể cả nếu hệ thống của bạn vẫn còn dùng cái union trời
đánh cho `struct in_addr`, bạn vẫn có thể tham chiếu địa chỉ IP 4-byte y
hệt như tôi làm ở trên (nhờ mấy `#define`).

Còn [i[IPv6]] IPv6 thì sao? Có các `struct` tương tự:

```{.c}
// (Chỉ IPv6, xem struct sockaddr_in và struct in_addr cho IPv4)

struct sockaddr_in6 {
    u_int16_t       sin6_family;   // address family, AF_INET6
    u_int16_t       sin6_port;     // port, Network Byte Order
    u_int32_t       sin6_flowinfo; // IPv6 flow information
    struct in6_addr sin6_addr;     // IPv6 address
    u_int32_t       sin6_scope_id; // Scope ID
};

struct in6_addr {
    unsigned char   s6_addr[16];   // IPv6 address
};
```

Để ý rằng IPv6 có một địa chỉ IPv6 và một số port, y như IPv4 có địa chỉ
IPv4 và số port.

Cũng để ý là tôi sẽ chưa nói về trường IPv6 flow information hay Scope
ID ngay bây giờ... đây chỉ là tài liệu khởi động thôi. `:-)`

Cuối cùng nhưng không kém phần quan trọng, đây là thêm một struct đơn
giản, `struct sockaddr_storage`, được thiết kế đủ to để chứa cả struct
IPv4 và IPv6. Bạn thấy đó, với một số lời gọi, đôi khi bạn không biết
trước nó sẽ điền `struct sockaddr` của bạn bằng địa chỉ IPv4 hay IPv6.
Nên bạn truyền vào cấu trúc song song này, rất giống `struct sockaddr`
nhưng to hơn, rồi ép kiểu về kiểu bạn cần:

```{.c}
struct sockaddr_storage {
    sa_family_t  ss_family;     // address family

    // tất cả dưới đây là padding, tuỳ implementation, bỏ qua:
    char      __ss_pad1[_SS_PAD1SIZE];
    int64_t   __ss_align;
    char      __ss_pad2[_SS_PAD2SIZE];
};
```

Điều quan trọng là bạn có thể nhìn address family trong trường
`ss_family`, kiểm tra xem nó là `AF_INET` hay `AF_INET6` (cho IPv4 hay
IPv6). Rồi bạn có thể ép kiểu nó về `struct sockaddr_in` hay `struct
sockaddr_in6` nếu muốn.


## Địa chỉ IP, Phần Hai

May cho bạn, có cả đống hàm cho phép bạn thao tác với [i[IP address]]
địa chỉ IP. Không cần mày mò tính bằng tay rồi nhét vào một `long` bằng
toán tử `<<`.

Đầu tiên, giả sử bạn có một `struct sockaddr_in ina`, và bạn có một địa
chỉ IP "`10.12.110.57`" hoặc "`2001:db8:63b3:1::3490`" mà bạn muốn lưu
vào đó. Hàm bạn muốn dùng, [i[`inet_pton()` function]] `inet_pton()`,
chuyển một địa chỉ IP ở dạng số-và-dấu-chấm thành `struct in_addr` hoặc
`struct in6_addr` tuỳ theo bạn chỉ định `AF_INET` hay `AF_INET6`.
("`pton`" là viết tắt của "presentation to network", bạn có thể gọi là
"printable to network" cho dễ nhớ.) Chuyển đổi có thể thực hiện như sau
cho IPv4 và IPv6:

```{.c}
struct sockaddr_in sa;   // IPv4
struct sockaddr_in6 sa6; // IPv6

inet_pton(AF_INET, "10.12.110.57", &(sa.sin_addr));
inet_pton(AF_INET6, "2001:db8:63b3:1::3490", &(sa6.sin6_addr));
```

(Ghi chú nhanh: cách cũ dùng một hàm tên [i[`inet_addr()` function]]
`inet_addr()` hoặc một hàm khác tên [i[`inet_aton()` function]]
`inet_aton()`; mấy cái này giờ lỗi thời và không chạy với IPv6.)

Đoạn code ở trên không vững chắc lắm vì không có kiểm tra lỗi. Đấy,
`inet_pton()` trả về `-1` khi lỗi, hoặc `0` nếu địa chỉ bị hỏng. Nên hãy
kiểm tra chắc chắn kết quả lớn hơn 0 trước khi dùng!

Rồi, giờ bạn có thể chuyển địa chỉ IP dạng chuỗi sang dạng nhị phân. Còn
chiều ngược lại thì sao? Nếu bạn có `struct in_addr` và bạn muốn in nó
ra dạng số-và-dấu-chấm? (Hoặc `struct in6_addr` mà bạn muốn dạng, ờ,
"hex-và-dấu-hai-chấm".) Trong trường hợp này, bạn muốn dùng hàm
[i[`inet_ntop()` function]] `inet_ntop()` ("ntop" nghĩa là "network to
presentation", bạn có thể gọi là "network to printable" cho dễ nhớ),
kiểu như:

```{.c .numberLines}
// IPv4:

char ip4[INET_ADDRSTRLEN];  // chỗ chứa chuỗi IPv4
struct sockaddr_in sa;      // giả sử nó đã được nạp gì đó rồi

inet_ntop(AF_INET, &(sa.sin_addr), ip4, INET_ADDRSTRLEN);

printf("The IPv4 address is: %s\n", ip4);


// IPv6:

char ip6[INET6_ADDRSTRLEN]; // chỗ chứa chuỗi IPv6
struct sockaddr_in6 sa6;    // giả sử nó đã được nạp gì đó rồi

inet_ntop(AF_INET6, &(sa6.sin6_addr), ip6, INET6_ADDRSTRLEN);

printf("The address is: %s\n", ip6);
```

Khi gọi, bạn sẽ truyền loại địa chỉ (IPv4 hoặc IPv6), địa chỉ, con trỏ
tới chuỗi để chứa kết quả, và độ dài tối đa của chuỗi đó. (Có hai macro
tiện lợi giữ kích thước chuỗi bạn cần để chứa địa chỉ IPv4 hoặc IPv6 lớn
nhất: `INET_ADDRSTRLEN` và `INET6_ADDRSTRLEN`.)

(Thêm một ghi chú nhanh nữa nhắc lại cách cũ: hàm lịch sử để làm chuyển
đổi này là [i[`inet_ntoa()` function]] `inet_ntoa()`. Nó cũng lỗi thời
và không chạy với IPv6.)

Cuối cùng, các hàm này chỉ chạy với địa chỉ IP dạng số, chúng không làm
DNS lookup trên nameserver với hostname như "`www.example.com`". Bạn sẽ
dùng `getaddrinfo()` để làm việc đó, như bạn sẽ thấy sau.


### Mạng Riêng (Hoặc Mạng Bị Ngắt Kết Nối)

[i[Private network]] Nhiều nơi có [i[Firewall]] firewall giấu network
của họ khỏi phần còn lại của thế giới để tự bảo vệ. Và nhiều khi,
firewall còn dịch địa chỉ IP "nội bộ" thành địa chỉ IP "bên ngoài" (cái
mà mọi người khác trên thế giới biết) bằng một quá trình gọi là _Network
Address Translation_, hay [i[NAT]] NAT.

Đang thấy hồi hộp chưa? "Anh đang dẫn tôi đi đâu với mớ thứ kỳ quặc
này?"

Ờ, thư giãn đi, mua cho mình một ly không cồn (hoặc có cồn), vì với
người mới, bạn còn chả cần lo về NAT, vì nó được làm trong suốt cho bạn.
Nhưng tôi muốn nói về network sau firewall phòng trường hợp bạn bắt đầu
lú lẫn vì những con số network bạn nhìn thấy.

Chẳng hạn, tôi có firewall ở nhà. Tôi được công ty DSL cấp hai địa chỉ
IPv4 tĩnh, vậy mà tôi có bảy máy trong mạng. Sao có thể? Hai máy không
thể chia sẻ cùng một địa chỉ IP, không thì dữ liệu biết đi về máy nào!

Câu trả lời: chúng không chia sẻ cùng địa chỉ IP. Chúng đang ở trong một
mạng riêng với 24 triệu địa chỉ IP được cấp. Chúng đều của riêng tôi. Ờ,
tất cả của riêng tôi, ít ra ai đó bên ngoài nhìn vào thì thấy vậy. Đây
là chuyện đang xảy ra:

Nếu tôi đăng nhập vào một máy từ xa, nó báo rằng tôi đang đăng nhập từ
192.0.2.33, đó là địa chỉ IP công khai mà ISP cấp cho tôi. Nhưng nếu tôi
hỏi máy ở nhà địa chỉ IP của nó, nó trả lời 10.0.0.5. Ai đang dịch địa
chỉ IP từ cái này sang cái kia? Đúng rồi, firewall đấy! Nó đang làm NAT!

`10.x.x.x` là một trong vài network được dự trữ, chỉ dùng trên các mạng
hoàn toàn tách biệt, hoặc các mạng ở sau firewall. Chi tiết về các số
network riêng nào có sẵn cho bạn dùng được nêu trong [flrfc[RFC
1918|1918]], nhưng vài cái thường thấy là [i[`10.x.x.x`]] `10.x.x.x` và
[i[`192.168.x.x`]] `192.168.x.x`, trong đó `x` là 0 đến 255 thường thế.
Ít gặp hơn là `172.y.x.x`, trong đó `y` chạy từ 16 đến 31.

Các mạng sau firewall NAT không _cần_ phải thuộc một trong những mạng
dự trữ này, nhưng thường là vậy.

(Chuyện vui! Địa chỉ IP bên ngoài của tôi thực ra không phải là
`192.0.2.33`. Mạng `192.0.2.x` được dự trữ để làm địa chỉ IP "thật" giả
tưởng cho dùng trong tài liệu, đúng y như tài liệu này! Ghê chưa!)

[i[IPv6]] IPv6 cũng có mạng riêng, theo một nghĩa nào đó. Chúng sẽ bắt
đầu bằng `fdXX:` (hoặc có thể trong tương lai `fcXX:`), theo [flrfc[RFC
4193|4193]]. Nhưng NAT và IPv6 nhìn chung không đi với nhau (trừ khi bạn
làm cái trò gateway IPv6 sang IPv4 vốn vượt quá phạm vi tài liệu này).
Về lý thuyết, bạn sẽ có quá trời địa chỉ dùng đến mức không cần tới NAT
nữa. Nhưng nếu bạn muốn cấp địa chỉ cho chính mình trên một mạng không
đi ra ngoài, đây là cách làm.
