# Một Vài Kỹ Thuật Hơi Nâng Cao

Mấy cái này thật ra không _nâng cao_ gì cho lắm, nhưng nó đã ra khỏi
phần căn bản mà chúng ta đã đi qua rồi. Thật ra, nếu bạn đã lê tới tận
đây, bạn có thể tự cho mình là khá thành thạo phần căn bản của lập
trình mạng Unix rồi đấy! Chúc mừng!

Vậy giờ chúng ta bước vào cái thế giới mới mẻ và rực rỡ của những thứ
bí hiểm hơn về socket mà bạn có thể muốn tìm hiểu. Chiến thôi!


## Blocking {#blocking}

[i[Blocking]<]

Blocking. Bạn đã nghe về nó rồi, vậy nó thực chất là cái quái gì? Nói
gọn, "block" là tiếng lóng dân kỹ thuật để chỉ "ngủ". Bạn chắc đã để ý
rằng khi chạy `listener` ở phía trên, nó cứ ngồi đó chờ cho đến khi có
gói tin đến. Cái xảy ra là nó đã gọi `recvfrom()`, chẳng có dữ liệu nào
cả, nên người ta nói `recvfrom()` đã "block" (nghĩa là nằm ngủ ở đó)
cho tới khi có dữ liệu.

Rất nhiều hàm bị block. `accept()` bị block. Toàn bộ họ hàng `recv()`
đều bị block. Lý do chúng làm được vậy là vì chúng được phép làm vậy.
Khi bạn tạo socket descriptor lần đầu bằng `socket()`, kernel đặt nó ở
chế độ blocking. [i[Non-blocking sockets]] Nếu bạn không muốn một
socket bị blocking, bạn phải gọi [i[`fcntl()` function]] `fcntl()`:

```{.c .numberLines}
#include <unistd.h>
#include <fcntl.h>
.
.
.
sockfd = socket(PF_INET, SOCK_STREAM, 0);
fcntl(sockfd, F_SETFL, O_NONBLOCK);
.
.
. 
```

Bằng cách đặt socket ở chế độ non-blocking, bạn có thể "poll" socket để
lấy thông tin một cách hiệu quả. Nếu bạn cố gắng đọc từ một socket
non-blocking mà không có dữ liệu, nó không được phép block, nó sẽ trả
về `-1` và `errno` được gán thành [i[`EAGAIN` macro]] `EAGAIN` hoặc
[i[`EWOULDBLOCK` macro]] `EWOULDBLOCK`.

(Khoan, nó có thể trả về [i[`EAGAIN` macro]] `EAGAIN` _hoặc_
[i[`EWOULDBLOCK` macro]] `EWOULDBLOCK`? Vậy phải kiểm tra cái nào? Đặc
tả thật ra không chỉ định hệ thống của bạn sẽ trả về cái nào, nên để
code chạy được trên mọi nơi, kiểm tra cả hai.)

Nói chung thì, kiểu polling này là ý tồi. Nếu bạn đặt chương trình vào
một vòng lặp busy-wait để tìm dữ liệu trên socket, bạn sẽ ngốn CPU như
thể nó miễn phí. Một giải pháp thanh lịch hơn để kiểm tra xem có dữ
liệu đang đợi được đọc hay không sẽ xuất hiện trong phần tiếp theo về
[i[`poll()` function]] `poll()`.

[i[Blocking]>]

## `poll()`: Synchronous I/O Multiplexing {#poll}

[i[poll()]<]

Cái bạn thực sự muốn làm là bằng cách nào đó theo dõi _một đống_ socket
cùng lúc rồi xử lý những cái nào đã có dữ liệu sẵn. Như vậy bạn không
cần phải liên tục poll tất cả mấy cái socket đó xem cái nào sẵn sàng
đọc.

> _Xin lưu ý: `poll()` chậm kinh khủng khi số lượng kết nối cực lớn.
> Trong những tình huống đó, bạn sẽ có hiệu năng tốt hơn nếu dùng một
> event library như [fl[libevent|https://libevent.org/]], thư viện này
> cố gắng dùng phương pháp nhanh nhất có sẵn trên hệ thống của bạn._

Vậy làm sao tránh được polling? Một cách có chút trớ trêu là, bạn có
thể tránh polling bằng cách dùng system call `poll()`. Nói gọn, chúng
ta sẽ nhờ hệ điều hành làm hết phần việc bẩn cho mình, và chỉ cần báo
cho chúng ta biết khi nào có dữ liệu sẵn sàng để đọc trên socket nào.
Trong thời gian đó, process của chúng ta có thể nằm ngủ, tiết kiệm tài
nguyên hệ thống.

Kế hoạch chung là giữ một mảng `struct pollfd` chứa thông tin về những
socket descriptor nào chúng ta muốn theo dõi, và muốn theo dõi những
loại sự kiện nào. Hệ điều hành sẽ block ở lời gọi `poll()` cho đến khi
một trong những sự kiện đó xảy ra (ví dụ "socket sẵn sàng để đọc!")
hoặc cho đến khi hết thời gian timeout mà người dùng đặt.

Tiện lợi ở chỗ, một socket đang `listen()` sẽ báo "sẵn sàng đọc" khi có
một kết nối mới sẵn sàng để `accept()`.

Nói đủ rồi. Làm sao dùng cái này đây?

``` {.c}
#include <poll.h>

int poll(struct pollfd fds[], nfds_t nfds, int timeout);
```

`fds` là mảng thông tin (socket nào theo dõi cái gì), `nfds` là số phần
tử trong mảng, còn `timeout` là timeout tính bằng milliseconds. Nó trả
về số phần tử trong mảng đã có sự kiện xảy ra.

Hãy xem qua cái `struct` đó:

[i[`struct pollfd` type]]

``` {.c}
struct pollfd {
    int fd;         // the socket descriptor
    short events;   // bitmap of events we're interested in
    short revents;  // on return, bitmap of events that occurred
};
```

Vậy chúng ta sẽ có một mảng những cái đó, và sẽ đặt trường `fd` của
mỗi phần tử bằng socket descriptor mà chúng ta quan tâm theo dõi. Rồi
chúng ta sẽ đặt trường `events` để chỉ định loại sự kiện quan tâm.

Trường `events` là phép OR bit của các giá trị sau:

| Macro     | Mô tả                                                      |
|-----------|------------------------------------------------------------|
| `POLLIN`  | Báo cho tôi khi có dữ liệu sẵn sàng để `recv()` trên socket này. |
| `POLLOUT` | Báo cho tôi khi tôi có thể `send()` dữ liệu đến socket này mà không bị block. |
| `POLLHUP` | Báo cho tôi khi đầu bên kia đóng kết nối. |

Khi đã có mảng `struct pollfd` sẵn sàng, bạn có thể truyền nó cho
`poll()`, kèm theo kích thước mảng, cùng với giá trị timeout tính bằng
milliseconds. (Bạn có thể chỉ định timeout âm để chờ mãi.)

Sau khi `poll()` trả về, bạn có thể kiểm tra trường `revents` để xem
`POLLIN` hoặc `POLLOUT` có được bật không, cho biết sự kiện đó đã xảy
ra.

(Thật ra bạn có thể làm nhiều hơn với `poll()`. Xem [man page của
`poll()`, ở phía dưới](#pollman), để biết chi tiết.)

Đây là [flx[một ví dụ|poll.c]], chúng ta chờ 2.5 giây để có dữ liệu sẵn
sàng đọc từ standard input, tức là khi bạn bấm `RETURN`:

``` {.c .numberLines}
#include <stdio.h>
#include <poll.h>

int main(void)
{
    struct pollfd pfds[1]; // More if you want to monitor more

    pfds[0].fd = 0;          // Standard input
    pfds[0].events = POLLIN; // Tell me when ready to read

    // If you needed to monitor other things, as well:
    //pfds[1].fd = some_socket; // Some socket descriptor
    //pfds[1].events = POLLIN;  // Tell me when ready to read

    printf("Hit RETURN or wait 2.5 seconds for timeout\n");

    int num_events = poll(pfds, 1, 2500); // 2.5 second timeout

    if (num_events == 0) {
        printf("Poll timed out!\n");
    } else {
        int pollin_happened = pfds[0].revents & POLLIN;

        if (pollin_happened) {
            printf("File descriptor %d is ready to read\n",
                    pfds[0].fd);
        } else {
            printf("Unexpected event occurred: %d\n",
                    pfds[0].revents);
        }
    }

    return 0;
}
```

Chú ý lại rằng `poll()` trả về số phần tử trong mảng `pfds` mà có sự
kiện xảy ra. Nó _không_ cho bạn biết _phần tử nào_ trong mảng (bạn vẫn
phải quét để tìm), nhưng nó có cho bạn biết có bao nhiêu phần tử có
trường `revents` khác không (nên bạn có thể ngừng quét sau khi tìm
được đủ số đó).

Có vài câu hỏi có thể nảy ra ở đây: làm sao thêm file descriptor mới
vào tập hợp truyền cho `poll()`? Cho cái này, chỉ cần đảm bảo bạn có đủ
chỗ trong mảng cho tất cả những gì bạn cần, hoặc `realloc()` thêm chỗ
khi cần.

Còn việc xóa phần tử khỏi tập hợp thì sao? Cho cái này, bạn có thể sao
chép phần tử cuối cùng trong mảng đè lên phần tử bạn đang xóa. Rồi
truyền vào một số đếm nhỏ hơn một đơn vị cho `poll()`. Một cách khác là
bạn có thể đặt trường `fd` thành một số âm và `poll()` sẽ bỏ qua nó.

Làm sao ráp tất cả lại thành một chat server mà bạn có thể `telnet`
vào?

Cái chúng ta sẽ làm là khởi tạo một listener socket, rồi thêm nó vào
tập file descriptor cho `poll()` theo dõi. (Nó sẽ báo sẵn-sàng-đọc khi
có kết nối đi tới.)

Rồi chúng ta sẽ thêm các kết nối mới vào mảng `struct pollfd` của mình.
Và chúng ta sẽ mở rộng nó linh động nếu hết chỗ.

Khi một kết nối bị đóng, chúng ta sẽ xóa nó khỏi mảng.

Và khi một kết nối sẵn-sàng-đọc, chúng ta sẽ đọc dữ liệu từ nó và gửi
dữ liệu đó tới tất cả các kết nối khác để họ thấy được người khác gõ
gì.

Hãy thử [flx[poll server này|pollserver.c]]. Chạy nó trong một cửa sổ,
rồi `telnet localhost 9034` từ một số cửa sổ terminal khác. Bạn sẽ thấy
được những gì bạn gõ trong một cửa sổ hiện ra ở những cửa sổ kia (sau
khi bấm RETURN).

Không chỉ vậy, nếu bạn bấm `CTRL-]` rồi gõ `quit` để thoát `telnet`,
server sẽ phát hiện việc ngắt kết nối và xóa bạn khỏi mảng file
descriptor.

``` {.c .numberLines}
/*
** pollserver.c -- a cheezy multiperson chat server
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <poll.h>

#define PORT "9034"   // Port we're listening on

/*
 * Convert socket to IP address string.
 * addr: struct sockaddr_in or struct sockaddr_in6
 */
const char *inet_ntop2(void *addr, char *buf, size_t size)
{
    struct sockaddr_storage *sas = addr;
    struct sockaddr_in *sa4;
    struct sockaddr_in6 *sa6;
    void *src;

    switch (sas->ss_family) {
        case AF_INET:
            sa4 = addr;
            src = &(sa4->sin_addr);
            break;
        case AF_INET6:
            sa6 = addr;
            src = &(sa6->sin6_addr);
            break;
        default:
            return NULL;
    }

    return inet_ntop(sas->ss_family, src, buf, size);
}

/*
 * Return a listening socket.
 */
int get_listener_socket(void)
{
    int listener;     // Listening socket descriptor
    int yes=1;        // For setsockopt() SO_REUSEADDR, below
    int rv;

    struct addrinfo hints, *ai, *p;

    // Get us a socket and bind it
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0) {
        fprintf(stderr, "pollserver: %s\n", gai_strerror(rv));
        exit(1);
    }

    for(p = ai; p != NULL; p = p->ai_next) {
        listener = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol);
        if (listener < 0) {
            continue;
        }

        // Lose the pesky "address already in use" error message
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes,
                sizeof(int));

        if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
            close(listener);
            continue;
        }

        break;
    }

    // If we got here, it means we didn't get bound
    if (p == NULL) {
        return -1;
    }

    freeaddrinfo(ai); // All done with this

    // Listen
    if (listen(listener, 10) == -1) {
        return -1;
    }

    return listener;
}

/*
 * Add a new file descriptor to the set.
 */
void add_to_pfds(struct pollfd **pfds, int newfd, int *fd_count,
        int *fd_size)
{
    // If we don't have room, add more space in the pfds array
    if (*fd_count == *fd_size) {
        *fd_size *= 2; // Double it
        *pfds = realloc(*pfds, sizeof(**pfds) * (*fd_size));
    }

    (*pfds)[*fd_count].fd = newfd;
    (*pfds)[*fd_count].events = POLLIN; // Check ready-to-read
    (*pfds)[*fd_count].revents = 0;

    (*fd_count)++;
}

/*
 * Remove a file descriptor at a given index from the set.
 */
void del_from_pfds(struct pollfd pfds[], int i, int *fd_count)
{
    // Copy the one from the end over this one
    pfds[i] = pfds[*fd_count-1];

    (*fd_count)--;
}

/*
 * Handle incoming connections.
 */
void handle_new_connection(int listener, int *fd_count,
        int *fd_size, struct pollfd **pfds)
{
    struct sockaddr_storage remoteaddr; // Client address
    socklen_t addrlen;
    int newfd;  // Newly accept()ed socket descriptor
    char remoteIP[INET6_ADDRSTRLEN];

    addrlen = sizeof remoteaddr;
    newfd = accept(listener, (struct sockaddr *)&remoteaddr,
            &addrlen);

    if (newfd == -1) {
        perror("accept");
    } else {
        add_to_pfds(pfds, newfd, fd_count, fd_size);

        printf("pollserver: new connection from %s on socket %d\n",
                inet_ntop2(&remoteaddr, remoteIP, sizeof remoteIP),
                newfd);
    }
}

/*
 * Handle regular client data or client hangups.
 */
void handle_client_data(int listener, int *fd_count,
        struct pollfd *pfds, int *pfd_i)
{
    char buf[256];    // Buffer for client data

    int nbytes = recv(pfds[*pfd_i].fd, buf, sizeof buf, 0);

    int sender_fd = pfds[*pfd_i].fd;

    if (nbytes <= 0) { // Got error or connection closed by client
        if (nbytes == 0) {
            // Connection closed
            printf("pollserver: socket %d hung up\n", sender_fd);
        } else {
            perror("recv");
        }

        close(pfds[*pfd_i].fd); // Bye!

        del_from_pfds(pfds, *pfd_i, fd_count);

        // reexamine the slot we just deleted
        (*pfd_i)--;

    } else { // We got some good data from a client
        printf("pollserver: recv from fd %d: %.*s", sender_fd,
                nbytes, buf);
        // Send to everyone!
        for(int j = 0; j < *fd_count; j++) {
            int dest_fd = pfds[j].fd;

            // Except the listener and ourselves
            if (dest_fd != listener && dest_fd != sender_fd) {
                if (send(dest_fd, buf, nbytes, 0) == -1) {
                    perror("send");
                }
            }
        }
    }
}

/*
 * Process all existing connections.
 */
void process_connections(int listener, int *fd_count, int *fd_size,
        struct pollfd **pfds)
{
    for(int i = 0; i < *fd_count; i++) {

        // Check if someone's ready to read
        if ((*pfds)[i].revents & (POLLIN | POLLHUP)) {
            // We got one!!

            if ((*pfds)[i].fd == listener) {
                // If we're the listener, it's a new connection
                handle_new_connection(listener, fd_count, fd_size,
                        pfds);
            } else {
                // Otherwise we're just a regular client
                handle_client_data(listener, fd_count, *pfds, &i);
            }
        }
    }
}

/*
 * Main: create a listener and connection set, loop forever
 * processing connections.
 */
int main(void)
{
    int listener;     // Listening socket descriptor

    // Start off with room for 5 connections
    // (We'll realloc as necessary)
    int fd_size = 5;
    int fd_count = 0;
    struct pollfd *pfds = malloc(sizeof *pfds * fd_size);

    // Set up and get a listening socket
    listener = get_listener_socket();

    if (listener == -1) {
        fprintf(stderr, "error getting listening socket\n");
        exit(1);
    }

    // Add the listener to set;
    // Report ready to read on incoming connection
    pfds[0].fd = listener;
    pfds[0].events = POLLIN;

    fd_count = 1; // For the listener

    puts("pollserver: waiting for connections...");

    // Main loop
    for(;;) {
        int poll_count = poll(pfds, fd_count, -1);

        if (poll_count == -1) {
            perror("poll");
            exit(1);
        }

        // Run through connections looking for data to read
        process_connections(listener, &fd_count, &fd_size, &pfds);
    }

    free(pfds);
}
```

Trong phần tiếp theo, chúng ta sẽ xem một hàm tương tự, cũ hơn, gọi là
`select()`. Cả `select()` và `poll()` đều có chức năng và hiệu năng
tương tự nhau, chỉ khác nhau ở cách dùng. `select()` có thể portable
hơn một chút, nhưng có lẽ hơi cồng kềnh khi sử dụng. Chọn cái nào bạn
thích nhất, miễn là nó được hỗ trợ trên hệ thống của bạn.

[i[poll()]>]


## `select()`: Synchronous I/O Multiplexing, Kiểu Cổ Điển {#select}

[i[`select()` function]<]

Hàm này hơi lạ, nhưng rất hữu ích. Hãy tưởng tượng tình huống sau: bạn
là một server, bạn muốn lắng nghe các kết nối mới đi tới đồng thời vẫn
tiếp tục đọc từ những kết nối bạn đã có.

Không thành vấn đề, bạn nói, chỉ cần một `accept()` và vài cái
`recv()` là xong. Khoan đã, anh bạn! Lỡ bạn đang block ở lời gọi
`accept()` thì sao? Bạn sẽ `recv()` dữ liệu kiểu gì cùng lúc đó? "Dùng
socket non-blocking đi!" Còn lâu! Bạn đâu muốn thành kẻ ngốn CPU. Vậy
thì sao?

`select()` cho bạn quyền năng theo dõi nhiều socket cùng một lúc. Nó
sẽ cho bạn biết cái nào sẵn sàng đọc, cái nào sẵn sàng ghi, và cái nào
đã phát sinh exception, nếu bạn thực sự muốn biết cái đó.

> _Xin lưu ý: `select()`, dù rất portable, chậm kinh khủng khi số
> lượng kết nối cực lớn. Trong những tình huống đó, bạn sẽ có hiệu
> năng tốt hơn nếu dùng một event library như
> [fl[libevent|https://libevent.org/]], thư viện này cố gắng dùng
> phương pháp nhanh nhất có sẵn trên hệ thống của bạn._

Không dài dòng nữa, tôi sẽ giới thiệu tóm tắt về `select()`:

```{.c}
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

int select(int numfds, fd_set *readfds, fd_set *writefds,
           fd_set *exceptfds, struct timeval *timeout); 
```

Hàm này theo dõi các "tập hợp" file descriptor; cụ thể là `readfds`,
`writefds`, và `exceptfds`. Nếu bạn muốn xem mình có thể đọc từ
standard input và một socket descriptor nào đó, `sockfd`, thì chỉ cần
thêm các file descriptor `0` và `sockfd` vào tập `readfds`. Tham số
`numfds` nên được đặt bằng giá trị của file descriptor cao nhất cộng
một. Trong ví dụ này, nó nên được đặt thành `sockfd+1`, vì chắc chắn
nó cao hơn standard input (`0`).

Khi `select()` trả về, `readfds` sẽ bị sửa để phản ánh cái nào trong
các file descriptor bạn đã chọn là sẵn sàng để đọc. Bạn có thể kiểm
tra chúng bằng macro `FD_ISSET()`, ở phía dưới.

Trước khi đi xa hơn, tôi sẽ nói về cách thao tác với các tập hợp này.
Mỗi tập thuộc kiểu `fd_set`. Các macro sau làm việc với kiểu này:

| Hàm                              | Mô tả                                |
|----------------------------------|--------------------------------------|
| [i[`FD_SET()` macro]]`FD_SET(int fd, fd_set *set);`   | Thêm `fd` vào `set`.               |
| [i[`FD_CLR()` macro]]`FD_CLR(int fd, fd_set *set);`   | Bỏ `fd` khỏi `set`.          |
| [i[`FD_ISSET()` macro]]`FD_ISSET(int fd, fd_set *set);` | Trả về true nếu `fd` nằm trong `set`. |
| [i[`FD_ZERO()` macro]]`FD_ZERO(fd_set *set);`          | Xóa toàn bộ phần tử khỏi `set`.    |

[i[`struct timeval` type]<]

Cuối cùng, cái `struct timeval` lạ đời này là gì vậy? Nhiều khi bạn
không muốn chờ vô tận để ai đó gửi dữ liệu. Có thể cứ mỗi 96 giây bạn
muốn in "Still Going..." ra terminal mặc dù chẳng có gì xảy ra. Cái
struct thời gian này cho phép bạn chỉ định khoảng thời gian timeout.
Nếu thời gian bị vượt quá mà `select()` vẫn chưa tìm thấy file
descriptor nào sẵn sàng, nó sẽ trả về để bạn có thể tiếp tục xử lý.

`struct timeval` có các trường sau:

```{.c}
struct timeval {
    int tv_sec;     // seconds
    int tv_usec;    // microseconds
}; 
```

Chỉ cần gán `tv_sec` bằng số giây cần chờ, và `tv_usec` bằng số
microsecond cần chờ. Vâng, là _micro_second, không phải millisecond.
Có 1.000 microsecond trong một millisecond, và 1.000 millisecond trong
một giây. Như vậy, có 1.000.000 microsecond trong một giây. Tại sao
lại là "usec"? Chữ "u" được vẽ trông giống chữ cái Hy Lạp μ (Mu) mà
chúng ta dùng cho "micro". Ngoài ra, khi hàm trả về, `timeout` _có
thể_ được cập nhật để cho biết thời gian còn lại. Cái này tùy vào bản
Unix bạn đang chạy.

Yay! Chúng ta có timer độ phân giải microsecond! Khoan đã, đừng tin
vào điều đó. Chắc bạn sẽ phải chờ một phần khoảng timeslice tiêu chuẩn
của Unix bất kể bạn đặt `struct timeval` nhỏ cỡ nào.

Một vài chuyện thú vị khác: Nếu bạn gán các trường trong `struct
timeval` thành `0`, `select()` sẽ timeout ngay lập tức, về bản chất là
poll toàn bộ file descriptor trong các tập của bạn. Nếu bạn đặt tham
số `timeout` thành NULL, nó sẽ không bao giờ timeout, và sẽ chờ cho
đến khi file descriptor đầu tiên sẵn sàng. Cuối cùng, nếu bạn không
quan tâm đến việc chờ một tập nào đó, bạn chỉ cần đặt nó thành NULL
trong lời gọi `select()`.

[flx[Đoạn code sau|select.c]] chờ 2.5 giây để có thứ gì đó xuất hiện
trên standard input:

```{.c .numberLines}
/*
** select.c -- a select() demo
*/

#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define STDIN 0  // file descriptor for standard input

int main(void)
{
    struct timeval tv;
    fd_set readfds;

    tv.tv_sec = 2;
    tv.tv_usec = 500000;

    FD_ZERO(&readfds);
    FD_SET(STDIN, &readfds);

    // don't care about writefds and exceptfds:
    select(STDIN+1, &readfds, NULL, NULL, &tv);

    if (FD_ISSET(STDIN, &readfds))
        printf("A key was pressed!\n");
    else
        printf("Timed out.\n");

    return 0;
} 
```

Nếu bạn đang dùng terminal chế độ line-buffered, phím bạn bấm phải là
RETURN, nếu không nó vẫn sẽ timeout.

Lúc này, một vài người trong các bạn có thể nghĩ đây là cách tuyệt vời
để chờ dữ liệu trên datagram socket, và các bạn đúng: nó _có thể_.
Một số Unix có thể dùng select theo kiểu này, một số thì không. Bạn
nên xem man page địa phương của mình nói gì về chuyện này nếu muốn thử.

Một số Unix cập nhật thời gian trong `struct timeval` của bạn để phản
ánh lượng thời gian còn lại trước khi timeout. Nhưng số khác thì
không. Đừng trông cậy vào chuyện đó nếu bạn muốn portable. (Dùng
[i[`gettimeofday()` function]] `gettimeofday()` nếu bạn cần theo dõi
thời gian đã trôi qua. Đáng tiếc, tôi biết, nhưng sự đời là vậy.)

[i[`struct timeval` type]>]

Chuyện gì xảy ra nếu một socket trong tập đọc đóng kết nối? Trong
trường hợp đó, `select()` sẽ trả về với socket descriptor đó được đánh
dấu là "sẵn sàng đọc". Khi bạn thực sự `recv()` từ nó, `recv()` sẽ trả
về `0`. Đó là cách bạn biết client đã đóng kết nối.

Một điểm thú vị nữa về `select()`: nếu bạn có một socket đang
[i[`select()` function-->with `listen()`]]
[i[`listen()` function-->with `select()`]]
`listen()`, bạn có thể kiểm tra xem có kết nối mới hay không bằng cách
đặt file descriptor của socket đó vào tập `readfds`.

Và đó, các bạn của tôi, là tổng quan nhanh về hàm `select()` đầy quyền
năng.

Nhưng, theo yêu cầu đông đảo, đây là một ví dụ chi tiết. Không may, sự
khác biệt giữa ví dụ đơn giản như bùn ở trên và cái này đây là đáng
kể. Nhưng hãy xem qua, rồi đọc phần mô tả đi kèm sau đó.

[flx[Chương trình này|selectserver.c]] hoạt động như một chat server
đa người dùng đơn giản. Khởi động nó trong một cửa sổ, rồi `telnet`
vào ("`telnet hostname 9034`") từ nhiều cửa sổ khác. Khi bạn gõ gì đó
trong một phiên `telnet`, nó sẽ xuất hiện ở tất cả phiên còn lại.

```{.c .numberLines}
/*
** selectserver.c -- a cheezy multiperson chat server
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define PORT "9034"   // port we're listening on

/*
 * Convert socket to IP address string.
 * addr: struct sockaddr_in or struct sockaddr_in6
 */
const char *inet_ntop2(void *addr, char *buf, size_t size)
{
    struct sockaddr_storage *sas = addr;
    struct sockaddr_in *sa4;
    struct sockaddr_in6 *sa6;
    void *src;

    switch (sas->ss_family) {
        case AF_INET:
            sa4 = addr;
            src = &(sa4->sin_addr);
            break;
        case AF_INET6:
            sa6 = addr;
            src = &(sa6->sin6_addr);
            break;
        default:
            return NULL;
    }

    return inet_ntop(sas->ss_family, src, buf, size);
}

/*
 * Return a listening socket
 */
int get_listener_socket(void)
{
    struct addrinfo hints, *ai, *p;
    int yes=1;    // for setsockopt() SO_REUSEADDR, below
    int rv;
    int listener;

    // get us a socket and bind it
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0) {
        fprintf(stderr, "selectserver: %s\n", gai_strerror(rv));
        exit(1);
    }

    for(p = ai; p != NULL; p = p->ai_next) {
        listener = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol);
        if (listener < 0) {
            continue;
        }

        // lose the pesky "address already in use" error message
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes,
                sizeof(int));

        if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
            close(listener);
            continue;
        }

        break;
    }

    // if we got here, it means we didn't get bound
    if (p == NULL) {
        fprintf(stderr, "selectserver: failed to bind\n");
        exit(2);
    }

    freeaddrinfo(ai); // all done with this

    // listen
    if (listen(listener, 10) == -1) {
        perror("listen");
        exit(3);
    }

    return listener;
}

/*
 * Add new incoming connections to the proper sets
 */
void handle_new_connection(int listener, fd_set *master, int *fdmax)
{
    socklen_t addrlen;
    int newfd;        // newly accept()ed socket descriptor
    struct sockaddr_storage remoteaddr; // client address
    char remoteIP[INET6_ADDRSTRLEN];

    addrlen = sizeof remoteaddr;
    newfd = accept(listener,
        (struct sockaddr *)&remoteaddr,
        &addrlen);

    if (newfd == -1) {
        perror("accept");
    } else {
        FD_SET(newfd, master); // add to master set
        if (newfd > *fdmax) {  // keep track of the max
            *fdmax = newfd;
        }
        printf("selectserver: new connection from %s on "
            "socket %d\n",
            inet_ntop2(&remoteaddr, remoteIP, sizeof remoteIP),
            newfd);
    }
}

/*
 * Broadcast a message to all clients
 */
void broadcast(char *buf, int nbytes, int listener, int s,
               fd_set *master, int fdmax)
{
    for(int j = 0; j <= fdmax; j++) {
        // send to everyone!
        if (FD_ISSET(j, master)) {
            // except the listener and ourselves
            if (j != listener && j != s) {
                if (send(j, buf, nbytes, 0) == -1) {
                    perror("send");
                }
            }
        }
    }
}

/*
 * Handle client data and hangups
 */
void handle_client_data(int s, int listener, fd_set *master,
                        int fdmax)
{
    char buf[256];    // buffer for client data
    int nbytes;

    // handle data from a client
    if ((nbytes = recv(s, buf, sizeof buf, 0)) <= 0) {
        // got error or connection closed by client
        if (nbytes == 0) {
            // connection closed
            printf("selectserver: socket %d hung up\n", s);
        } else {
            perror("recv");
        }
        close(s); // bye!
        FD_CLR(s, master); // remove from master set
    } else {
        // we got some data from a client
        broadcast(buf, nbytes, listener, s, master, fdmax);
    }
}

/*
 * Main
 */
int main(void)
{
    fd_set master;    // master file descriptor list
    fd_set read_fds;  // temp file descriptor list for select()
    int fdmax;        // maximum file descriptor number

    int listener;     // listening socket descriptor

    FD_ZERO(&master);    // clear the master and temp sets
    FD_ZERO(&read_fds);

    listener = get_listener_socket();

    // add the listener to the master set
    FD_SET(listener, &master);

    // keep track of the biggest file descriptor
    fdmax = listener; // so far, it's this one

    // main loop
    for(;;) {
        read_fds = master; // copy it
        if (select(fdmax+1, &read_fds, NULL, NULL, NULL) == -1) {
            perror("select");
            exit(4);
        }

        // run through the existing connections looking for data
        // to read
        for(int i = 0; i <= fdmax; i++) {
            if (FD_ISSET(i, &read_fds)) { // we got one!!
                if (i == listener)
                    handle_new_connection(i, &master, &fdmax);
                else
                    handle_client_data(i, listener, &master, fdmax);
            }
        }
    }

    return 0;
}
```

Chú ý rằng tôi có hai tập file descriptor trong code: `master` và
`read_fds`. Tập đầu, `master`, giữ tất cả socket descriptor hiện đang
được kết nối, cũng như socket descriptor đang lắng nghe kết nối mới.

Lý do tôi có tập `master` là vì `select()` thật sự _sửa_ tập bạn
truyền vào để phản ánh socket nào đang sẵn sàng đọc. Vì tôi phải theo
dõi các kết nối từ lần gọi `select()` này qua lần gọi kế, tôi phải
giữ chúng ở một nơi an toàn. Vào phút chót, tôi sao chép `master`
sang `read_fds`, rồi mới gọi `select()`.

Nhưng chẳng phải điều đó có nghĩa là mỗi lần tôi có kết nối mới, tôi
phải thêm nó vào tập `master` sao? Chuẩn! Và mỗi khi một kết nối
đóng, tôi phải xóa nó khỏi tập `master` à? Vâng, đúng vậy.

Chú ý là tôi kiểm tra khi nào socket `listener` sẵn sàng đọc. Khi nó
sẵn sàng, nghĩa là tôi có một kết nối mới đang chờ, và tôi `accept()`
nó rồi thêm vào tập `master`. Tương tự, khi một kết nối client sẵn
sàng đọc, và `recv()` trả về `0`, tôi biết client đã đóng kết nối, và
tôi phải xóa nó khỏi tập `master`.

Nếu `recv()` của client trả về khác không, thì tôi biết đã có dữ liệu
được nhận. Nên tôi lấy nó, rồi duyệt qua danh sách `master` và gửi dữ
liệu đó đến tất cả các client đang kết nối còn lại.

Và đó, các bạn của tôi, là tổng quan không-hẳn-là-đơn-giản về hàm
`select()` đầy quyền năng.

Một chú ý nhanh cho các fan Linux ngoài kia: đôi lúc, trong vài tình
huống hiếm hoi, `select()` của Linux có thể trả về "sẵn-sàng-đọc" rồi
thật ra lại không sẵn sàng đọc! Nghĩa là nó sẽ block ở `read()` sau
khi `select()` bảo nó sẽ không block! Trời ạ, cái thằng! Cách khắc
phục là bật cờ [i[`O_NONBLOCK` macro]] `O_NONBLOCK` trên socket nhận
để nó trả về lỗi `EWOULDBLOCK` (mà bạn có thể an toàn bỏ qua nếu nó
xảy ra). Xem [trang tham khảo `fcntl()`](#fcntlman) để biết thêm về
cách đặt socket ở chế độ non-blocking.

Thêm nữa, đây là một ghi chú bonus: có một hàm khác gọi là
[i[`poll()` function]] `poll()` hoạt động khá giống `select()`, nhưng
với hệ thống quản lý tập file descriptor khác. [Xem qua
đi!](#pollman)

[i[`select()` function]>]

## Xử Lý `send()` Một Phần {#sendall}

Còn nhớ hồi ở [phần về `send()`](#sendrecv) phía trên, tôi đã nói
rằng `send()` có thể không gửi hết số byte bạn yêu cầu chứ? Nghĩa là,
bạn muốn nó gửi 512 byte, nhưng nó trả về 412. Chuyện gì xảy ra với
100 byte còn lại?

Chúng vẫn còn trong cái buffer nhỏ của bạn, đang đợi được gửi đi. Vì
những hoàn cảnh ngoài tầm kiểm soát của bạn, kernel đã quyết định
không gửi tất cả dữ liệu ra trong một đợt, và giờ, bạn ơi, đến lượt
bạn phải đẩy dữ liệu đó ra.

[i[`sendall()` function]<]
Bạn có thể viết một hàm như thế này để làm việc đó:

```{.c .numberLines}
#include <sys/types.h>
#include <sys/socket.h>

int sendall(int s, char *buf, int *len)
{
    int total = 0;        // how many bytes we've sent
    int bytesleft = *len; // how many we have left to send
    int n;

    while(total < *len) {
        n = send(s, buf+total, bytesleft, 0);
        if (n == -1) { break; }
        total += n;
        bytesleft -= n;
    }

    *len = total; // return number actually sent here

    return n==-1?-1:0; // return -1 on failure, 0 on success
} 
```

Trong ví dụ này, `s` là socket bạn muốn gửi dữ liệu đến, `buf` là
buffer chứa dữ liệu, và `len` là con trỏ trỏ tới một `int` chứa số
byte trong buffer.

Hàm trả về `-1` khi có lỗi (và `errno` vẫn còn được gán từ lời gọi
`send()`). Ngoài ra, số byte thực sự được gửi được trả về trong
`len`. Nó sẽ là cùng một số byte bạn yêu cầu gửi, trừ khi có lỗi.
`sendall()` sẽ cố hết sức, hổn hển thở dốc, để gửi dữ liệu ra, nhưng
nếu có lỗi, nó sẽ báo lại cho bạn ngay.

Cho đầy đủ, đây là một lời gọi mẫu của hàm:

```{.c .numberLines}
char buf[10] = "Beej!";
int len;

len = strlen(buf);
if (sendall(s, buf, &len) == -1) {
    perror("sendall");
    printf("We only sent %d bytes because of the error!\n", len);
} 
```

[i[`sendall()` function]>]

Chuyện gì xảy ra ở đầu bên nhận khi chỉ một phần gói tin đến? Nếu các
gói tin có độ dài biến đổi, làm sao bên nhận biết khi nào một gói kết
thúc và một gói khác bắt đầu? Vâng, các tình huống đời thực là một
cơn đau đầu kiểu hoàng gia nhức cả [i[Donkeys]] mông. Chắc bạn sẽ
phải [i[Data encapsulation]] _đóng gói_ (còn nhớ chuyện đó từ [phần
về đóng gói dữ liệu](#lowlevel) mãi tít đằng trước chứ?) Đọc tiếp đi!


## Serialization: Cách Gói Dữ Liệu {#serialization}

[i[Serialization]<]

Gửi dữ liệu dạng text qua mạng thì khá dễ, bạn đang thấy vậy, nhưng
sẽ ra sao nếu bạn muốn gửi dữ liệu "nhị phân" như `int` hay `float`?
Hóa ra bạn có một vài lựa chọn.

1. Chuyển con số thành text bằng hàm như `sprintf()`, rồi gửi text.
   Bên nhận sẽ phân tích text trở lại thành số bằng hàm như
   `strtol()`.

2. Cứ gửi dữ liệu thô, truyền một con trỏ trỏ tới dữ liệu cho
   `send()`.

3. Mã hóa con số thành một dạng nhị phân portable. Bên nhận sẽ giải
   mã.

Xem trước nhanh! Chỉ đêm nay thôi!

[_Màn sân khấu kéo lên_]

Beej nói, "Tôi thích Cách Ba ở trên nhất!"

[_HẾT_]

(Trước khi bắt đầu phần này một cách nghiêm túc, tôi phải nói với bạn
rằng có các thư viện ngoài kia làm việc này, và tự cuộn tay làm lấy
mà vẫn portable và không có lỗi là một thử thách đáng kể. Nên đi tìm
hiểu và làm bài tập về nhà trước khi quyết định tự tay làm mấy thứ
này. Tôi đưa thông tin vào đây cho ai tò mò muốn biết mấy thứ kiểu
này hoạt động ra sao.)

Thật ra mọi cách ở trên đều có nhược và ưu điểm riêng, nhưng, như tôi
đã nói, nhìn chung tôi thích cách thứ ba. Trước hết, hãy nói về một
số nhược và ưu điểm của hai cách kia.

Cách thứ nhất, mã hóa các con số thành text trước khi gửi, có ưu
điểm là bạn có thể dễ dàng in ra và đọc được dữ liệu đang chạy trên
đường truyền. Đôi khi một giao thức dễ đọc cho người là rất tuyệt
khi dùng trong tình huống không đòi hỏi nhiều băng thông, như với
[i[IRC]] [fl[Internet Relay
Chat (IRC)|https://en.wikipedia.org/wiki/Internet_Relay_Chat]]. Tuy
nhiên, nó có nhược điểm là việc chuyển đổi chậm, và kết quả hầu như
luôn chiếm nhiều chỗ hơn con số gốc!

Cách hai: truyền dữ liệu thô. Cái này khá dễ (nhưng nguy hiểm!): chỉ
cần lấy con trỏ trỏ tới dữ liệu muốn gửi, và gọi send với nó.

```{.c}
double d = 3490.15926535;

send(s, &d, sizeof d, 0);  /* DANGER--non-portable! */
```

Bên nhận lấy nó như sau:

```{.c}
double d;

recv(s, &d, sizeof d, 0);  /* DANGER--non-portable! */
```

Nhanh, đơn giản, còn gì để chê? Vâng, hóa ra không phải mọi kiến
trúc đều biểu diễn `double` (hay `int` cũng vậy) với cùng bit
representation hay cùng thứ tự byte! Code này rõ ràng là không
portable. (Ê, có khi bạn không cần portable, trong trường hợp đó thì
cái này nhanh và ngon.)

Khi đóng gói các kiểu số nguyên, chúng ta đã thấy họ hàng
[i[`htons()` function]] `htons()` giúp giữ mọi thứ portable bằng
cách chuyển các con số sang [i[Byte ordering]] Network Byte Order ra
sao, và đó là Điều Đúng Đắn nên làm. Không may, không có hàm tương
tự cho kiểu `float`. Mọi hy vọng đã mất sao?

Đừng sợ! (Bạn có sợ lúc đó không? Không à? Không chút nào?) Có thứ
chúng ta có thể làm: chúng ta có thể pack (hoặc "marshal", hoặc
"serialize", hoặc một trong cả ngàn triệu cái tên khác) dữ liệu
thành một định dạng nhị phân đã biết mà bên nhận có thể unpack ở đầu
bên kia.

"Định dạng nhị phân đã biết" là gì? Chúng ta đã thấy ví dụ `htons()`
rồi, nhỉ? Nó đổi (hoặc "mã hóa", nếu bạn muốn nghĩ theo cách đó) một
con số từ bất kỳ định dạng nào của máy chủ sang Network Byte Order.
Để đảo ngược (giải mã), bên nhận gọi `ntohs()`.

Nhưng chẳng phải tôi vừa nói xong là không có hàm nào như thế cho
các kiểu phi số nguyên khác sao? Đúng vậy. Tôi có nói. Và vì không
có cách chuẩn nào trong C để làm điều này, đây là một tình thế khó
nhằn (một câu đùa gratuitous dành cho các fan Python của tôi).

Điều cần làm là đóng gói dữ liệu vào một định dạng đã biết và gửi nó
qua đường truyền để giải mã. Ví dụ, để pack `float`, đây là [flx[một
thứ nhanh và bẩn với nhiều chỗ để cải thiện|pack.c]]:

```{.c .numberLines}
#include <stdint.h>

uint32_t htonf(float f)
{
    uint32_t p;
    uint32_t sign;

    if (f < 0) { sign = 1; f = -f; }
    else { sign = 0; }
        
    // whole part and sign
    p = ((((uint32_t)f)&0x7fff)<<16) | (sign<<31);

    // fraction
    p |= (uint32_t)(((f - (int)f) * 65536.0f))&0xffff;

    return p;
}

float ntohf(uint32_t p)
{
    float f = ((p>>16)&0x7fff); // whole part
    f += (p&0xffff) / 65536.0f; // fraction

    if (((p>>31)&0x1) == 0x1) { f = -f; } // sign bit set

    return f;
}
```

Đoạn code trên là một cài đặt khá ngây thơ lưu một `float` trong một
số 32-bit. Bit cao nhất (31) được dùng để lưu dấu của số ("1" nghĩa
là âm), và bảy bit kế tiếp (30-16) được dùng để lưu phần nguyên của
`float`. Cuối cùng, các bit còn lại (15-0) được dùng để lưu phần lẻ
của số.

Cách dùng khá thẳng thắn:

```{.c .numberLines}
#include <stdio.h>

int main(void)
{
    float f = 3.1415926, f2;
    uint32_t netf;

    netf = htonf(f);  // convert to "network" form
    f2 = ntohf(netf); // convert back to test

    printf("Original: %f\n", f);        // 3.141593
    printf(" Network: 0x%08X\n", netf); // 0x0003243F
    printf("Unpacked: %f\n", f2);       // 3.141586

    return 0;
}
```

Ở mặt tích cực, nó nhỏ, đơn giản và nhanh. Ở mặt tiêu cực, nó dùng
không gian không hiệu quả và dải giá trị bị hạn chế nghiêm trọng,
thử lưu một số lớn hơn 32767 vào đấy xem, nó sẽ không vui đâu! Bạn
cũng có thể thấy trong ví dụ trên rằng vài chữ số thập phân cuối
cùng không được bảo toàn chính xác.

Chúng ta có thể làm gì thay thế? _Chuẩn_ để lưu các số dấu chấm động
được gọi là [i[IEEE-754]]
[fl[IEEE-754|https://en.wikipedia.org/wiki/IEEE_754]]. Hầu hết máy
tính dùng định dạng này nội bộ cho việc làm toán dấu chấm động, nên
trong các trường hợp đó, nói chính xác ra, không cần chuyển đổi
gì. Nhưng nếu bạn muốn source code của mình portable, đó là một giả
định bạn không nhất thiết có thể đặt.

Hoặc bạn có thể đặt? Rất có khả năng hệ thống của bạn là IEEE-754,
giống như khả năng cao nó là số bù hai cho số nguyên. Nên nếu bạn
biết mình có cái đó, bạn chỉ cần truyền dữ liệu qua đường truyền
(dù bạn cần sửa endianness bằng `htonl()` hoặc hàm phù hợp, `float`
cũng có endianness). Và đây là cái `htons()` cùng đồng bọn làm trên
các hệ thống big-endian, nơi không cần chuyển đổi.

Nhưng phòng trường hợp bạn đang ở trên hệ thống không phải IEEE-754,
[flx[đây là đoạn code mã hóa `float` và `double` sang định dạng
IEEE-754|ieee754.c]]. (Chủ yếu thôi, nó không mã hóa NaN hay
Infinity, nhưng có thể sửa lại để làm được.)

```{.c .numberLines}
#define pack754_32(f) (pack754((f), 32, 8))
#define pack754_64(f) (pack754((f), 64, 11))
#define unpack754_32(i) (unpack754((i), 32, 8))
#define unpack754_64(i) (unpack754((i), 64, 11))

uint64_t pack754(long double f, unsigned bits, unsigned expbits)
{
    long double fnorm;
    int shift;
    long long sign, exp, significand;

    // -1 for sign bit
    unsigned significandbits = bits - expbits - 1;

    if (f == 0.0) return 0; // get this special case out of the way

    // check sign and begin normalization
    if (f < 0) { sign = 1; fnorm = -f; }
    else { sign = 0; fnorm = f; }

    // get the normalized form of f and track the exponent
    shift = 0;
    while(fnorm >= 2.0) { fnorm /= 2.0; shift++; }
    while(fnorm < 1.0) { fnorm *= 2.0; shift--; }
    fnorm = fnorm - 1.0;

    // calculate the binary form (non-float) of the significand data
    significand = fnorm * ((1LL<<significandbits) + 0.5f);

    // get the biased exponent
    exp = shift + ((1<<(expbits-1)) - 1); // shift + bias

    // return the final answer
    return (sign<<(bits-1)) | (exp<<(bits-expbits-1)) | significand;
}

long double unpack754(uint64_t i, unsigned bits, unsigned expbits)
{
    long double result;
    long long shift;
    unsigned bias;

    // -1 for sign bit
    unsigned significandbits = bits - expbits - 1;

    if (i == 0) return 0.0;

    // pull the significand
    result = (i&((1LL<<significandbits)-1)); // mask
    result /= (1LL<<significandbits); // convert back to float
    result += 1.0f; // add the one back on

    // deal with the exponent
    bias = (1<<(expbits-1)) - 1;
    shift = ((i>>significandbits)&((1LL<<expbits)-1)) - bias;
    while(shift > 0) { result *= 2.0; shift--; }
    while(shift < 0) { result /= 2.0; shift++; }

    // sign it
    result *= (i>>(bits-1))&1? -1.0: 1.0;

    return result;
}
```

Tôi đặt vài macro tiện dụng ở trên cùng để đóng gói và mở gói các
số 32-bit (có thể là `float`) và 64-bit (có thể là `double`), nhưng
hàm `pack754()` có thể được gọi trực tiếp và bảo nó mã hóa `bits`
bit dữ liệu (trong đó `expbits` bit được dành cho phần mũ của số
chuẩn hóa).

Đây là cách dùng mẫu:

```{.c .numberLines}

#include <stdio.h>
#include <stdint.h> // defines uintN_t types
#include <inttypes.h> // defines PRIx macros

int main(void)
{
    float f = 3.1415926, f2;
    double d = 3.14159265358979323, d2;
    uint32_t fi;
    uint64_t di;

    fi = pack754_32(f);
    f2 = unpack754_32(fi);

    di = pack754_64(d);
    d2 = unpack754_64(di);

    printf("float before : %.7f\n", f);
    printf("float encoded: 0x%08" PRIx32 "\n", fi);
    printf("float after  : %.7f\n\n", f2);

    printf("double before : %.20lf\n", d);
    printf("double encoded: 0x%016" PRIx64 "\n", di);
    printf("double after  : %.20lf\n", d2);

    return 0;
}
```

Đoạn code trên cho ra output:

```
float before : 3.1415925
float encoded: 0x40490FDA
float after  : 3.1415925

double before : 3.14159265358979311600
double encoded: 0x400921FB54442D18
double after  : 3.14159265358979311600
```

Một câu hỏi khác bạn có thể có là làm sao đóng gói `struct`? Không
may cho bạn, compiler được tự do nhét padding khắp nơi trong
`struct`, và điều đó nghĩa là bạn không thể gửi nguyên cục đó qua
đường truyền một cách portable trong một đợt. (Bạn có đang chán
nghe "không thể làm cái này", "không thể làm cái kia" không? Xin
lỗi! Để dẫn lời một người bạn của tôi, "Bất cứ khi nào có gì trục
trặc, tôi luôn đổ lỗi cho Microsoft." Cái này có thể không phải lỗi
của Microsoft, đành nhận vậy, nhưng phát biểu của bạn tôi hoàn toàn
đúng.)

Quay lại chuyện chính: cách tốt nhất để gửi `struct` qua đường
truyền là đóng gói từng trường độc lập rồi mở gói chúng thành
`struct` khi đến đầu bên kia.

Nghe làm nhiều việc quá, bạn đang nghĩ vậy. Vâng, đúng thế. Một
điều bạn có thể làm là viết một hàm trợ giúp để giúp đóng gói dữ
liệu cho bạn. Sẽ vui lắm! Thật mà!

Trong sách [flr[_The Practice of Programming_|tpop]] của Kernighan
và Pike, họ cài đặt các hàm kiểu `printf()` tên là `pack()` và
`unpack()` làm chính xác chuyện này. Tôi sẽ link tới chúng, nhưng
có vẻ mấy hàm đó không có trên mạng cùng với phần còn lại của source
sách.

(_The Practice of Programming_ là một cuốn đọc xuất sắc. Zeus cứu
một con mèo con mỗi khi tôi giới thiệu nó.)

Tới đây, tôi sẽ thả một gợi ý về một [fl[cài đặt Protocol Buffers
bằng C|https://github.com/protobuf-c/protobuf-c]] mà tôi chưa từng
dùng, nhưng trông hoàn toàn tử tế. Các lập trình viên Python và Perl
sẽ muốn xem qua các hàm `pack()` và `unpack()` của ngôn ngữ mình để
hoàn thành cùng chuyện đó. Còn Java có cái interface Serializable to
đùng có thể dùng theo cách tương tự.

Nhưng nếu bạn muốn tự viết tiện ích đóng gói của mình trong C, mánh
của K&P là dùng variable argument list để tạo các hàm kiểu
`printf()` để dựng các gói tin. [flx[Đây là phiên bản tôi tự nấu
lên|pack2.c]] dựa trên đó mà hy vọng sẽ đủ để cho bạn ý tưởng về
cách một thứ như vậy có thể hoạt động.

(Code này tham chiếu đến các hàm `pack754()` ở trên. Các hàm
`packi*()` hoạt động giống họ hàng `htons()` quen thuộc, ngoại trừ
việc chúng pack vào một mảng `char` thay vì một số nguyên khác.)

```{.c .numberLines}
#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <string.h>

/*
** packi16() -- store a 16-bit int into a char buffer (like htons())
*/
void packi16(unsigned char *buf, unsigned int i)
{
    *buf++ = i>>8; *buf++ = i;
}

/*
** packi32() -- store a 32-bit int into a char buffer (like htonl())
*/
void packi32(unsigned char *buf, unsigned long int i)
{
    *buf++ = i>>24; *buf++ = i>>16;
    *buf++ = i>>8;  *buf++ = i;
}

/*
** packi64() -- store a 64-bit int into a char buffer (like htonl())
*/
void packi64(unsigned char *buf, unsigned long long int i)
{
    *buf++ = i>>56; *buf++ = i>>48;
    *buf++ = i>>40; *buf++ = i>>32;
    *buf++ = i>>24; *buf++ = i>>16;
    *buf++ = i>>8;  *buf++ = i;
}

/*
** unpacki16() -- unpack a 16-bit int from a char buffer (like
**                ntohs())
*/
int unpacki16(unsigned char *buf)
{
    unsigned int i2 = ((unsigned int)buf[0]<<8) | buf[1];
    int i;

    // change unsigned numbers to signed
    if (i2 <= 0x7fffu) { i = i2; }
    else { i = -1 - (unsigned int)(0xffffu - i2); }

    return i;
}

/*
** unpacku16() -- unpack a 16-bit unsigned from a char buffer (like
**                ntohs())
*/
unsigned int unpacku16(unsigned char *buf)
{
    return ((unsigned int)buf[0]<<8) | buf[1];
}

/*
** unpacki32() -- unpack a 32-bit int from a char buffer (like
**                ntohl())
*/
long int unpacki32(unsigned char *buf)
{
    unsigned long int i2 = ((unsigned long int)buf[0]<<24) |
                           ((unsigned long int)buf[1]<<16) |
                           ((unsigned long int)buf[2]<<8)  |
                           buf[3];
    long int i;

    // change unsigned numbers to signed
    if (i2 <= 0x7fffffffu) { i = i2; }
    else { i = -1 - (long int)(0xffffffffu - i2); }

    return i;
}

/*
** unpacku32() -- unpack a 32-bit unsigned from a char buffer (like
**                ntohl())
*/
unsigned long int unpacku32(unsigned char *buf)
{
    return ((unsigned long int)buf[0]<<24) |
           ((unsigned long int)buf[1]<<16) |
           ((unsigned long int)buf[2]<<8)  |
           buf[3];
}

/*
** unpacki64() -- unpack a 64-bit int from a char buffer (like
**                ntohl())
*/
long long int unpacki64(unsigned char *buf)
{
    unsigned long long int i2 =
        ((unsigned long long int)buf[0]<<56) |
        ((unsigned long long int)buf[1]<<48) |
        ((unsigned long long int)buf[2]<<40) |
        ((unsigned long long int)buf[3]<<32) |
        ((unsigned long long int)buf[4]<<24) |
        ((unsigned long long int)buf[5]<<16) |
        ((unsigned long long int)buf[6]<<8)  |
        buf[7];
    long long int i;

    // change unsigned numbers to signed
    if (i2 <= 0x7fffffffffffffffu) { i = i2; }
    else { i = -1 -(long long int)(0xffffffffffffffffu - i2); }

    return i;
}

/*
** unpacku64() -- unpack a 64-bit unsigned from a char buffer (like
**                ntohl())
*/
unsigned long long int unpacku64(unsigned char *buf)
{
    return ((unsigned long long int)buf[0]<<56) |
           ((unsigned long long int)buf[1]<<48) |
           ((unsigned long long int)buf[2]<<40) |
           ((unsigned long long int)buf[3]<<32) |
           ((unsigned long long int)buf[4]<<24) |
           ((unsigned long long int)buf[5]<<16) |
           ((unsigned long long int)buf[6]<<8)  |
           buf[7];
}

/*
** pack() -- store data dictated by the format string in the buffer
**
**   bits |signed   unsigned   float   string
**   -----+----------------------------------
**      8 |   c        C
**     16 |   h        H         f
**     32 |   l        L         d
**     64 |   q        Q         g
**      - |                               s
**
**  (16-bit unsigned length is automatically prepended to strings)
*/

unsigned int pack(unsigned char *buf, char *format, ...)
{
    va_list ap;

    signed char c;              // 8-bit
    unsigned char C;

    int h;                      // 16-bit
    unsigned int H;

    long int l;                 // 32-bit
    unsigned long int L;

    long long int q;            // 64-bit
    unsigned long long int Q;

    float f;                    // floats
    double d;
    long double g;
    unsigned long long int fhold;

    char *s;                    // strings
    unsigned int len;

    unsigned int size = 0;

    va_start(ap, format);

    for(; *format != '\0'; format++) {
        switch(*format) {
        case 'c': // 8-bit
            size += 1;
            c = (signed char)va_arg(ap, int); // promoted
            *buf++ = c;
            break;

        case 'C': // 8-bit unsigned
            size += 1;
            C = (unsigned char)va_arg(ap, unsigned int); // promoted
            *buf++ = C;
            break;

        case 'h': // 16-bit
            size += 2;
            h = va_arg(ap, int);
            packi16(buf, h);
            buf += 2;
            break;

        case 'H': // 16-bit unsigned
            size += 2;
            H = va_arg(ap, unsigned int);
            packi16(buf, H);
            buf += 2;
            break;

        case 'l': // 32-bit
            size += 4;
            l = va_arg(ap, long int);
            packi32(buf, l);
            buf += 4;
            break;

        case 'L': // 32-bit unsigned
            size += 4;
            L = va_arg(ap, unsigned long int);
            packi32(buf, L);
            buf += 4;
            break;

        case 'q': // 64-bit
            size += 8;
            q = va_arg(ap, long long int);
            packi64(buf, q);
            buf += 8;
            break;

        case 'Q': // 64-bit unsigned
            size += 8;
            Q = va_arg(ap, unsigned long long int);
            packi64(buf, Q);
            buf += 8;
            break;

        case 'f': // float-16
            size += 2;
            f = (float)va_arg(ap, double); // promoted
            fhold = pack754_16(f); // convert to IEEE 754
            packi16(buf, fhold);
            buf += 2;
            break;

        case 'd': // float-32
            size += 4;
            d = va_arg(ap, double);
            fhold = pack754_32(d); // convert to IEEE 754
            packi32(buf, fhold);
            buf += 4;
            break;

        case 'g': // float-64
            size += 8;
            g = va_arg(ap, long double);
            fhold = pack754_64(g); // convert to IEEE 754
            packi64(buf, fhold);
            buf += 8;
            break;

        case 's': // string
            s = va_arg(ap, char*);
            len = strlen(s);
            size += len + 2;
            packi16(buf, len);
            buf += 2;
            memcpy(buf, s, len);
            buf += len;
            break;
        }
    }

    va_end(ap);

    return size;
}

/*
** unpack() -- unpack data dictated by the format string into the
**             buffer
**
**   bits |signed   unsigned   float   string
**   -----+----------------------------------
**      8 |   c        C
**     16 |   h        H         f
**     32 |   l        L         d
**     64 |   q        Q         g
**      - |                               s
**
**  (string is extracted based on its stored length, but 's' can be
**  prepended with a max length)
*/
void unpack(unsigned char *buf, char *format, ...)
{
    va_list ap;

    signed char *c;              // 8-bit
    unsigned char *C;

    int *h;                      // 16-bit
    unsigned int *H;

    long int *l;                 // 32-bit
    unsigned long int *L;

    long long int *q;            // 64-bit
    unsigned long long int *Q;

    float *f;                    // floats
    double *d;
    long double *g;
    unsigned long long int fhold;

    char *s;
    unsigned int len, maxstrlen=0, count;

    va_start(ap, format);

    for(; *format != '\0'; format++) {
        switch(*format) {
        case 'c': // 8-bit
            c = va_arg(ap, signed char*);
            if (*buf <= 0x7f) { *c = *buf;} // re-sign
            else { *c = -1 - (unsigned char)(0xffu - *buf); }
            buf++;
            break;

        case 'C': // 8-bit unsigned
            C = va_arg(ap, unsigned char*);
            *C = *buf++;
            break;

        case 'h': // 16-bit
            h = va_arg(ap, int*);
            *h = unpacki16(buf);
            buf += 2;
            break;

        case 'H': // 16-bit unsigned
            H = va_arg(ap, unsigned int*);
            *H = unpacku16(buf);
            buf += 2;
            break;

        case 'l': // 32-bit
            l = va_arg(ap, long int*);
            *l = unpacki32(buf);
            buf += 4;
            break;

        case 'L': // 32-bit unsigned
            L = va_arg(ap, unsigned long int*);
            *L = unpacku32(buf);
            buf += 4;
            break;

        case 'q': // 64-bit
            q = va_arg(ap, long long int*);
            *q = unpacki64(buf);
            buf += 8;
            break;

        case 'Q': // 64-bit unsigned
            Q = va_arg(ap, unsigned long long int*);
            *Q = unpacku64(buf);
            buf += 8;
            break;

        case 'f': // float
            f = va_arg(ap, float*);
            fhold = unpacku16(buf);
            *f = unpack754_16(fhold);
            buf += 2;
            break;

        case 'd': // float-32
            d = va_arg(ap, double*);
            fhold = unpacku32(buf);
            *d = unpack754_32(fhold);
            buf += 4;
            break;

        case 'g': // float-64
            g = va_arg(ap, long double*);
            fhold = unpacku64(buf);
            *g = unpack754_64(fhold);
            buf += 8;
            break;

        case 's': // string
            s = va_arg(ap, char*);
            len = unpacku16(buf);
            buf += 2;
            if (maxstrlen > 0 && len > maxstrlen)
                count = maxstrlen - 1;
            else
                count = len;
            memcpy(s, buf, count);
            s[count] = '\0';
            buf += len;
            break;

        default:
            if (isdigit(*format)) { // track max str len
                maxstrlen = maxstrlen * 10 + (*format-'0');
            }
        }

        if (!isdigit(*format)) maxstrlen = 0;
    }

    va_end(ap);
}
```

Và [flx[đây là chương trình demo|pack2.c]] của đoạn code ở trên, nó
pack một ít dữ liệu vào `buf` rồi unpack ra các biến. Chú ý rằng khi
gọi `unpack()` với tham số string (format specifier "`s`"), khôn
ngoan thì nên đặt một giới hạn độ dài tối đa ở phía trước nó để ngăn
chặn buffer overrun, ví dụ "`96s`". Hãy cẩn thận khi unpack dữ liệu
bạn nhận được qua mạng, một kẻ xấu có thể gửi các gói tin được dựng
sai cách nhằm tấn công hệ thống của bạn!

```{.c .numberLines}
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

// If you have a C23 compiler
#if __STDC_VERSION__ >= 202311L
#include <stdfloat.h>
#else
// Otherwise let's define our own.
// Varies for different architectures! But you're probably:
typedef float float32_t;
typedef double float64_t;
#endif

int main(void)
{
    uint8_t buf[1024];
    int8_t magic;
    int16_t monkeycount;
    int32_t altitude;
    float32_t absurdityfactor;
    char *s = "Great unmitigated Zot!  You've found the Runestaff!";
    char s2[96];
    int16_t packetsize, ps2;

    packetsize = pack(buf, "chhlsf", (int8_t)'B', (int16_t)0,
            (int16_t)37, (int32_t)-5, s, (float32_t)-3490.6677);
    packi16(buf+1, packetsize); // store packet size for kicks

    printf("packet is %" PRId32 " bytes\n", packetsize);

    unpack(buf, "chhl96sf", &magic, &ps2, &monkeycount, &altitude,
            s2, &absurdityfactor);

    printf("'%c' %" PRId32" %" PRId16 " %" PRId32
            " \"%s\" %f\n", magic, ps2, monkeycount,
            altitude, s2, absurdityfactor);
}
```

Dù bạn tự cuộn tay code lấy hay dùng của người khác, có một bộ các
thủ tục đóng gói dữ liệu chung là ý hay, để hạn chế bugs, thay vì
pack từng bit bằng tay mỗi lần.

Khi đóng gói dữ liệu, định dạng nào là tốt để dùng? Câu hỏi hay.
Rất may, [i[XDR]] [flrfc[RFC 4506|4506]], the External Data
Representation Standard, đã định nghĩa các định dạng nhị phân cho cả
đống kiểu khác nhau, như kiểu floating point, kiểu số nguyên, mảng,
dữ liệu thô, vân vân. Tôi đề nghị bạn tuân thủ theo đó nếu bạn định
tự cuộn dữ liệu lấy. Nhưng không bắt buộc. Cảnh Sát Gói Tin không
đang đứng ngay ngoài cửa nhà bạn đâu. Ít nhất, tôi _nghĩ_ là họ
không.

Dù gì đi nữa, mã hóa dữ liệu bằng cách này hay cách khác trước khi
gửi nó đi là cách làm đúng đắn!

[i[Serialization]>]

## Đứa Con Trai Của Đóng Gói Dữ Liệu {#sonofdataencap}

Đóng gói dữ liệu thực sự nghĩa là gì? Trong trường hợp đơn giản
nhất, nó nghĩa là bạn sẽ dán lên đó một header với thông tin nhận
diện hoặc độ dài gói tin, hoặc cả hai.

Header của bạn nên trông ra sao? Thì, nó chỉ là một ít dữ liệu nhị
phân đại diện cho bất cứ gì bạn thấy cần để hoàn thành dự án của
mình.

Wow. Nghe mơ hồ ghê.

Được rồi. Ví dụ, giả sử bạn có một chương trình chat nhiều người
dùng `SOCK_STREAM`. Khi một người dùng gõ ("nói") gì đó, có hai
thông tin cần được truyền về server: cái gì được nói và ai đã nói.

Tới đây ổn chứ? "Vấn đề ở đâu?", bạn đang hỏi.

Vấn đề là các tin nhắn có thể có độ dài khác nhau. Một người tên
"tom" có thể nói "Hi", còn người khác tên "Benjamin" có thể nói
"Hey guys what is up?"

Nên bạn `send()` tất cả thứ này tới các client khi nó đến. Luồng dữ
liệu ra của bạn trông như thế này:

```
t o m H i B e n j a m i n H e y g u y s w h a t i s u p ?
```

Và cứ thế. Làm sao client biết khi nào một tin nhắn bắt đầu và một
tin khác kết thúc? Bạn có thể, nếu muốn, làm cho tất cả tin nhắn có
cùng độ dài và chỉ cần gọi [i[`sendall()` function]] `sendall()` mà
chúng ta đã cài đặt, [ở trên](#sendall). Nhưng như vậy phí băng
thông! Chúng ta không muốn `send()` 1024 byte chỉ để "tom" nói
"Hi".

Vì vậy chúng ta _đóng gói_ dữ liệu vào một cấu trúc header và gói
tin nhỏ. Cả client và server đều biết cách pack và unpack (đôi khi
được gọi là "marshal" và "unmarshal") dữ liệu này. Đừng nhìn bây
giờ, nhưng chúng ta đang bắt đầu định nghĩa một _giao thức_ mô tả
cách client và server giao tiếp!

Trong trường hợp này, giả sử user name có độ dài cố định 8 ký tự,
padding bằng `'\0'`. Rồi giả sử dữ liệu có độ dài biến đổi, tối đa
128 ký tự. Hãy xem thử một cấu trúc gói tin mà chúng ta có thể dùng
trong tình huống này:

1. `len` (1 byte, unsigned), tổng độ dài của gói tin, đếm cả
    user name 8 byte và dữ liệu chat.

2. `name` (8 byte), tên người dùng, NUL-padded nếu cần.

3. `chatdata` (_n_ byte), chính dữ liệu, không quá 128 byte. Độ
   dài của gói tin nên được tính bằng độ dài của dữ liệu này cộng
   8 (độ dài của trường name ở trên).

Tại sao tôi chọn giới hạn 8 byte và 128 byte cho các trường? Tôi
bịa ra từ không khí, giả định chúng sẽ đủ dài. Có thể, dù vậy, 8
byte là quá hạn chế với nhu cầu của bạn, và bạn có thể có trường
name 30 byte, hoặc bất cứ gì. Chọn lựa là của bạn.

Dùng định nghĩa gói tin ở trên, gói tin đầu tiên sẽ gồm thông tin
sau (ở hex và ASCII):

```
   0A     74 6F 6D 00 00 00 00 00      48 69
(length)  T  o  m    (padding)         H  i
```

Và gói thứ hai tương tự:

```
   18     42 65 6E 6A 61 6D 69 6E      48 65 79 20 67 75 79 73 20 77 ...
(length)  B  e  n  j  a  m  i  n       H  e  y     g  u  y  s     w  ...
```

(Độ dài được lưu ở Network Byte Order, dĩ nhiên. Trong trường hợp
này, nó chỉ có một byte nên không quan trọng, nhưng nói chung bạn
sẽ muốn tất cả số nguyên nhị phân của mình được lưu ở Network Byte
Order trong các gói tin.)

Khi bạn gửi dữ liệu này, bạn nên an toàn và dùng một lệnh tương tự
[`sendall()`](#sendall) ở trên, để bạn biết tất cả dữ liệu đã được
gửi, kể cả khi cần nhiều lời gọi `send()` để đưa hết ra.

Tương tự, khi bạn nhận dữ liệu này, bạn cần làm thêm một ít việc.
Để an toàn, bạn nên giả định rằng bạn có thể nhận được một phần gói
tin (ví dụ có khi chúng ta nhận được "`18 42 65 6E 6A`" từ
Benjamin ở trên, nhưng chỉ nhận được chừng đó trong lời gọi
`recv()` này). Chúng ta cần gọi `recv()` lặp đi lặp lại cho đến khi
gói tin được nhận đầy đủ.

Nhưng làm sao? Thì, chúng ta biết tổng số byte cần nhận để gói tin
hoàn chỉnh, vì con số đó được dán ở đầu gói tin. Chúng ta cũng biết
kích thước gói tin tối đa là 1+8+128, tức 137 byte (vì đó là cách
chúng ta định nghĩa gói tin).

Thật ra có vài thứ bạn có thể làm ở đây. Vì bạn biết mỗi gói tin
bắt đầu bằng độ dài, bạn có thể gọi `recv()` chỉ để lấy độ dài gói
tin. Rồi sau khi có nó, bạn có thể gọi nó lần nữa chỉ định chính
xác độ dài còn lại của gói tin (có thể lặp lại để lấy hết dữ liệu)
cho đến khi có gói tin hoàn chỉnh. Ưu điểm của cách này là bạn chỉ
cần một buffer đủ lớn cho một gói tin, còn nhược điểm là bạn phải
gọi `recv()` ít nhất hai lần để lấy hết dữ liệu.

Một lựa chọn khác là chỉ cần gọi `recv()` và nói rằng số byte bạn
sẵn sàng nhận là số byte tối đa trong một gói tin. Rồi bất cứ gì
bạn nhận được, dán nó vào cuối buffer, và cuối cùng kiểm tra xem
gói tin có hoàn chỉnh chưa. Dĩ nhiên, bạn có thể nhận được một phần
của gói tin kế tiếp, nên bạn cần có chỗ cho phần đó.

Cái bạn có thể làm là khai báo một mảng đủ lớn cho hai gói tin. Đây
là mảng công tác nơi bạn sẽ dựng lại các gói tin khi chúng đến.

Mỗi lần bạn `recv()` dữ liệu, bạn sẽ append nó vào work buffer và
kiểm tra xem gói tin đã hoàn chỉnh chưa. Tức là, số byte trong
buffer lớn hơn hoặc bằng độ dài được chỉ định trong header (+1, vì
độ dài trong header không bao gồm byte cho chính độ dài đó). Nếu số
byte trong buffer nhỏ hơn 1, gói tin rõ ràng là chưa hoàn chỉnh.
Bạn phải làm trường hợp đặc biệt cho chuyện này, vì byte đầu tiên
là rác và bạn không thể dựa vào nó để lấy đúng độ dài gói tin.

Khi gói tin đã hoàn chỉnh, bạn có thể làm gì với nó tùy ý. Dùng nó
rồi xóa khỏi work buffer.

Hú! Bạn có đang tung hứng hết mấy thứ đó trong đầu không? Đây là cú
đấm thứ hai trong combo một-hai: bạn có thể đã đọc qua phần cuối
của một gói tin và sang gói kế trong một lời gọi `recv()` duy
nhất. Tức là, bạn có work buffer với một gói tin hoàn chỉnh, và
một phần chưa hoàn chỉnh của gói tin kế tiếp! Chết tiệt. (Nhưng đây
là lý do bạn làm work buffer đủ lớn để chứa _hai_ gói tin, phòng
khi chuyện này xảy ra!)

Vì bạn biết độ dài của gói tin đầu tiên từ header, và bạn đã theo
dõi số byte trong work buffer, bạn có thể trừ ra và tính được bao
nhiêu byte trong work buffer thuộc về gói tin thứ hai (chưa hoàn
chỉnh). Khi đã xử lý xong gói đầu tiên, bạn có thể xóa nó khỏi work
buffer và dời phần gói thứ hai chưa hoàn chỉnh xuống đầu buffer để
mọi thứ sẵn sàng cho lời gọi `recv()` kế tiếp.

(Một số độc giả sẽ chú ý rằng việc thật sự dời phần gói thứ hai
chưa hoàn chỉnh về đầu work buffer mất thời gian, và chương trình
có thể được code để không cần làm vậy bằng cách dùng circular
buffer. Không may cho số còn lại trong các bạn, một cuộc thảo luận
về circular buffer vượt ra ngoài phạm vi bài viết này. Nếu vẫn tò
mò, tóm lấy một cuốn sách cấu trúc dữ liệu và đi từ đó.)

Tôi chưa bao giờ nói là dễ đâu nhé. À ừ, tôi có nói nó dễ. Và nó
dễ mà; bạn chỉ cần luyện tập thôi, rồi khá nhanh nó sẽ tự đến với
bạn một cách tự nhiên. Tôi thề bằng thanh kiếm [i[Excalibur]]
Excalibur đấy!


## Gói Tin Broadcast: Hello, World!

Tới giờ, hướng dẫn này nói về việc gửi dữ liệu từ một máy sang một
máy khác. Nhưng có thể, tôi khẳng định, rằng bạn có thể, với đúng
quyền hạn, gửi dữ liệu tới nhiều máy _cùng một lúc_!

Với [i[UDP]] UDP (chỉ UDP, không phải TCP) và IPv4 chuẩn, chuyện
này được làm qua một cơ chế gọi là [i[Broadcast]] _broadcasting_.
Với IPv6, broadcasting không được hỗ trợ, bạn phải dùng kỹ thuật
thường là vượt trội hơn gọi là _multicasting_, mà đáng tiếc tôi sẽ
không bàn tới lúc này. Nhưng thôi đừng mơ mộng về tương lai nữa,
chúng ta đang kẹt trong hiện tại 32-bit.

Khoan đã! Bạn không thể chạy đi broadcast lung tung được; bạn phải
[i[`setsockopt()` function]] đặt tùy chọn socket
[i[`SO_BROADCAST` macro]] `SO_BROADCAST` trước khi có thể gửi một
gói tin broadcast ra mạng. Nó giống như mấy cái nắp nhựa nhỏ người
ta đậy lên công tắc phóng tên lửa vậy! Quyền năng trong tay bạn
lớn tới mức đó đấy!

Nhưng nghiêm túc nhé, có một nguy hiểm khi dùng gói tin broadcast,
đó là: mọi hệ thống nhận được gói tin broadcast phải bóc hết các
lớp vỏ hành đóng gói dữ liệu cho đến khi tìm ra dữ liệu được gửi
đến port nào. Rồi nó bàn giao dữ liệu hoặc vứt đi. Trong cả hai
trường hợp, đó là nhiều việc cho mỗi máy nhận gói tin broadcast,
và vì đó là tất cả các máy trên mạng local, có thể rất nhiều máy
làm rất nhiều việc không cần thiết. Khi game Doom mới ra, đây là
một lời than phiền về network code của nó.

Giờ, có hơn một cách lột da mèo[^6178]... khoan đã. Có thật là có
hơn một cách lột da mèo không? Câu thành ngữ kiểu gì vậy? Ờ,
tương tự, có hơn một cách gửi một gói tin broadcast. Vậy, đi vào
phần thịt và khoai tây của vấn đề: bạn chỉ định địa chỉ đích cho
một tin nhắn broadcast ra sao? Có hai cách phổ biến:

[^6178]: Nói cho rõ, tôi yêu mèo. Chúng là nhất. Tôi đã có nhiều
    người bạn mèo yêu quý qua năm tháng. Dù tôi thừa nhận một số
    người phản đối câu thành ngữ hình tượng rùng rợn này, với
    nguồn gốc từ nguyên đã thất lạc theo thời gian, tôi nghĩ phần
    này của hướng dẫn được phục vụ tốt nhất bằng việc dùng nó.

1. Gửi dữ liệu tới địa chỉ broadcast của một subnet cụ thể. Đây là
   network number của subnet đó với tất cả các bit một được bật ở
   phần host của địa chỉ. Ví dụ, ở nhà mạng của tôi là
   `192.168.1.0`, netmask là `255.255.255.0`, nên byte cuối của
   địa chỉ là số host của tôi (vì ba byte đầu, theo netmask, là
   network number). Nên địa chỉ broadcast của tôi là
   `192.168.1.255`. Trên Unix, lệnh `ifconfig` thật ra sẽ cho bạn
   tất cả dữ liệu này. (Nếu bạn tò mò, logic bitwise để lấy địa
   chỉ broadcast của mình là `network_number` OR (NOT `netmask`).)
   Bạn có thể gửi loại gói tin broadcast này tới mạng remote cũng
   như mạng local, nhưng bạn có rủi ro gói tin bị router của đích
   đến vứt đi. (Nếu họ không vứt đi, thì một con smurf ngẫu nhiên
   nào đó có thể bắt đầu làm ngập LAN của họ bằng traffic
   broadcast.)

2. Gửi dữ liệu tới địa chỉ broadcast "toàn cục". Đây là
   [i[`255.255.255.255`]] `255.255.255.255`, còn gọi là
   [i[`INADDR_BROADCAST` macro]] `INADDR_BROADCAST`. Nhiều máy sẽ
   tự động AND bitwise cái này với network number của bạn để
   chuyển nó thành địa chỉ broadcast của mạng, nhưng một số thì
   không. Tùy thôi. Router không chuyển tiếp loại gói tin
   broadcast này ra khỏi mạng local của bạn, khá là trớ trêu.

Vậy chuyện gì xảy ra nếu bạn thử gửi dữ liệu trên địa chỉ broadcast
mà không đặt tùy chọn socket `SO_BROADCAST` trước? Hãy khởi động
mấy chương trình [`talker` và `listener`](#datagram) ngon lành cũ
và xem chuyện gì xảy ra.

```
$ talker 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ talker 192.168.1.255 foo
sendto: Permission denied
$ talker 255.255.255.255 foo
sendto: Permission denied
```

Vâng, nó không vui chút nào... vì chúng ta đã không đặt tùy chọn
socket `SO_BROADCAST`. Đặt cái đó, và giờ bạn có thể `sendto()`
tới bất cứ đâu bạn muốn!

Thật ra, đó là sự _khác biệt duy nhất_ giữa một ứng dụng UDP có
thể broadcast và một cái không thể. Vậy hãy lấy ứng dụng `talker`
cũ và thêm một đoạn đặt tùy chọn socket `SO_BROADCAST`. Chúng ta
sẽ gọi chương trình này là [flx[`broadcaster.c`|broadcaster.c]]:

```{.c .numberLines}
/*
** broadcaster.c -- a datagram "client" like talker.c, except
**                  this one can broadcast
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

#define SERVERPORT 4950    // the port users will be connecting to

int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in their_addr; // connector's address info
    struct hostent *he;
    int numbytes;
    int broadcast = 1;
    //char broadcast = '1'; // if that doesn't work, try this

    if (argc != 3) {
        fprintf(stderr,"usage: broadcaster hostname message\n");
        exit(1);
    }

    if ((he=gethostbyname(argv[1])) == NULL) {  // get the host info
        perror("gethostbyname");
        exit(1);
    }

    if ((sockfd = socket(PF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("socket");
        exit(1);
    }

    // this call is what allows broadcast packets to be sent:
    if (setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &broadcast,
        sizeof broadcast) == -1) {
        perror("setsockopt (SO_BROADCAST)");
        exit(1);
    }

    their_addr.sin_family = AF_INET;     // host byte order
    their_addr.sin_port = htons(SERVERPORT); // network byte order
    their_addr.sin_addr = *((struct in_addr *)he->h_addr);
    memset(their_addr.sin_zero, '\0', sizeof their_addr.sin_zero);

    numbytes = sendto(sockfd, argv[2], strlen(argv[2]), 0,
             (struct sockaddr *)&their_addr, sizeof their_addr);

    if (numbytes == -1) {
        perror("sendto");
        exit(1);
    }

    printf("sent %d bytes to %s\n", numbytes,
        inet_ntoa(their_addr.sin_addr));

    close(sockfd);

    return 0;
}
```

Cái gì khác biệt giữa cái này và tình huống UDP client/server
"bình thường"? Không có gì! (Ngoại trừ việc client được phép gửi
gói tin broadcast trong trường hợp này.) Vậy, cứ chạy chương trình
UDP [`listener`](#datagram) cũ trong một cửa sổ, và `broadcaster`
trong một cửa sổ khác. Giờ bạn có thể làm tất cả những send mà đã
thất bại ở trên.

```
$ broadcaster 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ broadcaster 192.168.1.255 foo
sent 3 bytes to 192.168.1.255
$ broadcaster 255.255.255.255 foo
sent 3 bytes to 255.255.255.255
```

Và bạn sẽ thấy `listener` phản hồi rằng nó đã nhận được gói tin.
(Nếu `listener` không phản hồi, có thể là vì nó được bind vào một
địa chỉ IPv6. Thử đổi `AF_INET6` trong `listener.c` thành
`AF_INET` để ép IPv4.)

À, cái này hơi phấn khích đấy. Nhưng giờ khởi động `listener`
trên một máy khác bên cạnh bạn cùng mạng sao cho bạn có hai bản
đang chạy, mỗi máy một bản, và chạy `broadcaster` lần nữa với địa
chỉ broadcast của bạn... Ê! Cả hai `listener` đều nhận được gói
tin mặc dù bạn chỉ gọi `sendto()` một lần! Ngầu!

Nếu `listener` nhận được dữ liệu bạn gửi trực tiếp tới nó, nhưng
không nhận được dữ liệu trên địa chỉ broadcast, có thể là vì bạn
có một [i[Firewall]] firewall trên máy local đang chặn các gói
tin. (Đúng vậy, [i[Pat]] Pat và [i[Bapper]] Bapper, cảm ơn các bạn
đã nhận ra trước tôi rằng đó là lý do code mẫu của tôi không chạy.
Tôi đã bảo các bạn là tôi sẽ nhắc tên các bạn trong hướng dẫn, và
đây các bạn. Vậy đó, _nyah_.)

Lại nữa, hãy cẩn thận với gói tin broadcast. Vì mọi máy trên LAN
đều bị ép xử lý gói tin dù nó có `recvfrom()` hay không, nó có thể
tạo khá nhiều tải cho toàn bộ mạng máy tính. Chúng chắc chắn là
thứ cần dùng tiết kiệm và đúng lúc.
