"""
归因分析 SOP v2 框架图 —— 重构版（2026-04-30）
Q3 改为并行下钻 → 交叉矩阵 → 专项深挖
Q2 改为分表策略（订单表分区完整性 / 电销表 P99）
"""

W = 2400
PAD = 60
CX = W // 2


def rect(x, y, w, h, fill, rx=10, stroke=None, sw=2, opacity=1):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{sw}"'
    if opacity != 1:
        s += f' opacity="{opacity}"'
    s += '/>'
    return s


def txt(x, y, content, size=22, fill='#333', anchor='start', weight='normal'):
    return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" fill="{fill}" '
            f'font-size="{size}" font-weight="{weight}">{content}</text>')


def arrow(x1, y1, x2, y2, color='#666', sw=2.5):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
            f'stroke="{color}" stroke-width="{sw}" marker-end="url(#arrow)"/>')


def seg(x1, y1, x2, y2, color='#999', sw=2):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
            f'stroke="{color}" stroke-width="{sw}"/>')


lines = []

# ── SVG 头 + defs ──────────────────────────────────────────────
TOTAL_H = 5600
lines.append(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {TOTAL_H}" '
    f'font-family="PingFang SC, Heiti SC, STHeiti, Microsoft YaHei, sans-serif">'
)
lines.append('''<defs>
  <marker id="arrow" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#666"/>
  </marker>
  <marker id="arrow-blue" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#3B82F6"/>
  </marker>
  <marker id="arrow-purple" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#7C3AED"/>
  </marker>
  <marker id="arrow-orange" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#D97706"/>
  </marker>
</defs>''')
lines.append(f'<rect width="{W}" height="{TOTAL_H}" fill="#F0F2F5"/>')


# ══════════════════════════════════
# 标题栏
# ══════════════════════════════════
y = 24
lines.append(rect(PAD, y, W - PAD * 2, 90, '#1A365D', rx=14))
lines.append(txt(CX, y + 48, '洋葱学园 · 异动归因分析框架 SOP v2.0',
                 size=44, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 78, 'Business Metric Attribution Analysis — BI Team',
                 size=22, fill='#90CDF4', anchor='middle'))


# ══════════════════════════════════
# Q1 异动精确化
# ══════════════════════════════════
y = 140
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#2B6CB0', rx=12))
lines.append(txt(CX, y + 32, 'Q1  异动精确化 · Anomaly Definition',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '明确：指标 / 时间周期 / 目标维度 / 异动幅度',
                 size=20, fill='#BEE3F8', anchor='middle'))

y = 230
BH1 = 200
lines.append(rect(PAD, y, W - PAD * 2, BH1, 'white', stroke='#BEE3F8', sw=2))

col_w = (W - PAD * 2 - 48) // 3
col_x = [PAD + 24, PAD + 24 + col_w + 12, PAD + 24 + (col_w + 12) * 2]

lines.append(txt(col_x[0], y + 38, '输入规范', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 指标：GMV / 付费人数 / 线索量 / 转化率 / ARPU',
    '· 周期：Current 周 vs Baseline 周（默认环比上周）',
    '· 特殊节假日可选同比，需标注',
]):
    lines.append(txt(col_x[0], y + 72 + i * 36, t, size=19, fill='#444'))

lines.append(txt(col_x[1], y + 38, '异动判定阈值', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 核心指标（GMV/付费人数）：|变化率| ≥ 4%',
    '  且绝对值 ≥ 1万元 → 触发归因流程',
    '· 过程指标（CVR/AOV）：|变化率| ≥ 10% → 触发',
]):
    lines.append(txt(col_x[1], y + 72 + i * 36, t, size=19, fill='#444'))

lines.append(txt(col_x[2], y + 38, '本次案例', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 全学段 GMV：4,681,322 → 4,456,178',
    '  ↓ 4.8%，-22.5万',
    '· 付费用户：5,342 → 4,891（↓8.4%）',
]):
    lines.append(txt(col_x[2], y + 72 + i * 36, t, size=19, fill='#444'))

ay = y + BH1
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q2 真伪判定（分表策略）
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#276749', rx=12))
lines.append(txt(CX, y + 32, 'Q2  真伪判定 · Authenticity Check',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '分表策略：订单表只查分区完整性；电销表额外做 P99 极值校验',
                 size=20, fill='#9AE6B4', anchor='middle'))

y += 88
BH2 = 210
gap2 = 24
bw2 = (W - PAD * 2 - gap2) // 2

# 左：订单表
bx = PAD
lines.append(rect(bx, y, bw2, BH2, 'white', stroke='#9AE6B4', sw=2))
lines.append(rect(bx, y, bw2, 40, '#276749', rx=8))
lines.append(txt(bx + bw2 // 2, y + 26, '📋  订单表质检（topic_order_detail）',
                 size=21, fill='white', anchor='middle', weight='bold'))
order_items = [
    '① 分区完整性：每日 order_cnt vs 历史7天均值',
    '   偏差 > 50% 且无业务原因 → 标记[数据延迟]，终止',
    '② 基线合理性：两周节假日节奏是否一致',
    '   若基线含大促波峰 → 切换[去促基线]',
    '★ 不做极值剔除（电商单笔金额差异小，分布稳定）',
]
for i, t in enumerate(order_items):
    lines.append(txt(bx + 24, y + 56 + i * 28, t, size=18,
                     fill='#553C9A' if t.startswith('★') else '#444'))
lines.append(rect(bx + 10, y + BH2 - 38, bw2 - 20, 28, '#F0FFF4', rx=4))
lines.append(txt(bx + 24, y + BH2 - 18, '✅ 本案：日均偏差 4.4%，两周节奏一致，数据真实',
                 size=18, fill='#276749', weight='bold'))

# 右：电销表
bx = PAD + bw2 + gap2
lines.append(rect(bx, y, bw2, BH2, 'white', stroke='#9AE6B4', sw=2))
lines.append(rect(bx, y, bw2, 40, '#276749', rx=8))
lines.append(txt(bx + bw2 // 2, y + 26, '📞  电销表质检（crm_order_info）',
                 size=21, fill='white', anchor='middle', weight='bold'))
crm_items = [
    '① 分区完整性：每日 order_cnt 合理性校验（同订单表）',
    '② P99 极值剔除：单笔 amount > PERCENTILE(0.99)',
    '   电销单笔金额差异大，超大单会扭曲趋势，必须过滤',
    '③ 日期字段：使用 pay_time（不是 paid_time）',
    '★ is_test = false | amount ≥ 39 为基础过滤条件',
]
for i, t in enumerate(crm_items):
    lines.append(txt(bx + 24, y + 56 + i * 28, t, size=18,
                     fill='#553C9A' if t.startswith('★') else '#444'))
lines.append(rect(bx + 10, y + BH2 - 38, bw2 - 20, 28, '#F0FFF4', rx=4))
lines.append(txt(bx + 24, y + BH2 - 18, '✅ 本案：P99 = 5,798 元，已过滤，趋势无扭曲',
                 size=18, fill='#276749', weight='bold'))

y += BH2 + 10
lines.append(rect(PAD, y, W - PAD * 2, 44, '#F0FFF4', stroke='#9AE6B4', sw=1.5))
lines.append(txt(CX, y + 28, 'Q2 结论：数据真实，GMV 环比 -4.8%，触发归因流程 ✅',
                 size=22, fill='#276749', anchor='middle', weight='bold'))

ay = y + 44
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q3 定位下钻（新三层逻辑）
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#744210', rx=12))
lines.append(txt(CX, y + 32, 'Q3  定位下钻 · 并行 → 交叉 → 专项',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '第一层并行下钻，第二层交叉验证，第三层根据结果决定专项方向',
                 size=20, fill='#FBD38D', anchor='middle'))

# ─── 第一层：并行下钻标题 ───
y += 88
lines.append(rect(PAD, y, W - PAD * 2, 46, '#FFFBEB', stroke='#F6AD55', sw=1.5, rx=8))
lines.append(txt(PAD + 24, y + 16, '第一层  并行下钻（同时运行两个维度，互不依赖）',
                 size=22, fill='#744210', weight='bold'))
lines.append(txt(PAD + 24, y + 38, 'GMV 总Δ = Σ(学段贡献)  =  Σ(渠道贡献)  → 两路各自找 TOP 跌点',
                 size=19, fill='#555'))

y += 56
half_w = (W - PAD * 2 - 32) // 2

# 左：学段维度
STAGE_H = 310
lines.append(rect(PAD, y, half_w, STAGE_H, 'white', stroke='#805AD5', sw=2.5))
lines.append(rect(PAD, y, half_w, 44, '#805AD5', rx=8))
lines.append(txt(PAD + half_w // 2, y + 28, '维度 A：学段贡献度排名',
                 size=24, fill='white', anchor='middle', weight='bold'))

lines.append(txt(PAD + 24, y + 62, '字段: stage_name（小学 / 初中 / 高中）', size=18, fill='#444'))
lines.append(txt(PAD + 24, y + 88, 'SQL: GROUP BY stage_name，对比两周 GMV，算贡献度%', size=18, fill='#444'))
lines.append(txt(PAD + 24, y + 114, '贡献度 = ΔGMV_学段 / ΔTotal_GMV × 100%', size=18, fill='#744210', weight='bold'))

# 学段数据表
th_y = y + 136
lines.append(rect(PAD + 12, th_y, half_w - 24, 30, '#EDE9FE'))
for cx_, lb in zip([PAD + 28, PAD + 200, PAD + 380, PAD + 540, PAD + 660],
                   ['学段', 'Baseline', 'Current', '变化率', '贡献度']):
    lines.append(txt(cx_, th_y + 21, lb, size=17, fill='#553C9A', weight='bold'))
stage_rows = [
    ('初中',  '2,423,345', '2,250,593', '-7.1% 🔴', '77%'),
    ('小学',  '1,701,656', '1,659,432', '-2.5% 🟡', '19%'),
    ('高中',  '556,321',   '546,153',   '-1.8% 🟡',  '4%'),
]
for ri, (s, b, c, p, ctr) in enumerate(stage_rows):
    ry = th_y + 30 + ri * 30
    col = '#C53030' if '🔴' in p else '#D69E2E'
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, half_w - 24, 30, '#FAFAFA'))
    for cx_, val, vcol in [(PAD + 28, s, col), (PAD + 200, b, '#555'),
                            (PAD + 380, c, '#555'), (PAD + 540, p, col),
                            (PAD + 660, ctr, col)]:
        lines.append(txt(cx_, ry + 21, val, size=17, fill=vcol,
                         weight='bold' if cx_ in [PAD + 540, PAD + 660] else 'normal'))

lines.append(rect(PAD + 12, th_y + 120, half_w - 24, 32, '#F3E8FF', rx=4))
lines.append(txt(PAD + 24, th_y + 141,
                 '→ TOP 下跌学段：初中（贡献 77%）、小学（19%）',
                 size=18, fill='#553C9A', weight='bold'))

# 右：渠道维度
CHAN_H = 310
rx2 = PAD + half_w + 32
lines.append(rect(rx2, y, half_w, CHAN_H, 'white', stroke='#2B6CB0', sw=2.5))
lines.append(rect(rx2, y, half_w, 44, '#2B6CB0', rx=8))
lines.append(txt(rx2 + half_w // 2, y + 28, '维度 B：渠道贡献度排名',
                 size=24, fill='white', anchor='middle', weight='bold'))

lines.append(txt(rx2 + 24, y + 62, '字段: business_gmv_attribution（订单表 + 电销表分别查）', size=18, fill='#444'))
lines.append(txt(rx2 + 24, y + 88, '电销 GMV 来自 crm_order_info（P99过滤），其余来自订单表', size=18, fill='#444'))
lines.append(txt(rx2 + 24, y + 114, '贡献度 = ΔGMV_渠道 / ΔTotal_GMV × 100%', size=18, fill='#744210', weight='bold'))

th_y2 = y + 136
lines.append(rect(rx2 + 12, th_y2, half_w - 24, 30, '#DBEAFE'))
rx_cols = [rx2 + 28, rx2 + 260, rx2 + 450, rx2 + 610, rx2 + 730]
for cx_, lb in zip(rx_cols, ['渠道', 'Baseline', 'Current', '变化率', '贡献度']):
    lines.append(txt(cx_, th_y2 + 21, lb, size=17, fill='#1E40AF', weight='bold'))
chan_rows = [
    ('商业化',  '757,682', '649,223', '-14.3% 🔴', '47%'),
    ('商业化电商', '93,959', '62,535', '-33.4% 🔴', '13%'),
    ('入校',   '210,440', '191,550',  '-9.0% 🔴',  '8%'),
    ('电销',    '电销表',   '电销表',  '+3.7% 🟢', '-9%'),
]
for ri, (ch, b, c, p, ctr) in enumerate(chan_rows):
    ry = th_y2 + 30 + ri * 30
    col = '#C53030' if '🔴' in p else ('#276749' if '🟢' in p else '#555')
    if ri % 2 == 0:
        lines.append(rect(rx2 + 12, ry, half_w - 24, 30, '#FAFAFA'))
    for cx_, val, vcol in [(rx_cols[0], ch, col), (rx_cols[1], b, '#555'),
                            (rx_cols[2], c, '#555'), (rx_cols[3], p, col),
                            (rx_cols[4], ctr, col)]:
        lines.append(txt(cx_, ry + 21, val, size=17, fill=vcol,
                         weight='bold' if cx_ in rx_cols[3:] else 'normal'))

lines.append(rect(rx2 + 12, th_y2 + 120, half_w - 24, 32, '#EBF8FF', rx=4))
lines.append(txt(rx2 + 24, th_y2 + 141,
                 '→ TOP 下跌渠道：商业化（47%）、商业化电商（13%）',
                 size=18, fill='#1E40AF', weight='bold'))

# ─── 合并箭头 → 第二层 ───
merge1_y = y + max(STAGE_H, CHAN_H) + 12
mid_L = PAD + half_w // 2
mid_R = rx2 + half_w // 2
lines.append(seg(mid_L, y + STAGE_H, mid_L, merge1_y))
lines.append(seg(mid_R, y + CHAN_H,  mid_R, merge1_y))
lines.append(seg(mid_L, merge1_y, mid_R, merge1_y))
lines.append(arrow(CX, merge1_y, CX, merge1_y + 36))

# ─── 第二层：交叉矩阵 ───
y = merge1_y + 38
lines.append(rect(PAD, y, W - PAD * 2, 50, '#744210', stroke='#F6AD55', sw=0, rx=8))
lines.append(txt(PAD + 24, y + 18, '第二层  交叉矩阵（学段 × 渠道）', size=22, fill='white', weight='bold'))
lines.append(txt(PAD + 24, y + 42, '目的：定位到"哪个学段 × 哪个渠道"才是真实跌点',
                 size=19, fill='#FBD38D'))

y += 60
CROSS_H = 340
lines.append(rect(PAD, y, W - PAD * 2, CROSS_H, 'white', stroke='#F6AD55', sw=2))

# 表头
th_cross = y + 14
lines.append(rect(PAD + 12, th_cross, W - PAD * 2 - 24, 34, '#FFFBEB'))
cx_cols = [PAD + 28, PAD + 200, PAD + 580, PAD + 900, PAD + 1160, PAD + 1380, PAD + 1600]
for cx_, lb in zip(cx_cols, ['学段', '渠道', 'Baseline GMV', 'Current GMV', 'ΔGMV', '变化率', '贡献度']):
    lines.append(txt(cx_, th_cross + 23, lb, size=18, fill='#744210', weight='bold'))

cross_rows = [
    ('初中', '商业化',    '557,682',   '474,430',   '-83,252', '-14.9% 🔴', '37%', '#C53030'),
    ('初中', '商业化电商', '93,959',    '62,535',    '-31,424', '-33.4% 🔴', '14%', '#C53030'),
    ('小学', '商业化',    '199,999',   '174,793',   '-25,206', '-12.6% 🔴', '11%', '#C53030'),
    ('初中', '入校',      '153,441',   '139,120',   '-14,321',  '-9.3% 🟡',  '6%', '#D69E2E'),
    ('小学', '入校',       '56,999',    '52,430',    '-4,569',  '-8.0% 🟡',  '2%', '#D69E2E'),
    ('初中', '电销',       '电销表',    '电销表',    '+91,252',  '+3.7% 🟢', '-40%', '#276749'),
]
for ri, (st, ch, b, c, d, p, ctr, col) in enumerate(cross_rows):
    ry = th_cross + 34 + ri * 34
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 34, '#FAFAFA'))
    for cx_, val in zip(cx_cols, [st, ch, b, c, d, p, ctr]):
        lines.append(txt(cx_, ry + 23, val, size=17, fill=col,
                         weight='bold' if cx_ in cx_cols[4:] else 'normal'))

# 交叉结论
concl_y = th_cross + 34 + len(cross_rows) * 34 + 8
lines.append(rect(PAD + 12, concl_y, W - PAD * 2 - 24, 50, '#FFFBEB', rx=6, stroke='#F6AD55', sw=1))
lines.append(txt(PAD + 28, concl_y + 18,
                 '交叉结论：初中×商业化（贡献37%）+ 初中×商业化电商（14%）是核心跌点；电销初中逆势+3.7%（亮点）',
                 size=19, fill='#744210', weight='bold'))
lines.append(txt(PAD + 28, concl_y + 40,
                 '→ 确定专项方向：学段侧下钻初中 SKU；渠道侧下钻商业化投放效率',
                 size=18, fill='#C05621'))

# 分叉箭头 → 第三层
fork3_y = y + CROSS_H + 14
lines.append(seg(CX, fork3_y, CX, fork3_y + 20))
fork3_mid_L = PAD + (W // 2 - PAD) // 2
fork3_mid_R = W // 2 + (W // 2 - PAD) // 2
lines.append(seg(CX, fork3_y + 20, fork3_mid_L, fork3_y + 20))
lines.append(seg(CX, fork3_y + 20, fork3_mid_R, fork3_y + 20))
lines.append(arrow(fork3_mid_L, fork3_y + 20, fork3_mid_L, fork3_y + 44))
lines.append(arrow(fork3_mid_R, fork3_y + 20, fork3_mid_R, fork3_y + 44))

# ─── 第三层：专项深挖 ───
y = fork3_y + 46
lines.append(rect(PAD, y, W - PAD * 2, 46, '#2D3748', rx=8))
lines.append(txt(PAD + 24, y + 16, '第三层  专项深挖（根据交叉结果决定方向，只钻显著维度）', size=22, fill='white', weight='bold'))
lines.append(txt(PAD + 24, y + 38, '⚠️  商品与渠道采用差异化路径；电销 GMV 来自 crm 表（P99 过滤），APP/电商来自订单表', size=18, fill='#A0AEC0'))

y += 56
DEEP_H = 720
half_w2 = (W - PAD * 2 - 32) // 2

# ── 左：学段→SKU 深挖 ──
lines.append(rect(PAD, y, half_w2, DEEP_H, 'white', stroke='#805AD5', sw=2.5))
lines.append(rect(PAD, y, half_w2, 44, '#805AD5', rx=8))
lines.append(txt(PAD + half_w2 // 2, y + 28, '📦  专项 A：学段 → SKU 下钻',
                 size=24, fill='white', anchor='middle', weight='bold'))

# Step A1
sa1_y = y + 56
lines.append(rect(PAD + 14, sa1_y, half_w2 - 28, 32, '#EDE9FE', rx=6))
lines.append(txt(PAD + 28, sa1_y + 21, 'Step A1  锁定初中/小学下跌 SKU', size=20, fill='#553C9A', weight='bold'))
for i, t in enumerate([
    '字段: good_name + mid_grade（年级精确到升学节点）',
    'SQL: GROUP BY good_name, mid_grade WHERE stage IN (初中,小学)',
    '贡献度 = ΔSKU_GMV / ΔTotal_GMV × 100%',
]):
    lines.append(txt(PAD + 36, sa1_y + 42 + i * 26, t, size=17, fill='#444'))

# SKU 数据表
th_sku = sa1_y + 126
lines.append(rect(PAD + 14, th_sku, half_w2 - 28, 30, '#F3E8FF'))
for cx_, lb in zip([PAD + 28, PAD + 440, PAD + 620, PAD + 760],
                   ['商品名（TOP 5）', 'ΔGMV', '变化率', '贡献度']):
    lines.append(txt(cx_, th_sku + 21, lb, size=17, fill='#553C9A', weight='bold'))
sku_rows = [
    ('[七升八]初中规划提分课', '-39,060',  '-7.9%', '17%'),
    ('[小升初]初中规划提分课', '-31,347', '-24.5%', '14%'),
    ('[四升五]小初全面进阶课', '-28,666', '-46.3%', '13%'),
    ('[新高二]高中规划提分课', '-26,488', '-68.3%', '12%'),
    ('初中数学同步课12个月',   '-21,414', '-24.6%',  '9%'),
]
for ri, (nm, d, p, ctr) in enumerate(sku_rows):
    ry3 = th_sku + 30 + ri * 30
    if ri % 2 == 0:
        lines.append(rect(PAD + 14, ry3, half_w2 - 28, 30, '#FDF8FF'))
    lines.append(txt(PAD + 28,  ry3 + 21, nm,  size=17, fill='#C53030'))
    lines.append(txt(PAD + 440, ry3 + 21, d,   size=17, fill='#C53030'))
    lines.append(txt(PAD + 620, ry3 + 21, p,   size=17, fill='#C53030', weight='bold'))
    lines.append(txt(PAD + 760, ry3 + 21, ctr, size=17, fill='#C53030'))

# Step A2
sa2_y = th_sku + 180
lines.append(rect(PAD + 14, sa2_y, half_w2 - 28, 32, '#EDE9FE', rx=6))
lines.append(txt(PAD + 28, sa2_y + 21, 'Step A2  判断原因类型', size=20, fill='#553C9A', weight='bold'))
reason_items = [
    ('季节性退潮', '对比去年同期同 SKU，若同样下跌 → 自然周期', '#553C9A'),
    ('曝光骤降',   '查 APP 端 show 事件 UV 是否骤降（商品下架？）', '#744210'),
    ('价格调整',   '对比两周 sub_amount 均值，确认是否有调价', '#276749'),
    ('内容质量',   '查看完课率/差评率是否异常', '#C53030'),
]
for i, (typ, desc, col) in enumerate(reason_items):
    iy = sa2_y + 44 + i * 44
    lines.append(rect(PAD + 28, iy, 140, 30, col, rx=5))
    lines.append(txt(PAD + 28 + 70, iy + 20, typ, size=15, fill='white', anchor='middle', weight='bold'))
    lines.append(txt(PAD + 180, iy + 20, desc, size=16, fill='#444'))

# 结论
concl_a = sa2_y + 220
lines.append(rect(PAD + 14, concl_a, half_w2 - 28, 36, '#553C9A', rx=6))
lines.append(txt(PAD + half_w2 // 2, concl_a + 23,
                 '结论：[升学规划]课型季节性退潮，非产品/价格问题',
                 size=18, fill='white', anchor='middle', weight='bold'))

# ── 右：渠道专项（APP 漏斗 + 电销团队）──
rx3 = PAD + half_w2 + 32
lines.append(rect(rx3, y, half_w2, DEEP_H, 'white', stroke='#2B6CB0', sw=2.5))
lines.append(rect(rx3, y, half_w2, 44, '#2B6CB0', rx=8))
lines.append(txt(rx3 + half_w2 // 2, y + 28, '📡  专项 B：渠道分支深挖',
                 size=24, fill='white', anchor='middle', weight='bold'))

# APP 渠道部分
app_y = y + 56
lines.append(rect(rx3 + 14, app_y, half_w2 - 28, 32, '#DBEAFE', rx=6))
lines.append(txt(rx3 + 28, app_y + 21, '▶ APP 渠道：四层漏斗逐级定位断点', size=20, fill='#1E40AF', weight='bold'))

funnel_steps = [
    ('① 曝光量', 'event=show，统计 UV', '量级骤降 → 流量入口问题'),
    ('② 点击率', '点击UV / 曝光UV，~35%', '下滑 → 商品卡片吸引力不足'),
    ('③ 试听率', '试听UV / 点击UV，~55%', '下滑 → 详情页/课程质量问题'),
    ('④ 支付率', '支付UV / 试听UV，关键', '下滑 → 定价/活动/促销断档'),
]
for i, (label, sql_hint, action) in enumerate(funnel_steps):
    fy = app_y + 44 + i * 70
    step_col = ['#1D4ED8', '#2563EB', '#3B82F6', '#60A5FA'][i]
    lines.append(rect(rx3 + 28, fy, 120, 28, step_col, rx=5))
    lines.append(txt(rx3 + 28 + 60, fy + 19, label, size=16, fill='white', anchor='middle', weight='bold'))
    lines.append(txt(rx3 + 160, fy + 19, sql_hint, size=16, fill='#1E40AF'))
    lines.append(txt(rx3 + 36, fy + 46, '→ ' + action, size=15, fill='#555'))
    if i < 3:
        lines.append(seg(rx3 + 88, fy + 28, rx3 + 88, fy + 44, '#3B82F6', sw=1.5))

plat_y = app_y + 44 + 4 * 70
lines.append(rect(rx3 + 14, plat_y, half_w2 - 28, 44, '#EBF8FF', rx=6))
lines.append(txt(rx3 + 28, plat_y + 18, '补充：iOS vs Android 分平台对比', size=17, fill='#1E40AF', weight='bold'))
lines.append(txt(rx3 + 28, plat_y + 38, '某平台 CVR 骤降 → 排查版本更新/功能异常', size=16, fill='#555'))

lines.append(seg(rx3 + 14, plat_y + 52, rx3 + half_w2 - 14, plat_y + 52, '#BEE3F8', sw=1.5))

# 电销渠道部分
crm_y = plat_y + 64
lines.append(rect(rx3 + 14, crm_y, half_w2 - 28, 32, '#DBEAFE', rx=6))
lines.append(txt(rx3 + 28, crm_y + 21, '▶ 电销渠道：团队 × 学段三步归因', size=20, fill='#1E40AF', weight='bold'))

crm_steps = [
    ('Step 1  按团队 × 学段拆 GMV',
     '字段: business_gmv_attribution | 表: crm_order_info (P99过滤)',
     '定位哪个团队 × 哪个学段贡献了跌幅'),
    ('Step 2  拆线索量 vs 转化率',
     '线索量: aws.clue_info | 转化率 = 成单/线索',
     '线索少→获客问题；线索多但转化低→销售/商品'),
    ('Step 3  对比团队人效',
     '人均GMV = 团队GMV / 在岗人数',
     '人效下滑 → 排查话术/激励/培训'),
]
CRM_STEP_H = 76
for i, (title, sql_h, action) in enumerate(crm_steps):
    cy = crm_y + 44 + i * (CRM_STEP_H + 8)
    lines.append(rect(rx3 + 28, cy, half_w2 - 56, CRM_STEP_H, '#F0F7FF', rx=6, stroke='#BEE3F8', sw=1))
    lines.append(txt(rx3 + 44, cy + 20, title,  size=17, fill='#1E40AF', weight='bold'))
    lines.append(txt(rx3 + 44, cy + 42, sql_h,  size=15, fill='#666'))
    lines.append(txt(rx3 + 44, cy + 62, '→ ' + action, size=15, fill='#C05621'))

# 电销本案数据
th4_y = crm_y + 44 + 3 * (CRM_STEP_H + 8) + 8
lines.append(rect(rx3 + 14, th4_y, half_w2 - 28, 30, '#DBEAFE'))
rx_col4 = [rx3 + 28, rx3 + 350, rx3 + 540, rx3 + 680]
for cx_, lb in zip(rx_col4, ['渠道/团队（本案数据）', 'ΔGMV', '变化率', '说明']):
    lines.append(txt(cx_, th4_y + 20, lb, size=17, fill='#1E40AF', weight='bold'))
crm_rows = [
    ('商业化渠道',    '-108,459', '-14.3% 🔴', '主要跌点', '#C53030'),
    ('商业化电商',     '-31,424', '-33.4% 🔴', '主要跌点', '#C53030'),
    ('电销初中团队',  '+91,252',   '+3.7% 🟢', '逆势亮点', '#276749'),
]
for ri, (nm, d, p, note, col) in enumerate(crm_rows):
    ry4 = th4_y + 30 + ri * 30
    bg = '#FFF5F5' if col == '#C53030' else '#F0FFF4'
    lines.append(rect(rx3 + 14, ry4, half_w2 - 28, 30, bg))
    for cx_, val in zip(rx_col4, [nm, d, p, note]):
        lines.append(txt(cx_, ry4 + 20, val, size=17, fill=col,
                         weight='bold' if cx_ in rx_col4[2:] else 'normal'))

crm_concl_y = th4_y + 98
lines.append(rect(rx3 + 14, crm_concl_y, half_w2 - 28, 36, '#1E40AF', rx=6))
lines.append(txt(rx3 + half_w2 // 2, crm_concl_y + 23,
                 '结论：电销团队正常；商业化/电商投放效率下滑是主因',
                 size=17, fill='white', anchor='middle', weight='bold'))

# 合并 → Q4
merge3_y = y + DEEP_H + 20
lines.append(seg(PAD + half_w2 // 2,  y + DEEP_H, PAD + half_w2 // 2,  merge3_y))
lines.append(seg(rx3 + half_w2 // 2,  y + DEEP_H, rx3 + half_w2 // 2,  merge3_y))
lines.append(seg(PAD + half_w2 // 2,  merge3_y,   rx3 + half_w2 // 2,  merge3_y))
lines.append(arrow(CX, merge3_y, CX, merge3_y + 36))


# ══════════════════════════════════
# Q4 假设验证（聚焦显著维度）
# ══════════════════════════════════
y = merge3_y + 38
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#702459', rx=12))
lines.append(txt(CX, y + 32, 'Q4  假设验证 · Hypothesis Testing',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '⚡ 只验证 Q3 显著维度，不全跑六假设；已排除项直接标注',
                 size=20, fill='#FED7E2', anchor='middle'))

y += 88
lines.append(rect(PAD, y, W - PAD * 2, 380, 'white', stroke='#FED7E2', sw=2))

th5_y = y + 14
lines.append(rect(PAD + 12, th5_y, W - PAD * 2 - 24, 40, '#FFF5F7'))
hcols = [PAD + 30, PAD + 300, PAD + 900, PAD + 1480, PAD + 1700]
for hx, hl in zip(hcols, ['假设维度', '验证逻辑 &amp; SQL 口径', '本案验证结果', '贡献度', '判定']):
    lines.append(txt(hx, th5_y + 27, hl, size=21, fill='#702459', weight='bold'))

hyp_rows = [
    ('H1 用户规模萎缩（Q3确认）',
     'COUNT(DISTINCT u_user)，topic_order_detail',
     '付费用户 5,342→4,891（↓8.4%），三因子拆解：用户贡献-176%', '~55%', '🔴 核心主因', '#C53030'),
    ('H2 商品结构（Q3-D确认）',
     'good_name 维度，升学规划课集中下跌',
     '[小升初/四升五/七升八]三类课型占跌幅65%', '~40%', '🔴 核心主因', '#C53030'),
    ('H3 渠道效率（Q3-B/C确认）',
     'business_gmv_attribution，商业化/电销对比',
     '商业化-14.3%，电商-33.4%；电销+3.7%逆势', '~60%', '🔴 渠道主因', '#C53030'),
    ('H4 价格/AOV 变化',
     'SUM(sub_amount)/COUNT(DISTINCT u_user)',
     'AOV: 1,008→1,006（-0.2%），不影响趋势', '~0%', '✅ 已排除', '#276749'),
    ('H5 外部竞品/政策',
     '竞品监控（作业帮/猿辅导/学而思）',
     '未检测到竞品大促或行业政策变动', '~0%', '✅ 已排除', '#276749'),
    ('H6 APP 漏斗/技术',
     'APP 漏斗转化率，支付成功率监控',
     '需 APP 侧埋点数据确认（当前待补充）', '待核', '🟡 待确认', '#D69E2E'),
]
for ri, (h, sql, res, contrib, judge, col) in enumerate(hyp_rows):
    ry = th5_y + 40 + ri * 50
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 50, '#FAFAFA'))
    lines.append(txt(hcols[0], ry + 30, h,       size=18, fill='#444', weight='bold'))
    lines.append(txt(hcols[1], ry + 30, sql,     size=17, fill='#555'))
    lines.append(txt(hcols[2], ry + 30, res,     size=17, fill=col))
    lines.append(txt(hcols[3], ry + 30, contrib, size=19, fill=col, weight='bold'))
    lines.append(txt(hcols[4], ry + 30, judge,   size=19, fill=col, weight='bold'))

lines.append(rect(PAD + 12, y + 338, W - PAD * 2 - 24, 32, '#FFF5F7'))
lines.append(txt(CX, y + 360,
                 "SQL 规范红线：product_id='01' | is_test_user=0 | sub_amount≥39 | 使用 mid_grade | 订单表 paid_time | 电销表 pay_time",
                 size=19, fill='#702459', anchor='middle', weight='bold'))

ay = y + 380
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q5 主因判定（三因子拆解）
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#C05621', rx=12))
lines.append(txt(CX, y + 32, 'Q5  主因判定 · Root Cause Quantification',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, 'GMV = 付费用户数 × AOV   →   拆解各因子实际贡献',
                 size=20, fill='#FBD38D', anchor='middle'))

y += 88
BH5 = 230
lines.append(rect(PAD, y, W - PAD * 2, BH5, 'white', stroke='#FBD38D', sw=2))

bw5 = (W - PAD * 2 - 48) // 3
factor_data = [
    ('#FFFBEB', '#C05621', '因子① 付费用户数', '5,342 → 4,891（-8.4%）',
     'ΔGMV用户贡献 = ΔUser × BaseAOV', '贡献度约 176%  🔴 核心驱动因子'),
    ('#F0FFF4', '#276749', '因子② AOV（客单价）', '877 → 910（+3.8%）',
     'ΔGMV_AOV = ΔAOV × CurrUser', 'AOV 反涨，部分对冲  ✅ 不是跌因'),
    ('#F7FAFC', '#4A5568', '三因子公式', 'ΔGMV = User效应 + AOV效应',
     '= (ΔUser×BaseAOV) + (ΔAOV×CurrUser)', '🟡 建议补充 APP CVR 漏斗数据'),
]
for i, (bg, fg, title, val, note1, note2) in enumerate(factor_data):
    fx = PAD + i * (bw5 + 24)
    lines.append(rect(fx + 12, y + 16, bw5 - 12, BH5 - 32, bg, rx=8))
    lines.append(txt(fx + 12 + bw5 // 2, y + 52,  title, size=22, fill=fg, anchor='middle', weight='bold'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 96,  val,   size=22, fill=fg, anchor='middle', weight='bold'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 138, note1, size=17, fill='#666', anchor='middle'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 172, note2, size=19, fill=fg, anchor='middle', weight='bold'))

ay = y + BH5
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q6 建议输出
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#1A365D', rx=12))
lines.append(txt(CX, y + 32, 'Q6  建议输出 · Action &amp; Narrative Report',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '结论先行（金字塔结构）+ 取数给建议（禁止虚指）',
                 size=20, fill='#90CDF4', anchor='middle'))

y += 88
BH6 = 320
lines.append(rect(PAD, y, W - PAD * 2, BH6, 'white', stroke='#90CDF4', sw=2))

lw6 = (W - PAD * 2 - 40) // 2
lines.append(rect(PAD + 16, y + 16, lw6 - 8, BH6 - 32, '#EBF8FF', rx=8))
lines.append(txt(PAD + 16 + lw6 // 2, y + 50, '📋 报告结构（金字塔原理）',
                 size=22, fill='#1A365D', anchor='middle', weight='bold'))
report_items = [
    ('① 背景（Background）',    '指标 / 周期 / 异动幅度（数字说话，一表说清）'),
    ('② 核心结论（Conclusion）', '主因（贡献度%）+ 次因 + 数据佐证  ← 最先看'),
    ('③ 业务建议（Action）',     '[数据事实] + [发现问题] + [具体行动]  ← 可直接讲'),
    ('④ 分析推导（Steps）',      'Q2质检→Q3并行→交叉→专项→Q4验证明细'),
]
for i, (t1, t2) in enumerate(report_items):
    iy = y + 88 + i * 56
    lines.append(txt(PAD + 32, iy,      t1, size=20, fill='#2C5282', weight='bold'))
    lines.append(txt(PAD + 32, iy + 28, t2, size=18, fill='#555'))

rx6 = PAD + lw6 + 32
rw6 = W - PAD * 2 - lw6 - 48
lines.append(rect(rx6, y + 16, rw6, BH6 - 32, '#FFF5F7', rx=8))
lines.append(txt(rx6 + rw6 // 2, y + 50, '⚡ 建议输出规范（取数给建议）',
                 size=22, fill='#702459', anchor='middle', weight='bold'))
lines.append(txt(rx6 + 20, y + 88,  '❌ 错误示范（禁止使用）', size=20, fill='#C53030', weight='bold'))
lines.append(txt(rx6 + 20, y + 118, '  "建议关注升学课的销售情况..."', size=18, fill='#999'))
lines.append(txt(rx6 + 20, y + 146, '  "建议排查商业化渠道问题..."', size=18, fill='#999'))
lines.append(txt(rx6 + 20, y + 186, '✅ 正确示范（必须）', size=20, fill='#276749', weight='bold'))
lines.append(txt(rx6 + 20, y + 216,
                 '  [小升初] GMV↓24.5%（-3.1万），4月初签约高峰结束后自然退潮，',
                 size=18, fill='#276749'))
lines.append(txt(rx6 + 20, y + 242,
                 '  建议4月底启动小升初专题活动提前拉需求。',
                 size=18, fill='#276749'))
lines.append(txt(rx6 + 20, y + 268,
                 '  商业化电商↓33.4%，建议4/22前核查商品链接状态与投放计划。',
                 size=18, fill='#276749'))
lines.append(txt(rx6 + 20, y + 300,
                 '  → [数据事实] + [发现问题] + [具体行动]，每条可直接执行',
                 size=18, fill='#702459', weight='bold'))

ay = y + BH6
lines.append(arrow(CX, ay, CX, ay + 40))


# ══════════════════════════════════
# 输出交付物
# ══════════════════════════════════
y = ay + 42
lines.append(rect(PAD + 220, y, W - PAD * 2 - 440, 64, '#2D3748', rx=12))
lines.append(txt(CX, y + 28, '📤  最终交付物', size=26, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 54,
                 'reports_v2/归因分析报告_[指标]_[周期].md  ｜  CSV 原始数据  ｜  周会 PPT 摘要',
                 size=19, fill='#A0AEC0', anchor='middle'))


# ══════════════════════════════════
# SQL 速查底栏
# ══════════════════════════════════
y += 80
lines.append(rect(PAD, y, W - PAD * 2, 260, '#1A202C', rx=14))
lines.append(txt(CX, y + 40, '📐  SQL 口径规范速查（必须遵守）',
                 size=26, fill='#A0AEC0', anchor='middle', weight='bold'))

sql_secs = [
    ('核心表', [
        '活跃宽表: dws.topic_user_active_detail_day',
        '订单表:   dws.topic_order_detail',
        '电销表:   aws.crm_order_info  |  线索表: aws.clue_info',
    ]),
    ('订单表必筛', [
        "product_id = '01'（C端）  |  is_test_user = 0",
        "sub_amount ≥ 39（正价单）  |  日期用 paid_time（timestamp）",
        "商品: good_name + stage_name  |  年级: mid_grade",
    ]),
    ('电销表必筛', [
        "is_test = false  |  amount ≥ 39",
        "日期字段: pay_time（不是 paid_time！）",
        "P99 过滤: amount ≤ PERCENTILE(amount, 0.99)",
    ]),
    ('禁用字段', [
        '❌ grade → ✅ mid_grade',
        '❌ role → ✅ real_identity',
        '❌ day 分区 → ✅ paid_time timestamp',
        '❌ product_name → ✅ good_name + stage_name',
    ]),
]
sec_w = (W - PAD * 2 - 60) // 4
for i, (sec_title, sec_items) in enumerate(sql_secs):
    sx = PAD + 20 + i * (sec_w + 20)
    lines.append(txt(sx, y + 76, sec_title, size=20, fill='#68D391', weight='bold'))
    for j, item in enumerate(sec_items):
        lines.append(txt(sx, y + 106 + j * 30, item, size=16, fill='#A0AEC0'))

lines.append(txt(CX, y + 238,
                 '洋葱学园 BI 团队 · 归因分析 SOP v2.0 · 2026-04-30（Q3 并行下钻重构版）',
                 size=18, fill='#4A5568', anchor='middle'))

total_h = y + 260
lines.append('</svg>')

svg_content = '\n'.join(lines)
out_path = '/Users/hilda/attribution-analysis/docs/sop_v2_flowchart.svg'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(svg_content)

print(f'✅ SVG 生成完成，总高度 {total_h}px，宽度 {W}px')
