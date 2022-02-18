# Beej's Guide to Network Programming
Using Internet Sockets

Brian “Beej Jorgensen” Hall

v3.1.5, Copyright © November 20, 2020

<details>
<summary>Table of Contents</summary>

- [2 What is a socket?](#2-what-is-a-socket)
  * [2.1 Two Types of Internet Sockets](#21-two-types-of-internet-sockets)
  * [2.2 Low level Nonsense and Network Theory](#22-low-level-nonsense-and-network-theory)
- [3 IP Addresses, structs, and Data Munging](#3-ip-addresses-structs-and-data-munging)
  * [3.1 IP Addresses, versions 4 and 6](#31-ip-addresses--versions-4-and-6)
    + [3.1.1 Subnets](#311-subnets)
    + [3.1.2 Port Numbers](#312-port-numbers)
  * [3.2 Byte Order](#32-byte-order)
  * [3.3 structs](#33-structs)
  * [3.4 IP Addresses, Part Deux](#34-ip-addresses-part-deux)
    + [3.4.1 Private (Or Disconnected) Networks](#341-private-or-disconnected-networks)
- [4 Jumping from IPv4 to IPv6](#4-jumping-from-ipv4-to-ipv6)
- [5 System Calls or Bust](#5-system-calls-or-bust)
  * [5.1 getaddrinfo()—Prepare to launch!](#51-getaddrinfoprepare-to-launch)
  * [5.2 socket()—Get the File Descriptor!](#52-socketget-the-file-descriptor)
  * [5.3 bind()—What port am I on?](#53-bindwhat-port-am-i-on)
  * [5.4 connect()—Hey, you!](#54-connecthey-you)
  * [5.5 listen()—Will somebody please call me?](#55-listenwill-somebody-please-call-me)
  * [5.6 accept()—“Thank you for calling port 3490.”](#56-acceptthank-you-for-calling-port-3490)
  * [5.7 send() and recv()—Talk to me, baby!](#57-send-and-recvtalk-to-me-baby)
  * [5.8 sendto() and recvfrom()—Talk to me, DGRAM-style](#58-sendto-and-recvfromtalk-to-me-dgram-style)
  * [5.9 close() and shutdown()—Get outta my face!](#59-close-and-shutdownget-outta-my-face)
  * [5.10 getpeername()—Who are you?](#510-getpeernamewho-are-you)
  * [5.11 gethostname()—Who am I?](#510-getpeernamewho-are-you)
- [6 Client-Server Background](#6-client-server-background)
  * [6.1 A Simple Stream Server](#61-a-simple-stream-server)
  * [6.2 A Simple Stream Client](#62-a-simple-stream-client)
  * [6.3 Datagram Sockets](#63-datagram-sockets)

</details>

## 2 What is a socket?
ソケットという言葉をよく耳にしますが、そもそも"ソケット"とは何なのでしょうか？それは、標準的なUnixのファイルディスクリプタを使って他のプログラムと会話するための方法です。

何と？

Unixのハッカーが、"なんてこった、Unixのすべてはファイルだ！"と言ったのを聞いたことがあるかもしれません。その人が言っているのは、Unixのプログラムが何らかのI/Oを行うとき、ファイル記述子に対して読み書きを行うという事実のことでしょう。ファイルディスクリプタは、単純に、開いているファイルに関連する整数です。しかし、このファイルは、ネットワーク接続、FIFO、パイプ、ターミナル、ディスク上のファイルなど、あらゆるものになり得ます（ここが重要）。Unix ではすべてがファイルなのです! だから、インターネット上で他のプログラムと通信したいときは、ファイル記述子を介して行うことになる。

"ネットワーク通信のためのファイルディスクリプタはどこで手に入るのでしょうか、お利口さんですね "というのが、今あなたが考えている最後の質問でしょうが、とにかくそれに答えてあげましょう。システムルーチンの`socket()`を呼び出すのです。`socket()`システムルーチンを呼び出すと、ソケットディスクリプタが返され、それを使って特殊な `send()` と recv() (man send, man recv) ソケットコールを使って通信を行います。

"でもね！"あなたは今まさにそう叫んでいるかもしれません。"ファイルディスクリプタなら、なぜネプチューンの名において、通常の `read()` や `write()` 呼び出しでソケットを通して通信できないんだ？" と。短い答えは、"できる！"です。もっと長い答えは、"できるけど、`send()` や `recv()` の方がデータ転送をより細かく制御できる "です。

次は何？どうでしょう、ソケットにはいろいろな種類がありますね。DARPA インターネットアドレス (インターネットソケット)、ローカルノード上のパス名 (Unix ソケット)、CCITT X.25 アドレス (X.25 ソケット、無視しても大丈夫)、そしておそらくあなたが実行する Unix のフレーバーに応じて他の多くの種類があります。この文書では、最初のインターネットソケットのみを扱います。

### 2.1 Two Types of Internet Sockets
これは何？インターネットソケットには2種類ある？そうです。まあ、違うけど。嘘です。もっとあるんだけど、怖がらせたくなかったんだ。ここでは2種類しか話しません。ただし、この文章では、"Raw Sockets"も非常に強力なので、ぜひ調べてみてください、と書いています。

わかったよ、もう。この2つのタイプは何ですか？一つは"ストリームソケット"、もう一つは"データグラムソケット"で、以下それぞれ"SOCK_STREAM" "SOCK_DGRAM"と表記することがあります。データグラムソケットは、"コネクションレス型ソケット"と呼ばれることもある。(ただし、本当に必要ならconnect()することができる。後述のconnect()を参照)。

ストリームソケットは、信頼性の高い双方向接続の通信ストリームです。ソケットに2つのアイテムを"1, 2"という順序で出力すると、反対側にも"1, 2"という順序で届きます。また、エラーも発生しません。もし、そうでないと主張する人がいたら、耳に指を突っ込んでララララと唱えてやりたいくらいだ。

ストリームソケットは何を使うのか？さて、皆さんはtelnetというアプリケーションをご存じでしょうか？これは、ストリームソケットを使用しています。入力した文字がすべて、入力した順番に届く必要がありますよね？また、WebブラウザはHTTP(Hypertext Transfer Protocol)を使っていますが、これもストリームソケットを使ってページを取得しています。実際、80番ポートのWebサイトにtelnetでアクセスし、"GET / HTTP/1.0"と入力してリターンを2回押すと、HTMLがダンプされて戻ってきますよ。

> telnetがインストールされておらず、インストールしたくない場合、またはtelnetがクライアントへの接続についてうるさい場合、ガイドにはtelnot7と呼ばれるtelnetのようなプログラムが付属しています。これは、このガイドのすべての必要性に対してうまく機能するはずです。(telnet は実際には仕様化されたネットワークプロトコルであり8、 telnot はこのプロトコルを全く実装していないことに注意してください)。

ストリームソケットは、どのようにしてこの高いレベルのデータ伝送品質を実現しているのでしょうか。それは、"TCP "として知られる "The Transmission Control Protocol"というプロトコルを使っているからです（TCPに関する非常に詳しい情報はRFC 793を参照してください）。TCPは、データが順次、エラーなく到着することを確認します。TCP"は"TCP/IP"の半分で、"IP"は"Internet Protocol"（RFC 791 参照）の略です。IP は主にインターネットのルーティングを扱い、一般にデータの完全性には責任を持ちません。

かっこいい。データグラムソケットについてはどうですか？なぜコネクションレス型と呼ばれるのでしょうか？どうなっているんだ？なぜ信頼性が低いのでしょうか？データグラムを送ると、それが届くかもしれません。データグラムを送信すると、それは到着するかもしれません。もし到着すれば、パケット内のデータはエラーフリーです。

データグラムソケットもルーティングにIPを使いますが、TCPではなく、"User Datagram Protocol"または"UDP"（RFC 768参照）を使用します。

なぜコネクションレス型なのか？まあ、基本的には、ストリームソケットのようにオープンな接続を維持する必要がないからです。パケットを作り、その上に宛先情報を含むIPヘッダを貼り付け、送信するだけでいいのです。接続は必要ない。一般的には、TCPスタックが使用できない場合や、パケットをいくつか落としても宇宙の終わりを意味しない場合に使用されます。アプリケーション例：tftp (trivial file transfer protocol, a little brother to FTP), dhcpcd (a DHCP client), マルチプレイヤーゲーム、ストリーミングオーディオ、ビデオ会議、などなど。

"ちょっと待った！tftpとdhcpcdはバイナリアプリケーションをあるホストから別のホストに転送するために使われているんだ！"。アプリケーションが到着したときに動作することを期待するならば、データが失われることはありえない! どんな黒魔術なんだ？"

さて、人間の友人ですが、tftpやそれに類するプログラムは、UDPの上に独自のプロトコルを載せています。例えば、tftpのプロトコルは、パケットを送信するごとに、受信者は"受け取ったよ！"というパケットを送り返さなければならない、と言っています。というパケット("ACK"パケット)を送り返さなければなりません。元のパケットの送信者は、例えば5秒間返信がない場合、最終的にACKを得るまでパケットを再送信することになります。この確認手続きは、信頼性の高いSOCK_DGRAMアプリケーションを実装する際に非常に重要です。

ゲーム、オーディオ、ビデオなどの信頼性の低いアプリケーションでは、ドロップされたパケットを無視するか、あるいは巧みに補正しようとします。(Quakeのプレイヤーは、この効果の発現を"呪われたラグ"という専門用語で知っていることでしょう。この場合の "acursed"は、極めて不敬な発言を意味する)

なぜ信頼性の低い基礎プロトコルを使うのか？理由は2つ、速度とスピードです。何が無事に到着したかを追跡し、順序立てて確認したりするよりも、発射して忘れる方がずっと速いのです。チャットメッセージを送るなら、TCPは素晴らしいです。世界中のプレイヤーの位置情報を毎秒40件送るなら、1件や2件が落ちてもそれほど問題ではないので、UDPは良い選択だと思います。

### 2.2 Low level Nonsense and Network Theory
先ほどプロトコルの階層化について触れましたので、そろそろネットワークの実際の仕組みについて、SOCK_DGRAMパケットがどのように構築されるのか、いくつかの例を挙げて説明しましょう。実際、このセクションは読み飛ばしても大丈夫でしょう。しかし、良い背景となります。

```
# データのカプセル化
Ethernet > IP > UDP > TFTP > Data
```

子供たちよ、データカプセル化について学ぶ時間だ! これはとても重要なことです。あまりに重要なので、Chico Stateでネットワークの授業を受けると、このことを学ぶことになるかもしれません;-)。基本的にはこうです：パケットが生まれ、パケットは最初のプロトコル（例えばTFTPプロトコル）によってヘッダー（まれにフッターも）でラップ（"カプセル化"）され、次のプロトコル（例えばUDP）によって全体が再びカプセル化され、さらに次のプロトコル（IP）によって、そしてハードウェア（物理）層の最後のプロトコル（例えばイーサネット）によって再びカプセル化されます。

他のコンピュータがパケットを受信すると、ハードウェアがイーサネットヘッダを、カーネルがIPとUDPヘッダを、TFTPプログラムがTFTPヘッダを取り除き、ようやくデータを手に入れることができるのです。

これでやっと悪名高いレイヤードネットワークモデル（通称"ISO/OSI"）について語れるようになった。このネットワークモデルは、他のモデルに比べて多くの利点を持つネットワーク機能のシステムを記述しています。例えば、データが物理的にどのように転送されるか（シリアル、シンイーサネット、AUI、何でも）を気にせずに、全く同じソケットプログラムを書くことができます。実際のネットワークハードウェアやトポロジーは、ソケットプログラマにとって透過的です。

さっそくですが、本格的なモデルのレイヤーを紹介します。ネットワーククラスの試験のために覚えておいてください。

- Application
- Presentation
- Session
- Transport
- Network
- Data Link
- Physical

物理層は、ハードウェア（シリアル、イーサネットなど）です。アプリケーション層は物理層から想像できる限り離れたところにあり、ユーザがネットワークと対話する場所です。

さて、このモデルは非常に一般的なもので、本当にやろうと思えば、自動車の修理ガイドとして使うこともできるだろう。よりUnixに近いレイヤーモデルは次のようなものでしょう。

- Application Layer (telnet, ftp, etc.)
- Host-to-Host Transport Layer (TCP, UDP)
- Internet Layer (IP and routing)
- Network Access Layer (Ethernet, wi-fi, or whatever)

この時点で、これらのレイヤーが元のデータのカプセル化に対応していることがお分かりいただけたと思います。

シンプルなパケットを作るのに、どれだけの労力が必要なのか、おわかりいただけたでしょうか？じぇじぇじぇ! しかも、パケットヘッダを自分で "cat"を使って入力しなければならないのです! 冗談です。ストリームソケットの場合は、データをsend()するだけでいいんです。データグラムソケットでは、パケットを好きな方法でカプセル化し、sendto()で送るだけでいいのです。カーネルはあなたのためにトランスポート層とインターネット層を構築し、ハードウェアはネットワークアクセス層を構築するのです。ああ、現代の技術だ。

というわけで、ネットワーク理論についての簡単な解説を終わります。そうそう、ルーティングについて言いたいことを全部言うのを忘れていた：何もない！（笑）。その通り、全く話すつもりはありません。ルータはパケットをIPヘッダに分解し、ルーティングテーブルを参照し、ブラブラブラブラ。もし本当に気になるなら、IP RFCをチェックしてみてください。もし、あなたがそれについて学ぶことがなければ、まあ、あなたは生きていくでしょう。

## 3 IP Addresses, structs, and Data Munging
ここからは気分転換にコードの話をするところです。

その前に、もっとノンコードの話をしましょう! イエーイ! まず最初にIPアドレスとポートについて少しお話したいと思いますので、それを整理します。それからソケットAPIがどのようにIPアドレスや他のデータを保存し、操作するかについて話します。

### 3.1 IP Addresses, versions 4 and 6
ベン・ケノービがまだオビワン・ケノービと呼ばれていた頃、インターネット・プロトコル・バージョン4（IPv4）と呼ばれる素晴らしいネットワーク・ルーティング・システムが存在しました。IPv4は4バイト（4オクテット）で構成されるアドレスで、一般的には次のように"ドットと数字"で記述されていました。`192.0.2.111`.

皆さんも一度は目にしたことがあるのではないでしょうか。

実際、この記事を書いている時点では、インターネット上のほぼすべてのサイトがIPv4を使っています。

オビ・ワンをはじめ、誰もが幸せでした。しかし、ヴィント・サーフという名の否定的な人物が、IPv4アドレスが足りなくなると警告を発したのです。

(ヴィント・サーフ氏は、IPv4による"破滅と暗黒の黙示録"の到来を警告するとともに、"インターネットの父"としても有名です。だから、私は彼の判断に二の足を踏む立場にはないのだ)。

アドレスが足りなくなる？そんなことがあるのでしょうか？つまり、32ビットのIPv4アドレスには何十億ものIPアドレスが存在するのです。本当に何十億台ものコンピュータがあるのだろうか？

Yes.

また、コンピュータが数台しかなく、10億という数字があり得ないほど大きいと誰もが思っていた当初、いくつかの大きな組織は、自分たちが使うために何百万というIPアドレスを惜しげもなく割り当てていたのです。(ゼロックス、MIT、フォード、HP、IBM、GE、AT&T、そしてアップルという小さな会社などです)。

実際、いくつかの応急処置がなかったら、とっくに使い果たしていたでしょう。

しかし今は、すべての人間がIPアドレスを持ち、すべてのコンピュータ、電卓、電話、パーキングメーター、そして（なぜか）子犬も、という時代です。

そして、IPv6が誕生したのです。ヴィント・サーフはおそらく不死身なので（たとえ肉体がこの世を去ったとしても、おそらく彼はインターネット2の奥底で超知的なELIZAプログラムとしてすでに存在しています）、次のバージョンのインターネットプロトコルで十分なアドレスが確保できなければ、誰も彼の"だから言っただろう"という言葉を再び聞きたくはないでしょう。

これは何を示唆しているのでしょうか？

もっとたくさんのアドレスが必要だということです。2倍どころか10億倍でもなく 1000兆倍でもなく 7900万ビリオン・トリリオンの数のアドレスが必要なのです そうこなくちゃ！

"ビージェイ、それは本当なの？大きな数字を信じない理由があるんだ。" 32ビットと128ビットの差は大したことないように聞こえるかもしれない、96ビット多いだけだろ？しかし、私たちはここで累乗の話をしていることを忘れてはならない。32ビットは約40億個（2^32個）、128ビットは約340兆個（2^128個）の数字に相当するのだ。これは、宇宙の星1つに対して、100万個のIPv4インターネットがあるようなものです。

IPv4のドットや数字も忘れて、16進数で、2バイトの塊をコロンで区切って、このように表現しています。

```
2001:0db8:c9d2:aee5:73e3:934a:a5ae:9551
```

それだけではありません! 多くの場合、IPアドレスにはたくさんのゼロが含まれていますが、それらを2つのコロンで区切って圧縮することができます。そして、各バイトペアの先頭のゼロを省くことができます。例えば、次のようなアドレスのペアは、それぞれ等価です。

```
2001:0db8:c9d2:0012:0000:0000:0000:0051
2001:db8:c9d2:12::51

2001:0db8:ab00:0000:0000:0000:0000:0000
2001:db8:ab00::

0000:0000:0000:0000:0000:0000:0000:0001
::1
```

アドレス `::1` はループバックアドレスです。常に"今走っているこのマシン"という意味です。IPv4では、ループバックアドレスは`127.0.0.1`です。

最後に、IPv6アドレスのIPv4互換モードですが、これは皆さんが遭遇する可能性のあるものです。例えば、IPv4アドレスの`192.0.2.33`をIPv6アドレスとして表現したい場合、以下のような表記になります。`::ffff:192.0.2.33` となります。

本気で楽しみたいんです。

実際、IPv6の開発者たちは、何兆個ものアドレスを軽率にも予約用に切り捨てたほど、IPv6は楽しいものなのですが、数が多すぎて、正直言って、もう誰が数えているのでしょうか？銀河系のすべての惑星のすべての男性、女性、子供、子犬、そしてパーキングメーターのために十分な数が残されています。信じてくれ、銀河系のどの星にもパーキングメーターはあるんだ。本当なんだ。

#### 3.1.1 Subnets
組織的な理由から、"このIPアドレスのこのビットまでの部分がネットワーク部分、それ以外がホスト部分"と宣言するのが便利な場合があります。

例えば、IPv4の場合、`192.0.2.12`とありますが、最初の3バイトがネットワークで、最後の1バイトがホストと言うことができます。あるいは、別の言い方をすれば、ネットワーク`192.0.2.0`上のホスト12について話していることになります（ホストであるバイトをゼロにしているところをご覧ください）。

そして、さらに時代遅れの情報を! 準備はいいですか？古代では、サブネットには"クラス"があり、アドレスの最初の1バイト、2バイト、3バイトがネットワーク部分でした。運良く1バイトがネットワーク、3バイトがホストの場合、ネットワーク上に24ビット分のホスト（1600万程度）を持つことができます。これが"クラスA"のネットワークです。一方、"クラスC"は、ネットワークが3バイト、ホストが1バイトで、256台のホスト（ただし、予約された数台は除く）を持ちます。

ご覧のように、Aクラスがほんの少し、Cクラスが大量に、そして真ん中にBクラスが何個かある状態でした。

IPアドレスのネットワーク部分は、ネットマスクと呼ばれるもので記述され、IPアドレスとビット単位でANDすることでネットワーク番号を取得します。ネットマスクは通常、`255.255.255.0`のようなものです（例えば、このネットマスクでは、IPが`192.0.2.12`なら、ネットワークは`192.0.2.12` AND `255.255.255.0` で `192.0.2.0` となり ます）。

クラスCのネットワークはすぐに足りなくなったし、クラスAのネットワークも足りなくなったので、わざわざ尋ねる必要はありません。この問題を解決するために、権力者たちはネットマスクを 8、16、24 のどれでもなく、任意のビット数にすることを許可しました。例えば、 `255.255.255.252` というネットマスクは、30 ビットのネットワークと、2 ビットのホストで、ネットワーク上に 4 台のホストが存在することになります。(ネットマスクは常に1ビットの束と0ビットの束であることに注意してください)。

しかし、`255.192.0.0`ような大きな数字の羅列をネットマスクとして使うのは、ちょっと扱いにくいですね。まず、それが何ビットなのかが直感的にわからないし、コンパクトでもありません。そこで、新スタイルが登場し、よりすっきりしました。IPアドレスの後にスラッシュを付けて、その後に10進数でネットワークのビット数を指定するだけです。こんな感じです。`192.0.2.12/30`。

あるいは、IPv6の場合、こんな感じ。`2001:db8::/32` または `2001:db8:5413:4028::9db9/64` のようなものです。

#### 3.1.2 Port Numbers
以前、インターネット層（IP）とホスト間トランスポート層（TCPとUDP）を分離したレイヤード・ネットワークモデルを紹介しましたが、覚えているでしょうか。次の段落の前に、そのことをしっかり覚えておいてください。

IPアドレス（IP層で使われる）の他に、TCP（ストリームソケット）や、偶然にもUDP（データグラムソケット）で使われるアドレスがあることが判明したのです。それは、ポート番号です。これは16ビットの数字で、接続のためのローカルアドレスのようなものです。

IPアドレスはホテルの番地、ポート番号は部屋番号だと思ってください。まともな例えですね。後日、自動車産業を題材にしたものを考えてみたいと思います。

例えば、メールの受信とWebサービスの両方を扱うコンピュータを用意したい場合、1つのIPアドレスを持つコンピュータでこの2つを区別する方法はあるのでしょうか？

さて、インターネット上のサービスには、それぞれ異なるウェルノウン・ポート番号が設定されています。IANAのポート一覧か、Unixなら`/etc/services`ファイルで確認できます。HTTP（ウェブ）はポート80、telnetはポート23、SMTPはポート25、ゲームDOOMはポート666を使用、などなど。1024以下のポートは特殊とみなされることが多く、通常、使用するにはOSの特別な権限が必要です。

といったところでしょうか。

### 3.2 Byte Order
レルムの命令で！バイトの並び順は2種類とします。今後、Lame and Magnificentと呼ばれるようになります。

というのは冗談ですが、本当にどちらか一方が優れているのです :-)

あなたのコンピュータは、あなたの背後でバイトを逆順に保存しているかもしれないのです。そうなんです。誰もあなたに言いたくはなかったのです。

つまり、2バイトの16進数、たとえばb34fを表現する場合、b3と4fの2バイトに続けて格納する、というのがインターネットの世界の共通認識になっているのです。これは理にかなっているし、ウィルフォード・ブリムリーも言うように、正しい行為です。このように、大きい方の端が先になるように格納された数字をビッグエンディアン（Big-Endian）と呼びます。

残念ながら、世界中に散在する一部のコンピュータ、すなわちインテルまたはインテル互換のプロセッサを搭載したものは、バイトを逆に格納しているため、b34fは4fとb3の連続したバイトとしてメモリに格納されることになります。この記憶方式をリトルエンディアンと呼びます。

でも、ちょっと待ってください！用語の説明はまだ終わっていないのです。もっとまともなBig-EndianはNetwork Byte Orderとも呼ばれ、私たちネットワーク系が好む順序だからです。

コンピュータはホストバイトオーダーで数字を記憶しています。インテル80x86であれば、ホストバイト順はリトルエンディアンです。モトローラ68Kの場合は、ビッグエンディアンです。PowerPCなら、ホストバイトの並びは......まあ、人それぞれですね。

パケットを作成するときやデータ構造を埋めるときに、2バイトや4バイトの数値がネットワークバイトオーダーになっていることを確認する必要があることがよくあります。しかし、ネイティブなHost Byte Orderがわからない場合、どのようにすればよいのでしょうか。

朗報です。ホストのバイトオーダーが正しくないと仮定して、値をネットワークバ イトオーダーに設定するための関数を常に実行するようにすればよいのです。この関数は、必要であれば魔法のような変換を行い、エンディアンが異なるマシンにもコードを移植することができます。

よしよし。変換できる数値は、short（2バイト）とlong（4バイト）の2種類です。これらの関数は、符号なしのバリエーションでも動作します。例えば、shortをHost Byte OrderからNetwork Byte Orderに変換したいとします。まず "h"でホスト、その後に "to"をつけます。そして、"n" は "network"、"s"は "short"を表します。h-to-n-s または htons() (読み方: "ホストからネットワークへのショート") です。

簡単すぎるくらいに...。

"n"、"h"、"s"、"l "の組み合わせは、本当にくだらないものを除いて、すべて使うことができるのです。たとえば、stolh() ("Short to Long Host") という関数はありません-とにかく、このパーティーでは。しかし、あるのです。

| Function  | Description           |
|-----------|-----------------------|
| `htons()` | host to network short |
| `htonl()` | host to network long  |
| `ntohs()` | network to host short |
| `ntohl()` | network to host long  |

基本的には、送出する前にネットワークバイトオーダーに変換し、送出後にホストバイトオーダーに変換します。

64bitのバリエーションは知らないです、すみません。また、浮動小数点をやりたい場合は、ずっと下の"シリアライズ"のセクションをチェックしてください。

この文書では、特に断らない限り、数値はHost Byte Orderであると仮定しています。

### 3.3 structs
さて、ついにここまで来ました。そろそろプログラミングの話をしましょう。このセクションでは、ソケットインターフェイスで使用される様々なデータ型について説明します。

まず、簡単なものから。ソケットディスクリプタです。ソケットディスクリプタは以下のような型です。

```cpp
int
```

普通の`int`です。

ここからは変な話なので、我慢して読んでください。

My First Struct™--struct addrinfo. この構造体は最近開発されたもので、ソケットアドレス構造体を後で使用するために準備するために使用されます。また、ホスト名のルックアップやサービス名のルックアップにも使用されます。これは、後で実際の使い方を説明するときに、より意味をなすと思いますが、今は、接続を行うときに最初に呼び出されるものの1つであることを知っておいてください。

```cpp
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

この構造体を少し読み込んでから、`getaddrinfo()`を呼び出します。この構造体のリンクリストへのポインタが返され、必要なものがすべて満たされます。

`ai_family`フィールドでIPv4かIPv6を使うように強制することもできますし、`AF_UNSPEC`のままにして何でも使えるようにすることも可能です。これは、あなたのコードがIPバージョンに依存しないので、クールです。

これはリンクされたリストであることに注意してください：`ai_next`は次の要素を指しています-そこから選択するためにいくつかの結果があるかもしれません。私は最初にうまくいった結果を使いますが、あなたは異なるビジネスニーズを持っているかもしれません。

`struct addrinfo`の`ai_addr`フィールドは`struct sockaddr`へのポインタであることがわかります。ここからが、IPアドレス構造体の中身についての細かい話になります。

通常、これらの構造体に書き込む必要はありません。多くの場合、`addrinfo`構造体を埋めるために`getaddrinfo()`を呼び出すだけでよいでしょう。しかし、これらの構造体の内部を覗いて値を取得する必要があるため、ここでそれらを紹介します。

(また、構造体`addrinfo`が発明される前に書かれたコードはすべて、これらのものをすべて手作業で梱包していたので、まさにそのようなIPv4コードを多く見かけることができます。このガイドの古いバージョンなどでもそうです)。

ある構造体はIPv4で、ある構造体はIPv6で、ある構造体はその両方です。どれが何なのか、メモしておきます。

とにかく、構造体`sockaddr`は、多くの種類のソケットのためのソケットアドレス情報を保持します。

```cpp
struct sockaddr {
    unsigned short    sa_family;    // address family, AF_xxx
    char              sa_data[14];  // 14 bytes of protocol address
};
```

`sa_family` には様々なものを指定できるが、この文書ではすべて AF_INET (IPv4) または AF_INET6 (IPv6) とします。 `sa_data` にはソケットの宛先アドレスとポート番号を指定します。`sa_data`にアドレスを手で詰め込むのは面倒なので、これはかなり扱いにくいです。

構造体`sockaddr`を扱うために、プログラマはIPv4で使用する構造体`sockaddr_in`（"in "は "Internet "の意）を並列に作成しました。

`sockaddr_in`構造体へのポインタは`sockaddr`構造体へのポインタにキャストすることができ、その逆も可能です。つまり、connect() が `struct sockaddr*` を要求しても、`struct sockaddr_in` を使用して、最後の最後でキャストすることができるのです!

```cpp
// (IPv4 only--see struct sockaddr_in6 for IPv6)

struct sockaddr_in {
    short int          sin_family;  // Address family, AF_INET
    unsigned short int sin_port;    // Port number
    struct in_addr     sin_addr;    // Internet address
    unsigned char      sin_zero[8]; // Same size as struct sockaddr
};
```

この構造体により、ソケットアドレスの要素を簡単に参照することができます。`sin_zero` (構造体を `struct sockaddr` の長さに合わせるために含まれる) は、関数 `memset()` ですべて 0 に設定する必要があることに注意すること。また、`sin_family` は `struct sockaddr` の `sa_family` に相当し、"AF_INET" に設定されることに注意します。最後に、`sin_port`はネットワークバイトオーダーでなければなりません（`htons()`を使用することで！）。

もっと掘り下げよう! `sin_addr`フィールドは`in_addr`構造体であることがわかりますね。あれは何なんだ？まあ、大げさではなく、史上最も恐ろしい組合せの1つです。

```cpp
// (IPv4 only--see struct in6_addr for IPv6)

// Internet address (a structure for historical reasons)
struct in_addr {
    uint32_t s_addr; // that's a 32-bit int (4 bytes)
};
```

うおぉ まあ、昔は組合だったんだけど、今はもうそういう時代じゃないみたいだね。おつかれさまでした。つまり、`ina`を`struct sockaddr_in`型と宣言した場合、`ina.sin_addr.s_addr`は4バイトのIPアドレス（ネットワークバイトオーダー）を参照することになります。あなたのシステムがまだ`struct in_addr`のための神々しいユニオンを使用している場合でも、あなたはまだ私が上記のように全く同じ方法で4バイトのIPアドレスを参照することができます（これは`#defines`によるものです）ことに注意してください。

IPv6ではどうでしょうか。これについても同様の構造体が存在します。

```cpp
// (IPv6 only--see struct sockaddr_in and struct in_addr for IPv4)

struct sockaddr_in6 {
    u_int16_t       sin6_family;   // address family, AF_INET6
    u_int16_t       sin6_port;     // port number, Network Byte Order
    u_int32_t       sin6_flowinfo; // IPv6 flow information
    struct in6_addr sin6_addr;     // IPv6 address
    u_int32_t       sin6_scope_id; // Scope ID
};

struct in6_addr {
    unsigned char   s6_addr[16];   // IPv6 address
};
```

IPv4がIPv4アドレスとポート番号を持つように、IPv6もIPv6アドレスとポート番号を持つことに注意してください。

また、IPv6フロー情報やスコープIDのフィールドについては、今のところ触れないことに注意してください。）

最後になりますが、こちらもシンプルな構造体である `struct sockaddr_storage` は、IPv4 と IPv6 の両方の構造体を保持できるように十分な大きさに設計されています。この構造体はIPv4とIPv6の両方の構造体を保持できるように設計されています。そこで、この並列構造体を渡しますが、サイズが大きい以外は`struct sockaddr`とよく似ており、必要な型にキャストします。

```cpp
struct sockaddr_storage {
    sa_family_t  ss_family;     // address family

    // all this is padding, implementation specific, ignore it:
    char      __ss_pad1[_SS_PAD1SIZE];
    int64_t   __ss_align;
    char      __ss_pad2[_SS_PAD2SIZE];
};
```

重要なのは、`ss_family`フィールドでアドレスファミリーを確認できることで、これが`AF_INET`か`AF_INET6`（IPv4かIPv6か）かを確認することです。それから、必要なら `struct sockaddr_in` や `struct sockaddr_in6` にキャストすることができます。

### 3.4 IP Addresses, Part Deux
幸いなことに、IPアドレスを操作するための関数がたくさんあります。手書きで把握して << 演算子で long に詰め込む必要はありません。

まず、`struct sockaddr_in ina`があり、そこに格納したいIPアドレスが`10.12.110.57`または`2001:db8:63b3:1::3490`だとしましょう。`inet_pton()`という関数は、数字とドットで表記されたIPアドレスを、`AF_INET`か`AF_INET6`の指定によって、`in_addr`構造体か`in6_addr`構造体に変換する関数です。("pton" は "presentation to network" の略で、覚えやすければ "printable to network" と呼んでも構いません)。変換は次のように行うことができます。

```cpp
struct sockaddr_in sa; // IPv4
struct sockaddr_in6 sa6; // IPv6

inet_pton(AF_INET, "10.12.110.57", &(sa.sin_addr)); // IPv4
inet_pton(AF_INET6, "2001:db8:63b3:1::3490", &(sa6.sin6_addr)); // IPv6
```

(クイックメモ: 古い方法では、`inet_addr()`という関数や`inet_aton()`という別の関数を使っていましたが、これらはもう時代遅れでIPv6では動きません)

さて、上記のコードスニペットは、エラーチェックがないため、あまり堅牢ではありません。`inet_pton()` はエラー時に -1 を返し、アドレスがめちゃくちゃになった場合は 0 を返します。ですから、使用する前に結果が 0 よりも大きいことを確認してください!

さて、これで文字列のIPアドレスをバイナリ表現に変換することができるようになりました。では、その逆はどうでしょうか？`in_addr`構造体を持っていて、それを数字とドットの表記で印刷したい場合はどうでしょうか。(この場合、関数 `inet_ntop()` ("ntop" は "network to presentation" という意味です。覚えやすければ "network to printable" と呼んでも構いません) を次のように使用します。

```cpp
// IPv4:

char ip4[INET_ADDRSTRLEN];  // space to hold the IPv4 string
struct sockaddr_in sa;      // pretend this is loaded with something

inet_ntop(AF_INET, &(sa.sin_addr), ip4, INET_ADDRSTRLEN);

printf("The IPv4 address is: %s\n", ip4);


// IPv6:

char ip6[INET6_ADDRSTRLEN]; // space to hold the IPv6 string
struct sockaddr_in6 sa6;    // pretend this is loaded with something

inet_ntop(AF_INET6, &(sa6.sin6_addr), ip6, INET6_ADDRSTRLEN);

printf("The address is: %s\n", ip6);
```

呼び出す際には、アドレスの種類（IPv4またはIPv6）、アドレス、結果を格納する文字列へのポインタ、その文字列の最大長を渡すことになります。(2つのマクロは、最大のIPv4またはIPv6アドレスを保持するために必要な文字列のサイズを都合よく保持します。`INET_ADDRSTRLEN`と`INET6_ADDRSTRLEN`です)。

(古いやり方についてもう一度簡単に触れておくと、この変換を行う歴史的な関数は `inet_ntoa()` と呼ばれるものでした。これも時代遅れで、IPv6では動きません)。

最後に、これらの関数は数値のIPアドレスに対してのみ動作します。"www.example.com "のようなホスト名に対してネームサーバのDNSルックアップは行いません。後ほど説明するように、そのためには `getaddrinfo()` を使用します。

#### 3.4.1 Private (Or Disconnected) Networks
多くの場所では、自分たちを守るために、ネットワークを他の地域から隠すファイアウォールがあります。そして多くの場合、ファイアウォールは、ネットワークアドレス変換（NAT）と呼ばれるプロセスを使って、"内部"IPアドレスを"外部"（世界中の誰もが知っている）IPアドレスに変換しています。

もう緊張してきましたか？"こんな変なことして どこへ行くんだろう？"

まあ、ノンアルコール飲料でも買ってリラックスしてください。初心者の場合、NATは透過的に行われるので、心配する必要もありませんから。しかし、あなたが見ているネットワーク番号に混乱し始めた場合に備えて、ファイアウォールの背後にあるネットワークについて話したいと思います。

例えば、私の自宅にはファイアウォールがあります。DSL会社から割り当てられた2つの固定IPv4アドレスを持っていますが、ネットワーク上に7台のコンピューターがあります。どうしてこんなことが可能なのでしょうか？2台のコンピュータが同じIPアドレスを共有することはできませんし、そうでなければデータはどちらに行けばいいのかわからなくなってしまいます。

答えは、"同じIPアドレスを共有していない"です。2400万個のIPアドレスが割り当てられたプライベートネットワーク上にあるのです。それらはすべて私のためだけのものです。まあ、他の人たちから見れば、すべて私のためのものなのですが。ここで、何が起こっているのかを説明します。

リモートコンピューターにログインすると、ISPから提供されたパブリックIPアドレスである`192.0.2.33`からログインしていると表示されるのです。しかし、ローカルコンピューターにそのIPアドレスを尋ねると、`10.0.0.5`と答えるのです。誰がIPアドレスを変換しているのでしょうか？そうです、ファイアウォールです。ファイアウォールがNATしているのです。

`10.x.x.x`は、完全に切断されたネットワークか、ファイアウォールの内側にあるネットワークでのみ使用される、数少ない予約ネットワークの1つです。どのプライベート・ネットワーク番号が使用できるかの詳細は、RFC 1918に概説されていますが、一般的によく目にするのは、`10.x.x.x` と `192.168.x.x` で、x は通常 0 ～ 255 です。一般的ではないのは、`172.y.x.x`で、yは16から31の間です。

NATするファイアウォールの内側のネットワークは、これらの予約されたネットワークのいずれかにある必要はありませんが、一般的にはそうなっています。

(楽しい事実! 私の外部IPアドレスは、本当は`192.0.2.33`ではないのです。`192.0.2.x` ネットワークは、このガイドのように、ドキュメントで使用するための架空の"本当の"IPアドレスとして予約されているのです! わーい、すごい！)

IPv6にも、ある意味プライベートネットワークがあります。RFC 4193にあるように、fdXX:（将来的にはfcXX:）で始まります。しかし、NATとIPv6は一般的に混ざりません(このドキュメントの範囲外であるIPv6からIPv4へのゲートウェイを行う場合を除く)。理論的には、自由に使えるアドレスが非常に多くなるため、NATを使用する必要はなくなるはずです。しかし、外部にルーティングしないネットワーク上で自分のためにアドレスを割り当てたい場合は、このようにします。

## 4 Jumping from IPv4 to IPv6
しかし、IPv6で動作させるためには、私のコードのどこを変えればいいのか知りたいのです! 今すぐ教えてください!

Ok! Ok!

ここに書かれていることはほとんどすべて、私が上で説明したことですが、せっかちな人のためのショートバージョンです。(もちろん、これ以外にもありますが、このガイドに該当するのはこれです)。

1. まず、構造体を手で詰めるのではなく、`getaddrinfo()`を使ってすべての`sockaddr`構造体の情報を取得するようにしてください。こうすることで、IPのバージョンに左右されず、また、その後の多くのステップを省くことができます。
1. IPバージョンに関連する何かをハードコーディングしていることが分かったら、ヘルパー関数でラップするようにします。
1. `AF_INET`を`AF_INET6`に変更します。
1. `PF_INET`を`PF_INET6`に変更します。
1. `INADDR_ANY` の割り当てを `in6addr_any` の割り当てに変更し、若干の差異が生じます。
    ```cpp
    struct sockaddr_in sa;
    struct sockaddr_in6 sa6;
    
    sa.sin_addr.s_addr = INADDR_ANY;  // use my IPv4 address
    sa6.sin6_addr = in6addr_any; // use my IPv6 address
    ```
    また、`IN6ADDR_ANY_INIT`は、構造体`in6_addr`を宣言する際に、イニシャライザとして次のように使用することができます。
    ```cpp
    struct in6_addr ia6 = IN6ADDR_ANY_INIT;
    ```
1. `struct sockaddr_in` の代わりに `struct sockaddr_in6` を使用し、必要に応じてフィールドに "6" を追加してください（上記の [3.3 structs](#33-structs) を参照）。`sin6_zero`フィールドはありません。
1. `struct in_addr` の代わりに `struct in6_addr` を使用し、必要に応じてフィールドに "6" を追加してください（上記の [3.3 structs](#33-structs) を参照）。
1. `inet_aton()` や `inet_addr()` の代わりに、`inet_apton()` を使用してください。
1. `inet_ntoa()`の代わりに`inet_ntop()`を使用してください。
1. `gethostbyname()`の代わりに、優れた`getaddrinfo()`を使用してください。
1. `gethostbyaddr()`の代わりに、優れた`getnameinfo()`を使用してください（`gethostbyaddr()`はIPv6でも動作可能です）。
1. `INADDR_BROADCAST`は動作しなくなりました。代わりにIPv6マルチキャストを使用してください。

出来上がり

## 5 System Calls or Bust
このセクションでは、Unix マシンのネットワーク機能にアクセスするためのシステムコールやその他のライブラリコールに触れることができますし、ソケット API をサポートしているあらゆるマシン (BSD, Windows, Linux, Mac, など) も同様です。これらの関数を呼び出すと、カーネルが引き継ぎ、すべての作業を自動で行ってくれます。

このあたりで多くの人がつまづくのは、これらのものをどのような順序で呼び出すかということです。これについては、皆さんもお分かりのように、manページが役に立ちません。そこで、この恐ろしい状況を改善するために、以下のセクションのシステムコールを、あなたがプログラムの中で呼び出す必要があるのと全く（おおよそ）同じ順序で並べることにしました。

これに、あちこちにあるサンプルコード、ミルクとクッキー（自分で用意しなければならないのが怖い）、そして生粋のガッツと勇気があれば、"ジョン・ポステルの息子"のようにインターネット上でデータを発信することができるのです!

(なお、以下の多くのコードでは、簡潔にするため、必要なエラーチェックは行っていません。また、`getaddrinfo()`の呼び出しが成功し、リンクリストの有効なエントリを返すと仮定することが非常に一般的です。これらの状況はいずれもスタンドアロン・プログラムで適切に対処されているので、それらをモデルとして使用してください)。

### 5.1 getaddrinfo()—Prepare to launch!
この関数は多くのオプションを持つ真の主力関数ですが、使い方はいたってシンプルです。後で必要な構造体をセットアップするのに役立ちます。

昔は、`gethostbyname()`という関数を使ってDNSのルックアップを行っていました。そして、その情報を `sockaddr_in` 構造体に手作業でロードし、それを呼び出しに使用するのです。

これは、ありがたいことに、もう必要ありません。(IPv4とIPv6の両方で動作するコードを書きたいのであれば、望ましいことではありません!) 現代では、DNSやサービス名のルックアップなど、あらゆる種類の良いことをやってくれる`getaddrinfo()`という関数があり、さらに必要な構造体も埋めてくれます!

それでは、ご覧ください。

```cpp
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *node,     // e.g. "www.example.com" or IP
                const char *service,  // e.g. "http" or port number
                const struct addrinfo *hints,
                struct addrinfo **res);
```

この関数に3つの入力パラメータを与えると、結果のリンクリストであるresへのポインタが得られる。

`node` パラメータには、接続先のホスト名、または IP アドレスを指定します。

次にパラメータ`service`ですが、これは"80"のようなポート番号か、"http", "ftp", "telnet", "smtp"などの特定のサービスの名前（[IANAポートリスト](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)やUnixマシンの`/etc/services`ファイルで見つけることができます）であることができます。

最後に、`hints`パラメータは、関連情報をすでに記入した`addrinfo`構造体を指します。

以下は、自分のホストのIPアドレス、ポート3490をリッスンしたいサーバの場合の呼び出し例です。これは実際にはリスニングやネットワークの設定を行っていないことに注意してください。

```cpp
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // will point to the results

memset(&hints, 0, sizeof hints); // make sure the struct is empty
hints.ai_family = AF_UNSPEC;     // don't care IPv4 or IPv6
hints.ai_socktype = SOCK_STREAM; // TCP stream sockets
hints.ai_flags = AI_PASSIVE;     // fill in my IP for me

if ((status = getaddrinfo(NULL, "3490", &hints, &servinfo)) != 0) {
    fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(status));
    exit(1);
}

// servinfo now points to a linked list of 1 or more struct addrinfos

// ... do everything until you don't need servinfo anymore ....

freeaddrinfo(servinfo); // free the linked-list
```

`ai_family`を`AF_UNSPEC`に設定することで、IPv4やIPv6を使うかどうかを気にしないことを表明していることに注意してください。もし、どちらか一方だけを使いたい場合は、`AF_INET`または`AF_INET6`に設定することができます。

また、`AI_PASSIVE`フラグがあるのがわかると思いますが、これは`getaddrinfo()`にローカルホストのアドレスをソケット構造体に割り当てるように指示しています。これは、ハードコードする必要がないのがいいところです。(あるいは、`getaddrinfo()`の最初のパラメータとして特定のアドレスを入れることもできます。私は現在NULLを持っています。)

そして、呼び出しを行います。エラー(`getaddrinfo()`が0以外を返す)があれば、ご覧のように関数 `gai_strerror()` を使ってそれを表示することができます。しかし、すべてがうまくいけば、`servinfo`は`struct addrinfos`のリンクリストを指し、それぞれのリストには後で使用できる何らかの`sockaddr`構造体が含まれています! 素晴らしい!

最後に、`getaddrinfo()`が快く割り当ててくれたリンクリストをすべて使い終わったら、`freeaddrinfo()`を呼び出してすべてを解放することができます(そうすべき)です。

ここでは、クライアントが特定のサーバ、例えば "www.example.net "ポート3490に接続したい場合のサンプルコールを紹介します。繰り返しますが、これは実際には接続しませんが、後で使用する構造をセットアップしています。

```cpp
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // will point to the results

memset(&hints, 0, sizeof hints); // make sure the struct is empty
hints.ai_family = AF_UNSPEC;     // don't care IPv4 or IPv6
hints.ai_socktype = SOCK_STREAM; // TCP stream sockets

// get ready to connect
status = getaddrinfo("www.example.net", "3490", &hints, &servinfo);

// servinfo now points to a linked list of 1 or more struct addrinfos

// etc.
```

`servinfo`は、あらゆるアドレス情報を持つリンクリストだと言い続けています。この情報を披露するために、簡単なデモプログラムを書いてみよう。[この短いプログラム](https://beej.us/guide/bgnet/examples/showip.c)は、コマンドラインで指定された任意のホストのIPアドレスを表示します。

```cpp
/*
** showip.c -- show IP addresses for a host given on the command line
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
    hints.ai_family = AF_UNSPEC; // AF_INET or AF_INET6 to force version
    hints.ai_socktype = SOCK_STREAM;

    if ((status = getaddrinfo(argv[1], NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 2;
    }

    printf("IP addresses for %s:\n\n", argv[1]);

    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;

        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
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

ご覧のように、このコードはコマンドラインで渡されたものに対して `getaddrinfo()` を呼び出し、`res` が指すリンクリストを埋めて、そのリストを繰り返し表示して何かを出力したりすることができます。

(そこには、IPバージョンによって異なるタイプの構造体`sockaddrs`を掘り下げなければならない、ちょっとした醜さがあります。申し訳ありません。他にいい方法はないかなぁ...)

サンプル走行 みんな大好きスクリーンショット。

```shell
$ showip www.example.net
IP addresses for www.example.net:

  IPv4: 192.0.2.88

$ showip ipv6.example.com
IP addresses for ipv6.example.com:

  IPv4: 192.0.2.101
  IPv6: 2001:db8:8c00:22::171
```

これで、`getaddrinfo()`の結果を他のソケット関数に渡して、ついにネットワーク接続を確立することができます。引き続きお読みください。

### 5.2 socket()—Get the File Descriptor!
もう先延ばしにはできません。`socket()`システムコールの話をしなければならないのです。以下はその内訳です。

```cpp
#include <sys/types.h>
#include <sys/socket.h>

int socket(int domain, int type, int protocol);
```

しかし、これらの引数は何なのでしょうか？これらは、どのようなソケットが欲しいか（IPv4かIPv6か、ストリームかデータグラムか、TCPかUDPか）を指定することができます。

以前は、これらの値をハードコードする人がいましたが、今でも絶対にそうすることができます。(ドメインは `PF_INET` または `PF_INET6`、タイプは `SOCK_STREAM` または `SOCK_DGRAM`、プロトコルは 0 に設定すると、与えられたタイプに適したプロトコルを選択することができます。あるいは `getprotobyname()` を呼んで、"tcp" や "udp" などの欲しいプロトコルを調べることもできます)。

(この`PF_INET`は、`sockaddr_in`構造体の`sin_family`フィールドを初期化するときに使用できる`AF_INET`の近縁種です。実際、両者は非常に密接な関係にあり、実際に同じ値を持っているので、多くのプログラマは`socket()`を呼び出して`PF_INET`の代わりに`AF_INET`を第一引数に渡しています。さて、ミルクとクッキーを用意して、お話の時間です。昔々、あるアドレスファミリ(`AF_INET`のAF)が、プロトコルファミリ(`PF_INET`のPF)で参照される複数のプロトコルをサポートするかもしれないと考えられたことがあります。しかし、そうはならなかった。そして、みんな幸せに暮らした、ザ・エンド。というわけで、最も正しいのは `struct sockaddr_in` で `AF_INET` を使い、`socket()` の呼び出しで `PF_INET` を使うことです)。

とにかく、もう十分です。本当にやりたいことは、`getaddrinfo()`の呼び出しの結果の値を使い、以下のように直接`socket()`に送り込むことです。

```cpp
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

`socket()` は単に、後のシステムコールで使用できるソケットディスクリプタを返すか、エラーの場合は -1 を返します。グローバル変数 errno にはエラーの値が設定されます (詳細については errno のマニュアルページを参照してください。また、マルチスレッドプログラムで errno を使用する際の簡単な注意も参照してください)。

でも、このソケットは何の役に立つのでしょうか？答えは、これだけでは本当に意味がなく、もっと読み進めてシステムコールを作らないと意味がないのです。

### 5.3 bind()—What port am I on?
ソケットを取得したら、そのソケットをローカルマシンのポートに関連付ける必要があるかもしれません。(これは、特定のポートへの接続を `listen()` する場合によく行われます。多人数参加型ネットワークゲームで "192.168.5.10 ポート 3490 に接続" と指示されたときに行います)。ポート番号はカーネルが受信パケットを特定のプロセスのソケットディスクリプタにマッチさせるために使用されます。もしあなたが`connect()`を行うだけなら(あなたはクライアントであり、サーバではないので)、これはおそらく不要でしょう。とにかく読んでみてください。

`bind()`システムコールの概要は以下のとおりです。

```cpp
#include <sys/types.h>
#include <sys/socket.h>

int bind(int sockfd, struct sockaddr *my_addr, int addrlen);
```

`sockfd` は `socket()` が返すソケットファイル記述子です。 `my_addr` は自分のアドレスに関する情報、すなわちポートおよび IP アドレスを含む `sockaddr` 構造体へのポインタです。

ふぅー。一度に吸収するのはちょっと無理があるな。ソケットをプログラムが実行されているホスト、ポート3490にバインドする例を見てみましょう。

```cpp
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

`AI_PASSIVE`フラグを使うことで、プログラムが動作しているホストのIPにバインドするように指示しているのです。もし、特定のローカルIPアドレスにバインドしたい場合は、`AI_PASSIVE`を削除して、`getaddrinfo()`の最初の引数にIPアドレスを入れてください。

`bind()`もエラー時には-1を返し、errnoにエラーの値を設定します。

多くの古いコードでは、`bind()`を呼び出す前に、`sockaddr_in`構造体を手動でパックしています。これは明らかにIPv4特有のものですが、IPv6で同じことをするのを止めるものは何もありません。ただし、一般的には`getaddrinfo()`を使う方が簡単になりそうです。とにかく、古いコードは次のようなものです。

```cpp
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

上記のコードでは、ローカルのIPアドレスにバインドしたい場合、`s_addr`フィールドに`INADDR_ANY`を代入することもできます（上記の`AI_PASSIVE`フラグのようなものです）。`INADDR_ANY`のIPv6バージョンはグローバル変数`in6addr_any`で、 `struct sockaddr_in6` の `sin6_addr` フィールドに代入されます。 (変数の初期化で使用できるマクロ `IN6ADDR_ANY_INIT` も存在します。)また、`IN6ADDR_ANY_INIT`を使用することで、IPv6のIPアドレスにバインドできます。

`bind()`を呼ぶときにもうひとつ気をつけなければならないのは、 ポート番号で下手を打たないことです。1024以下のポートはすべて予約済みです(あなたがスーパーユーザでない限り)! それ以上のポート番号は、(他のプログラムによってすでに使われていなければ) 65535 までの任意のポート番号を使用することができます。

時々、サーバを再実行しようとすると、`bind()`が "Address already in use" と言って失敗することに気がつくかもしれません。これはどういうことでしょう? それは、接続されたソケットの一部がまだカーネル内に残っていて、ポートを占有しているのです。それが消えるのを待つか(1分くらい)、次のようにポートが再利用できるようなコードをプログラムに追加します。

```cpp
int yes=1;
//char yes='1'; // Solaris people use this

// lose the pesky "Address already in use" error message
if (setsockopt(listener,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof yes) == -1) {
    perror("setsockopt");
    exit(1);
}
```

`bind()`について、最後にちょっとした注意点があります。`bind()`を絶対に呼び出す必要がない場合があります。リモートマシンに `connect()` する際に、ローカルポートを気にしない場合 (telnet のようにリモートポートを気にする場合) は、単に `connect()` をコールすれば、ソケットが未束縛かどうかをチェックし、必要なら未使用のローカルポートに `bind()` してくれます。

### 5.4 connect()—Hey, you!
ちょっとだけ、あなたがtelnetアプリケーションであることを仮定してみましょう。ユーザが（映画 TRON のように）ソケットファイル記述子を取得するように命令します。あなたはそれに応じ、`socket()`を呼び出します。次に、ユーザはポート `23` (標準的な telnet ポート) で `10.12.110.57` に接続するように指示します。やったー! どうするんだ？

幸運なことに、あなたは今、`connect()`のセクションを読んでいるところです。だから、猛烈に読み進めよう! 時間がない!

`connect()`の呼び出しは以下の通りである。

```cpp
#include <sys/types.h>
#include <sys/socket.h>

int connect(int sockfd, struct sockaddr *serv_addr, int addrlen);
```

`sockfd`は`socket()`コールで返される、我々の身近なソケットファイル記述子、`serv_addr`は宛先ポートとIPアドレスを含む`sockaddr`構造体、`addrlen`はサーバアドレス構造体のバイト長です。

これらの情報はすべて、`getaddrinfo()`の呼び出しの結果から得ることができ、これはロックします。

だんだん分かってきたかな？ここからは聞こえないので、そうであることを祈るしかないですね。ポート3490の "www.example.com "にソケット接続する例を見てみましょう。

```cpp
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

繰り返しになりますが、古いタイプのプログラムでは、独自の `sockaddr_ins` 構造体を作成して `connect()` に渡していました。必要であれば、そうすることができます。上の [5.3 bind()—What port am I on?](#53-bind-what-port-am-i-on) の節で同様のことを書いています。

`connect()`の戻り値を必ず確認してください。エラー時に-1が返され、errnoという変数がセットされます。

また、`bind()`を呼んでいないことに注意してください。基本的に、私たちはローカルのポート番号には関心がありません。カーネルは私たちのためにローカルポートを選択し、接続先のサイトは自動的にこの情報を取得します。心配はいりません。

### 5.5 listen()—Will somebody please call me?
よし、気分転換の時間だ。リモートホストに接続したくない場合はどうすればいいのでしょう。例えば、接続が来るのを待ち、何らかの方法でそれを処理したいとします。この処理は2段階です。まず `listen()` を行い、次に `accept()` を行います (後述)。

`listen()`の呼び出しはかなり単純ですが、少し説明が必要です。

```cpp
int listen(int sockfd, int backlog);
```

`sockfd` は `socket()` システムコールから得られる通常のソケットファイル記述子です。これはどういう意味でしょうか？着信した接続は、`accept()` (後述) するまでこのキューで待機することになりますが、このキューに入れることができる数の上限を表しているのです。ほとんどのシステムでは、この数を黙って約 20 に制限しています。おそらく、5 や 10 に設定しても大丈夫でしょう。

ここでも、いつものように listen() は -1 を返し、エラー時には errno をセットします。

さて、想像がつくと思いますが、サーバが特定のポートで動作するように `listen()` を呼び出す前に `bind()` を呼び出す必要があります。(どのポートに接続するかを仲間に伝えることができなければなりません!) ですから、もし接続を待ち受けるのであれば、一連のシステムコールは次のようになります。

```cpp
getaddrinfo();
socket();
bind();
listen();
/* accept() goes here */
```

かなり自明なので、サンプルコードの代わりに置いておきます。(以下の`accept()`セクションのコードはより完全なものです。) この全体の中で本当に厄介なのは、`accept()`の呼び出しです。

### 5.6 accept()—“Thank you for calling port 3490.”
`accept()`の呼び出しはちょっと変です。これから起こることはこうです。遠く離れた誰かが、あなたが `listen()` しているポートであなたのマシンに `connect()` しようとするでしょう。その接続は、`accept()`されるのを待つためにキューに入れられることになります。あなたは `accept()` をコールし、保留中の接続を取得するように指示します。すると、この接続に使用する新しいソケットファイル記述子が返されます! そうです、1つの値段で2つのソケットファイル記述子を手に入れたことになります。元のソケットファイル記述子はまだ新しい接続を待ち続けており、新しく作成されたソケットファイル記述子はようやく `send()` と `recv()` を行う準備が整いました。着いたぞ!

通話内容は以下の通りです。

```cpp
#include <sys/types.h>
#include <sys/socket.h>

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrl
```

`sockfd`は`listen()`するソケットディスクリプタです。`addr`は通常、ローカルの構造体`sockaddr_storage`へのポインタになります。この構造体には、着信接続に関する情報が格納されます(これにより、どのホストがどのポートから電話をかけてきたかを判断することができます)。`addrlen` はローカルの整数型変数で、そのアドレスが `accept()` に渡される前に `sizeof(struct sockaddr_storage)` に設定されなければなりません。`accept()` は、`addr` にそれ以上のバイト数を入れることはありません。もし、それ以下のバイト数であれば、`addrlen` の値を変更します。

何だと思いますか？`accept()`は-1を返し、エラーが発生した場合は errno をセットします。そうだったんですか。

前回と同様、一度に吸収するのは大変なので、サンプルコードの一部をご覧ください。

```cpp
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#define MYPORT "3490"  // the port users will be connecting to
#define BACKLOG 10     // how many pending connections queue will hold

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

    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    bind(sockfd, res->ai_addr, res->ai_addrlen);
    listen(sockfd, BACKLOG);

    // now accept an incoming connection:

    addr_size = sizeof their_addr;
    new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &addr_size);

    // ready to communicate on socket descriptor new_fd!
    .
    .
    .
```

ここでも、すべての `send()` と `recv()` の呼び出しに、ソケットディスクリプタ `new_fd` を使用することに注意してください。もし、一度しか接続がないのであれば、同じポートからの接続を防ぐために、`listen` している `sockfd` を `close()` することができます。

### 5.7 send() and recv()—Talk to me, baby!
この2つの関数は、ストリームソケットまたは接続されたデータグラムソケットで通信を行うためのものです。通常の非接続型データグラムソケットを使いたい場合は、以下の [5.8 sendto() and recvfrom()—Talk to me, DGRAM-style](#58-sendto-and-recvfrom-talk-to-me-dgram-style) のセクションを参照する必要があります。

`send()`呼び出し。

```cpp
int send(int sockfd, const void *msg, int len, int flags);
```

`sockfd`はデータを送信したいソケットディスクリプタ（`socket()`で返されたものでも`accept()`で取得したものでも可）、 `msg`は送信したいデータへのポインタ、`len`はそのデータの長さ（バイト数）です。フラグを0に設定するだけです(フラグに関する詳しい情報は`send()`のマニュアルページを参照してください)。

サンプルコードとしては、以下のようなものがあります。

```cpp
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

`send()` は実際に送信されたバイト数を返しますが、これは送信するように指示した数よりも少ないかもしれません! つまり、大量のデータを送信するように指示しても、それが処理しきれないことがあるのです。その場合、できる限りのデータを送信し、残りは後で送信するように指示します。`send()` が返す値が `len` の値と一致しない場合、残りの文字列を送信するかどうかはあなた次第だということを覚えておいてください。良いニュースはこれです。パケットが小さければ(1K以下とか)、 おそらく全部を一度に送信することができるでしょう。ここでも、エラー時には -1 が返され、 errno にはエラー番号がセットされる。

`recv()`呼び出しは、多くの点で類似しています。

```cpp
int recv(int sockfd, void *buf, int len, int flags);
```

`sockfd` は読み込むソケットディスクリプタ、`buf` は情報を読み込むバッファ、`len` はバッファの最大長、`flags` は再び 0 に設定できます(フラグについては `recv()` の man ページを参照)。

`recv()` は、実際にバッファに読み込まれたバイト数を返し、エラーの場合は -1 を返します（それに応じて errno が設定されます）。

待ってください！`recv()`は0を返すことがあります。これは、リモート側が接続を切断したことを意味します! 0 という返り値は、`recv()` がこのような事態が発生したことをあなたに知らせるためのものです。

ほら、簡単だったでしょう？これでストリームソケットでデータのやり取りができるようになったぞ。やったー! あなたはUnixネットワークプログラマーです!

### 5.8 sendto() and recvfrom()—Talk to me, DGRAM-style
"これはすべて素晴らしく、ダンディーだ"、"しかし、データグラムソケットを接続しないままにしておくのはどうなんだ"、という声が聞こえてきそうです。大丈夫だ、アミーゴ。ちょうどいいものがありますよ。

データグラムソケットはリモートホストに接続されていないので、パケットを送信する前にどのような情報を与える必要があるか分かりますか？そうです! 宛先アドレスです! これがそのスクープです。

```cpp
int sendto(int sockfd, const void *msg, int len, unsigned int flags,
           const struct sockaddr *to, socklen_t tolen);
```

見ての通り、この呼び出しは基本的に`send()`の呼び出しと同じで、他に2つの情報が追加されています。`to`は`struct sockaddr`へのポインターで（おそらく直前にキャストした別の`struct sockaddr_in`や`struct sockaddr_in6`、`struct sockaddr_storage`になるでしょう）、送信先のIPアドレスとポートが含まれています。`tolen`は`int`型ですが、単純に`sizeof *to`または`sizeof(struct sockaddr_storage)`に設定することができます。

宛先アドレスの構造体を手に入れるには、`getaddrinfo()`や以下の`recvfrom()`から取得するか、手で記入することになると思います。

`send()` と同様、`sendto()` は実際に送信したバイト数 (これも、送信するように指示したバイト数よりも少ないかもしれません!) を返し、エラーの場合は -1 を返します。

同様に、`recv()`と`recvfrom()`も類似しています。`recvfrom()`の概要は以下の通りです。

```cpp
int recvfrom(int sockfd, void *buf, int len, unsigned int flags,
             struct sockaddr *from, int *fromlen);
```

これも `recv()` と同様であるが、いくつかのフィールドが追加されています。`from` はローカルの `struct sockaddr_storage` へのポインタで、送信元のマシンの IP アドレスとポートが格納されます。`fromlen` はローカルの `int` へのポインタであり、`sizeof *from` または `sizeof(struct sockaddr_storage)` に初期化する必要があります。この関数が戻ったとき、`fromlen`は実際に`from`に格納されたアドレスの長さを含みます。

`recvfrom()` は受信したバイト数を返し、エラーの場合は -1 を返します（errno はそれに応じて設定されます）。

そこで質問ですが、なぜソケットの型として `struct sockaddr_storage` を使うのでしょうか？なぜ、`struct sockaddr_in`ではないのでしょうか？なぜなら、私たちはIPv4やIPv6に縛られたくないからです。そこで、汎用的な構造体である`sockaddr_storage`を使用するのですが、これはどちらにも十分な大きさであることが分かっています。

(そこで...ここでまた疑問なのですが、なぜ `struct sockaddr` 自体はどんなアドレスに対しても十分な大きさがないのでしょうか? 汎用構造体`sockaddr_storage`を汎用構造体`sockaddr`にキャストしているくらいなのに！？余計なことをしたような気がしますね。答えは、十分な大きさがなく、この時点で変更するのは問題がある、ということでしょう。だから新しいのを作ったんだ)。

データグラムソケットを`connect()`すれば、すべてのトランザクションに`send()`と`recv()`を使用できることを覚えておいてください。ソケット自体はデータグラムソケットであり、パケットはUDPを使用しますが、ソケットインターフェイスが自動的に宛先と送信元の情報を追加してくれるのです。

### 5.9 close() and shutdown()—Get outta my face!
ふぅー 一日中データの送受信をしていて、もう限界だ。ソケットディスクリプタの接続を閉じる準備ができました。これは簡単です。通常のUnixファイルディスクリプタの`close()`関数を使えばいいのです。

```cpp
close(sockfd);
```

これにより、それ以上のソケットへの読み書きができなくなります。リモート側でソケットの読み書きをしようとすると、エラーが発生します。

ソケットの閉じ方をもう少し制御したい場合は、`shutdown()`関数を使用します。この関数では、特定の方向、あるいは両方の通信を遮断することができます (ちょうど `close()` がそうであるように)。概要:

```cpp
int shutdown(int sockfd, int how);
```

`sockfd` はシャットダウンしたいソケットファイル記述子、`how`は以下のいずれかです。

| how | Effect                                              |
|-----|-----------------------------------------------------|
| 0   | それ以上の受信は不可                                |
| 1   | それ以上の送信は禁止されています                    |
| 2   | それ以上の送受信は禁止されています(close()のような) |

`shutdown()`は成功すると0を、エラーが発生すると-1を返します（errnoは適宜設定されます）。

データグラムソケットが接続されていない状態で `shutdown()` を使用すると、それ以降の `send()` および `recv()` 呼び出しに使用できなくなります (データグラムソケットを `connect()` した場合は、これらの呼び出しが可能であることを思い出してください)。

`shutdown()` は実際にはファイルディスクリプタを閉じないことに注意することが重要です。ソケットディスクリプタを解放するには、`close()`を使用する必要があります。

何もないんだけどね。

(ただし、WindowsとWinsockを使用している場合は、`close()`ではなく`closesocket()`を呼び出すべきであることを忘れないでください)。

### 5.10 getpeername()—Who are you?
この関数はとても簡単です。

あまりに簡単なので、ほとんど独自のセクションを設けなかったほどです。でも、とりあえずここに書いておきます。

`getpeername()`関数は、接続されたストリームソケットのもう一方の端にいるのが誰であるかを教えてくれます。その概要は

```cpp
#include <sys/socket.h>

int getpeername(int sockfd, struct sockaddr *addr, int *addrlen);
```

`sockfd` は接続したストリームソケットのディスクリプタ、`addr` は接続の相手側の情報を保持する `struct sockaddr` (または `struct sockaddr_in`) へのポインタ、`addrlen` は `int` へのポインタであり、 `sizeof *addr` または `sizeof(struct sockaddr)` で初期化される必要があります。

この関数は，エラーが発生すると -1 を返し，それに応じて errno を設定します．

アドレスがわかれば、`inet_ntop()`、`getnameinfo()`、`gethostbyaddr()`を使って、より詳しい情報を表示したり取得したりすることができます。いいえ、ログイン名を取得することはできません。(OK、OK。相手のコンピュータでidentデーモンが動いていれば、可能です。しかし、これはこのドキュメントの範囲外です。詳しくは [RFC 1413](https://datatracker.ietf.org/doc/html/rfc1413) をチェックしてください)。

### 5.11 gethostname()—Who am I?
`getpeername()`よりもさらに簡単なのは、`gethostname()`という関数です。これは、あなたのプログラムが動作しているコンピュータの名前を返します。この名前は、後述の `gethostbyname()` でローカルマシンの IP アドレスを決定するために使用されます。

これ以上楽しいことはないでしょう？いくつか思いつきましたが、ソケットプログラミングには関係ないですね。とにかく、内訳はこんな感じです。

```cpp
#include <unistd.h>

int gethostname(char *hostname, size_t size);
```

引数は単純で、`hostname`はこの関数が戻ったときにホスト名を格納する文字列の配列へのポインタ、`size`はホスト名配列のバイト長である。

この関数は，正常に終了した場合は0を，エラーの場合は-1を返し，通常通りerrnoを設定します。

## 6 Client-Server Background
クライアント-サーバの世界なのだ。ネットワーク上のあらゆることが、クライアント・プロセスとサーバ・プロセスとの対話、またはその逆を扱っています。たとえば、telnetを考えてみよう。ポート23のリモートホストにtelnetで接続すると（クライアント）、そのホスト上のプログラム（telnetdと呼ばれるサーバ）が起動します。このプログラムは、送られてきたtelnet接続を処理し、ログインプロンプトを表示するなどの設定を行います。

```shell
        The Network
         +--------+
         |request |
send() ------------->  recv()
Client   |        |    Server
recv() <-------------  send()
         |response|
         +--------+
```
クライアント-サーバの相互作用

クライアントとサーバ間の情報のやりとりは、上の図のようにまとめられます。

クライアントとサーバのペアは、`SOCK_STREAM`、`SOCK_DGRAM`、その他（同じことを話している限り）何でも話すことができることに注意してください。クライアントとサーバのペアの良い例としては、telnet/telnetd、ftp/ftpd、Firefox/Apache などがあります。ftp を使うときはいつも、リモートプログラム ftpd があなたにサービスを提供します。

多くの場合、1つのマシンには1つのサーバしかなく、そのサーバは`fork()`を使用して複数のクライアントを処理します。基本的なルーチンは、サーバが接続を待ち、それを `accept()` し、それを処理するために子プロセスを `fork()` する、というものです。これが、次のセクションで紹介するサンプルサーバが行っていることです。

### 6.1 A Simple Stream Server
このサーバがすることは、ストリーム接続で "Hello, world!" という文字列を送り出すだけです。このサーバをテストするために必要なことは、あるウィンドウでこのサーバを実行し、別のウィンドウからこのサーバにtelnetでアクセスすることだけです。

```shell
$ telnet remotehostname 3490
```

ここで、remotehostname は実行するマシンの名前です。

[サーバコード](https://beej.us/guide/bgnet/examples/server.c)

```cpp
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
    int sockfd, new_fd;  // listen on sock_fd, new connection on new_fd
    struct addrinfo hints, *servinfo, *p;
    struct sockaddr_storage their_addr; // connector's address information
    socklen_t sin_size;
    struct sigaction sa;
    int yes=1;
    char s[INET6_ADDRSTRLEN];
    int rv;

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
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
        new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size);
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

一応、構文的にわかりやすいように、1つの大きな`main()`関数にまとめてあります。もし、その方が良いと思われるなら、自由に小さな関数に分割してください。

(また、この`sigaction()`全体は、あなたにとって新しいものかもしれません-それは大丈夫です。このコードは、`fork()`された子プロセスが終了するときに現れるゾンビプロセスを刈り取る役割を担っているのです。ゾンビをたくさん作ってそれを刈り取らないと、システム管理者が怒りますよ)。

このサーバからデータを取得するには、次のセクションに記載されているクライアントを使用します。

### 6.2 A Simple Stream Client
こいつはサーバよりもっと簡単です。このクライアントがすることは コマンドラインで指定したホスト、ポート3490に接続するだけです。サーバが送信する文字列を取得します。

[クライアントソース](https://beej.us/guide/bgnet/examples/client.c)。

```cpp
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

        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("client: connect");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return 2;
    }

    inet_ntop(p->ai_family, get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
    printf("client: connecting to %s\n", s);

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

クライアントを実行する前にサーバを実行しない場合、`connect()` は "Connection refused" を返すことに注意してください。非常に便利です。

### 6.3 Datagram Sockets
UDPデータグラムソケットの基本は，上記の [5.8 sendto() and recvfrom()—Talk to me, DGRAM-style](#58-sendto-and-recvfromtalk-to-me-dgram-style) ですでに説明しましたので，ここでは`talker.c`と`listener.c`という2つのサンプルプログラムのみを紹介します。

listenerは、ポート4950で入ってくるパケットを待つマシンに座っています。talkerは、指定されたマシンのそのポートに、ユーザがコマンドラインに入力したものを含むパケットを送信します。

データグラムソケットはコネクションレス型であり、パケットを無慈悲に発射するだけなので、クライアントとサーバにはIPv6を使用するように指示することにしています。こうすることで、サーバがIPv6でリッスンしていて、クライアントがIPv4で送信するような状況を避けることができます。(接続されたTCPストリームソケットの世界では、まだ不一致があるかもしれませんが、一方のアドレスファミリーの`connect()`でエラーが発生すると、他方のアドレスファミリーの再試行が行われます)。

[listener ソースコード](https://beej.us/guide/bgnet/examples/listener.c)

```cpp
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
    hints.ai_family = AF_INET6; // set to AF_INET to use IPv4
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

`getaddrinfo()`の呼び出しで、最終的に`SOCK_DGRAM`を使用していることに注意してください。また、`listen()` や `accept()` は必要ないことに注意してください。これは非接続型データグラムソケットを使用する利点の1つです!

[talker.c ソースコード](https://beej.us/guide/bgnet/examples/talker.c)

```cpp
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

#define SERVERPORT "4950"    // the port users will be connecting to

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

    if ((rv = getaddrinfo(argv[1], SERVERPORT, &hints, &servinfo)) != 0) {
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

と、これだけです! listenerをあるマシンで実行し、次にtaklerを別のマシンで実行します。彼らのコミュニケーションをご覧ください 核家族で楽しめるG級興奮体験です

今回はサーバを動かす必要もありません! talker はただ楽しくパケットをエーテルに発射し、相手側に `recvfrom()` の準備が出来ていなければ消えてしまうのです。UDP データグラムソケットを使用して送信されたデータは、到着が保証されていないことを思い出してください!

過去に何度も述べた、もうひとつの小さなディテールを除いては、コネクテッド・データグラム・ソケットです。このドキュメントのデータグラムセクションにいるので、ここでこれについて話す必要があります。例えば、話し手が`connect()`を呼び出してlistenerのアドレスを指定したとします。それ以降、talkerは`connect()`で指定されたアドレスにのみ送信と受信ができます。このため、`sendto()`と`recvfrom()`を使う必要はなく、単に`send()`と`recv()`を使えばいいのです。



# Slightly Advanced Techniques

これらは本当に高度なものではありませんが、私たちがすでにカバーしたより基本的なレベルから抜け出しているのです。実際、ここまでくれば、Unix ネットワークプログラミングの基本をかなり習得したと考えてよいでしょう! おめでとうございます!

そこで今回は、ソケットについてもっと知りたい、難解な事柄をご紹介します。どうぞお楽しみに!


## Blocking {#blocking}

ブロッキング。聞いたことはあるだろう---さて、それは一体何なのか？一言で言えば、「ブロック」は技術用語で「スリープ」のことです。上で `listener` を実行したとき、パケットが到着するまでただそこに座っていることに気づいたかもしれません。何が起こったかというと、`recvfrom()` を呼び出したのですが、データがなかったので、`recvfrom()` はデータが到着するまで "block" (つまり、そこで眠る) と言われているのです。

多くの関数がブロックします。`accept()` がブロックされます。すべての `recv()` 関数がブロックされます。このようなことができるのは、ブロックすることが許されているからです。最初に `socket()` でソケットディスクリプタを作成するとき、カーネルはそれをブロッキングに設定します。もし、ソケットをブロッキングさせたくなければ、`fcntl()` を呼び出す必要があります。

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

ソケットをノンブロッキングに設定することで、効果的にソケットの情報を "ポーリング "することができます。ノンブロッキングソケットから読み込もうとしたときに、そこにデータがない場合、ブロックすることは許されません-- `-1` を返し、 `errno` には `EAGAIN` または `EWOULDBLOCK` がセットされます。

(待てよ--`EAGAIN` や `EWOULDBLOCK` を返すこともあるのか？どちらをチェックする？仕様では実際にあなたのシステムがどちらを返すかは指定されていないので、移植性のために両方チェックしましょう)。

しかし、一般的に言って、この種のポーリングは悪い考えです。ソケットのデータを探すためにプログラムをビジーウェイト状態にすると、流行遅れのようにCPU時間を吸い取られてしまうからです。読み込み待ちのデータがあるかどうかを確認するための、よりエレガントなソリューションが、次の `poll()` のセクションで紹介されています。


## `poll()`---Synchronous I/O Multiplexing {#poll}

あなたが本当にしたいことは、一度にたくさんのソケットを監視して、データの準備ができたものを処理することです。そうすれば、どのソケットが読み込み可能かを確認するために、すべてのソケットを継続的にポーリングする必要はありません。

> 警告: `poll()` は巨大な数のコネクションを持つ場合、恐ろしく遅くなります。そのような状況では、[libevent](https://libevent.org/) のような、システムで利用可能な最も高速なメソッドを使用しようとするイベントライブラリの方が良いパフォーマンスを得ることができるでしょう。

では、どうすればポーリングを回避できるのでしょうか。少し皮肉なことに、`poll()` システムコールを使えばポーリングを避けることができます。簡単に言うと、オペレーティングシステムにすべての汚い仕事を代行してもらい、どのソケットでデータが読めるようになったかだけを知らせてもらうのです。その間、我々のプロセスはスリープして、システムリソースを節約することができます。

一般的なゲームプランは、どのソケットディスクリプタを監視したいか、どのような種類のイベントを監視したいかという情報を `struct pollfd` の配列として保持することです。OS は、これらのイベントのいずれかが発生するか (例えば "socket ready to read!") またはユーザが指定したタイムアウトが発生するまで `poll()` 呼び出しでブロックします。

便利なことに、 `listen()`ing ソケットは、新しい接続が `accept()` される準備ができたときに "ready to read" を返します。

雑談はこのくらいにして。これをどう使うか？

``` {.c}
#include <poll.h>

int poll(struct pollfd fds[], nfds_t nfds, int timeout);
```

`fds` は情報の配列 (どのソケットの何を監視するか)、 `nfds` は配列の要素数、そして `timeout` はミリ秒単位のタイムアウトである。`timeout` はミリ秒単位のタイムアウトで、イベントが発生した配列の要素数を返します。

その `struct` を見てみましょう。

``` {.c}
struct pollfd {
    int fd;         // the socket descriptor
    short events;   // bitmap of events we're interested in
    short revents;  // when poll() returns, bitmap of events that occurred
};
```

だから、その配列を用意するんです。各要素の `fd` フィールドには、監視したいソケットディスクリプタを指定します。そして、`events` フィールドには、監視するイベントの種類を指定します。

`events` フィールドは、以下の bitwise-OR です。
The `events` field is the bitwise-OR of the following:

| Macro     | Description                                                                        |
| --------- | ------------------------------------------------------------------------------     |
| `POLLIN`  | このソケットで `recv()` のためのデータが準備できたときに警告を出します。           |
| `POLLOUT` | このソケットにブロックせずにデータを `send()` できるようになったら警告を出します。 |

一旦 `struct pollfd` の配列を整えたら、それを `poll()` に渡すことができます。配列のサイズと、ミリ秒単位のタイムアウト値も一緒に渡してください。(タイムアウトに負の値を指定すると、永遠に待つことができます)。

`poll()` が返った後、 `revents` フィールドをチェックして、`POLLIN` または `POLLOUT` がセットされているかどうかで、イベントが発生したことを確認できます。

(実際には `poll()` の呼び出しでできることはもっとたくさんあります。詳細は以下の `poll()` man ページを参照してください)。

ここでは、標準入力からデータを読み込めるようになるまで、つまり `RETURN` を押したときに 2.5 秒間待つ[例](https://beej.us/guide/bgnet/examples/poll.c)を示します。

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
            printf("File descriptor %d is ready to read\n", pfds[0].fd);
        } else {
            printf("Unexpected event occurred: %d\n", pfds[0].revents);
        }
    }

    return 0;
}
```

`poll()` が `pfds` 配列の中でイベントが発生した要素の数を返していることに再び注目してください。これは配列のどの要素にイベントが発生したかを教えてくれるわけではありませんが (そのためにはまだスキャンする必要があります)、`revents` フィールドが 0 ではないエントリがいくつあるかを教えてくれます (したがって、その数がわかったらスキャンを止めることができます)。

ここで、いくつかの疑問が出てくるかもしれません。`poll()` に渡したセットに新しいファイルディスクリプタを追加するにはどうしたらいいのでしょうか？これについては、単に配列に必要なだけのスペースがあることを確認するか、必要に応じて `realloc()` でスペースを追加してください。

セットから項目を削除する場合はどうすればよいのでしょうか。この場合は、配列の最後の要素をコピーして、削除する要素の上に置くことができます。そして、その数をひとつ減らして `poll()` に渡します。もうひとつの方法として、`fd` フィールドに負の数を設定すると、`poll()` はそれを無視します。

どうすれば、`telnet` できるチャットサーバーにまとめることができるのでしょうか？

これから行うのは、リスナーソケットを起動し、それをファイルディスクリプタのセットに追加して `poll()` に送ることです。(これは、接続があったときに読み込み可能な状態を表示します)。

そして、新しい接続を `struct pollfd` 配列に追加していきます。そして、容量が足りなくなったら、動的にそれを増やしていきます。

接続が終了したら、その接続を配列から削除します。

そして、ある接続が読み取り可能になったら、そこからデータを読み取り、そのデータを他のすべての接続に送ることで、他のユーザーが入力した内容を見ることができるようにします。

そこで、[このポール・サーバー](https://beej.us/guide/bgnet/examples/pollserver.c)を試してみてください。あるウィンドウで実行し、他の多くのターミナルウィンドウから `telnet localhost 9034` を実行してみてください。一つのウィンドウで入力したものが他のウィンドウでも(RETURNを押した後で)見られるようになるはずです。

それだけでなく、`CTRL-]`を押して `quit` とタイプして `telnet` を終了すると、サーバーは切断を検出し、ファイルディスクリプタの配列からあなたを削除するはずです。

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

// Get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

// Return a listening socket
int get_listener_socket(void)
{
    int listener;     // Listening socket descriptor
    int yes=1;        // For setsockopt() SO_REUSEADDR, below
    int rv;

    struct addrinfo hints, *ai, *p;

    // Get us a socket and bind it
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0) {
        fprintf(stderr, "selectserver: %s\n", gai_strerror(rv));
        exit(1);
    }

    for(p = ai; p != NULL; p = p->ai_next) {
        listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (listener < 0) {
            continue;
        }

        // Lose the pesky "address already in use" error message
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));

        if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
            close(listener);
            continue;
        }

        break;
    }

    freeaddrinfo(ai); // All done with this

    // If we got here, it means we didn't get bound
    if (p == NULL) {
        return -1;
    }

    // Listen
    if (listen(listener, 10) == -1) {
        return -1;
    }

    return listener;
}

// Add a new file descriptor to the set
void add_to_pfds(struct pollfd *pfds[], int newfd, int *fd_count, int *fd_size)
{
    // If we don't have room, add more space in the pfds array
    if (*fd_count == *fd_size) {
        *fd_size *= 2; // Double it

        *pfds = realloc(*pfds, sizeof(**pfds) * (*fd_size));
    }

    (*pfds)[*fd_count].fd = newfd;
    (*pfds)[*fd_count].events = POLLIN; // Check ready-to-read

    (*fd_count)++;
}

// Remove an index from the set
void del_from_pfds(struct pollfd pfds[], int i, int *fd_count)
{
    // Copy the one from the end over this one
    pfds[i] = pfds[*fd_count-1];

    (*fd_count)--;
}

// Main
int main(void)
{
    int listener;     // Listening socket descriptor

    int newfd;        // Newly accept()ed socket descriptor
    struct sockaddr_storage remoteaddr; // Client address
    socklen_t addrlen;

    char buf[256];    // Buffer for client data

    char remoteIP[INET6_ADDRSTRLEN];

    // Start off with room for 5 connections
    // (We'll realloc as necessary)
    int fd_count = 0;
    int fd_size = 5;
    struct pollfd *pfds = malloc(sizeof *pfds * fd_size);

    // Set up and get a listening socket
    listener = get_listener_socket();

    if (listener == -1) {
        fprintf(stderr, "error getting listening socket\n");
        exit(1);
    }

    // Add the listener to set
    pfds[0].fd = listener;
    pfds[0].events = POLLIN; // Report ready to read on incoming connection

    fd_count = 1; // For the listener

    // Main loop
    for(;;) {
        int poll_count = poll(pfds, fd_count, -1);

        if (poll_count == -1) {
            perror("poll");
            exit(1);
        }

        // Run through the existing connections looking for data to read
        for(int i = 0; i < fd_count; i++) {

            // Check if someone's ready to read
            if (pfds[i].revents & POLLIN) { // We got one!!

                if (pfds[i].fd == listener) {
                    // If listener is ready to read, handle new connection

                    addrlen = sizeof remoteaddr;
                    newfd = accept(listener,
                        (struct sockaddr *)&remoteaddr,
                        &addrlen);

                    if (newfd == -1) {
                        perror("accept");
                    } else {
                        add_to_pfds(&pfds, newfd, &fd_count, &fd_size);

                        printf("pollserver: new connection from %s on "
                            "socket %d\n",
                            inet_ntop(remoteaddr.ss_family,
                                get_in_addr((struct sockaddr*)&remoteaddr),
                                remoteIP, INET6_ADDRSTRLEN),
                            newfd);
                    }
                } else {
                    // If not the listener, we're just a regular client
                    int nbytes = recv(pfds[i].fd, buf, sizeof buf, 0);

                    int sender_fd = pfds[i].fd;

                    if (nbytes <= 0) {
                        // Got error or connection closed by client
                        if (nbytes == 0) {
                            // Connection closed
                            printf("pollserver: socket %d hung up\n", sender_fd);
                        } else {
                            perror("recv");
                        }

                        close(pfds[i].fd); // Bye!

                        del_from_pfds(pfds, i, &fd_count);

                    } else {
                        // We got some good data from a client

                        for(int j = 0; j < fd_count; j++) {
                            // Send to everyone!
                            int dest_fd = pfds[j].fd;

                            // Except the listener and ourselves
                            if (dest_fd != listener && dest_fd != sender_fd) {
                                if (send(dest_fd, buf, nbytes, 0) == -1) {
                                    perror("send");
                                }
                            }
                        }
                    }
                } // END handle data from client
            } // END got ready-to-read from poll()
        } // END looping through file descriptors
    } // END for(;;)--and you thought it would never end!

    return 0;
}
```

次のセクションでは、似たような古い関数である `select()` について見ていきます。`select()` と `poll()` はどちらも似たような機能とパフォーマンスを持っており、どのように使うかが違うだけです。`select()` の方が若干移植性が高いかもしれませんが、使い勝手は少し悪いかもしれません。あなたのシステムでサポートされている限り、一番好きなものを選んでください。


## `select()`---Synchronous I/O Multiplexing, Old School {#select}

この機能、ちょっと不思議なんですが、とても便利なんです。次のような状況を考えてみましょう。あなたはサーバーで、入ってくるコネクションをリッスンするだけでなく、すでに持っているコネクションを読み続けたいのです。

問題ありません。`accept()` と `recv()` を数回実行するだけです。そうはいかないよ、バスター! もし `accept()` の呼び出しがブロックされていたらどうでしょう? どうやって `recv()` を同時に行うんだ？"ノンブロッキングソケットを使いましょう!" まさか! CPUを占有するようなことはしない方がいい。じゃあ、何？

`select()` は同時に複数のソケットを監視する力を与えてくれます。どのソケットが読み込み可能で、どのソケットが書き込み可能か、そしてどのソケットが例外を発生させたか、本当に知りたければ教えてくれるでしょう。

> 警告: `select()` は非常にポータブルですが、巨大な数の接続が発生すると、恐ろしく遅くなります。このような状況では、[libevent](https://libevent.org/) のような、システムで利用可能な最も高速なメソッドを使おうとするイベントライブラリの方が良いパフォーマンスを得ることができるでしょう。

さっそくですが、`select()` の概要を説明します。

```{.c}
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

int select(int numfds, fd_set *readfds, fd_set *writefds,
           fd_set *exceptfds, struct timeval *timeout);
```

The function monitors "sets" of file descriptors; in particular
`readfds`, `writefds`, and `exceptfds`. If you want to see if you can
read from standard input and some socket descriptor, `sockfd`, just add
the file descriptors `0` and `sockfd` to the set `readfds`. The
parameter `numfds` should be set to the values of the highest file
descriptor plus one. In this example, it should be set to `sockfd+1`,
since it is assuredly higher than standard input (`0`).

When `select()` returns, `readfds` will be modified to reflect which of
the file descriptors you selected which is ready for reading. You can
test them with the macro `FD_ISSET()`, below.

Before progressing much further, I'll talk about how to manipulate these
sets.  Each set is of the type `fd_set`. The following macros operate on
this type:

[ixtt[FD\_SET()]] [ixtt[FD\_CLR()]] [ixtt[FD\_ISSET()]] [ixtt[FD\_ZERO()]]

| Function                         | Description                          |
| -------------------------------- | ------------------------------------ |
| `FD_SET(int fd, fd_set *set);`   | Add `fd` to the `set`.               |
| `FD_CLR(int fd, fd_set *set);`   | Remove `fd` from the `set`.          |
| `FD_ISSET(int fd, fd_set *set);` | Return true if `fd` is in the `set`. |
| `FD_ZERO(fd_set *set);`          | Clear all entries from the `set`.    |

Finally, what is this weirded out [ixtt[struct timeval]] `struct
timeval`? Well, sometimes you don't want to wait forever for someone to
send you some data. Maybe every 96 seconds you want to print "Still
Going..." to the terminal even though nothing has happened. This time
structure allows you to specify a timeout period. If the time is
exceeded and `select()` still hasn't found any ready file descriptors,
it'll return so you can continue processing.

The `struct timeval` has the follow fields:

```{.c}
struct timeval {
    int tv_sec;     // seconds
    int tv_usec;    // microseconds
}; 
```

Just set `tv_sec` to the number of seconds to wait, and set `tv_usec` to
the number of microseconds to wait. Yes, that's _micro_seconds, not
milliseconds.  There are 1,000 microseconds in a millisecond, and 1,000
milliseconds in a second. Thus, there are 1,000,000 microseconds in a
second. Why is it "usec"?  The "u" is supposed to look like the Greek
letter μ (Mu) that we use for "micro". Also, when the function returns,
`timeout` _might_ be updated to show the time still remaining. This
depends on what flavor of Unix you're running.

Yay! We have a microsecond resolution timer! Well, don't count on it.
You'll probably have to wait some part of your standard Unix timeslice
no matter how small you set your `struct timeval`.

Other things of interest:  If you set the fields in your `struct
timeval` to `0`, `select()` will timeout immediately, effectively
polling all the file descriptors in your sets. If you set the parameter
`timeout` to NULL, it will never timeout, and will wait until the first
file descriptor is ready. Finally, if you don't care about waiting for a
certain set, you can just set it to NULL in the call to `select()`.

[flx[The following code snippet|select.c]] waits 2.5 seconds for
something to appear on standard input:

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

If you're on a line buffered terminal, the key you hit should be RETURN
or it will time out anyway.

Now, some of you might think this is a great way to wait for data on a
datagram socket---and you are right: it _might_ be. Some Unices can use
select in this manner, and some can't. You should see what your local
man page says on the matter if you want to attempt it.

Some Unices update the time in your `struct timeval` to reflect the
amount of time still remaining before a timeout. But others do not.
Don't rely on that occurring if you want to be portable. (Use
[ixtt[gettimeofday()]] `gettimeofday()` if you need to track time
elapsed. It's a bummer, I know, but that's the way it is.)

What happens if a socket in the read set closes the connection? Well, in
that case, `select()` returns with that socket descriptor set as "ready
to read".  When you actually do `recv()` from it, `recv()` will return
`0`. That's how you know the client has closed the connection.

One more note of interest about `select()`: if you have a socket that is
[ix[select()@\texttt{select()}!with listen()@with \texttt{listen()}]]
[ix[listen()@\texttt{listen()}!with select()@with \texttt{select()}]]
`listen()`ing, you can check to see if there is a new connection by
putting that socket's file descriptor in the `readfds` set.

And that, my friends, is a quick overview of the almighty `select()`
function.

But, by popular demand, here is an in-depth example. Unfortunately, the
difference between the dirt-simple example, above, and this one here is
significant. But have a look, then read the description that follows it.

[flx[This program|selectserver.c]] acts like a simple multi-user chat
server. Start it running in one window, then `telnet` to it ("`telnet
hostname 9034`") from multiple other windows. When you type something in
one `telnet` session, it should appear in all the others.

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
    fd_set master;    // master file descriptor list
    fd_set read_fds;  // temp file descriptor list for select()
    int fdmax;        // maximum file descriptor number

    int listener;     // listening socket descriptor
    int newfd;        // newly accept()ed socket descriptor
    struct sockaddr_storage remoteaddr; // client address
    socklen_t addrlen;

    char buf[256];    // buffer for client data
    int nbytes;

    char remoteIP[INET6_ADDRSTRLEN];

    int yes=1;        // for setsockopt() SO_REUSEADDR, below
    int i, j, rv;

    struct addrinfo hints, *ai, *p;

    FD_ZERO(&master);    // clear the master and temp sets
    FD_ZERO(&read_fds);

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
        listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (listener < 0) { 
            continue;
        }
        
        // lose the pesky "address already in use" error message
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));

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

        // run through the existing connections looking for data to read
        for(i = 0; i <= fdmax; i++) {
            if (FD_ISSET(i, &read_fds)) { // we got one!!
                if (i == listener) {
                    // handle new connections
                    addrlen = sizeof remoteaddr;
                    newfd = accept(listener,
                        (struct sockaddr *)&remoteaddr,
                        &addrlen);

                    if (newfd == -1) {
                        perror("accept");
                    } else {
                        FD_SET(newfd, &master); // add to master set
                        if (newfd > fdmax) {    // keep track of the max
                            fdmax = newfd;
                        }
                        printf("selectserver: new connection from %s on "
                            "socket %d\n",
                            inet_ntop(remoteaddr.ss_family,
                                get_in_addr((struct sockaddr*)&remoteaddr),
                                remoteIP, INET6_ADDRSTRLEN),
                            newfd);
                    }
                } else {
                    // handle data from a client
                    if ((nbytes = recv(i, buf, sizeof buf, 0)) <= 0) {
                        // got error or connection closed by client
                        if (nbytes == 0) {
                            // connection closed
                            printf("selectserver: socket %d hung up\n", i);
                        } else {
                            perror("recv");
                        }
                        close(i); // bye!
                        FD_CLR(i, &master); // remove from master set
                    } else {
                        // we got some data from a client
                        for(j = 0; j <= fdmax; j++) {
                            // send to everyone!
                            if (FD_ISSET(j, &master)) {
                                // except the listener and ourselves
                                if (j != listener && j != i) {
                                    if (send(j, buf, nbytes, 0) == -1) {
                                        perror("send");
                                    }
                                }
                            }
                        }
                    }
                } // END handle data from client
            } // END got new incoming connection
        } // END looping through file descriptors
    } // END for(;;)--and you thought it would never end!
    
    return 0;
}
```

Notice I have two file descriptor sets in the code: `master` and
`read_fds`. The first, `master`, holds all the socket descriptors that
are currently connected, as well as the socket descriptor that is
listening for new connections.

The reason I have the `master` set is that `select()` actually _changes_
the set you pass into it to reflect which sockets are ready to read.
Since I have to keep track of the connections from one call of
`select()` to the next, I must store these safely away somewhere. At the
last minute, I copy the `master` into the `read_fds`, and then call
`select()`.

But doesn't this mean that every time I get a new connection, I have to
add it to the `master` set? Yup! And every time a connection closes, I
have to remove it from the `master` set? Yes, it does.

Notice I check to see when the `listener` socket is ready to read. When
it is, it means I have a new connection pending, and I `accept()` it and
add it to the `master` set. Similarly, when a client connection is ready
to read, and `recv()` returns `0`, I know the client has closed the
connection, and I must remove it from the `master` set.

If the client `recv()` returns non-zero, though, I know some data has
been received. So I get it, and then go through the `master` list and
send that data to all the rest of the connected clients.

And that, my friends, is a less-than-simple overview of the almighty
`select()` function.

Quick note to all you Linux fans out there: sometimes, in rare
circumstances, Linux's `select()` can return "ready-to-read" and then
not actually be ready to read! This means it will block on the `read()`
after the `select()` says it won't! Why you little---! Anyway, the
workaround solution is to set the [ixtt[O\_NONBLOCK]] `O_NONBLOCK` flag
on the receiving socket so it errors with `EWOULDBLOCK` (which you can
just safely ignore if it occurs). See the [`fcntl()` reference
page](#fcntlman) for more info on setting a socket to non-blocking.

In addition, here is a bonus afterthought: there is another function
called [ixtt[poll()]] `poll()` which behaves much the same way
`select()` does, but with a different system for managing the file
descriptor sets. [Check it out!](#pollman)


## Handling Partial `send()`s {#sendall}

Remember back in the [section about `send()`](#sendrecv), above, when I
said that `send()` might not send all the bytes you asked it to? That
is, you want it to send 512 bytes, but it returns 412. What happened to
the remaining 100 bytes?

Well, they're still in your little buffer waiting to be sent out. Due to
circumstances beyond your control, the kernel decided not to send all
the data out in one chunk, and now, my friend, it's up to you to get the
data out there.

[ixtt[sendall()]] You could write a function like this to do it, too:

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

In this example, `s` is the socket you want to send the data to, `buf`
is the buffer containing the data, and `len` is a pointer to an `int`
containing the number of bytes in the buffer.

The function returns `-1` on error (and `errno` is still set from the
call to `send()`). Also, the number of bytes actually sent is returned
in `len`. This will be the same number of bytes you asked it to send,
unless there was an error. `sendall()` will do it's best, huffing and
puffing, to send the data out, but if there's an error, it gets back to
you right away.

For completeness, here's a sample call to the function:

```{.c .numberLines}
char buf[10] = "Beej!";
int len;

len = strlen(buf);
if (sendall(s, buf, &len) == -1) {
    perror("sendall");
    printf("We only sent %d bytes because of the error!\n", len);
} 
```

What happens on the receiver's end when part of a packet arrives? If the
packets are variable length, how does the receiver know when one packet
ends and another begins? Yes, real-world scenarios are a royal pain in
the [ix[donkeys]] donkeys. You probably have to [ix[data encapsulation]]
_encapsulate_ (remember that from the [data encapsulation
section](#lowlevel) way back there at the beginning?)  Read on for
details!


## Serialization---How to Pack Data {#serialization}

[ix[serialization]] It's easy enough to send text data across the
network, you're finding, but what happens if you want to send some
"binary" data like `int`s or `float`s? It turns out you have a few
options.

1. Convert the number into text with a function like `sprintf()`, then
   send the text. The receiver will parse the text back into a number
   using a function like `strtol()`.

2. Just send the data raw, passing a pointer to the data to `send()`.

3. Encode the number into a portable binary form. The receiver will
   decode it.

Sneak preview! Tonight only!

[_Curtain raises_]

Beej says, "I prefer Method Three, above!"

[_THE END_]

(Before I begin this section in earnest, I should tell you that there
are libraries out there for doing this, and rolling your own and
remaining portable and error-free is quite a challenge. So hunt around
and do your homework before deciding to implement this stuff yourself. I
include the information here for those curious about how things like
this work.)

Actually all the methods, above, have their drawbacks and advantages,
but, like I said, in general, I prefer the third method. First, though,
let's talk about some of the drawbacks and advantages to the other two.

The first method, encoding the numbers as text before sending, has the
advantage that you can easily print and read the data that's coming over
the wire.  Sometimes a human-readable protocol is excellent to use in a
non-bandwidth-intensive situation, such as with [ix[IRC]] [fl[Internet
Relay Chat (IRC)|https://en.wikipedia.org/wiki/Internet_Relay_Chat]].
However, it has the disadvantage that it is slow to convert, and the
results almost always take up more space than the original number!

Method two: passing the raw data. This one is quite easy (but
dangerous!): just take a pointer to the data to send, and call send with
it.

```{.c}
double d = 3490.15926535;

send(s, &d, sizeof d, 0);  /* DANGER--non-portable! */
```

The receiver gets it like this:

```{.c}
double d;

recv(s, &d, sizeof d, 0);  /* DANGER--non-portable! */
```

Fast, simple---what's not to like? Well, it turns out that not all
architectures represent a `double` (or `int` for that matter) with the
same bit representation or even the same byte ordering! The code is
decidedly non-portable. (Hey---maybe you don't need portability, in
which case this is nice and fast.)

When packing integer types, we've already seen how the [ixtt[htons()]]
`htons()`-class of functions can help keep things portable by
transforming the numbers into [ix[byte ordering]] Network Byte Order,
and how that's the Right Thing to do. Unfortunately, there are no
similar functions for `float` types. Is all hope lost?

Fear not! (Were you afraid there for a second? No? Not even a little
bit?) There is something we can do: we can pack (or "marshal", or
"serialize", or one of a thousand million other names) the data into a
known binary format that the receiver can unpack on the remote side.

What do I mean by "known binary format"? Well, we've already seen the
`htons()` example, right? It changes (or "encodes", if you want to think
of it that way) a number from whatever the host format is into Network
Byte Order. To reverse (unencode) the number, the receiver calls
`ntohs()`.

But didn't I just get finished saying there wasn't any such function for
other non-integer types? Yes. I did. And since there's no standard way
in C to do this, it's a bit of a pickle (that a gratuitous pun there for
you Python fans).

The thing to do is to pack the data into a known format and send that
over the wire for decoding. For example, to pack `float`s, here's
[flx[something quick and dirty with plenty of room for
improvement|pack.c]]:

```{.c .numberLines}
#include <stdint.h>

uint32_t htonf(float f)
{
    uint32_t p;
    uint32_t sign;

    if (f < 0) { sign = 1; f = -f; }
    else { sign = 0; }
        
    p = ((((uint32_t)f)&0x7fff)<<16) | (sign<<31); // whole part and sign
    p |= (uint32_t)(((f - (int)f) * 65536.0f))&0xffff; // fraction

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

The above code is sort of a naive implementation that stores a `float`
in a 32-bit number. The high bit (31) is used to store the sign of the
number ("1" means negative), and the next seven bits (30-16) are used to
store the whole number portion of the `float`. Finally, the remaining
bits (15-0) are used to store the fractional portion of the number.

Usage is fairly straightforward:

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

On the plus side, it's small, simple, and fast. On the minus side, it's
not an efficient use of space and the range is severely restricted---try
storing a number greater-than 32767 in there and it won't be very happy!
You can also see in the above example that the last couple decimal
places are not correctly preserved.

What can we do instead? Well, _The_ Standard for storing floating point
numbers is known as [ix[IEEE-754]]
[fl[IEEE-754|https://en.wikipedia.org/wiki/IEEE_754]].  Most computers
use this format internally for doing floating point math, so in those
cases, strictly speaking, conversion wouldn't need to be done. But if
you want your source code to be portable, that's an assumption you can't
necessarily make. (On the other hand, if you want things to be fast, you
should optimize this out on platforms that don't need to do it! That's
what `htons()` and its ilk do.)

[flx[Here's some code that encodes floats and doubles into IEEE-754
format|ieee754.c]].  (Mostly---it doesn't encode NaN or Infinity, but it
could be modified to do that.)

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
    unsigned significandbits = bits - expbits - 1; // -1 for sign bit

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
    unsigned significandbits = bits - expbits - 1; // -1 for sign bit

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

I put some handy macros up there at the top for packing and unpacking
32-bit (probably a `float`) and 64-bit (probably a `double`) numbers,
but the `pack754()` function could be called directly and told to encode
`bits`-worth of data (`expbits` of which are reserved for the normalized
number's exponent).

Here's sample usage:

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


The above code produces this output:

```
float before : 3.1415925
float encoded: 0x40490FDA
float after  : 3.1415925

double before : 3.14159265358979311600
double encoded: 0x400921FB54442D18
double after  : 3.14159265358979311600
```

Another question you might have is how do you pack `struct`s?
Unfortunately for you, the compiler is free to put padding all over the
place in a `struct`, and that means you can't portably send the whole
thing over the wire in one chunk.  (Aren't you getting sick of hearing
"can't do this", "can't do that"? Sorry! To quote a friend, "Whenever
anything goes wrong, I always blame Microsoft."  This one might not be
Microsoft's fault, admittedly, but my friend's statement is completely
true.)

Back to it: the best way to send the `struct` over the wire is to pack
each field independently and then unpack them into the `struct` when
they arrive on the other side.

That's a lot of work, is what you're thinking. Yes, it is. One thing you
can do is write a helper function to help pack the data for you. It'll
be fun! Really!

In the book [flr[_The Practice of Programming_|tpop]] by Kernighan and
Pike, they implement `printf()`-like functions called `pack()` and
`unpack()` that do exactly this. I'd link to them, but apparently those
functions aren't online with the rest of the source from the book.

(The Practice of Programming is an excellent read. Zeus saves a kitten
every time I recommend it.)

At this point, I'm going to drop a pointer to a [fl[Protocol Buffers
implementation in C|https://github.com/protobuf-c/protobuf-c]] which
I've never used, but looks completely respectable. Python and Perl
programmers will want to check out their language's `pack()` and
`unpack()` functions for accomplishing the same thing. And Java has a
big-ol' Serializable interface that can be used in a similar way.

But if you want to write your own packing utility in C, K&P's trick is
to use variable argument lists to make `printf()`-like functions to
build the packets.  [flx[Here's a version I cooked up|pack2.c]] on my
own based on that which hopefully will be enough to give you an idea of
how such a thing can work.

(This code references the `pack754()` functions, above. The `packi*()`
functions operate like the familiar `htons()` family, except they pack
into a `char` array instead of another integer.)

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
** unpacki16() -- unpack a 16-bit int from a char buffer (like ntohs())
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
** unpacku16() -- unpack a 16-bit unsigned from a char buffer (like ntohs())
*/ 
unsigned int unpacku16(unsigned char *buf)
{
    return ((unsigned int)buf[0]<<8) | buf[1];
}

/*
** unpacki32() -- unpack a 32-bit int from a char buffer (like ntohl())
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
** unpacku32() -- unpack a 32-bit unsigned from a char buffer (like ntohl())
*/ 
unsigned long int unpacku32(unsigned char *buf)
{
    return ((unsigned long int)buf[0]<<24) |
           ((unsigned long int)buf[1]<<16) |
           ((unsigned long int)buf[2]<<8)  |
           buf[3];
}

/*
** unpacki64() -- unpack a 64-bit int from a char buffer (like ntohl())
*/ 
long long int unpacki64(unsigned char *buf)
{
    unsigned long long int i2 = ((unsigned long long int)buf[0]<<56) |
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
** unpacku64() -- unpack a 64-bit unsigned from a char buffer (like ntohl())
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
** unpack() -- unpack data dictated by the format string into the buffer
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
            if (maxstrlen > 0 && len >= maxstrlen) count = maxstrlen - 1;
            else count = len;
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

And [flx[here is a demonstration program|pack2.c]] of the above code
that packs some data into `buf` and then unpacks it into variables. Note
that when calling `unpack()` with a string argument (format specifier
"`s`"), it's wise to put a maximum length count in front of it to
prevent a buffer overrun, e.g. "`96s`". Be wary when unpacking data you
get over the network---a malicious user might send badly-constructed
packets in an effort to attack your system!

```{.c .numberLines}
#include <stdio.h>

// various bits for floating point types--
// varies for different architectures
typedef float float32_t;
typedef double float64_t;

int main(void)
{
    unsigned char buf[1024];
    int8_t magic;
    int16_t monkeycount;
    int32_t altitude;
    float32_t absurdityfactor;
    char *s = "Great unmitigated Zot! You've found the Runestaff!";
    char s2[96];
    int16_t packetsize, ps2;

    packetsize = pack(buf, "chhlsf", (int8_t)'B', (int16_t)0, (int16_t)37, 
            (int32_t)-5, s, (float32_t)-3490.6677);
    packi16(buf+1, packetsize); // store packet size in packet for kicks

    printf("packet is %" PRId32 " bytes\n", packetsize);

    unpack(buf, "chhl96sf", &magic, &ps2, &monkeycount, &altitude, s2,
        &absurdityfactor);

    printf("'%c' %" PRId32" %" PRId16 " %" PRId32
            " \"%s\" %f\n", magic, ps2, monkeycount,
            altitude, s2, absurdityfactor);

    return 0;
}
```

Whether you roll your own code or use someone else's, it's a good idea
to have a general set of data packing routines for the sake of keeping
bugs in check, rather than packing each bit by hand each time.

When packing the data, what's a good format to use? Excellent question.
Fortunately, [ix[XDR]] [flrfc[RFC 4506|4506]], the External Data
Representation Standard, already defines binary formats for a bunch of
different types, like floating point types, integer types, arrays, raw
data, etc. I suggest conforming to that if you're going to roll the data
yourself. But you're not obligated to. The Packet Police are not right
outside your door. At least, I don't _think_ they are.

In any case, encoding the data somehow or another before you send it is
the right way of doing things!


## Son of Data Encapsulation {#sonofdataencap}

What does it really mean to encapsulate data, anyway? In the simplest
case, it means you'll stick a header on there with either some
identifying information or a packet length, or both.

What should your header look like? Well, it's just some binary data that
represents whatever you feel is necessary to complete your project.

Wow. That's vague.

Okay. For instance, let's say you have a multi-user chat program that
uses `SOCK_STREAM`s. When a user types ("says") something, two pieces of
information need to be transmitted to the server: what was said and who
said it.

So far so good? "What's the problem?" you're asking.

The problem is that the messages can be of varying lengths. One person
named "tom" might say, "Hi", and another person named "Benjamin" might
say, "Hey guys what is up?"

So you `send()` all this stuff to the clients as it comes in. Your
outgoing data stream looks like this:

```
t o m H i B e n j a m i n H e y g u y s w h a t i s u p ?
```

And so on. How does the client know when one message starts and another
stops?  You could, if you wanted, make all messages the same length and
just call the [ixtt[sendall()]] `sendall()` we implemented,
[above](#sendall). But that wastes bandwidth! We don't want to `send()`
1024 bytes just so "tom" can say "Hi".

So we _encapsulate_ the data in a tiny header and packet structure. Both
the client and server know how to pack and unpack (sometimes referred to
as "marshal" and "unmarshal") this data. Don't look now, but we're
starting to define a _protocol_ that describes how a client and server
communicate!

In this case, let's assume the user name is a fixed length of 8
characters, padded with `'\0'`. And then let's assume the data is
variable length, up to a maximum of 128 characters. Let's have a look a
sample packet structure that we might use in this situation:

1. `len` (1 byte, unsigned)---The total length of the packet, counting
    the 8-byte user name and chat data.

2. `name` (8 bytes)---The user's name, NUL-padded if necessary.

3. `chatdata` (_n_-bytes)---The data itself, no more than 128 bytes. The
   length of the packet should be calculated as the length of this data
   plus 8 (the length of the name field, above).

Why did I choose the 8-byte and 128-byte limits for the fields? I pulled
them out of the air, assuming they'd be long enough. Maybe, though, 8
bytes is too restrictive for your needs, and you can have a 30-byte name
field, or whatever.  The choice is up to you.

Using the above packet definition, the first packet would consist of the
following information (in hex and ASCII):

```
   0A     74 6F 6D 00 00 00 00 00      48 69
(length)  T  o  m    (padding)         H  i
```

And the second is similar:

```
   18     42 65 6E 6A 61 6D 69 6E      48 65 79 20 67 75 79 73 20 77 ...
(length)  B  e  n  j  a  m  i  n       H  e  y     g  u  y  s     w  ...
```

(The length is stored in Network Byte Order, of course. In this case,
it's only one byte so it doesn't matter, but generally speaking you'll
want all your binary integers to be stored in Network Byte Order in your
packets.)

When you're sending this data, you should be safe and use a command
similar to [`sendall()`](#sendall), above, so you know all the data is
sent, even if it takes multiple calls to `send()` to get it all out.

Likewise, when you're receiving this data, you need to do a bit of extra
work.  To be safe, you should assume that you might receive a partial
packet (like maybe we receive "`18 42 65 6E 6A`" from Benjamin, above,
but that's all we get in this call to `recv()`). We need to call
`recv()` over and over again until the packet is completely received.

But how? Well, we know the number of bytes we need to receive in total
for the packet to be complete, since that number is tacked on the front
of the packet.  We also know the maximum packet size is 1+8+128, or 137
bytes (because that's how we defined the packet).

There are actually a couple things you can do here. Since you know every
packet starts off with a length, you can call `recv()` just to get the
packet length.  Then once you have that, you can call it again
specifying exactly the remaining length of the packet (possibly
repeatedly to get all the data) until you have the complete packet. The
advantage of this method is that you only need a buffer large enough for
one packet, while the disadvantage is that you need to call `recv()` at
least twice to get all the data.

Another option is just to call `recv()` and say the amount you're
willing to receive is the maximum number of bytes in a packet. Then
whatever you get, stick it onto the back of a buffer, and finally check
to see if the packet is complete. Of course, you might get some of the
next packet, so you'll need to have room for that.

What you can do is declare an array big enough for two packets. This is
your work array where you will reconstruct packets as they arrive.

Every time you `recv()` data, you'll append it into the work buffer and
check to see if the packet is complete. That is, the number of bytes in
the buffer is greater than or equal to the length specified in the
header (+1, because the length in the header doesn't include the byte
for the length itself). If the number of bytes in the buffer is less
than 1, the packet is not complete, obviously. You have to make a
special case for this, though, since the first byte is garbage and you
can't rely on it for the correct packet length.

Once the packet is complete, you can do with it what you will. Use it,
and remove it from your work buffer.

Whew! Are you juggling that in your head yet? Well, here's the second of
the one-two punch: you might have read past the end of one packet and
onto the next in a single `recv()` call. That is, you have a work buffer
with one complete packet, and an incomplete part of the next packet!
Bloody heck. (But this is why you made your work buffer large enough to
hold _two_ packets---in case this happened!)

Since you know the length of the first packet from the header, and
you've been keeping track of the number of bytes in the work buffer, you
can subtract and calculate how many of the bytes in the work buffer
belong to the second (incomplete) packet. When you've handled the first
one, you can clear it out of the work buffer and move the partial second
packet down the to front of the buffer so it's all ready to go for the
next `recv()`.

(Some of you readers will note that actually moving the partial second
packet to the beginning of the work buffer takes time, and the program
can be coded to not require this by using a circular buffer.
Unfortunately for the rest of you, a discussion on circular buffers is
beyond the scope of this article. If you're still curious, grab a data
structures book and go from there.)

I never said it was easy. Ok, I did say it was easy. And it is; you just
need practice and pretty soon it'll come to you naturally. By
[ix[Excalibur]] Excalibur I swear it!


## Broadcast Packets---Hello, World!

So far, this guide has talked about sending data from one host to one
other host. But it is possible, I insist, that you can, with the proper
authority, send data to multiple hosts _at the same time_!

With [ix[UDP]] UDP (only UDP, not TCP) and standard IPv4, this is done
through a mechanism called [ix[broadcast]] _broadcasting_. With IPv6,
broadcasting isn't supported, and you have to resort to the often
superior technique of _multicasting_, which, sadly I won't be discussing
at this time. But enough of the starry-eyed future---we're stuck in the
32-bit present.

But wait! You can't just run off and start broadcasting willy-nilly; You
have to [ixtt[setsockopt()]] set the socket option [ixtt[SO\_BROADCAST]]
`SO_BROADCAST` before you can send a broadcast packet out on the
network. It's like a one of those little plastic covers they put over
the missile launch switch! That's just how much power you hold in your
hands!

But seriously, though, there is a danger to using broadcast packets, and
that is: every system that receives a broadcast packet must undo all the
onion-skin layers of data encapsulation until it finds out what port the
data is destined to. And then it hands the data over or discards it. In
either case, it's a lot of work for each machine that receives the
broadcast packet, and since it is all of them on the local network, that
could be a lot of machines doing a lot of unnecessary work. When the
game Doom first came out, this was a complaint about its network code.

Now, there is more than one way to skin a cat... wait a minute. Is there
really more than one way to skin a cat? What kind of expression is that?
Uh, and likewise, there is more than one way to send a broadcast packet.
So, to get to the meat and potatoes of the whole thing: how do you
specify the destination address for a broadcast message? There are two
common ways:

1. Send the data to a specific subnet's broadcast address. This is the
   subnet's network number with all one-bits set for the host portion of
   the address. For instance, at home my network is `192.168.1.0`, my
   netmask is `255.255.255.0`, so the last byte of the address is my
   host number (because the first three bytes, according to the netmask,
   are the network number). So my broadcast address is `192.168.1.255`.
   Under Unix, the `ifconfig` command will actually give you all this
   data. (If you're curious, the bitwise logic to get your broadcast
   address is `network_number` OR (NOT `netmask`).) You can send this
   type of broadcast packet to remote networks as well as your local
   network, but you run the risk of the packet being dropped by the
   destination's router.  (If they didn't drop it, then some random
   smurf could start flooding their LAN with broadcast traffic.)

2. Send the data to the "global" broadcast address. This is
   [ix[255.255.255.255]] `255.255.255.255`, aka
   [ixtt[INADDR\_BROADCAST]] `INADDR_BROADCAST`. Many machines will
   automatically bitwise AND this with your network number to convert it
   to a network broadcast address, but some won't. It varies. Routers do
   not forward this type of broadcast packet off your local network,
   ironically enough.

So what happens if you try to send data on the broadcast address without
first setting the `SO_BROADCAST` socket option? Well, let's fire up good
old [`talker` and `listener`](#datagram) and see what happens.

```
$ talker 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ talker 192.168.1.255 foo
sendto: Permission denied
$ talker 255.255.255.255 foo
sendto: Permission denied
```

Yes, it's not happy at all...because we didn't set the `SO_BROADCAST`
socket option. Do that, and now you can `sendto()` anywhere you want!

In fact, that's the _only difference_ between a UDP application that can
broadcast and one that can't. So let's take the old `talker` application
and add one section that sets the `SO_BROADCAST` socket option. We'll
call this program [flx[`broadcaster.c`|broadcaster.c]]:

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

#define SERVERPORT 4950 // the port users will be connecting to

int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in their_addr; // connector's address information
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

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
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
    their_addr.sin_port = htons(SERVERPORT); // short, network byte order
    their_addr.sin_addr = *((struct in_addr *)he->h_addr);
    memset(their_addr.sin_zero, '\0', sizeof their_addr.sin_zero);

    if ((numbytes=sendto(sockfd, argv[2], strlen(argv[2]), 0,
             (struct sockaddr *)&their_addr, sizeof their_addr)) == -1) {
        perror("sendto");
        exit(1);
    }

    printf("sent %d bytes to %s\n", numbytes,
        inet_ntoa(their_addr.sin_addr));

    close(sockfd);

    return 0;
}
```

What's different between this and a "normal" UDP client/server
situation?  Nothing! (With the exception of the client being allowed to
send broadcast packets in this case.) As such, go ahead and run the old
UDP [`listener`](#datagram) program in one window, and `broadcaster` in
another. You should be now be able to do all those sends that failed,
above.

```
$ broadcaster 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ broadcaster 192.168.1.255 foo
sent 3 bytes to 192.168.1.255
$ broadcaster 255.255.255.255 foo
sent 3 bytes to 255.255.255.255
```

And you should see `listener` responding that it got the packets. (If
`listener` doesn't respond, it could be because it's bound to an IPv6
address. Try changing the `AF_UNSPEC` in `listener.c` to `AF_INET` to
force IPv4.)

Well, that's kind of exciting. But now fire up `listener` on another
machine next to you on the same network so that you have two copies
going, one on each machine, and run `broadcaster` again with your
broadcast address... Hey! Both `listener`s get the packet even though
you only called `sendto()` once! Cool!

If the `listener` gets data you send directly to it, but not data on the
broadcast address, it could be that you have a [ix[firewall]] firewall
on your local machine that is blocking the packets. (Yes, [ix[Pat]] Pat
and [ix[Bapper]] Bapper, thank you for realizing before I did that this
is why my sample code wasn't working. I told you I'd mention you in the
guide, and here you are. So _nyah_.)

Again, be careful with broadcast packets. Since every machine on the LAN
will be forced to deal with the packet whether it `recvfrom()`s it or
not, it can present quite a load to the entire computing network. They
are definitely to be used sparingly and appropriately.


# Common Questions

**Where can I get those header files?**

[ix[header files]] If you don't have them on your system already, you
probably don't need them. Check the manual for your particular platform.
If you're building for [ix[Windows]] Windows, you only need to `#include
<winsock.h>`.

**What do I do when `bind()` reports [ix[Address already in use]]
"Address already in use"?**

You have to use [ixtt[setsockopt()]] `setsockopt()` with the
[ixtt[SO\_REUSEADDR]] `SO_REUSEADDR` option on the listening socket.
Check out the [ixtt[bind()]] [section on `bind()`](#bind) and the
[ixtt[select()]] [section on `select()`](#select) for an example.

**How do I get a list of open sockets on the system?**

Use the [ix[netstat]] `netstat`. Check the `man` page for full details,
but you should get some good output just typing:

```
$ netstat
```

The only trick is determining which socket is associated with which
program.  `:-)`

**How can I view the routing table?**

Run the [ix[route]] `route` command (in `/sbin` on most Linuxes) or the
command [ix[netstat]] `netstat -r`.

**How can I run the client and server programs if I only have one
computer?  Don't I need a network to write network programs?**

Fortunately for you, virtually all machines implement a [ix[loopback
device]] loopback network "device" that sits in the kernel and pretends
to be a network card. (This is the interface listed as "`lo`" in the
routing table.)

Pretend you're logged into a machine named [ix[goat]] "`goat`". Run the
client in one window and the server in another. Or start the server in
the background ("`server &`") and run the client in the same window. The
upshot of the loopback device is that you can either `client goat` or
[ix[localhost]] `client localhost` (since "`localhost`" is likely
defined in your `/etc/hosts` file) and you'll have the client talking to
the server without a network!

In short, no changes are necessary to any of the code to make it run on
a single non-networked machine! Huzzah!

**How can I tell if the remote side has closed connection?**

You can tell because `recv()` will return `0`.

**How do I implement a [ixtt[ping]] "ping" utility? What is [ixtt[ICMP]]
ICMP?  Where can I find out more about [ix[raw sockets]] raw sockets and
`SOCK_RAW`?**

All your raw sockets questions will be answered in [W. Richard Stevens'
UNIX Network Programming books](#books). Also, look in the `ping/`
subdirectory in Stevens' UNIX Network Programming source code,
[fl[available online|http://www.unpbook.com/src.html]].

**How do I change or shorten the timeout on a call to `connect()`?**

Instead of giving you exactly the same answer that W. Richard Stevens
would give you, I'll just refer you to [fl[`lib/connect_nonb.c` in the
UNIX Network Programming source code|http://www.unpbook.com/src.html]].

The gist of it is that you make a socket descriptor with `socket()`,
[set it to non-blocking](#blocking), call `connect()`, and if all goes
well `connect()` will return `-1` immediately and `errno` will be set to
`EINPROGRESS`. Then you call [`select()`](#select) with whatever timeout
you want, passing the socket descriptor in both the read and write sets.
If it doesn't timeout, it means the `connect()` call completed. At this
point, you'll have to use `getsockopt()` with the `SO_ERROR` option to
get the return value from the `connect()` call, which should be zero if
there was no error.

Finally, you'll probably want to set the socket back to be blocking
again before you start transferring data over it.

Notice that this has the added benefit of allowing your program to do
something else while it's connecting, too. You could, for example, set
the timeout to something low, like 500 ms, and update an indicator
onscreen each timeout, then call `select()` again. When you've called
`select()` and timed-out, say, 20 times, you'll know it's time to give
up on the connection.

Like I said, check out Stevens' source for a perfectly excellent
example.

**How do I build for Windows?**

First, delete Windows and install Linux or BSD. `};-)`. No, actually,
just see the [section on building for Windows](#windows) in the
introduction.

**How do I build for Solaris/SunOS? I keep getting linker errors when I
try to compile!**

The linker errors happen because Sun boxes don't automatically compile
in the socket libraries. See the [section on building for
Solaris/SunOS](#solaris) in the introduction for an example of how to do
this.

**Why does `select()` keep falling out on a signal?**

Signals tend to cause blocked system calls to return `-1` with `errno`
set to `EINTR`. When you set up a signal handler with
[ixtt[sigaction()]] `sigaction()`, you can set the flag
[ixtt[SA\_RESTART]] `SA_RESTART`, which is supposed to restart the
system call after it was interrupted.

Naturally, this doesn't always work.

My favorite solution to this involves a [ix[goto]] `goto` statement. You
know this irritates your professors to no end, so go for it!

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

Sure, you don't _need_ to use `goto` in this case; you can use other
structures to control it. But I think the `goto` statement is actually
cleaner.

**How can I implement a timeout on a call to `recv()`?**

[ix[recv()@\texttt{recv()}!timeout]] Use [ixtt[select()]]
[`select()`](#select)! It allows you to specify a timeout parameter for
socket descriptors that you're looking to read from. Or, you could wrap
the entire functionality in a single function, like this:

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

Notice that [ixtt[recvtimeout()]] `recvtimeout()` returns `-2` in case
of a timeout. Why not return `0`? Well, if you recall, a return value of
`0` on a call to `recv()` means that the remote side closed the
connection. So that return value is already spoken for, and `-1` means
"error", so I chose `-2` as my timeout indicator.

**How do I [ix[encryption]] encrypt or compress the data before sending
it through the socket?**

One easy way to do encryption is to use [ix[SSL]] SSL (secure sockets
layer), but that's beyond the scope of this guide. [ix[OpenSSL]] (Check
out the [fl[OpenSSL project|https://www.openssl.org/]] for more info.)

But assuming you want to plug in or implement your own [ix[compression]]
compressor or encryption system, it's just a matter of thinking of your
data as running through a sequence of steps between both ends. Each step
changes the data in some way.

1. server reads data from file (or wherever)
2. server encrypts/compresses data  (you add this part)
3. server `send()`s encrypted data

Now the other way around:

1. client `recv()`s encrypted data
2. client decrypts/decompresses data  (you add this part)
3. client writes data to file (or wherever)

If you're going to compress and encrypt, just remember to compress
first. `:-)`

Just as long as the client properly undoes what the server does, the
data will be fine in the end no matter how many intermediate steps you
add.

So all you need to do to use my code is to find the place between where
the data is read and the data is sent (using `send()`) over the network,
and stick some code in there that does the encryption.

**What is this "`PF_INET`" I keep seeing? Is it related to `AF_INET`?**

[ixtt[PF\_INET]] [ixtt[AF\_INET]]

Yes, yes it is. See [the section on `socket()`](#socket) for details.

**How can I write a server that accepts shell commands from a client and
executes them?**

For simplicity, lets say the client `connect()`s, `send()`s, and
`close()`s the connection (that is, there are no subsequent system calls
without the client connecting again).

The process the client follows is this:

1. `connect()` to server
2. `send("/sbin/ls > /tmp/client.out")`
3. `close()` the connection

Meanwhile, the server is handling the data and executing it:

1. `accept()` the connection from the client
2. `recv(str)` the command string
3. `close()` the connection
4. `system(str)` to run the command

[ix[security]] _Beware!_  Having the server execute what the client says
is like giving remote shell access and people can do things to your
account when they connect to the server. For instance, in the above
example, what if the client sends "`rm -rf ~`"? It deletes everything in
your account, that's what!

So you get wise, and you prevent the client from using any except for a
couple utilities that you know are safe, like the `foobar` utility:

```{.c}
if (!strncmp(str, "foobar", 6)) {
    sprintf(sysstr, "%s > /tmp/server.out", str);
    system(sysstr);
} 
```

But you're still unsafe, unfortunately: what if the client enters
"`foobar; rm -rf ~`"? The safest thing to do is to write a little
routine that puts an escape ("`\`") character in front of all
non-alphanumeric characters (including spaces, if appropriate) in the
arguments for the command.

As you can see, security is a pretty big issue when the server starts
executing things the client sends.

**I'm sending a slew of data, but when I `recv()`, it only receives 536
bytes or 1460 bytes at a time. But if I run it on my local machine, it
receives all the data at the same time. What's going on?**

You're hitting the [ix[MTU]] MTU---the maximum size the physical medium
can handle. On the local machine, you're using the loopback device which
can handle 8K or more no problem. But on Ethernet, which can only handle
1500 bytes with a header, you hit that limit. Over a modem, with 576 MTU
(again, with header), you hit the even lower limit.

You have to make sure all the data is being sent, first of all. (See the
[`sendall()`](#sendall) function implementation for details.) Once
you're sure of that, then you need to call `recv()` in a loop until all
your data is read.

Read the section [Son of Data Encapsulation](#sonofdataencap) for
details on receiving complete packets of data using multiple calls to
`recv()`.

**I'm on a Windows box and I don't have the `fork()` system call or any
kind of `struct sigaction`. What to do?**

[ixtt[fork()]] If they're anywhere, they'll be in POSIX libraries that
may have shipped with your compiler. Since I don't have a Windows box, I
really can't tell you the answer, but I seem to remember that Microsoft
has a POSIX compatibility layer and that's where `fork()` would be. (And
maybe even `sigaction`.)

Search the help that came with VC++ for "fork" or "POSIX" and see if it
gives you any clues.

If that doesn't work at all, ditch the `fork()`/`sigaction` stuff and
replace it with the Win32 equivalent: [ixtt[CreateProcess()]]
`CreateProcess()`. I don't know how to use `CreateProcess()`---it takes
a bazillion arguments, but it should be covered in the docs that came
with VC++.

**[ix[firewall]] I'm behind a firewall---how do I let people outside the
firewall know my IP address so they can connect to my machine?**

Unfortunately, the purpose of a firewall is to prevent people outside
the firewall from connecting to machines inside the firewall, so
allowing them to do so is basically considered a breach of security.

This isn't to say that all is lost. For one thing, you can still often
`connect()` through the firewall if it's doing some kind of masquerading
or NAT or something like that. Just design your programs so that you're
always the one initiating the connection, and you'll be fine.

[ix[firewall!poking holes in]] If that's not satisfactory, you can ask
your sysadmins to poke a hole in the firewall so that people can connect
to you. The firewall can forward to you either through it's NAT
software, or through a proxy or something like that.

Be aware that a hole in the firewall is nothing to be taken lightly. You
have to make sure you don't give bad people access to the internal
network; if you're a beginner, it's a lot harder to make software secure
than you might imagine.

Don't make your sysadmin mad at me. `;-)`

**[ix[packet sniffer]] [ix[promiscuous mode]] How do I write a packet
sniffer? How do I put my Ethernet interface into promiscuous mode?**

For those not in the know, when a network card is in "promiscuous mode",
it will forward ALL packets to the operating system, not just those that
were addressed to this particular machine. (We're talking Ethernet-layer
addresses here, not IP addresses--but since ethernet is lower-layer than
IP, all IP addresses are effectively forwarded as well. See the section
[Low Level Nonsense and Network Theory](#lowlevel) for more info.)

This is the basis for how a packet sniffer works. It puts the interface
into promiscuous mode, then the OS gets every single packet that goes by
on the wire.  You'll have a socket of some type that you can read this
data from.

Unfortunately, the answer to the question varies depending on the
platform, but if you Google for, for instance, "windows promiscuous
[ixtt[ioctl()]] ioctl" you'll probably get somewhere.  For Linux,
there's what looks like a [fl[useful Stack Overflow
thread|https://stackoverflow.com/questions/21323023/]], as well.

**How can I set a custom [ix[timeout, setting]] timeout value for a TCP
or UDP socket?**

It depends on your system. You might search the net for
[ixtt[SO\_RCVTIMEO]] `SO_RCVTIMEO` and [ixtt[SO\_SNDTIMEO]]
`SO_SNDTIMEO` (for use with [ixtt[setsockopt()]] `setsockopt()`) to see
if your system supports such functionality.

The Linux man page suggests using `alarm()` or `setitimer()` as a
substitute.

**How can I tell which ports are available to use? Is there a list of
"official" port numbers?**

Usually this isn't an issue. If you're writing, say, a web server, then
it's a good idea to use the well-known port 80 for your software. If
you're writing just your own specialized server, then choose a port at
random (but greater than 1023) and give it a try.

If the port is already in use, you'll get an "Address already in use"
error when you try to `bind()`. Choose another port. (It's a good idea
to allow the user of your software to specify an alternate port either
with a config file or a command line switch.)

There is a [fl[list of official port
numbers|https://www.iana.org/assignments/port-numbers]] maintained by
the Internet Assigned Numbers Authority (IANA). Just because something
(over 1023) is in that list doesn't mean you can't use the port. For
instance, Id Software's DOOM uses the same port as "mdqs", whatever that
is. All that matters is that no one else _on the same machine_ is using
that port when you want to use it.
