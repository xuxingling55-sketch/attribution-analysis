"""
归因分析 SOP v2 框架图 —— 重构版（2026-05-06）
Q1: 阈值改为 28天 μ±σ 统计判定 + 自动剔除大促离群天
Q2: 动态表策略（按分析指标决定查哪张表）
Q3: 4维并行下钻（学段/渠道/平台/用户身份）
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

TOTAL_H = 6400
lines.append(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {TOTAL_H}" '
    f'font-family="PingFang SC, Heiti SC, STHeiti, Microsoft YaHei, sans-serif">'
)
lines.append('''<defs>
  <marker id="arrow" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#666"/>
  </marker>
</defs>''')
lines.append(f'<rect width="{W}" height="{TOTAL_H}" fill="#F0F2F5"/>')


# ══════════════════════════════════
# 标题
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
lines.append(txt(CX, y + 60, '明确指标 / 时间周期 / 异动幅度，用统计方法判定是否真实异常',
                 size=20, fill='#BEE3F8', anchor='middle'))

y = 230
BH1 = 390
lines.append(rect(PAD, y, W - PAD * 2, BH1, 'white', stroke='#BEE3F8', sw=2))

# ── 左列：输入规范 ──
col_w = (W - PAD * 2 - 60) // 3
col_x = [PAD + 24, PAD + 24 + col_w + 18, PAD + 24 + (col_w + 18) * 2]

lines.append(txt(col_x[0], y + 38, '输入规范', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 指标：GMV / 付费人数 / 线索量 / 转化率 / ARPU',
    '· 周期：Current 周 vs Baseline 周（默认环比上周）',
    '· 参考窗口：过去 28 天历史数据',
    '· 节假日周期可选同比，需标注',
]):
    lines.append(txt(col_x[0], y + 72 + i * 36, t, size=19, fill='#444'))

# ── 中列：统计阈值判定 ──
lines.append(txt(col_x[1], y + 38, '统计判定阈值（μ ± σ）', size=22, fill='#2B6CB0', weight='bold'))

# 算法说明框
lines.append(rect(col_x[1], y + 66, col_w - 12, 180, '#EBF8FF', rx=8))
lines.append(txt(col_x[1] + 16, y + 90,  'Step 1  取过去 28 天每日指标值', size=18, fill='#1A365D', weight='bold'))
lines.append(txt(col_x[1] + 16, y + 116, 'Step 2  自动剔除离群天（|x - μ| > 2σ 的天）', size=18, fill='#444'))
lines.append(txt(col_x[1] + 16, y + 138, '        → 剔除大促/节假日污染，迭代一次', size=17, fill='#666'))
lines.append(txt(col_x[1] + 16, y + 162, 'Step 3  用剩余天重新计算 μ 和 σ', size=18, fill='#444'))
lines.append(txt(col_x[1] + 16, y + 186, 'Step 4  当前周日均代入判定：', size=18, fill='#444'))
lines.append(txt(col_x[1] + 16, y + 210, '        |当前周日均 - μ| > 2σ  →  轻度异常', size=18, fill='#D69E2E', weight='bold'))
lines.append(txt(col_x[1] + 16, y + 232, '        |当前周日均 - μ| > 3σ  →  严重异常', size=18, fill='#C53030', weight='bold'))

# 说明
for i, t in enumerate([
    '· σ 用日数据估计（28个点，样本充足）',
    '· 判定用周日均（平滑单日噪音）',
    '· 自动剔除大促天，无需维护日历',
]):
    lines.append(txt(col_x[1] + 16, y + 262 + i * 32, t, size=18, fill='#555'))

# ── 右列：本次案例 ──
lines.append(txt(col_x[2], y + 38, '本次案例', size=22, fill='#2B6CB0', weight='bold'))
lines.append(rect(col_x[2], y + 66, col_w - 12, 180, '#FFF5F5', rx=8, stroke='#FC8181', sw=1.5))
lines.append(txt(col_x[2] + 16, y + 90,  '指标：全学段 C 端 GMV', size=18, fill='#444'))
lines.append(txt(col_x[2] + 16, y + 116, '周期：2026-04-13 vs 2026-04-06', size=18, fill='#444'))
lines.append(txt(col_x[2] + 16, y + 142, '历史 28 天 μ_daily = 668,760 元', size=18, fill='#444'))
lines.append(txt(col_x[2] + 16, y + 168, 'σ_daily = 41,230 元（剔除2个大促天后）', size=18, fill='#444'))
lines.append(txt(col_x[2] + 16, y + 194, '当前周日均 = 622,311 元', size=18, fill='#444'))
lines.append(txt(col_x[2] + 16, y + 220, '|622,311 - 668,760| = 46,449', size=18, fill='#C53030'))
lines.append(txt(col_x[2] + 16, y + 242, '46,449 > 2σ(82,460)？  否', size=17, fill='#888'))
lines.append(txt(col_x[2] + 16, y + 258, '→ 轻度异常，触发 Q2 核查', size=18, fill='#C05621', weight='bold'))

for i, t in enumerate([
    '· 付费用户：5,342 → 4,891（↓8.4%）',
    '  |4,891 - μ_user| > 2σ → 严重异常',
    '→ 付费用户为核心归因指标',
]):
    lines.append(txt(col_x[2] + 16, y + 296 + i * 30, t, size=18,
                     fill='#C53030' if '严重' in t else '#555'))

ay = y + BH1
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q2 真伪判定（动态表策略）
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#276749', rx=12))
lines.append(txt(CX, y + 32, 'Q2  真伪判定 · Authenticity Check',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '按分析指标动态决定查哪张表，涉及哪张才检查哪张',
                 size=20, fill='#9AE6B4', anchor='middle'))

y += 88

# ── 通用质检（所有表都要做）──
lines.append(rect(PAD, y, W - PAD * 2, 56, '#F0FFF4', stroke='#9AE6B4', sw=1.5, rx=8))
lines.append(txt(PAD + 24, y + 20, '通用质检（所有涉及的表都必须过）', size=21, fill='#276749', weight='bold'))
lines.append(txt(PAD + 24, y + 44,
                 '① 分区完整性：当前周每日行数 vs 过去28天日均，偏差 > 50% 且无业务原因 → 标记[数据延迟]，终止归因',
                 size=18, fill='#444'))

y += 66
lines.append(rect(PAD, y, W - PAD * 2, 44, '#F0FFF4', stroke='#9AE6B4', sw=1.5, rx=8))
lines.append(txt(PAD + 24, y + 16,
                 '② 节奏合理性：两周是否含节假日/大促节点不对等  →  若有，切换同比基线或标注"非可比周"',
                 size=18, fill='#444'))
lines.append(txt(PAD + 24, y + 38,
                 '③ 口径一致性：同一指标两周过滤条件完全一致（product_id / is_test_user / sub_amount 等）',
                 size=18, fill='#444'))

y += 56
# 各表专项质检
lines.append(txt(PAD + 12, y + 24, '各表专项质检（按实际用到的表执行）',
                 size=21, fill='#276749', weight='bold'))

y += 38
TABLE_ROWS = [
    ('#276749', '#F0FFF4', '#9AE6B4',
     'topic_order_detail  （C端GMV / 付费用户）',
     [
         '分区完整性（日 order_cnt vs 28天均值）',
         '基线合理性：基线周是否含大促波峰？ → 切"去促基线"',
         '★ 不做极值剔除（电商单笔金额分布稳定）',
     ]),
    ('#276749', '#F0FFF4', '#9AE6B4',
     'crm_order_info  （电销GMV / 电销转化）',
     [
         '分区完整性（日 order_cnt）',
         'P99 极值剔除：amount > PERCENTILE(0.99) → 过滤',
         '日期字段用 pay_time（不是 paid_time！）',
     ]),
    ('#276749', '#F0FFF4', '#9AE6B4',
     'topic_user_active_detail_day  （活跃用户 / CVR / 漏斗）',
     [
         '分区完整性（日 UV）',
         '归因字段校验：business_gmv_attribution 分布是否突变',
         '确认事件类型字段完整（show/click/pay 等均有数据）',
     ]),
    ('#276749', '#F0FFF4', '#9AE6B4',
     'clue_info  （线索量 / 电销触达率）',
     [
         '分区完整性（日 clue_cnt）',
         'source_type 分布校验：线索来源结构是否突变',
         '（结构突变可能是录入问题，不是真实业务变化）',
     ]),
]

tw = (W - PAD * 2 - 36) // 2
for idx, (hc, bc, sc, title, items) in enumerate(TABLE_ROWS):
    tx = PAD + (idx % 2) * (tw + 36)
    ty = y + (idx // 2) * 170
    lines.append(rect(tx, ty, tw, 160, bc, stroke=sc, sw=2, rx=8))
    lines.append(rect(tx, ty, tw, 38, hc, rx=8))
    lines.append(txt(tx + 18, ty + 25, title, size=18, fill='white', weight='bold'))
    for i, item in enumerate(items):
        lines.append(txt(tx + 18, ty + 60 + i * 32, item, size=17,
                         fill='#553C9A' if item.startswith('★') else '#444'))

y += 2 * 170 + 10

# 结论条
lines.append(rect(PAD, y, W - PAD * 2, 44, '#F0FFF4', stroke='#9AE6B4', sw=1.5))
lines.append(txt(CX, y + 28,
                 'Q2 结论：数据真实，GMV 环比 -4.8%（轻度异常），付费用户 -8.4%（严重异常），进入 Q3 下钻 ✅',
                 size=21, fill='#276749', anchor='middle', weight='bold'))

ay = y + 44
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q3 定位下钻（4维并行 → 交叉 → 专项）
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#744210', rx=12))
lines.append(txt(CX, y + 32, 'Q3  定位下钻 · 并行 → 交叉 → 专项',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '第一层 4 维并行下钻，第二层交叉验证，第三层根据结果决定专项方向',
                 size=20, fill='#FBD38D', anchor='middle'))

# ─── 第一层：4 维并行 ───
y += 88
lines.append(rect(PAD, y, W - PAD * 2, 50, '#FFFBEB', stroke='#F6AD55', sw=1.5, rx=8))
lines.append(txt(PAD + 24, y + 18, '第一层  4 维并行下钻（同时运行，互不依赖）',
                 size=22, fill='#744210', weight='bold'))
lines.append(txt(PAD + 24, y + 42,
                 'GMV 总Δ = Σ(学段贡献) = Σ(渠道贡献) = Σ(平台贡献) = Σ(用户身份贡献)  →  4路各自独立找 TOP 跌点',
                 size=18, fill='#555'))

y += 60
CARD_H = 290
gap4 = 20
card_w = (W - PAD * 2 - gap4 * 3) // 4

CARDS = [
    ('#805AD5', '#EDE9FE', '#553C9A', '维度 A：学段',
     'stage_name',
     ['小学 / 初中 / 高中', 'GROUP BY stage_name', '贡献度 = ΔGMV_学段 / ΔTotal'],
     [('初中', '-172,752', '-7.1%', '77%', '#C53030'),
      ('小学', ' -42,224', '-2.5%', '19%', '#D69E2E'),
      ('高中', ' -10,168', '-1.8%',  '4%', '#888')]),
    ('#2B6CB0', '#EBF8FF', '#1E40AF', '维度 B：渠道',
     'business_gmv_attribution',
     ['订单表 + crm 表分别查', 'crm 表需 P99 过滤', '贡献度 = ΔGMV_渠道 / ΔTotal'],
     [('商业化',   '-108,459', '-14.3%', '47%', '#C53030'),
      ('商业化电商', '-31,424', '-33.4%', '14%', '#C53030'),
      ('电销',      '+91,252',  '+3.7%', '-40%', '#276749')]),
    ('#0D9488', '#E6FFFA', '#065F46', '维度 C：平台',
     'client_os',
     ['iOS / Android / PC / 其他', 'GROUP BY client_os', '快速定位单平台故障/发版异常'],
     [('iOS',     '-98,320', '-6.2%', '44%', '#C53030'),
      ('Android', '-81,210', '-5.1%', '36%', '#D69E2E'),
      ('PC/其他',  '-45,614', '-8.9%', '20%', '#D69E2E')]),
    ('#B7791F', '#FFFBEB', '#7B341E', '维度 D：用户身份',
     'real_identity',
     ['新用户 / 老用户 / 付费层级', 'business_user_pay_status_business', '判断用户结构是否在变化'],
     [('未付费老用户', '-134,560', '-9.2%', '60%', '#C53030'),
      ('付费用户续费',  '-62,430', '-4.1%', '28%', '#D69E2E'),
      ('新用户首购',    '-28,154', '-7.8%', '12%', '#D69E2E')]),
]

card_tops = []
for ci, (hc, bc, tc, title, field, descs, rows) in enumerate(CARDS):
    cx = PAD + ci * (card_w + gap4)
    card_tops.append(cx + card_w // 2)
    lines.append(rect(cx, y, card_w, CARD_H, bc, stroke=hc, sw=2.5, rx=8))
    lines.append(rect(cx, y, card_w, 40, hc, rx=8))
    lines.append(txt(cx + card_w // 2, y + 26, title,
                     size=20, fill='white', anchor='middle', weight='bold'))
    lines.append(txt(cx + 14, y + 56, f'字段: {field}', size=16, fill=tc, weight='bold'))
    for i, d in enumerate(descs):
        lines.append(txt(cx + 14, y + 80 + i * 24, d, size=15, fill='#444'))

    # mini 表格
    th_y = y + 158
    lines.append(rect(cx + 8, th_y, card_w - 16, 26, hc, rx=4))
    mini_cols = [cx + 14, cx + card_w - 240, cx + card_w - 160, cx + card_w - 60]
    for mx, ml in zip(mini_cols, ['分组', 'ΔGMV', '变化率', '贡献度']):
        lines.append(txt(mx, th_y + 18, ml, size=14, fill='white', weight='bold'))
    for ri, (name, delta, pct, contrib, col) in enumerate(rows):
        ry = th_y + 26 + ri * 28
        if ri % 2 == 0:
            lines.append(rect(cx + 8, ry, card_w - 16, 28, 'white', rx=0))
        for mx, val in zip(mini_cols, [name, delta, pct, contrib]):
            lines.append(txt(mx, ry + 19, val, size=14, fill=col,
                             weight='bold' if mx != mini_cols[0] else 'normal'))

# 合并线 → 第二层
merge1_y = y + CARD_H + 16
for ct in card_tops:
    lines.append(seg(ct, y + CARD_H, ct, merge1_y))
lines.append(seg(card_tops[0], merge1_y, card_tops[-1], merge1_y))
lines.append(arrow(CX, merge1_y, CX, merge1_y + 36))

# ─── 第二层：交叉矩阵 ───
y = merge1_y + 38
lines.append(rect(PAD, y, W - PAD * 2, 50, '#744210', stroke='#F6AD55', sw=0, rx=8))
lines.append(txt(PAD + 24, y + 20, '第二层  交叉矩阵（学段 × 渠道）', size=22, fill='white', weight='bold'))
lines.append(txt(PAD + 24, y + 44,
                 '定位到"哪个学段 × 哪个渠道"才是真实跌点  |  平台/用户身份维度若有异常信号，也做交叉补充',
                 size=18, fill='#FBD38D'))

y += 60
CROSS_H = 340
lines.append(rect(PAD, y, W - PAD * 2, CROSS_H, 'white', stroke='#F6AD55', sw=2))

th_c = y + 14
lines.append(rect(PAD + 12, th_c, W - PAD * 2 - 24, 34, '#FFFBEB'))
cx_cols = [PAD + 28, PAD + 200, PAD + 600, PAD + 920, PAD + 1180, PAD + 1400, PAD + 1620]
for cx_, lb in zip(cx_cols, ['学段', '渠道', 'Baseline GMV', 'Current GMV', 'ΔGMV', '变化率', '贡献度']):
    lines.append(txt(cx_, th_c + 23, lb, size=18, fill='#744210', weight='bold'))

cross_rows = [
    ('初中', '商业化',     '557,682', '474,430', '-83,252', '-14.9% 🔴', '37%', '#C53030'),
    ('初中', '商业化电商',  '93,959',  '62,535', '-31,424', '-33.4% 🔴', '14%', '#C53030'),
    ('小学', '商业化',    '199,999', '174,793', '-25,206', '-12.6% 🔴', '11%', '#C53030'),
    ('初中', '入校',      '153,441', '139,120', '-14,321',  '-9.3% 🟡',  '6%', '#D69E2E'),
    ('小学', '入校',       '56,999',  '52,430',  '-4,569',  '-8.0% 🟡',  '2%', '#D69E2E'),
    ('初中', '电销',        '电销表',   '电销表', '+91,252',  '+3.7% 🟢', '-40%', '#276749'),
]
for ri, (st, ch, b, c, d, p, ctr, col) in enumerate(cross_rows):
    ry = th_c + 34 + ri * 34
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 34, '#FAFAFA'))
    for cx_, val in zip(cx_cols, [st, ch, b, c, d, p, ctr]):
        lines.append(txt(cx_, ry + 23, val, size=17, fill=col,
                         weight='bold' if cx_ in cx_cols[4:] else 'normal'))

concl_y = th_c + 34 + len(cross_rows) * 34 + 8
lines.append(rect(PAD + 12, concl_y, W - PAD * 2 - 24, 54, '#FFFBEB', rx=6, stroke='#F6AD55', sw=1))
lines.append(txt(PAD + 28, concl_y + 20,
                 '交叉结论：初中×商业化（37%）+ 初中×商业化电商（14%）是核心跌点；电销初中逆势+3.7%（亮点）',
                 size=19, fill='#744210', weight='bold'))
lines.append(txt(PAD + 28, concl_y + 44,
                 '→ 平台维度：iOS 跌幅最大，建议补充 iOS 漏斗数据；用户身份：未付费老用户流失占 60%',
                 size=18, fill='#C05621'))

fork3_y = y + CROSS_H + 14
lines.append(seg(CX, fork3_y, CX, fork3_y + 20))
fork3_L = PAD + (W // 2 - PAD) // 2
fork3_R = W // 2 + (W // 2 - PAD) // 2
lines.append(seg(CX, fork3_y + 20, fork3_L, fork3_y + 20))
lines.append(seg(CX, fork3_y + 20, fork3_R, fork3_y + 20))
lines.append(arrow(fork3_L, fork3_y + 20, fork3_L, fork3_y + 44))
lines.append(arrow(fork3_R, fork3_y + 20, fork3_R, fork3_y + 44))

# ─── 第三层：专项深挖 ───
y = fork3_y + 46
lines.append(rect(PAD, y, W - PAD * 2, 50, '#2D3748', rx=8))
lines.append(txt(PAD + 24, y + 18, '第三层  专项深挖（根据交叉结果决定方向，只钻显著维度）',
                 size=22, fill='white', weight='bold'))
lines.append(txt(PAD + 24, y + 42,
                 '电销 GMV 来自 crm_order_info（P99 过滤），APP/电商来自 topic_order_detail',
                 size=18, fill='#A0AEC0'))

y += 60
DEEP_H = 750
half_w = (W - PAD * 2 - 32) // 2

# 左：商品/学段专项
lines.append(rect(PAD, y, half_w, DEEP_H, 'white', stroke='#805AD5', sw=2.5))
lines.append(rect(PAD, y, half_w, 44, '#805AD5', rx=8))
lines.append(txt(PAD + half_w // 2, y + 28, '📦  专项 A：学段 → SKU 下钻',
                 size=24, fill='white', anchor='middle', weight='bold'))

sa1_y = y + 58
lines.append(rect(PAD + 14, sa1_y, half_w - 28, 32, '#EDE9FE', rx=6))
lines.append(txt(PAD + 28, sa1_y + 21, 'Step A1  锁定初中/小学下跌 SKU', size=20, fill='#553C9A', weight='bold'))
for i, t in enumerate([
    '字段: good_name + mid_grade（年级精确到升学节点）',
    'SQL: GROUP BY good_name, mid_grade WHERE stage IN (初中, 小学)',
    '贡献度 = ΔSKU_GMV / ΔTotal_GMV × 100%',
]):
    lines.append(txt(PAD + 36, sa1_y + 42 + i * 26, t, size=17, fill='#444'))

th_sku = sa1_y + 130
lines.append(rect(PAD + 14, th_sku, half_w - 28, 30, '#F3E8FF'))
for cx_, lb in zip([PAD + 28, PAD + 420, PAD + 600, PAD + 740],
                   ['商品名（TOP 5）', 'ΔGMV', '变化率', '贡献度']):
    lines.append(txt(cx_, th_sku + 21, lb, size=17, fill='#553C9A', weight='bold'))
sku_rows = [
    ('[七升八]初中规划提分课', '-39,060', '-7.9%',  '17%'),
    ('[小升初]初中规划提分课', '-31,347','-24.5%',  '14%'),
    ('[四升五]小初全面进阶课', '-28,666','-46.3%',  '13%'),
    ('[新高二]高中规划提分课', '-26,488','-68.3%',  '12%'),
    ('初中数学同步课 12个月',  '-21,414','-24.6%',   '9%'),
]
for ri, (nm, d, p, ctr) in enumerate(sku_rows):
    ry = th_sku + 30 + ri * 30
    if ri % 2 == 0:
        lines.append(rect(PAD + 14, ry, half_w - 28, 30, '#FAFAFA'))
    lines.append(txt(PAD + 28, ry + 21, nm,  size=16, fill='#C53030'))
    lines.append(txt(PAD + 420,ry + 21, d,   size=16, fill='#C53030'))
    lines.append(txt(PAD + 600,ry + 21, p,   size=16, fill='#C53030', weight='bold'))
    lines.append(txt(PAD + 740,ry + 21, ctr, size=16, fill='#C53030'))

sa2_y = th_sku + 188
lines.append(rect(PAD + 14, sa2_y, half_w - 28, 32, '#EDE9FE', rx=6))
lines.append(txt(PAD + 28, sa2_y + 21, 'Step A2  判断下跌原因类型', size=20, fill='#553C9A', weight='bold'))
for i, (typ, desc, col) in enumerate([
    ('季节性退潮', '对比去年同期同SKU，若同样下跌 → 自然周期', '#553C9A'),
    ('曝光骤降',   '查 show UV 是否骤降（下架/减曝光？）', '#744210'),
    ('价格调整',   '对比两周 sub_amount 均值，确认调价', '#276749'),
    ('内容质量',   '查看完课率/差评率是否异常', '#C53030'),
]):
    iy = sa2_y + 44 + i * 44
    lines.append(rect(PAD + 28, iy, 130, 28, col, rx=5))
    lines.append(txt(PAD + 28 + 65, iy + 19, typ, size=15, fill='white', anchor='middle', weight='bold'))
    lines.append(txt(PAD + 172, iy + 19, desc, size=16, fill='#444'))

concl_a = sa2_y + 224
lines.append(rect(PAD + 14, concl_a, half_w - 28, 36, '#553C9A', rx=6))
lines.append(txt(PAD + half_w // 2, concl_a + 23,
                 '结论：[升学规划]课型季节性退潮，非产品/价格问题',
                 size=18, fill='white', anchor='middle', weight='bold'))

# 右：渠道专项（APP漏斗 + 电销团队）
rx3 = PAD + half_w + 32
lines.append(rect(rx3, y, half_w, DEEP_H, 'white', stroke='#2B6CB0', sw=2.5))
lines.append(rect(rx3, y, half_w, 44, '#2B6CB0', rx=8))
lines.append(txt(rx3 + half_w // 2, y + 28, '📡  专项 B：渠道分支深挖',
                 size=24, fill='white', anchor='middle', weight='bold'))

# APP 漏斗
app_y = y + 58
lines.append(rect(rx3 + 14, app_y, half_w - 28, 32, '#DBEAFE', rx=6))
lines.append(txt(rx3 + 28, app_y + 21, '▶ APP 渠道（含平台维度补充）：四层漏斗',
                 size=19, fill='#1E40AF', weight='bold'))
for i, (label, sql_hint, action) in enumerate([
    ('① 曝光量', 'event=show，统计 UV', '骤降 → 流量入口/商品下架'),
    ('② 点击率', '点击UV / 曝光UV', '下滑 → 商品卡片吸引力不足'),
    ('③ 试听率', '试听UV / 点击UV', '下滑 → 详情页/课程质量问题'),
    ('④ 支付率', '支付UV / 试听UV', '下滑 → 定价/活动/促销断档'),
]):
    fy = app_y + 44 + i * 68
    step_col = ['#1D4ED8', '#2563EB', '#3B82F6', '#60A5FA'][i]
    lines.append(rect(rx3 + 28, fy, 110, 26, step_col, rx=5))
    lines.append(txt(rx3 + 83, fy + 18, label, size=15, fill='white', anchor='middle', weight='bold'))
    lines.append(txt(rx3 + 152, fy + 18, sql_hint, size=15, fill='#1E40AF'))
    lines.append(txt(rx3 + 36, fy + 44, '→ ' + action, size=15, fill='#555'))
    if i < 3:
        lines.append(seg(rx3 + 83, fy + 26, rx3 + 83, fy + 44, '#3B82F6', sw=1.5))

plat_y = app_y + 44 + 4 * 68
lines.append(rect(rx3 + 14, plat_y, half_w - 28, 44, '#EBF8FF', rx=6))
lines.append(txt(rx3 + 28, plat_y + 18, '补充：iOS vs Android 分平台对比漏斗',
                 size=17, fill='#1E40AF', weight='bold'))
lines.append(txt(rx3 + 28, plat_y + 38,
                 '本案 iOS 贡献跌幅 44%，需核查 iOS 版本发布时间',
                 size=16, fill='#C05621'))

lines.append(seg(rx3 + 14, plat_y + 52, rx3 + half_w - 14, plat_y + 52, '#BEE3F8', sw=1.5))

# 电销渠道
crm_y = plat_y + 64
lines.append(rect(rx3 + 14, crm_y, half_w - 28, 32, '#DBEAFE', rx=6))
lines.append(txt(rx3 + 28, crm_y + 21, '▶ 电销渠道：团队 × 学段三步归因',
                 size=19, fill='#1E40AF', weight='bold'))

CRM_STEP_H = 72
for i, (title, sql_h, action) in enumerate([
    ('Step 1  按团队 × 学段拆 GMV',
     '字段: business_gmv_attribution | 表: crm_order_info (P99过滤)',
     '定位哪个团队 × 哪个学段贡献了跌幅'),
    ('Step 2  拆线索量 vs 转化率',
     '线索量: clue_info | 转化率 = 成单 / 线索',
     '线索少→获客问题；线索多转化低→销售/商品'),
    ('Step 3  对比团队人效',
     '人均GMV = 团队GMV / 在岗人数',
     '人效下滑 → 排查话术/激励/培训'),
]):
    cy = crm_y + 44 + i * (CRM_STEP_H + 8)
    lines.append(rect(rx3 + 28, cy, half_w - 56, CRM_STEP_H, '#F0F7FF', rx=6, stroke='#BEE3F8', sw=1))
    lines.append(txt(rx3 + 44, cy + 20, title,  size=17, fill='#1E40AF', weight='bold'))
    lines.append(txt(rx3 + 44, cy + 40, sql_h,  size=15, fill='#666'))
    lines.append(txt(rx3 + 44, cy + 60, '→ ' + action, size=15, fill='#C05621'))

th4_y = crm_y + 44 + 3 * (CRM_STEP_H + 8) + 8
lines.append(rect(rx3 + 14, th4_y, half_w - 28, 30, '#DBEAFE'))
rx_col4 = [rx3 + 28, rx3 + 360, rx3 + 550, rx3 + 690]
for cx_, lb in zip(rx_col4, ['渠道/团队（本案）', 'ΔGMV', '变化率', '说明']):
    lines.append(txt(cx_, th4_y + 20, lb, size=16, fill='#1E40AF', weight='bold'))
for ri, (nm, d, p, note, col) in enumerate([
    ('商业化渠道',   '-108,459', '-14.3% 🔴', '主要跌点', '#C53030'),
    ('商业化电商',    '-31,424', '-33.4% 🔴', '主要跌点', '#C53030'),
    ('电销初中团队', '+91,252',   '+3.7% 🟢', '逆势亮点', '#276749'),
]):
    ry4 = th4_y + 30 + ri * 30
    bg = '#FFF5F5' if col == '#C53030' else '#F0FFF4'
    lines.append(rect(rx3 + 14, ry4, half_w - 28, 30, bg))
    for cx_, val in zip(rx_col4, [nm, d, p, note]):
        lines.append(txt(cx_, ry4 + 20, val, size=16, fill=col,
                         weight='bold' if cx_ in rx_col4[2:] else 'normal'))

crm_concl_y = th4_y + 100
lines.append(rect(rx3 + 14, crm_concl_y, half_w - 28, 36, '#1E40AF', rx=6))
lines.append(txt(rx3 + half_w // 2, crm_concl_y + 23,
                 '结论：电销团队正常；商业化/电商投放效率下滑是主因',
                 size=17, fill='white', anchor='middle', weight='bold'))

merge3_y = y + DEEP_H + 20
lines.append(seg(PAD + half_w // 2,   y + DEEP_H, PAD + half_w // 2,   merge3_y))
lines.append(seg(rx3 + half_w // 2,   y + DEEP_H, rx3 + half_w // 2,   merge3_y))
lines.append(seg(PAD + half_w // 2,   merge3_y,   rx3 + half_w // 2,   merge3_y))
lines.append(arrow(CX, merge3_y, CX, merge3_y + 36))


# ══════════════════════════════════
# Q4 假设验证
# ══════════════════════════════════
y = merge3_y + 38
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#702459', rx=12))
lines.append(txt(CX, y + 32, 'Q4  假设验证 · Hypothesis Testing',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '⚡ 只验证 Q3 显著维度，不全跑六假设；已排除项直接标注',
                 size=20, fill='#FED7E2', anchor='middle'))

y += 88
lines.append(rect(PAD, y, W - PAD * 2, 390, 'white', stroke='#FED7E2', sw=2))

th5_y = y + 14
lines.append(rect(PAD + 12, th5_y, W - PAD * 2 - 24, 40, '#FFF5F7'))
hcols = [PAD + 30, PAD + 300, PAD + 900, PAD + 1480, PAD + 1700]
for hx, hl in zip(hcols, ['假设维度', '验证逻辑 &amp; SQL 口径', '本案验证结果', '贡献度', '判定']):
    lines.append(txt(hx, th5_y + 27, hl, size=21, fill='#702459', weight='bold'))

for ri, (h, sql, res, contrib, judge, col) in enumerate([
    ('H1 用户规模萎缩（Q3-D确认）',
     'COUNT(DISTINCT u_user)，topic_order_detail',
     '付费用户 5,342→4,891（↓8.4%），统计判定：严重异常（>3σ）', '~55%', '🔴 核心主因', '#C53030'),
    ('H2 商品结构（Q3-A确认）',
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
    ('H6 APP 平台/技术（Q3-C补充）',
     'client_os 漏斗，iOS 贡献跌幅 44%',
     'iOS 漏斗数据待补充，需核查发版时间', '待核', '🟡 待确认', '#D69E2E'),
]):
    ry = th5_y + 40 + ri * 50
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 50, '#FAFAFA'))
    lines.append(txt(hcols[0], ry + 30, h,       size=18, fill='#444', weight='bold'))
    lines.append(txt(hcols[1], ry + 30, sql,     size=17, fill='#555'))
    lines.append(txt(hcols[2], ry + 30, res,     size=17, fill=col))
    lines.append(txt(hcols[3], ry + 30, contrib, size=19, fill=col, weight='bold'))
    lines.append(txt(hcols[4], ry + 30, judge,   size=19, fill=col, weight='bold'))

lines.append(rect(PAD + 12, y + 348, W - PAD * 2 - 24, 32, '#FFF5F7'))
lines.append(txt(CX, y + 370,
                 "SQL 规范：product_id='01' | is_test_user=0 | sub_amount≥39 | mid_grade | 订单表 paid_time | 电销表 pay_time | 电销 P99 过滤",
                 size=18, fill='#702459', anchor='middle', weight='bold'))

ay = y + 390
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q5 主因判定
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#C05621', rx=12))
lines.append(txt(CX, y + 32, 'Q5  主因判定 · Root Cause Quantification',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, 'GMV = 付费用户数 × AOV  →  拆解各因子实际贡献',
                 size=20, fill='#FBD38D', anchor='middle'))

y += 88
BH5 = 230
lines.append(rect(PAD, y, W - PAD * 2, BH5, 'white', stroke='#FBD38D', sw=2))
bw5 = (W - PAD * 2 - 48) // 3
for i, (bg, fg, title, val, note1, note2) in enumerate([
    ('#FFFBEB', '#C05621', '因子① 付费用户数', '5,342 → 4,891（-8.4%）',
     'ΔGMV用户贡献 = ΔUser × BaseAOV', '贡献度约 176%  🔴 核心驱动'),
    ('#F0FFF4', '#276749', '因子② AOV（客单价）', '877 → 910（+3.8%）',
     'ΔGMV_AOV = ΔAOV × CurrUser', 'AOV 反涨，部分对冲  ✅ 非跌因'),
    ('#F7FAFC', '#4A5568', '三因子公式', 'ΔGMV = User效应 + AOV效应',
     '= (ΔUser×BaseAOV) + (ΔAOV×CurrUser)', '🟡 建议补充 iOS 漏斗数据'),
]):
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
for i, (t1, t2) in enumerate([
    ('① 背景（Background）',    '指标 / 周期 / 异动幅度 / σ 判定等级'),
    ('② 核心结论（Conclusion）', '主因（贡献度%）+ 次因 + 数据佐证  ← 最先看'),
    ('③ 业务建议（Action）',     '[数据] + [问题] + [行动]  ← 可直接执行'),
    ('④ 分析推导（Steps）',      'Q2质检→Q3并行→交叉→专项→Q4验证明细'),
]):
    iy = y + 88 + i * 56
    lines.append(txt(PAD + 32, iy,      t1, size=20, fill='#2C5282', weight='bold'))
    lines.append(txt(PAD + 32, iy + 28, t2, size=18, fill='#555'))

rx6 = PAD + lw6 + 32
rw6 = W - PAD * 2 - lw6 - 48
lines.append(rect(rx6, y + 16, rw6, BH6 - 32, '#FFF5F7', rx=8))
lines.append(txt(rx6 + rw6 // 2, y + 50, '⚡ 建议输出规范',
                 size=22, fill='#702459', anchor='middle', weight='bold'))
lines.append(txt(rx6 + 20, y + 88,  '❌ 错误示范', size=20, fill='#C53030', weight='bold'))
lines.append(txt(rx6 + 20, y + 116, '"建议关注升学课销售情况..."（虚指，不可执行）', size=18, fill='#999'))
lines.append(txt(rx6 + 20, y + 160, '✅ 正确示范', size=20, fill='#276749', weight='bold'))
lines.append(txt(rx6 + 20, y + 190,
                 '[小升初] GMV ↓24.5%（-3.1万，>2σ 轻度异常），4月初签约高峰结束后自然退潮，',
                 size=17, fill='#276749'))
lines.append(txt(rx6 + 20, y + 214, '建议4月底启动专题活动提前拉需求。', size=17, fill='#276749'))
lines.append(txt(rx6 + 20, y + 244,
                 '商业化电商 ↓33.4%（>3σ 严重异常），建议立即核查商品链接状态与投放计划。',
                 size=17, fill='#276749'))
lines.append(txt(rx6 + 20, y + 276,
                 '→ [数据事实 + σ级别] + [发现问题] + [具体行动]，每条可直接执行',
                 size=17, fill='#702459', weight='bold'))

ay = y + BH6
lines.append(arrow(CX, ay, CX, ay + 40))


# ══════════════════════════════════
# 交付物
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
lines.append(rect(PAD, y, W - PAD * 2, 280, '#1A202C', rx=14))
lines.append(txt(CX, y + 40, '📐  SQL 口径规范速查（必须遵守）',
                 size=26, fill='#A0AEC0', anchor='middle', weight='bold'))

sql_secs = [
    ('核心表', [
        '活跃宽表: topic_user_active_detail_day',
        '订单表:   topic_order_detail',
        '电销表:   crm_order_info',
        '线索表:   clue_info',
    ]),
    ('订单表必筛', [
        "product_id = '01'（C端）",
        'is_test_user = 0  |  sub_amount ≥ 39',
        '日期用 paid_time（timestamp）',
        '商品: good_name + stage_name  |  年级: mid_grade',
    ]),
    ('电销表必筛', [
        'is_test = false  |  amount ≥ 39',
        '日期字段: pay_time（非 paid_time）',
        'P99 过滤: amount ≤ PERCENTILE(0.99)',
        '渠道: business_gmv_attribution',
    ]),
    ('禁用字段', [
        '❌ grade → ✅ mid_grade',
        '❌ role → ✅ real_identity',
        '❌ day 分区 → ✅ paid_time',
        '❌ product_name → ✅ good_name + stage_name',
    ]),
]
sec_w = (W - PAD * 2 - 60) // 4
for i, (sec_title, sec_items) in enumerate(sql_secs):
    sx = PAD + 20 + i * (sec_w + 20)
    lines.append(txt(sx, y + 78, sec_title, size=20, fill='#68D391', weight='bold'))
    for j, item in enumerate(sec_items):
        lines.append(txt(sx, y + 108 + j * 30, item, size=16, fill='#A0AEC0'))

lines.append(txt(CX, y + 258,
                 '洋葱学园 BI 团队 · 归因分析 SOP v2.0 · 2026-05-06（统计阈值 + 动态表策略 + 4维并行）',
                 size=18, fill='#4A5568', anchor='middle'))

total_h = y + 280
lines.append('</svg>')

svg_content = '\n'.join(lines)
out_path = '/Users/hilda/attribution-analysis/docs/sop_v2_flowchart.svg'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(svg_content)

print(f'✅ SVG 生成完成，总高度 {total_h}px，宽度 {W}px')
