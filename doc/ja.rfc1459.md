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
    + [8.11.1 Hostname (DNS) lookups](#8111-hostname--dns--lookups)
    + [8.11.2 Username (Ident) lookups](#8112-username--ident--lookups)
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
クライアントとは，他のサーバではないサーバに接続するものです．各クライアントは，最大9文字のユニークなニックネームによって他のクライアントと区別されます．ニックネームに使用できるもの，できないものについては，プロトコルの文法規則を参照してください．ニックネームに加えて，全てのサーバは全てのクライアントに関する以下の情報を 持っていなければなりません: クライアントが動作しているホストの実名，そのホスト上でのクライアントの ユーザ名，クライアントが接続しているサーバ．

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
このメッセージ群は，チャネル，そのプロパティ（チャネルモード），およびそのコンテンツ（通常はクライアント）を操作することに関係しています． これらの実装では，ネットワークの反対側の端にいるクライアントがコマンドを送ると，最終的に衝突してしまうため，多くのレースコンディションが避けられない．また，パラメータが与えられると，それが最近変更された場合に備えてサーバがその履歴をチェックすることを確実にするために，サーバがニックネームの履歴を保持することが要求されます．

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
The following is a list of numeric replies which are generated in response to the commands given above. Each numeric is given with its number, name and reply string.

### 6.1 Error Replies.
```
401    ERR_NOSUCHNICK
           "<nickname> :No such nick/channel"
       - Used to indicate the nickname parameter supplied to a command is currently unused.
402    ERR_NOSUCHSERVER
           "<server name> :No such server"
       - Used to indicate the server name given currently doesn’t exist.
403    ERR_NOSUCHCHANNEL
           "<channel name> :No such channel"
       - Used to indicate the given channel name is invalid.
404    ERR_CANNOTSENDTOCHAN
           "<channel name> :Cannot send to channel"
       - Sent to a user who is either (a) not on a channel which is mode +n or (b) not a chanop (or mode +v) on a channel which has mode +m set and is trying to send a PRIVMSG message to that channel.
405    ERR_TOOMANYCHANNELS
           "<channel name> :You have joined too many channels"
       - Sent to a user when they have joined the maximum number of allowed channels and they try to join another channel.
406    ERR_WASNOSUCHNICK
           "<nickname> :There was no such nickname"
       - Returned by WHOWAS to indicate there is no history information for that nickname.
407    ERR_TOOMANYTARGETS
           "<target> :Duplicate recipients. No message delivered"
       - Returned to a client which is attempting to send a PRIVMSG/NOTICE using the user@host destination format and for a user@host which has several occurrences.
409    ERR_NOORIGIN
           ":No origin specified"
       - PING or PONG message missing the originator parameter which is required since these commands must work without valid prefixes.
411    ERR_NORECIPIENT
           ":No recipient given (<command>)"
412    ERR_NOTEXTTOSEND
           ":No text to send"
413    ERR_NOTOPLEVEL
           "<mask> :No toplevel domain specified"
414    ERR_WILDTOPLEVEL
           "<mask> :Wildcard in toplevel domain"
       - 412 - 414 are returned by PRIVMSG to indicate that the message wasn’t delivered for some reason.  ERR_NOTOPLEVEL and ERR_WILDTOPLEVEL are errors that are returned when an invalid use of "PRIVMSG $<server>" or "PRIVMSG #<host>" is attempted.
421    ERR_UNKNOWNCOMMAND
           "<command> :Unknown command"
       - Returned to a registered client to indicate that the command sent is unknown by the server.
422    ERR_NOMOTD
           ":MOTD File is missing"
       - Server’s MOTD file could not be opened by the server.
423    ERR_NOADMININFO
           "<server> :No administrative info available"
       - Returned by a server in response to an ADMIN message when there is an error in finding the appropriate information.
424    ERR_FILEERROR
           ":File error doing <file op> on <file>"
       - Generic error message used to report a failed file operation during the processing of a message.
431    ERR_NONICKNAMEGIVEN
           ":No nickname given"
       - Returned when a nickname parameter expected for a command and isn’t found.
432    ERR_ERRONEUSNICKNAME
           "<nick> :Erroneus nickname"
       - Returned after receiving a NICK message which contains characters which do not fall in the defined set. See section x.x.x for details on valid nicknames.
433    ERR_NICKNAMEINUSE
           "<nick> :Nickname is already in use"
       - Returned when a NICK message is processed that results in an attempt to change to a currently existing nickname.
436    ERR_NICKCOLLISION
           "<nick> :Nickname collision KILL"
       - Returned by a server to a client when it detects a nickname collision (registered of a NICK that already exists by another server).
441    ERR_USERNOTINCHANNEL
           "<nick> <channel> :They aren’t on that channel"
       - Returned by the server to indicate that the target user of the command is not on the given channel.
442    ERR_NOTONCHANNEL
           "<channel> :You’re not on that channel"
       - Returned by the server whenever a client tries to perform a channel effecting command for which the client isn’t a member.
443    ERR_USERONCHANNEL
           "<user> <channel> :is already on channel"
       - Returned when a client tries to invite a user to a channel they are already on.
444    ERR_NOLOGIN
           "<user> :User not logged in"
       - Returned by the summon after a SUMMON command for a user was unable to be performed since they were not logged in.
445    ERR_SUMMONDISABLED
           ":SUMMON has been disabled"
       - Returned as a response to the SUMMON command. Must be returned by any server which does not implement it.
446    ERR_USERSDISABLED
           ":USERS has been disabled"
       - Returned as a response to the USERS command. Must be returned by any server which does not implement it.
451    ERR_NOTREGISTERED
           ":You have not registered"
       - Returned by the server to indicate that the client must be registered before the server will allow it to be parsed in detail.
461    ERR_NEEDMOREPARAMS
           "<command> :Not enough parameters"
       - Returned by the server by numerous commands to indicate to the client that it didn’t supply enough parameters.
462    ERR_ALREADYREGISTRED
           ":You may not reregister"
       - Returned by the server to any link which tries to change part of the registered details (such as password or user details from second USER message).
463    ERR_NOPERMFORHOST
           ":Your host isn’t among the privileged"
       - Returned to a client which attempts to register with a server which does not been setup to allow connections from the host the attempted connection is tried.
464    ERR_PASSWDMISMATCH
           ":Password incorrect"
       - Returned to indicate a failed attempt at registering a connection for which a password was required and was either not given or incorrect.
465    ERR_YOUREBANNEDCREEP
           ":You are banned from this server"
       - Returned after an attempt to connect and register yourself with a server which has been setup to explicitly deny connections to you.
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
       - Any command requiring operator privileges to operate must return this error to indicate the attempt was unsuccessful.
482    ERR_CHANOPRIVSNEEDED
           "<channel> :You’re not channel operator"
       - Any command requiring ’chanop’ privileges (such as MODE messages) must return this error if the client making the attempt is not a chanop on the specified channel.
483    ERR_CANTKILLSERVER
           ":You cant kill a server!"
       - Any attempts to use the KILL command on a server are to be refused and this error returned directly to the client.
491    ERR_NOOPERHOST
           ":No O-lines for your host"
       - If a client sends an OPER message and the server has not been configured to allow connections from the client’s host as an operator, this error must be returned.
501    ERR_UMODEUNKNOWNFLAG
           ":Unknown MODE flag"
       - Returned by the server to indicate that a MODE message was sent with a nickname parameter and that the a mode flag sent was not recognized.
502    ERR_USERSDONTMATCH
           ":Cant change mode for other users"
       - Error sent to any user trying to view or change the user mode for a user other than themselves.
```

### 6.2 Command responses.
```
300    RPL_NONE
           Dummy reply number. Not used.
302    RPL_USERHOST
           ":[<reply>{<space><reply>}]"
       - Reply format used by USERHOST to list replies to the query list. The reply string is composed as follows:
       <reply> ::= <nick>[’*’] ’=’ <’+’|’-’><hostname>
       The ’*’ indicates whether the client has registered as an Operator. The ’-’ or ’+’ characters represent whether the client has set an AWAY message or not respectively.
303    RPL_ISON
           ":[<nick> {<space><nick>}]"
       - Reply format used by ISON to list replies to the query list.
301    RPL_AWAY
           "<nick> :<away message>"
305    RPL_UNAWAY
           ":You are no longer marked as being away"
306    RPL_NOWAWAY
           ":You have been marked as being away"
       - These replies are used with the AWAY command (if allowed). RPL_AWAY is sent to any client sending a PRIVMSG to a client which is away. RPL_AWAY is only sent by the server to which the client is connected.  Replies RPL_UNAWAY and RPL_NOWAWAY are sent when the client removes and sets an AWAY message.
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
       - Replies 311 - 313, 317 - 319 are all replies generated in response to a WHOIS message. Given that there are enough parameters present, the answering server must either formulate a reply out of the above numerics (if the query nick is found) or return an error reply. The ’*’ in RPL_WHOISUSER is there as the literal character and not as a wild card. For each reply set, only RPL_WHOISCHANNELS may appear more than once (for long lists of channel names).  The ’@’ and ’+’ characters next to the channel name indicate whether a client is a channel operator or has been granted permission to speak on a moderated channel. The RPL_ENDOFWHOIS reply is used to mark the end of processing a WHOIS message.
314    RPL_WHOWASUSER
           "<nick> <user> <host> * :<real name>"
369    RPL_ENDOFWHOWAS
           "<nick> :End of WHOWAS"
       - When replying to a WHOWAS message, a server must use the replies RPL_WHOWASUSER, RPL_WHOISSERVER or ERR_WASNOSUCHNICK for each nickname in the presented list. At the end of all reply batches, there must be RPL_ENDOFWHOWAS (even if there was only one reply and it was an error).
321    RPL_LISTSTART
           "Channel :Users Name"
322    RPL_LIST
           "<channel> <# visible> :<topic>"
323    RPL_LISTEND
           ":End of /LIST"
       - Replies RPL_LISTSTART, RPL_LIST, RPL_LISTEND mark the start, actual replies with data and end of the server’s response to a LIST command. If there are no channels available to return, only the start and end reply must be sent.
324    RPL_CHANNELMODEIS
           "<channel> <mode> <mode params>"
331    RPL_NOTOPIC
           "<channel> :No topic is set"
332    RPL_TOPIC
           "<channel> :<topic>"
       - When sending a TOPIC message to determine the channel topic, one of two replies is sent. If the topic is set, RPL_TOPIC is sent back else RPL_NOTOPIC.
341    RPL_INVITING
           "<channel> <nick>"
       - Returned by the server to indicate that the attempted INVITE message was successful and is being passed onto the end client.
342    RPL_SUMMONING
           "<user> :Summoning user to IRC"
       - Returned by a server answering a SUMMON message to indicate that it is summoning that user.
351    RPL_VERSION
           "<version>.<debuglevel> <server> :<comments>"
       - Reply by the server showing its version details.  The <version> is the version of the software being used (including any patchlevel revisions) and the <debuglevel> is used to indicate if the server is running in "debug mode".
       The "comments" field may contain any comments about the version or further version details.
352    RPL_WHOREPLY
           "<channel> <user> <host> <server> <nick> \
           <H|G>[*][@|+] :<hopcount> <real name>"
315    RPL_ENDOFWHO
           "<name> :End of /WHO list"
       - The RPL_WHOREPLY and RPL_ENDOFWHO pair are used to answer a WHO message. The RPL_WHOREPLY is only sent if there is an appropriate match to the WHO query. If there is a list of parameters supplied with a WHO message, a RPL_ENDOFWHO must be sent after processing each list item with <name> being the item.
353    RPL_NAMREPLY
           "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]"
366    RPL_ENDOFNAMES
           "<channel> :End of /NAMES list"
       - To reply to a NAMES message, a reply pair consisting of RPL_NAMREPLY and RPL_ENDOFNAMES is sent by the server back to the client. If there is no channel found as in the query, then only RPL_ENDOFNAMES is returned. The exception to this is when a NAMES message is sent with no parameters and all visible channels and contents are sent back in a series of RPL_NAMEREPLY messages with a RPL_ENDOFNAMES to mark the end.
364    RPL_LINKS
           "<mask> <server> :<hopcount> <server info>"
365    RPL_ENDOFLINKS
           "<mask> :End of /LINKS list"
       - In replying to the LINKS message, a server must send replies back using the RPL_LINKS numeric and mark the end of the list using an RPL_ENDOFLINKS reply.
367    RPL_BANLIST
           "<channel> <banid>"
368    RPL_ENDOFBANLIST
           "<channel> :End of channel ban list"
       - When listing the active ’bans’ for a given channel, a server is required to send the list back using the RPL_BANLIST and RPL_ENDOFBANLIST messages. A separate RPL_BANLIST is sent for each active banid. After the banids have been listed (or if none present) a RPL_ENDOFBANLIST must be sent.
371    RPL_INFO
           ":<string>"
374    RPL_ENDOFINFO
           ":End of /INFO list"
       - A server responding to an INFO message is required to send all its ’info’ in a series of RPL_INFO messages with a RPL_ENDOFINFO reply to indicate the end of the replies.
375    RPL_MOTDSTART
           ":- <server> Message of the day - "
372    RPL_MOTD
           ":- <text>"
376    RPL_ENDOFMOTD
           ":End of /MOTD command"
       - When responding to the MOTD message and the MOTD file is found, the file is displayed line by line, with each line no longer than 80 characters, using RPL_MOTD format replies. These should be surrounded by a RPL_MOTDSTART (before the RPL_MOTDs) and an RPL_ENDOFMOTD (after).
381    RPL_YOUREOPER
           ":You are now an IRC operator"
       - RPL_YOUREOPER is sent back to a client which has just successfully issued an OPER message and gained operator status.
382    RPL_REHASHING
           "<config file> :Rehashing"
       - If the REHASH option is used and an operator sends a REHASH message, an RPL_REHASHING is sent back to the operator.
391    RPL_TIME
           "<server> :<string showing server’s local time>"
       - When replying to the TIME message, a server must send the reply using the RPL_TIME format above. The string showing the time need only contain the correct day and time there. There is no further requirement for the time string.
392    RPL_USERSSTART
           ":UserID Terminal Host"
393    RPL_USERS
           ":%-8s %-9s %-8s"
394    RPL_ENDOFUSERS
           ":End of users"
395    RPL_NOUSERS
           ":Nobody logged in"
       - If the USERS message is handled by a server, the replies RPL_USERSTART, RPL_USERS, RPL_ENDOFUSERS and RPL_NOUSERS are used. RPL_USERSSTART must be sent first, following by either a sequence of RPL_USERS or a single RPL_NOUSER. Following this is RPL_ENDOFUSERS.
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
       - The RPL_TRACE* are all returned by the server in response to the TRACE message. How many are returned is dependent on the the TRACE message and whether it was sent by an operator or not. There is no predefined order for which occurs first.  Replies RPL_TRACEUNKNOWN, RPL_TRACECONNECTING and RPL_TRACEHANDSHAKE are all used for connections which have not been fully established and are either unknown, still attempting to connect or in the process of completing the ’server handshake’.  RPL_TRACELINK is sent by any server which handles a TRACE message and has to pass it on to another server. The list of RPL_TRACELINKs sent in response to a TRACE command traversing the IRC network should reflect the actual connectivity of the servers themselves along that path.  RPL_TRACENEWTYPE is to be used for any connection which does not fit in the other categories but is being displayed anyway.
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
       - To answer a query about a client’s own mode, RPL_UMODEIS is sent back.
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
       - In processing an LUSERS message, the server sends a set of replies from RPL_LUSERCLIENT, RPL_LUSEROP, RPL_USERUNKNOWN, RPL_LUSERCHANNELS and RPL_LUSERME. When replying, a server must send back RPL_LUSERCLIENT and RPL_LUSERME. The other replies are only sent back if a non-zero count is found for them.
256    RPL_ADMINME
           "<server> :Administrative info"
257    RPL_ADMINLOC1
           ":<admin info>"
258    RPL_ADMINLOC2
           ":<admin info>"
259    RPL_ADMINEMAIL
           ":<admin info>"
       - When replying to an ADMIN message, a server is expected to use replies RLP_ADMINME through to RPL_ADMINEMAIL and provide a text message with each. For RPL_ADMINLOC1 a description of what city, state and country the server is in is expected, followed by details of the university and department (RPL_ADMINLOC2) and finally the administrative contact for the server (an email address here is required) in RPL_ADMINEMAIL.
```

### 6.3 Reserved numerics.
These numerics are not described above since they fall into one of the following categories:

1. no longer in use;
2. reserved for future planned use;
3. in current use but are part of a non-generic ’feature’ of the current IRC server.

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
Clients and servers are both subject to the same level of authentication. For both, an IP number to hostname lookup (and reverse check on this) is performed for all connections made to the server. Both connections are then subject to a password check (if there is a password set for that connection). These checks are possible on all connections although the password check is only commonly used with servers.

An additional check that is becoming of more and more common is that of the username responsible for making the connection. Finding the username of the other end of the connection typically involves connecting to an authentication server such as IDENT as described in RFC 1413.

Given that without passwords it is not easy to reliably determine who is on the other end of a network connection, use of passwords is strongly recommended on inter-server connections in addition to any other measures such as using an ident server.

## 8. Current implementations
The only current implementation of this protocol is the IRC server, version 2.8. Earlier versions may implement some or all of the commands described by this document with NOTICE messages replacing many of the numeric replies. Unfortunately, due to backward compatibility requirements, the implementation of some parts of this document varies with what is laid out. On notable difference is:

* recognition that any LF or CR anywhere in a message marks the end of that message (instead of requiring CR-LF);

The rest of this section deals with issues that are mostly of importance to those who wish to implement a server but some parts also apply directly to clients as well.

### 8.1 Network protocol: TCP - why it is best used here.
IRC has been implemented on top of TCP since TCP supplies a reliable network protocol which is well suited to this scale of conferencing.  The use of multicast IP is an alternative, but it is not widely available or supported at the present time.

#### 8.1.1 Support of Unix sockets
Given that Unix domain sockets allow listen/connect operations, the current implementation can be configured to listen and accept both client and server connections on a Unix domain socket. These are recognized as sockets where the hostname starts with a ’/’.

When providing any information about the connections on a Unix domain socket, the server is required to supplant the actual hostname in place of the pathname unless the actual socket name is being asked for.

### 8.2 Command Parsing
To provide useful ’non-buffered’ network IO for clients and servers, each connection is given its own private ’input buffer’ in which the results of the most recent read and parsing are kept. A buffer size of 512 bytes is used so as to hold 1 full message, although, this will usually hold several commands. The private buffer is parsed after every read operation for valid messages. When dealing with multiple messages from one client in the buffer, care should be taken in case one happens to cause the client to be ’removed’.

### 8.3 Message delivery
It is common to find network links saturated or hosts to which you are sending data unable to send data. Although Unix typically handles this through the TCP window and internal buffers, the server often has large amounts of data to send (especially when a new server-server link forms) and the small buffers provided in the kernel are not enough for the outgoing queue. To alleviate this problem, a "send queue" is used as a FIFO queue for data to be sent.  A typical "send queue" may grow to 200 Kbytes on a large IRC network with a slow network connection when a new server connects.

When polling its connections, a server will first read and parse all incoming data, queuing any data to be sent out. When all available input is processed, the queued data is sent. This reduces the number of write() system calls and helps TCP make bigger packets.

### 8.4 Connection ’Liveness’
To detect when a connection has died or become unresponsive, the server must ping each of its connections that it doesn’t get a response from in a given amount of time.

If a connection doesn’t respond in time, its connection is closed using the appropriate procedures. A connection is also dropped if its sendq grows beyond the maximum allowed, because it is better to close a slow connection than have a server process block.

### 8.5 Establishing a server to client connection
Upon connecting to an IRC server, a client is sent the MOTD (if present) as well as the current user/server count (as per the LUSER command). The server is also required to give an unambiguous message to the client which states its name and version as well as any other introductory messages which may be deemed appropriate.

After dealing with this, the server must then send out the new user’s nickname and other information as supplied by itself (USER command) and as the server could discover (from DNS/authentication servers).  The server must send this information out with NICK first followed by USER.

### 8.6 Establishing a server-server connection.
The process of establishing of a server-to-server connection is fraught with danger since there are many possible areas where problems can occur - the least of which are race conditions.

After a server has received a connection following by a PASS/SERVER pair which were recognised as being valid, the server should then reply with its own PASS/SERVER information for that connection as well as all of the other state information it knows about as described below.

When the initiating server receives a PASS/SERVER pair, it too then checks that the server responding is authenticated properly before accepting the connection to be that server.

#### 8.6.1 Server exchange of state information when connecting
The order of state information being exchanged between servers is essential. The required order is as follows:

* all known other servers;
* all known user information;
* all known channel information.

Information regarding servers is sent via extra SERVER messages, user information with NICK/USER/MODE/JOIN messages and channels with MODE messages.

NOTE: channel topics are *NOT* exchanged here because the TOPIC command overwrites any old topic information, so at best, the two sides of the connection would exchange topics.

By passing the state information about servers first, any collisions with servers that already exist occur before nickname collisions due to a second server introducing a particular nickname. Due to the IRC network only being able to exist as an acyclic graph, it may be possible that the network has already reconnected in another location, the place where the collision occurs indicating where the net needs to split.

### 8.7 Terminating server-client connections
When a client connection closes, a QUIT message is generated on behalf of the client by the server to which the client connected. No other message is to be generated or used.

### 8.8 Terminating server-server connections
If a server-server connection is closed, either via a remotely generated SQUIT or ’natural’ causes, the rest of the connected IRC network must have its information updated with by the server which detected the closure. The server then sends a list of SQUITs (one for each server behind that connection) and a list of QUITs (again, one for each client behind that connection).

### 8.9 Tracking nickname changes
All IRC servers are required to keep a history of recent nickname changes. This is required to allow the server to have a chance of keeping in touch of things when nick-change race conditions occur with commands which manipulate them. Commands which must trace nick changes are:

* KILL (the nick being killed)
* MODE (+/- o,v)
* KICK (the nick being kicked)

No other commands are to have nick changes checked for.

In the above cases, the server is required to first check for the existence of the nickname, then check its history to see who that nick currently belongs to (if anyone!). This reduces the chances of race conditions but they can still occur with the server ending up affecting the wrong client. When performing a change trace for an above command it is recommended that a time range be given and entries which are too old ignored.

For a reasonable history, a server should be able to keep previous nickname for every client it knows about if they all decided to change. This size is limited by other factors (such as memory, etc).

### 8.10 Flood control of clients
With a large network of interconnected IRC servers, it is quite easy for any single client attached to the network to supply a continuous stream of messages that result in not only flooding the network, but also degrading the level of service provided to others. Rather than require every ’victim’ to be provide their own protection, flood protection was written into the server and is applied to all clients except services. The current algorithm is as follows:

* check to see if client’s ‘message timer’ is less than current time (set to be equal if it is);
* read any data present from the client;
* while the timer is less than ten seconds ahead of the current time, parse any present messages and penalize the client by 2 seconds for each message;

which in essence means that the client may send 1 message every 2 seconds without being adversely affected.

### 8.11 Non-blocking lookups
In a real-time environment, it is essential that a server process do as little waiting as possible so that all the clients are serviced fairly. Obviously this requires non-blocking IO on all network read/write operations. For normal server connections, this was not difficult, but there are other support operations that may cause the server to block (such as disk reads). Where possible, such activity should be performed with a short timeout.

#### 8.11.1 Hostname (DNS) lookups
Using the standard resolver libraries from Berkeley and others has meant large delays in some cases where replies have timed out. To avoid this, a separate set of DNS routines were written which were setup for non-blocking IO operations and then polled from within the main server IO loop.

#### 8.11.2 Username (Ident) lookups
Although there are numerous ident libraries for use and inclusion into other programs, these caused problems since they operated in a synchronous manner and resulted in frequent delays. Again the solution was to write a set of routines which would cooperate with the rest of the server and work using non-blocking IO.

### 8.12 Configuration File
To provide a flexible way of setting up and running the server, it is recommended that a configuration file be used which contains instructions to the server on the following:

* which hosts to accept client connections from;
* which hosts to allow to connect as servers;
* which hosts to connect to (both actively and passively);
* information about where the server is (university, city/state, company are examples of this);
* who is responsible for the server and an email address at which they can be contacted;
* hostnames and passwords for clients which wish to be given access to restricted operator commands.

In specifying hostnames, both domain names and use of the ’dot’ notation (127.0.0.1) should both be accepted. It must be possible to specify the password to be used/accepted for all outgoing and incoming connections (although the only outgoing connections are those to other servers).

The above list is the minimum requirement for any server which wishes to make a connection with another server. Other items which may be of use are:

* specifying which servers other server may introduce;
* how deep a server branch is allowed to become;
* hours during which clients may connect.

#### 8.12.1 Allowing clients to connect
A server should use some sort of ’access control list’ (either in the configuration file or elsewhere) that is read at startup and used to decide what hosts clients may use to connect to it.

Both ’deny’ and ’allow’ should be implemented to provide the required flexibility for host access control.

#### 8.12.2 Operators
The granting of operator privileges to a disruptive person can have dire consequences for the well-being of the IRC net in general due to the powers given to them. Thus, the acquisition of such powers should not be very easy. The current setup requires two ’passwords’ to be used although one of them is usually easy guessed. Storage of oper passwords in configuration files is preferable to hard coding them in and should be stored in a crypted format (ie using crypt(3) from Unix) to prevent easy theft.

#### 8.12.3 Allowing servers to connect
The interconnection of server is not a trivial matter: a bad connection can have a large impact on the usefulness of IRC. Thus, each server should have a list of servers to which it may connect and which servers may connect to it. Under no circumstances should a server allow an arbitrary host to connect as a server. In addition to which servers may and may not connect, the configuration file should also store the password and other characteristics of that link.

#### 8.12.4 Administrivia
To provide accurate and valid replies to the ADMIN command (see section 4.3.7), the server should find the relevant details in the configuration.

### 8.13 Channel membership
The current server allows any registered local user to join upto 10 different channels. There is no limit imposed on non-local users so that the server remains (reasonably) consistant with all others on a channel membership basis

## 9. Current problems
There are a number of recognized problems with this protocol, all of which hope to be solved sometime in the near future during its rewrite. Currently, work is underway to find working solutions to these problems.

### 9.1 Scalability
It is widely recognized that this protocol does not scale sufficiently well when used in a large arena. The main problem comes from the requirement that all servers know about all other servers and users and that information regarding them be updated as soon as it changes. It is also desirable to keep the number of servers low so that the path length between any two points is kept minimal and the spanning tree as strongly branched as possible.

### 9.2 Labels
The current IRC protocol has 3 types of labels: the nickname, the channel name and the server name. Each of the three types has its own domain and no duplicates are allowed inside that domain.  Currently, it is possible for users to pick the label for any of the three, resulting in collisions. It is widely recognized that this needs reworking, with a plan for unique names for channels and nicks that don’t collide being desirable as well as a solution allowing a cyclic tree.

#### 9.2.1 Nicknames
The idea of the nickname on IRC is very convenient for users to use when talking to each other outside of a channel, but there is only a finite nickname space and being what they are, its not uncommon for several people to want to use the same nick. If a nickname is chosen by two people using this protocol, either one will not succeed or both will removed by use of KILL (4.6.1).

#### 9.2.2 Channels
The current channel layout requires that all servers know about all channels, their inhabitants and properties. Besides not scaling well, the issue of privacy is also a concern. A collision of channels is treated as an inclusive event (both people who create the new channel are considered to be members of it) rather than an exclusive one such as used to solve nickname collisions.

#### 9.2.3 Servers
Although the number of servers is usually small relative to the number of users and channels, they two currently required to be known globally, either each one separately or hidden behind a mask.

###  9.3 Algorithms
In some places within the server code, it has not been possible to avoid N^2 algorithms such as checking the channel list of a set of clients.

In current server versions, there are no database consistency checks, each server assumes that a neighbouring server is correct. This opens the door to large problems if a connecting server is buggy or otherwise tries to introduce contradictions to the existing net.

Currently, because of the lack of unique internal and global labels, there are a multitude of race conditions that exist. These race conditions generally arise from the problem of it taking time for messages to traverse and effect the IRC network. Even by changing to unique labels, there are problems with channel-related commands being disrupted.
