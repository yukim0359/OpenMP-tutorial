#import "theme.typ": *
#show: apply-my-theme

#let INFO = (
  title: [OpenMP Tutorial],
  author: [前田 優希],
  date: [2026.06.26],
  institution: [田浦研究室 M1],
  event: [Taura-Lab Spring Training 2026],
)

#show: my-deck-theme(INFO)
#set text(size: 18pt)
#my-cover-slide(INFO)

#slide(title: [このTutorialの目標])[
  - OpenMPの概念を理解する
  - OpenMPの基本的な使い方を習得する
  - もう少し一般的に，並列プログラミングにおいて意識すべきことを学習する
]

= OpenMPとは？

#slide(title: [HPC計算機の基本構成])[
  #set text(size: 0.85em)
  - HPCでは，多数の計算機をネットワークで接続した計算クラスタを用いることが多い
  - クラスタを構成する1台1台の計算機を#text(weight: "bold")[ノード]と呼ぶ
  - 各ノードは，CPU・メモリ・場合によってはGPUなどを持つ
    - CPU内部には複数の#text(weight: "bold")[コア]があり，複数の処理を並列に実行できる
  - 1ノード内では複数コアがメモリを共有する（*共有メモリ*）
  - 一方，ノード間ではメモリは共有されない（*分散メモリ*）
  #align(center)[
    #image("img/hpc_cluster.svg", width: auto, height: 55%)
  ]
]

#slide(title: [OpenMPとは？])[
- *OpenMP*とは，共有メモリ型並列計算機用にプログラムを並列化するための#linebreak()API仕様・標準規格
	- MPはMulti-Processingを意味する
	- C，C++，Fortranから利用可能
- 長所：`#pragma omp parallel` などのコンパイラ指示文で並列処理を簡単に記述可能
	- #text(weight: "bold")[既存の逐次コードから少ない変更で，簡単に並列化を追加できる]
- 例：for文の並列化
  #align(center)[
    #grid(
      columns: (1fr, 0.2fr, 1.5fr),
      gutter: 1em,
      [
        #align(right)[
          ```c
          for (int i=0; i<N; i++) {
            a[i] = i;
          }
          ```
        ]  
      ],
      [
        #text(fill: accent, size: 2em)[➡︎]
      ],
      [
        #align(left)[
          ```c
          [[[#pragma omp parallel for]]]
          for (int i=0; i<N; i++) {
            a[i] = i;
          }
          ```
        ]
      ]
    )
  ]
]

#slide(title: [[補足] 「API仕様・標準規格」とは？])[
- OpenMPは，特定の1つのライブラリ名ではなく，並列化のための#text(weight: "bold")[仕様]
- 仕様には以下が含まれる
  - `#pragma omp ...` のようなコンパイラ指示文
  - `omp_get_thread_num()` などのランタイム関数
  - `OMP_NUM_THREADS` などの環境変数
- 実際には，コンパイラやランタイムがこの仕様を実装する
  - GCC: `libgomp`
  - LLVM/Clang: `libomp`
  - Intel oneAPI: Intel OpenMP runtime
- OpenMPの規格書：https://www.openmp.org/specifications/
]

#slide(title: [[補足] pragmaとは])[
  - pragmaはコンパイラに対する指示文（*ディレクティブ*）
  - C/C++では *`#pragma`* で始まる行として記述される
  - OpenMPでは *`#pragma omp ...`* の形式で並列化の指示をコンパイラに与える
  - OpenMPがpragmaを使うのは，既存のC/C++/Fortranプログラムに対して，元のコード構造を大きく変えずに並列化の指示を追加できるようにするため
]

#slide(title: [ノード内並列化とノード間並列化])[
- OpenMPはノード内の並列化（#text(weight: "bold")[共有メモリ並列化]）を担う
- ノード間の並列化（#text(weight: "bold")[分散メモリ並列化]）を担当するAPIとしては*MPI*などがある
- 実際のHPCでは，ノード間はMPI，ノード内はOpenMPで並列化する#text(weight: "bold")[ハイブリッド並列]が#linebreak()重要
  - OpenMP単体では主に1ノード内に制約され，大規模計算でのスケールアウトにはMPIが必要
  - 一方で，分散メモリでは通信，データ配置，負荷分散を意識する必要があり，性能を出すのは容易ではない
]


#slide(title: [`#pragma omp parallel`])[
  - 複数スレッドで実行する#text(weight: "bold")[並列領域]を作るための基本的な指示文
  - 以下のように記述すると，並列領域内の文を各スレッドが実行する
  - #text(weight: "bold")[同じ文がスレッドの数だけ実行される]点に注意
  - ブロックの終わりで終了を待ち合わせる（*fork-join モデル*）
  ```c
  // sequential region

  [[[#pragma omp parallel]]]
  { 
    // parallel region
  }

  // sequential region
  ```
]


#slide(title: [Fork-Joinモデル])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    [
      #image("img/fork_join_model.png", width: auto, height: auto, fit: "contain")
    ],
    [
      - 並列領域に入ると，複数のスレッドに分岐（*fork*）
      - 各スレッドが並列に処理を実行
      - 並列領域の終わりで同期（*join*）
    ]
  )
  #align(right)[
    #text(size: 0.7em, fill: rgb("#666"))[
      出典：#link("https://parallelcomputingsite.wordpress.com/2017/04/17/fork-join-in-open-mp/")[
        https://parallelcomputingsite.wordpress.com/2017/04/17/fork-join-in-open-mp/
      ]
    ]
  ]
]

#slide(title: [サンプルプログラム：`hello.c`])[
  ```c
  printf("Before parallel region\n");
  #pragma omp parallel
  {
    int tid = [[[omp_get_thread_num()]]];
    int nthreads = [[[omp_get_num_threads()]]];
    printf("Hello, World! I'm thread %d of %d\n", tid, nthreads);
  }
  printf("After parallel region\n");
  ```
  - このように書くと，全スレッドが `{ }` 内部の文を実行する
  - *`omp_get_num_threads()`* で全体のスレッド数を取得できる
  - *`omp_get_thread_num()`* で自分のスレッド番号を取得できる
]

#slide(title: [コンパイルしてみよう])[
  - OpenMPを使うには，コンパイル時に `-fopenmp` を付ける
  ```sh
  $ gcc [[[-fopenmp]]] hello.c -o hello
  $ clang [[[-fopenmp]]] hello.c -o hello
  ```
  - ただし，clang の場合はOpenMPランタイムが別途必要なことがある
  - 注意：macOSでは話が面倒
    - macOSの `gcc` は，実は名前だけgccで中身はApple Clangと呼ばれるclangになっている
    - この場合，上のようにはコンパイルできない
    - homebrewでgccを入れて使うのが簡単
    ```sh
    $ brew install gcc
    $ gcc-<your_gcc_version> -fopenmp hello.c -o hello
    ```
    - サンプルプログラムでは，Makefileを `CC := gcc-<your_gcc_version>` に書き換えればよい
]

#slide(title: [[補足] Apple Clangとは？])[
  - macOSで以下を実行
  ```sh
  $ gcc --version
  Apple clang version 17.0.0 (clang-1700.6.3.2)
  Target: arm64-apple-darwin25.1.0
  Thread model: posix
  InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
  ```
  - Apple Clangは `-fopenmp` を直接サポートしていない
  - 一応，Apple Clangで頑張ることもできる
  ```sh
  $ brew install libomp
  $ clang -Xpreprocessor -fopenmp -lomp \
  -I$(brew --prefix libomp)/include \
  -L$(brew --prefix libomp)/lib \
  hello.c -o hello
  ```
]

#slide(title: [実行してみよう])[
  - 実行時は以下のように実行するスレッド数を指定できる
  ```sh
  $ OMP_NUM_THREADS=4 ./hello
  ```
  - あるいは，あらかじめ環境変数として設定しておくこともできる
  ```sh
  $ export OMP_NUM_THREADS=4
  $ ./hello
  ```
  - また，関数 `omp_set_num_threads(num_threads)` によりプログラム側でも指定できる
]

#slide(title: [実行結果])[
  - 実行結果の例：
  ```bash
  $ OMP_NUM_THREADS=4 ./hello
  Before parallel region
  Hello, World! I'm thread 1 of 4
  Hello, World! I'm thread 2 of 4
  Hello, World! I'm thread 0 of 4
  Hello, World! I'm thread 3 of 4
  After parallel region
  ```
  - たしかに各スレッドがparallel内部の文を実行している
  - `Before` → `Hello` → `After`の順番は必ず守られる
    - これはfork-joinモデルによるもの
    - `Hello` の中の順番は実行のたびに入れ替わる
]

#slide(title: [実用的には？])[
  #set text(size: 0.85em)
  - 実用上は，同じコード片を全スレッドで実行するだけでなく，異なる仕事をスレッド間で分担したい
  - OpenMPでは，`parallel` でスレッドチームを作り，その中で仕事を分割・分散する構文を使う
  - 代表的な構文：
    - *for構文*： `#pragma omp for`#linebreak()ループのイテレーションを分割
    - *sections構文*： `#pragma omp sections`#linebreak()複数の独立処理ブロックを並列実行
    - *task構文*： `#pragma omp task`#linebreak()任意の処理を動的にタスク化して柔軟に分散
  - なお，`for` や `sections` には，`parallel` とまとめた短縮形もある
    - `#pragma omp parallel for`
    - `#pragma omp parallel sections`
  - `task` は通常，`parallel` 領域内で `single` から生成する
]

= ループ並列化

#slide(title: [for構文])[
  #set text(size: 0.9em)
  #grid(
    columns: (0.7fr, 0.3fr),
    gutter: 1em,
    [
      - 以下のように書くことで，for文の各イテレーションがスレッドに分散される

      ```c
      [[[#pragma omp parallel]]]
      {
        [[[#pragma omp for]]]
        for (int i = 0; i < N; i++) {
          a[i] = i;
        }
      }
      ```

      - 以下のように略記可能

      ```c
      [[[#pragma omp parallel for]]]
      for (int i = 0; i < N; i++) {
        a[i] = i;
      }
      ```
    ],
    [
      #image("img/101.png", width: 100%, height: 90%, fit: "contain")
    ],
  )

  #align(right)[
    #text(size: 0.7em, fill: rgb("#666"))[
      出典：#link("https://www.geeksforgeeks.org/c/c-parallel-for-loop-in-openmp/")[
        https://www.geeksforgeeks.org/c/c-parallel-for-loop-in-openmp/
      ]
    ]
  ]
]


#slide(title: [`parallel_for.c` を実行してみよう])[
  - `parallel_for.c` を実行してみる
  - 実行結果の例：
  ```bash
  $ OMP_NUM_THREADS=4 ./parallel_for
  Loop 2 is being processed by thread 1
  Loop 3 is being processed by thread 1
  Loop 4 is being processed by thread 2
  Loop 5 is being processed by thread 2
  Loop 0 is being processed by thread 0
  Loop 1 is being processed by thread 0
  Loop 6 is being processed by thread 3
  Loop 7 is being processed by thread 3
  ```
  - 若い番号から $frac(#jp[ループの個数], #jp[スレッドの個数])$ 個ごとにループが各スレッドに割り当てられる
  - この割り当ての方法は変更可能（後述）
]

= 正しく並列化するために <touying:skip>

== 共有変数とプライベート変数について

#slide(title: [注意点①：共有変数とプライベート変数について])[
  - OpenMPにおいて，変数にはスレッドごとに共有されるもの（*共有変数*）とスレッドごとに独立に確保されるもの（*プライベート変数*）がある
    - これを変数の*属性*という
  - `#pragma omp parallel for` の直後のループ変数以外はすべて共有変数となる(!)
  - つまり，以下のようなプログラムは正しく動作しない
    - `j` が共有変数
    - `j = i` と `a[j] = i` の間に `j` が他スレッドにより書き換えられる可能性
  ```c
  int i, j;
  #pragma omp parallel for
  for (i = 0; i < N; i++) {
    j = i;
    a[j] = 1;
  }
  ```
]

#slide(title: [注意点①：共有変数とプライベート変数について])[
  #set text(size: 0.9em)
  - 実際におかしなことが起こるのを確認する
  ```c
  #pragma omp parallel for
  for (i = 0; i < 10000; i++) {
      j = i;
      a[j] = 1;
  }

  long sum = 0;
  for (int idx = 0; idx < 10000; idx++) sum += a[idx];
  ```
  - `attribution_err.c` の実行結果
    - 正しい結果は `Sum = 10000`
  ```bash
  $ OMP_NUM_THREADS=4 ./attribution_err
  Sum = 9986
  $ OMP_NUM_THREADS=4 ./attribution_err
  Sum = 9989
  $ OMP_NUM_THREADS=1 ./attribution_err
  Sum = 10000
  ```
]

#slide(title: [注意点①：共有変数とプライベート変数について])[
  #set text(size: 0.9em)
  - 正しくはこう，`private` 節で個別にプライベート変数に設定できる
  ```c
  int i, j;
  #pragma omp parallel for [[[private(j)]]]
  for (i = 0; i < N; i++) {
    j = i;
    a[j] = 1;
  }
  ```
  - あるいは `default(private)` とすればデフォルトがプライベート変数になる
  - あるいは今回はこれでもいい
    - parallel節内部で宣言された変数はprivateになるはず
  ```c
  int i;
  #pragma omp parallel for
  for (i = 0; i < N; i++) {
    [[[int j = i;]]]
    a[j] = 1;
  }
  ```
]


#slide(title: [[補足] 変数の属性])[
  - *private*：各スレッドに独立した領域を割り当て，#text(weight: "bold")[並列領域開始時の値は不定]
  - *shared*：全スレッドで同じ変数を参照，並列領域内で競合すると未定義動作になる
  - *firstprivate*：private と同じだが，#text(weight: "bold")[並列領域開始時に親スレッドの値で初期化]
  - *lastprivate*：並列領域終了後，最後に更新されたスレッドの値を親スレッドに反映
  - 詳細は `attribution.c` を参照
]

== そもそも並列化できない例

#slide(title: [注意点②：そもそも並列化できない例])[
  - すべてのfor文が並列化可能なわけではない
  - `i` を `1` から `N` まで順番に回さないと逐次実行と結果が異なるようなプログラム（*流れ依存*）に対しては，（アルゴリズムの変更等を試みない限り）厳しい
  - 例１：
    ```c
    for (i = 1; i < N - 1; i++) {
      a[i] = a[i] + 1;
      b[i] = a[i - 1] + a[i + 1];
    }
    ```
    - `a[i - 1]` が更新されていない可能性がある
]

#slide(title: [注意点②：そもそも並列化できない例])[
  - 例２：
    ```c
    for (i = 0; i < N; i++) {
      a[i] = a[b[i]];
    }
    ```
    - `b[i]` の内容により並列化が可能かどうか決まる
]

== データ競合

#slide(title: [注意点③：データ競合])[
  - 並列処理においては*データ競合*への対処が重要
  - 例：Monte Carlo による $pi$ の推定
    - 各試行 `i` で `trial_hits(i)`（`SUBSAMPLES`回ランダムで矢を投げる）を計算し，当たり数 `hits` を共有変数に足し合わせる
  - 以下はデータ競合が発生するプログラムの例
  ```c
  long long hits = 0;

  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    hits += h;  // data race!
  }
  ```
  - `hits` に対する読み込み→書き込みの間に他スレッドが書き込みを行う可能性がある
  - OpenMPではデータ競合を避ける方法がいくつかある
]

#slide(title: [データ競合の回避①：lock])[
  - OpenMPではlock機構が用意されている
  - 先ほどの例だと以下のよう
  ```c
  [[[omp_lock_t lock;]]]
  [[[omp_init_lock(&lock);]]]
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[omp_set_lock(&lock);]]]
    hits += h;
    [[[omp_unset_lock(&lock);]]]
  }
  ```
]

#slide(title: [データ競合の回避②：critical補助指示文])[
  - `#pragma omp critical` 内部の文は，同時には1つ以下のスレッドしか実行しない
  - lockより自由度は低いが，実装は単純
  - オプション *`(name)`* をつけることで複数のクリティカルセクションを作ることができる
	  - 同じ `name` を持つクリティカルセクション同士は排他制御されるが，異なる `name` なら同時に実行できる
	  - `name` は省略可能
  - 先ほどの例だと以下のよう
  ```c
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[#pragma omp critical]]]
    {
      hits += h;
    }
  }
  ```
]

#slide(title: [データ競合の回避③：atomic補助指示文])[
  - #text(weight: "bold")[単純な式一行のみ]（ `x+=値` や `x^=値` など）であれば，`#pragma omp atomic` を用いると速い
  - ハードウェアatomic命令などで効率的に値を更新する
  - 先ほどの例だと以下のよう
  ```c
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[#pragma omp atomic]]]
    hits += h;
  }
  ```
]

#slide(title: [比較してみる])[
  - これらの実行時間を比較してみる
    - 実行時間の計測は *`omp_get_wtime()`* により可能
  - `seq.c`，`lock.c`，`critical.c`，`atomic.c` を実行
    - `N = 20000000`，`SUBSAMPLES = 16`
  - 実行結果の例：
  ```bash
  $ ./seq
  Elapsed time: 1.890952 seconds
  $ ./lock
  Elapsed time: 5.342480 seconds
  $ ./critical
  Elapsed time: 5.382293 seconds
  $ ./atomic
  Elapsed time: 1.273485 seconds
  ```
]

#slide(title: [reduction節])[
  - 総和のように，複数スレッドの結果を最後に1つにまとめる場合は *reduction* 節を使うのが自然
  - 先ほどの例では，hits に対する加算を以下のように書ける

  ```c
  long long hits = 0;

  #pragma omp parallel for [[[reduction(+:hits)]]]
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    hits += h;
  }
  ```
  - `reduction(+:hits)` により，各スレッドは自分専用の hits を持つ
  - 並列ループの終了時に，各スレッドの `hits` が足し合わされ，元の `hits` に反映される
  - そのため，各反復で共有変数を直接更新する必要がない
    - `atomic` のように毎回共有変数を更新しないため，高速になりやすい
]

#slide(title: [reductionのイメージ])[
  - `reduction` は，概念的には以下のような処理に近い
  ```c
  long long hits_local[MAX_THREADS] = {0};

  #pragma omp parallel
  {
    int tid = omp_get_thread_num();

    #pragma omp for
    for (int i = 0; i < N; i++) {
      long long h = trial_hits(i);
      hits_local[tid] += h;
    }
  }

  long long hits = 0;
  for (int t = 0; t < nthreads; t++) {
    hits += hits_local[t];
  }
  ```
]

#slide(title: [計測時間の比較])[
  - 同じ Monte Carlo 例で，`atomic.c` と `reduction.c` を比較
  - 実行結果の例
  ```bash
  $ ./atomic
  Elapsed time: 1.273485 seconds
  $ ./reduction
  Elapsed time: 0.340737 seconds
  ```
]

#slide(title: [注意：いつもこうなるとは限らない])[
  #set text(size: 0.9em)
  - 並列化の効果は，並列領域内の計算量に依存する
  - `SUBSAMPLES`をいじることで`trial_hits`の計算量を変えることができる
    - 小さいと，各反復の計算が軽いため `hits` への同期コストが目立ち，並列版が `seq` より遅くなることがある
    - 大きいと，`trial_hits(i)` の計算が支配的になり，並列化の効果が出やすくなる
  #align(center)[
    #image("img/subsamples_timing.png", height: 60%)
  ]
]

#slide(title: [[補足] reductionとして実行できる演算])[
  #set text(size: 0.95em)
  - reduction では `+` 以外の演算も使える
  - C/C++では，`+ * & | ^ && || max min` が利用可能
  - また，`declare reduction` により，ユーザがreduction演算を定義できる
  ```c
  typedef struct {
    double x; double y;
  } Pair;

  #pragma omp declare reduction( \
    pair_plus : Pair : \
    omp_out.x += omp_in.x, omp_out.y += omp_in.y \
  ) initializer(omp_priv = {0.0, 0.0})

  Pair total = {0.0, 0.0};
  #pragma omp parallel for reduction(pair_plus:total)
  for (int i = 0; i < N; i++) {
    Pair p = compute_pair(i);
    total.x += p.x;
    total.y += p.y;
  }
  ```
]


= 速く並列化するために <touying:skip>

== スケジューリング

#slide(title: [スケジューリングの重要性])[
  - 高性能化のためにはスケジューリングが重要
  - 並列化をしたとしても，負荷分散が不均衡だと性能が出ない
  - 特にOpenMPのfork-joinモデルでは，仕事の最も多いスレッドが終わるまで待たないと#linebreak()いけない

  #align(center)[
    #image("img/load_imbalance.svg", height: 60%, fit: "contain")
  ]
]

#slide(title: [スケジューリングの種類])[
  - forループのスケジューリングの種類には以下の3通りがある
    + *`static`*：スレッドごとにchunk個のイテレーションを静的に割り当てる
    + *`dynamic`*：スレッドごとにchunk個のイテレーションを動的に割り当てる，終わった#linebreak()スレッドから次のchunkを取りに行く
    + *`guided`*：スレッドごとに割り当てるイテレーションの個数を徐々に小さくする

  - `#pragma omp parallel for schedule(dynamic, CHUNK_SIZE)` のように指定できる
    - 省略した場合のデフォルトは，仕様上は規定されていないが，主要実装ではstaticになる
]

#slide(title: [static])[
  #set text(size: 0.95em)
  - *`schedule(static, CHUNK_SIZE)`*
    - ループを `CHUNK_SIZE` 個ごとに分割し，スレッド0番からラウンドロビンで#text(weight: "bold")[静的に]割り当てる
    - schedule補助指定文を省略したときのデフォルトはstaticで，`CHUNK_SIZE` は$frac(jp("ループの個数"), jp("スレッドの個数"))$となる#text(size: 0.8em)[（要するに，何もスケジューリング句を指定しないとこうなる）]
    - `CHUNK_SIZE` $= frac(jp("ループの個数"), jp("スレッドの個数"))$ のとき
    #align(center)[
      #image("img/static_example_1.svg", width: 55%, fit: "contain")
    ]
    - `CHUNK_SIZE` $= 1$ のとき
    #align(center)[
      #image("img/static_example_2.svg", width: 55%, fit: "contain")
    ]
]

#slide(title: [dynamic])[
  - *`schedule(dynamic, CHUNK_SIZE)`*
    - ループを `CHUNK_SIZE` 個ごとに分割し，#text(weight: "bold")[処理が終わったスレッドに順々で次の処理を#linebreak()割り当てる]
    - 実行時にならないとループ内部の計算量が明らかにならない場合に有効
    - `CHUNK_SIZE` を省略すると1になる

  #align(center)[
    #image("img/dynamic_example.svg", width: 60%, fit: "contain")
  ]
]

#slide(title: [guided])[
  - *`schedule(guided, CHUNK_SIZE)`*
    - #text(weight: "bold")[徐々にチャンクサイズを小さくしながら，処理が終わったスレッドに順々で次の処理を#linebreak()割り当てる]
    - `CHUNK_SIZE` はチャンクサイズの最小単位
    - チャンクサイズに1より大きい $k$ を指定した場合，チャンクサイズは指数的に $k$ まで#linebreak()小さくなるが，最後のチャンクは $k$ より小さくなる場合がある
    - `CHUNK_SIZE` を省略すると1になる

  #align(center)[
    #image("img/guided_example.svg", width: 80%, fit: "contain")
  ]
]

#slide(title: [各スケジューリングの特徴])[
  - dynamic，guidedのチャンクサイズは性能に影響する
    - チャンクサイズ小→負荷分散は良くなるが，オーバーヘッドは大きくなる
    - チャンクサイズ大→負荷分散は悪くなるが，オーバーヘッドは小さくなる
  - 割り当てのオーバーヘッド
    - dynamic，guidedは実行時スケジューリングのため，staticよりもオーバーヘッドが#linebreak()大きい
    - #text(weight: "bold")[事前に負荷分散が均衡となるスケジューリングを組むことができれば，]#linebreak()staticスケジューリングを用いることでさらに高速化できる可能性がある
]

#slide(title: [スケジューリングの比較])[
  - 以下のようなforループの外側のみをOpenMPで並列化する
    - ループの後半ほど計算量が大きい
  - スケジューリングとして上記の3パターンを試し，実行時間を比較する
  - どのループをどのスレッドが担当したかの記録も取っておく
  ```c
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < i; j++) {
      A[i]++;
    }
  }
  ```
]

#slide(title: [スケジューリングの比較])[
  - `static.c`，`dynamic.c`，`guided.c` を実行（スレッド数は4）

  #align(center)[
    #stack(
      spacing: 0.6em,
      image("img/static_schedule.png", width: 80%, height: 25%, fit: "contain"),
      image("img/dynamic_schedule.png", width: 80%, height: 25%, fit: "contain"),
      image("img/guided_schedule.png", width: 80%, height: 25%, fit: "contain"),
    )
  ]
]

#slide(title: [スケジューリングの比較：計測結果])[
  - 実行結果の例：
  ```bash
  === OpenMP threads: 4 ===
  static : 0.372155 ± 0.004169 s
  dynamic: 0.586862 ± 0.003830 s
  guided : 0.259611 ± 0.067941 s
  ```
  - 負荷分散は良好なのにもかかわらず，dynamicがstaticよりも遅い
    - スケジューリングのオーバーヘッドが大きいと考えられる
  - guidedが最速
    - 小さいオーバーヘッドと良好な負荷分散を両立している
]

#slide(title: [staticのチャンクサイズを変える])[
  - staticの`CHUNK_SIZE`を1とすればより均等に分割される（もともとのチャンクサイズは$frac(jp("ループの個数"), jp("スレッドの個数"))$であったことに注意）
  - 実行してみる
  ```bash
  === OpenMP threads: 4 ===
  static : 0.264197 ± 0.042221 s
  dynamic: 0.586862 ± 0.003830 s
  guided : 0.259611 ± 0.067941 s
  ```
  - 静的割り当てなぶんstaticはguidedより速くなるかと思ったが，明確に速くなるわけでも#linebreak()なかった
    - キャッシュヒット率の違い？#linebreak()guidedは序盤は連続アクセス，staticは4個飛びでバラバラ
]

#slide(title: [参考：collapse補助指示文])[
  - ネストされたループを並列化する際はcollapse補助指示文を用いることができる
  ```c
  #pragma omp parallel for [[[collapse(2)]]]
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      C[i][j] = A[i][j] + B[i][j];
    }
  }
  ```
  - for文の間に何か操作を挟むことはできない（純粋な二重ループでないといけない）
  - `collapse(n)` で $n$ 層のループを*大きな一つのループとみなして*並列化できる
  - `schedule` 補助指示文と組み合わせることもできる
]

#slide(title: [collapseの挙動を調べてみる])[
  - `collapse.c` を実行
  - スレッドごとに色分けしてどのループを担当しているか可視化
  - `schedule` の指定なし（自動的に `static` になる）での実行結果：

  #align(center)[
    #image("img/collapse_static.png", width: 100%, height: 70%, fit: "contain")
  ]
]

#slide(title: [collapseの挙動を調べてみる])[
  - `schedule(dynamic, 1)` での実行結果：
  #align(center)[
    #image("img/collapse_dynamic.png", width: 100%, height: 75%, fit: "contain")
  ]
  - 二重ループ的な構造はもはや関係ない
]

#slide(title: [collapseが役立つ場面])[
  - 二重ループを展開することで，分散すべきイテレーションの個数が増える
  - 上記のようなCPU上のプログラムではあまり嬉しさはないかもしれないが，役に立つ例としては*GPU上でのfor文の並列化*などが考えられる
  - 詳細はAppendixの例を参照
]

== スレッド数のチューニング

#slide(title: [最適なスレッド数は？])[
  - 話は変わって，最適なスレッド数について考えてみる
  - スレッドを増やすほど性能が向上するわけではない
    - そもそも#text(weight: "bold")[論理コアの数]までしかスレッドは同時に実行できない
  - 利用可能な論理コア数を知るためのコマンド
    - Linux： `nproc`
    - Mac OS： `sysctl -n hw.logicalcpu`
  - Miyabi-gでは論理コア数は72
]

#slide(title: [スレッド数と実行時間の関係①：計算が重い例])[
  #set text(size: 0.95em)
  - 各要素で重い計算を行う `measure_threads_compute.c` をスレッド数を変えながら実行
    - 十分に計算量が大きいため，並列化の効果が大きいことが期待される

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      WORK = 100
      #pragma omp parallel for
      for (long i = 0; i < N; i++) {
        double x = 1.0 + 1.0e-9 * i;
        for (int k = 0; k < WORK; k++) {
          x = x * 1.0000001 + 0.0000001;
          x = x * 0.9999999 + 0.0000002;
        }
        out[i] = x;
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_compute.png", width: auto)
      ]
    ],
  )


  - スレッド数を増やすと speedup も増えるが，論理コア数付近でideal speedupから離れる
]

#slide(title: [スレッド数と実行時間の関係②：メモリ帯域の影響])[
  #set text(size: 0.95em)
  - スレッド数を増やしても，必ず性能が伸び続けるわけではない
  - 例：大きな配列に対する単純な演算（`measure_threads_mem.c`）
    - この処理は計算量に比べてメモリアクセスが多い
    - `B[i]`, `C[i]` を読み，`A[i]` に書く
  - スレッドを増やすと，CPUコアではなく*メモリ帯域*が先に限界になることがある

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      #pragma omp parallel for
      for (long i = 0; i < N; i++) {
        A[i] = B[i] + 2.0 * C[i];
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_mem.png", width: auto)
      ]
    ],
  )
]

#slide(title: [スレッド数と実行時間の関係③：競合の影響])[
  #set text(size: 0.9em)
  - 正しく同期していても，スレッド数を増やすほど速くなるとは限らない
  - 例：ヒストグラム計算（`measure_threads_hist.c`）
  - `atomic` によりデータ競合は防げる
  - しかし，複数スレッドが同じ `hist[bin]` を頻繁に更新すると，その場所がボトルネックになる
  - データが一部の bin に偏っていると，スレッド数を増やすほど競合が激しくなる

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      #pragma omp parallel for
      for (int i = 0; i < N; i++) {
        int bin = data[i];
        #pragma omp atomic
        hist[bin]++;
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_hist.png", width: auto)
      ]
    ],
  )
]


= その他の構文

#slide(title: [single構文])[
  - #text(weight: "bold")[並列領域の中で，1スレッドにだけ実行させたい処理を書く際に使う]
  - single構文の内部は，1つのスレッドのみが実行する
  - どのスレッドが実行するかは不定
  - nowait補助指定文を用いない限り，#text(weight: "bold")[single終了後に同期が入る]
  - 詳細は `single.c` も参照
  ```c
  #pragma omp parallel
  {
    [[[#pragma omp single]]]
    {
      work();
    }
  }
  ```
]

#slide(title: [masked構文])[
  - `single` 構文と似ており，チーム内の一部のスレッドだけが実行する
  - 節を指定しない場合，#text(weight: "bold")[thread 0 が実行する]
    - `filter` 節により，実行するスレッドを指定できる
  - #text(weight: "bold")[終了後に暗黙の同期は入らない]
  - 詳細は `masked.c` も参照
    - なお，以前使われていた `master` 構文はdeprecatedであり，OpenMP 5.1 からは `masked` の使用が推奨される

  ```c
  #pragma omp parallel
  {
    [[[#pragma omp masked]]]
    {
      work();
    }
  }
  ```
]

#slide(title: [ループ以外の並列化①：section構文])[
  - for構文よりもう少し自由度の高い(?)並列化方法
  - 各sectionがスレッドに割り当てられる
  ```c
  [[[#pragma omp parallel sections]]]
  {
    [[[#pragma omp section]]]
    {
      work1();
    }
    [[[#pragma omp section]]]
    {
      work2();
    }
  }
  ```
  - 詳細は略
]


#slide(title: [ループ以外の並列化②：task構文])[
  - いわゆる「タスク並列」のための構文
  - これまでは，主に `for` ループの各反復をスレッドに分配する方法を見てきた
  - しかし，並列化したい処理がいつも `for` ループの形で書けるとは限らない
    - 再帰的な分割統治法
    - 木構造・グラフ構造の探索
    - 実行中に新しい仕事が動的に生まれる処理
  - task構文を使えば，並列化の単位をより柔軟に設定できる
]


#slide(title: [ループ以外の並列化②：task構文])[
  #set text(size: 0.9em)
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 1em,
    [
      - 例：フィボナッチ数列の計算
      ```c
      int fib(int n) {
        if (n < 2) return n;
        else{
          [[[#pragma omp task]]] shared(x) firstprivate(n)
          x = fib(n - 1);
          [[[#pragma omp task]]] shared(y) firstprivate(n)
          y = fib(n - 2);
          [[[#pragma omp taskwait]]]
          return x + y;
        }
      }

      #pragma omp parallel
      {
        [[[#pragma omp single]]]
        printf("Fibonacci of %d is %d\n", 10, fib(10));
      }
      ```
    ],
    [
      #set text(size: 0.9em)
      - *`task`* は，「あとで誰かが実行できる仕事」を作るための構文
        - 注：`task` は，新しいスレッドを作る指示ではない
        - 生成されたタスクは，OpenMPランタイムが既存のスレッドに割り当てて実行する
      - *`taskwait`* により，生成した子タスクの完了を待つことができる
    ]
  )
]

#slide(title: [ループ以外の並列化②：task構文])[
  #set text(size: 0.9em)
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 1em,
    [
      - 例：フィボナッチ数列の計算
      ```c
      int fib(int n) {
        if (n < 2) return n;
        else{
          [[[#pragma omp task]]] shared(x) firstprivate(n)
          x = fib(n - 1);
          [[[#pragma omp task]]] shared(y) firstprivate(n)
          y = fib(n - 2);
          [[[#pragma omp taskwait]]]
          return x + y;
        }
      }

      #pragma omp parallel
      {
        [[[#pragma omp single]]]
        printf("Fibonacci of %d is %d\n", 10, fib(10));
      }
      ```
    ],
    [
      #set text(size: 0.9em)
      - 全スレッドが `fib(10)` を呼ぶと，同じ計算を重複して実行してしまう
      - そのため，`single` または `masked` により，最初のタスク生成は1スレッドだけが行う
      - 生成されたタスクは，他の待機中のスレッドも#linebreak()実行できる
    ]
  )
]

#slide(title: [taskwaitの役割])[
  - `taskwait` は，現在のタスクが生成した子タスクの完了を待つ
  - Fibonacciの例では，`fib(n - 1)` と `fib(n - 2)` の結果が揃うまで待つ必要がある
  - `taskwait` がないと，`x` や `y` が計算される前に `x + y` を返してしまう可能性がある
  ```c
  #pragma omp task shared(x) firstprivate(n)
  x = fib(n - 1);
  #pragma omp task shared(y) firstprivate(n)
  y = fib(n - 2);
  [[[#pragma omp taskwait]]]
  return x + y;
  ```
]

#slide(title: [タスク実行の可視化])[
  #set text(size: 0.9em)
  - `fib_tree.c` を実行し，`animate_fib.py` で タスク生成の様子を可視化してみる

  #align(center)[
    #image("img/fibonacci_tasks_animation.gif", width: 80%)
  ]

  - #link("https://github.com/yukim0359/OpenMP-tutorial/blob/main/slide/img/fibonacci_tasks_animation.gif")[GIFへのリンク]
]

// #slide(title: [`fib.c` の実行])[
//   - `fib.c` を実行
//   - 実行結果の例：
//   ```bash
//   $ ./fib
//   serial version
//   Fibonacci of 50 is 12586269025
//   Elapsed time: 51.424394 seconds

//   $ OMP_NUM_THREADS=4 ./fib
//   OpenMP version
//   threads: 4
//   Fibonacci of 50 is 12586269025
//   Elapsed time: 23.339175 seconds
//   ```
// ]

#slide(title: [[補足] Fibonacci例の注意点])[
  - Fibonacciは，task構文の動きを説明するには分かりやすい
  - しかし，実用的な高性能化の例としてはあまり良くない
    - そもそもタスク並列で計算する必然性がない
    - タスクが細かすぎるため，計算量に対してタスク生成オーバーヘッドが支配的
    - 現実のタスク並列プログラムらしくない
  - むしろ，ランタイムのオーバーヘッドを測る目的でよく用いられる
  - より「ちゃんとした」タスク並列のベンチマークとしては#link("https://github.com/bsc-pm/bots")[BOTS]などを参照
]

#slide(title: [task生成の粒度制御])[
  #set text(size: 0.9em)
  - タスクの作成や管理にはオーバーヘッドが生じる
    - タスクの問題サイズが十分小さければ，いちいちタスク化して分配するより，逐次実行した方が速い
  - そのため，実用上はこのような閾値（*cutoff*）を設けることが多い

  ```c
  int fib(int n) {
    [[[if (n < 20) {]]]
      [[[return fib_serial(n);]]]
    [[[}]]]

    int x, y;
    #pragma omp task shared(x) firstprivate(n)
    x = fib(n - 1);
    #pragma omp task shared(y) firstprivate(n)
    y = fib(n - 2);
    #pragma omp taskwait
    return x + y;
  }
  ```
]

#slide(title: [`if` 節])[
  - OpenMPの `task` には `if` 節を付けることもできる
  - 条件が真なら通常のタスクとして生成される
  - 条件が偽なら，基本的にはその場で実行されるタスクになる
  - 手動のcutoffと同様に，細かすぎるタスクの生成を避ける目的で使える
  ```c
  #pragma omp task [[[if(n > 20)]]] shared(x) firstprivate(n)
  x = fib(n - 1);
  #pragma omp task [[[if(n > 20)]]] shared(y) firstprivate(n)
  y = fib(n - 2);
  ```
]

#slide(title: [[補足] タスク並列のスケジューリング (1/3)])[
  #set text(size: 0.9em)
  - タスク並列では，不規則性ゆえに*静的負荷分散*ではなく*動的負荷分散*が通常用いられる
  - 一番シンプルなのが，共有キュー方式
    - 共有のタスクキュー#text(size: 0.75em)[（実行可能なタスクを格納するキュー）]が一個存在し，全ワーカーがそこにタスクをpush/popする
    - キューアクセス時の競合が大きい
  #align(center)[
    #image("img/global_queue.pdf", width: auto, height: 60%)
  ] 
]

#slide(title: [[補足] タスク並列のスケジューリング (2/3)])[
  #set text(size: 0.9em)
  - 一方で，それよりも高速な動的負荷分散方式として*work stealing*がある
  - 各ワーカーは1つずつタスクキューを保持する
    - 自身のキューが空になった場合，他のキューからタスクを steal
    - キューアクセス時の競合を緩和できるため，#text(weight: "bold")[ワーカー数の増加に対してより良好にスケールする]ことが知られている

  #align(center)[
    #image("img/work_stealing.pdf", width: auto, height: 60%)
  ] 
]

#slide(title: [[補足] タスク並列のスケジューリング (3/3)])[
  #set text(size: 0.95em)
  #grid(
    columns: (1.2fr, 1fr),
    gutter: 1em,
    [
      - OpenMPの仕様上，具体的なスケジューリング方針は定められておらず，実装によって異なる
      - [要検証] ChatGPT曰く
        - GCC libgomp：共有キュー方式
        - LLVM libomp：work stealing
      - 実際にfibで`OMP_NUM_THREADS`をスケール#linebreak()させながら測定してみる
    ],
    [
      #align(center)[
        #image("img/fib_threads_timing.png", width: 100%)
      ]
    ]
  )

  - LLVM libompは良好にスケールする一方で，GCC libgompはスレッドを増やすほど遅くなる
]

#slide(title: [[補足] task depend])[
  - `depend` 節により，タスク間の依存関係を指定できる
  - 依存関係を持つ処理をDAGとして表現できる
    - 依存関係が満たされたタスクから順に実行される
    - 単なるfork-joinによる同期よりも細粒度の制御が可能になる

  #grid(
    columns: (1.8fr, 1fr),
    gutter: 1em,
    [
      ```c
      #pragma omp task [[[depend(out: A)]]]
      compute_A();
      #pragma omp task [[[depend(in: A)]]] [[[depend(out: B)]]]
      compute_B();
      #pragma omp task [[[depend(in: A)]]] [[[depend(out: C)]]]
      compute_C();
      #pragma omp task [[[depend(in: B, C)]]]
      compute_D();
      ```
    ],
    [
      #align(center)[
        #image("img/task_depend_dag.svg", width: 70%, fit: "contain")
      ]
    ]
  )
]

#slide(title: [[補足] 分散メモリタスク並列処理系Itoyori])[
  - OpenMPのtaskは，共有メモリ環境におけるタスク並列
  - 複数ノードにまたがる分散メモリ環境でタスク並列を実現するのは簡単ではない
    - タスクをどのノードで実行するか
    - 必要なデータをどこに配置するか
    - ノード間通信をどのタイミングで行うか
    - 負荷分散をどのように行うか
  - Itoyoriは，このような*分散メモリ環境でのタスク並列を扱う処理系*の一例 (#link("https://dl.acm.org/doi/10.1145/3581784.3607049")[Paper], #link("https://github.com/itoyori/itoyori")[GitHub])
]

#slide(title: [[補足] GPUタスク並列処理系GTaP])[
  #set text(size: 0.9em)
  - GTaPは，GPU上でタスク並列を扱う処理系 (#link("https://arxiv.org/abs/2604.05982")[Paper], #link("https://github.com/yukim0359/GTaP")[GitHub])
  - GPU上に常駐するruntimeが，タスクの生成・実行・同期を管理する
    - CPUから細かいGPUカーネルを何度も起動するのではなく，GPU内でタスクをスケジューリング
    - *`#pragma gtap task`* / *`#pragma gtap taskwait`* により，OpenMP taskに近い形で記述できる
      - GPUでfork-joinをサポートするのはそんなに簡単ではない
  - 2つの実行モードをサポートする
    - *1スレッド1タスク*：
      細粒度で不規則なタスクを，多数のGPUスレッドで実行する
    - *1スレッドブロック1タスク*：
      タスク内部にデータ並列性がある場合に，1つのブロック内の#linebreak()スレッドが協調して実行する
]

= Appendix <touying:skip>

== SIMD

#slide(title: [OpenMPにおけるSIMD機能])[
  - SIMDを用いると，同じ命令を複数のデータに対して並列に実行できる
  - OpenMPでは `#pragma omp simd` でSIMD機能を使用できる
  ```c
  [[[#pragma omp simd]]]
  for (int i = 0; i < N; i++) {
    b[i] = 2 * a[i];
  }
  ```
]

#slide(title: [参考：コンパイルと最適化レポート])[
  - 以下のようにコンパイルすることで，ベクトル化に関する最適化レポートを `vec_report.txt` に出力できる
  - `-O3` は最適化レベルを指す
  ```bash
  $ gcc-15 -O3 [[[-fopt-info-vec-optimized=vec_report.txt]]] -fopenmp simd.c -o simd
  ```
  - 出力例：
  ```bash
  simd.c:30:21: optimized: loop vectorized using 16 byte vectors
  simd.c:30:21: optimized: loop vectorized using 8 byte vectors
  simd.c:18:10: optimized: loop vectorized using 16 byte vectors
  ```
  - たしかにSIMD化されていることがわかる
]

#slide(title: [参考：アセンブリの生成])[
  - 以下のようにコンパイルすることで，アセンブリを `simd.s` に出力できる
  ```bash
  $ gcc-15 -O1 -fopenmp -S simd.c -o simd.s
  ```
  - 出力例：
  ```text
  ldr q31, [x7, x1]           // x7 + x1 のアドレスから128bitロード（int型4つ分）
  add v31.4s, v31.4s, v31.4s  // v31の4つの32bit整数をそれぞれ2倍（ベクトル加算）
  str q31, [x0, x1]           // x0 + x1 のアドレスに128bitストア（結果を書き込み）
  ```
  - ベクトルレジスタにデータを格納後，4つの整数を一気に2倍している
  - Macの場合，#link("https://developer.arm.com/documentation/dht0002/a/Introducing-NEON?lang=en")[Arm Neon]というSIMD拡張が採用されているようである
  - SIMD命令のために用意されているレジスタ幅が128bitのため，32bit整数4つや64bit小数2つを一気に演算できる
]

#slide(title: [SIMDの有無による実行時間の比較])[
  - `make bench-simd` で各条件 10 回実行し，平均 ± 標準偏差を表示
    - 最適化レベル `-O1` のうえに `#pragma omp simd` を指定/非指定
    - そのうえで，アセンブリでSIMD命令が有効/無効化されていることを確認
  - SIMDありの場合
  ```bash
  $ make bench-simd
  # SIMD (simd), 10 runs each
    OMP_NUM_THREADS=1: 0.032581 ± 0.000935
    OMP_NUM_THREADS=4: 0.015092 ± 0.000373
  ```
  - SIMDなしの場合
  ```bash
  # scalar (simd_scalar), 10 runs each
    OMP_NUM_THREADS=1: 0.048844 ± 0.001819
    OMP_NUM_THREADS=4: 0.017411 ± 0.000664
  ```
]

#slide(title: [SIMDの有無による実行時間の比較])[
  #set text(size: 0.95em)
  - 上記は各条件 10 回測定の平均；標準偏差も併記している
  - ただし，SIMD化しても単純にベクトル幅の分だけ速くなるとは限らない
    - メモリアクセス，キャッシュ，ループ制御，命令スケジューリングなどの影響を受ける
    - 特にスレッド数を増やすと，メモリ帯域など他の要因がボトルネックになることがある
  - なお，自分の環境・このプログラムでは，そもそも最適化レベルを `-O3` にしてコンパイルすると，`#pragma omp simd` を指定しなくてもSIMD命令が有効化された
]

== OpenMPのGPU対応

#slide(title: [OpenMPのGPUへの対応])[
  - OpenMP 4.0以降，GPUなどのアクセラレータ向けの機能が追加された
  - `target` 指示文を使うことでGPUでの実行が可能
  - 似たようなアクセラレータ向けの指示文APIとして*OpenACC*がある
    - ACCはAcceleratorを意味する
    - OpenMPと異なり，アクセラレータ向けに最適化された設計
]

#slide(title: [OpenMP GPU offloadingの基本モデル])[
  #set text(size: 0.95em)
  ```c
  #pragma omp [[[target teams distribute parallel for \]]]
      [[[map(to: A[0:N], B[0:N]) map(from: C[0:N])]]]
  for (int i = 0; i < N; i++) {
    C[i] = A[i] + B[i];
  }
  ```
  - `target`：GPU側で実行する
  - `teams`：GPU上に複数のteamを作る
  - `distribute`：ループ反復をteam間に分配する
  - `parallel for`：team内のスレッドでループを並列実行する
  - `map`：hostとdevice間でデータを転送する
]

#slide(title: [GPU利用時の注意：データ転送コスト])[
  #set text(size: 0.95em)
  - GPUで計算しても，毎回データ転送を行うと性能が出ないことがある
    - hostメモリからdeviceメモリへ入力データを転送
    - device上で計算
    - deviceメモリからhostメモリへ結果を転送
  - 小さい計算を何度もGPUに投げると，計算時間より転送・起動オーバーヘッドが支配的に#linebreak()なりやすい
  ```c
  #pragma omp target data map(to: A[0:N], B[0:N]) map(from: C[0:N])
  {
    #pragma omp target teams distribute parallel for
    for (int i = 0; i < N; i++) {
      C[i] = A[i] + B[i];
    }

    // 必要なら，この中で複数回GPU計算を行う
  }
  ```
]

== プログラム例

#slide(title: [for並列のプログラム例：行列積])[
  #set text(size: 0.9em)
  - 行列積を OpenMP の for 並列で実装した例（チューニング済み）
    - ループ入れ替え（i-k-j）で A の行・B の行を順にアクセス
    - ブロック化（`TILE`）で L1/L2 キャッシュを有効利用
    - 外側ループを `#pragma omp parallel for` で並列化
  - `matmul_tuned.c` を参照
  ```c
  #pragma omp parallel for schedule(static)
  for (int ii = 0; ii < N; ii += TILE) {
    for (int kk = 0; kk < N; kk += TILE) {
      for (int jj = 0; jj < N; jj += TILE) {
        for (int i = ii; i < i_end; i++) {
          for (int k = kk; k < k_end; k++) {
            double a_ik = A[i][k];
            for (int j = jj; j < j_end; j++) {
              C[i][j] += a_ik * B[k][j];
            }
          }
        }
      }
    }
  }
  ```
]

#slide(title: [task並列のプログラム例：merge sort, cilk sort])[
  - 再帰的なソートは，OpenMPの `task` と相性がよい
    - 配列を分割し，部分配列のソートをタスクとして生成する
    - 小さくなった部分配列は，タスク化せず逐次ソートする
      - 例：挿入ソート，逐次merge sortなど
    - 子タスクの完了を `taskwait` で待ってから，結果をマージする
  - 単純な並列merge sort：
    - 左半分と右半分のソートをそれぞれタスク化
    - 最後のマージは逐次的に行う
  - Cilk sort：
    - *ソートだけでなく，マージ処理も再帰的に分割してタスク化する*
    - より細かく並列性を取り出せる
  - `parallel_merge_sort.c`，`cilk_sort.c` を参照
]

#slide(title: [GPU実行のプログラム例：行列積])[
  - 行列積のGPUでの並列化をOpenMPで実装する
    - 最適化はなし，シンプルなもの
  - `matmul_gpu.c` を参照
  ```c
  #pragma omp target data map(to:A[0:N][0:N], B[0:N][0:N]) map(from:C[0:N][0:N])
  {
    #pragma omp target teams distribute parallel for [[[collapse(2)]]]
    for(int i = 0; i < N; i++) {
      for(int j = 0; j < N; j++) {
        for(int k = 0; k < N; k++) {
          C[i][j] += A[i][k] * B[k][j];
        }
      }
    }
  }
  ```
]

#slide(title: [GPU実行のプログラム例：行列積])[
  - ここでは `collapse(2)` の有無による実行時間を比較してみる（miyabi-g上で実行）
  - 実行結果の例：

  ```bash
  $ ./matmul_gpu
  Use collapse
  Test passed!
  Computation time: 0.386624 seconds

  $ ./matmul_gpu
  No collapse
  Test passed!
  Computation time: 0.702773 seconds
  ```

  - `collapse` によりイテレーション個数が $N$ から $N^2$ に増え，GPU上の多数のスレッドに計算が行き渡ると考えられる
]

== 各種ディレクティブの実装

#slide(title: [各種ディレクティブの実装])[
  - 誤りを含む可能性があります
  - 以下gccにおけるOpenMPランタイム `libgomp` の内部実装に限って話を進める
  - 実装は #link("https://github.com/gcc-mirror/gcc/tree/releases/gcc-9.2.0/libgomp")[https://github.com/gcc-mirror/gcc/tree/releases/gcc-9.2.0/libgomp] を参照
]

#slide(title: [各種ディレクティブの実装①：スレッドの生成])[
  - parallelディレクティブは以下のように展開される
  ```c
  void subfunction (void *data)
  {
    use data;
    body;
  }

  setup data;
  GOMP_parallel_start (subfunction, &data, num_threads);
  subfunction (&data);
  GOMP_parallel_end ();
  ```
  - `GOMP_parallel_start` が `gomp_team_start()` を呼び出し，OSレベルのスレッドを生成（Linux, Mac：`pthread_create`）
  - gitリポジトリの `parallel.c`，`team.c` 参照
]

#slide(title: [各種ディレクティブの実装②：lockの実装])[
  - 自分の調べた範囲では `pthread_mutex` と同等
  - `config/posix/mutex.h` に以下のように定義されている
  ```c
  typedef pthread_mutex_t gomp_mutex_t;
  static inline void gomp_mutex_init (gomp_mutex_t *mutex)
  {
    pthread_mutex_init (mutex, NULL);
  }
  static inline void gomp_mutex_lock (gomp_mutex_t *mutex)
  {
    pthread_mutex_lock (mutex);
  }
  // 略
  ```
  - `lock.c` 参照
]

#slide(title: [各種ディレクティブの実装③：criticalの実装])[
  - 名前なしcriticalセクションの定義
  ```c
  void
  GOMP_critical_start (void)
  {
    /* There is an implicit flush on entry to a critical region. */
    __atomic_thread_fence (MEMMODEL_RELEASE);
    gomp_mutex_lock (&default_lock);
  }

  void
  GOMP_critical_end (void)
  {
    gomp_mutex_unlock (&default_lock);
  }
  ```
  - 結局mutexで管理していそう
  - `critical.c` 参照
]

#slide(title: [各種ディレクティブの実装④：atomicの実装])[
  - `atomic1.c` をアセンブリにすると，atomic部分は以下のようになる

  ```text
  ldadd w1, w0, [x0]
  ```

  - armにおいて `ldadd` は「メモリ位置 `[x0]` から値をロード→ `w0` の値を加算→結果を `[x0]` に#linebreak()ストア→元のメモリ値を `w1` に返す」を*不可分で*実行する命令
]

#slide(title: [各種ディレクティブの実装④：atomicの実装])[
  #set text(size: 0.9em)
  - もう少し複雑だとどうなるか
  - `atomic2.c` をアセンブリにすると，atomic部分は以下のようになる

  ```text
  LFB0:
      fadd    d0, d0, d0     // bを2倍
      ldr     x1, [x0]       // *aをx1に読み出し
  L2:
      fmov    d31, x1        // x1を浮動小数点レジスタd31に移動
      mov     x2, x1         // x1をx2にコピー
      fadd    d31, d0, d31   // d31 = *a + 2*b
      fmov    x3, d31        // x3に新しい値を格納
      cas     x2, x3, [x0]   // メモリ内の現値[x0]がx2（旧値）と一致すればx3（新値）をatomicに書き込み
                             // いずれの場合も元のメモリ値をx2に戻す
      cmp     x1, x2         // casの結果，x1==x2なら成功
      bne     L3             // 失敗なら再試行
      ret
  ```

  - CASループになっている
]
