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
  * [5.1 getaddrinfo()—Prepare to launch!](#51-getaddrinfo---prepare-to-launch-)
  * [5.2 socket()—Get the File Descriptor!](#52-socket---get-the-file-descriptor-)
  * [5.3 bind()—What port am I on?](#53-bind---what-port-am-i-on-)
  * [5.4 connect()—Hey, you!](#54-connect---hey--you-)
  * [5.5 listen()—Will somebody please call me?](#55-listen---will-somebody-please-call-me-)
  * [5.6 accept()—“Thank you for calling port 3490.”](#56-accept----thank-you-for-calling-port-3490-)
  * [5.7 send() and recv()—Talk to me, baby!](#57-send---and-recv---talk-to-me--baby-)
  * [5.8 sendto() and recvfrom()—Talk to me, DGRAM-style](#58-sendto---and-recvfrom---talk-to-me--dgram-style)
  * [5.9 close() and shutdown()—Get outta my face!](#59-close---and-shutdown---get-outta-my-face-)
  * [5.10 getpeername()—Who are you?](#510-getpeername---who-are-you-)
  * [5.11 gethostname()—Who am I?](#511-gethostname---who-am-i-)

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

物理層は、ハードウェア（シリアル、イーサネットなど）です。アプリケーション層は物理層から想像できる限り離れたところにあり、ユーザーがネットワークと対話する場所です。

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

最後に、これらの関数は数値のIPアドレスに対してのみ動作します。"www.example.com "のようなホスト名に対してネームサーバーのDNSルックアップは行いません。後ほど説明するように、そのためには `getaddrinfo()` を使用します。

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

node パラメータには、接続先のホスト名、または IP アドレスを指定します。

次にパラメータserviceですが、これは"80"のようなポート番号か、"http", "ftp", "telnet", "smtp"などの特定のサービスの名前（[IANAポートリスト](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)やUnixマシンの`/etc/services`ファイルで見つけることができます）であることができます。

最後に、`hints`パラメータは、関連情報をすでに記入した`addrinfo`構造体を指します。

以下は、自分のホストのIPアドレス、ポート3490をリッスンしたいサーバーの場合の呼び出し例です。これは実際にはリスニングやネットワークの設定を行っていないことに注意してください。

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

ここでは、クライアントが特定のサーバー、例えば "www.example.net "ポート3490に接続したい場合のサンプルコールを紹介します。繰り返しますが、これは実際には接続しませんが、後で使用する構造をセットアップしています。

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

```
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
もう先延ばしにはできない。`socket()`システムコールの話をしなければならないのだ。以下はその内訳です。

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

時々、サーバーを再実行しようとすると、`bind()`が "Address already in use" と言って失敗することに気がつくかもしれません。これはどういうことでしょう? それは、接続されたソケットの一部がまだカーネル内に残っていて、ポートを占有しているのです。それが消えるのを待つか(1分くらい)、次のようにポートが再利用できるようなコードをプログラムに追加します。

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
ちょっとだけ、あなたがtelnetアプリケーションであることを仮定してみましょう。ユーザーが（映画 TRON のように）ソケットファイル記述子を取得するように命令します。あなたはそれに応じ、`socket()`を呼び出します。次に、ユーザはポート `23` (標準的な telnet ポート) で `10.12.110.57` に接続するように指示します。やったー! どうするんだ？

幸運なことに、あなたは今、`connect()`のセクションを読んでいるところです。だから、猛烈に読み進めよう! 時間がない!

`connect()`の呼び出しは以下の通りである。

```cpp
#include <sys/types.h>
#include <sys/socket.h>

int connect(int sockfd, struct sockaddr *serv_addr, int addrlen);
```

`sockfd`は`socket()`コールで返される、我々の身近なソケットファイル記述子、`serv_addr`は宛先ポートとIPアドレスを含む`sockaddr`構造体、`addrlen`はサーバーアドレス構造体のバイト長です。

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

`sockfd` は読み込むソケットディスクリプタ、`buf` は情報を読み込むバッファ、`len` はバッファの最大長、`flags` は再び 0 に設定できる(フラグについては `recv()` の man ページを参照)。

`recv()` は、実際にバッファに読み込まれたバイト数を返し、エラーの場合は -1 を返す（それに応じて errno が設定される）。

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

宛先アドレスの構造体を手に入れるには、以下の`getaddrinfo()`や`recvfrom()`から取得するか、手で記入することになると思います。

`send()` と同様、`sendto()` は実際に送信したバイト数 (これも、送信するように指示したバイト数よりも少ないかもしれません!) を返し、エラーの場合は -1 を返します。

同様に、`recv()`と`recvfrom()`も類似しています。`recvfrom()`の概要は以下の通りです。

```cpp
int recvfrom(int sockfd, void *buf, int len, unsigned int flags,
			 struct sockaddr *from, int *fromlen);
```

これも `recv()` と同様であるが、いくつかのフィールドが追加されています。`from` はローカルの `struct sockaddr_storage` へのポインタで、送信元のマシンの IP アドレスとポートが格納される。`fromlen` はローカルの `int` へのポインタであり、`sizeof *from` または `sizeof(struct sockaddr_storage)` に初期化する必要があります。この関数が戻ったとき、`fromlen`は実際に`from`に格納されたアドレスの長さを含みます。

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

ソケットの閉じ方をもう少し制御したい場合は、`shutdown()`関数を使用します。この関数では、特定の方向、あるいは両方の通信を遮断することができます (ちょうど `close()` がそうであるように)。概要

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
