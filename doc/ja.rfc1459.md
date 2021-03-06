Network Working Group       J. Oikarinen

Request for Comments: 1459  D. Reed

May 1993

# Internet Relay Chat Protocol

## Status of This Memo
このメモでは，インターネットコミュニティのための実験的なプロトコルを定義しています．改善のための議論と提案が望まれます．このプロトコルの標準化状態やステータスについては，「IAB Official Protocol Standards」の最新版を参照してください．このメモの配布は無制限です．

## Abstract
IRCプロトコルは，BBSでユーザ同士がチャットする手段として実装されて以来，4年の歳月をかけて開発されたものです．現在では，世界中に広がるサーバとクライアントのネットワークをサポートし，その成長に対応できるような体制を整えています．過去2年間で，IRCの主要ネットワークに接続しているユーザの平均人数は10倍に増加しています．

IRCプロトコルはテキストベースのプロトコルであり，最も単純なクライアントはサーバに接続可能な任意のソケットプログラムです．

<details>
<summary>Table of Contents</summary>

- [1. INTRODUCTION](#1-introduction)
  * [1.1 Servers](#11-servers)
  * [1.2 Clients](#12-clients)
    + [1.2.1 Operators](#121-operators)
  * [1.3 Channels](#13-channels)
    + [1.3.1 Channel Operators](#131-channel-operators)
- [2. The IRC Specification](#2-the-irc-specification)
  * [2.1 Overview](#21-overview)
  * [2.2 Character codes](#22-character-codes)
  * [2.3 Messages](#23-messages)
    + [2.3.1 Message format in ’pseudo’ BNF](#231-message-format-in-pseudo-bnf)
  * [2.4 Numeric replies](#24-numeric-replies)
- [3. IRC Concepts.](#3-irc-concepts)
  * [3.1 One-to-one communication](#31-one-to-one-communication)
  * [3.2 One-to-many](#32-one-to-many)
    + [3.2.1 To a list](#321-to-a-list)
    + [3.2.2 To a group (channel)](#322-to-a-group-channel)
    + [3.2.3 To a host/server mask](#323-to-a-hostserver-mask)
  * [3.3 One-to-all](#33-one-to-all)
    + [3.3.1 Client-to-Client](#331-client-to-client)
    + [3.3.2 Client-to-Server](#332-client-to-server)
    + [3.3.3 Server-to-Server.](#333-server-to-server)
- [4. MESSAGE DETAILS](#4-message-details)
  * [4.1 Connection Registration](#41-connection-registration)
    + [4.1.1 Password message](#411-password-message)
    + [4.1.2 Nickname message](#412-nickname-message)
    + [4.1.3 User message](#413-user-message)
    + [4.1.4 Server message](#414-server-message)
    + [4.1.5 Oper](#415-oper)
    + [4.1.6 Quit message](#416-quit-message)
    + [4.1.7 Server Quit message](#417-server-quit-message)
  * [4.2 Channel operations](#42-channel-operations)
    + [4.2.1 Join message](#421-join-message)
    + [4.2.2 Part message](#422-part-message)
    + [4.2.3 Mode message](#423-mode-message)
      - [4.2.3.1 Channel modes](#4231-channel-modes)
      - [4.2.3.2 User modes](#4232-user-modes)
    + [4.2.4 Topic message](#424-topic-message)
    + [4.2.5 Names message](#425-names-message)
    + [4.2.6 List message](#426-list-message)
    + [4.2.7 Invite message](#427-invite-message)
    + [4.2.8 Kick message](#428-kick-message)
  * [4.3 Server queries and commands](#43-server-queries-and-commands)
    + [4.3.1 Version message](#431-version-message)
    + [4.3.2 Stats message](#432-stats-message)
    + [4.3.3 Links message](#433-links-message)
    + [4.3.4 Time message](#434-time-message)
    + [4.3.5 Connect message](#435-connect-message)
    + [4.3.6 Trace message](#436-trace-message)
    + [4.3.7 Admin command](#437-admin-command)
    + [4.3.8 Info command](#438-info-command)
  * [4.4 Sending messages](#44-sending-messages)
    + [4.4.1 Private messages](#441-private-messages)
    + [4.4.2 Notice](#442-notice)
  * [4.5 User based queries](#45-user-based-queries)
    + [4.5.1 Who query](#451-who-query)
    + [4.5.2 Whois query](#452-whois-query)
    + [4.5.3 Whowas](#453-whowas)
  * [4.6 Miscellaneous messages](#46-miscellaneous-messages)
    + [4.6.1 Kill message](#461-kill-message)
    + [4.6.2 Ping message](#462-ping-message)
    + [4.6.3 Pong message](#463-pong-message)
    + [4.6.4 Error](#464-error)
- [5. OPTIONALS](#5-optionals)
  * [5.1 Away](#51-away)
  * [5.2 Rehash message](#52-rehash-message)
  * [5.3 Restart message](#53-restart-message)
  * [5.4 Summon message](#54-summon-message)
  * [5.5 Users](#55-users)
  * [5.6 Operwall message](#56-operwall-message)
  * [5.7 Userhost message](#57-userhost-message)
  * [5.8 Ison message](#58-ison-message)
- [6. REPLIES](#6-replies)
  * [6.1 Error Replies.](#61-error-replies)
  * [6.2 Command responses.](#62-command-responses)
  * [6.3 Reserved numerics.](#63-reserved-numerics)
- [7. Client and server authentication](#7-client-and-server-authentication)
- [8. Current implementations](#8-current-implementations)
  * [8.1 Network protocol: TCP - why it is best used here.](#81-network-protocol--tcp---why-it-is-best-used-here)
    + [8.1.1 Support of Unix sockets](#811-support-of-unix-sockets)
  * [8.2 Command Parsing](#82-command-parsing)
  * [8.3 Message delivery](#83-message-delivery)
  * [8.4 Connection ’Liveness’](#84-connection--liveness-)
  * [8.5 Establishing a server to client connection](#85-establishing-a-server-to-client-connection)
  * [8.6 Establishing a server-server connection.](#86-establishing-a-server-server-connection)
    + [8.6.1 Server exchange of state information when connecting](#861-server-exchange-of-state-information-when-connecting)
  * [8.7 Terminating server-client connections](#87-terminating-server-client-connections)
  * [8.8 Terminating server-server connections](#88-terminating-server-server-connections)
  * [8.9 Tracking nickname changes](#89-tracking-nickname-changes)
  * [8.10 Flood control of clients](#810-flood-control-of-clients)
  * [8.11 Non-blocking lookups](#811-non-blocking-lookups)
    + [8.11.1 Hostname (DNS) lookups](#8111-hostname-dns-lookups)
    + [8.11.2 Username (Ident) lookups](#8112-username-ident-lookups)
  * [8.12 Configuration File](#812-configuration-file)
    + [8.12.1 Allowing clients to connect](#8121-allowing-clients-to-connect)
    + [8.12.2 Operators](#8122-operators)
    + [8.12.3 Allowing servers to connect](#8123-allowing-servers-to-connect)
    + [8.12.4 Administrivia](#8124-administrivia)
  * [8.13 Channel membership](#813-channel-membership)
- [9. Current problems](#9-current-problems)
  * [9.1 Scalability](#91-scalability)
  * [9.2 Labels](#92-labels)
    + [9.2.1 Nicknames](#921-nicknames)
    + [9.2.2 Channels](#922-channels)
    + [9.2.3 Servers](#923-servers)
  * [9.3 Algorithms](#93-algorithms)

</details>

## 1. INTRODUCTION
IRC（Internet Relay Chat）プロトコルは，テキストベースの会議で使用するために何年もかけて設計されています．この文書では，現在のIRCプロトコルを説明します．

IRCプロトコルは，TCP/IPネットワークプロトコルを使用するシステム上で開発されましたが，このプロトコルが動作する唯一の領域である必要はありません．

IRC自体は電話会議システムで，クライアント・サーバモデルを採用しているため，多くのマシンで分散して動作させるのに適しています．典型的なセットアップは，単一のプロセス（サーバ）がクライアント（または他のサーバ）が接続するための中心点を形成し，必要なメッセージの配信/多重化およびその他の機能を実行することです．

### 1.1 Servers
サーバはIRCのバックボーンを形成し，クライアントが互いに会話するために接続するポイント，および他のサーバがIRCネットワークを形成するために接続するポイントを提供します．IRCサーバに許されるネットワーク構成は，スパニングツリー（図1参照）のみで，各サーバは，それが見るネットの残りの部分に対して中心ノードとして機能します．

```
             [ Server 15 ]   [ Server 13 ]      [ Server 14]
                 /                 \                /
                /                   \              /
        [ Server 11 ] ------ [ Server 1 ]    [ Server 12]
                              /        \        /
                             /          \      /
                  [ Server 2 ]        [ Server 3 ]
                    /       \                   \
                   /         \                   \
           [ Server 4 ]    [ Server 5 ]      [ Server 6 ]
            /    |   \                         /
           /     |    \                       /
          /      |     \____                 /
         /       |          \               /
[ Server 7 ] [ Server 8 ] [ Server 9 ] [ Server 10 ]
                                :
                             [ etc. ]
                                :
               [ Fig. 1. Format of IRC server network ]
```

### 1.2 Clients
クライアントとは，他のサーバではないサーバに接続するものです．各クライアントは，最大9文字の一意なニックネームによって他のクライアントと区別されます．ニックネームに使用できるもの，できないものについては，プロトコルの文法規則を参照してください．ニックネームに加えて，全てのサーバは全てのクライアントに関する以下の情報を 持っていなければなりません: クライアントが動作しているホストの実名，そのホスト上でのクライアントの ユーザ名，クライアントが接続しているサーバ．

#### 1.2.1 Operators
IRCネットワーク内の秩序を保つために，特別なクライアント（オペレータ）がネットワーク上で一般的なメンテナンス機能を実行することが許されています．オペレータに与えられた権限は「危険」とみなされることもありますが，それにもかかわらず，それらは必要とされます．オペレータは，不正なネットワーク・ルーティングの長期使用を防ぐために，必要に応じてサーバの切断や再接続などの基本的なネットワーク・タスクを実行できるようにする必要があります．この必要性を認識し，ここで議論されるプロトコルは，オペレータのみがそのような機能を実行できるように規定しています．[4.1.7 (SQUIT)](#417-server-quit-message) と [4.3.5 (CONNECT)](#435-connect-message) の項を参照してください．

オペレータの権限でもっと議論を呼ぶのは，接続されたネットワークからユーザを「強制的」に排除する能力，つまりオペレータは任意のクライアントとサーバ間の接続を閉じることができることです．その乱用は破壊的で迷惑なものであるため，これを正当化するのは微妙なところです．この種の動作の詳細については，セクション [4.6.1 (KILL)](#461-kill-message) を参照してください．

### 1.3 Channels
チャネルは，そのチャネル宛てのメッセージをすべて受信する，1つまたは複数のクライアントの名前付きグループです．チャネルは，最初のクライアントが参加したときに暗黙のうちに作成され，最後のクライアントが離脱したときに消滅します．チャネルが存在する間は，どのクライアントもチャネルの名前を使用してチャネルを参照することができます．

チャネル名は，200文字以内の文字列（’＆’または’#’で始まる文字）です．最初の文字が ’&’ または ’#’ であるという条件を除けば，チャネル名の唯一の制限は，スペース (’ ’)，コントロール G (^G または ASCII 7)，カンマ (’,’ はプロトコルではリスト項目の区切りとして使われます) を含まないということです．

このプロトコルでは，2種類のチャネルが認められています．1つは，ネットワークに接続されているすべてのサーバが知っている分散チャネルです．これらのチャネルは，最初の文字が，そのチャネルが存在するサーバ上のクライアントのみが参加できることでマークされています．これらのチャネルは，先頭の ’&’ 文字で区別されます．この2つのタイプの他に，個々のチャネルの特性を変更するために，様々なチャネルモードがあります．これについての詳細は [4.2.3 (MODE コマンド)](#423-mode-message) を参照してください．

新しいチャネルを作成したり，既存のチャネルの一部になるには，ユーザはチャネルに参加する必要があります．参加する前にチャネルが存在しない場合，チャネルは作成され，作成ユーザはチャネルオペレータになります．チャネルが既に存在する場合，そのチャネルへの JOIN 要求が受け入れられるかどうかは，チャネルの現在のモードによって異なります．たとえば，チャネルが招待制 (+i) の場合，あなたは招待された場合のみ参加できます．プロトコルの一部として，ユーザは同時に複数のチャネルに参加することができますが，経験豊富なユーザと初心者ユーザの両方にとって十分であるとして，10チャネルに制限することが推奨されています．これについては，[8.13 Channel membership](#813-channel-membership)を参照してください．

2つのサーバ間の分割によりIRCネットワークが分断された場合，それぞれの側のチャネルは，分割されたそれぞれの側のサーバに接続されているクライアントのみで構成され，分割された一方の側で存在しなくなる可能性があります．分割が完了すると，接続サーバはそれぞれのチャネルにいると思われる人とそのチャネルのモードを互いに発表します．チャネルが両側に存在する場合，JOIN と MODE は包括的に解釈され，新しい接続の両側が，どのクライアントがチャネルにいるか，チャネルがどのようなモードを持っているかについて合意するようにします．

#### 1.3.1 Channel Operators
あるチャネルのチャネル・オペレータ（「チョップ」または「チャノップ」とも呼ばれる）は，そのチャネルを「所有」しているとみなされます．このステータスを認識し，チャネル・オペレータは自分のチャネルをコントロールし，ある種の健全性を保つことができる一定の権限を与えられています． しかし，彼らの行動が一般的に反社会的であったり，虐待的である場合，IRCオペレータに介入を依頼したり，ユーザが他のチャネルに移動して，自分たちのチャネルを形成することは妥当なことかもしれません．

チャネルオペレータのみが使用できるコマンドは以下の通りです．

    KICK      - クライアントをチャネルから退出させる
    MODE      - チャネルのモードを変更する
    INVITE    - クライアントを招待制のチャネルに招待する（モード +i）
    TOPIC     - モード +t のチャネルのチャネルトピックを変更する

チャネルオペレータは，チャネルに関連づけられたときに(NAMES, WHO, WHOIS コマンドへの返信など)，ニックネームの隣にある’@’記号で識別されます．

## 2. The IRC Specification
### 2.1 Overview
本書で説明するプロトコルは，サーバ間接続とクライアントからサーバへの接続の両方に使用することができます．ただし，クライアント接続（信用できないとされる）には，サーバ接続よりも多くの制約があります．

### 2.2 Character codes
特定の文字セットは指定しません．プロトコルは，8 ビットで構成されるオクテットという符号体系を基本としています．各メッセージはこのオクテットの数で構成されますが，一部のオクテット値はメッセージの区切りとなる制御コードに使用されます．

8ビットプロトコルであるにもかかわらず，デリミタとキーワードがあるため，USASCIIターミナルとtelnet接続でほとんど使用可能です．

IRCはスカンジナビア語が起源なので，{}|という文字はそれぞれ[]という文字に相当する小文字とみなされます．これは，2つのニックネームの等価性を判断する際に重要な問題です．

### 2.3 Messages
サーバとクライアントは互いにメッセージを送り合い，返信が発生することもあればしないこともあります．メッセージに有効なコマンドが含まれている場合，後のセクションで説明するように，クライアントは指定されたとおりの返信を期待すべきですが，返信を永遠に待つことはお勧めできません．クライアントからサーバ，サーバからサーバへの通信は，本質的に非同期的な性質を持っています．

各IRCメッセージは，プレフィックス（オプション），コマンド，コマンド・パラメータ（最大15個まで）の3つの主要部分から構成されます．プレフィックス，コマンド，およびすべてのパラメータは，1つ（または複数）のASCIIスペース文字（0x20）で区切られます．

プリフィックスの存在は，先頭のASCIIコロン文字（’:’，0x3b）1つで示され，これはメッセージ自体の最初の文字でなければなりません．コロンとプレフィックスの間に隙間（ホワイトスペース）があってはいけません．プレフィックスは，サーバがメッセージの本当の出所を示すために使われます．メッセージにプレフィックスがない場合，そのメッセージは受信した接続から発信されたものとみなされます．クライアントは自分自身からメッセージを送るときには prefix を使うべきではありません． もし prefix を使うなら，有効な prefix はそのクライアントに関連付けられた登録済みの ニックネームだけです．プレフィックスによって識別される送信元がサーバの内部データベースから見つからない場合，あるいは送信元がメッセージの到着元とは異なるリンクから登録されている場合，サーバはそのメッセージを黙って無視しなければなりません．

コマンドは，有効なIRCコマンドか，ASCIIテキストで表現された(3)桁の数字でなければなりません．

IRCメッセージは常にCR-LF（Carriage Return - Line Feed）ペアで終了する文字列であり，メッセージの長さは最後のCR-LFを含むすべての文字を含めて512文字以下でなければなりません．したがって，コマンドとそのパラメータに許容される文字数は最大510文字です．継続メッセージ行の規定はありません．現在の実装の詳細については，章[7. Client and server authentication](#7-client-and-server-authentication)を参照してください．

#### 2.3.1 Message format in ’pseudo’ BNF
プロトコルメッセージは，オクテットの連続したストリームから抽出されなければなりません．現在の解決策は，CRとLFという2つの文字をメッセージのセパレータとして指定することです．空のメッセージは黙って無視されるので，メッセージ間でCR-LFのシーケンスが余分な問題なく使用できるようになります．

抽出されたメッセージは，\<prefix\>，\<command\> という要素と，\<middle\> または \<trailing\> のどちらかの要素でマッチするパラメータのリストに解析されます．

これをBNFで表現すると
```
<message>  ::= [’:’ <prefix> <SPACE> ] <command> <params> <crlf>
<prefix>   ::= <servername> | <nick> [ ’!’ <user> ] [ ’@’ <host> ]
<command>  ::= <letter> { <letter> } | <number> <number> <number>
<SPACE>    ::= ’ ’ { ’ ’ }
<params>   ::= <SPACE> [ ’:’ <trailing> | <middle> <params> ]
<middle>   ::= <SPACE，NUL，CR，LFを含まない，*空でない*オクテットのシーケンス． その最初の文字が’:’であってはならない．>
<trailing> ::= <NUL，CR，LF を含まない，任意の（場合によっては*空白の*）オクテット列>
<crlf>     ::= CR LF
```

NOTES:
1) \<SPACE\>は，スペース文字(0x20)のみで構成されます．特に，TABULATION と他のすべての制御文字は非空白文字とみなされます．
2) パラメータリスト抽出後，\<middle\>でマッチングしても\<trailing\>でマッチングしても，すべてのパラメータは等しくなります．\<trailing\>は，パラメータ内の SPACE を許容するための構文上のトリックに過ぎません．
3) パラメータ文字列にCRとLFが出現しないのは，メッセージのフレームワークのせいです．これは後で変更されるかもしれません．
4) NUL文字はメッセージのフレーム化において特別なものではなく，基本的にはパラメータの内部で終わる可能性がありますが，通常のCの文字列処理において余分な複雑さを引き起こすため，この文字は使用できません．したがって，NULはメッセージの中では許されません．
5) 最後のパラメータには，空文字列を指定することができます．
6) 拡張プレフィックス（[’!’ \<user\> ] [’@’ \<host\> ]）の使用は，サーバ間通信では使用してはならず，サーバからクライアントへのメッセージに限り，追加の問い合わせを必要とせずにメッセージの送信元に関するより有用な情報をクライアントに提供するために意図されています．

ほとんどのプロトコルメッセージは，リスト内の位置によって，抽出されたパラメータ文字列の追加のセマンティクスとシンタックスを指定しています．例えば，多くのサーバコマンドは，コマンドの後の最初のパラメータがターゲットのリストであると仮定し，これを記述することができます．
```
<target>     ::= <to> [ "," <target> ]
<to>         ::= <channel> | <user> ’@’ <servername> | <nick> | <mask>
<channel>    ::= (’#’ | ’&’) <chstring>
<servername> ::= <host>
<host>       ::= see RFC 952 [DNS:4] for details on allowed hostnames
<nick>       ::= <letter> { <letter> | <number> | <special> }
<mask>       ::= (’#’ | ’$’) <chstring>
<chstring>   ::= <any 8bit code except SPACE, BELL, NUL, CR, LF and comma (’,’)>
```
その他のパラメータ構文は以下の通りです．
```
<user>     ::= <nonwhite> { <nonwhite> }
<letter>   ::= ’a’ ... ’z’ | ’A’ ... ’Z’
<number>   ::= ’0’ ... ’9’
<special>  ::= ’-’ | ’[’ | ’]’ | ’\’ | ’‘’ | ’^’ | ’{’ | ’}’
<nonwhite> ::= <any 8bit code except SPACE (0x20), NUL (0x0), CR (0xd), and LF (0xa)>
```

### 2.4 Numeric replies
サーバに送信されたメッセージのほとんどは，何らかの応答を生成します．最も一般的な返信は数値による返信で，エラーと正常な返信の両方に使用されます．数値による返信は，送信者プレフィックス，3桁の数値，リプライのターゲットからなる1つのメッセージとして送信する必要があります．数値による応答は，クライアントから発信することはできないので，サーバが受信したそのようなメッセージは静かに削除されます．キーワードが文字列ではなく3桁の数字で構成されていることを除けば，他のすべての点で，数値による返信は通常のメッセージと同じである．さまざまな返信のリストは章[6. REPLIES](#6-replies)に記載されています．

## 3. IRC Concepts.
このセクションでは，IRCプロトコルの構成の背後にある実際の概念と，現在の実装がどのようにメッセージの異なるクラスを提供するかを説明することに専念します．

```
    1--\
        A        D---4
    2--/ \      /
          B----C
         /      \
        3        E
 Servers: A, B, C, D, E Clients: 1, 2, 3, 4
 [ Fig. 2. Sample small IRC network ]
```

### 3.1 One-to-one communication
サーバとサーバのトラフィックのほとんどは，サーバ同士が会話しているわけではないため，1対1の通信は通常クライアントのみが行います．クライアントが互いに会話するための安全な手段を提供するためには，すべてのサーバが，任意のクライアントに到達するために，スパニングツリーに沿って正確に一方向にメッセージを送信できることが必要です．メッセージが配送される経路は，スパニングツリー上の任意の2点間の最短経路です．

以下の例は，すべて上記の図2を参照しています．

* Example 1:

    クライアント1とクライアント2間のメッセージは，サーバAだけが見ることができ，サーバAはメッセージをそのままクライアント2に送ります．

* Example 2:

    クライアント1とクライアント3間のメッセージは，サーバAとB，クライアント3が見ることができます．他のクライアントやサーバはメッセージを見ることができません．

* Example 3:

    クライアント2と4の間のメッセージは，サーバA，B，C，Dとクライアント4だけが見ることができます．

### 3.2 One-to-many
IRCの主な目的は，簡単かつ効率的にコンファレンス（1対多の会話）を行うことができるフォーラムを提供することです．IRCはこれを実現するためにいくつかの手段を提供しており，それぞれが独自の目的をもっています．

#### 3.2.1 To a list
1対多の会話で最も効率が悪いのは，クライアントがユーザの’リスト’と会話するスタイルです．クライアントがメッセージの配送先のリストを与えると，サーバはそれを分割して，指定された配送先ごとにメッセージのコピーを送信します． これは，宛先リストが分割され，各経路に重複して送信されないことを確認せずにディスパッチが送信されるため，グループを使用する場合よりも効率的ではありません．

#### 3.2.2 To a group (channel)
IRCでは，チャネルはマルチキャストグループと同等の役割を持っています．その存在は動的であり（人々がチャネルに参加したり離れたりすることで行ったり来たりする），チャネル上で行われる実際の会話は，与えられたチャネル上のユーザをサポートしているサーバにのみ送信されます．同じチャネルのサーバに複数のユーザがいる場合，メッセージテキストはそのサーバに一度だけ送信され，その後チャネル内の各クライアントに送信されます．この動作は，元のメッセージが広がってチャネルの各メンバーに到達するまで，クライアントとサーバの組み合わせごとに繰り返されます．

以下の例は，すべて図2を参照しています．

* Example 4:

    クライアントが1人いる任意のチャネル．チャネルへのメッセージはサーバに送られ，それ以外の場所には送られません．

* Example 5:

    チャネル内の2クライアント．すべてのメッセージは，チャネルの外にいる2つのクライアント間のプライベートメッセージであるかのように経路を通過します．

* Example 6:

    クライアント1，2，3がチャネルを持つ．チャネルへのすべてのメッセージは，すべてのクライアントに送信され，それが単一のクライアントへのプライベートメッセージである場合，メッセージが通過しなければならないサーバにのみ送信されます．クライアント1がメッセージを送信すると，それはクライアント2に戻り，サーバBを経由してクライアント3に届きます．

#### 3.2.3 To a host/server mask
IRCの運営者が，関連する多くのユーザにメッセージを送るための何らかの仕組みを提供するために，ホストとサーバのマスクメッセージが提供されています．これらのメッセージは，ホストまたはサーバ情報がマスクに一致するユーザに送られます．メッセージは，チャネルと同様の方法で，ユーザがいる場所にのみ送信されます．

### 3.3 One-to-all
1対全のメッセージはブロードキャストメッセージと呼ばれ，すべてのクライアントまたはサーバ，あるいはその両方に送信されます．ユーザとサーバからなる大規模なネットワークでは，1つのメッセージによって，希望するすべての宛先に到達するために，ネットワーク上で多くのトラフィックが送信されることになります．

メッセージによっては，各サーバが持つ状態情報がサーバ間で適度に整合するように，全サーバにブロードキャストする以外の選択肢はありません．

#### 3.3.1 Client-to-Client
1つのメッセージから，他のすべてのクライアントにメッセージが送信されるようなメッセージのクラスは存在しません．

#### 3.3.2 Client-to-Server
状態情報の変更をもたらすコマンド（チャネルメンバーシップ，チャネルモード，ユーザステータスなど）のほとんどは，デフォルトですべてのサーバに送信されなければならず，この配布はクライアントによって変更することができません．

#### 3.3.3 Server-to-Server.
サーバ間のほとんどのメッセージは，すべての’他の’サーバに配布されますが，これは，ユーザ，チャネル，サーバのいずれかに影響を与えるメッセージにのみ必要です．これらは IRC で見られる基本的な項目ですので，あるサーバから発信されたほぼすべてのメッセージは，接続されている他のすべてのサーバにブロードキャストされます．

## 4. MESSAGE DETAILS
以下のページでは，IRCサーバとクライアントが認識する各メッセージについて説明します．このセクションで説明されているすべてのコマンドは，このプロトコルのための任意のサーバで実装されている必要があります．

ERR_NOSUCHSERVER が記載されている場合，パラメータが見つからなかったことを意味します．サーバはこれ以降，そのコマンドに対して他の応答を送ってはなりません．

クライアントが接続されているサーバは，メッセージ全体を解析し，適切なエラーを返すことが要求されます．メッセージの解析中に致命的なエラーが発生した場合，クライアントにエラーを返し，解析は終了しなければなりません．致命的なエラーとは，不正なコマンド，サーバにとって未知の宛先(サーバ名，ニックネーム，チャネル名がこれに該当)，十分なパラメータがない，不正な権限などが考えられます．

パラメータの完全なセットが提示された場合，それぞれの有効性をチェックし，適切なレスポンスをクライアントに返さなければなりません．コンマを区切り文字としてパラメータリストを使用するメッセージの場合，各項目に対して応答を送信しなければなりません．

以下の例では，一部のメッセージはフルフォーマットで表示されます．

```
:Name COMMAND parameter list
```

このような例は，サーバ間で転送中の「名前」からのメッセージを表し，リモートサーバが正しい経路で返信できるように，メッセージの元の送信者の名前を含めることが重要です．

### 4.1 Connection Registration
ここで説明するコマンドは，IRCサーバにユーザまたはサーバとして接続を登録し，正しく切断するために使用されます．

"PASS" コマンドは，クライアント接続，サーバ接続のいずれにおいても登録する必要はありませんが，サーバメッセージまたはNICK/USERの組み合わせの後者に先行させる必要があります．実際の接続にある程度のセキュリティを与えるために，すべてのサーバ接続にパスワードを設定することを強くお勧めします．クライアントが登録する際の推奨順序は以下の通りです．

1. Pass message
2. Nick message
3. User message

#### 4.1.1 Password message
```
Command   :  PASS
Parameters:  <password>
```
PASSコマンドは，’接続パスワード’を設定するために使用します．パスワードは，接続を登録しようとする前に設定することができ，また設定しなければなりません．現在，クライアントはNICK/USERの組み合わせを送信する前にPASSコマンドを送信する必要があり，サーバはSERVERコマンドの前にPASSコマンドを送信する必要があります．提供されるパスワードは，C/Nライン（サーバ用）またはIライン（クライアント用）に含まれるものと一致しなければなりません．登録前に複数のPASSコマンドを送信することは可能ですが，最後に送信されたものだけが検証に使用され，一度登録すると変更することはできません．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_ALREADYREGISTRED
```

Example:
```
    PASS secretpasswordhere
```

#### 4.1.2 Nickname message
```
   Command:  NICK
Parameters:  <nickname> [ <hopcount> ]
```

NICKメッセージは，ユーザにニックネームを与えたり，以前のニックネームを変更するために使用されます．このパラメータは，ニックネームがホームサーバからどれくらい離れているかを示すために，サーバによってのみ使用されます．ローカル接続の場合，hopcountは 0 になります．クライアントから提供された場合，これは無視されなければなりません．

他のクライアントの同じニックネームを既に知っているサーバにNICKメッセージが到着した場合，ニックネームの衝突が発生します． ニックネームの衝突の結果，そのニックネームのすべてのインスタンスがサーバのデータベースから削除され，KILL コマンドが他のすべてのサーバのデータベースからそのニックネームを削除するために発行されます．衝突の原因となった NICK メッセージがニックネームの変更であった場合，元の（古い）ニックネームも同様に削除されなければなりません．

サーバが直接接続されているクライアントから同一のNICKを受信した場合，ローカルクライアントにERR_NICKCOLLISIONを発行してNICKコマンドを破棄し，killを生成しないようにすることができます．

Numeric Replies:
```
    ERR_NONICKNAMEGIVEN   ERR_ERRONEUSNICKNAME
    ERR_NICKNAMEINUSE     ERR_NICKCOLLISION
```

Example:
```
NICK Wiz           ; 新しいニックネーム "Wiz "を紹介します．
:WiZ NICK Kilroy   ; WiZがKilroyにニックネームを変更しました．
```

#### 4.1.3 User message
```
Command   :  USER
Parameters:  <username> <hostname> <servername> <realname>
```

USER メッセージは，接続の最初に新しいユーザのユーザ名，ホスト名，サーバ名，実名 を指定するために使用されます．また，サーバ間の通信でも，新しいユーザがIRCに到着したことを示すために使われます．なぜなら，クライアントからUSERとNICKの両方を受け取って初めて，ユーザが登録されるからです．

サーバ間では，USERの前にクライアントのNICKnameを付ける必要があります． ホスト名とサーバ名は，通常，IRCサーバが直接接続されたクライアントからUSERコマンドが来た場合には(セキュリティ上の理由から)無視されますが，サーバ間の通信では使用されることに注意してください．つまり，新しいユーザをネットワークの他の部分に紹介するときには，必ずNICKをリモートサーバに送信してから，付随するUSERを送信しなければなりません．

realnameパラメータは，スペース文字を含む可能性があるため，最後のパラメータとする必要があり，そのように認識されるようにコロン（’:’）を先頭に付ける必要があることに注意しなければなりません．

USERメッセージのみに依存すると，クライアントがユーザ名について簡単に嘘をつ くことができるため，「IDサーバ」の使用を推奨します．ユーザが接続するホストでこのようなサーバが有効になっている場合，ユーザ名は「IDサーバ」からの返信と同じように設定されます．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_ALREADYREGISTRED
```

Examples:
```
USER guest tolmoon tolsun :Ronnie Reagan
        ; ユーザ名「guest」，本名「Ronnie Reagan」で登録されたユーザ

:testnick USER guest tolmoon tolsun :Ronnie Reagan
        ; USERコマンドが属するニックネームで，サーバ間でメッセージをやり取りします
```

#### 4.1.4 Server message
```
   Command:  SERVER
Parameters:  <user> <password>
```

サーバメッセージは，新しい接続の相手側がサーバであることをサーバに伝えるために使用されます．このメッセージは，サーバのデータをネット全体に渡すためにも使われます．新しいサーバがネットに接続されると，そのサーバに関する情報はネットワーク全体にブロードキャストされます．\<hopcount\> は，すべてのサーバがどの程度離れているかという内部情報を与えるために使用されます．完全なサーバリストがあれば，サーバツリー全体のマップを作成することが可能ですが，ホストマスクがそれを阻んでいます．

SERVERメッセージは，(a)まだ登録されておらず，サーバとして登録しようとしている接続，または(b)他のサーバへの既存の接続，この場合，SERVERメッセージはそのサーバの後ろに新しいサーバを導入している，のいずれかからのみ受け入れられなければなりません．

SERVERコマンドを受信したときに発生するエラーのほとんどは，宛先ホスト（ターゲットSERVER）によって接続が切断されることになります．ERRORコマンドにはいくつかの有用な特性があるため，エラー返信は通常，数値コマンドではなく，"ERROR "コマンドを使用して送信されます．

SERVERメッセージが解析され，受信側のサーバにすでに知られているサーバを紹介しようとした場合，サーバへの重複したルートが形成され，IRCツリーの非周期性が壊れているため，そのメッセージからの接続は(正しい手順に従って)閉じられなければなりません．

Numeric Replies:
```
    ERR_ALREADYREGISTRED
```

Example:
```
SERVER test.oulu.fi 1 :[tolsun.oulu.fi] Experimental server
        ; 新しいサーバ test.oulu.fi が自己紹介し，登録を試みています．[]内の名前は，test.oulu.fiを実行しているホストのホスト名です．

:tolsun.oulu.fi SERVER csd.bu.edu 5 :BU Central Server
        ; サーバ tolsun.oulu.fi は，5ホップ離れた csd.bu.edu へのアップリンクです．
```

#### 4.1.5 Oper
```
   Command:  OPER
Parameters:  <user> <password>
```

OPER メッセージは，一般ユーザがオペレータ権限を取得するために使用します．Operator権限を取得するためには，\<user\>と\<password\>の組み合わせが必要です．

OPERコマンドを送信したクライアントが，指定されたユーザの正しいパスワードを提供した場合，サーバはクライアントのニックネームに対して"MODE +o"を発行して，新しいオペレータをネットワークの残りの部分に通知します．

OPERメッセージは，クライアント・サーバのみです．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    RPL_YOUREOPER
    ERR_NOOPERHOST        ERR_PASSWDMISMATCH
```

Example:
```
OPER foo bar    ; ユーザ名に "foo"，パスワードに "bar "を使ってオペレータ登録を試みます．
```

#### 4.1.6 Quit message
```
   Command:  QUIT
Parameters:  [<Quit message>]
```

クライアントのセッションは，終了メッセージで終了します．サーバは，QUITメッセージを送信したクライアントとの接続を終了しなければなりません．"Quit Message" が指定された場合，デフォルトのメッセージである nickname の代わりにこれが送られます．

ネットスプリット（2つのサーバの接続が切れること）が発生した場合，終了メッセージは関係する2つのサーバの名前をスペースで区切って構成されます．最初の名前は，まだ接続しているサーバの名前であり，2番目の名前は，切断されたサーバの名前です．

その他の理由で，クライアントがQUITコマンドを発行せずにクライアント接続を閉じた場合（例：クライアントが死亡し，ソケットでEOFが発生），サーバは，その原因となった事象の性質を反映した何らかのメッセージで，終了メッセージを埋める必要があります．

Numeric Replies:
```
    None.
```

Examples:
```
QUIT :Gone to have lunch   ; 望ましいメッセージの形式
```

#### 4.1.7 Server Quit message
```
   Command:  SQUIT
Parameters:  <server> <comment>
```

SQUITメッセージは，終了したサーバや死んだサーバを伝えるために必要です． あるサーバが他のサーバとの接続を切断したい場合，SQUIT メッセージを他のサーバに送信する必要があります．その際，サーバパラメータとして他のサーバ名を指定します．

このコマンドは，IRCサーバのネットワークを秩序正しく接続するために，オペレータも利用できます．オペレータは，リモートサーバ接続のために SQUIT メッセージを発行することもできます．この場合，SQUITはオペレータとリモートサーバの間にある各サーバによって解析されなければならず，以下に説明するように各サーバによって保持されるネットワークのビューが更新されます．

\<comment\>は，（現在接続していない）リモートサーバに対してSQUITを実行するすべてのオペレータが，このアクションの理由を他のオペレータに認識させるために提供されるべきです．\<comment\> はまた，エラーまたは同様のメッセージを表示するサーバによって記入されます．

コネクションを閉じた側の両サーバは，そのリンクの背後にあると考えられる他のすべてのサーバのコネクションに対してSQUITメッセージを送信することが要求されます．

同様に，QUITメッセージは，そのリンクの背後にあるすべてのクライアントに代わって，ネットワークの他の接続されたサーバの残りの部分に送信されなければなりません．これに加えて，分割によってメンバーを失ったチャネルの全メンバーにQUITメッセージを送信しなければなりません．

サーバ接続が早期に切断された場合（リンクの反対側のサーバが死んだなど），この切断を検出したサーバは，ネットワークの残りの部分に接続が終了したことを通知し，コメントフィールドに適切な内容を記入する必要があります．

Numeric replies:
```
    ERR_NOPRIVILEGES    ERR_NOSUCHSERVER
```

Example:
```
SQUIT tolsun.oulu.fi :Bad Link?
        ; サーバのリンク tolson.oulu.fi は "Bad Link" のため終了されました．

:Trillian SQUIT cm22.eng.umd.edu :Server out of control
        ; Trillianから，"Server out of control "のため，"cm22.eng.umd.edu "をネットから切断するようにとのメッセージが表示されました．
```

### 4.2 Channel operations
このメッセージ群は，チャネル，そのプロパティ（チャネルモード），およびそのコンテンツ（通常はクライアント）を操作することに関係しています． これらの実装では，ネットワークの反対側の端にいるクライアントがコマンドを送ると，最終的に衝突してしまうため，多くの競合状態が避けられない．また，パラメータが与えられると，それが最近変更された場合に備えてサーバがその履歴をチェックすることを確実にするために，サーバがニックネームの履歴を保持することが要求されます．

#### 4.2.1 Join message
```
   Command:  JOIN
Parameters:  <channel>{,<channel>} [<key>{,<key>}]
```

JOINコマンドは，クライアントが特定のチャネルのリスニングを開始するために使用されます．クライアントがチャネルに参加できるかどうかは，クライアントが接続しているサーバのみが確認します．他のサーバは，他のサーバからチャネルを受信すると，自動的にユーザをチャネルに追加します．これに影響する条件は以下の通りです．

1. チャネルが招待制である場合，ユーザは招待されていなければなりません．
2. ユーザのニックネーム/ユーザ名/ホスト名は，アクティブな禁止事項にマッチしてはいけません．
3. 正しいキー(パスワード)が設定されている場合は，それを入力しなければなりません．

これらについては，MODEコマンドで詳しく説明します（詳細は[4.2.3 Mode message](#423-mode-message)項を参照してください）．

ユーザがチャネルに参加すると，そのチャネルに影響を与えるサーバが受け取るすべてのコマンドに関する通知を受け取ります．これには，MODE，KICK，PART，QUITや，もちろんPRIVMSG/NOTICEが含まれます．JOINコマンドは，各サーバがチャネルに参加しているユーザをどこで見つけることができるかを知るために，すべてのサーバにブロードキャストされる必要があります．これにより，PRIVMSG/NOTICEメッセージのチャネルへの最適な配信が可能になります．

JOINが成功すると，ユーザにチャネルのトピック（RPL_TOPICを使用）とチャネルに参加しているユーザのリスト（RPL_NAMREPLYを使用）が送られますが，これには参加しているユーザを含める必要があります．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_BANNEDFROMCHAN
    ERR_INVITEONLYCHAN    ERR_BADCHANNELKEY
    ERR_CHANNELISFULL     ERR_BADCHANMASK
    ERR_NOSUCHCHANNEL     ERR_TOOMANYCHANNELS
    RPL_TOPIC
```

Examples:
```
JOIN #foobar                ; チャネル #foobar に参加します．

JOIN &foo fubar             ; "fubar"をキーにチャネル &foo に参加します．

JOIN #foo,&bar fubar        ; チャネル #foo にキー "fubar" で，&bar にキー無しで参加します．

JOIN #foo,#bar fubar,foobar ; キー "fubar" を使ってチャネル #foo に参加し，キー "foobar" を使ってチャネル #bar に参加します．

JOIN #foo,#bar              ; チャネル #foo と #bar に参加します．

:WiZ JOIN #Twilight_zone    ; WiZからのJOINメッセージ
```

#### 4.2.2 Part message
```
   Command:  PART
Parameters:  <channel>{,<channel>}
```

PARTメッセージは，メッセージを送信したクライアントを，パラメータ文字列で指定されたすべてのチャネルのアクティブユーザ一覧から削除します．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_NOSUCHCHANNEL
    ERR_NOTONCHANNEL
```

Examples:
```
PART #twilight_zone    ; チャネル "#twilight_zone" を離脱します．

PART #oz-ops,&group5   ; "&group5" と "#oz-ops" の両方のチャネルを離脱します．
```

#### 4.2.3 Mode message
```
Command: MODE
```

MODEコマンドは，IRCでは2つの用途を持つコマンドです．これはユーザ名とチャネルの両方にモードを変更させることができます．この選択の根拠は，いつの日かニックネームが廃れ，同等のプロパティがチャネルになることです．

MODEメッセージを解析する場合，まずメッセージ全体を解析し，その結果生じた変更を引き継ぐことをお勧めします．

##### 4.2.3.1 Channel modes
```
Parameters:  <channel> {[+|-]|o|p|s|i|t|n|b|v} [<limit>] [<user>] [<ban mask>]
```

MODEコマンドは，チャネルオペレータが「自分の」チャネルの特性を変更できるように提供されています．また，チャネルオペレータを作成するために，サーバがチャネルモードを変更できることが要求されます．

チャネルに用意されている各種モードは以下の通りです．

```
    o - チャネルオペレータの特権を与えます/奪います;
    p - プライベートチャネルフラグ;
    s - シークレットチャネルフラグ;
    i - 招待専用チャネルフラグ;
    t - チャネルオペレータだけが設定可能なトピックフラグ;
    n - 外部のクライアントからチャネルへのメッセージの受信を禁止します;
    m - モデレートされたチャネル;
    l - チャネルへのユーザ制限を設定します;
    b - ユーザを閉め出すためのバンマスクを設定します;
    v - モデレートされたチャネルで発言する能力を与えます/奪います;
    k - チャネルキー（パスワード）を設定します.
```

’o’ と ’b’ オプションを使用する場合，1つのモードコマンドにつき合計3つまでという制限が課されます．つまり，’o’ と ’b’ の組み合わせは，1つのモードコマンドにつき，合計3つまでという制限があります．

##### 4.2.3.2 User modes
```
Parameters:  <nickname> {[+|-]|i|w|s|o}
```

ユーザモードは通常，クライアントが他者からどのように見られるか，またはクライアントがどのような「追加」メッセージを送信するかに影響する変更です．ユーザMODEコマンドは，メッセージの送信者とパラメータとして与えられたニックネームの両方が同じである場合にのみ受け入れることができます．

使用可能なモードは以下の通りです．

```
    i - ユーザを非表示にします;
    s - サーバからのお知らせを受信するユーザをマークします;
    w - ユーザは，Wallopsを受け取ります;
    o - オペレータフラグ．
```

後日，追加モードも用意される予定です．

ユーザが "+o" フラグを使用して自分自身をオペレータにしようとした場合，その試みは無視されるべきです．しかし，"-o" を使って自分自身をオペレータから外すことには何の制限もありません．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS      RPL_CHANNELMODEIS
    ERR_CHANOPRIVSNEEDED    ERR_NOSUCHNICK
    ERR_NOTONCHANNEL        ERR_KEYSET
    RPL_BANLIST             RPL_ENDOFBANLIST
    ERR_UNKNOWNMODE         ERR_NOSUCHCHANNEL

    ERR_USERSDONTMATCH      RPL_UMODEIS
    ERR_UMODEUNKNOWNFLAG
```

Examples:
```
Use of Channel Modes:

MODE #Finnish +im       ; #Finish のチャネルをモデレートされた「招待制」にします．

MODE #Finnish +o Kilroy ; チャネル #Finnish で Kilroy に ’chanop’ 権限を付与します．

MODE #Finnish +v Wiz    ; WiZに #Finnish で発言するのを許可します．

MODE #Fins -s           ; チャネル #Fins から ’secret’ フラグを削除します．

MODE #42 +k oulu        ; チャネルキーを "oulu" に設定します．

MODE #eu-opers +l 10    ; チャネルのユーザ数制限を10に設定します．

MODE &oulu +b           ; チャネルに設定されたバンマスクをリストアップします．

MODE &oulu +b !@*       ; すべてのユーザを参加させないようにします．

MODE &oulu +b !@*.edu   ; ホスト名が \*.edu に一致するユーザが参加できないようにします．

Use of user Modes:

:MODE WiZ -w            ; WiZ の WALLOPS メッセージの受信をオフにします．

:Angel MODE Angel +i    ; Angle からのメッセージを自分自身へ非表示にします．

MODE WiZ -o             ; WiZ をオペレータでなくします（オペレータの状態を解除する．）このコマンドの逆（"MODE WiZ +o"）は，OPERコマンドをバイパスしてしまうので，ユーザから許可されてはいけません．
```

#### 4.2.4 Topic message
```
   Command:  TOPIC
Parameters:  <channel> [<topic>]
```

TOPIC メッセージは，チャネルのトピックを変更または表示するために使用されます．\<topic\> が指定されていない場合は，チャネル \<channel\> のトピックが返されます．\<topic\> パラメータがある場合，チャネルモードが許可していれば，そのチャネルのトピックが変更されます．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_NOTONCHANNEL
    RPL_NOTOPIC           RPL_TOPIC
    ERR_CHANOPRIVSNEEDED
```

Examples:
```
:Wiz TOPIC #test :New topic    ;トピックを設定するユーザ Wiz．

TOPIC #test :another topic     ;#testのトピックを "別のトピック"に設定します．

TOPIC #test                    ; #testのトピックを確認します．
```

#### 4.2.5 Names message
```
   Command:  NAMES
Parameters:  [<channel>{,<channel>}]
```

NAMES コマンドを使用すると，ユーザが見ることのできるチャネルに表示されているすべてのニックネームをリストアップすることができます．表示されるチャネル名は，プライベート (+p) やシークレット (+s) でないもの，または実際に参加しているチャネル名です．パラメータは，有効な場合に情報を返すチャネルを指定します． 不正なチャネル名に対するエラーの返事はありません．

\<channel\> パラメータが与えられない場合，すべてのチャネルとその占有者のリストが返されます．このリストの最後には，表示されているがどのチャネルにも入っていない，または表示されているチャネルに入っていないユーザのリストが ’channel’ "\*" に入っているとしてリストアップされます．

Numerics:
```
    RPL_NAMREPLY    RPL_ENDOFNAMES
```

Examples:
```
NAMES #twilight_zone,#42
        ; #twilight_zone と #42 のチャネルが表示されている場合，表示されているユーザをリストアップします．

NAMES
        ; 表示されているすべてのチャネルとユーザをリストアップします．
```

#### 4.2.6 List message
```
   Command:  LIST
Parameters:  [<channel>{,<channel>} [<server>]]
```

リストメッセージは，チャネルとそのトピックを一覧表示するために使用されます．\<channel\> パラメータを使用した場合，そのチャネルの状態のみが表示されます．プライベートチャネルは，クエリを生成したクライアントが実際にそのチャネルにいない限り，チャネル "Prv" としてリストされます (トピックは含まれません)．同様に，シークレットチャネルは，クライアントがそのチャネルのメンバーでない限り，まったく表示されません．

Numeric Replies:
```
    ERR_NOSUCHSERVER    RPL_LISTSTART
    RPL_LIST            RPL_LISTEND
```

Examples:
```
LIST                       ;すべてのチャネルを一覧表示します．

LIST #twilight_zone,#42    ; #twilight_zone と #42 チェネルを一覧表示します．
```

#### 4.2.7 Invite message
```
   Command:  INVITE
Parameters:  <nickname> <channel>
```

INVITEメッセージは，ユーザをチャネルに招待するために使用されます．パラメータ \<nickname\> には，ターゲットチャネル \<channel\> に招待する人のニックネームを指定します．招待されるターゲットユーザが存在すること，または有効なチャネルであることは要求されません．招待専用チャネル（MODE +i）にユーザを招待するには，招待を送信するクライアントがそのチャネルのチャネルオペレータとして認識されている必要があります．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_NOSUCHNICK
    ERR_NOTONCHANNEL      ERR_USERONCHANNEL
    ERR_CHANOPRIVSNEEDED
    RPL_INVITING          RPL_AWAY
```

Examples:
```
:Angel INVITE Wiz #Dust      ; ユーザ Angel が WiZ をチャネル #Dust に招待しています．

INVITE Wiz #Twilight_Zone    ; WiZ を #Twilight_zone に招待するコマンド
```

#### 4.2.8 Kick message
```
   Command:  KICK
Parameters:  <channel> <user> [<comment>]
```

KICKコマンドは，あるユーザをチャネルから強制的に排除するために使用します．これはチャネルから「追い出す」（forced PART）ことです．チャネルオペレータのみが他のユーザをチャネルから追い出すことができます．KICKメッセージを受信した各サーバは，それが有効であるかどうか（つまり，送信者が実際にチャネルオペレータであるかどうか）を，犠牲者をチャネルから追い出す前にチェックします．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS    ERR_NOSUCHCHANNEL
    ERR_BADCHANMASK       ERR_CHANOPRIVSNEEDED
    ERR_NOTONCHANNEL
```

Examples:
```
KICK &Melbourne Matthew
        ; チャネル &Melbourne から Matthew をキックします．

KICK #Finnish John :Speaking English
        ; 英語で話すことを理由（コメント）に #Finnish から John をキックします．

:WiZ KICK #Finnish John
        ; チャネル #Finnish から John を削除するという Wiz からのキックメッセージ．
```

NOTE:
    KICKコマンドのパラメータを以下に拡張することが可能です．

```
<channel>{,<channel>} <user>{,<user>} [<comment>]
```

### 4.3 Server queries and commands
サーバ問合せコマンド群は，ネットワークに接続されているあらゆるサーバの情報を返すように設計されています．接続されているすべてのサーバは，これらの問い合わせに応答し，正しく応答する必要があります．無効な応答（またはその欠如）は，サーバの故障の兆候とみなされ，状況が改善されるまでできるだけ早く切断/無効化されなければなりません．

これらのクエリにおいて，パラメータが"\<server\>"と表示される場合，それは通常，ニックネーム，サーバ，またはある種のワイルドカード名である可能性があることを意味します．しかし，各パラメータに対して，1つのクエリと返信のセットしか生成されません．

#### 4.3.1 Version message
```
   Command:  VERSION
Parameters:  [<server>]
```

VERSION メッセージはサーバプログラムのバージョンを問い合わせるために使用されます．オプションのパラメータ \<server\> は，クライアントが直接接続していないサーバプログラムのバージョンを問い合わせるために使用されます．

Numeric Replies:
```
    ERR_NOSUCHSERVER    RPL_VERSION
```

Examples:
```
:Wiz VERSION *.se
		; Wizから "*.se" に一致するサーバのバージョンを確認するメッセージ

VERSION tolsun.oulu.fi
		; サーバ "tolsun.oulu.fi "のバージョンを確認します．
```

#### 4.3.2 Stats message
```
   Command:  STATS
Parameters:  [<query> [<server>]]
```

statsメッセージは，特定のサーバの統計情報を問い合わせるために使用されます．\<server\> パラメータを省略した場合は，stats メッセージの末尾のみを返送します．本コマンドの実装は返信するサーバに大きく依存しますが，サーバは以下のクエリ（または類似のもの）で記述された情報を提供できる必要があります．

クエリは任意の一文字で指定することができ，(\<server\> パラメータとして指定された場合) 宛先サーバでのみ確認され，それ以外は中間サーバによって無視され，変更されずに渡されます． 以下のクエリは現在の IRC の実装で見られるもので，そのサーバのセットアップ情報の大部分を提供します．これらは他のバージョンでは同じようにサポートされていないかもしれませんが，すべてのサーバは現在使用されている応答フォーマットとクエリの目的に合致した，STATS クエリに対する有効な応答を提供することができるはずです．

現在対応しているクエリは以下の通りです．

```
    c - サーバが接続する，あるいは接続を許可するサーバのリストを返します;
	h - 強制的に離脱として扱われるか，ハブとして動作することが許可されているサーバのリストを返します;
	i - サーバがクライアントからの接続を許可するホストのリストを返します;
	k - そのサーバでバンされているユーザ名とホスト名の組み合わせのリストを返します;
	l - サーバの接続のリストを返します．各接続の確立時間，およびその接続上のトラフィックを各方向のバイトとメッセージで表示します．
	m - サーバがサポートするコマンドのリストと，使用回数が0でない場合は，それぞれの使用回数を返します;
	o - 通常のクライアントがオペレータになることができるホストのリストを返します;
	y - サーバの構成ファイルから Y (クラス) 行を表示します;
	u - サーバが稼働していた時間を示す文字列を返します．
```

Numeric Replies:
```
    ERR_NOSUCHSERVER
    RPL_STATSCLINE       RPL_STATSNLINE
    RPL_STATSILINE       RPL_STATSKLINE
    RPL_STATSQLINE       RPL_STATSLLINE
    RPL_STATSLINKINFO    RPL_STATSUPTIME
    RPL_STATSCOMMANDS    RPL_STATSOLINE
    RPL_STATSHLINE       RPL_ENDOFSTATS
```

Examples:
```
STATS m                 ; 接続しているサーバのコマンドの使用状況を確認します．
:Wiz STATS c eff.org    ; WiZによるサーバ eff.org からの C/N ライン情報のリクエスト．
```

#### 4.3.3 Links message
```
   Command:  LINKS
Parameters:  [[<remote server>] <server mask>]
```

LINKSを使用すると，ユーザはクエリに応答するサーバが知っているすべてのサーバをリストアップすることができます．返されるサーバのリストはマスクと一致しなければならず，マスクが与えられない場合は完全なリストが返されます．\<server mask\> に加えて \<remote server\> が指定された場合，LINKS コマンドはその名前にマッチする最初のサーバに転送され，そのサーバは問い合わせに応答することが要求されます．

Numeric Replies:
```
    ERR_NOSUCHSERVER
    RPL_LINKS           RPL_ENDOFLINKS
```

Examples:
```
LINKS *.au                   ; *.au に一致する名前を持つすべてのサーバをリストアップします．

:WiZ LINKS *.bu.edu *.edu    ; WiZから *.bu.edu に一致するサーバリストの* .edu に最初にマッチするサーバへのLINKSメッセージ．
```

#### 4.3.4 Time message
```
   Command:  TIME
Parameters:  [<server>]
```

time メッセージは，指定されたサーバからローカルタイムを問い合わせるために使用されます．server パラメータが指定されない場合，コマンドを処理するサーバは問い合わせに応答する必要があります．

Numeric Replies:
```
    ERR_NOSUCHSERVER    RPL_TIME
```

Examples:
```
TIME tolsun.oulu.fi    ; サーバ "tolson.oulu.fi" の時刻を確認します．
Angel TIME *.au        ; ユーザ Angel が "*.au" に一致するサーバで時刻を確認しています．
```

#### 4.3.5 Connect message
```
   Command:  CONNECT
Parameters:  <target server> [<port> [<remote server>]]
```

CONNECT コマンドは，サーバが他のサーバとの新しい接続を直ちに確立しようとすることを強制するために使用することができます．CONNECT は特権的なコマンドであり，IRC オペレータのみが使用することができます．リモートサーバが指定された場合，そのサーバは \<target server\> と \<port\> に対して CONNECT を試みます．

Numeric Replies:
```
    ERR_NOSUCHSERVER      ERR_NOPRIVILEGES
    ERR_NEEDMOREPARAMS
```

Examples:
```
CONNECT tolsun.oulu.fi
		; tolsun.oulu.fi へのサーバ接続を試みます．

:WiZ CONNECT eff.org 6667 csd.bu.edu
		; WiZ がサーバ eff.org と csd.bu.edu をポート6667で接続するためにCONNECTを試みました．
```

#### 4.3.6 Trace message
```
   Command:  TRACE
Parameters:  [<server>]
```

TRACEコマンドは，特定のサーバへの経路を検索するために使用されます．このメッセージを処理する各サーバは，パススルーリンクであることを示す応答を送信して送信者に伝える必要があり，"traceroute" を使用して得られるのと同様の応答の連鎖を形成します．この応答を送り返した後，指定されたサーバに到達するまで，次のサーバに TRACE メッセージを送信しなければなりません．\<server\> パラメータが省略された場合，TRACE コマンドは，現在のサーバがどのサーバに直接接続しているかを送信者に伝えるメッセージを送信することが推奨されます．

"\<server\>" で指定された送信先が実際のサーバである場合，送信先サーバは接続されているすべてのサーバとユーザを報告する必要がありますが，オペレータのみがユーザの存在を確認することを許可されます．\<server\> で指定された宛先がニックネームの場合，そのニックネームに対する応答のみが返されます．

Numeric Replies:
```
    ERR_NOSUCHSERVER

TRACEメッセージが他のサーバに向けられた場合，すべての中間サーバはRPL_TRACELINK応答を返し，TRACEがそれを通過したことと次の行き先を示す必要があります．

    RPL_TRACELINK
TRACE応答は，以下の数値応答からいくつでも構成することができます．

    RPL_TRACECONNECTING    RPL_TRACEHANDSHAKE
    RPL_TRACEUNKNOWN       RPL_TRACEOPERATOR
    RPL_TRACEUSER          RPL_TRACESERVER
    RPL_TRACESERVICE       RPL_TRACENEWTYPE
    RPL_TRACECLASS
```

Examples:
```
TRACE *.oulu.fi         ; *.oulu.fi に一致するサーバへの TRACE．

:WiZ TRACE AngelDust    ; WiZ が AngelDust のニックネームに対して発行した TRACE．
```

#### 4.3.7 Admin command
```
Command   :  ADMIN
Parameters:  [<server>]
```

adminメッセージは，指定されたサーバ（\<server\>パラメータが省略された場合は現在のサーバ）の管理者名を検索するために使用されます．各サーバは，ADMINメッセージを他のサーバに転送する機能を持つ必要があります．

Numeric Replies:
```
    ERR_NOSUCHSERVER
    RPL_ADMINME      RPL_ADMINLOC1
    RPL_ADMINLOC2    RPL_ADMINEMAIL
```

Examples:
```
ADMIN tolsun.oulu.fi    ; tolsun.oulu.fi からADMINの返信を要求します．
:WiZ ADMIN *.edu        ; WiZからの *.edu に一致する最初のサーバへのADMINリクエスト．
```

#### 4.3.8 Info command
```
   Command:  INFO
Parameters:  [<server>]
```

INFOコマンドは，サーバのバージョン，コンパイル日，パッチレベル，起動日，その他関連すると思われる雑多な情報など，サーバに関する情報を返すことが要求されます．

Numeric Replies:
```
    ERR_NOSUCHSERVER
    RPL_INFO            RPL_ENDOFINFO
```

Examples:
```
INFO csd.bu.edu      ; csd.bu.eduからINFOの返信を要求します．
:Avalon INFO *.fi    ; Avalonからの *.fi に一致する最初のサーバへのINFOリクエスト．
INFO Angel           ; Angelが接続されているサーバに情報を要求します．
```

### 4.4 Sending messages
IRCプロトコルの主な目的は，クライアントが互いに通信するための基盤を提供することです．PRIVMSG と NOTICE は，あるクライアントから別のクライアントへのテキストメッセージの配信を実際に実行する唯一のメッセージです - 残りはそれを可能にし，それが信頼できる構造化された方法で起こることを確実にしようとするだけです．

#### 4.4.1 Private messages
```
   Command:  PRIVMSG
Parameters:  <receiver>{,<receiver>} <text to be sent>
```

PRIVMSGは，ユーザ間のプライベートメッセージの送信に使用されます．\<receiver\> には，メッセージの受信者のニックネームを指定します．\<receiver\> はカンマで区切られた名前またはチャネルのリストでもかまいません．

\<receiver\> パラメータには，ホストマスク (#mask) またはサーバマスク ($mask) を指定することもできます．どちらの場合も，サーバはこのマスクに一致するサーバやホストを持つ人にのみ PRIVMSG を送ります．マスクには少なくとも1つの "." が必要で，最後の "." の後にはワイルドカードを使用しないでください．この条件は，"#*" や "$*" にメッセージを送ると，すべてのユーザにブロードキャストされてしまうのを防ぐためにあります．経験上，これは責任を持って適切に使われるよりも悪用されることが多いです． ワイルドカードとは，’*’ および ’?’ 文字のことです．この PRIVMSG コマンドの拡張は，オペレータのみが使用できます．

Numeric Replies:
```
    ERR_NORECIPIENT         ERR_NOTEXTTOSEND
    ERR_CANNOTSENDTOCHAN    ERR_NOTOPLEVEL
    ERR_WILDTOPLEVEL        ERR_TOOMANYTARGETS
    ERR_NOSUCHNICK
    RPL_AWAY
```

Examples:
```
:Angel PRIVMSG Wiz :Hello are you receiving this message ?
        ; Angel からの Wiz へのメッセージ
PRIVMSG Angel :yes I’m receiving it !receiving it !’u>(768u+1n) .br
        ; Angel へのメッセージ
PRIVMSG jto@tolsun.oulu.fi :Hello !
        ; サーバ tolsun.oulu.fi のユーザ名 "jto" のクライアントへのメッセージ．
PRIVMSG $*.fi :Server tolsun.oulu.fi rebooting.
        ; *.fi に一致する名前を持つサーバ上のすべての人へのメッセージ．
PRIVMSG #*.edu :NSFNet is undergoing work, expect interruptions
        ; ホスト名が *.edu に一致するホストから来たすべてのユーザへのメッセージ．
```

#### 4.4.2 Notice
```
   Command:  NOTICE
Parameters:  <nickname> <text>
```

NOTICEメッセージは，PRIVMSGと同様に使用される．NOTICE と PRIVMSG の違いは，NOTICE メッセージに応答して自動返信が決して送られてはならないことです．このルールはサーバにも適用されます．サーバは，NOTICEを受信したときに，クライアントにいかなるエラー返信も送り返してはいけません．このルールの目的は，クライアントが受信した何かに応答して自動的に何かを送信する間のループを避けることです．これは，オートマトン(AIや他の対話的なプログラムが行動を制御しているクライアント)によって典型的に使われます．オートマトンは，他のオートマトンとループになってしまわないように，常に返信しているように見えます．

返信の詳細および例については，PRIVMSGを参照してください．

### 4.5 User based queries
ユーザクエリは，特定のユーザまたはグループユーザの詳細を検索することを主目的とするコマンド群です．これらのコマンドでワイルドカードを使用する場合，それらが一致すると，あなたが’見える’ユーザの情報のみが返されます．ユーザの可視性は，ユーザのモードと，あなたが共にいる共通のチャネルセットの組み合わせで決定されます．

#### 4.5.1 Who query
```
   Command:  WHO
Parameters:  [<name> [<o>]]
```

WHOメッセージはクライアントがクエリを生成する際に使用され，クライアントが指定した \<name\> パラメータに「一致」する情報のリストを返します．\<name\> パラメータがない場合，すべての可視 (不可視 (ユーザモード +i) でなく，要求元のクライアントと共通のチャネルを持っていないユーザ) のリストが表示されます．\<name\> に "0" やワイルドカードを使用しても同じ結果が得られますが，これは可能な限りすべてのエントリーにマッチすることになります．

WHO に渡された \<name\> は，チャネル \<name\> が見つからない場合，ユーザのホスト，サーバ，実名，ニックネームと照合されます．"o" パラメータを渡した場合は，与えられた名前マスクに従って，オペレータのみが返されます．

Numeric Replies:
```
    ERR_NOSUCHSERVER
    RPL_WHOREPLY        RPL_ENDOFWHO
```

Examples:
```
WHO *.fi      ; "*.fi" にマッチするすべてのユーザをリストアップします．
WHO jto* o    ; "jto*" にマッチするユーザがオペレータである場合，そのユーザをすべてリストアップします．
```

#### 4.5.2 Whois query
```
   Command:  WHOIS
Parameters:  [<server>] <nickmask>[,<nickmask>[,...]]
```

このメッセージは，特定のユーザに関する情報を問い合わせるために使用されます．サーバはこのメッセージに対して，ニックネームと一致する各ユーザの異なるステータスを示すいくつかの数値メッセージを返します(あなたがそれらを見る権利がある場合)．\<nickmask\> にワイルドカードが指定されていない場合は，そのニックネームに関する，閲覧可能なすべての情報が表示されます．カンマ (’,’) で区切ったニックネームのリストを指定することもできます．

後者は，特定のサーバに問い合わせを行うものです．ローカルサーバ（つまり，ユーザが直接接続しているサーバ）だけがその情報を知っており，他のすべてはグローバルに知られているので，問題のユーザがどれくらいアイドル状態であったかを知りたい場合に有用です．

Numeric Replies:
```
    ERR_NOSUCHSERVER     ERR_NONICKNAMEGIVEN
    RPL_WHOISUSER        RPL_WHOISCHANNELS
    RPL_WHOISCHANNELS    RPL_WHOISSERVER
    RPL_AWAY             RPL_WHOISOPERATOR
    RPL_WHOISIDLE        ERR_NOSUCHNICK
    RPL_ENDOFWHOIS
```

Examples:
```
WHOIS wiz                 ; nick WiZ に関する利用可能なユーザ情報を返します．
WHOIS eff.org trillian    ; trillian に関するユーザ情報をサーバ eff.org に問い合わせます．
```

#### 4.5.3 Whowas
```
   Command:  WHOWAS
Parameters:  <nickname> [<count> [<server>]]
```

Whowas は，もう存在しないニックネームに関する情報を要求します．これはニックネームの変更か，ユーザが IRC を去ったかのどちらかでしょう．この問い合わせに対して，サーバはニックネームの履歴を検索し，辞書的に同じニックネームを探します (ここではワイルドカードによるマッチングは行いません)．履歴は後方から検索され，最新のエントリが最初に返されます．複数のエントリがある場合は，\<count\> 個までの返答が返されます (\<count\> パラメータが与えられていない場合は，それらすべてが返されます)．\<count\> として正でない数字が渡された場合，完全な検索が行われます．

Numeric Replies:
```
    ERR_NONICKNAMEGIVEN    ERR_WASNOSUCHNICK
    RPL_WHOWASUSER         RPL_WHOISSERVER
    RPL_ENDOFWHOWAS
```

Examples:
```
WHOWAS Wiz                ; ニックネーム "WiZ" に関するニックネーム履歴の全情報を返します;
WHOWAS Mermaid 9          ; "Mermaid" のニックネーム履歴のうち，最大で最新の9件を返します;
WHOWAS Trillian 1 *.edu    ; "Trillian" の最新の履歴を，"*.edu" にマッチする最初のサーバから返します．
```

### 4.6 Miscellaneous messages
このカテゴリのメッセージは，上記のどのカテゴリにも当てはまらないが，それでもプロトコルの一部であり，要求されるものです．

#### 4.6.1 Kill message
```
Command   :  KILL
Parameters:  <nickname> <comment>
```

KILL メッセージは，クライアントとサーバの接続を，実際に接続しているサーバに閉じさせるために使用されます．KILL は，有効なニックネームのリストに重複したエントリがある場合に，サーバによって使用され，両方のエントリを削除するために使用されます．また，オペレータも利用することができます．

自動再接続のアルゴリズムを持っているクライアントは，切断が短時間であるため，このコマンドは事実上無意味です．しかし，データの流れを断ち切り，大量の不正使用を阻止するために使うことができます．どのユーザでも，他のユーザがトラブルスポットを ’監視’ するために生成された KILL メッセージを受け取ることを選択できます．

ニックネームは常にグローバルにユニークであることが要求されるため，’重複’（同じニックネームで2人のユーザを登録しようとすること）が検出されるたびにKILLメッセージが送られ，2人とも消えて1人だけが再び現れることが期待されるのです．

コメントには，KILL の実際の理由を反映させる必要があります．サーバが生成した KILL の場合は，通常，2 つの衝突するニックネームの起源に関する詳細が含まれます．ユーザの場合は，それを見た人が満足するような適切な理由を提供するように任されています．KILLer を隠すために偽の KILL が生成されるのを防ぐために，コメントには ’kill-path’ が表示され，通過する各サーバによってそのパスが更新され，それぞれのサーバ名が先頭に追加されます．

Numeric Replies:
```
    ERR_NOPRIVILEGES ERR_NEEDMOREPARAMS
    ERR_NOSUCHNICK ERR_CANTKILLSERVER
```

Examples:
```
KILL David (csd.bu.edu <- tolsun.oulu.fi)
        ; csd.bu.edu と tolson.oulu.fi の間のニックネームの衝突
```

NOTE:
オペレータだけが KILL メッセージで他のユーザを KILL することができるようにすることを推奨します．理想的な世界では，オペレータでさえもこれを行う必要はなく，サーバが対処することになるでしょう．

#### 4.6.2 Ping message
```
Command   :  PING
Parameters:  <server1> [<server2>]
```

PING メッセージは，接続の相手側にアクティブなクライアントが存在するかどうかをテストするために使用されます．PING メッセージは，接続から他のアクティビティが検出されない場合，一定の間隔で送信されます．接続が一定時間内に PING コマンドに応答しない場合，その接続は閉じられます．

PING メッセージを受け取ったクライアントは，できるだけ早く \<server1\>（PING メッセージを発信したサーバ）に適切な PONG メッセージで応答し，自分がまだそこにいて生きていることを示さなければなりません．サーバは PING コマンドに応答せず，接続の相手側からの PING に依存して，接続が生きていることを示さなければなりません．\<server2\> パラメータが指定された場合，PING メッセージはそこに転送されます．

Numeric Replies:
```
    ERR_NOORIGIN    ERR_NOSUCHSERVER
```

Examples:
```
PING tolsun.oulu.fi    ; サーバが他のサーバに PING メッセージを送信し，自分が生きていることを示します．
PING WiZ               ; ニックネーム WiZ に PING メッセージを送信します．
```

#### 4.6.3 Pong message
```
Command   :  PONG
Parameters:  <daemon> [<daemon2>]
```

PONG メッセージは，Ping メッセージに対する返信です．パラメータ \<daemon2\> が指定された場合，このメッセージは指定されたデーモンに転送されなければなりません．\<daemon\> パラメータには，PING メッセージに応答し，このメッセージを生成したデーモンの名前を指定します．

Numeric Replies:
```
    ERR_NOORIGIN    ERR_NOSUCHSERVER
```

Examples:
```
PONG csd.bu.edu tolsun.oulu.fi    ; csd.bu.edu から tolsun.oulu.fi への PONG メッセージ
```

#### 4.6.4 Error
```
Command   :  ERROR
Parameters:  <error message>
```

ERROR コマンドは，サーバが重大な，あるいは致命的なエラーをオペレータに報告するときに使用します．また，あるサーバから別のサーバに送信することもできますが，通常の未知のクライアントからは受け入れてはいけません．

ERROR メッセージは，サーバ間のリンクで発生したエラーを報告するためにのみ使用されます．ERROR メッセージは，相手側のサーバ（相手側のサーバは ERROR メッセージをその接続されているすべてのオペレータに送る）と，現在接続されているすべてのオペレータに送られます．サーバから受信した場合，サーバによって他のサーバに渡されることはありません．

サーバが受信した ERROR メッセージをそのオペレータに送るとき，メッセージは NOTICE メッセージの中にカプセル化され，クライアントがそのエラーに対して責任がないことを示すべきです．

Numerics:
```
    None.
```

Examples:
```
ERROR :Server *.fi already exists
		; このエラーを発生させた相手サーバへの ERROR メッセージ
NOTICE WiZ :ERROR from csd.bu.edu -- Server *.fi already exists
		; 上記と同じ ERROR メッセージが，相手サーバのユーザ WiZ に送信されます．
```

## 5. OPTIONALS
このセクションでは，OPTIONAL メッセージについて説明します．これらは，ここで説明するプロトコルの実用的なサーバ実装では必要ありません．オプションがない場合，エラー応答メッセージが生成されるか，未知のコマンドエラーが発生しなければなりません．もしメッセージが他のサーバに応答するよう意図されているなら，それは渡されなければなりません(初歩的なパースが必要です)．このために割り当てられた数値は，以下のメッセージとともにリストされています．

### 5.1 Away
```
Command   :  AWAY
Parameters:  [message]
```

AWAY メッセージにより，クライアントは自分宛の PRIVMSG コマンド（自分がいるチャネル宛ではない）に対して，自動返信文字列を設定することができます．自動応答は，PRIVMSG コマンドを送信するクライアントに対してサーバから送信されます．返信するサーバは，送信側クライアントが接続されているサーバのみです．

AWAY メッセージは1つのパラメータで使用する（AWAY メッセージを設定する）か，パラメータなしで使用する（AWAY メッセージを削除する）かを選択します．

Numeric Replies:
```
    RPL_UNAWAY    RPL_NOWAWAY
```

Examples:
```
AWAY :Gone to lunch. Back in 5    ; AWAY メッセージを "Gone to lunch.  Back in 5" に設定します．
:WiZ AWAY                         ; WiZ を AWAY としてマーク解除する．
```

### 5.2 Rehash message
```
Command   :  REHASH
Parameters:  None
```

rehashメッセージは，オペレータがサーバに設定ファイルの再読み込みと処理を強制するために使用することができます．

Numeric Replies:
```
    RPL_REHASHING    ERR_NOPRIVILEGES
```

Examples:
```
REHASH    ; オペレータの状態を示すクライアントからサーバにメッセージを送信し，サーバに設定ファイルの再読み込みを要求します．
```

### 5.3 Restart message
```
Command   :  RESTART
Parameters:  None
```

RESTART メッセージは，オペレータがサーバ自体を強制的に再起動させるためにのみ使用することができます．任意の人がオペレータとしてサーバに接続してこのコマンドを実行し，（少なくとも）サービスの停止を引き起こすことはリスクとみなされる可能性があるため，このメッセージはオプションとします．

RESTART コマンドは，常に送信側クライアントが接続しているサーバで完全に処理されなければならず，接続している他のサーバに渡されることはありません．

Numeric Replies:
```
    ERR_NOPRIVILEGES
```

Examples:
```
RESTART    ; パラメータは必要ありません．
```

### 5.4 Summon message
```
Command   :  SUMMON
Parameters:  <user> [<server>]
```

SUMMON コマンドは，IRC サーバを実行しているホストにいるユーザに，IRC に参加してくださいというメッセージを送るために使用することができます．このメッセージは，ターゲットサーバが (a) SUMMON を有効にしていて， (b) ユーザがログインしていて， (c) サーバプロセスがユーザの tty (または同様のもの) に書き込める場合にのみ送信されます．

\<server\> パラメータを指定しない場合，クライアントが接続しているサーバから \<user\> を呼び出そうとするものとします．

サーバで summon が有効でない場合，ERR_SUMMONDISABLED の数値を返し，summon メッセージを以降に渡さなければなりません．

Numeric Replies:
```
    ERR_NORECIPIENT    ERR_FILEERROR
    ERR_NOLOGIN        ERR_NOSUCHSERVER
    RPL_SUMMONING
```

Examples:
```
SUMMON jto                   ; サーバのホストでユーザ jto を召喚します．
SUMMON jto tolsun.oulu.fi    ; "tolsun.ulu.fi" という名前のサーバが稼働しているホストで，ユーザ jto を召喚します．
```

### 5.5 Users
```
Command   :  USERS
Parameters:  [<server>]
```

USERS コマンドは，who(1), rusers(1), finger(1) と同様のフォーマットで，サーバにログインしているユーザのリストを返します．人によっては，セキュリティ関連の理由から，サーバ上でこのコマンドを無効にしている場合があります．無効にした場合は，それを示すために正しい数値を返さなければなりません．

Numeric Replies:
```
    ERR_NOSUCHSERVER    ERR_FILEERROR
    RPL_USERSSTART      RPL_USERS
    RPL_NOUSERS         RPL_ENDOFUSERS
    ERR_USERSDISABLED
```

Disabled Reply:
```
    ERR_USERSDISABLED
```

Examples:
```
USERS eff.org                 ; サーバ eff.org にログインしているユーザのリストを要求します．
:John USERS tolsun.oulu.fi    ; John がサーバ tolsun.oulu.fi にログインしているユーザのリストを要求しています．
```

### 5.6 Operwall message
```
Command   :  WALLOPS
Parameters:  現在オンライン中の全オペレータに送信されるテキスト
```

現在オンライン中の全オペレータにメッセージを送信します．ユーザコマンドとして WALLOPS を実装した後，それが多くの人にメッセージを送る手段としてしばしば一般的に乱用されることがわかりました（WALL によく似ています）．このため，WALLOPS の現在の実装は，WALLOPS の送信者としてサーバだけを許可し，認識することによって，例として使用されることが推奨されます．

Numeric Replies:
```
    ERR_NEEDMOREPARAMS
```

Examples:
```
:csd.bu.edu WALLOPS :Connect ’*.uiuc.edu 6667’ from Joshua
        ; WALLOPS message from csd.bu.edu announcing a CONNECT message it received and acted upon from Joshua.
        ; csd.bu.edu からの WALLOPS メッセージは，Joshua から受信し対応した CONNECT メッセージを知らせています．
```

### 5.7 Userhost message
```
Command   :  USERHOST
Parameters:  <nickname>{<space><nickname>}
```

USERHOST コマンドはスペース文字で区切られた最大5つのニックネームのリストを受け取り，見つけたそれぞれのニックネームに関する情報のリストを返します．返されるリストには，それぞれの返答がスペースで区切られています．

Numeric Replies:
```
    RPL_USERHOST    ERR_NEEDMOREPARAMS
```

Examples:
```
USERHOST Wiz Michael Marty p
        ; ニックネーム "Wiz", "Michael", "Marty", "p" の情報に関する USERHOST リクエスト．
```

### 5.8 Ison message
```
Command   :  ISON
Parameters:  <nickname>{<space><nickname>}
```

ISON コマンドは，与えられたニックネームが現在 IRC 上にあるかどうかについての応答を得るための，迅速かつ効率的な手段を提供するために実装されました．ISON はスペースで区切られたニックネームのリストという，たった一つのパラメータを取ります．リスト中のそれぞれのニックネームが存在する場合，サーバはその応答文字列にそのニックネームを追加します．したがって，応答文字列は空 (与えられたニックネームが存在しない)，パラメータ文字列の完全なコピー (すべてのニックネームが存在する)，パラメータで与えられたニックネームのセットの他のサブセットを返すかもしれません．チェックするニックの数に関する唯一の制限は，サーバが512文字に収まるように切り捨てるほど，ニックの合計の長さが大きすぎてはいけないということです．

ISONは，コマンドを送信したクライアントのローカルサーバでのみ処理されるため，他のサーバに渡されてさらに処理されることはありません．

Numeric Replies:
```
    RPL_ISON    ERR_NEEDMOREPARAMS
```

Examples:
```
ISON phone trillian WiZ jarlek Avalon Angel Monstah    ; サンプル ISON は7つのニックをリクエストしています．
```

## 6. REPLIES
以下は，上記のコマンドに応答して生成される数値応答のリストです．各数値は，番号，名前，返信文字列で示されます．

### 6.1 Error Replies.
```
401    ERR_NOSUCHNICK
           "<nickname> :No such nick/channel"
       - コマンドに与えられたニックネームパラメータが現在未使用であることを示すために使用されます．

402    ERR_NOSUCHSERVER
           "<server name> :No such server"
       - 指定されたサーバ名が現在存在しないことを示すために使用されます．

403    ERR_NOSUCHCHANNEL
           "<channel name> :No such channel"
       - 与えられたチャネル名が無効であることを示すために使用されます．

404    ERR_CANNOTSENDTOCHAN
           "<channel name> :Cannot send to channel"
       - (a) モード +n が設定されているチャネルにいない，または (b) モード +m が設定されているチャネルのチャノップ (またはモード +v) でないユーザが，そのチャネルに PRIVMSG メッセージを送信しようとしたときに送信されます．

405    ERR_TOOMANYCHANNELS
           "<channel name> :You have joined too many channels"
       - ユーザが許可された最大数のチャネルに参加し，別のチャネルに参加しようとしたときに送信されます．

406    ERR_WASNOSUCHNICK
           "<nickname> :There was no such nickname"
       - WHOWAS により，そのニックネームの履歴情報がないことを示すために返されます．

407    ERR_TOOMANYTARGETS
           "<target> :Duplicate recipients. No message delivered"
       - PRIVMSG/NOTICE を user@host の宛先フォーマットで，user@host が複数存在する場合に送信しようとしたクライアントに返されます．

409    ERR_NOORIGIN
           ":No origin specified"
       - PING または PONG メッセージに originator パラメータがない．これらのコマンドは有効な接頭辞がないと動作しないため，必須です．

411    ERR_NORECIPIENT
           ":No recipient given (<command>)"

412    ERR_NOTEXTTOSEND
           ":No text to send"

413    ERR_NOTOPLEVEL
           "<mask> :No toplevel domain specified"

414    ERR_WILDTOPLEVEL
           "<mask> :Wildcard in toplevel domain"
       - 412 - 414は，何らかの理由でメッセージが届かなかったことを示すために PRIVMSG が返すものです．
         ERR_NOTOPLEVEL と ERR_WILDTOPLEVEL は "PRIVMSG $<server>" または "PRIVMSG #<host>" を不正に使用しようとしたときに返されるエラーです．

421    ERR_UNKNOWNCOMMAND
           "<command> :Unknown command"
       - 送信されたコマンドがサーバによって不明であることを示すために，登録されたクライアントに返されます．

422    ERR_NOMOTD
           ":MOTD File is missing"
       - サーバの MOTD ファイルを開くことができませんでした．

423    ERR_NOADMININFO
           "<server> :No administrative info available"
       - ADMIN メッセージの応答として，適切な情報の検索に失敗した場合にサーバから返されます．

424    ERR_FILEERROR
           ":File error doing <file op> on <file>"
       - メッセージの処理中にファイル操作の失敗を報告するために使用される一般的なエラーメッセージです．

431    ERR_NONICKNAMEGIVEN
           ":No nickname given"
       - コマンドに期待したニックネームパラメータが見つからなかった場合に返されます．

432    ERR_ERRONEUSNICKNAME
           "<nick> :Erroneus nickname"
       - 定義された文字セットに該当しない文字を含む NICK メッセージを受信した後に返されます．
         有効なニックネームの詳細については，セクションx.x.xを参照してください．

433    ERR_NICKNAMEINUSE
           "<nick> :Nickname is already in use"
       - NICK メッセージが処理された結果，現在存在するニックネームを変更しようとしたときに返されます．

436    ERR_NICKCOLLISION
           "<nick> :Nickname collision KILL"
       - ニックネームの衝突（他のサーバによってすでに存在するNICKの登録）を検出したときにサーバからクライアントに返されます．

441    ERR_USERNOTINCHANNEL
           "<nick> <channel> :They aren’t on that channel"
       - コマンドのターゲットユーザが指定されたチャネルにいないことを示すために，サーバから返されます．

442    ERR_NOTONCHANNEL
           "<channel> :You’re not on that channel"
       - クライアントがメンバーでないチャネルに影響を与えるコマンドを実行しようとしたときに，サーバから返されます．

443    ERR_USERONCHANNEL
           "<user> <channel> :is already on channel"
       - クライアントが，ユーザが既に参加しているチャネルに招待しようとしたときに返されます．

444    ERR_NOLOGIN
           "<user> :User not logged in"
       - あるユーザに対する SUMMON コマンドがログインしていないために実行できなかった場合に，summon から返されます．

445    ERR_SUMMONDISABLED
           ":SUMMON has been disabled"
       - SUMMON コマンドの応答として返されます．これを実装していないサーバは必ず返さなければなりません．

446    ERR_USERSDISABLED
           ":USERS has been disabled"
       - USERS コマンドの応答として返されます．これを実装していないサーバは必ず返さなければなりません．

451    ERR_NOTREGISTERED
           ":You have not registered"
       - サーバが返す値で，サーバが詳細な解析を許可する前にクライアントを登録する必要があることを示す．

461    ERR_NEEDMOREPARAMS
           "<command> :Not enough parameters"
       - サーバが多数のコマンドで返すもので，クライアントに十分なパラメータが供給されていないことを示す．

462    ERR_ALREADYREGISTRED
           ":You may not reregister"
       - 登録された情報の一部（パスワードや USER メッセージの2番目のユーザ情報など）を変更しようとするリンクに対して，サーバから返されます．

463    ERR_NOPERMFORHOST
           ":Your host isn’t among the privileged"
       - 接続しようとしたホストからの接続を許可するように設定されていないサーバに登録しようとしたクライアントに返されます．

464    ERR_PASSWDMISMATCH
           ":Password incorrect"
       - パスワードが要求された接続の登録に失敗したことを示すために返されるもので，パスワードが与えられなかったか，不正確であったためです．

465    ERR_YOUREBANNEDCREEP
           ":You are banned from this server"
       - 接続を明示的に拒否するように設定されたサーバに接続し，自分自身を登録しようとした後に返されます．

467    ERR_KEYSET
           "<channel> :Channel key already set"

471    ERR_CHANNELISFULL
           "<channel> :Cannot join channel (+l)"

472    ERR_UNKNOWNMODE
           "<char> :is unknown mode char to me"

473    ERR_INVITEONLYCHAN
           "<channel> :Cannot join channel (+i)"

474    ERR_BANNEDFROMCHAN
           "<channel> :Cannot join channel (+b)"

475    ERR_BADCHANNELKEY
           "<channel> :Cannot join channel (+k)"

481    ERR_NOPRIVILEGES
           ":Permission Denied- You’re not an IRC operator"
       - 操作にオペレータ権限が必要なコマンドは，試行に失敗したことを示すためにこのエラーを返さなければなりません．

482    ERR_CHANOPRIVSNEEDED
           "<channel> :You’re not channel operator"
       - chanop 権限を必要とするコマンド（MODEメッセージなど）は，試行するクライアントが指定されたチャネルの chanop でない場合，このエラーを返さなければなりません．

483    ERR_CANTKILLSERVER
           ":You cant kill a server!"
       - サーバ上で KILL コマンドを使用しようとすると，拒否され，このエラーが直接クライアントに返されます．

491    ERR_NOOPERHOST
           ":No O-lines for your host"
       - クライアントが OPER メッセージを送信し，サーバがクライアントのホストからの接続をオペレータとして許可するように設定されていない場合，このエラーを返さなければなりません．

501    ERR_UMODEUNKNOWNFLAG
           ":Unknown MODE flag"
       - ニックネームパラメータを持つ MODE メッセージが送信され，送信されたモードフラグが認識されなかったことを示すためにサーバによって返されます．

502    ERR_USERSDONTMATCH
           ":Cant change mode for other users"
       - 自分以外のユーザのユーザモードを表示または変更しようとしたユーザに送られるエラー．
```

### 6.2 Command responses.
```
300    RPL_NONE
           Dummy reply number. Not used.

302    RPL_USERHOST
           ":[<reply>{<space><reply>}]"
       - USERHOST がクエリリストの返信を一覧表示するために使用する返信フォーマットです．
         返信文字列は以下のように構成されます．
       <reply> ::= <nick>[’*’] ’=’ <’+’|’-’><hostname>
         ’*’ は，クライアントがオペレータとして登録されているかどうかを示す．
         ’-’ または ’+’ は，それぞれクライアントが AWAY メッセージを設定しているか否かを表す．

303    RPL_ISON
           ":[<nick> {<space><nick>}]"
       - ISON が問い合わせリストに対する返信を一覧表示するために使用する返信フォーマット．

301    RPL_AWAY
           "<nick> :<away message>"

305    RPL_UNAWAY
           ":You are no longer marked as being away"

306    RPL_NOWAWAY
           ":You have been marked as being away"
       - これらの応答は，AWAY コマンドと一緒に使用されます（許可されている場合）．
         RPL_AWAY は，離席しているクライアントに PRIVMSG を送信するすべてのクライアントに送信されます．
         RPL_AWAY は，クライアントが接続されているサーバによってのみ送信されます．
         応答 RPL_UNAWAY と RPL_NOWAWAY は，クライアントが AWAY メッセージを削除して設定するときに送信されます．

311    RPL_WHOISUSER
           "<nick> <user> <host> * :<real name>"

312    RPL_WHOISSERVER
           "<nick> <server> :<server info>"

313    RPL_WHOISOPERATOR
           "<nick> :is an IRC operator"

317    RPL_WHOISIDLE
           "<nick> <integer> :seconds idle"

318    RPL_ENDOFWHOIS
           "<nick> :End of /WHOIS list"

319    RPL_WHOISCHANNELS
           "<nick> :{[@|+]<channel><space>}"
       - 返信 311 - 313, 317 - 319 は，すべて WHOIS メッセージに応答して生成される返信です．
         十分な数のパラメータが存在する場合，応答サーバは上記の数値から応答を作成するか（クエリニックが見つかった場合），エラー応答を返す必要があります．
         RPL_WHOISUSER の ’*’ は，ワイルドカードとしてではなく，リテラル文字として存在します．
         各返事セットについて，RPL_WHOISCHANNELS だけが複数回現れるかもしれません(チャネル名の長いリストの場合)．
         チャネル名の横にある ’@’ と ’+’ の文字は，クライアントがチャネルオペレータであるか，モデレートされたチャネルで発言する許可を得ているかどうかを示します．
         RPL_ENDOFWHOIS 応答は，WHOIS メッセージの処理の終了をマークするために使用されます．

314    RPL_WHOWASUSER
           "<nick> <user> <host> * :<real name>"

369    RPL_ENDOFWHOWAS
           "<nick> :End of WHOWAS"
       - WHOWAS メッセージに返信するとき，サーバは提示されたリストの各ニックネームに対してRPL_WHOWASUSER，RPL_WHOISSERVER または ERR_WASNOSUCHNICK の返信を使用しなければなりません．
         すべてのリプライバッチの終わりに，RPL_ENDOFWHOWAS がなければなりません（リプライが1つだけで，それがエラーであったとしても）．

321    RPL_LISTSTART
           "Channel :Users Name"

322    RPL_LIST
           "<channel> <# visible> :<topic>"

323    RPL_LISTEND
           ":End of /LIST"
       - 返信 RPL_LISTSTART，RPL_LIST，RPL_LISTEND は，LIST コマンドに対するサーバの応答の開始，実際のデータによる返信，終了をマークします．
         返送可能なチャネルがない場合，開始と終了のリプライのみを送信する必要があります．

324    RPL_CHANNELMODEIS
           "<channel> <mode> <mode params>"

331    RPL_NOTOPIC
           "<channel> :No topic is set"

332    RPL_TOPIC
           "<channel> :<topic>"
       - チャネルのトピックを決定する TOPIC メッセージを送信する場合，2 つの返信のうち 1 つを送信します．
         トピックが設定されていれば，RPL_TOPIC が返送され，そうでなければ RPL_NOTOPIC が返送されます．

341    RPL_INVITING
           "<channel> <nick>"
       - 試行された INVITE メッセージが成功し，エンドクライアントに渡されることを示すためにサーバから返されます．

342    RPL_SUMMONING
           "<user> :Summoning user to IRC"
       - Returned by a server answering a SUMMON message to indicate that it is summoning that user.
       - SUMMON メッセージに応答したサーバが，そのユーザを呼び出していることを示すために返されます．

351    RPL_VERSION
           "<version>.<debuglevel> <server> :<comments>"
       - サーバがそのバージョンの詳細を示す返信です．
         <version> は使用中のソフトウェアのバージョン（パッチレベルリビジョンを含む），<debuglevel> はサーバが"デバッグモード"で動作しているかどうかを示すために使用されます．
         "コメント欄"には，バージョンに関するコメントや，さらなるバージョンに関する詳細情報を入力することができます．

352    RPL_WHOREPLY
           "<channel> <user> <host> <server> <nick> \
           <H|G>[*][@|+] :<hopcount> <real name>"

315    RPL_ENDOFWHO
           "<name> :End of /WHO list"
       - RPL_WHOREPLY と RPL_ENDOFWHO のペアは，WHO メッセージに答えるために使用されます．
         RPL_WHOREPLY は，WHO クエリに適切なマッチがある場合にのみ送信されます．
         WHO メッセージで供給されるパラメータのリストがある場合，<name> を項目とする各リスト項目を処理した後に RPL_ENDOFWHO を送信する必要があります．

353    RPL_NAMREPLY
           "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]"

366    RPL_ENDOFNAMES
           "<channel> :End of /NAMES list"
       - NAMES メッセージに返信するために，RPL_NAMREPLY と RPL_ENDOFNAMES からなる返信ペアがサーバからクライアントに返送されます．
         クエリのように見つかったチャネルがない場合，RPL_ENDOFNAMES だけが返されます．
         この例外は，NAMES メッセージがパラメータなしで送信され，すべての可視チャネルとコンテンツが一連の RPL_NAMEREPLY メッセージで送り返され，RPL_ENDOFNAMES で終了をマークする場合です．

364    RPL_LINKS
           "<mask> <server> :<hopcount> <server info>"

365    RPL_ENDOFLINKS
           "<mask> :End of /LINKS list"
       - LINKS メッセージに返信する際，サーバは RPL_LINKS 数値を使用して返信を送り，RPL_ENDOFLINKS 返信を使用してリストの終わりをマークしなければなりません．

367    RPL_BANLIST
           "<channel> <banid>"

368    RPL_ENDOFBANLIST
           "<channel> :End of channel ban list"
       - 特定のチャネルのアクティブな’バン’をリストアップする場合，サーバは RPL_BANLIST と RPL_ENDOFBANLIST メッセージを使用してリストを送り返すことが要求されます．
         アクティブな BANID ごとに個別の RPL_BANLIST が送信されます．
         banids がリストアップされた後（または1つも存在しない場合），RPL_ENDOFBANLIST を送信する必要があります．

371    RPL_INFO
           ":<string>"

374    RPL_ENDOFINFO
           ":End of /INFO list"
       - INFO メッセージに応答するサーバは，そのすべての ’info’ を一連の RPL_INFO メッセージで送信し，返信の終わりを示すために RPL_ENDOFINFO 返信をすることが要求されます．

375    RPL_MOTDSTART
           ":- <server> Message of the day - "

372    RPL_MOTD
           ":- <text>"

376    RPL_ENDOFMOTD
           ":End of /MOTD command"
       - MOTD メッセージに応答し，MOTD ファイルが見つかった場合，RPL_MOTD 形式の返信で，1行80文字以内でファイルを表示します．
         これらは RPL_MOTDSTART（RPL_MOTD の前）と RPL_ENDOFMOTD（後）で囲む必要があります．

381    RPL_YOUREOPER
           ":You are now an IRC operator"
       - RPL_YOUREOPER は，OPER メッセージを正常に発行し，オペレータ・ステータスを得たばかりのクライアントに返送されます．

382    RPL_REHASHING
           "<config file> :Rehashing"
       - REHASH オプションが使用され，オペレータが REHASH メッセージを送信する場合，RPL_REHASHING がオペレータに返送されます．

391    RPL_TIME
           "<server> :<string showing server’s local time>"
       - TIME メッセージに返信する場合，サーバは上記の RPL_TIME 形式を使用して返信を送信する必要があります．
         時刻を示す文字列は，そこに正しい曜日と時刻を含むだけでよいです．
         時刻を示す文字列には，それ以上の要件はありません．

392    RPL_USERSSTART
           ":UserID Terminal Host"

393    RPL_USERS
           ":%-8s %-9s %-8s"

394    RPL_ENDOFUSERS
           ":End of users"

395    RPL_NOUSERS
           ":Nobody logged in"
       - USERS メッセージがサーバによって処理される場合，応答 RPL_USERSTART，RPL_USERS，RPL_ENDOFUSERS，RPL_NOUSERS が使用されます．
         RPL_USERSSTART を最初に送信し，その後に一連の RPL_USERS または単一の RPL_NOUSER のいずれかを送信する必要があります．
         これに続くのは RPL_ENDOFUSERS です．

200    RPL_TRACELINK
           "Link <version & debug level> <destination> <next server>"

201    RPL_TRACECONNECTING
           "Try. <class> <server>"

202    RPL_TRACEHANDSHAKE
           "H.S. <class> <server>"

203    RPL_TRACEUNKNOWN
           "???? <class> [<client IP address in dot form>]"

204    RPL_TRACEOPERATOR
           "Oper <class> <nick>"

205    RPL_TRACEUSER
           "User <class> <nick>"

206    RPL_TRACESERVER
           "Serv <class> <int>S <int>C <server> <nick!user|*!*>@<host|server>"

208    RPL_TRACENEWTYPE
           "<newtype> 0 <client name>"

261    RPL_TRACELOG
           "File <logfile> <debug level>"
       - RPL_TRACE* は，すべて TRACE メッセージに応答してサーバから返されます．
         いくつ返されるかは，TRACE メッセージとそれがオペレータによって送信されたかどうかに依存します．
         どちらが先に発生するか，あらかじめ定義された順序はありません．
         応答 RPL_TRACEUNKNOWN，RPL_TRACECONNECTING，RPL_TRACEHANDSHAKE はすべて，完全に確立されていない接続，不明，まだ接続しようとしている，または’サーバハンドシェイク’の完了プロセスのいずれかに使用されるものです．
         RPL_TRACELINK は，TRACE メッセージを処理し，それを別のサーバに渡す必要があるすべてのサーバによって送信されます．
         IRC ネットワークを横断する TRACE コマンドに応答して送信される RPL_TRACELINK のリストは，そのパスに沿ったサーバ自身の実際の接続性を反映する必要があります．
         RPL_TRACENEWTYPE は，他のカテゴリに当てはまらないが，とにかく表示されている接続に使用されるものです．

211    RPL_STATSLINKINFO
           "<linkname> <sendq> <sent messages> <sent bytes> <received messages> <received bytes> <time open>"

212    RPL_STATSCOMMANDS
           "<command> <count>"

213    RPL_STATSCLINE
           "C <host> * <name> <port> <class>"

214    RPL_STATSNLINE
           "N <host> * <name> <port> <class>"

215    RPL_STATSILINE
           "I <host> * <host> <port> <class>"

216    RPL_STATSKLINE
           "K <host> * <username> <port> <class>"

218    RPL_STATSYLINE
           "Y <class> <ping frequency> <connect frequency> <max sendq>"

219    RPL_ENDOFSTATS
           "<stats letter> :End of /STATS report"

241    RPL_STATSLLINE
           "L <hostmask> * <servername> <maxdepth>"

242    RPL_STATSUPTIME
           ":Server Up %d days %d:%02d:%02d"

243    RPL_STATSOLINE
           "O <hostmask> * <name>"

244    RPL_STATSHLINE
           "H <hostmask> * <servername>"

221    RPL_UMODEIS
           "<user mode string>"
       - クライアント自身のモードに関する問い合わせに答えるために，RPL_UMODEIS が返送されます．

251    RPL_LUSERCLIENT
           ":There are <integer> users and <integer> invisible on <integer> servers"

252    RPL_LUSEROP
           "<integer> :operator(s) online"

253    RPL_LUSERUNKNOWN
           "<integer> :unknown connection(s)"

254    RPL_LUSERCHANNELS
           "<integer> :channels formed"

255    RPL_LUSERME
           ":I have <integer> clients and <integer> servers"
       - LUSERS メッセージの処理では，サーバは RPL_LUSERCLIENT，RPL_LUSEROP，RPL_USERUNKNOWN，RPL_LUSERCHANNELSおよびRPL_LUSERMEから一式の応答を送信します．
         返信するとき，サーバは RPL_LUSERCLIENT と RPL_LUSERME を送り返さなければなりません．
         他の返信は，それらにゼロでないカウントが見つかった場合にのみ送り返されます．

256    RPL_ADMINME
           "<server> :Administrative info"

257    RPL_ADMINLOC1
           ":<admin info>"

258    RPL_ADMINLOC2
           ":<admin info>"

259    RPL_ADMINEMAIL
           ":<admin info>"
       - ADMIN メッセージに返信する場合，サーバは RLP_ADMINME から RPL_ADMINEMAIL までの返信を使用し，それぞれテキストメッセージを提供することが期待されています．
         RPL_ADMINLOC1 には，サーバがある都市，州，国の説明が期待され，次に大学と学科の詳細（RPL_ADMINLOC2），最後に RPL_ADMINEMAIL にサーバの管理連絡先（ここに電子メールアドレスが必要です）が求められます．
```

### 6.3 Reserved numerics.
これらの数値は，以下のいずれかに該当するため，上記では説明しません．

1. もう使用されていない．
2. 将来の使用のために予約されている．
3. 現在使用されているが，現在の IRC サーバの一般的でない’機能’の一部である．

```
209    RPL_TRACECLASS         217    RPL_STATSQLINE
231    RPL_SERVICEINFO        232    RPL_ENDOFSERVICES
233    RPL_SERVICE            234    RPL_SERVLIST
235    RPL_SERVLISTEND
316    RPL_WHOISCHANOP        361    RPL_KILLDONE
362    RPL_CLOSING            363    RPL_CLOSEEND
373    RPL_INFOSTART          384    RPL_MYPORTIS
466    ERR_YOUWILLBEBANNED    476    ERR_BADCHANMASK
492    ERR_NOSERVICEHOST
```

## 7. Client and server authentication
クライアントもサーバも同じレベルの認証が行われます．両者とも，サーバへのすべての接続について，IP 番号とホスト名のルックアップ（およびこの逆チェック）が実行されます．その後，両方の接続に対してパスワードチェックが行われます (その接続にパスワードが設定されている場合)．これらのチェックはすべての接続で可能ですが，パスワードチェックはサーバでのみ一般的に使用されます．

さらに，最近増えているのが，接続に使用したユーザ名のチェックです．接続の相手側のユーザ名を見つけるには，通常，RFC1413 に記載されている IDENT などの認証サーバに接続する必要があります．

パスワードがなければ，ネットワーク接続の相手方を確実に特定することは容易ではないため，サーバ間接続では，ID サーバの使用などの対策に加え，パスワードの使用を強く推奨します．

## 8. Current implementations
このプロトコルの現在の実装は，IRCサーバのバージョン2.8のみです．それ以前のバージョンでは，このドキュメントで説明されているコマンドの一部または全部を，数値応答の多くを NOTICE メッセージに置き換えて実装しているかもしれません．残念ながら，後方互換性の要求のために，この文書のいくつかの部分の実装は，レイアウトされたものと異なっています．顕著な違いとしては

* メッセージ内の任意の LF または CR がそのメッセージの終わりを示すという認識（CR-LFを要求する代わりに）．

このセクションの残りの部分は，主にサーバを実装しようとする人にとって重要な問題を扱っていますが，いくつかの部分はクライアントにも直接適用されます．

### 8.1 Network protocol: TCP - why it is best used here.
IRC は，TCP がこの規模の会議に適した信頼性の高いネットワークプロトコルを提供しているため，TCP の上に実装されています．マルチキャスト IP の利用も考えられるが，現時点では広く普及し ておらず，サポートされていません．

#### 8.1.1 Support of Unix sockets
Unilx ドメインソケットはリスン/コネクト操作が可能であることから，現在の実装では，Unix ドメインソケット上でクライアントとサーバの両方の接続をリスンして受け入れるように設定することができます．これは，ホスト名が ’/’ で始まるソケットとして認識されます．

Unix ドメインソケットの接続に関する情報を提供する場合，実際のソケット名を要求されない限り，サーバはパス名の代わりに実際のホスト名を指定する必要があります．

### 8.2 Command Parsing
クライアントとサーバに便利な’非バッファード’ネットワークIOを提供するために，各接続には専用の’入力バッファ’が与えられ，最新の読み取りと解析の結果が保持されます．バッファのサイズは512バイトで，1つの完全なメッセージを保持することができます．プライベートバッファは，有効なメッセージの読み取り操作のたびに解析されます．一つのクライアントからの複数のメッセージをバッファで扱う場合，あるメッセージによってクライアントが’削除’されることがないように注意する必要があります．

### 8.3 Message delivery
ネットワークリンクが飽和したり，データ送信先のホストがデータ送信できなくなることはよくあることです．Unix は通常，TCP ウィンドウと内部バッファによってこれを処理しますが， サーバはしばしば大量の送信データを持ち（特に新しいサーバとサーバのリンクが形成されたとき）， カーネルで提供される小さなバッファでは送信キューに十分ではありません．この問題を軽減するために，送信するデータの FIFO キューとして"送信キュー"が使用されます．典型的な"送信キュー"は，新しいサーバが接続するとき，遅いネットワーク接続を持つ大きな IRC ネットワーク上で200Kバイトに成長するかもしれません．

接続をポーリングする際，サーバはまず受信データをすべて読み込んで解析し，送信すべきデータがあればキューに入れます．利用可能なすべての入力が処理されると，キューに入れられたデータが送信されます．これにより，write() システムコールの回数が減り，TCP がより大きなパケットを作成できるようになります．

### 8.4 Connection ’Liveness’
接続が切れたり応答しなくなったりしたことを検知するために，サーバは一定時間内に応答がない接続に対してそれぞれ ping を打つ必要があります．

接続が時間内に応答しない場合，その接続は適切な手順で閉じられます．サーバプロセスがブロックされるよりも遅い接続を閉じる方が良いので，sendq が許容範囲を超えて大きくなった場合にも，接続は切断されます．

### 8.5 Establishing a server to client connection
IRC サーバに接続すると，LUSER コマンドにより，MOTD と現在のユーザ/サーバ数がクライアントに送信されます．また，サーバはクライアントに対して，サーバ名とバージョン，その他適切と思われる紹介メッセージを明確に伝えることが要求されます．

これを処理した後，サーバは新しいユーザのニックネームやその他の情報を自分自身（USER コマンド）で提供したり，サーバが DNS/認証サーバから発見したものを送信する必要があります．サーバは，この情報を NICK の後に USER を付けて送信しなければなりません．

### 8.6 Establishing a server-server connection.
サーバ間の接続は，競合状態をはじめ，さまざまな問題が発生する可能性があるため，危険と隣り合わせのプロセスです．

サーバは，有効であると認識された PASS/SERVER のペアに続く接続を受け取った後，その接続のための自身の PASS/SERVER 情報と，以下に述べるように知っている他のすべての状態情報を返信する必要があります．

開始サーバは PASS/SERVER のペアを受け取ると，応答したサーバが適切に認証されていることを確認した上で，そのサーバへの接続を受け入れます．

#### 8.6.1 Server exchange of state information when connecting
サーバ間で交換される状態情報の順序が重要です．必要な順序は以下の通りです．

* 他のすべての既知のサーバ
* すべての既知のユーザ情報
* すべての既知のチャネル情報

サーバに関する情報は SERVER メッセージ，ユーザ情報は NICK/USER/MODE/JOIN メッセージ，チャネルは MODE メッセージで追加送信されます．

NOT: TOPIC コマンドは古いトピック情報を上書きするため，ここではチャネルトピックは交換されず，せいぜい接続の両側がトピックを交換する程度です．

サーバの状態情報を先に渡すことで，第二サーバが特定のニックネームを導入することによるニックネームの衝突よりも先に，既に存在するサーバとの衝突が発生します．IRC ネットワークは非循環グラフとしてしか存在できないため，ネットワークがすでに別の場所で再接続されている可能性があり，衝突が発生した場所はネットを分割する必要がある場所であることを示しています．

### 8.7 Terminating server-client connections
クライアント接続が終了すると，そのクライアントが接続したサーバがクライアントに代わって QUIT メッセージを生成します．他のメッセージは生成されず，使用されません．

### 8.8 Terminating server-server connections
サーバとサーバの接続が，リモートで生成された SQUIT または’自然な’原因によって閉じられた場合，接続されている残りのIRCネットワークは，閉鎖を検出したサーバによってその情報が更新されなければなりません．サーバは，SQUIT のリスト(その接続の背後にある各サーバについて1つ)とQUITのリスト(再び，その接続の背後にある各クライアントについて1つ)を送信します．

### 8.9 Tracking nickname changes
すべての IRC サーバは最近のニックネームの変更履歴を保持することが要求されます．これは，ニックネームを操作するコマンドでニックネーム変更の競合状態が発生したときに，サーバが状況を把握する機会を持つために必要です．ニックネームの変更を追跡しなければならないコマンドは以下の通りです．

* KILL（キルされるニックネーム）
* MODE（+/- o,v）
* KICK（キックされるニックネーム）

他のコマンドは，ニックネームの変更をチェックさせません．

上記の場合，サーバはまずニックネームの存在を確認し，次にそのニックネームが現在誰に属しているかを確認するために履歴をチェックする必要があります (もし誰かいればですが!)．これは競合状態の可能性を減らしますが，サーバが間違ったクライアントに影響を及ぼしてしまうということはまだ起こり得ます．上記のコマンドで変更履歴を調べるときは，時間範囲を指定し，古すぎるエントリは無視することをお勧めします．

合理的な履歴のために，サーバは，すべてのクライアントが変更することを決めた場合，サーバが知っているすべてのクライアントのために前のニックネームを保持することができるはずです．このサイズは他の要因(例えばメモリなど)によって制限されます．

### 8.10 Flood control of clients
IRC サーバが相互に接続された大規模なネットワークでは，ネットワークに接続している任意の1つのクライアントが連続的にメッセージを供給することは非常に簡単で，その結果，ネットワークが氾濫するだけでなく，他のクライアントに提供するサービスのレベルを低下させることになるのです．大量リクエスト対策は，すべての’犠牲者’に独自の対策を要求するのではなく，サーバに書き込まれ，サービスを除くすべてのクライアントに適用されます．現在のアルゴリズムは以下の通りである．

* クライアントの‘メッセージタイマー‘が現在の時刻より小さいかどうかを確認します（小さい場合は等しくなるように設定します）．
* クライアントから存在するあらゆるデータを読み取ります．
* タイマーが現在時刻より10秒以上進んでいる間に，現在のメッセージを解析し，メッセージごとにクライアントに2秒のペナルティーを課します．

これは要するに，クライアントが2秒に1回メッセージを送信しても悪影響がないことを意味します．

### 8.11 Non-blocking lookups
リアルタイム環境では，すべてのクライアントに公平にサービスを提供するために，サーバプロセスができるだけ待機しないことが重要です．このためには，ネットワーク上のすべての読み取り/書き込み操作において，ノンブロッキング IO が必要であることは明らかです．通常のサーバ接続では，これは難しいことではありませんでしたが，サーバがブロックする可能性がある他のサポート操作（ディスク読み取りなど）があります．可能であれば，そのような動作は短いタイムアウトで実行されるべきです．

#### 8.11.1 Hostname (DNS) lookups
Berkeley などの標準的なリゾルバライブラリを使用すると，返信がタイムアウトになるケースがあり，大きな遅延が発生しました．これを避けるために，DNS ルーチンの別セットが書かれました．これは，ノンブロッキング IO オペレーション用にセットアップされ，メインサーバの IO ループの中からポーリングされます．

#### 8.11.2 Username (Ident) lookups
他のプログラムに組み込んで使用するための ident ライブラリは数多く存在しますが，これらは同期的に動作するため，遅延が頻繁に発生するという問題がありました．この場合も，サーバの他の部分と協調し，ノンブロッキング IO で動作するルーチン群を書くことが解決策となりました．

### 8.12 Configuration File
サーバの設定や運用を柔軟に行うために，以下のようなサーバへの指示を含む設定ファイルを使用することが推奨されます．

* クライアントからの接続を受け付けるホストを指定します．
* サーバとして接続を許可するホストを指定します．
* サーバとして接続を許可するホストを指定します．
* どのホストに接続するか（アクティブおよびパッシブの両方）．
* サーバがどこにあるかという情報（大学，都市／州，会社がその例です）．
* サーバの責任者と連絡可能な電子メールアドレス．
* 制限されたオペレータコマンドへのアクセスを希望するクライアントのホスト名とパスワード．

ホスト名の指定は，ドメイン名とドット表記（127.0.0.1）の両方が可能である必要があります．送信および受信のすべての接続で使用/受信するパスワードを指定できるようにしなければなりません（ただし，送信接続は他のサーバへの接続のみ）．

上記のリストは，他のサーバとの接続を希望するサーバに最低限必要なものです．その他，参考になる項目は以下の通りです．

* 他のサーバが導入できるサーバを指定する．
* サーバの分岐をどこまで深くするか．
* クライアントが接続可能な時間帯

#### 8.12.1 Allowing clients to connect
サーバは，起動時に読み込まれるある種の’アクセス制御リスト’（設定ファイルまたはその他の場所）を使用して，クライアントが接続するために使用するホストを決定する必要があります．

ホストアクセス制御に必要な柔軟性を提供するために，’deny’ と ’allow’ の両方を実装する必要があります．

#### 8.12.2 Operators
破壊的な人物にオペレータの特権を与えることは，その人物に与えられた権限によって，IRC ネット全般の幸福に悲惨な結果をもたらす可能性があります．したがって，そのような権限の取得は非常に簡単であってはなりません．現在の設定では，2つの ’パスワード’ が必要ですが，そのうちの1つは通常簡単に推測されます．オペレーティングシステムのパスワードを設定ファイルに保存することは，ハードコーディングするよりも望ましく，簡単に盗まれないように暗号化されたフォーマットで保存されるべきです (例えば，Unix の crypt(3) を使用します)．

#### 8.12.3 Allowing servers to connect
サーバの相互接続は些細なことではありません．接続不良は IRC の有用性に大きな影響を与える可能性があります．したがって，各サーバは接続できるサーバのリストと，どのサーバがそれに接続できるかのリストを持つべきです．どんな場合でも，サーバは任意のホストがサーバとして接続することを許可してはいけません．どのサーバが接続できて，どのサーバが接続できないかに加えて，設定ファイルにはそのリンクのパスワードや他の特性も保存されるべきです．

#### 8.12.4 Administrivia
ADMIN コマンド（[4.3.7 Admin command](#437-admin-command) 項参照）に対して正確で有効な返答をするために，サーバは設定から関連する詳細を見つけ出す必要があります．

### 8.13 Channel membership
現在のサーバでは，登録したローカルユーザが最大10個の異なるチャネルに参加することができます．非ローカルユーザには制限がないため，サーバはチャネルメンバーシップに関して他のすべてのユーザと（合理的に）一貫性を保つことができます．

## 9. Current problems
このプロトコルにはいくつかの問題があるとされており，近い将来，書き換えの際に解決されることが期待されています．現在，これらの問題に対する実用的な解決策を見つけるための作業が進行中です．

### 9.1 Scalability
このプロトコルは，大規模な舞台で使用する場合，十分にスケールしないことが広く認識されています．主な問題は，すべてのサーバが他のすべてのサーバとユーザについて知っており，それらに関する情報が変更されるとすぐに更新されるという要件から来るものです．また，任意の2点間の経路長が最小に保たれ，スパニングツリーができるだけ強く分岐するように，サーバの数を少なくすることが望まれます．

### 9.2 Labels
現在のIRCプロトコルには，ニックネーム，チャネル名，サーバ名の3種類のラベルがあります．3つのタイプはそれぞれ独自のドメインを持っており，そのドメイン内では重複が許されません． 現状では，ユーザが3種類のラベルのどれかを選ぶことが可能であり，その結果，衝突が発生しています．チャネル名とニックネームが衝突しないような一意な名前にする計画や，サイクリック・ツリーを可能にするソリューションが望ましいと広く認識されています．

#### 9.2.1 Nicknames
IRC におけるニックネームの考え方は，ユーザがチャネル外で会話する際に非常に便利ですが，ニックネームのスペースは有限であり，複数の人が同じニックネームを使いたいと思うことは珍しいことではありません．もしこのプロトコルを使って二人がニックネームを選んだ場合，どちらかが成功しないか，KILL ([4.6.1 Kill message](#461-kill-message)) を使うことで両方が削除されるでしょう．

#### 9.2.2 Channels
現在のチャネルレイアウトでは，すべてのサーバがすべてのチャネル，その住人，プロパティについて知っている必要があります．うまく拡張できないことに加えて，プライバシーの問題も懸念されます．チャネルの衝突は，ニックネームの衝突を解決するために使用されるような排他的なものではなく，新しいチャネルを作成した両方の人々がそのメンバーであるとみなされる包括的なイベントとして扱われます．

#### 9.2.3 Servers
サーバの数は通常，ユーザやチャネルの数に比べて少ないのですが，現在，2つのサーバはそれぞれ個別に，またはマスクの後ろに隠されて，グローバルに知られていることが要求されています．

###  9.3 Algorithms
サーバコード内のいくつかの場所では，クライアントのセットのチャネルリストをチェックするようなN^2アルゴリズムを回避することができませんでした．

現在のサーバのバージョンでは，データベースの整合性チェックがなく，各サーバは隣接するサーバが正しいことを前提にしています．そのため，接続先のサーバがバグっていたり，既存のネットに矛盾を持ち込もうとしたりすると，大きな問題が発生する可能性があります．

現在，内部およびグローバルラベルが一意でないため，多数の競合状態が存在します．これらの競合状態は，一般に，メッセージが IRC ネットワークを横断して影響を及ぼすのに時間がかかるという問題から発生します．一意なラベルに変更することによっても，チャネル関連のコマンドが中断される問題があります．
