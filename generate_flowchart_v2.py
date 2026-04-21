"""
归因分析 SOP v2 框架图 —— 高清大字版
画布：2400 宽，字号全面提升，模块间距充足
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

# ── SVG 头 + defs ─────────────────────────────────────────
lines.append(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} 4300" '
    f'font-family="PingFang SC, Heiti SC, STHeiti, Microsoft YaHei, sans-serif">'
)
lines.append('''<defs>
  <marker id="arrow" markerWidth="12" markerHeight="9" refX="11" refY="4.5" orient="auto">
    <polygon points="0 0,12 4.5,0 9" fill="#666"/>
  </marker>
</defs>''')
lines.append(f'<rect width="{W}" height="4300" fill="#F0F2F5"/>')


# ══════════════════════════════════
# 标题栏
# ══════════════════════════════════
y = 24
lines.append(rect(PAD, y, W - PAD * 2, 90, '#1A365D', rx=14))
lines.append(txt(CX, y + 48, '洋葱学园 · 异动归因分析框架 SOP v2.0', size=44,
                 fill='white', anchor='middle', weight='bold'))
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

# 列 1 输入规范
lines.append(txt(col_x[0], y + 38, '输入规范', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 指标：GMV / 付费人数 / 线索量 / 转化率 / ARPU',
    '· 周期：Current 周 vs Baseline 周（默认环比上周）',
    '· 特殊节假日可选同比，需标注',
]):
    lines.append(txt(col_x[0], y + 72 + i * 36, t, size=19, fill='#444'))

# 列 2 异动判定阈值
lines.append(txt(col_x[1], y + 38, '异动判定阈值', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 核心指标（GMV/付费人数）：|变化率| ≥ 5%',
    '  且绝对值 ≥ 1万元 → 触发归因流程',
    '· 过程指标（CVR/AOV）：|变化率| ≥ 10% → 触发',
]):
    lines.append(txt(col_x[1], y + 72 + i * 36, t, size=19, fill='#444'))

# 列 3 本次案例
lines.append(txt(col_x[2], y + 38, '本次案例', size=22, fill='#2B6CB0', weight='bold'))
for i, t in enumerate([
    '· 全学段 GMV：4,681,323 → 4,456,323',
    '  ↓ 4.8%，-22.5万',
    '· 付费用户：4,644 → 4,428（↓4.7%，-216人）',
]):
    lines.append(txt(col_x[2], y + 72 + i * 36, t, size=19, fill='#444'))

# 箭头 Q1→Q2
ay = y + BH1
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q2 真伪判定
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#276749', rx=12))
lines.append(txt(CX, y + 32, 'Q2  真伪判定 · Authenticity Check',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '质检门控：排除数据延迟 / 统计误差 / 离群值干扰',
                 size=20, fill='#9AE6B4', anchor='middle'))

y += 88
BH2 = 200
gap2 = 24
bw2 = (W - PAD * 2 - gap2 * 2) // 3

q2_boxes = [
    ('① 分区完整性校验', [
        'SQL: 每日记录数 vs 历史7天均值',
        '判定: 偏差 > 20% 且无业务原因',
        '→ 标记[疑似数据延迟]，暂停分析',
        '表: topic_order_detail | 字段: paid_time',
    ], '✅ 本案：每日量级正常，数据真实'),
    ('② 离群值剔除 (P99)', [
        '剔除单笔 sub_amount > P99 的超大单',
        '剔除 is_test_user = 1 的测试账号',
        '剔除 sub_amount < 39 的无效小单',
        '正价订单口径：sub_amount ≥ 39 元',
    ], '✅ 本案：已过滤，对趋势无影响'),
    ('③ 基线合理性校验', [
        '检查基线周是否含大促/节假日波峰',
        '若含波峰 → 切换[去促基线]再对比',
        '检查当前周是否含节日放量',
        '注意: 周末 GMV ≈ 工作日 2 倍属正常',
    ], '✅ 本案：两周节奏一致，基线合理'),
]

for i, (title, items, note) in enumerate(q2_boxes):
    bx = PAD + i * (bw2 + gap2)
    lines.append(rect(bx, y, bw2, BH2, 'white', stroke='#9AE6B4', sw=2))
    lines.append(txt(bx + 20, y + 36, title, size=21, fill='#276749', weight='bold'))
    for j, item in enumerate(items):
        lines.append(txt(bx + 20, y + 70 + j * 30, item, size=18, fill='#444'))
    lines.append(rect(bx + 10, y + BH2 - 38, bw2 - 20, 28, '#F0FFF4', rx=4))
    lines.append(txt(bx + 20, y + BH2 - 18, note, size=18, fill='#276749', weight='bold'))

# Q2 结论条
y += BH2 + 10
lines.append(rect(PAD, y, W - PAD * 2, 44, '#F0FFF4', stroke='#9AE6B4', sw=1.5))
lines.append(txt(CX, y + 28, 'Q2 结论：数据真实，进入 Q3 定位阶段 ✅',
                 size=22, fill='#276749', anchor='middle', weight='bold'))

ay = y + 44
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q3 定位下钻
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#744210', rx=12))
lines.append(txt(CX, y + 32, 'Q3  定位下钻与对标 · Location & Drill-Down',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '判断异动是[点 / 线 / 面]，确定分析主战场',
                 size=20, fill='#FBD38D', anchor='middle'))

# Step 3-A
y += 88
lines.append(rect(PAD, y, W - PAD * 2, 56, '#FFFBEB', stroke='#F6AD55', sw=1.5))
lines.append(txt(PAD + 24, y + 22, 'Step 3-A  全局对标（系统性 vs 局部性）',
                 size=22, fill='#744210', weight='bold'))
lines.append(txt(PAD + 24, y + 46,
                 '拉取[目标年级] vs [全学段大盘]同周期趋势 → 趋势一致：系统性异动（外部因素）；仅目标年级下跌：局部性异动（内部因素）',
                 size=19, fill='#555'))

# Step 3-B 年级数据表
y += 66
lines.append(rect(PAD, y, W - PAD * 2, 360, 'white', stroke='#F6AD55', sw=1.5))
lines.append(txt(PAD + 24, y + 32, 'Step 3-B  年级维度下钻（本案真实数据）',
                 size=22, fill='#744210', weight='bold'))

th_y = y + 52
lines.append(rect(PAD + 12, th_y, W - PAD * 2 - 24, 36, '#FFFBEB'))
col_x2 = [PAD + 36, PAD + 280, PAD + 560, PAD + 840, PAD + 1100, PAD + 1340]
for cx_, lb in zip(col_x2, ['年级', 'Baseline GMV', 'Current GMV', '变化额', '变化率', '归因信号']):
    lines.append(txt(cx_, th_y + 24, lb, size=20, fill='#744210', weight='bold'))

grade_rows = [
    ('六年级',       '289,283',   '239,345',   '-49,938',  '-17.3% 🔴', '#C53030', '小升初规划课需求退潮'),
    ('三/四年级',    '412,148',   '360,393',   '-51,755',  '-12.6% 🔴', '#C53030', '升学节点课退潮（四升五/五升六）'),
    ('八年级',       '927,440',   '870,640',   '-56,800',  '-6.1%  🟡', '#D69E2E', '七升八规划课周期回落'),
    ('七年级',       '1,111,905', '1,072,954', '-38,951',  '-3.5%  🟡', '#D69E2E', '商业化渠道效率下滑'),
    ('高一',         '627,153',   '604,076',   '-23,077',  '-3.7%  🟡', '#D69E2E', '新高二规划课退潮'),
    ('九年级',       '384,508',   '391,789',   '+7,281',   '+1.9%  🟢', '#276749', '临考紧迫感强，需求稳定'),
    ('一年级/学龄前', '98,526',   '121,836',   '+23,310',  '+23.7% 🟢', '#276749', '低年级逆势增长，亮点'),
    ('全学段合计',   '4,681,323', '4,456,323', '-225,000', '-4.8%',     '#C53030', '下跌集中于升学节点年级'),
]
for ri, (grade, b, c, d, pct, pcol, signal) in enumerate(grade_rows):
    ry = th_y + 36 + ri * 36
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 36, '#FAFAFA'))
    g_col = '#C53030' if '-' in pct else ('#276749' if '+' in pct else '#555')
    lines.append(txt(col_x2[0], ry + 24, grade,  size=19, fill=g_col))
    lines.append(txt(col_x2[1], ry + 24, b,      size=19, fill='#555'))
    lines.append(txt(col_x2[2], ry + 24, c,      size=19, fill='#555'))
    lines.append(txt(col_x2[3], ry + 24, d,      size=19, fill=pcol))
    lines.append(txt(col_x2[4], ry + 24, pct,    size=19, fill=pcol, weight='bold'))
    lines.append(txt(col_x2[5], ry + 24, signal, size=18, fill='#744210'))

# Step 3-C
y += 360 + 12
lines.append(rect(PAD, y, W - PAD * 2, 56, '#FFFBEB', stroke='#F6AD55', sw=1))
lines.append(txt(PAD + 24, y + 22, 'Step 3-C  亲缘关联识别', size=22, fill='#744210', weight='bold'))
lines.append(txt(PAD + 24, y + 46,
                 '六年级↓17.3% ＋ 三四年级↓12.6% ＋ 八年级↓6.1% → 共性：均为升学节点年级 → 锁定[升学规划课需求周期性退潮]为群体共性原因',
                 size=19, fill='#555'))

# Step 3-D 分叉标题
y += 66
lines.append(rect(PAD + 180, y, W - PAD * 2 - 360, 56, '#2D3748', rx=10))
lines.append(txt(CX, y + 24, 'Step 3-D  专项维度下钻（商品维度 & 渠道维度）',
                 size=26, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 48, '⚠️  商品与渠道采用差异化归因路径，不可混用',
                 size=19, fill='#A0AEC0', anchor='middle'))

# 分叉
y += 56
fork_y = y + 20
mid_L = PAD + (W // 2 - PAD) // 2
mid_R = W // 2 + (W // 2 - PAD) // 2
lines.append(seg(CX, y, CX, fork_y))
lines.append(seg(CX, fork_y, mid_L, fork_y))
lines.append(seg(CX, fork_y, mid_R, fork_y))
lines.append(arrow(mid_L, fork_y, mid_L, fork_y + 24))
lines.append(arrow(mid_R, fork_y, mid_R, fork_y + 24))

# ── 商品维度（左）──
y2 = fork_y + 26
half_w = W // 2 - PAD - 20

lines.append(rect(PAD, y2, half_w, 530, 'white', stroke='#805AD5', sw=2.5))
lines.append(rect(PAD, y2, half_w, 48, '#805AD5', rx=10))
lines.append(txt(PAD + half_w // 2, y2 + 31, '📦  商品维度归因',
                 size=26, fill='white', anchor='middle', weight='bold'))

lines.append(txt(PAD + 28, y2 + 80, '第一级：归因至学段', size=22, fill='#553C9A', weight='bold'))
for i, t in enumerate(['字段: stage_name（小学 / 初中 / 高中）',
                        '作用: 确认哪个学段贡献了最大异动']):
    lines.append(txt(PAD + 28, y2 + 112 + i * 30, t, size=19, fill='#444'))

lines.append(seg(PAD + 28, y2 + 176, PAD + half_w - 28, y2 + 176, '#805AD5', sw=1))

lines.append(txt(PAD + 28, y2 + 200, '第二级：归因至具体异动 SKU', size=22, fill='#553C9A', weight='bold'))
for i, t in enumerate(['字段: good_name + mid_grade',
                        '方法: 对比两周各 SKU GMV，计算贡献度',
                        '公式: Contribution = ΔSKU_GMV / ΔTotal_GMV']):
    lines.append(txt(PAD + 28, y2 + 232 + i * 30, t, size=19, fill='#444'))

# TOP SKU 表  （列位置用绝对 x，给名称列足够空间）
th3_y = y2 + 332
SKU_NAME_X  = PAD + 28
SKU_DELTA_X = PAD + 28 + 620   # 变化额列
SKU_PCT_X   = PAD + 28 + 800   # 变化率列
lines.append(rect(PAD + 14, th3_y, half_w - 28, 30, '#F3E8FF'))
lines.append(txt(SKU_NAME_X,  th3_y + 20, 'TOP 异动商品（真实数据）', size=18, fill='#553C9A', weight='bold'))
lines.append(txt(SKU_DELTA_X, th3_y + 20, '变化额',                   size=18, fill='#553C9A', weight='bold'))
lines.append(txt(SKU_PCT_X,   th3_y + 20, '变化率',                   size=18, fill='#553C9A', weight='bold'))

sku_rows = [
    ('[七升八]初中规划提分课（七年级）', '-39,060', '-7.9%'),
    ('[小升初]初中规划提分课（六年级）', '-31,347', '-24.5%'),
    ('[四升五]小初全面进阶课（四年级）', '-28,666', '-46.3%'),
    ('[新高二]高中规划提分课（九年级）', '-26,488', '-68.3%'),
    ('初中数学同步课12个月（七年级）',    '-21,414', '-24.6%'),
]
for ri, (nm, d, p) in enumerate(sku_rows):
    ry3 = th3_y + 30 + ri * 32
    if ri % 2 == 0:
        lines.append(rect(PAD + 14, ry3, half_w - 28, 32, '#FDF8FF'))
    lines.append(txt(SKU_NAME_X,  ry3 + 22, nm, size=17, fill='#C53030'))
    lines.append(txt(SKU_DELTA_X, ry3 + 22, d,  size=17, fill='#C53030'))
    lines.append(txt(SKU_PCT_X,   ry3 + 22, p,  size=17, fill='#C53030'))

lines.append(txt(PAD + 28, y2 + 510,
                 '→ 共性：均为[升学规划]课型，4月初签约高峰后自然退潮',
                 size=18, fill='#553C9A', weight='bold'))

# ── 渠道维度（右）──
rx2 = W // 2 + 20
lines.append(rect(rx2, y2, half_w, 530, 'white', stroke='#2B6CB0', sw=2.5))
lines.append(rect(rx2, y2, half_w, 48, '#2B6CB0', rx=10))
lines.append(txt(rx2 + half_w // 2, y2 + 31, '📡  渠道维度归因',
                 size=26, fill='white', anchor='middle', weight='bold'))

lines.append(txt(rx2 + 28, y2 + 80, '▶  APP 渠道：漏斗转化分析', size=22, fill='#2C5282', weight='bold'))
for i, t in enumerate([
    '路径：曝光 → 点击 → 试听 → 支付成功',
    '方法：逐级计算转化率，定位断点环节',
    '表: dws.topic_user_behavior_detail',
    '字段: event_name (show/click/listen/pay), u_user',
]):
    lines.append(txt(rx2 + 28, y2 + 112 + i * 30, t, size=19, fill='#444'))

lines.append(rect(rx2 + 14, y2 + 244, half_w - 28, 64, '#EBF8FF', rx=6))
lines.append(txt(rx2 + 28, y2 + 264, '正常转化参考：曝光→点击 ~35%   点击→试听 ~55%', size=18, fill='#2C5282'))
lines.append(txt(rx2 + 28, y2 + 290,
                 '⚠️ 重点关注：试听→支付 若骤降 → 定位为【支付断点】',
                 size=18, fill='#C53030'))

lines.append(seg(rx2 + 14, y2 + 322, rx2 + half_w - 14, y2 + 322, '#BEE3F8', sw=1.5))

lines.append(txt(rx2 + 28, y2 + 348, '▶  电销渠道：归因至销售团队', size=22, fill='#2C5282', weight='bold'))
for i, t in enumerate([
    '维度: business_gmv_attribution（团队标签）',
    '表: aws.crm_order_info | 字段: stage, pay_time, amount',
]):
    lines.append(txt(rx2 + 28, y2 + 378 + i * 28, t, size=19, fill='#444'))

# 电销数据  （列位置用绝对 x）
th4_y = y2 + 430
CRM_NAME_X  = rx2 + 28
CRM_DELTA_X = rx2 + 400
CRM_PCT_X   = rx2 + 600
lines.append(rect(rx2 + 14, th4_y, half_w - 28, 30, '#EBF8FF'))
lines.append(txt(CRM_NAME_X,  th4_y + 20, '本案真实数据',  size=18, fill='#2C5282', weight='bold'))
lines.append(txt(CRM_DELTA_X, th4_y + 20, '变化额',        size=18, fill='#2C5282', weight='bold'))
lines.append(txt(CRM_PCT_X,   th4_y + 20, '变化率',        size=18, fill='#2C5282', weight='bold'))

crm_rows = [
    ('初中-商业化',     '-108,459', '-14.3%', '#C53030'),
    ('初中-商业化电商', '-31,424',  '-33.4%', '#C53030'),
    ('初中-电销团队',   '+91,252',  '+3.5% ✅', '#276749'),
]
for ri, (nm, d, p, col) in enumerate(crm_rows):
    ry4 = th4_y + 30 + ri * 30
    bg4 = '#FFF5F5' if col == '#C53030' else '#F0FFF4'
    lines.append(rect(rx2 + 14, ry4, half_w - 28, 30, bg4))
    lines.append(txt(CRM_NAME_X,  ry4 + 20, nm, size=18, fill=col))
    lines.append(txt(CRM_DELTA_X, ry4 + 20, d,  size=18, fill=col))
    lines.append(txt(CRM_PCT_X,   ry4 + 20, p,  size=18, fill=col, weight='bold'))

# 合并箭头
merge_y = y2 + 530 + 20
lines.append(seg(mid_L,  y2 + 530, mid_L,  merge_y))
lines.append(seg(mid_R,  y2 + 530, mid_R,  merge_y))
lines.append(seg(mid_L,  merge_y,  mid_R,  merge_y))
lines.append(arrow(CX,  merge_y, CX, merge_y + 36))


# ══════════════════════════════════
# Q4 假设验证
# ══════════════════════════════════
y = merge_y + 38
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#702459', rx=12))
lines.append(txt(CX, y + 32, 'Q4  假设验证 · Hypothesis Testing',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '六大假设维度逐一验证，排除干扰、锁定根因',
                 size=20, fill='#FED7E2', anchor='middle'))

y += 88
lines.append(rect(PAD, y, W - PAD * 2, 380, 'white', stroke='#FED7E2', sw=2))

th5_y = y + 14
lines.append(rect(PAD + 12, th5_y, W - PAD * 2 - 24, 40, '#FFF5F7'))
hcols = [PAD + 30, PAD + 300, PAD + 900, PAD + 1480, PAD + 1700]
for hx, hl in zip(hcols, ['假设维度', '验证逻辑 & SQL 口径', '本案验证结果', '贡献度', '判定']):
    lines.append(txt(hx, th5_y + 27, hl, size=21, fill='#702459', weight='bold'))

hyp_rows = [
    ('H1 流量/活跃萎缩',
     'COUNT(DISTINCT u_user), topic_user_active_detail_day',
     '付费用户 4,644→4,428（↓216人，-4.7%）', '~55%', '🔴 主因', '#C53030'),
    ('H2 商品结构变化',
     'good_name 维度对比，升学规划课集中下跌',
     '[小升初/四升五/七升八]课型集中下跌', '~55%', '🔴 主因', '#C53030'),
    ('H3 渠道结构变化',
     'business_gmv_attribution, crm_order_info',
     '商业化渠道-14.3%，电销团队+3.5%', '~30%', '🟡 次因', '#D69E2E'),
    ('H4 价格/AOV 变化',
     'SUM(sub_amount)/COUNT(DISTINCT u_user)',
     'AOV: 1,008→1,006（-0.2%，几乎不变）', '~0%', '✅ 排除', '#276749'),
    ('H5 外部竞品/政策',
     '竞品监控（作业帮/猿辅导/学而思）',
     '未检测到竞品大促或行业政策变动', '~0%', '✅ 排除', '#276749'),
    ('H6 产品/技术故障',
     'APP 漏斗转化率对比，支付成功率监控',
     '支付成功率无异常跌幅（需 APP 漏斗数据确认）', '待核', '🟡 待确认', '#D69E2E'),
]
for ri, (h, sql, res, contrib, judge, col) in enumerate(hyp_rows):
    ry = th5_y + 40 + ri * 50
    if ri % 2 == 0:
        lines.append(rect(PAD + 12, ry, W - PAD * 2 - 24, 50, '#FAFAFA'))
    lines.append(txt(hcols[0], ry + 30, h,       size=19, fill='#444', weight='bold'))
    lines.append(txt(hcols[1], ry + 30, sql,     size=18, fill='#555'))
    lines.append(txt(hcols[2], ry + 30, res,     size=18, fill=col))
    lines.append(txt(hcols[3], ry + 30, contrib, size=20, fill=col, weight='bold'))
    lines.append(txt(hcols[4], ry + 30, judge,   size=20, fill=col, weight='bold'))

# SQL 规范
lines.append(rect(PAD + 12, y + 338, W - PAD * 2 - 24, 32, '#FFF5F7'))
lines.append(txt(CX, y + 360,
                 "SQL 规范红线：product_id='01' | is_test_user=0 | sub_amount≥39 | 使用 mid_grade 不使用 grade | 日期用 paid_time",
                 size=19, fill='#702459', anchor='middle', weight='bold'))

ay = y + 380
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q5 主因判定
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 120, y, W - PAD * 2 - 240, 72, '#C05621', rx=12))
lines.append(txt(CX, y + 32, 'Q5  主因判定 · Root Cause Quantification',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '三因子分解：GMV = 付费用户数 × CVR × AOV',
                 size=20, fill='#FBD38D', anchor='middle'))

y += 88
BH5 = 220
lines.append(rect(PAD, y, W - PAD * 2, BH5, 'white', stroke='#FBD38D', sw=2))

bw5 = (W - PAD * 2 - 48) // 3
factor_data = [
    ('#FFFBEB', '#C05621', '因子① 付费用户数', '4,644 → 4,428（-4.7%）', '贡献度：~95%', '🔴 核心驱动因子'),
    ('#F0FFF4', '#276749', '因子② AOV（客单价）', '1,008 → 1,006（-0.2%）', '贡献度：~5%', '✅ 排除，无价格策略影响'),
    ('#F7FAFC', '#4A5568', '因子③ CVR（转化率）', '需结合活跃宽表计算', '表: topic_user_active_detail_day', '🟡 建议补充 APP 漏斗数据'),
]
for i, (bg, fg, title, val, note1, note2) in enumerate(factor_data):
    fx = PAD + i * (bw5 + 24)
    lines.append(rect(fx + 12, y + 16, bw5 - 12, BH5 - 32, bg, rx=8))
    lines.append(txt(fx + 12 + bw5 // 2, y + 52,  title, size=22, fill=fg, anchor='middle', weight='bold'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 96,  val,   size=24, fill=fg, anchor='middle', weight='bold'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 136, note1, size=19, fill='#666', anchor='middle'))
    lines.append(txt(fx + 12 + bw5 // 2, y + 172, note2, size=20, fill=fg,   anchor='middle', weight='bold'))

ay = y + BH5
lines.append(arrow(CX, ay, CX, ay + 44))


# ══════════════════════════════════
# Q6 建议输出
# ══════════════════════════════════
y = ay + 46
lines.append(rect(PAD + 80, y, W - PAD * 2 - 160, 72, '#1A365D', rx=12))
lines.append(txt(CX, y + 32, 'Q6  建议输出 · Action & Narrative Report',
                 size=30, fill='white', anchor='middle', weight='bold'))
lines.append(txt(CX, y + 60, '结论先行（金字塔结构）+ 取数给建议（禁止虚指）',
                 size=20, fill='#90CDF4', anchor='middle'))

y += 88
BH6 = 320
lines.append(rect(PAD, y, W - PAD * 2, BH6, 'white', stroke='#90CDF4', sw=2))

lw6 = (W - PAD * 2 - 40) // 2
# 左：报告结构
lines.append(rect(PAD + 16, y + 16, lw6 - 8, BH6 - 32, '#EBF8FF', rx=8))
lines.append(txt(PAD + 16 + lw6 // 2, y + 50, '📋 报告结构（金字塔原理）',
                 size=22, fill='#1A365D', anchor='middle', weight='bold'))
report_items = [
    ('① 背景（Background）',    '指标 / 周期 / 异动幅度（数字说话，一表说清）'),
    ('② 核心结论（Conclusion）', '主因（贡献度%）+ 次因 + 数据佐证  ← 最先看'),
    ('③ 业务建议（Action）',     '[数据事实] + [发现问题] + [具体行动]  ← 可直接讲'),
    ('④ 分析推导（Steps）',      'Q2质检→Q3下钻→Q4验证明细  ← 按需阅读'),
]
for i, (t1, t2) in enumerate(report_items):
    iy = y + 88 + i * 56
    lines.append(txt(PAD + 32, iy,     t1, size=20, fill='#2C5282', weight='bold'))
    lines.append(txt(PAD + 32, iy + 28, t2, size=18, fill='#555'))

# 右：建议规范
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
                 '  [小升初] GMV↓24.5%（-3.1万），系4月初签约高峰结束后自然退潮，',
                 size=18, fill='#276749'))
lines.append(txt(rx6 + 20, y + 242,
                 '  建议4月底启动小升初专题活动提前拉需求。',
                 size=18, fill='#276749'))
lines.append(txt(rx6 + 20, y + 268,
                 '  初中商业化电商↓33.4%，建议4/22前核查商品链接状态。',
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
lines.append(rect(PAD, y, W - PAD * 2, 250, '#1A202C', rx=14))
lines.append(txt(CX, y + 40, '📐  SQL 口径规范速查（必须遵守）',
                 size=26, fill='#A0AEC0', anchor='middle', weight='bold'))

sql_secs = [
    ('核心表', [
        '活跃宽表: dws.topic_user_active_detail_day',
        '订单表:   dws.topic_order_detail',
        '电销表:   aws.crm_order_info  |  线索表: aws.clue_info',
    ]),
    ('必筛字段', [
        "product_id = '01'（C端）  |  is_test_user = 0（去测试）",
        "sub_amount ≥ 39（正价单）  |  client_os IN ('android','ios','harmony')",
    ]),
    ('字段规范', [
        '年级: mid_grade（禁用 grade）  |  身份: real_identity（禁用 role）',
        '日期: paid_time timestamp（禁用 day 分区）  |  商品: good_name + stage_name',
    ]),
    ('活跃宽表必筛', [
        "active_user_attribution IN ('中学用户','小学用户','c')",
        'business_user_pay_status_business（付费分层字段）',
    ]),
]
sec_w = (W - PAD * 2 - 60) // 4
for i, (sec_title, sec_items) in enumerate(sql_secs):
    sx = PAD + 20 + i * (sec_w + 20)
    lines.append(txt(sx, y + 76, sec_title, size=20, fill='#68D391', weight='bold'))
    for j, item in enumerate(sec_items):
        lines.append(txt(sx, y + 106 + j * 30, item, size=16, fill='#A0AEC0'))

lines.append(txt(CX, y + 228,
                 '洋葱学园 BI 团队 · 归因分析 SOP v2.0 · 2026-04-21',
                 size=18, fill='#4A5568', anchor='middle'))

total_h = y + 250
lines.append('</svg>')

svg_content = '\n'.join(lines)
with open('/Users/hilda/attribution-analysis/docs/sop_v2_flowchart.svg', 'w', encoding='utf-8') as f:
    f.write(svg_content)

print(f'✅ SVG 生成完成，总高度 {total_h}px，宽度 {W}px')
