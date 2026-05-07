"""
归因分析 v2 真实测试脚本（重构版）
周期：2026-04-13 ~ 2026-04-19 vs 2026-04-06 ~ 2026-04-12
指标：全学段 GMV

逻辑：
  Q2  数据质检（分表策略：订单表只查分区完整性，电销表加 P99 过滤）
  Q3  并行下钻（学段 + 渠道）→ 交叉矩阵（学段 × 渠道）→ 专项深挖
  Q5  三因子拆解（GMV = 付费用户 × AOV）
  Q6  结论输出
"""

import paramiko, socket, threading, select, time, sys
from impala.dbapi import connect
import pandas as pd

pd.set_option('display.float_format', lambda x: f'{x:,.1f}')
pd.set_option('display.max_colwidth', 40)
pd.set_option('display.width', 120)

# ── 连接配置 ──────────────────────────────────────
SSH_HOST = '221.194.189.145'; SSH_USER = 'master'; SSH_PASS = 'unitedmaster'
DB_HOST  = '10.17.2.45';      DB_PORT  = 10010
DB_USER  = 'xuxingling';      DB_PASS  = 'Yangcong345'
LOCAL_PORT = 19998

# ── 分析周期 ──────────────────────────────────────
CURR_START = '2026-04-13'; CURR_END = '2026-04-20'
BASE_START = '2026-04-06'; BASE_END = '2026-04-13'

# ── Q2-C 触发阈值 ──────────────────────────────────
# 不固定，使用近四周同星期历史波动范围（std）动态判断
# 可在每次归因前由业务方确认调整
# 格式：(lower_pct, upper_pct)，如 (-5.0, 5.0) 表示历史正常波动 ±5%
# 设为 None 则跳过自动触发判断，强制进入 Q3
ANOMALY_THRESHOLD = (-4.0, 4.0)   # 单位：%，与业务方对齐后修改

# ── SSH 隧道 ──────────────────────────────────────
def build_tunnel():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(SSH_HOST, username=SSH_USER, password=SSH_PASS,
                   look_for_keys=False, allow_agent=False, timeout=15, banner_timeout=15)
    transport = client.get_transport()
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(('127.0.0.1', LOCAL_PORT)); srv.listen(10); srv.settimeout(3)
    def fwd():
        while True:
            try:
                lsock, addr = srv.accept()
                def handle(ls, a):
                    try:
                        chan = transport.open_channel('direct-tcpip', (DB_HOST, DB_PORT), a)
                        while True:
                            r, _, _ = select.select([ls, chan], [], [], 1)
                            if ls in r:
                                d = ls.recv(4096); 
                                if not d: break
                                chan.send(d)
                            if chan in r:
                                d = chan.recv(4096)
                                if not d: break
                                ls.send(d)
                        chan.close(); ls.close()
                    except: pass
                threading.Thread(target=handle, args=(lsock, addr), daemon=True).start()
            except socket.timeout: continue
            except: break
    threading.Thread(target=fwd, daemon=True).start()
    time.sleep(0.5)
    return client

def q(cur, sql, label=''):
    if label: print(f'    SQL: {label}')
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    return pd.DataFrame(cur.fetchall(), columns=cols)

def fmt_pct(a, b):
    if not b: return 'N/A'
    return f'{(a - b) / b * 100:+.1f}%'

def sep(title):
    print(f'\n{"━"*65}')
    print(f'  {title}')
    print('━'*65)


# ══════════════════════════════════════════════════
print('🔌 建立 SSH 隧道...')
client = build_tunnel()
conn = connect(host='127.0.0.1', port=LOCAL_PORT,
               user=DB_USER, password=DB_PASS, auth_mechanism='PLAIN')
cur = conn.cursor()
print('✅ 连接成功')


# ══════════════════════════════════════════════════
# Q2-A  订单表质检：分区完整性 + 基线合理性
#        ★ 不做极值剔除
# ══════════════════════════════════════════════════
sep('Q2-A  订单表质检（分区完整性）')

sql_daily = f"""
SELECT
    CAST(paid_time AS DATE) AS dt,
    COUNT(*) AS order_cnt,
    COUNT(DISTINCT u_user) AS user_cnt,
    SUM(sub_amount) AS gmv
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
GROUP BY 1
ORDER BY 1
"""
df_daily = q(cur, sql_daily, '每日订单量级')
print(df_daily.to_string(index=False))

# 校验：当前周 vs 基线周 每日均值偏差
curr_daily = df_daily[df_daily.dt.astype(str) >= CURR_START]
base_daily = df_daily[df_daily.dt.astype(str) < BASE_END]
curr_avg = curr_daily.order_cnt.mean()
base_avg = base_daily.order_cnt.mean()
dev = abs(curr_avg - base_avg) / base_avg * 100
print(f'\n  当前周日均订单：{curr_avg:.0f}  基线周日均：{base_avg:.0f}  偏差：{dev:.1f}%')
if dev > 50:
    print('  ❌ 日均偏差 > 50%，疑似数据异常，请核查！')
    sys.exit(1)
else:
    print('  ✅ 分区完整，数据量级正常')


# ══════════════════════════════════════════════════
# Q2-B  电销表质检：分区完整性 + P99 极值剔除
# ══════════════════════════════════════════════════
sep('Q2-B  电销表质检（含 P99 极值校验）')

sql_crm_check = f"""
SELECT
    CAST(pay_time AS DATE) AS dt,
    COUNT(*) AS order_cnt,
    MAX(amount) AS max_amount,
    AVG(amount) AS avg_amount
FROM aws.crm_order_info
WHERE pay_time >= '{BASE_START}' AND pay_time < '{CURR_END}'
  AND is_test = false
  AND amount >= 39
GROUP BY 1
ORDER BY 1
"""
df_crm_check = q(cur, sql_crm_check, '电销每日量级')
print(df_crm_check.to_string(index=False))

# P99 阈值查询
sql_p99 = f"""
SELECT PERCENTILE(amount, 0.99) AS p99
FROM aws.crm_order_info
WHERE pay_time >= '{BASE_START}' AND pay_time < '{CURR_END}'
  AND is_test = false AND amount >= 39
"""
df_p99 = q(cur, sql_p99, 'P99 阈值')
p99_val = float(df_p99['p99'].values[0])
print(f'\n  电销 P99 金额阈值：{p99_val:,.0f} 元')
print(f'  后续电销分析将过滤 amount > {p99_val:,.0f} 的超大单')


# ══════════════════════════════════════════════════
# Q2-C  汇总：两周 GMV / 用户数
# ══════════════════════════════════════════════════
sep('Q2-C  两周汇总对比')

sql_total = f"""
SELECT
    CASE WHEN paid_time >= '{CURR_START}' THEN 'current' ELSE 'baseline' END AS wk,
    COUNT(DISTINCT u_user) AS users,
    SUM(sub_amount) AS gmv,
    SUM(sub_amount) / COUNT(DISTINCT u_user) AS aov
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
GROUP BY 1
"""
df_total = q(cur, sql_total, '两周汇总')
print(df_total.to_string(index=False))

curr_r = df_total[df_total.wk == 'current'].iloc[0]
base_r = df_total[df_total.wk == 'baseline'].iloc[0]
curr_gmv  = float(curr_r.gmv);  base_gmv  = float(base_r.gmv)
curr_user = int(curr_r.users);  base_user = int(base_r.users)
curr_aov  = float(curr_r.aov);  base_aov  = float(base_r.aov)
total_delta = curr_gmv - base_gmv
gmv_pct = (curr_gmv - base_gmv) / base_gmv * 100

print(f'\n  GMV    ：{base_gmv:>12,.0f} → {curr_gmv:>12,.0f}  {fmt_pct(curr_gmv, base_gmv)}')
print(f'  付费用户：{base_user:>12,} → {curr_user:>12,}  {fmt_pct(curr_user, base_user)}')
print(f'  AOV    ：{base_aov:>12,.1f} → {curr_aov:>12,.1f}  {fmt_pct(curr_aov, base_aov)}')

if ANOMALY_THRESHOLD is None:
    print(f'\n  ℹ️  ANOMALY_THRESHOLD=None，跳过自动触发判断，强制进入 Q3')
else:
    lo, hi = ANOMALY_THRESHOLD
    if lo <= gmv_pct <= hi:
        print(f'\n  ⚠️  GMV 变化 {gmv_pct:+.1f}%，在业务方确认的正常波动范围 [{lo:+.1f}%, {hi:+.1f}%] 内')
        print(f'  → 不满足归因条件，记录后关闭')
        print(f'  → [关闭] GMV {CURR_START}周：变化 {gmv_pct:+.1f}%，历史正常范围 [{lo:+.1f}%, {hi:+.1f}%]，无需归因')
        sys.exit(0)
    print(f'\n  ✅ Q2 通过，GMV {gmv_pct:+.1f}%，超出正常范围 [{lo:+.1f}%, {hi:+.1f}%]，进入 Q3 下钻')


# ══════════════════════════════════════════════════
# Q3-A  并行下钻：学段贡献度
# ══════════════════════════════════════════════════
sep('Q3-A  学段维度贡献度')

sql_stage = f"""
SELECT
    stage_name,
    SUM(CASE WHEN paid_time >= '{BASE_START}' AND paid_time < '{BASE_END}'
             THEN sub_amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN paid_time >= '{CURR_START}' AND paid_time < '{CURR_END}'
             THEN sub_amount ELSE 0 END) AS curr_gmv
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
  AND stage_name IS NOT NULL AND stage_name != ''
GROUP BY 1
ORDER BY (curr_gmv - base_gmv) ASC
"""
df_stage = q(cur, sql_stage, '学段贡献度')
df_stage['delta']   = df_stage.curr_gmv - df_stage.base_gmv
df_stage['pct']     = (df_stage.curr_gmv - df_stage.base_gmv) / df_stage.base_gmv * 100
df_stage['contrib'] = df_stage.delta / total_delta * 100
print(df_stage[['stage_name','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))

top_stage = df_stage[df_stage.delta < 0].head(2)['stage_name'].tolist()
print(f'\n  TOP 下跌学段：{top_stage}')


# ══════════════════════════════════════════════════
# Q3-B  并行下钻：渠道贡献度
#        订单表：business_gmv_attribution
#        电销表：business_gmv_attribution（独立，用 p99 过滤）
# ══════════════════════════════════════════════════
sep('Q3-B  渠道维度贡献度')

# 订单表渠道（APP / 电商等）
sql_chan_order = f"""
SELECT
    business_gmv_attribution AS channel,
    SUM(CASE WHEN paid_time >= '{BASE_START}' AND paid_time < '{BASE_END}'
             THEN sub_amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN paid_time >= '{CURR_START}' AND paid_time < '{CURR_END}'
             THEN sub_amount ELSE 0 END) AS curr_gmv
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
  AND business_gmv_attribution IS NOT NULL AND business_gmv_attribution != ''
GROUP BY 1
ORDER BY (curr_gmv - base_gmv) ASC
"""
df_chan_order = q(cur, sql_chan_order, '订单表渠道')
df_chan_order['delta']   = df_chan_order.curr_gmv - df_chan_order.base_gmv
df_chan_order['pct']     = (df_chan_order.curr_gmv - df_chan_order.base_gmv) / df_chan_order.base_gmv * 100
df_chan_order['contrib'] = df_chan_order.delta / total_delta * 100
df_chan_order['source']  = 'order'
print('\n[订单表渠道 · 口径: topic_order_detail / 贡献度基于全量 GMV delta]')
print(df_chan_order[['channel','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))

# 电销表渠道（P99 过滤）
sql_chan_crm = f"""
SELECT
    business_gmv_attribution AS channel,
    SUM(CASE WHEN pay_time >= '{BASE_START}' AND pay_time < '{BASE_END}'
             THEN amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN pay_time >= '{CURR_START}' AND pay_time < '{CURR_END}'
             THEN amount ELSE 0 END) AS curr_gmv
FROM aws.crm_order_info
WHERE pay_time >= '{BASE_START}' AND pay_time < '{CURR_END}'
  AND is_test = false
  AND amount >= 39
  AND amount <= {p99_val}
  AND business_gmv_attribution IS NOT NULL AND business_gmv_attribution != ''
GROUP BY 1
ORDER BY (curr_gmv - base_gmv) ASC
"""
df_chan_crm = q(cur, sql_chan_crm, '电销表渠道（P99过滤）')
df_chan_crm['delta']   = df_chan_crm.curr_gmv - df_chan_crm.base_gmv
df_chan_crm['pct']     = (df_chan_crm.curr_gmv - df_chan_crm.base_gmv) / df_chan_crm.base_gmv * 100
# 电销表 contrib 基于电销内部 delta，不与订单表混用，避免口径歧义
crm_total_delta = df_chan_crm['delta'].sum()
df_chan_crm['contrib_crm'] = df_chan_crm.delta / crm_total_delta * 100 if crm_total_delta != 0 else float('nan')
df_chan_crm['source']  = 'crm'
print(f'\n[电销表渠道 · 口径: crm_order_info / P99={p99_val:,.0f} / 贡献度基于电销内部 delta，勿与订单表直接比较]')
print(df_chan_crm[['channel','base_gmv','curr_gmv','delta','pct','contrib_crm']].to_string(index=False))
print(f'  ⚠️  电销表与订单表口径不同（表、日期字段、金额字段均不同），贡献度不可跨表加总')

top_channel = df_chan_order[df_chan_order.delta < 0].head(2)['channel'].tolist()
print(f'\n  TOP 下跌渠道（订单表）：{top_channel}')


# ══════════════════════════════════════════════════
# Q3-C  交叉矩阵：学段 × 渠道
#        定位到具体的"学段 + 渠道"跌点
# ══════════════════════════════════════════════════
sep('Q3-C  交叉下钻：学段 × 渠道（订单表）')

sql_cross = f"""
SELECT
    stage_name,
    business_gmv_attribution AS channel,
    SUM(CASE WHEN paid_time >= '{BASE_START}' AND paid_time < '{BASE_END}'
             THEN sub_amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN paid_time >= '{CURR_START}' AND paid_time < '{CURR_END}'
             THEN sub_amount ELSE 0 END) AS curr_gmv
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
  AND stage_name IS NOT NULL AND stage_name != ''
  AND business_gmv_attribution IS NOT NULL AND business_gmv_attribution != ''
GROUP BY 1, 2
HAVING base_gmv > 10000
ORDER BY (curr_gmv - base_gmv) ASC
"""
df_cross = q(cur, sql_cross, '学段 × 渠道矩阵')
df_cross['delta']   = df_cross.curr_gmv - df_cross.base_gmv
df_cross['pct']     = (df_cross.curr_gmv - df_cross.base_gmv) / df_cross.base_gmv * 100
df_cross['contrib'] = df_cross.delta / total_delta * 100

print('\n[TOP 15 下跌组合]')
drop_cross = df_cross[df_cross.delta < 0].head(15)
print(drop_cross[['stage_name','channel','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))

print('\n[TOP 5 逆势增长组合]')
rise_cross = df_cross[df_cross.delta > 0].sort_values('delta', ascending=False).head(5)
print(rise_cross[['stage_name','channel','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))

# 找出贡献度最大的跌点组合
top_combo = drop_cross.head(3)[['stage_name','channel','delta','pct','contrib']].values
print('\n  TOP 3 跌点组合：')
for stage, channel, delta, pct_v, contrib in top_combo:
    print(f'    {stage} × {channel}：ΔGMV={delta:+,.0f}  {pct_v:+.1f}%  贡献{contrib:.1f}%')


# ══════════════════════════════════════════════════
# Q3-D  专项深挖 A：TOP 跌点学段 → SKU 下钻
# ══════════════════════════════════════════════════
sep('Q3-D  专项深挖：TOP 下跌学段 × SKU')

stage_filter = "', '".join(top_stage)
sql_sku = f"""
SELECT
    stage_name,
    good_name,
    mid_grade,
    SUM(CASE WHEN paid_time >= '{BASE_START}' AND paid_time < '{BASE_END}'
             THEN sub_amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN paid_time >= '{CURR_START}' AND paid_time < '{CURR_END}'
             THEN sub_amount ELSE 0 END) AS curr_gmv
FROM dws.topic_order_detail
WHERE paid_time >= '{BASE_START}' AND paid_time < '{CURR_END}'
  AND product_id = '01'
  AND sub_amount >= 39
  AND is_test_user = 0
  AND stage_name IN ('{stage_filter}')
  AND good_name IS NOT NULL
GROUP BY 1, 2, 3
HAVING base_gmv > 5000
ORDER BY (curr_gmv - base_gmv) ASC
LIMIT 12
"""
df_sku = q(cur, sql_sku, f'TOP 下跌学段 SKU（{top_stage}）')
df_sku['delta']   = df_sku.curr_gmv - df_sku.base_gmv
df_sku['pct']     = (df_sku.curr_gmv - df_sku.base_gmv) / df_sku.base_gmv * 100
df_sku['contrib'] = df_sku.delta / total_delta * 100
print(df_sku[['stage_name','good_name','mid_grade','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))


# ══════════════════════════════════════════════════
# Q3-E  专项深挖 B：TOP 跌点渠道 × 电销团队
# ══════════════════════════════════════════════════
sep('Q3-E  专项深挖：电销渠道 × 团队 × 学段')

sql_crm_team = f"""
SELECT
    business_gmv_attribution AS team,
    stage AS stage_name,
    SUM(CASE WHEN pay_time >= '{BASE_START}' AND pay_time < '{BASE_END}'
             THEN amount ELSE 0 END) AS base_gmv,
    SUM(CASE WHEN pay_time >= '{CURR_START}' AND pay_time < '{CURR_END}'
             THEN amount ELSE 0 END) AS curr_gmv
FROM aws.crm_order_info
WHERE pay_time >= '{BASE_START}' AND pay_time < '{CURR_END}'
  AND is_test = false
  AND amount >= 39
  AND amount <= {p99_val}
GROUP BY 1, 2
HAVING base_gmv > 5000
ORDER BY (curr_gmv - base_gmv) ASC
"""
df_crm_team = q(cur, sql_crm_team, '电销团队 × 学段')
df_crm_team['delta']   = df_crm_team.curr_gmv - df_crm_team.base_gmv
df_crm_team['pct']     = (df_crm_team.curr_gmv - df_crm_team.base_gmv) / df_crm_team.base_gmv * 100
df_crm_team['contrib'] = df_crm_team.delta / total_delta * 100
print(df_crm_team[['team','stage_name','base_gmv','curr_gmv','delta','pct','contrib']].to_string(index=False))


# ══════════════════════════════════════════════════
# Q5  三因子拆解：GMV = 付费用户 × AOV
# ══════════════════════════════════════════════════
sep('Q5  三因子拆解')

user_effect = (curr_user - base_user) * base_aov
aov_effect  = (curr_aov  - base_aov)  * curr_user

print(f'  付费用户：{base_user:,} → {curr_user:,}  {fmt_pct(curr_user, base_user)}')
print(f'  AOV    ：{base_aov:,.1f} → {curr_aov:,.1f}  {fmt_pct(curr_aov, base_aov)}')
print(f'  GMV 总Δ：{total_delta:+,.0f}')
print(f'    用户数贡献：{user_effect:+,.0f}  ({user_effect/total_delta*100:.1f}%)')
print(f'    AOV 贡献  ：{aov_effect:+,.0f}   ({aov_effect/total_delta*100:.1f}%)')


# ══════════════════════════════════════════════════
# Q6  结论输出
# ══════════════════════════════════════════════════
sep('Q6  归因结论')

print(f"""
【核心指标】
  GMV：{base_gmv:,.0f} → {curr_gmv:,.0f}  {fmt_pct(curr_gmv, base_gmv)}（Δ{total_delta:+,.0f}）
  付费用户：{base_user:,} → {curr_user:,}  {fmt_pct(curr_user, base_user)}
  AOV：{base_aov:,.1f} → {curr_aov:,.1f}  {fmt_pct(curr_aov, base_aov)}（{'排除价格因素' if abs((curr_aov-base_aov)/base_aov) < 0.05 else '价格有变动，需关注'}）

【Q5 主因】
  用户数贡献 {user_effect/total_delta*100:.0f}%，AOV 贡献 {aov_effect/total_delta*100:.0f}%
  → {'用户规模萎缩是主因' if abs(user_effect) > abs(aov_effect) else 'AOV 变动是主因'}

【Q3-A 学段贡献】
""")
for _, r in df_stage[df_stage.delta < 0].iterrows():
    print(f"  {r.stage_name:8s}  Δ{r.delta:+,.0f}  {r.pct:+.1f}%  贡献{r.contrib:.1f}%")

print('\n【Q3-B 渠道贡献（订单表，贡献度基于全量 GMV delta）】')
for _, r in df_chan_order[df_chan_order.delta < 0].iterrows():
    print(f"  {str(r.channel):20s}  Δ{r.delta:+,.0f}  {r.pct:+.1f}%  贡献{r.contrib:.1f}%")

print('\n【Q3-B 电销渠道（crm 表，贡献度仅在电销内部可比，⚠️ 不与上表叠加）】')
for _, r in df_chan_crm.iterrows():
    contrib_str = f"{r.contrib_crm:.1f}%" if not pd.isna(r.contrib_crm) else 'N/A'
    arrow = '↑' if r.delta > 0 else '↓'
    print(f"  {str(r.channel):20s}  Δ{r.delta:+,.0f}  {r.pct:+.1f}%  电销内贡献{contrib_str} {arrow}")

print('\n【Q3-C 学段×渠道 TOP 跌点】')
for stage, channel, delta, pct_v, contrib in top_combo:
    print(f"  {stage} × {channel}  Δ{delta:+,.0f}  {pct_v:+.1f}%  贡献{contrib:.1f}%")

print('\n【Q3-D TOP 下跌 SKU】')
for _, r in df_sku.head(5).iterrows():
    print(f"  [{r.stage_name}] {str(r.good_name)[:28]:28s} {r.mid_grade:4s}  Δ{r.delta:+,.0f}  {r.pct:+.1f}%")

print('\n✅ 归因分析完成')
cur.close(); conn.close(); client.close()
