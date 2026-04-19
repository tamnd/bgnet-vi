# Từ IPv4 nhảy sang IPv6

[i[IPv6]]

Nhưng tôi chỉ muốn biết phải đổi gì trong code để nó chạy được với IPv6!
Nói luôn đi!

Được! Được!

Gần như mọi thứ ở đây đều là cái tôi đã nói ở phía trên, nhưng đây là
phiên bản ngắn dành cho người không đủ kiên nhẫn. (Tất nhiên, còn nhiều
hơn thế, nhưng đây là những gì áp dụng được trong phạm vi tài liệu
này.)

1. Đầu tiên, cố gắng dùng [i[`getaddrinfo()` function]]
   [`getaddrinfo()`](#structs) để lấy toàn bộ thông tin `struct
   sockaddr`, thay vì đóng gói struct bằng tay. Làm vậy sẽ giữ cho code
   của bạn bất kể phiên bản IP, và cắt gọn được kha khá bước phía sau.

2. Chỗ nào bạn thấy mình đang hard-code thứ gì liên quan đến phiên bản
   IP, cố gắng gói lại trong một hàm trợ giúp.

3. Đổi `AF_INET` thành `AF_INET6`.

4. Đổi `PF_INET` thành `PF_INET6`.

5. Đổi các phép gán `INADDR_ANY` thành phép gán `in6addr_any`, có hơi
   khác một chút:

   ```{.c}
   struct sockaddr_in sa;
   struct sockaddr_in6 sa6;
   
   sa.sin_addr.s_addr = INADDR_ANY;  // use my IPv4 address
   sa6.sin6_addr = in6addr_any; // use my IPv6 address
   ```

   Ngoài ra, giá trị `IN6ADDR_ANY_INIT` có thể dùng như một initializer
   khi khai báo `struct in6_addr`, như thế này:

   ```{.c}
   struct in6_addr ia6 = IN6ADDR_ANY_INIT;
   ```

6. Thay vì `struct sockaddr_in`, dùng `struct sockaddr_in6`, nhớ thêm
   "6" vào tên trường nếu cần (xem [`struct`s](#structs) ở trên). Không
   có trường `sin6_zero`.

7. Thay vì `struct in_addr`, dùng `struct in6_addr`, nhớ thêm "6" vào
   tên trường nếu cần (xem [`struct`s](#structs) ở trên).

8. Thay vì `inet_aton()` hoặc `inet_addr()`, dùng `inet_pton()`.

9. Thay vì `inet_ntoa()`, dùng `inet_ntop()`.

10. Thay vì `gethostbyname()`, dùng `getaddrinfo()` xịn hơn.

11. Thay vì `gethostbyaddr()`, dùng [i[`getnameinfo()` function]]
    `getnameinfo()` xịn hơn (dù `gethostbyaddr()` vẫn chạy được với
    IPv6).

12. `INADDR_BROADCAST` không còn chạy nữa. Dùng IPv6 multicast thay
    thế.

_Et voilà_!
