# 归因分析 AI 工作流

## 描述
当用户描述业务指标异动（如"上周9年级转化率跌了"、"客单价下滑"、"GMV下降"）时，引导用户提供数据库连接信息，自动查询数据并输出结构化归因报告。

## 使用方法

将以下链接发给你的智能体即可启动：

```
https://github.com/xuxingling55-sketch/attribution-analysis
```

---

## 智能体执行流程

### Step 1：收集连接信息
向用户询问以下信息（可以一次性问）：
- SSH 跳板机 IP、用户名、密码
- 数据库内网 IP、端口、用户名、密码

### Step 2：收集异动描述
询问用户：
- 异动描述（例：上周9年级线索转化率和客单价都跌了）
- 分析年级/维度
- 时间窗口（近几周的起止日期）

### Step 3：执行分析
克隆仓库，填入用户提供的参数，运行 `python main.py`：

```bash
git clone https://github.com/xuxingling55-sketch/attribution-analysis.git
cd attribution-analysis
pip install -r requirements.txt
python main.py
```

### Step 4：输出报告
将 `reports/` 目录下生成的 Markdown 报告内容直接展示给用户，并给出根因判断建议。

---

## 参数填写位置

所有参数在 `main.py` 顶部修改：

```python
config = DBConfig(
    ssh_host="用户提供的SSH IP",
    ssh_user="用户提供的SSH用户名",
    ssh_password="用户提供的SSH密码",
    db_host="用户提供的DB内网IP",
    db_port=10010,
    db_user="用户提供的DB用户名",
    db_pass="用户提供的DB密码",
)

ANOMALY_DESC = "用户描述的异动"
GRADE = "用户指定的年级"

WEEKS_INT = [
    ("上周",  本周一int, 本周日int),
    ("上上周", 上周一int, 上周日int),
]
WEEKS_STR = [
    ("上周",  "YYYY-MM-DD", "YYYY-MM-DD"),
    ("上上周", "YYYY-MM-DD", "YYYY-MM-DD"),
]
```

---

## 注意事项
- 用户的数据库密码只在本次会话中使用，不会被保存或上传
- SQL 口径基于 Impala + 洋葱学园数仓规范，换用其他数仓需修改 `src/queries.py`
- 报告中的根因判断需结合数据结果人工审阅后填写
