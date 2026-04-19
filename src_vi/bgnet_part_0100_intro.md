# Giới thiệu
<!--
Beej's Guide to Network Programming book source

# vim: ts=4:sw=4:nosi:et:tw=72
-->

<!--
	History:

	2.3.2:		socket man page
	2.3.3:		sockaddr_in man page
	2.3.4:		bind, listen man page
	2.3.5:		connect man page
	2.3.6:		listen, perror man page
	2.3.7:		errno man page
	2.3.8:		htonl etc man page
	2.3.9:		close man page, expanded man page leader
	2.3.10:		inet_ntoa, setsockopt man pages
	2.3.11:		getpeername man page
	2.3.12:		send/sendto man pages
	2.3.13:		shutdown man pages
	2.3.14:		gethostname man pages, fix inet_aton links
	2.3.15:		fcntl man page
	2.3.16:		recv/recvfrom man page
	2.3.17:		gethostbyname/gethostbyaddr man page
	2.3.18:		changed GET / to GET / HTTP/1.0
	2.3.19:		added select() man page
	2.3.20:		added poll() man page
	2.3.21:		section on NAT and reserved networks
	2.3.22:		typo fixes in sects "man" and "privnet"
	2.3.23:		added broadcast packets section
	2.3.24:		manpage prototype changed to code, subtitle moved out of title
	2.4.0:		big overhaul, serialization stuff
	2.4.1:		minor text changes in intro
	2.4.2:		changed all sizeofs to use variable names instead of types
	2.4.3:		fix myaddr->my_addr in listener.c, sockaddr_inman example
	2.4.4:		fix myaddr->my_addr in server.c
	2.4.5:		fix 14->18 in son of data encap
	3.0.0:		IPv6 overhaul
	3.0.1:		sa-to-sa6 typo fix
	3.0.2:		typo fixes
	3.0.3:		typo fixes
	3.0.4:		cut-n-paste errors, selectserver hints fix
	3.0.5:		typo fixes
	3.0.6:		typo fixes
	3.0.7:		typo fixes, added front matter
	3.0.8:		getpeername() code fixes
	3.0.9:		getpeername() code fixes, this time fer sure
	3.0.10:		bind() man page code fix, comment changes
	3.0.11:		socket syscall section code fix, comment changes
	3.0.12:		typos in "IP Addresses, structs, and Data Munging"
	3.0.13:		amp removals, note about errno and multithreading
	3.0.14:		type changes to listener.c, pack2.c
	3.0.15:		fix inet_pton example
	3.0.16:		fix simple server output, optlen in getsockopt man page
	3.0.17:		fix small typo
	3.0.18:		reverse perror and close calls in getaddrinfo
	3.0.19:		add notes about O_NONBLOCK with select() under Linux
	3.0.20:		fix missing .fd in poll() example
	3.0.21:		change sizeof(int) to sizeof yes
    3.0.22:     C99 updates, bug fixes, markdown
    3.0.23:     Book reference and URL updates
    3.1.0:      Section on poll()
    3.1.1:      Add WSL note, telnot
    3.1.2:      pollserver.c bugfix
    3.1.3:      Fix freeaddrinfo memleak
    3.1.4:      Fix accept example header files
    3.1.5:      Fix dgram AF_UNSPEC
-->

<!-- prevent hyphenation of the following words: -->
[nh[strtol]]
[nh[sprintf]]
[nh[accept]]
[nh[bind]]
[nh[connect]]
[nh[close]]
[nh[getaddrinfo]]
[nh[freeaddrinfo]]
<!--
Don't know how to make this work with underscores. I love
you, Knuth, but... daaahm.

[nh[gai_strerr]]
-->
[nh[gethostname]]
[nh[gethostbyname]]
[nh[gethostbyaddr]]
[nh[getnameinfo]]
[nh[getpeername]]
[nh[errno]]
[nh[fcntl]]
[nh[htons]]
[nh[htonl]]
[nh[ntohs]]
[nh[ntohl]]
<!--
[nh[inet_ntoa]]
[nh[inet_aton]]
[nh[inet_addr]]
[nh[inet_ntop]]
[nh[inet_pton]]
-->
[nh[listen]]
[nh[perror]]
[nh[strerror]]
[nh[poll]]
[nh[recv]]
[nh[recvfrom]]
[nh[select]]
[nh[setsockopt]]
[nh[getsockopt]]
[nh[send]]
[nh[sendto]]
[nh[shutdown]]
[nh[socket]]
[nh[struct]]
[nh[sockaddr]]
<!--
[nh[sockaddr_in]]
[nh[in_addr]]
[nh[sockaddr_in6]]
[nh[in6_addr]]
-->
[nh[hostent]]
[nh[addrinfo]]
[nh[closesocket]]

Này! Lập trình socket đang hành bạn? Đọc trang `man` mà chả hiểu ra làm sao? Bạn muốn làm mấy thứ ngầu trên mạng nhưng không có thời gian lội qua đống `struct` để biết có cần gọi `bind()` trước `connect()` không, v.v.

Mà đoán xem! Tôi đã lội qua cái đống đó rồi, và đang ngứa ngáy muốn kể cho mọi người nghe! Bạn đã đến đúng chỗ rồi. Tài liệu này sẽ giúp lập trình viên C tầm trung có đủ vũ khí để nắm được cái mớ lập trình mạng này.

Ồ và còn nữa: tôi đã theo kịp tương lai rồi (vừa kịp lúc thôi!) và đã cập nhật thêm IPv6 cho tài liệu! Đọc thôi!


## Đối tượng đọc

Tài liệu này được viết theo dạng hướng dẫn, không phải tài liệu tham khảo đầy đủ. Nó phù hợp nhất với những ai mới bắt đầu với lập trình socket và đang cần chỗ bám để leo. Nó chắc chắn không phải là tài liệu _toàn diện và đầy đủ_ về lập trình socket, theo bất kỳ nghĩa nào.

Nhưng hy vọng nó vừa đủ để bạn bắt đầu đọc hiểu được trang `man`... `:-)`


## Nền tảng và trình biên dịch

Code trong tài liệu này được biên dịch trên máy Linux với trình biên dịch [i[Compilers-->GCC]] `gcc` của GNU. Tuy nhiên nó cũng biên dịch được trên hầu hết các nền tảng dùng `gcc`. Tất nhiên điều này không áp dụng nếu bạn lập trình trên Windows, xem [phần về Windows](#windows) bên dưới.


## Trang chủ chính thức và sách in

Tài liệu gốc được đặt tại:

* [`https://beej.us/guide/bgnet/`](https://beej.us/guide/bgnet/)

Ở đó bạn cũng tìm thấy code ví dụ và các bản dịch sang nhiều ngôn ngữ.

Để mua bản in đóng bìa đẹp (có người gọi là "sách"), ghé vào:

* [`https://beej.us/guide/url/bgbuy`](https://beej.us/guide/url/bgbuy)

Tôi sẽ rất cảm ơn nếu bạn mua, vì nó giúp tôi duy trì lối sống viết tài liệu!


## Ghi chú cho người dùng Solaris/SunOS/illumos {#solaris}

Khi biên dịch trên [i[Solaris]] Solaris hay [i[SunOS]] SunOS, bạn cần thêm một số cờ dòng lệnh để liên kết đúng thư viện. Chỉ cần thêm "`-lnsl -lsocket -lresolv`" vào cuối lệnh biên dịch, kiểu như:

```
$ cc -o server server.c -lnsl -lsocket -lresolv
```

Nếu vẫn còn báo lỗi, thử thêm `-lxnet` vào cuối. Tôi không biết chính xác cái đó làm gì, nhưng một số người cần đến nó.

Một chỗ khác có thể gặp vấn đề là khi gọi `setsockopt()`. Prototype trên Solaris khác với trên máy Linux của tôi, vì vậy thay vì:

```{.c}
int yes=1;
```

hãy dùng:

```{.c}
char yes='1';
```

Vì tôi không có máy Sun nên chưa tự kiểm tra, đây chỉ là những gì mọi người nói với tôi qua email.


## Ghi chú cho người dùng Windows {#windows}

Từ trước đến nay tài liệu này có truyền thống chê [i[Windows]] Windows khá nhiều, đơn giản là vì tôi không thích nó mấy. Nhưng rồi Windows và Microsoft cũng có nhiều cải thiện. Windows 10 kết hợp với WSL (xem bên dưới) tạo nên một hệ điều hành khá được. Không có gì nhiều để phàn nàn.

À, vẫn còn một chút. Ví dụ, tôi đang viết bài này (năm 2025) trên chiếc laptop 2015 từng chạy Windows 10. Cuối cùng nó chậm quá và tôi cài Linux lên. Rồi dùng từ đó đến giờ.

Còn nay lại có Windows 11 đòi hỏi phần cứng mạnh hơn Windows 10. Tôi không ưa điều đó chút nào. Hệ điều hành phải càng nhẹ càng tốt, không nên buộc bạn bỏ thêm tiền. CPU mạnh hơn là để chạy ứng dụng, không phải để chạy hệ điều hành! Và thêm vào đó, Microsoft biết bạn muốn gì, và cái bạn muốn là... quảng cáo! Đúng không? Ngay trong hệ điều hành! Bạn đang nhớ nó lắm phải không? Windows 11 đã có sẵn cho bạn rồi đó.

Vì vậy tôi vẫn khuyến khích bạn thử [i[Linux]]
[fl[Linux|https://www.linux.com/]], [i[BSD]] [fl[BSD|https://bsd.org/]],
[i[illumos]] [fl[illumos|https://www.illumos.org/]] hay bất kỳ hệ Unix nào đó thay vì Windows.

Ừ mà cái bục diễn thuyết này chui vào đây lúc nào vậy?

Thôi, ai thích gì dùng nấy. Bạn dùng Windows cũng được, phần lớn nội dung trong tài liệu này vẫn áp dụng, chỉ cần sửa vài chỗ nhỏ.

Điều đầu tiên bạn nên cân nhắc là [i[WSL]] [i[Windows
Subsystem For Linux]] [fl[Windows Subsystem for
Linux|https://learn.microsoft.com/en-us/windows/wsl/]]. Đây cơ bản là cách cài một thứ gì đó kiểu máy ảo Linux trên Windows 10. Với nó, bạn biên dịch và chạy các chương trình trong tài liệu này nguyên vẹn không cần sửa gì.

Một lựa chọn khác là cài [i[Cygwin]]
[fl[Cygwin|https://cygwin.com/]], bộ công cụ Unix cho Windows. Nghe đồn rằng các chương trình này biên dịch được nguyên vẹn với Cygwin, nhưng tôi chưa tự thử bao giờ.

Còn nếu bạn muốn làm theo đúng kiểu Windows thuần túy, thật can đảm đấy! Và đây là việc bạn phải làm: chạy ra ngoài mua ngay một máy Unix! Không không, đùa thôi. Tôi phải thân thiện hơn với Windows ngày nay mà...

Thôi được rồi. Vào việc thôi.

[i[Winsock]]

Đây là những gì bạn cần làm: đầu tiên, bỏ qua gần hết các file header hệ thống tôi đề cập trong tài liệu. Thay vào đó, include:

```{.c}
#include <winsock2.h>
#include <ws2tcpip.h>
```

`winsock2` là phiên bản "mới" (khoảng năm 1994) của thư viện socket trên Windows.

Đáng tiếc là nếu bạn include `windows.h`, nó tự động kéo theo header `winsock.h` cũ hơn (phiên bản 1), xung đột với `winsock2.h`! Vui thật.

Vì vậy nếu phải include `windows.h`, bạn cần định nghĩa một macro để nó _không_ kéo theo header cũ:

```{.c}
#define WIN32_LEAN_AND_MEAN  // Say this...

#include <windows.h>         // And now we can include that.
#include <winsock2.h>        // And this.
```

Khoan đã! Bạn còn phải gọi [i[`WSAStartup()` function]]
`WSAStartup()` trước khi làm bất cứ điều gì với thư viện socket. Bạn truyền vào phiên bản Winsock muốn dùng (ví dụ phiên bản 2.2), rồi kiểm tra kết quả để chắc chắn phiên bản đó có sẵn.

Code trông kiểu này:

```{.c .numberLines}
#include <winsock2.h>

{
    WSADATA wsaData;

    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        fprintf(stderr, "WSAStartup failed.\n");
        exit(1);
    }

    if (LOBYTE(wsaData.wVersion) != 2 ||
        HIBYTE(wsaData.wVersion) != 2)
    {
        fprintf(stderr,"Version 2.2 of Winsock not available.\n");
        WSACleanup();
        exit(2);
    }
```

Để ý lệnh gọi [i[`WSACleanup()` function]] `WSACleanup()` ở đó. Đó là hàm bạn cần gọi khi dùng xong thư viện Winsock.

Bạn cũng cần báo cho trình biên dịch liên kết với thư viện Winsock, tên là `ws2_32.lib` cho Winsock 2. Trong VC++, vào menu `Project`, chọn `Settings...`, bấm tab `Link`, tìm ô "Object/library modules" và thêm "ws2_32.lib" vào danh sách.

Ít nhất tôi nghe vậy.

Sau khi xong xuôi, hầu hết các ví dụ trong tài liệu này đều dùng được, với vài ngoại lệ. Thứ nhất, bạn không thể dùng `close()` để đóng socket mà phải dùng [i[`closesocket()`
function]] `closesocket()`. Ngoài ra, [i[`select()` function]]
`select()` chỉ hoạt động với socket descriptor, không hoạt động với file descriptor thông thường (như `0` cho `stdin`).

Ngoài ra còn có lớp socket [i[`CSocket` class]]
[`CSocket`](https://learn.microsoft.com/en-us/cpp/mfc/reference/csocket-class?view=msvc-170). Xem tài liệu trình biên dịch của bạn để biết thêm.

Muốn biết thêm về Winsock, [xem trang chính thức của Microsoft](https://learn.microsoft.com/en-us/windows/win32/winsock/windows-sockets-start-page-2).

Cuối cùng, tôi nghe nói Windows không có system call [i[`fork()` function]] `fork()`, mà một số ví dụ của tôi có dùng. Có thể bạn cần liên kết với thư viện POSIX nào đó, hoặc dùng [i[`CreateProcess()` function]] `CreateProcess()` thay thế. `fork()` không nhận tham số nào, còn `CreateProcess()` nhận khoảng 48 tỷ tham số. Nếu không muốn đối mặt với điều đó, [i[`CreateThread()`
function]] `CreateThread()` dễ nuốt hơn một chút, tiếc thay thảo luận về đa luồng thì nằm ngoài phạm vi tài liệu này rồi. Tôi chỉ viết được đến đây thôi!

Và còn một điều "cuối cùng" nữa, Steven Mitchell đã [fl[chuyển một số ví dụ|https://www.tallyhawk.net/WinsockExamples/]] sang Winsock. Có thể xem thêm ở đó.


## Chính sách email

Tôi thường sẵn sàng trả lời [i[Emailing Beej]] câu hỏi qua email, cứ viết thôi, nhưng tôi không đảm bảo sẽ hồi âm. Cuộc sống khá bận và đôi khi tôi thật sự không có thời gian trả lời. Khi đó tôi thường xóa email đi. Không có gì cá nhân cả, chỉ là không có thời gian cho câu trả lời chi tiết mà bạn cần thôi.

Thông thường, câu hỏi càng phức tạp thì khả năng tôi trả lời càng thấp. Nếu bạn thu hẹp vấn đề trước khi gửi, kèm theo đầy đủ thông tin liên quan (nền tảng, trình biên dịch, thông báo lỗi, và bất cứ thứ gì bạn nghĩ có thể giúp tôi debug), bạn sẽ có nhiều khả năng nhận được hồi âm hơn. Để biết thêm, đọc tài liệu của ESR: [fl[How To Ask Questions The Smart
Way|http://www.catb.org/~esr/faqs/smart-questions.html]].

Nếu không nhận được hồi âm, hãy tiếp tục mày mò, cố tự tìm câu trả lời, rồi nếu vẫn bế tắc thì viết lại cho tôi kèm theo những gì bạn đã tìm được. Biết đâu thông tin đó đủ để tôi giúp được.

Dù tôi có nài nỉ bạn viết thế này hay thế kia, tôi chỉ muốn nói rằng tôi _thực sự_ trân trọng mọi lời khen ngợi mà tài liệu này nhận được qua bao nhiêu năm. Đó là nguồn động lực thực sự, và nghe rằng nó được dùng vào việc tốt thì thật vui! `:-)` Cảm ơn mọi người!


## Nhân bản tài liệu

[i[Mirroring the Guide]] Bạn hoàn toàn được phép nhân bản trang này, dù công khai hay riêng tư. Nếu bạn nhân bản công khai và muốn tôi đặt liên kết từ trang chủ, gửi cho tôi một dòng tại
[`beej@beej.us`](mailto:beej@beej.us).


## Ghi chú cho người dịch

[i[Translating the Guide]] Nếu bạn muốn dịch tài liệu sang ngôn ngữ khác, liên hệ tôi tại [`beej@beej.us`](mailto:beej@beej.us) và tôi sẽ đặt liên kết đến bản dịch của bạn từ trang chủ. Bạn được phép thêm tên và thông tin liên lạc của mình vào bản dịch.

Tài liệu nguồn dùng encoding UTF-8.

Xin lưu ý các điều khoản giấy phép trong phần [Bản quyền, phân phối và pháp lý](#legal) bên dưới.

Nếu bạn muốn tôi lưu trữ bản dịch, cứ hỏi. Tôi cũng sẽ đặt liên kết nếu bạn tự lưu trữ. Cách nào cũng được.


## Bản quyền, phân phối và pháp lý {#legal}

Beej's Guide to Network Programming is Copyright &copy; 2019 Brian "Beej
Jorgensen" Hall.

Ngoại trừ các trường hợp đặc biệt dành cho mã nguồn và bản dịch được đề cập bên dưới, tác phẩm này được cấp phép theo Creative Commons Attribution-Noncommercial-No Derivative Works 3.0 License. Xem bản sao giấy phép tại

[`https://creativecommons.org/licenses/by-nc-nd/3.0/`](https://creativecommons.org/licenses/by-nc-nd/3.0/)

hoặc gửi thư đến Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.

Một ngoại lệ cụ thể cho phần "No Derivative Works" là: tài liệu này được phép dịch tự do sang bất kỳ ngôn ngữ nào, với điều kiện bản dịch phải chính xác và tài liệu được in lại toàn bộ. Bản dịch phải tuân theo cùng điều khoản giấy phép với tài liệu gốc. Bản dịch cũng được phép ghi tên và thông tin liên lạc của người dịch.

Mã nguồn C trong tài liệu này được đưa vào public domain và hoàn toàn tự do sử dụng.

Các nhà giáo dục được khuyến khích giới thiệu hoặc cung cấp bản sao tài liệu này cho học sinh của mình.

Trừ khi có thỏa thuận bằng văn bản khác giữa các bên, tác giả cung cấp tác phẩm "nguyên trạng" và không đưa ra bất kỳ đảm bảo nào, dù rõ ràng hay ngụ ý, theo luật định hay cách khác, bao gồm nhưng không giới hạn ở các đảm bảo về quyền sở hữu, khả năng thương mại, phù hợp cho mục đích cụ thể, không vi phạm quyền, hay sự vắng mặt của các lỗi tiềm ẩn, tính chính xác, hay sự hiện diện hoặc vắng mặt của lỗi.

Trừ khi luật áp dụng yêu cầu, trong mọi trường hợp tác giả sẽ không chịu trách nhiệm pháp lý với bạn về bất kỳ thiệt hại đặc biệt, ngẫu nhiên, hệ quả, trừng phạt hay mang tính ví dụ nào phát sinh từ việc sử dụng tác phẩm, kể cả khi tác giả đã được thông báo về khả năng xảy ra thiệt hại đó.

Liên hệ [`beej@beej.us`](mailto:beej@beej.us) để biết thêm thông tin.
