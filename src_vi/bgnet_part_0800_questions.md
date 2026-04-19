# Những Câu Hỏi Thường Gặp

**Tôi kiếm những header file đó ở đâu?**

[i[Header files]] Nếu bạn chưa có chúng trên hệ thống, thì chắc bạn
không cần chúng. Kiểm tra sách hướng dẫn cho nền tảng cụ thể của bạn.
Nếu bạn đang build cho [i[Windows]] Windows, bạn chỉ cần `#include
<winsock.h>`.

**Tôi phải làm gì khi `bind()` báo [i[Address already in use]] "Address
already in use"?**

Bạn phải dùng [i[`setsockopt()` function]] `setsockopt()` với tùy
chọn [i[`SO_REUSEADDR` macro]] `SO_REUSEADDR` trên socket đang lắng
nghe. Xem [phần về `bind()`](#bind) và [phần về `select()`](#select)
để có ví dụ.

**Làm sao lấy danh sách socket đang mở trên hệ thống?**

Dùng [i[`netstat` command]] `netstat`. Kiểm tra `man` page để biết
chi tiết đầy đủ, nhưng bạn sẽ có output tốt chỉ bằng cách gõ:

```
$ netstat
```

Khó khăn duy nhất là xác định socket nào gắn với chương trình nào.
`:-)`

**Làm sao xem routing table?**

Chạy lệnh [i[`route` command]] `route` (trong `/sbin` trên hầu hết
Linux) hoặc lệnh [i[`netstat` command]] `netstat -r`. Hoặc lệnh
[i[`ip route` command]] `ip route`.

**Làm sao chạy chương trình client và server nếu tôi chỉ có một máy
tính? Tôi không cần một mạng để viết chương trình mạng à?**

May cho bạn, hầu như mọi máy đều có triển khai "thiết bị" mạng
[i[Loopback device]] loopback nằm trong kernel và giả vờ là một
card mạng. (Đây là interface được liệt kê là "`lo`" trong routing
table.)

Giả sử bạn đang login vào một máy tên [i[Goat]] "`goat`". Chạy
client trong một cửa sổ và server trong cửa sổ khác. Hoặc khởi động
server ở chế độ nền ("`server &`") và chạy client trong cùng cửa
sổ. Cái được của loopback device là bạn có thể `client goat` hoặc
[i[`localhost`]] `client localhost` (vì "`localhost`" có khả năng
được định nghĩa trong file `/etc/hosts` của bạn) và bạn sẽ có
client nói chuyện với server mà không cần mạng!

Nói gọn, không cần thay đổi gì trong code để nó chạy được trên một
máy đơn lẻ không nối mạng! Hoan hô!

**Làm sao biết đầu bên kia đã đóng kết nối?**

Bạn có thể biết vì `recv()` sẽ trả về `0`.

**Làm sao cài đặt tiện ích [i[`ping` command]] "ping"? [i[ICMP]] ICMP
là gì? Tôi tìm hiểu thêm về [i[Raw sockets]] raw socket và `SOCK_RAW`
ở đâu?**

[i[`SOCK_RAW` macro]]

Tất cả câu hỏi về raw socket của bạn sẽ được trả lời trong sách
[UNIX Network Programming của W. Richard Stevens](#books). Cũng vậy,
xem trong thư mục `ping/` con trong source code của UNIX Network
Programming của Stevens, [fl[có sẵn
online|http://www.unpbook.com/src.html]].

**Làm sao thay đổi hoặc rút ngắn timeout của một lời gọi `connect()`?**

Thay vì đưa bạn chính xác cùng câu trả lời mà W. Richard Stevens sẽ
đưa, tôi sẽ chỉ bạn tới [fl[`lib/connect_nonb.c` trong source code
UNIX Network Programming|http://www.unpbook.com/src.html]].

Tóm tắt là bạn tạo một socket descriptor bằng `socket()`, [đặt nó
thành non-blocking](#blocking), gọi `connect()`, và nếu mọi thứ
suôn sẻ `connect()` sẽ trả về `-1` ngay lập tức và `errno` sẽ được
gán thành `EINPROGRESS`. Rồi bạn gọi [`select()`](#select) với bất
kỳ timeout nào bạn muốn, truyền socket descriptor vào cả tập đọc
lẫn tập ghi. Nếu nó không timeout, nghĩa là lời gọi `connect()` đã
hoàn thành. Lúc này, bạn sẽ phải dùng `getsockopt()` với tùy chọn
`SO_ERROR` để lấy giá trị trả về từ lời gọi `connect()`, giá trị đó
sẽ bằng không nếu không có lỗi.

Cuối cùng, có lẽ bạn sẽ muốn đặt socket trở lại chế độ blocking
trước khi bắt đầu truyền dữ liệu qua nó.

Chú ý rằng cách này có thêm cái được là cho phép chương trình của
bạn làm việc khác trong lúc đang connect. Ví dụ, bạn có thể đặt
timeout thấp, như 500 ms, và cập nhật một chỉ báo trên màn hình mỗi
lần timeout, rồi gọi `select()` lần nữa. Khi bạn đã gọi `select()`
và timeout, ví dụ 20 lần, bạn biết đã đến lúc bỏ cuộc với kết nối
này.

Như tôi đã nói, xem source của Stevens để có ví dụ tuyệt vời tuyệt
đối.

**Làm sao build cho Windows?**

Trước hết, xóa Windows và cài Linux hoặc BSD. `};-)`. Không, thật
ra, chỉ cần xem [phần về build cho Windows](#windows) ở phần giới
thiệu.

**Làm sao build cho Solaris/SunOS? Tôi cứ bị lỗi linker khi cố biên
dịch!**

Lỗi linker xảy ra vì mấy cái máy Sun không tự động compile chung
với các thư viện socket. Xem [phần về build cho
Solaris/SunOS](#solaris) ở phần giới thiệu để có ví dụ về cách làm
việc này.

**Tại sao `select()` cứ thoát ra khi có signal?**

Signal có xu hướng làm cho các system call đang bị block trả về
`-1` với `errno` được gán thành `EINTR`. Khi bạn đặt một signal
handler bằng [i[`sigaction()` function]] `sigaction()`, bạn có thể
đặt cờ [i[`SA_RESTART` macro]] `SA_RESTART`, được cho là sẽ khởi
động lại system call sau khi nó bị ngắt.

Đương nhiên, cái này không phải lúc nào cũng hiệu quả.

Giải pháp ưa thích của tôi cho chuyện này liên quan đến một câu
lệnh [i[`goto` statement]] `goto`. Bạn biết chuyện này khiến các
giáo sư của bạn cực kỳ khó chịu, nên cứ làm đi!

```{.c .numberLines}
select_restart:
if ((err = select(fdmax+1, &readfds, NULL, NULL, NULL)) == -1) {
    if (errno == EINTR) {
        // some signal just interrupted us, so restart
        goto select_restart;
    }
    // handle the real error here:
    perror("select");
} 
```

Chắc rồi, bạn không _cần_ dùng `goto` trong trường hợp này; bạn có
thể dùng cấu trúc khác để điều khiển. Nhưng tôi nghĩ câu lệnh
`goto` thật ra sạch hơn.

**Làm sao cài đặt timeout cho một lời gọi `recv()`?**

[i[`recv()` function-->timeout]] Dùng [i[`select()` function]]
[`select()`](#select)! Nó cho phép bạn chỉ định tham số timeout cho
các socket descriptor mà bạn đang muốn đọc từ đó. Hoặc, bạn có thể
gói toàn bộ chức năng vào một hàm duy nhất, như thế này:

```{.c .numberLines}
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>

int recvtimeout(int s, char *buf, int len, int timeout)
{
    fd_set fds;
    int n;
    struct timeval tv;

    // set up the file descriptor set
    FD_ZERO(&fds);
    FD_SET(s, &fds);

    // set up the struct timeval for the timeout
    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    // wait until timeout or data received
    n = select(s+1, &fds, NULL, NULL, &tv);
    if (n == 0) return -2; // timeout!
    if (n == -1) return -1; // error

    // data must be here, so do a normal recv()
    return recv(s, buf, len, 0);
}
.
.
.
// Sample call to recvtimeout():
n = recvtimeout(s, buf, sizeof buf, 10); // 10 second timeout

if (n == -1) {
    // error occurred
    perror("recvtimeout");
}
else if (n == -2) {
    // timeout occurred
} else {
    // got some data in buf
}
.
.
. 
```

Chú ý rằng [i[`recvtimeout()` function]] `recvtimeout()` trả về
`-2` trong trường hợp timeout. Sao không trả về `0`? Nếu bạn còn
nhớ, giá trị trả về `0` trên lời gọi `recv()` nghĩa là đầu bên kia
đã đóng kết nối. Nên giá trị trả về đó đã có chỗ, và `-1` nghĩa là
"lỗi", nên tôi chọn `-2` làm chỉ báo timeout của mình.

**Làm sao [i[Encryption]] mã hóa hoặc nén dữ liệu trước khi gửi
qua socket?**

Một cách dễ để mã hóa là dùng [i[SSL]] SSL (secure sockets layer),
nhưng cái đó vượt ra ngoài phạm vi hướng dẫn này. [i[OpenSSL]] (Xem
[fl[dự án OpenSSL|https://www.openssl.org/]] để biết thêm.)

Nhưng giả sử bạn muốn cắm vào hoặc tự cài đặt hệ thống
[i[Compression]] nén hay mã hóa của mình, thì đó chỉ là chuyện
nghĩ về dữ liệu của mình như đang chạy qua một chuỗi bước giữa hai
đầu. Mỗi bước thay đổi dữ liệu theo một cách nào đó.

1. server đọc dữ liệu từ file (hoặc ở đâu đó)
2. server mã hóa/nén dữ liệu (bạn thêm phần này)
3. server `send()` dữ liệu đã mã hóa

Giờ hướng ngược lại:

1. client `recv()` dữ liệu đã mã hóa
2. client giải mã/giải nén dữ liệu (bạn thêm phần này)
3. client ghi dữ liệu ra file (hoặc ở đâu đó)

Nếu bạn định nén và mã hóa, nhớ nén trước. `:-)`

Miễn là client đảo ngược đúng những gì server làm, dữ liệu sẽ ổn
ở cuối bất kể bạn thêm bao nhiêu bước trung gian.

Vậy tất cả những gì bạn cần làm để dùng code của tôi là tìm vị trí
giữa chỗ dữ liệu được đọc và chỗ dữ liệu được gửi (bằng `send()`)
qua mạng, và nhét vào đó một đoạn code làm việc mã hóa.

**Cái "`PF_INET`" mà tôi cứ thấy là gì vậy? Nó có liên quan đến
`AF_INET` không?**

[i[`PF_INET` macro]] [i[`AF_INET` macro]]

Có, có liên quan đấy. Xem [phần về `socket()`](#socket) để biết
chi tiết.

**Làm sao viết một server nhận lệnh shell từ client và thực thi
chúng?**

Để đơn giản, giả sử client `connect()`, `send()` và `close()` kết
nối (tức là không có system call nào theo sau mà client không kết
nối lại).

Quy trình mà client làm theo là:

1. `connect()` tới server
2. `send("/sbin/ls > /tmp/client.out")`
3. `close()` kết nối

Trong lúc đó, server xử lý dữ liệu và thực thi nó:

1. `accept()` kết nối từ client
2. `recv(str)` chuỗi lệnh
3. `close()` kết nối
4. `system(str)` để chạy lệnh

[i[Security]] _Coi chừng!_ Cho server thực thi những gì client bảo
thì chẳng khác gì cho quyền truy cập shell từ xa, và người ta có
thể làm nhiều trò với tài khoản của bạn khi kết nối vào server. Ví
dụ, trong ví dụ trên, lỡ client gửi "`rm -rf ~`" thì sao? Nó xóa
sạch mọi thứ trong tài khoản của bạn, thế đấy!

Nên bạn khôn ra, và bạn ngăn client dùng bất cứ gì trừ một vài
tiện ích bạn biết là an toàn, như tiện ích `foobar`:

```{.c}
if (!strncmp(str, "foobar", 6)) {
    sprintf(sysstr, "%s > /tmp/server.out", str);
    system(sysstr);
} 
```

Nhưng bạn vẫn chưa an toàn, đáng tiếc: lỡ client nhập "`foobar;
rm -rf ~`" thì sao? Điều an toàn nhất cần làm là viết một thủ tục
nhỏ đặt ký tự escape ("`\`") trước tất cả ký tự không phải chữ và
số (bao gồm cả khoảng trắng, nếu phù hợp) trong các tham số cho
lệnh.

Như bạn thấy, bảo mật là vấn đề khá lớn khi server bắt đầu thực
thi những thứ client gửi.

**Tôi gửi cả đống dữ liệu, nhưng khi `recv()`, nó chỉ nhận được
536 byte hoặc 1460 byte mỗi lần. Nhưng nếu tôi chạy trên máy local,
nó nhận toàn bộ dữ liệu cùng lúc. Chuyện gì đang xảy ra?**

Bạn đang chạm đến [i[MTU]] MTU, kích thước tối đa mà môi trường
vật lý có thể xử lý. Trên máy local, bạn đang dùng thiết bị
loopback có thể xử lý 8K hoặc hơn không thành vấn đề. Nhưng trên
Ethernet, vốn chỉ có thể xử lý 1500 byte kèm header, bạn chạm giới
hạn đó. Qua modem, với MTU 576 (lại kèm header), bạn chạm giới hạn
còn thấp hơn.

Bạn phải đảm bảo toàn bộ dữ liệu đang được gửi, trước hết. (Xem
hàm [`sendall()`](#sendall) để biết chi tiết.) Khi bạn chắc chuyện
đó, thì bạn cần gọi `recv()` trong vòng lặp cho đến khi tất cả dữ
liệu của bạn được đọc.

Đọc phần [Đứa Con Trai Của Đóng Gói Dữ Liệu](#sonofdataencap) để
biết chi tiết về việc nhận đầy đủ các gói tin dùng nhiều lời gọi
`recv()`.

**Tôi dùng máy Windows và không có system call `fork()` hay bất kỳ
kiểu `struct sigaction` nào. Phải làm sao?**

[i[`fork()` function]] Nếu chúng tồn tại ở đâu đó, chúng sẽ nằm
trong các thư viện POSIX có thể đã đi kèm với compiler của bạn. Vì
tôi không có máy Windows, tôi thật sự không thể cho bạn câu trả
lời, nhưng tôi nhớ mang máng là Microsoft có một lớp tương thích
POSIX và đó là nơi `fork()` có thể nằm. (Và có thể cả `sigaction`
nữa.)

Tìm trong phần help đi kèm VC++ từ khóa "fork" hoặc "POSIX" xem có
manh mối gì không.

Nếu cái đó hoàn toàn không chạy, vứt hết cái `fork()`/`sigaction`
và thay bằng thứ tương đương của Win32: [i[`CreateProcess()`
function]] `CreateProcess()`. Tôi không biết cách dùng
`CreateProcess()`, nó nhận cả tỷ tham số, nhưng chắc nó được bao
phủ trong tài liệu đi kèm VC++.

[[book-pagebreak]]

**[i[Firewall]] Tôi ở sau firewall, làm sao cho người ngoài firewall
biết địa chỉ IP của tôi để họ có thể kết nối tới máy tôi?**

Đáng tiếc, mục đích của firewall là ngăn người ở ngoài firewall
kết nối tới máy bên trong firewall, nên cho phép họ làm vậy về cơ
bản là bị coi là vi phạm bảo mật.

Không có nghĩa là mọi thứ đều thua cuộc. Một là, bạn vẫn thường có
thể `connect()` qua firewall nếu nó đang làm kiểu masquerading
hoặc NAT hay gì đó tương tự. Chỉ cần thiết kế chương trình sao cho
bạn luôn là người chủ động khởi tạo kết nối, và bạn sẽ ổn.

[i[Firewall-->poking holes in]] Nếu cái đó không thỏa đáng, bạn có
thể nhờ mấy ông sysadmin đục một lỗ trên firewall để người ta có
thể kết nối tới bạn. Firewall có thể forward tới bạn qua phần mềm
NAT của nó, hoặc qua proxy hay gì đó tương tự.

Xin lưu ý rằng một lỗ thủng trên firewall không phải chuyện đùa.
Bạn phải đảm bảo mình không cho kẻ xấu truy cập vào mạng nội bộ;
nếu bạn là người mới, khó hơn nhiều để làm phần mềm an toàn so với
tưởng tượng của bạn.

Đừng làm sysadmin của bạn giận tôi. `;-)`

**[i[Packet sniffer]] [i[Promiscuous mode]] Làm sao viết một packet
sniffer? Làm sao đặt Ethernet interface của tôi vào chế độ
promiscuous?**

Cho những ai chưa biết, khi một card mạng ở "chế độ promiscuous",
nó sẽ chuyển TẤT CẢ gói tin cho hệ điều hành, không chỉ những gói
tin có địa chỉ đến máy cụ thể này. (Chúng ta đang nói về địa chỉ
tầng Ethernet ở đây, không phải địa chỉ IP, nhưng vì Ethernet ở
tầng dưới IP, tất cả địa chỉ IP thực chất cũng được forward luôn.
Xem phần [Chuyện Nhảm Cấp Thấp và Lý Thuyết Mạng](#lowlevel) để
biết thêm.)

Đây là cơ sở cách một packet sniffer hoạt động. Nó đặt interface
vào chế độ promiscuous, rồi OS nhận mọi gói tin đi qua trên dây.
Bạn sẽ có một loại socket nào đó để đọc dữ liệu này.

Đáng tiếc, câu trả lời cho câu hỏi này khác nhau tùy nền tảng,
nhưng nếu bạn Google từ khóa, ví dụ, "windows promiscuous
[i[`ioctl()` function]] ioctl" chắc bạn sẽ tới được đâu đó. Cho
Linux, có vẻ có một [fl[chủ đề Stack Overflow hữu
ích|https://stackoverflow.com/questions/21323023/]] nữa.

**Làm sao đặt giá trị [i[Timeout-->setting]] timeout tùy chỉnh cho
một socket TCP hoặc UDP?**

Cái này tùy hệ thống của bạn. Bạn có thể tìm trên mạng [i[`SO_RCVTIMEO`
macro]] `SO_RCVTIMEO` và [i[`SO_SNDTIMEO` macro]] `SO_SNDTIMEO` (để
dùng với [i[`setsockopt()` function]] `setsockopt()`) xem hệ thống
của bạn có hỗ trợ chức năng như vậy không.

Trang man của Linux đề nghị dùng `alarm()` hoặc `setitimer()` thay
thế.

[[book-pagebreak]]

**Làm sao biết port nào có sẵn để dùng? Có danh sách số port "chính
thức" không?**

Thường thì đây không phải vấn đề. Nếu bạn đang viết, ví dụ, một web
server, thì nên dùng port 80 nổi tiếng cho phần mềm của mình. Nếu
bạn đang viết một server chuyên biệt của riêng mình, thì chọn một
port ngẫu nhiên (nhưng lớn hơn 1023) và thử.

Nếu port đã được dùng, bạn sẽ bị lỗi "Address already in use" khi
cố `bind()`. Chọn port khác. (Nên cho phép người dùng phần mềm của
bạn chỉ định một port khác qua file config hoặc tùy chọn dòng
lệnh.)

Có một [fl[danh sách số port chính
thức|https://www.iana.org/assignments/port-numbers]] được duy trì
bởi Internet Assigned Numbers Authority (IANA). Chỉ vì cái gì đó
(lớn hơn 1023) có trong danh sách đó không có nghĩa là bạn không
thể dùng port đó. Ví dụ, DOOM của Id Software dùng cùng port với
"mdqs", bất kể cái đó là gì. Tất cả những gì quan trọng là không ai
khác _trên cùng một máy_ đang dùng port đó khi bạn muốn dùng nó.
