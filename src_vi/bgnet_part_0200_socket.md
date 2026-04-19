# Socket là gì?

Bạn cứ nghe nói về "socket" suốt, và chắc đang thắc mắc chính xác thì
nó là cái gì. Thì nó là thế này: một cách để nói chuyện với các chương
trình khác qua [i[File descriptor]] file descriptor chuẩn của Unix.

Cái gì?

Được rồi, chắc bạn từng nghe một hacker Unix nào đó tuyên bố, "Trời
ạ, _mọi thứ_ trong Unix đều là file!". Ý họ nói là khi các chương
trình Unix làm I/O, chúng đọc hoặc ghi qua một file descriptor. File
descriptor đơn giản là một số nguyên gắn với một file đang mở. Nhưng
(điểm mấu chốt đây), "file" đó có thể là một kết nối mạng, một FIFO,
một pipe, một terminal, một file thật nằm trên đĩa, hay gần như bất
kỳ thứ gì khác. Mọi thứ trong Unix _đều là_ file! Vì vậy khi bạn
muốn nói chuyện với một chương trình khác qua Internet, bạn sẽ làm
điều đó qua một file descriptor, tin đi là vừa.

"Vậy kiếm cái file descriptor cho giao tiếp mạng này ở đâu, hở ông
Thông Thái?" có lẽ là câu cuối bạn định hỏi ngay lúc này, nhưng tôi
vẫn sẽ trả lời: Bạn gọi đến system routine [i[`socket()`
function]] `socket()`. Nó trả về [i[Socket
descriptor]] socket descriptor, và bạn giao tiếp qua nó bằng các lời
gọi socket chuyên dụng [i[`send()` function]] `send()` và [i[`recv()`
function]] `recv()` ([`man send`](#sendman), [`man recv`](#recvman)).

"Khoan đã!" có lẽ giờ bạn đang la lên. "Nếu đó là file descriptor,
thì vì sao quỷ thần ơi tôi không dùng luôn [i[`read()` function]]
`read()` và [i[`write()` function]] `write()` bình thường để giao
tiếp qua socket?" Câu trả lời ngắn là, "Được chứ!" Câu trả lời dài
hơn là, "Được, nhưng [i[`send()` function]]
`send()` và [i[`recv()` function]] `recv()` cho bạn nhiều quyền kiểm
soát hơn đối với việc truyền dữ liệu."

Tiếp theo là gì? Thế này nhé: có đủ loại socket. Có địa chỉ DARPA
Internet (Internet Socket), tên đường dẫn trên máy cục bộ (Unix
Socket), địa chỉ CCITT X.25 (X.25 Socket bạn cứ yên tâm bỏ qua), và
chắc còn nhiều loại khác tuỳ phiên bản Unix bạn chạy. Tài liệu này
chỉ bàn đến loại đầu tiên: Internet Socket.


## Hai loại internet socket

Gì cơ? Có hai loại Internet socket à? Đúng. Mà thôi, không. Tôi nói
dối đấy. Có nhiều hơn, chỉ là tôi không muốn làm bạn sợ. Ở đây tôi
chỉ nói về hai loại thôi. Ngoại trừ câu này, nơi tôi sẽ nói rằng
[i[Raw sockets]] "Raw Socket" cũng rất mạnh và bạn nên tìm hiểu
thêm.

Thôi được rồi. Hai loại đó là gì? Một là [i[Stream sockets]]
"Stream Socket"; cái kia là [i[Datagram sockets]] "Datagram Socket",
từ đây trở đi có thể được gọi là [i[`SOCK_STREAM` macro]]
"`SOCK_STREAM`" và [i[`SOCK_DGRAM` macro]] "`SOCK_DGRAM`" tương
ứng. Datagram socket đôi khi được gọi là "connectionless socket"
(socket phi kết nối). (Mặc dù chúng vẫn có thể [i[`connect()`
function]] `connect()` nếu bạn thật sự muốn. Xem
[`connect()`](#connect) bên dưới.)

Stream socket là luồng giao tiếp hai chiều, có kết nối, và đáng tin
cậy. Nếu bạn đẩy hai thứ vào socket theo thứ tự "1, 2", chúng sẽ đến
đầu bên kia đúng theo thứ tự "1, 2". Và cũng không có lỗi. Tôi chắc
chắn điều đó đến mức nếu ai đó dám cãi lại, tôi sẽ bịt tai lại và
ngân nga _la la la la_.

Cái gì dùng stream socket? Chắc bạn nghe nói đến mấy ứng dụng
[i[telnet]] `telnet` hay `ssh` rồi chứ? Chúng dùng stream socket.
Mọi ký tự bạn gõ cần đến đúng theo thứ tự bạn gõ, đúng không? Ngoài
ra, trình duyệt web dùng Hypertext Transfer Protocol [i[HTTP
protocol]] (HTTP), giao thức này dùng stream socket để lấy trang
web. Thật vậy, nếu bạn telnet vào một trang web ở port 80, gõ
"`GET / HTTP/1.0`" rồi nhấn RETURN hai lần, nó sẽ quăng cả đống HTML
vào mặt bạn!

> Nếu bạn không cài `telnet` và cũng không muốn cài, hoặc cái
> `telnet` của bạn kén chọn khi kết nối với client, tài liệu này
> kèm theo một chương trình giống `telnet` tên là [flx[`telnot`|telnot.c]].
> Nó đủ đáp ứng mọi nhu cầu trong tài liệu. (Lưu ý telnet thật ra là
> một [flrfc[giao thức mạng có đặc tả chuẩn|854]], còn `telnot` thì
> không implement giao thức đó chút nào.)

Stream socket đạt được chất lượng truyền dữ liệu cao như vậy bằng
cách nào? Chúng dùng một giao thức gọi là "Transmission Control
Protocol", hay còn được biết đến với tên [i[TCP]] "TCP" (xem
[flrfc[RFC 793|793]] để biết thông tin cực kỳ chi tiết về TCP). TCP
đảm bảo dữ liệu của bạn đến đúng thứ tự và không có lỗi. Có thể bạn
đã nghe "TCP" trước đây, như là nửa ngon lành của "TCP/IP", trong đó
[i[IP]] "IP" viết tắt cho "Internet Protocol" (xem [flrfc[RFC
791|791]]). IP chủ yếu lo việc định tuyến trên Internet và nhìn
chung không chịu trách nhiệm về tính toàn vẹn dữ liệu.

[i[Datagram sockets]<]

Ngon. Còn Datagram socket thì sao? Vì sao chúng được gọi là
connectionless? Nói chung chuyện là sao vậy? Vì sao chúng lại không
đáng tin cậy? Vài sự thật cho bạn đây: nếu bạn gửi một datagram, nó
_có thể_ đến nơi. Nó _có thể_ đến không đúng thứ tự. Nếu nó đến,
dữ liệu trong packet sẽ không có lỗi.

Datagram socket cũng dùng IP để định tuyến, nhưng không dùng TCP;
chúng dùng "User Datagram Protocol", hay [i[UDP]] "UDP" (xem
[flrfc[RFC 768|768]]).

Vì sao chúng là connectionless? Cơ bản là vì bạn không cần duy trì
một kết nối mở như với stream socket. Bạn chỉ cần đóng gói một
packet, gắn header IP với thông tin đích vào, rồi gửi đi. Không cần
kết nối. Chúng thường được dùng hoặc khi TCP stack không có sẵn,
hoặc khi vài packet rơi rụng đây đó không đồng nghĩa với tận thế.
Ứng dụng mẫu: `tftp` (trivial file transfer protocol, em họ bé tí
của FTP), `dhcpcd` (một DHCP client), game nhiều người chơi,
streaming audio, gọi video, v.v.

[i[Datagram sockets]>]

"Khoan đã! `tftp` và `dhcpcd` được dùng để chuyển các chương trình
nhị phân từ máy này sang máy khác! Dữ liệu không được phép mất nếu
muốn chương trình còn chạy được sau khi đến nơi! Loại phép thuật
đen tối gì vậy?"

Ờ, bạn người của tôi, `tftp` và các chương trình tương tự có giao
thức riêng chạy trên UDP. Ví dụ, giao thức tftp quy định rằng với
mỗi packet được gửi đi, bên nhận phải gửi lại một packet nói, "Tôi
nhận được rồi!" (một packet "ACK"). Nếu bên gửi packet gốc không
nhận được hồi âm trong, giả sử, năm giây, anh ta sẽ gửi lại packet
cho đến khi cuối cùng nhận được ACK. Thủ tục xác nhận này rất quan
trọng khi implement các ứng dụng `SOCK_DGRAM` đáng tin cậy.

Còn với các ứng dụng không cần độ tin cậy như game, audio, hay
video, bạn chỉ việc mặc kệ mấy packet bị rớt, hoặc tìm cách bù trừ
một cách khéo léo. (Dân chơi Quake sẽ nhận ra biểu hiện của hiện
tượng này với thuật ngữ kỹ thuật: _cái lag trời đánh_. Từ "trời
đánh" ở đây đại diện cho bất kỳ lời chửi thề cực kỳ tục tĩu nào.)

Vì sao lại dùng một giao thức nền không tin cậy? Hai lý do: tốc độ
và tốc độ. Gửi đi rồi quên luôn thì nhanh hơn nhiều so với việc
theo dõi cái gì đã đến nơi an toàn và đảm bảo thứ tự rồi đủ thứ
chuyện. Nếu bạn đang gửi tin nhắn chat, TCP tuyệt vời; nếu bạn đang
gửi 40 lần cập nhật vị trí mỗi giây của các người chơi trong thế
giới game, có lẽ một hai cái bị rớt cũng không sao lắm, và UDP là
lựa chọn tốt.


## Mấy thứ thấp cấp và lý thuyết mạng {#lowlevel}

Vì tôi vừa nhắc đến việc các giao thức xếp lớp lên nhau, đã đến lúc
nói về cách mạng thật sự hoạt động, và chỉ cho bạn xem vài ví dụ về
cách [i[`SOCK_DGRAM` macro]] `SOCK_DGRAM` packet được dựng lên.
Thực tế thì bạn có thể bỏ qua phần này. Tuy nhiên nó là kiến thức
nền tốt để có.

![Data Encapsulation.](dataencap.pdf "[Encapsulated Protocols Diagram]")

Này các cháu, đã đến lúc học về [i[Data encapsulation]] _Data
Encapsulation_! Cái này rất rất quan trọng. Quan trọng đến mức bạn
có thể sẽ được học nó nếu chọn môn mạng ở đây, trường Chico State
`;-)`. Cơ bản, nó nói như sau: một packet được sinh ra, packet được
bọc ("encapsulated") vào một [i[Data enacapsulation-->header]]
header (và hiếm khi là một [i[Data encapsulation-->footer]] footer)
bởi giao thức đầu tiên (ví dụ giao thức [i[TFTP]] TFTP), rồi toàn
bộ (kèm theo cả header TFTP bên trong) lại được bọc tiếp bởi giao
thức kế tiếp (ví dụ [i[UDP]] UDP), rồi lại được bọc bởi cái tiếp
nữa [i[IP]] (IP), rồi cuối cùng bởi giao thức ở tầng phần cứng
(vật lý) (ví dụ [i[Ethernet]] Ethernet).

Khi máy khác nhận được packet, phần cứng bóc header Ethernet ra,
kernel bóc header IP và UDP ra, chương trình TFTP bóc header TFTP
ra, và cuối cùng nó có được dữ liệu.

Giờ thì tôi mới có thể nói về cái [i[Layered network model]]
[i[ISO/OSI]] _Layered Network Model_ khét tiếng (hay còn gọi là
"ISO/OSI"). Mô hình mạng này mô tả một hệ thống chức năng mạng có
nhiều ưu điểm so với các mô hình khác. Ví dụ, bạn có thể viết các
chương trình socket giống hệt nhau mà chẳng cần quan tâm dữ liệu
được truyền đi về mặt vật lý thế nào (serial, thin Ethernet, AUI,
gì cũng được), vì các chương trình ở tầng thấp hơn lo chuyện đó
cho bạn. Phần cứng mạng thật sự và topology hoàn toàn trong suốt
với lập trình viên socket.

Không dông dài nữa, tôi sẽ trình bày các tầng của mô hình đầy đủ.
Nhớ cái này cho kỳ thi môn mạng nhé:

* Application
* Presentation
* Session
* Transport
* Network
* Data Link
* Physical

Physical Layer là phần cứng (serial, Ethernet, v.v.). Application
Layer thì cách xa tầng vật lý gần như xa hết mức bạn có thể tưởng
tượng, đó là nơi người dùng tương tác với mạng.

Mô hình này chung chung đến mức bạn có thể dùng nó làm sách hướng
dẫn sửa xe hơi nếu thật sự muốn. Một mô hình xếp lớp nhất quán hơn
với Unix có thể là:

* Application Layer (_telnet, ftp, v.v._)
* Host-to-Host Transport Layer (_TCP, UDP_)
* Internet Layer (_IP và định tuyến_)
* Network Access Layer (_Ethernet, wi-fi, hay gì đó_)

Đến đây, chắc bạn đã thấy các tầng này tương ứng với việc đóng gói
dữ liệu gốc như thế nào rồi.

Thấy cần bao nhiêu công đoạn để xây dựng một packet đơn giản chưa?
Trời ạ! Và bạn phải tự gõ các header packet bằng "`cat`"! Đùa thôi.
Với stream socket, tất cả việc bạn cần làm là [i[`send()` function]]
`send()` dữ liệu ra. Với datagram socket, bạn chỉ cần đóng gói
packet theo cách của mình rồi [i[`sendto()` function]] `sendto()`
đi. Kernel xây dựng Transport Layer và Internet Layer giúp bạn, còn
phần cứng lo Network Access Layer. Ôi, công nghệ hiện đại.

Thế là kết thúc chuyến ghé ngắn ngủi của chúng ta vào lý thuyết
mạng. À đúng rồi, tôi quên nói với bạn tất cả những gì tôi muốn nói
về định tuyến: không gì cả! Đúng vậy, tôi sẽ không nói về nó chút
nào. Router bóc packet ra đến header IP, tra bảng định tuyến,
[i[Blah blah blah]] _bla bla bla_. Xem [flrfc[RFC về IP|791]] nếu
bạn thật sự thật sự quan tâm. Nếu bạn không bao giờ học về nó, thì
cũng không sao, bạn vẫn sống được.
