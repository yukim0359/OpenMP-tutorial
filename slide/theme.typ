#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

#let accent = blue.darken(30%)

// 数式内で本文フォントを使うためのヘルパ（$ ... #jp[…] ... $ で使う）
#let jp(body) = text(
  font: ("IBM Plex Sans", "Hiragino Sans", "Helvetica Neue"),
  body,
)

// helper functions for the table of contents
#let plain-text(it) = {
  if type(it) == str { it }
  else if it.has("children") { it.children.map(plain-text).join() }
  else if it.has("body") { plain-text(it.body) }
  else if it.has("text") {
    if type(it.text) == str { it.text } else { plain-text(it.text) }
  } else { "" }
}

#let toc_current_color(
  level: 1,
  active: accent,
  inactive: rgb("#A3A3A3"),
  spacing: 0.85em,
  drop_title: "Contents",
) = context {
  let hs = query(heading.where(level: level))
  if hs == () { return [] }

  let cur = query(heading.where(level: level).before(here()))
  let cur_loc = if cur == () { none } else { cur.last().location() }

  let filtered = hs.filter(h => plain-text(h.body) != drop_title)

  let items = filtered.map(h => {
    let is_cur = (cur_loc != none) and (h.location() == cur_loc)
    link(h.location())[
      #set text(
        fill: if is_cur { active } else { inactive },
        weight: if is_cur { "bold" } else { "regular" },
        size: if is_cur { 1em } else { 0.9em },
      )
      #if is_cur { [▸ ] } else { [  ] }
      #(h.body)
    ]
  })

  stack(dir: ttb, spacing: spacing, ..items)
}

#let toc-styled-link(
  loc,
  body,
  is-active: false,
  active: accent,
  inactive: rgb("#A3A3A3"),
  size: 1em,
) = link(loc)[
  #set text(
    fill: if is-active { active } else { inactive },
    weight: if is-active { "bold" } else { "regular" },
    size: if is-active { size } else { size * 0.92 },
  )
  #if is-active { [▸ ] } else { [  ] }
  #body
]

// 章（level 1）一覧 + 現在の章だけ level 2 をインデント表示
// 章区切りスライドは == より先に描画されるため、level 2 は outline で先読みする
#let toc_chapter_nested(
  active: accent,
  inactive: rgb("#A3A3A3"),
  h1_size: 1em,
  h2_size: 0.78em,
  h1_spacing: 0.8em,
  h2_spacing: 0.48em,
  h2_indent: 1.4em,
  drop_title: "Contents",
) = context {
  let cur_h1_q = query(heading.where(level: 1).before(here()))
  let cur_h1_loc = if cur_h1_q == () { none } else { cur_h1_q.last().location() }

  let cur_h2_q = query(heading.where(level: 2).before(here()))
  let cur_h2_loc = if cur_h2_q == () { none } else { cur_h2_q.last().location() }

  block(width: 100%)[
    #show outline.entry.where(level: 1): it => {
      let title = plain-text(it.element.body)
      if title == drop_title { return none }
      let is_cur = (cur_h1_loc != none) and (it.element.location() == cur_h1_loc)
      block(width: 100%, below: h1_spacing)[
        #toc-styled-link(
          it.element.location(),
          it.element.body,
          is-active: is_cur,
          active: active,
          inactive: inactive,
          size: h1_size,
        )
      ]
    }
    #show outline.entry.where(level: 2): it => {
      if cur_h1_loc == none { return none }
      let h2-loc = it.element.location()
      let parent-h1 = query(heading.where(level: 1).before(h2-loc))
      if parent-h1 == () or parent-h1.last().location() != cur_h1_loc {
        return none
      }
      let is_cur = (cur_h2_loc != none) and (h2-loc == cur_h2_loc)
      block(width: 100%, below: h2_spacing)[
        #pad(left: h2_indent)[
          #toc-styled-link(
            h2-loc,
            plain-text(it.element.body),
            is-active: is_cur,
            active: active,
            inactive: inactive,
            size: h2_size,
          )
        ]
      ]
    }
    #set outline.entry(fill: none)
    #outline(depth: 2, title: none, indent: 0em)
  ]
}

// 左端アクセントバー（page.background に置くと全スライドで安定して表示される）
#let slide-accent-bar(width: 0.4em) = place(left + top)[
  #rect(fill: accent, width: width, height: 100%, inset: 0pt)
]

// 通常スライドのヘッダー：ベタ塗りなし・青文字（Metropolisのslideを上書き）
#let slide(
  title: auto,
  align: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if align != auto {
    self.store.align = align
  }
  let header(self) = {
    set std.align(top)
    show: components.cell.with(fill: none, inset: 1em)
    set std.align(horizon)
    set text(fill: accent, weight: "bold", size: 1.2em)
    pad(top: 0.5em)[
      #stack(
        dir: ttb,
        spacing: 1em,
        components.left-and-right(
          pad(left: 0.2em)[
            #if title != auto {
              utils.fit-to-width(grow: false, 100%, title)
            } else {
              utils.call-or-display(self, self.store.header)
            }
          ],
          utils.call-or-display(self, self.store.header-right),
        ),
        pad(left: -1em, right: 0.3em)[
          #line(length: 100%, stroke: (paint: accent, thickness: 1.5pt))
        ],
      )
    ]
  }
  let footer(self) = {
    set std.align(bottom)
    set text(size: 0.8em)
    pad(
      .5em,
      components.left-and-right(
        text(
          fill: self.colors.neutral-darkest.lighten(40%),
          utils.call-or-display(self, self.store.footer),
        ),
        text(fill: self.colors.neutral-darkest, utils.call-or-display(
          self,
          self.store.footer-right,
        )),
      ),
    )
  }
  let self = utils.merge-dicts(
    self,
    config-page(
      fill: self.colors.neutral-lightest,
      header: header,
      footer: footer,
      background: slide-accent-bar(),
    ),
  )
  let new-setting = body => {
    show: std.align.with(self.store.align)
    set text(fill: self.colors.neutral-darkest)
    show: setting
    body
  }
  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: new-setting,
    composer: composer,
    ..bodies,
  )
})
#let bg = rgb("#FCFCFD")

// my cover slide
#let my-cover-slide(
  info,
  title-size: 30pt,
  event-size: 21pt,
  author-size: 17pt,
  supervisor-size: 16pt,
  meta-size: 15pt,
  left-pad: 4%,
  right-pad: 1.5em,
  rule-width: 36em,
) = slide(
  title: none,
  config: config-page(
    margin: 0em,
    header: none,
    footer: none,
    header-ascent: 0em,
    footer-descent: 0em,
    background: none,
  ),
)[
  #box(width: 100%, height: 100%)[
    #grid(
      columns: (1%, 1fr),
      rows: (1fr,),
      gutter: 0pt,
      [
        #box(width: 100%, height: 100%)[
          #rect(fill: accent, width: 100%, height: 100%, inset: 0pt)
        ]
      ],
      [
        #box(width: 100%, height: 100%)[
          #stack(dir: ttb, spacing: 0.55em)[
            #pad(left: left-pad, right: right-pad)[

              #v(2.5em)

              #align(left + horizon)[
                #box[
                  #set text(size: title-size, weight: "bold", fill: accent)
                  #(info.title)
                ]
              ]
            ]

            #pad(left: 0%, right: right-pad)[
              #box(width: 100%)[
                #rect(fill: accent, width: 100%, height: 2.2pt, inset: 0pt)
              ]
            ]

            #pad(left: 4%, right: right-pad)[
              #v(-0.2em)

              #align(right + horizon)[
                #box[
                  #text(size: event-size, weight: "semibold", fill: accent)[#(info.event)]
                ]
              ]

              #v(8.5em)

              #align(right + horizon)[
                #box[
                  #text(size: author-size)[
                    #text(weight: "semibold", size: 1.15em)[#(info.author)]
                  ]
                ]

                #text(size: meta-size)[
                  #if info.institution != none { info.institution }
                ]

                #v(0.3em)

                #text(size: meta-size)[
                  #if info.date != none { info.date }
                ]
              ]
            ]
          ]
        ]
      ],
    )
  ]
]

#let toc-divider-slide-body = [
  #grid(
    columns: (1fr, 3fr),
    rows: (1fr,),
    gutter: 0pt,
    [
      #box(width: 100%, height: 100%)[
        #rect(fill: accent, width: 100%, height: 100%, inset: 0pt)[
          #align(left)[
            #pad(left: 1.2em)[
              #set text(fill: white, size: 32pt)
              目次
            ]
          ]
        ]
      ]
    ],
    [
      #rect(fill: bg, width: 100%, height: 100%, inset: 0pt)[
        #pad(left: 2.0em, right: 1.5em, top: 1.8em, bottom: 1.2em)[
          #set text(size: 24pt)
          #toc_chapter_nested()
        ]
      ]
    ],
  )
]

// slide for splitting a section (= 章)
#let split-section-slide(short-title: auto, title, body: none) = slide(
  title: none,
  config: config-page(
    margin: (left: 0em, right: 0em, top: 0em, bottom: 0em),
    header: none,
    header-ascent: 0em,
    footer-descent: 0em,
    background: none,
  ),
)[
  #toc-divider-slide-body
]

// slide for splitting a subsection (== 小節)
#let split-subsection-slide(short-title: auto, title, body: none) = slide(
  title: none,
  config: config-page(
    margin: (left: 0em, right: 0em, top: 0em, bottom: 0em),
    header: none,
    header-ascent: 0em,
    footer-descent: 0em,
    background: none,
  ),
)[
  #toc-divider-slide-body
]

#let outline-box(
  width: auto,
  height: auto,
  stroke: black,
  radius: 4pt,
  thickness: 1pt,
) = rect(
  fill: none,
  stroke: (paint: stroke, thickness: thickness),
  radius: radius,
  width: width,
  height: height,
  inset: 0pt,
)

#let card(
  title,
  body,
  fill: rgb("#F0F5FF"),
  header-fill: blue.darken(40%),
  stroke: accent,
  accent: none,
) = [
  #rect(
    fill: fill,
    stroke: (paint: stroke, thickness: 1pt),
    radius: 10pt,
    width: 100%,
    inset: 0em
  )[
    // header
    #rect(
      fill: header-fill,
      stroke: (paint: header-fill, thickness: 1pt),
      radius: (top-left: 10pt, top-right: 10pt, bottom-left: 0pt, bottom-right: 0pt),
      width: 100%,
    )[
      #pad(left: 0.6em, right: 0.2em, top: 0.4em, bottom: 0.4em)[
        #if accent != none [
          #grid(
            columns: (4pt, 1fr),
            gutter: 0.6em,
            [
              #rect(fill: accent, radius: 2pt, width: 4pt, height: 100%)
            ],
            [
              #set text(weight: "semibold")
              #title
            ],
          )
        ] else [
          #set text(weight: "semibold", fill: white)
          #title
        ]
      ]
    ]
    #v(-0.4em)
    // body
    #pad(left: 1.0em, right: 1.0em, top: 0em, bottom: 0.9em)[
      #set text(weight: "regular")
      #body
    ]
  ]
]

#let card_h(
  title,
  body,
  fill: rgb("#D3F0F8"),
  title-fill: rgb("#0B5568"),
  stroke: rgb("#55C3DD"),
  title-width: 8.0em,
  radius: 10pt,
) = [
  #rect(
    fill: fill,
    stroke: (paint: stroke, thickness: 1pt),
    radius: radius,
    width: 100%,
    inset: 0em
  )[
    #grid(
      columns: (title-width, 1fr),
      gutter: 0pt,

      // 左：タイトル帯（縦に引き延ばさない）
      [
        #rect(
          fill: title-fill,
          stroke: (paint: stroke, thickness: 1pt),
          radius: (
            top-left: radius,
            bottom-left: radius,
            top-right: 0pt,
            bottom-right: 0pt,
          ),
          width: 100%,
        )[
          // 境界側(右)の余白を詰めて“隙間感”を減らす
          #pad(left: 0.8em, right: 0.5em, top: 0.65em, bottom: 0.65em)[
            #set text(fill: white, weight: "semibold")
            #title
          ]
        ]
      ],

      // 右：本文（境界側(左)の余白を詰める）
      [
        #pad(left: 1.0em, right: 1.0em, top: 0.65em, bottom: 0.65em)[
          #set text(weight: "regular")
          #body
        ]
      ],
    )
  ]
]

#let callout(body, fill: white) = rect(
  fill: fill,
  stroke: (paint: accent, thickness: 1.5pt),
  radius: 8pt,
)[
  #pad(left: 0.8em, right: 0.8em, top: 0.5em, bottom: 0.5em)[
    #text()[#body]
  ]
]

#let bubble(
  body,
  fill: white,
  stroke: accent,
  thickness: 1.5pt,
  radius: 8pt,

  // tail config
  side: "bottom",               // "bottom" | "top" | "left" | "right"
  tip: none,                    // (x, y) 先端（本体左上基準）。noneなら自動
  root: none,                   // ((x1,y1),(x2,y2)) 根元2点。noneなら自動
  tail_w: 16pt,                 // 自動時の根元幅
  tail_h: 10pt,                 // 自動時の先端距離
  tail_pos: 0.5,                // 自動時の根元中心（0..1）
  margin: 5pt,                  // 根元外側への延長
  mask: white,                  // 背景色（根元消し用）
) = context {
  let box = rect(
    fill: fill,
    stroke: (paint: stroke, thickness: thickness),
    radius: radius,
  )[
    #pad(left: 0.8em, right: 0.8em, top: 0.5em, bottom: 0.5em)[
      #text()[#body]
    ]
  ]

  let m = measure(box)

  // --- root（根元2点）の自動生成 ---
  let auto_root = if side == "bottom" {
    let cx = tail_pos * m.width
    ((cx - tail_w/2, m.height), (cx + tail_w/2, m.height))
  } else if side == "top" {
    let cx = tail_pos * m.width
    ((cx - tail_w/2, 0pt), (cx + tail_w/2, 0pt))
  } else if side == "left" {
    let cy = tail_pos * m.height
    ((0pt, cy - tail_w/2), (0pt, cy + tail_w/2))
  } else { // "right"
    let cy = tail_pos * m.height
    ((m.width, cy - tail_w/2), (m.width, cy + tail_w/2))
  }

  let r = if root == none { auto_root } else { root }
  let p1 = r.at(0)
  let p2 = r.at(1)

  // --- tip（先端）の自動生成 ---
  let auto_tip = if side == "bottom" {
    ((p1.at(0) + p2.at(0)) / 2, m.height + tail_h)
  } else if side == "top" {
    ((p1.at(0) + p2.at(0)) / 2, -tail_h)
  } else if side == "left" {
    (-tail_h, (p1.at(1) + p2.at(1)) / 2)
  } else { // "right"
    (m.width + tail_h, (p1.at(1) + p2.at(1)) / 2)
  }

  let t = if tip == none { auto_tip } else { tip }

  // 根元マスク線（p1->p2 を少し太めで）
  let mask_th = thickness * 1.5

  // 根元外側に延長するための「外向き」方向
  // bottom/top: x方向に延長、left/right: y方向に延長
  let ext = if side == "bottom" or side == "top" {
    // 左右へ margin
    ((p1.at(0) - margin, p1.at(1)), (p2.at(0) + margin, p2.at(1)))
  } else {
    // 上下へ margin
    ((p1.at(0), p1.at(1) - margin), (p2.at(0), p2.at(1) + margin))
  }

  let e1 = ext.at(0)
  let e2 = ext.at(1)

  // 先端と根元2点を結ぶ一筆書き輪郭
  // e1 -> p1 -> tip -> p2 -> e2
  block(width: m.width, height: m.height)[
    // 本体
    #place(top + left)[#box]

    // 根元の枠線消し
    #place(top + left)[
      #line(
        stroke: (paint: mask, thickness: mask_th),
        start: p1,
        end: p2,
      )
    ]

    // 口の輪郭（つながり途切れ防止のため margin 付き）
    #place(top + left)[
      #curve(
        stroke: (paint: stroke, thickness: thickness),
        curve.move(e1),
        curve.line(p1),
        curve.line(t),
        curve.line(p2),
        curve.line(e2),
      )
    ]
  ]
}

// my citation
#let my-cite(key, size: 0.8em, color: accent, weight: "semibold") = [
  #set text(size: size, fill: color, weight: weight)
  #cite(key)
]

// helper for animation
#let pdf_anim(path, last, width: auto) = {
  for p in range(1, last + 1) {
    only(p)[
      #image(path, page: p, width: width)
    ]
  }
}

// 外部 URL だけ下線（目次など label / location への link はそのまま）
#let link-dest-is-external-url(dest) = (
  type(dest) == str
    and (
      dest.starts-with("http://")
        or dest.starts-with("https://")
        or dest.starts-with("mailto:")
        or dest.starts-with("tel:")
    )
)

// デッキ共通フッター（章区切りスライドはページ番号なし）
#let deck-footer(event) = self => context {
  let slides = query(<touying-metadata>).filter(it => utils.is-kind(it, "touying-new-slide"))

  let h1s = query(heading.where(level: 1))
  let h2s = query(heading.where(level: 2))
  let is_section_page = p => (
    h1s.any(h => h.location().page() == p)
      or h2s.any(h => h.location().page() == p)
  )

  let normal_slides = slides.filter(sl => not is_section_page(sl.location().page()))
  let cur_page = here().page()

  if is_section_page(cur_page) {
    return [
      #grid(
        columns: (1fr, auto, 1fr),
        [],
        [
          #align(center)[
            #text(size: 0.75em)[#event]
          ]
        ],
        [],
      )
    ]
  }

  let cur = normal_slides.filter(sl => sl.location().page() <= cur_page).len()
  let total = normal_slides.len()

  [
    #grid(
      columns: (1fr, auto, 1fr),
      [],
      [
        #align(center)[
          #text(size: 0.75em)[#event]
        ]
      ],
      [
        #align(right)[
          #text(size: 1.15em, fill: blue.darken(20%), weight: "semibold")[#cur]
          #text(size: 0.9em, fill: blue.darken(20%))[#text("/")#total]
        ]
      ],
    )
  ]
}

// デッキメタデータを受け取り Touying テーマを構成する
#let my-deck-theme(info) = metropolis-theme.with(
  aspect-ratio: "16-9",
  align: horizon,

  footer-progress: false,
  footer: deck-footer(info.event),
  footer-right: _ => [],

  config-common(
    slide-level: 2,
    new-section-slide-fn: split-section-slide,
    new-subsection-slide-fn: split-subsection-slide,
    receive-body-for-new-subsection-slide-fn: false,
  ),
  config-store(footer-progress: false),
  config-info(
    title: info.title,
    author: info.author,
    date: info.date,
    institution: info.institution,
  ),
  config-colors(
    primary: blue,
    primary-light: white,
    secondary: accent,
    neutral-lightest: white,
    neutral-darkest: rgb("#2E3440"),
  ),
)

// define theme
#let apply-my-theme(doc) = [
  #set text(
    font: (
      "IBM Plex Sans",
      "Hiragino Sans",
      "Helvetica Neue",
    ),
    fill: rgb("#2d2d3a"),
  )

  #show heading.where(level: 1): set text(weight: "semibold")
  // level 2 は目次用。見た目は小節区切りスライドに任せる
  #show heading.where(level: 2): it => text(size: 0pt, height: 0pt, fill: white)[#it]

  #show link: it => {
    if link-dest-is-external-url(it.dest) {
      underline(it)
    } else {
      it
    }
  }
  #show footnote: it => [#super(it, baseline: -0.6em)#h(0.1em)]
  #show super: set text(size: 0.8em)
  #show footnote.entry: set text(size: 0.8em)
  #show figure.caption: set text(size: 0.7em)

  // raw ブロック内の色付き強調: [[[ ]]]=赤, ((( )))=青, {{{ }}}=緑
  #let color-split(s, open-str, close-str, c) = {
    let parts = s.split(open-str)
    let out = ()
    out.push(parts.at(0))
    for i in range(1, parts.len()) {
      let p = parts.at(i)
      if p.contains(close-str) {
        let a = p.split(close-str)
        out.push(text(fill: c, weight: "semibold")[#(a.at(0))])
        if a.len() > 1 {
          out.push(a.slice(1).join(close-str))
        }
      } else {
        out.push(text(fill: c, weight: "semibold")[#p])
      }
    }
    out
  }
  #show raw.where(block: true): it => {
    set text(size: 0.9em)
    let s = it.text
    let red-parts = color-split(s, "[[[", "]]]", red)
    let blue-parts = ()
    for x in red-parts {
      if type(x) == str {
        for y in color-split(x, "(((", ")))", blue) {
          blue-parts.push(y)
        }
      } else {
        blue-parts.push(x)
      }
    }
    let out = ()
    for x in blue-parts {
      if type(x) == str {
        for y in color-split(x, "{{{", "}}}", rgb("#0d7d3d")) {
          out.push(y)
        }
      } else {
        out.push(x)
      }
    }
    block(width: 100%, above: 1em, below: 1em)[
      #align(left)[
        #box(
          width: 100%,
          fill: rgb("#f6f6f6"),
          inset: (left: 1em, right: 1em, top: 0.5em, bottom: 0.5em),
          radius: 4pt,
          out.join(),
        )
      ]
    ]
  }

  #set list(marker: ([•], [◦], [▸]))

  #doc
]
