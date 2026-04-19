# Beej's Guide to Network Programming &mdash; Bản tiếng Việt

> Tiếng Việt &middot; [English](README.en.md)

Bản dịch tiếng Việt của [Beej's Guide to Network Programming][bgnet],
tác giả Brian "Beej Jorgensen" Hall. Đọc miễn phí, chia sẻ thoải mái,
giống hệt như bản gốc.

> Này! Lập trình socket đang hành bạn? Đọc trang `man` mà chả ra đâu vào
> đâu? Bạn muốn viết mấy chương trình Internet ngầu ngầu bằng C nhưng
> không có thời gian lội qua đống `struct`?
>
> Mà đoán xem. Beej đã lội qua cái đống đó rồi, và giờ bạn có thể đọc
> bằng tiếng Việt.

[bgnet]: https://beej.us/guide/bgnet/

## Có hợp với tôi không?

Nếu bạn đọc được tiếng Việt và muốn biết hai máy tính nói chuyện với
nhau bằng C thế nào, thì hợp. Nếu bạn đọc được tiếng Anh thoải mái, cứ
[đọc bản gốc][bgnet], nó ở ngay đó thôi.

Nếu bạn là một developer người Việt đã từng mở `<sys/socket.h>`, nhìn
`struct sockaddr` một hồi rồi lặng lẽ đóng tab, thì repo này dành cho
bạn đấy.

## Bạn sẽ học được gì

Mười chương, không dài dòng:

1. Giới thiệu &mdash; tài liệu này là gì, dành cho ai
2. Socket là gì? &mdash; bức tranh tổng thể
3. Địa chỉ IP, `struct`, và xử lý dữ liệu &mdash; byte, endianness,
   `sockaddr`
4. Từ IPv4 nhảy sang IPv6 &mdash; cái gì đổi, cái gì giữ nguyên
5. System call hoặc không gì cả &mdash; `socket()`, `bind()`,
   `listen()`, `accept()`, `connect()`, `send()`, `recv()`, và bè
   bạn
6. Nền tảng client-server &mdash; chương trình thực sự đầu tiên của bạn
7. Kỹ thuật nâng cao một chút &mdash; `select()`, `poll()`, `send()`
   gửi từng phần, serialization, broadcast
8. Câu hỏi thường gặp &mdash; những gì mọi người hay hỏi Beej
9. Man page &mdash; một tour có chọn lọc
10. Tài liệu tham khảo thêm &mdash; đi tiếp từ đâu

## Tình trạng

Bản dịch đang làm, mỗi lần một chương. Theo dõi tiến độ trong
[ROADMAP.md](ROADMAP.md) hoặc issue
[#1](https://github.com/tamnd/bgnet-vi/issues/1).

| # | Chương | Tình trạng |
|---|--------|------------|
| 1 | Giới thiệu | đang review ([#2](https://github.com/tamnd/bgnet-vi/pull/2)) |
| 2 | Socket là gì? | chưa bắt đầu |
| 3 | Địa chỉ IP, struct, và xử lý dữ liệu | chưa bắt đầu |
| 4 | Từ IPv4 nhảy sang IPv6 | chưa bắt đầu |
| 5 | System call hoặc không gì cả | chưa bắt đầu |
| 6 | Nền tảng client-server | chưa bắt đầu |
| 7 | Kỹ thuật nâng cao một chút | chưa bắt đầu |
| 8 | Câu hỏi thường gặp | chưa bắt đầu |
| 9 | Man page | chưa bắt đầu |
| 10 | Tài liệu tham khảo thêm | chưa bắt đầu |

## Bố cục repo

```
bgnet-vi/
├── src/         # Bản gốc tiếng Anh (lấy từ upstream, không sửa)
├── src_vi/      # Bản dịch tiếng Việt (phần hay ho ở đây)
├── source/      # Chương trình C mẫu (giữ nguyên từ upstream)
├── translations/# Các bản dịch ngôn ngữ khác có sẵn từ upstream
├── website/     # Tài nguyên website của upstream
├── ROADMAP.md   # Kế hoạch và tiến độ dịch
├── LICENSE     # CC BY-NC-ND 3.0, giống upstream
└── README.md   # Bạn đang ở đây
```

Mỗi chương đã dịch trong `src_vi/` tương ứng một-một với file trong
`src/` (cùng tên file, cùng section anchor). Như vậy bạn luôn có thể
diff hai file để phát hiện chỗ lệch.

## Cách đọc

**Trên web:** bản HTML tiếng Việt sẽ được host tại một URL chưa chốt
khi có đủ chương. Trước mắt, đọc thẳng markdown trong `src_vi/`,
GitHub render vẫn ổn.

**Offline:** clone repo về, mở bất kỳ file nào trong `src_vi/` bằng
trình đọc markdown. Thế thôi.

**Tự build PDF/HTML:** xem phần [Build](#build) bên dưới.

## Đóng góp

Pull request luôn được chào đón. Vài quy tắc để giữ văn bản dễ đọc:

- **Mỗi PR một chương.** Đừng gộp. PR nhỏ được merge nhanh, PR lớn nằm
  đó.
- **Dịch ý, không dịch chữ.** Nếu bản dịch nguyên văn đọc như máy viết,
  viết lại. Giọng Beej đời thường, giọng bạn cũng nên vậy.
- **Không dịch máy.** Nghiêm túc đấy. Đọc là biết liền. Nếu bạn không có
  thời gian trau chuốt, đừng gửi.
- **Giữ nguyên code block, tên hàm, và tên trang `man` bằng tiếng
  Anh.** `bind()` vẫn là `bind()`. `struct sockaddr` vẫn là
  `struct sockaddr`.
- **Lần đầu xuất hiện một thuật ngữ kỹ thuật:** viết tiếng Anh trước,
  tiếng Việt trong ngoặc nếu có ích. Các lần sau có thể bỏ tiếng Việt.
- **Không dùng em dash trong văn xuôi tiếng Việt.** Viết lại câu hoặc
  dùng dấu phẩy.
- **Giữ nguyên section anchor.** Tiếng Anh là `{#windows}` thì tiếng
  Việt cũng `{#windows}`.

### Quy trình

1. Chọn một chương ở bảng trên đang ghi "chưa bắt đầu".
2. Mở issue nói bạn đang nhận chương đó, tránh trùng việc với người
   khác.
3. Tạo nhánh: `translate/<slug-chương>` (ví dụ `translate/socket`).
4. Copy `src/bgnet_part_NNNN_<slug>.md` sang `src_vi/` với cùng tên
   file. Dịch trực tiếp trên đó.
5. Mở PR vào nhánh `main`. Tham chiếu đến issue ROADMAP.
6. Chờ review. Mục tiêu là văn bản đọc như một developer người Việt tự
   viết từ đầu, không phải dịch máy.

### Reviewer sẽ xem gì

- Đọc to lên có tự nhiên không?
- Các câu đùa có còn duyên không?
- Code block có bị động vào không?
- Link anchor và ảnh có còn nguyên không?
- Có câu nào dịch máy lọt vào không?

## Build

Repo này giữ nguyên hệ thống build của upstream. Để tự tạo PDF/HTML,
làm theo hướng dẫn upstream:

- [README upstream][upstream-readme] cho dependency (`pandoc`,
  `xelatex`, font Liberation)
- Hệ thống build [`bgbspd`][bgbspd] (clone về làm thư mục song song)

Sau đó, tại thư mục gốc repo:

```
make all
```

Hoặc qua Docker:

```
docker build -t bgnet-vi-builder .
docker run --rm -v "$PWD":/guide -ti bgnet-vi-builder
```

Build hiện đang nhắm vào bản tiếng Anh trong `src/`. Target riêng cho
tiếng Việt còn TODO. Trước mắt, thay `src/` bằng `src_vi/` ở máy
local để build bản tiếng Việt.

[upstream-readme]: https://github.com/beejjorgensen/bgnet/blob/main/README.md
[bgbspd]: https://github.com/beejjorgensen/bgbspd

## Đồng bộ với upstream

Commit upstream mà bản dịch này bám theo: `9fb2a78`
(beejjorgensen/bgnet, nhánh main).

Khi upstream có cập nhật, chúng tôi đồng bộ lại `src/` theo upstream,
rồi diff sẽ cho biết chương dịch nào cần chỉnh lại. Nếu bạn phát hiện
lệch, mở issue.

## Ghi công

- **Tài liệu gốc:** Brian "Beej Jorgensen" Hall, 1995 đến nay,
  https://beej.us/guide/bgnet/
- **Bản dịch tiếng Việt:** Duc-Tam Nguyen (tamnd@liteio.dev) và
  [cộng đồng đóng góp](https://github.com/tamnd/bgnet-vi/graphs/contributors)

## Giấy phép

[CC BY-NC-ND 3.0](LICENSE), giống upstream. Bạn được đọc, được chia sẻ,
và được dịch. Bạn không được bán hay tạo tác phẩm phái sinh (trừ bản
dịch, upstream cho phép rõ ràng). Code trong tài liệu là public domain.

Toàn văn: [LICENSE](LICENSE) &middot; [trang của Creative
Commons](https://creativecommons.org/licenses/by-nc-nd/3.0/).
